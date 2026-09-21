import logging
import os

from sqlalchemy.orm import Session, joinedload

from models.usuario_model import UsuarioDB
from models.exercicio_model import ExercicioDB
from schemas.ia_schema import PlanoTreino, plano_com_dias
from services.restricoes_service import contraindicacoes
from schemas.treino_schema import TreinoCreate, TreinoExercicioCreate
from controllers.treino_controller import criar_treino
from services.treino_service import gerar_treino_personalizado

logger = logging.getLogger(__name__)

MODELO_IA = os.getenv("IA_MODEL", "claude-opus-5")

# O effort só entra na requisição quando IA_EFFORT está definida. Nem todo modelo
# aceita o parâmetro — o Haiku 4.5 responde 400 se ele vier junto (a Models API
# reporta effort.supported=False para ele), e um 400 aqui cairia calado no motor
# de regras, que é justamente o que não queremos enquanto testamos a IA.
EFFORT_IA = os.getenv("IA_EFFORT") or None

MAX_TOKENS = 8000  # teto, não custo: cobre a resposta e o thinking de quem pensa
MIN_EXERCICIOS_DIA = 4
MAX_EXERCICIOS_DIA = 7

INSTRUCOES = """Você é um educador físico experiente montando fichas de treino de academia.

Regras invioláveis:
- Use SOMENTE os id_exercicio presentes no catálogo abaixo. Nunca invente um ID.
- Monte EXATAMENTE {dias} dias de treino, numerados de 1 a {dias}, sem pular
  nem repetir número. Não confunda com os 7 dias da semana.
- Cada dia deve ter entre {minimo} e {maximo} exercícios.
- Nunca repita o mesmo exercício dentro do mesmo dia.

Diretrizes de prescrição:
- Distribua o volume entre os dias para que nenhum grupo muscular seja treinado em
  excesso nem fique de fora do foco escolhido.
- Comece cada dia pelos exercícios mais exigentes e termine pelos mais isolados.
- Ajuste séries, repetições e descanso ao objetivo: cargas altas e descansos longos
  para força; volume moderado e descansos médios para hipertrofia; repetições altas
  e descansos curtos para emagrecimento e condicionamento.
- Considere o IMC ao calibrar volume e intensidade.

Sobre as restrições deste usuário:
- O catálogo já teve removidos os exercícios de contraindicação absoluta. Tudo
  que aparece nele é permitido.
- Linhas marcadas com CAUTELA têm contraindicação relativa à lesão citada na
  própria linha. Quatro condições valem para elas, e a resposta é rejeitada se
  qualquer uma for violada:
  1. use uma linha CAUTELA somente quando TODAS as linhas daquele grupo
     muscular forem CAUTELA. Havendo qualquer alternativa liberada no mesmo
     grupo, use a alternativa;
  2. no máximo uma por dia;
  3. nunca como primeiro exercício do dia;
  4. com menos séries que qualquer outro exercício do mesmo dia.
- Na justificativa, cite apenas lesões que constam no perfil do usuário. Não
  mencione lesões que ele não relatou.

CATÁLOGO (id | nome | grupo muscular | restrições):
{catalogo}"""


def gerar_treino_ia(db: Session, id_usuario: int) -> list:
    """Gera a ficha de treino via IA.

    Qualquer falha — chave ausente, rede, resposta reprovada na validação —
    cai no motor de regras deterministico, para que o usuário nunca fique sem treino.
    """
    for tentativa in (1, 2):
        try:
            return _gerar_com_ia(db, id_usuario)
        except Exception as exc:
            # Falha de validação costuma ser azar de amostragem: a segunda
            # tentativa custa centavos e evita entregar a ficha pobre do motor
            # de regras. Erro de configuração (chave ausente) repete igual, e a
            # segunda tentativa apenas confirma antes de desistir.
            logger.warning(
                "Geração por IA falhou para o usuário %s na tentativa %d (%s: %s).",
                id_usuario, tentativa, type(exc).__name__, exc,
            )

    logger.warning(
        "Usuário %s ficará com o treino do motor de regras.", id_usuario
    )
    return gerar_treino_personalizado(db, id_usuario)


