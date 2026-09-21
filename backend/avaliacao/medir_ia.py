"""Bateria de medição da geração por IA, para o capítulo 6 do TCC.

Executa N gerações por perfil de teste usando exatamente o mesmo prompt, o
mesmo esquema de saída e a mesma validação do serviço de produção, porém sem
gravar nada no banco: os perfis são objetos em memória e o resultado vai para
CSV.

    python avaliacao/medir_ia.py --repeticoes 10

Saída (pasta avaliacao/resultados/):
    execucoes_<modelo>_<data>.csv    uma linha por chamada à API
    prescricoes_<modelo>_<data>.csv  uma linha por exercício prescrito

O resumo impresso ao final já traz os números no formato dos Quadros 4, 5 e 7.
"""

import argparse
import csv
import os
import statistics
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SessionLocal
from models.exercicio_model import ExercicioDB, LesaoDB
# Importados só para registrar os mapeamentos: sem eles o SQLAlchemy não
# resolve os relacionamentos declarados por nome em UsuarioDB.
from models import frequencia_model, treino_model, usuario_model  # noqa: F401
from schemas.ia_schema import FAIXAS_POR_OBJETIVO
from services import ia_treino_service as ia

# ---------------------------------------------------------------------------
# Perfis de teste (Quadro 3). As lesões são referenciadas pelo nome exato do
# catálogo; o script aborta se algum nome não existir no banco.
# ---------------------------------------------------------------------------


@dataclass
class PerfilTeste:
    """Sósia de UsuarioDB: tem só o que o prompt e o filtro de lesões leem.

    Deliberadamente não é um UsuarioDB — assim nenhuma execução da bateria
    escreve linha alguma no banco de produção.
    """

    codigo: str
    qtd_dias: int
    objetivo: str
    foco: str
    peso: float
    altura: float
    nomes_lesoes: list
    id_usuario: int = 0
    lesoes: list = field(default_factory=list)


PERFIS = [
    PerfilTeste(
        codigo="P1",
        qtd_dias=3,
        objetivo="hipertrofia",
        foco="full_body",
        peso=78.0,
        altura=1.78,
        nomes_lesoes=[],
    ),
    PerfilTeste(
        codigo="P2",
        qtd_dias=4,
        objetivo="forca",
        foco="superiores",
        peso=85.0,
        altura=1.80,
        # Combinação escolhida de propósito: deixa o grupo bíceps apenas com
        # exercícios de cautela, única condição em que a ressalva pode ser
        # usada. Sem isso as regras de cautela não seriam exercitadas.
        nomes_lesoes=[
            "Síndrome do Impacto (Ombro)",
            "Tendinite no Pulso / Síndrome do Túnel do Carpo",
        ],
    ),
    PerfilTeste(
        codigo="P3",
        qtd_dias=2,
        objetivo="emagrecimento",
        foco="inferiores",
        peso=95.0,
        altura=1.65,
        nomes_lesoes=[
            "Lesão de Ligamento (LCA/LCP)",
            "Lombalgia (Dor Lombar)",
            "Tendinite de Aquiles",
        ],
    ),
    PerfilTeste(
        codigo="P4",
        qtd_dias=5,
        objetivo="condicionamento",
        foco="full_body",
        peso=70.0,
        altura=1.72,
        # Deixa glúteos apenas com exercício sob cautela, repetindo a condição
        # do P2 em um foco equilibrado e com cinco dias.
        nomes_lesoes=["Pós-Operatório Recente"],
    ),
]

# Faixas de referência da literatura, importadas do próprio contrato de saída
# para que a régua da medição e a regra do sistema não divirjam.
FAIXAS_LITERATURA = FAIXAS_POR_OBJETIVO

GRUPOS_SUPERIORES = {"peito", "costas", "ombro", "biceps", "triceps"}
GRUPOS_INFERIORES = {
    "quadriceps", "isquiotibiais", "gluteos",
    "adutores", "abdutores", "panturrilha",
}


def grupos_esperados(foco: str) -> set:
    if foco == "superiores":
        return GRUPOS_SUPERIORES
    if foco == "inferiores":
        return GRUPOS_INFERIORES
    return GRUPOS_SUPERIORES | GRUPOS_INFERIORES


