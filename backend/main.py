from fastapi import FastAPI
from database import engine
from models.base import Base
# Importar para garantir que as tabelas sejam criadas no 200.19.1.18
from models import usuario_model, treino_model, associativas 
from views import usuario_view, treino_view

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Backend Treinos Personalizados")

app.include_router(usuario_view.router, prefix="/api")
app.include_router(treino_view.router, prefix="/api")

@app.get("/")
def root():
    return {"message": "API de Treinos do Toninho está online!"}