def _gerar_com_ia(db: Session, id_usuario: int) -> list:
    if not os.getenv("ANTHROPIC_API_KEY"):
        raise RuntimeError("ANTHROPIC_API_KEY não configurada")

    from anthropic import Anthropic  # import tardio: app sobe sem a dependência

    usuario = (
        db.query(UsuarioDB)
        .options(joinedload(UsuarioDB.lesoes))
        .filter(UsuarioDB.id_usuario == id_usuario)
        .first()
    )
    if usuario is None:
        raise ValueError(f"Usuário {id_usuario} não encontrado")

    qtd_dias = usuario.qtd_dias or 3
    validos, avisos = _exercicios_permitidos(db, usuario)
    if not validos:
        raise ValueError("Nenhum exercício disponível após filtrar as lesões")

    ids_validos = {e.id_exercicio for e in validos}
    grupo_por_id = {e.id_exercicio: e.grupo_muscular for e in validos}
    grupos_sem_alternativa = _grupos_sem_alternativa(validos, avisos)

    # dict vazio quando não há effort: assim o parâmetro nem chega na requisição.
    ajuste_effort = {"output_config": {"effort": EFFORT_IA}} if EFFORT_IA else {}

    resposta = Anthropic().messages.parse(
        model=MODELO_IA,
        max_tokens=MAX_TOKENS,
        system=[{
            "type": "text",
            "text": INSTRUCOES.format(
                dias=qtd_dias,
                minimo=MIN_EXERCICIOS_DIA,
                maximo=MAX_EXERCICIOS_DIA,
                catalogo=_montar_catalogo(validos, avisos),
            ),
            "cache_control": {"type": "ephemeral"},
        }],
        messages=[{"role": "user", "content": _montar_perfil(usuario, qtd_dias)}],
        output_format=plano_com_dias(qtd_dias, usuario.objetivo),
        **ajuste_effort,
    )

    plano = resposta.parsed_output
    _validar(plano, ids_validos, qtd_dias, avisos, grupo_por_id, grupos_sem_alternativa)
    logger.info("Plano gerado por IA para o usuário %s: %s", id_usuario, plano.justificativa)

    return _persistir(db, id_usuario, plano)


def _exercicios_permitidos(db: Session, usuario: UsuarioDB) -> tuple[list, dict]:
    """Catálogo do usuário, sem os exercícios de contraindicação absoluta.

    A ordenação é fixa de propósito: o catálogo entra no bloco com cache_control,
    e o cache da API é casamento de prefixo byte a byte.
    """
    bloqueados, avisos = contraindicacoes(db, usuario)
    todos = (
        db.query(ExercicioDB)
        .order_by(ExercicioDB.grupo_muscular, ExercicioDB.id_exercicio)
        .all()
    )
    validos = [e for e in todos if e.id_exercicio not in bloqueados]

    zerados = {e.grupo_muscular for e in todos} - {e.grupo_muscular for e in validos}
    if zerados:
        # Não impede a geração, mas se o foco do usuário for um desses grupos a
        # ficha sai torta e o log explica o porquê.
        logger.warning(
            "Usuário %s: as lesões zeraram os grupos %s",
            usuario.id_usuario, sorted(zerados),
        )
    return validos, avisos


def _grupos_sem_alternativa(validos: list, avisos: dict) -> set:
    """Grupos em que todo exercício restante está sob ressalva.

    São os únicos em que a cautela pode ser usada: nos demais existe opção
    liberada para cobrir o mesmo músculo.
    """
    por_grupo = {}
    for e in validos:
        por_grupo.setdefault(e.grupo_muscular, []).append(e.id_exercicio)
    return {
        grupo for grupo, ids in por_grupo.items()
        if ids and all(i in avisos for i in ids)
    }


def _montar_catalogo(exercicios: list, avisos: dict) -> str:
    linhas = []
    for e in exercicios:
        linha = f"{e.id_exercicio} | {e.nm_exercicio} | {e.grupo_muscular}"
        if e.id_exercicio in avisos:
            linha += " | CAUTELA: " + ", ".join(avisos[e.id_exercicio])
        linhas.append(linha)
    return "\n".join(linhas)


def _montar_perfil(usuario: UsuarioDB, qtd_dias: int) -> str:
    lesoes = [lesao.nm_lesao for lesao in usuario.lesoes] or ["nenhuma"]
    linhas = [
        "Monte a ficha de treino para este usuário:",
        f"- Dias de treino por semana: {qtd_dias}",
        f"- Objetivo: {usuario.objetivo or 'não informado'}",
        f"- Foco: {usuario.foco or 'não informado'}",
        f"- Peso: {usuario.peso} kg",
        f"- Altura: {_altura_em_metros(usuario.altura)} m"
        if _altura_em_metros(usuario.altura) is not None
        else "- Altura: não informada",
    ]
    imc = _calcular_imc(usuario.peso, usuario.altura)
    if imc is not None:
        linhas.append(f"- IMC: {imc:.1f}")
    linhas.append(f"- Lesões/restrições relatadas: {', '.join(lesoes)}")
    return "\n".join(linhas)