# ---------------------------------------------------------------------------
# Classificação das falhas
# ---------------------------------------------------------------------------

def classificar_motivo(exc: Exception) -> str:
    """Reduz a exceção a uma das categorias usadas no Quadro 5."""
    if not isinstance(exc, ValueError):
        return "falha_na_api"

    msg = str(exc)
    if "dias, esperado" in msg:
        return "qtd_dias_divergente"
    if "Numeração" in msg:
        return "numeracao_invalida"
    if "inexistentes ou contraindicados" in msg:
        return "id_fora_do_catalogo"
    if "repetido" in msg:
        return "exercicio_repetido"
    if "fora da faixa" in msg:
        return "qtd_exercicios_fora_da_faixa"
    if "sob cautela abrindo" in msg:
        return "cautela_como_primeiro"
    if "exercícios sob cautela, no máximo" in msg or "sob cautela," in msg and "máximo" in msg:
        return "cautela_mais_de_um_no_dia"
    if "que tem alternativa liberada" in msg:
        return "cautela_havendo_alternativa"
    if "acima do mínimo do dia" in msg:
        return "cautela_sem_reducao_de_volume"
    return "outro"


# ---------------------------------------------------------------------------
# Verificações que o _validar NÃO faz: são regras que só existem no prompt.
# Medi-las é o ponto do teste — mostra o que a instrução garante e o que não.
# ---------------------------------------------------------------------------

def auditar_cautela(plano, avisos: dict, grupo_por_id: dict, ids_validos: set) -> dict:
    """Confere as quatro condições de uso do nível de cautela.

    Devolve contagens de violação por dia, não interrompendo nada: uma
    violação aqui não reprova a ficha em produção, e é exatamente essa
    diferença que o capítulo 6 discute.
    """
    # grupos que só têm exercício sob ressalva: nesses, usar cautela é correto
    grupos_sem_alternativa = set()
    for grupo in set(grupo_por_id.values()):
        ids_do_grupo = {i for i, g in grupo_por_id.items() if g == grupo and i in ids_validos}
        if ids_do_grupo and ids_do_grupo <= set(avisos):
            grupos_sem_alternativa.add(grupo)

    total = primeiro_do_dia = mais_de_um = com_alternativa = 0
    for dia in plano.dias:
        ids = [e.id_exercicio for e in dia.exercicios]
        sob_ressalva = [i for i in ids if i in avisos]
        total += len(sob_ressalva)

        if ids and ids[0] in avisos:
            primeiro_do_dia += 1
        if len(sob_ressalva) > 1:
            mais_de_um += 1
        for i in sob_ressalva:
            if grupo_por_id.get(i) not in grupos_sem_alternativa:
                com_alternativa += 1

    return {
        "cautela_prescritos": total,
        "cautela_como_primeiro": primeiro_do_dia,
        "cautela_mais_de_um_no_dia": mais_de_um,
        "cautela_havendo_alternativa": com_alternativa,
    }


def auditar_foco(plano, foco: str, grupo_por_id: dict, ids_validos: set) -> dict:
    """Cobertura do foco declarado.

    Interessa tanto o que entrou fora do foco quanto o que ficou de fora
    tendo exercício disponível: um treino de superiores que ignora ombro e
    bíceps é estruturalmente válido e mesmo assim mal distribuído.
    """
    esperados = grupos_esperados(foco)
    treinados = {grupo_por_id.get(e.id_exercicio) for dia in plano.dias for e in dia.exercicios}
    treinados.discard(None)

    disponiveis = {grupo_por_id[i] for i in ids_validos if i in grupo_por_id}
    ausentes = (esperados & disponiveis) - treinados

    return {
        "grupos_treinados": len(treinados),
        "grupos_fora_do_foco": len(treinados - esperados),
        "grupos_do_foco_ausentes": len(ausentes),
        "lista_grupos": "|".join(sorted(treinados)),
        "lista_ausentes": "|".join(sorted(ausentes)),
    }


