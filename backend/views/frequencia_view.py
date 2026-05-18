from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from controllers.frequencia_controller import registrar_frequencia, buscar_frequencia_semanal
from schemas.frequencia_schema import FrequenciaCreate, FrequenciaResponse, FrequenciaDiaResponse

router = APIRouter(prefix="/frequencias")


@router.post("/", response_model=FrequenciaResponse, status_code=201)
def post_registrar_frequencia(dados: FrequenciaCreate, db: Session = Depends(get_db)):
    return registrar_frequencia(db, dados)


@router.get("/usuario/{id_usuario}/semanal", response_model=List[FrequenciaDiaResponse])
def get_frequencia_semanal(id_usuario: int, db: Session = Depends(get_db)):
    return buscar_frequencia_semanal(db, id_usuario)