def _altura_em_metros(altura):
    """O cadastro aceita 1.62 e 162; normaliza para metros antes de mostrar."""
    if not altura or altura <= 0:
        return None
    return round(altura / 100 if altura > 3 else altura, 2)


def _calcular_imc(peso, altura):
    metros = _altura_em_metros(altura)
    if not peso or metros is None:
        return None
    return peso / (metros ** 2)


def _validar(
    plano: PlanoTreino,
    ids_validos: set,
    qtd_dias: int,
    avisos: dict | None = None,
    grupo_por_id: dict | None = None,
    grupos_sem_alternativa: set | None = None,
) -> None:
    """Rede de segurança determinística sobre a resposta da IA.

    O JSON Schema garante o formato, não o conteúdo: um ID pode existir e ainda
    assim ser contraindicado, ou o plano pode vir com menos dias que o pedido.

    As quatro últimas verificações são as condições de uso do nível de cautela.
    Elas viviam apenas no texto das instruções, e a medição mostrou que o
    modelo as descumpria de forma sistemática: mais da metade das ressalvas
    prescritas tinha alternativa liberada no mesmo grupo, e o volume delas saía
    igual ou maior que o dos demais exercícios do dia. Instrução não é garantia.
    """
    avisos = avisos or {}
    grupo_por_id = grupo_por_id or {}
    grupos_sem_alternativa = grupos_sem_alternativa or set()

    if len(plano.dias) != qtd_dias:
        raise ValueError(f"IA retornou {len(plano.dias)} dias, esperado {qtd_dias}")

    numeros = sorted(dia.dia_treino for dia in plano.dias)
    if numeros != list(range(1, qtd_dias + 1)):
        raise ValueError(f"Numeração de dias inválida: {numeros}")

    for dia in plano.dias:
        ids = [e.id_exercicio for e in dia.exercicios]

        invalidos = set(ids) - ids_validos
        if invalidos:
            raise ValueError(
                f"Dia {dia.dia_treino}: exercícios inexistentes ou contraindicados {sorted(invalidos)}"
            )
        if len(ids) != len(set(ids)):
            raise ValueError(f"Dia {dia.dia_treino}: exercício repetido")
        if not MIN_EXERCICIOS_DIA <= len(ids) <= MAX_EXERCICIOS_DIA:
            raise ValueError(
                f"Dia {dia.dia_treino}: {len(ids)} exercícios, "
                f"fora da faixa {MIN_EXERCICIOS_DIA}-{MAX_EXERCICIOS_DIA}"
            )

        sob_ressalva = [e for e in dia.exercicios if e.id_exercicio in avisos]
        if not sob_ressalva:
            continue

        if len(sob_ressalva) > 1:
            raise ValueError(
                f"Dia {dia.dia_treino}: {len(sob_ressalva)} exercícios sob cautela, "
                f"no máximo 1 por dia"
            )
        if ids[0] in avisos:
            raise ValueError(
                f"Dia {dia.dia_treino}: exercício sob cautela abrindo a sessão"
            )

        ressalva = sob_ressalva[0]
        grupo = grupo_por_id.get(ressalva.id_exercicio)
        if grupo is not None and grupo not in grupos_sem_alternativa:
            raise ValueError(
                f"Dia {dia.dia_treino}: exercício sob cautela em {grupo}, "
                f"que tem alternativa liberada"
            )

        demais = [e.qtd_series for e in dia.exercicios if e is not ressalva]
        if demais and ressalva.qtd_series > min(demais):
            raise ValueError(
                f"Dia {dia.dia_treino}: exercício sob cautela com "
                f"{ressalva.qtd_series} séries, acima do mínimo do dia ({min(demais)})"
            )


def _persistir(db: Session, id_usuario: int, plano: PlanoTreino) -> list:
    """Grava o plano dia a dia, desfazendo o parcial se algum dia falhar."""
    treinos = []
    try:
        for dia in plano.dias:
            treino_data = TreinoCreate(
                id_usuario=id_usuario,
                dia_treino=dia.dia_treino,
                exercicios=[
                    TreinoExercicioCreate(**exercicio.model_dump())
                    for exercicio in dia.exercicios
                ],
            )
            treinos.append(
                criar_treino(
                    db, treino_data, origem="ia", justificativa=plano.justificativa
                )
            )
    except Exception:
        # criar_treino comita por dia; sem isso o fallback empilharia treinos
        # em cima dos dias já gravados.
        for treino in treinos:
            treino.st_ativo = False
        db.commit()
        raise

    return treinos