def dentro_da_faixa(objetivo: str, reps: int, descanso: int) -> bool:
    faixa = FAIXAS_LITERATURA.get(objetivo)
    if not faixa:
        return True
    r_min, r_max = faixa["reps"]
    d_min, d_max = faixa["descanso"]
    return r_min <= reps <= r_max and d_min <= descanso <= d_max


# ---------------------------------------------------------------------------
# Execução
# ---------------------------------------------------------------------------

def carregar_lesoes(db, perfil: PerfilTeste) -> None:
    for nome in perfil.nomes_lesoes:
        lesao = db.query(LesaoDB).filter(LesaoDB.nm_lesao == nome).first()
        if lesao is None:
            raise SystemExit(
                f"Lesão '{nome}' não existe em tb_lesoes. "
                f"Ajuste o perfil {perfil.codigo} em PERFIS."
            )
        perfil.lesoes.append(lesao)


def uma_chamada(client, perfil: PerfilTeste, catalogo: str) -> tuple:
    """Uma requisição à API, replicando os parâmetros de produção."""
    ajuste_effort = {"output_config": {"effort": ia.EFFORT_IA}} if ia.EFFORT_IA else {}

    inicio = time.perf_counter()
    resposta = client.messages.parse(
        model=ia.MODELO_IA,
        max_tokens=ia.MAX_TOKENS,
        system=[{
            "type": "text",
            "text": ia.INSTRUCOES.format(
                dias=perfil.qtd_dias,
                minimo=ia.MIN_EXERCICIOS_DIA,
                maximo=ia.MAX_EXERCICIOS_DIA,
                catalogo=catalogo,
            ),
            "cache_control": {"type": "ephemeral"},
        }],
        messages=[{"role": "user", "content": ia._montar_perfil(perfil, perfil.qtd_dias)}],
        output_format=ia.plano_com_dias(perfil.qtd_dias, perfil.objetivo),
        **ajuste_effort,
    )
    latencia = time.perf_counter() - inicio
    return resposta, latencia


