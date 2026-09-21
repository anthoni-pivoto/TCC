"""Converte os CSVs da bateria nos quadros do capítulo 6.

    python avaliacao/consolidar.py                  # usa os CSVs mais recentes
    python avaliacao/consolidar.py execucoes_x.csv prescricoes_x.csv

Imprime Markdown pronto para colar no documento.
"""

import csv
import glob
import os
import statistics
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from schemas.ia_schema import FAIXAS_POR_OBJETIVO, FAIXA_PADRAO

PASTA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "resultados")

ROTULO_MOTIVO = {
    "qtd_dias_divergente": "quantidade de dias divergente do declarado",
    "numeracao_invalida": "numeração de dias inválida",
    "id_fora_do_catalogo": "identificador fora do catálogo autorizado",
    "exercicio_repetido": "exercício repetido no mesmo dia",
    "qtd_exercicios_fora_da_faixa": "quantidade de exercícios fora da faixa",
    "falha_na_api": "falha na chamada à API",
    "cautela_como_primeiro": "ressalva abrindo a sessão",
    "cautela_mais_de_um_no_dia": "mais de uma ressalva no mesmo dia",
    "cautela_havendo_alternativa": "ressalva havendo alternativa liberada",
    "cautela_sem_reducao_de_volume": "ressalva sem redução de volume",
    "outro": "outro",
}


def ler(caminho):
    with open(caminho, encoding="utf-8-sig") as f:
        return list(csv.DictReader(f, delimiter=";"))


def num(valor, padrao=0):
    try:
        return float(valor)
    except (TypeError, ValueError):
        return padrao


