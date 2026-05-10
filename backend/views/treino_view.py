from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from controllers import treino_controller
from schemas.treino_schema import TreinoCreate, TreinoResponse, TreinoDetalhadoResponse

router = APIRouter(prefix="/treinos")

@router.get("/usuario/{id_usuario}", response_model=List[TreinoDetalhadoResponse])
def get_treinos_usuario(id_usuario: int, db: Session = Depends(get_db)):
    return treino_controller.buscar_treinos_usuario(db, id_usuario)

@router.post("/", response_model=TreinoResponse, status_code=201)
def post_criar_treino(treino: TreinoCreate, db: Session = Depends(get_db)):
    return treino_controller.criar_treino(db, treino)

@router.post("/gerar/{id_usuario}")
def post_gerar_treino(id_usuario: int, objetivo: str, db: Session = Depends(get_db)):
    return treino_controller.gerar_treino_automatico(db, id_usuario, objetivo)