def main() -> None:
    parser = argparse.ArgumentParser(description="Bateria de medição da geração por IA.")
    parser.add_argument("--repeticoes", type=int, default=10,
                        help="Gerações por perfil (padrão: 10).")
    parser.add_argument("--perfis", default="",
                        help="Códigos separados por vírgula, ex.: P2,P3. Vazio = todos.")
    parser.add_argument("--modelo", default="",
                        help="Sobrepõe IA_MODEL nesta execução, ex.: claude-opus-5.")
    args = parser.parse_args()

    if args.modelo:
        # Trocar aqui, e não no .env, deixa a comparação entre modelos ser uma
        # linha de comando — o serviço de produção continua intocado.
        ia.MODELO_IA = args.modelo

    if not os.getenv("ANTHROPIC_API_KEY"):
        raise SystemExit("ANTHROPIC_API_KEY não configurada no .env")

    from anthropic import Anthropic
    client = Anthropic()

    filtro = {c.strip() for c in args.perfis.split(",") if c.strip()}
    perfis = [p for p in PERFIS if not filtro or p.codigo in filtro]

    db = SessionLocal()
    grupo_por_id = dict(db.query(ExercicioDB.id_exercicio, ExercicioDB.grupo_muscular).all())

    carimbo = datetime.now().strftime("%Y%m%d_%H%M")
    modelo_slug = ia.MODELO_IA.replace(".", "-")
    pasta = os.path.join(os.path.dirname(os.path.abspath(__file__)), "resultados")
    os.makedirs(pasta, exist_ok=True)
    caminho_exec = os.path.join(pasta, f"execucoes_{modelo_slug}_{carimbo}.csv")
    caminho_presc = os.path.join(pasta, f"prescricoes_{modelo_slug}_{carimbo}.csv")

    colunas_exec = [
        "perfil", "rodada", "tentativa", "modelo", "aprovado", "motivo",
        "latencia_s", "tokens_entrada", "tokens_saida", "tokens_cache_lido",
        "tokens_cache_criado", "qtd_dias_pedidos", "qtd_dias_recebidos",
        "exercicios_total", "catalogo_tamanho", "bloqueados", "sob_cautela",
        "cautela_prescritos", "cautela_como_primeiro", "cautela_mais_de_um_no_dia",
        "cautela_havendo_alternativa", "grupos_treinados", "grupos_fora_do_foco",
        "grupos_do_foco_ausentes", "lista_grupos", "lista_ausentes", "justificativa",
    ]
    colunas_presc = [
        "perfil", "rodada", "dia", "posicao_no_dia", "id_exercicio",
        "grupo_muscular", "sob_cautela", "qtd_series", "qtd_repeticoes",
        "tempo_descanso_s", "objetivo", "dentro_da_faixa_literatura",
    ]

    f_exec = open(caminho_exec, "w", newline="", encoding="utf-8-sig")
    f_presc = open(caminho_presc, "w", newline="", encoding="utf-8-sig")
    w_exec = csv.DictWriter(f_exec, fieldnames=colunas_exec, delimiter=";")
    w_presc = csv.DictWriter(f_presc, fieldnames=colunas_presc, delimiter=";")
    w_exec.writeheader()
    w_presc.writeheader()

    linhas = []
    try:
        for perfil in perfis:
            carregar_lesoes(db, perfil)
            validos, avisos = ia._exercicios_permitidos(db, perfil)
            ids_validos = {e.id_exercicio for e in validos}
            grupos_sem_alternativa = ia._grupos_sem_alternativa(validos, avisos)
            catalogo = ia._montar_catalogo(validos, avisos)
            total_exercicios = db.query(ExercicioDB).count()

            print(f"\n=== {perfil.codigo} | {perfil.objetivo}/{perfil.foco}/"
                  f"{perfil.qtd_dias}d | catálogo {len(validos)}/{total_exercicios} "
                  f"({len(avisos)} sob cautela) ===")

            for rodada in range(1, args.repeticoes + 1):
                # Duas tentativas, como em produção: a segunda só ocorre se a
                # primeira for reprovada.
                for tentativa in (1, 2):
                    linha = {
                        "perfil": perfil.codigo,
                        "rodada": rodada,
                        "tentativa": tentativa,
                        "modelo": ia.MODELO_IA,
                        "qtd_dias_pedidos": perfil.qtd_dias,
                        "catalogo_tamanho": len(validos),
                        "bloqueados": total_exercicios - len(validos),
                        "sob_cautela": len(avisos),
                    }
                    try:
                        resposta, latencia = uma_chamada(client, perfil, catalogo)
                        plano = resposta.parsed_output
                        uso = resposta.usage

                        linha.update({
                            "latencia_s": round(latencia, 2),
                            "tokens_entrada": getattr(uso, "input_tokens", ""),
                            "tokens_saida": getattr(uso, "output_tokens", ""),
                            "tokens_cache_lido": getattr(uso, "cache_read_input_tokens", ""),
                            "tokens_cache_criado": getattr(uso, "cache_creation_input_tokens", ""),
                            "qtd_dias_recebidos": len(plano.dias),
                            "exercicios_total": sum(len(d.exercicios) for d in plano.dias),
                            "justificativa": (plano.justificativa or "").replace("\n", " "),
                        })
                        linha.update(auditar_cautela(plano, avisos, grupo_por_id, ids_validos))
                        linha.update(auditar_foco(plano, perfil.foco, grupo_por_id, ids_validos))

                        ia._validar(
                            plano, ids_validos, perfil.qtd_dias,
                            avisos, grupo_por_id, grupos_sem_alternativa,
                        )
                        linha["aprovado"] = "sim"
                        linha["motivo"] = ""

                        for dia in plano.dias:
                            for pos, ex in enumerate(dia.exercicios, start=1):
                                w_presc.writerow({
                                    "perfil": perfil.codigo,
                                    "rodada": rodada,
                                    "dia": dia.dia_treino,
                                    "posicao_no_dia": pos,
                                    "id_exercicio": ex.id_exercicio,
                                    "grupo_muscular": grupo_por_id.get(ex.id_exercicio, "?"),
                                    "sob_cautela": "sim" if ex.id_exercicio in avisos else "nao",
                                    "qtd_series": ex.qtd_series,
                                    "qtd_repeticoes": ex.qtd_repeticoes,
                                    "tempo_descanso_s": ex.tempo_descanso_s,
                                    "objetivo": perfil.objetivo,
                                    "dentro_da_faixa_literatura": "sim" if dentro_da_faixa(
                                        perfil.objetivo, ex.qtd_repeticoes, ex.tempo_descanso_s
                                    ) else "nao",
                                })
                    except Exception as exc:
                        linha["aprovado"] = "nao"
                        linha["motivo"] = classificar_motivo(exc)
                        linha.setdefault("latencia_s", "")
                        print(f"  {perfil.codigo} r{rodada} t{tentativa}: "
                              f"REPROVADO ({linha['motivo']}) — {exc}")

                    w_exec.writerow(linha)
                    f_exec.flush()
                    linhas.append(linha)

                    if linha["aprovado"] == "sim":
                        print(f"  {perfil.codigo} r{rodada} t{tentativa}: ok "
                              f"({linha.get('latencia_s')}s, "
                              f"{linha.get('exercicios_total')} exercícios)")
                        break
    finally:
        f_exec.close()
        f_presc.close()
        db.close()

    resumir(linhas, caminho_exec, caminho_presc)


