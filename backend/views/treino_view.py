from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from controllers import treino_controller

router = APIRouter(prefix="/treinos")

@router.post("/gerar/{id_usuario}")
def post_gerar_treino(id_usuario: int, objetivo: str, db: Session = Depends(get_db)):
    return treino_controller.gerar_treino_automatico(db, id_usuario, objetivo)