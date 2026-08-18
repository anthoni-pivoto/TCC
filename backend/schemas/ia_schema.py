from pydantic import BaseModel, ConfigDict, Field
from typing import List

# Contrato de saída da IA. Este schema é convertido em JSON Schema e enviado à
# API, que obriga a resposta a obedecê-lo — não há texto livre para parsear.
# As descrições dos campos vão junto e orientam o modelo, então valem tanto
# quanto o tipo.


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
