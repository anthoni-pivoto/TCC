from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from models.base import Base
from database import engine
from views import usuario_view, treino_view

# 1. Instancia o FastAPI
app = FastAPI()

# 2. Config middleware CORS para permitir requisições do frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. Rotas
app.include_router(usuario_view.router, prefix="/api")
app.include_router(treino_view.router, prefix="/api")

@app.get("/")
def home():
    return {"message": "Backend do TCC rodando!"}