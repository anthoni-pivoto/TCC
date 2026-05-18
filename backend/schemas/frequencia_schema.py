from pydantic import BaseModel
from datetime import datetime, date


class FrequenciaCreate(BaseModel):
    id_usuario: int
    treino_completo: bool
    qtd_exercicios_concluidos: int


class FrequenciaResponse(BaseModel):
    id_frequencia: int
    id_usuario: int
    dt_registro: datetime
    treino_completo: bool
    qtd_exercicios_concluidos: int

    class Config:
        from_attributes = True


class FrequenciaDiaResponse(BaseModel):
    data: date
    dia_semana: str
    treinou: bool
    qtd_exercicios: int