def main():
    if len(sys.argv) == 3:
        exec_csv, presc_csv = sys.argv[1], sys.argv[2]
    else:
        exec_csv = sorted(glob.glob(os.path.join(PASTA, "execucoes_*.csv")))[-1]
        presc_csv = sorted(glob.glob(os.path.join(PASTA, "prescricoes_*.csv")))[-1]

    execucoes = ler(exec_csv)
    prescricoes = ler(presc_csv)
    aprovadas = [l for l in execucoes if l["aprovado"] == "sim"]
    modelo = execucoes[0]["modelo"] if execucoes else "?"

    rodadas = {}
    for l in execucoes:
        rodadas.setdefault((l["perfil"], l["rodada"]), []).append(l)
    fichas_ia = sum(1 for t in rodadas.values() if any(x["aprovado"] == "sim" for x in t))

    primeira = [t[0] for t in rodadas.values()]
    ok_primeira = sum(1 for l in primeira if l["aprovado"] == "sim")

    motivos = {}
    for l in execucoes:
        if l["aprovado"] == "nao":
            motivos[l["motivo"]] = motivos.get(l["motivo"], 0) + 1

    lat = [num(l["latencia_s"]) for l in execucoes if l["latencia_s"]]
    soma = lambda c: int(sum(num(l.get(c)) for l in aprovadas))

    print(f"<!-- modelo: {modelo} | {exec_csv} -->\n")
    print("**Quadro 5 – Conformidade e desempenho da geração por Inteligência Artificial**\n")
    print("| Indicador | Resultado |")
    print("|---|---|")
    print(f"| Fichas geradas (perfis × repetições) | {len(rodadas)} |")
    print(f"| Chamadas à API (incluindo segundas tentativas) | {len(execucoes)} |")
    print(f"| Aprovadas na validação determinística | {len(aprovadas)} de {len(execucoes)} "
          f"({100 * len(aprovadas) / len(execucoes):.1f}%) |")
    print(f"| Aprovadas já na primeira tentativa | {ok_primeira} de {len(rodadas)} "
          f"({100 * ok_primeira / len(rodadas):.1f}%) |")
    print(f"| Fichas concluídas pelo caminho de IA | {fichas_ia} de {len(rodadas)} "
          f"({100 * fichas_ia / len(rodadas):.1f}%) |")
    print(f"| Fichas transferidas ao motor de regras | {len(rodadas) - fichas_ia} |")
    if motivos:
        detalhe = "; ".join(f"{ROTULO_MOTIVO.get(k, k)}: {v}" for k, v in
                            sorted(motivos.items(), key=lambda x: -x[1]))
        print(f"| Motivos de reprovação | {detalhe} |")
    else:
        print("| Motivos de reprovação | nenhuma reprovação registrada |")
    print(f"| Identificadores fora do catálogo autorizado | "
          f"{motivos.get('id_fora_do_catalogo', 0)} ocorrências |")
    print(f"| Exercícios repetidos no mesmo dia | "
          f"{motivos.get('exercicio_repetido', 0)} ocorrências |")
    print(f"| Divergência de quantidade ou numeração de dias | "
          f"{motivos.get('qtd_dias_divergente', 0) + motivos.get('numeracao_invalida', 0)} ocorrências |")
    if lat:
        print(f"| Tempo médio de resposta | {statistics.mean(lat):.1f} s |")
        print(f"| Tempo mínimo e máximo | {min(lat):.1f} s / {max(lat):.1f} s |")
        print(f"| Desvio padrão do tempo | {statistics.pstdev(lat):.1f} s |")
    print("\nFonte: Elaborado pelo autor (2026).\n")

    # ------------------------------------------------------------------
    print("**Quadro X – Aderência às regras de cautela (verificadas apenas por instrução)**\n")
    print("| Condição imposta ao modelo | Observado |")
    print("|---|---|")
    print(f"| Exercícios sob ressalva prescritos | {soma('cautela_prescritos')} |")
    print(f"| Prescritos havendo alternativa liberada no grupo | {soma('cautela_havendo_alternativa')} |")
    print(f"| Dias com mais de uma ressalva | {soma('cautela_mais_de_um_no_dia')} |")
    print(f"| Dias abertos por exercício sob ressalva | {soma('cautela_como_primeiro')} |")
    print("\nFonte: Elaborado pelo autor (2026).\n")

    # ------------------------------------------------------------------
    print("**Quadro Y – Coerência da prescrição com as faixas da literatura**\n")
    print("| Objetivo | Prescrições | Repetições (média) | Descanso (média) | Dentro da faixa |")
    print("|---|---|---|---|---|")
    for objetivo in ("forca", "hipertrofia", "emagrecimento", "condicionamento"):
        linhas = [p for p in prescricoes if p["objetivo"] == objetivo]
        if not linhas:
            continue
        reps = [num(p["qtd_repeticoes"]) for p in linhas]
        desc = [num(p["tempo_descanso_s"]) for p in linhas]
        # Recalculado aqui, e não lido do CSV, para que baterias gravadas sob
        # réguas diferentes sejam comparáveis entre si.
        faixa = FAIXAS_POR_OBJETIVO.get(objetivo, FAIXA_PADRAO)
        (r0, r1), (d0, d1) = faixa["reps"], faixa["descanso"]
        ok = sum(1 for p in linhas
                 if r0 <= num(p["qtd_repeticoes"]) <= r1
                 and d0 <= num(p["tempo_descanso_s"]) <= d1)
        print(f"| {objetivo} | {len(linhas)} | {statistics.mean(reps):.1f} "
              f"| {statistics.mean(desc):.0f} s | {ok} ({100 * ok / len(linhas):.0f}%) |")
    print("\nFonte: Elaborado pelo autor (2026).\n")

    # ------------------------------------------------------------------
    print("**Quadro Z – Resultados por perfil**\n")
    print("| Perfil | Catálogo | Sob cautela | Fichas ok | Tempo médio | Grupos do foco ignorados |")
    print("|---|---|---|---|---|---|")
    for perfil in sorted({l["perfil"] for l in execucoes}):
        do_perfil = [l for l in execucoes if l["perfil"] == perfil]
        ap = [l for l in do_perfil if l["aprovado"] == "sim"]
        rod = {l["rodada"] for l in do_perfil}
        ok = len({l["rodada"] for l in ap})
        lp = [num(l["latencia_s"]) for l in do_perfil if l["latencia_s"]]
        ign = int(sum(num(l.get("grupos_do_foco_ausentes")) for l in ap))
        base = do_perfil[0]
        print(f"| {perfil} | {base['catalogo_tamanho']}/39 (-{base['bloqueados']}) "
              f"| {base['sob_cautela']} | {ok}/{len(rod)} "
              f"| {statistics.mean(lp):.1f} s | {ign} |")
    print("\nFonte: Elaborado pelo autor (2026).\n")

    # ------------------------------------------------------------------
    cache_lido = [num(l["tokens_cache_lido"]) for l in aprovadas if l["tokens_cache_lido"]]
    entrada = [num(l["tokens_entrada"]) for l in aprovadas if l["tokens_entrada"]]
    saida = [num(l["tokens_saida"]) for l in aprovadas if l["tokens_saida"]]
    print("<!-- Tokens (para a discussão sobre cache na seção 5.6/6.3) -->")
    if entrada:
        print(f"entrada média: {statistics.mean(entrada):.0f} | "
              f"saída média: {statistics.mean(saida):.0f} | "
              f"cache lido: mín {min(cache_lido) if cache_lido else 0:.0f}, "
              f"máx {max(cache_lido) if cache_lido else 0:.0f}")

    ausentes = {}
    for l in aprovadas:
        for g in (l.get("lista_ausentes") or "").split("|"):
            if g:
                ausentes[g] = ausentes.get(g, 0) + 1
    if ausentes:
        print("<!-- Grupos do foco ignorados, por frequência: "
              + ", ".join(f"{k}={v}" for k, v in sorted(ausentes.items(), key=lambda x: -x[1]))
              + " -->")


if __name__ == "__main__":
    main()