def resumir(linhas: list, caminho_exec: str, caminho_presc: str) -> None:
    if not linhas:
        return

    chamadas = len(linhas)
    aprovadas = [l for l in linhas if l["aprovado"] == "sim"]
    latencias = [l["latencia_s"] for l in linhas if isinstance(l.get("latencia_s"), float)]

    rodadas = {}
    for l in linhas:
        rodadas.setdefault((l["perfil"], l["rodada"]), []).append(l)
    fichas_ia = sum(1 for tent in rodadas.values() if any(t["aprovado"] == "sim" for t in tent))

    motivos = {}
    for l in linhas:
        if l["aprovado"] == "nao":
            motivos[l["motivo"]] = motivos.get(l["motivo"], 0) + 1

    print("\n" + "=" * 62)
    print("RESUMO — números para o Quadro 5")
    print("=" * 62)
    print(f"Chamadas à API .............................. {chamadas}")
    print(f"Chamadas aprovadas na validação ............. {len(aprovadas)} "
          f"({100 * len(aprovadas) / chamadas:.1f}%)")
    print(f"Fichas com origem 'ia' (após até 2 tentativas) {fichas_ia}/{len(rodadas)} "
          f"({100 * fichas_ia / len(rodadas):.1f}%)")
    print(f"Fichas que cairiam no motor de regras ....... {len(rodadas) - fichas_ia}")
    if latencias:
        print(f"Latência média / mín / máx (s) .............. "
              f"{statistics.mean(latencias):.2f} / {min(latencias):.2f} / {max(latencias):.2f}")
    print("Motivos de reprovação ....................... "
          f"{motivos or 'nenhuma reprovação'}")

    somas = lambda chave: sum(l.get(chave) or 0 for l in aprovadas)
    print("\nAderência às regras de cautela (só instruídas, não validadas):")
    print(f"  exercícios sob ressalva prescritos ........ {somas('cautela_prescritos')}")
    print(f"  ...como primeiro exercício do dia ......... {somas('cautela_como_primeiro')}")
    print(f"  ...mais de um no mesmo dia ................ {somas('cautela_mais_de_um_no_dia')}")
    print(f"  ...havendo alternativa liberada ........... {somas('cautela_havendo_alternativa')}")
    print(f"\nGrupos musculares fora do foco declarado .... {somas('grupos_fora_do_foco')}")

    cache_lido = [l.get("tokens_cache_lido") for l in aprovadas if l.get("tokens_cache_lido")]
    if cache_lido:
        print(f"Tokens lidos do cache (mín/máx) ............. {min(cache_lido)} / {max(cache_lido)}")

    print(f"\nCSV por execução:  {caminho_exec}")
    print(f"CSV por exercício: {caminho_presc}")
    print("A coerência com as faixas da literatura está na coluna "
          "'dentro_da_faixa_literatura' do segundo CSV.")


if __name__ == "__main__":
    main()
