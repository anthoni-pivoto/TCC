from pydantic import BaseModel, ConfigDict, Field, create_model
from typing import Annotated, List

# Contrato de saída da IA. Este schema é convertido em JSON Schema e enviado à
# API, que obriga a resposta a obedecê-lo — não há texto livre para parsear.
# As descrições dos campos vão junto e orientam o modelo, então valem tanto
# quanto o tipo.


# Faixas de série, repetição e descanso por objetivo, conforme Fleck e Kraemer
# (2017) e as diretrizes do ACSM (2021) para praticantes iniciantes e
# intermediários, que é o público do aplicativo.
FAIXAS_POR_OBJETIVO = {
    "forca":           {"reps": (4, 8),   "descanso": (120, 240)},
    "hipertrofia":     {"reps": (8, 12),  "descanso": (45, 120)},
    "emagrecimento":   {"reps": (12, 20), "descanso": (15, 60)},
    "condicionamento": {"reps": (12, 20), "descanso": (15, 60)},
}

# Cadastros antigos trazem objetivos fora da lista atual; nesses casos vale a
# faixa ampla, que é o comportamento anterior à restrição por objetivo.
FAIXA_PADRAO = {"reps": (3, 30), "descanso": (15, 240)}


class ExercicioPrescrito(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id_exercicio: int = Field(
        description="ID do exercício. Obrigatoriamente um dos IDs do catálogo fornecido."
    )
    qtd_series: int = Field(ge=1, le=6, description="Número de séries.")
    qtd_repeticoes: int = Field(
        ge=3, le=30,
        description="Repetições por série. Baixas para força, altas para resistência.",
    )
    tempo_descanso_s: int = Field(
        ge=15, le=240, description="Descanso entre séries, em segundos."
    )


class DiaTreino(BaseModel):
    model_config = ConfigDict(extra="forbid")

    dia_treino: int = Field(
        ge=1, le=7,
        description="Número sequencial do dia, começando em 1 e sem pular números.",
    )
    foco_do_dia: str = Field(
        description="Rótulo curto dos grupos trabalhados, ex.: 'Peito e Tríceps'."
    )
    exercicios: List[ExercicioPrescrito]


class PlanoTreino(BaseModel):
    model_config = ConfigDict(extra="forbid")

    justificativa: str = Field(
        description=(
            "Em 2 ou 3 frases, por que esta divisão atende ao objetivo, ao perfil "
            "físico e às restrições do usuário."
        )
    )
    dias: List[DiaTreino]


def plano_com_dias(qtd_dias: int, objetivo: str | None = None) -> type[PlanoTreino]:
    """Variação de PlanoTreino ajustada ao usuário: dias exatos e faixas do objetivo.

    Duas exigências que antes viviam só no texto do prompt passam por aqui.

    A quantidade de dias muda por usuário, então não dá para fixá-la na classe.
    Sem este limite o modelo às vezes devolvia 7 dias para quem treina 4 — a
    validação reprovava e o usuário caía no motor de regras.

    As faixas de repetição e descanso seguiram o mesmo caminho depois que a
    medição mostrou o problema: com a instrução apenas textual ("cargas altas e
    descansos longos para força"), 25% das prescrições de força saíam com 8 a 15
    repetições, faixa de hipertrofia. O modelo acertava onde havia referência
    numérica e errava onde não havia.
    """
    faixa = FAIXAS_POR_OBJETIVO.get(objetivo or "", FAIXA_PADRAO)
    rep_min, rep_max = faixa["reps"]
    desc_min, desc_max = faixa["descanso"]

    exercicio = create_model(
        "ExercicioPrescrito_%s" % (objetivo or "padrao"),
        __base__=ExercicioPrescrito,
        qtd_repeticoes=(
            Annotated[
                int,
                Field(
                    ge=rep_min, le=rep_max,
                    description="Repetições por série, entre %d e %d para este objetivo."
                                % (rep_min, rep_max),
                ),
            ],
            ...,
        ),
        tempo_descanso_s=(
            Annotated[
                int,
                Field(
                    ge=desc_min, le=desc_max,
                    description="Descanso entre séries, entre %d e %d segundos."
                                % (desc_min, desc_max),
                ),
            ],
            ...,
        ),
    )

    dia = create_model(
        "DiaTreino_%s" % (objetivo or "padrao"),
        __base__=DiaTreino,
        exercicios=(List[exercicio], ...),
    )

    return create_model(
        "PlanoTreino%dDias" % qtd_dias,
        __base__=PlanoTreino,
        dias=(
            Annotated[
                List[dia],
                Field(
                    min_length=qtd_dias,
                    max_length=qtd_dias,
                    description=(
                        "Exatamente %d dias de treino, numerados de 1 a %d."
                        % (qtd_dias, qtd_dias)
                    ),
                ),
            ],
            ...,
        ),
    )
