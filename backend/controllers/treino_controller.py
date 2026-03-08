from sqlalchemy.orm import Session
from models.treino_model import TreinoDB, TreinoExercicioDB

def gerar_treino_automatico(db: Session, id_usuario: int, objetivo: str):
    # aqui vira logica da geracao dos treinos
    
    # Exemplo de inserção de cabeçalho de treino:
    novo_treino = TreinoDB(id_usuario=id_usuario, dia_treino=1, st_ativo=True)
    db.add(novo_treino)
    db.commit()
    db.refresh(novo_treino)
    
    return novo_treino