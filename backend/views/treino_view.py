from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from controllers import treino_controller
from schemas.treino_schema import TreinoCreate, TreinoResponse

router = APIRouter(prefix="/treinos")

@router.post("/", response_model=TreinoResponse, status_code=201)
def post_criar_treino(treino: TreinoCreate, db: Session = Depends(get_db)):
    return treino_controller.criar_treino(db, treino)

@router.post("/gerar/{id_usuario}")
def post_gerar_treino(id_usuario: int, objetivo: str, db: Session = Depends(get_db)):
    return treino_controller.gerar_treino_automatico(db, id_usuario, objetivo)