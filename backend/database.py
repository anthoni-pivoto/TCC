import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

load_dotenv()

# 1. URL da base de dados vinda do .env
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL_LOCAL")

if not SQLALCHEMY_DATABASE_URL:
    raise ValueError("A variável DATABASE_URL_LOCAL não foi encontrada no arquivo .env")

# 2. Iniciar o engine e a sessão do SQLAlchemy
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()