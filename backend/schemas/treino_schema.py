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

# --- Resposta detalhada (com nome do exercício) usada na home ---

class ExercicioDetalhadoResponse(BaseModel):
    id_exercicio: int
    nm_exercicio: str
    slug_firebase: str
    grupo_muscular: str
    qtd_series: int
    qtd_repeticoes: int
    tempo_descanso_s: int

class TreinoDetalhadoResponse(BaseModel):
    id_treino: int
    dia_treino: int
    st_ativo: bool
    exercicios: List[ExercicioDetalhadoResponse]
