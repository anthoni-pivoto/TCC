from pydantic import BaseModel
from typing import List

class TreinoExercicioCreate(BaseModel):
    id_exercicio: int
    qtd_series: int
    tempo_descanso_s: int
    qtd_repeticoes: int

class TreinoCreate(BaseModel):
    id_usuario: int
    dia_treino: int
    exercicios: List[TreinoExercicioCreate]

class TreinoExercicioResponse(BaseModel):
    id_exercicio: int
    qtd_series: int
    tempo_descanso_s: int
    qtd_repeticoes: int

    class Config:
        from_attributes = True

class TreinoResponse(BaseModel):
    id_treino: int
    id_usuario: int
    dia_treino: int
    st_ativo: bool
    exercicios_associados: List[TreinoExercicioResponse]

    class Config:
        from_attributes = True
