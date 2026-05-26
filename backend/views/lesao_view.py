from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models.exercicio_model import LesaoDB
from schemas.lesao_schema import LesaoResponse

router = APIRouter(prefix="/lesoes")


@router.get("/", response_model=List[LesaoResponse])
def get_all_lesoes(db: Session = Depends(get_db)):
    return db.query(LesaoDB).order_by(LesaoDB.id_lesao).all()
