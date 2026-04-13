from pydantic import BaseModel, EmailStr
from typing import List, Optional

class UsuarioCreate(BaseModel):
    nm_usuario: str
    em_usuario: EmailStr
    pwd_usuario: str
    qtd_dias: int
    objetivo: str
    peso: float
    altura: float
    foco: str
    ids_lesoes: List[int] = []

class UsuarioResponse(BaseModel):
    id_usuario: int
    nm_usuario: str
    em_usuario: str
    
    class Config:
        from_attributes = True
        
class UsuarioLogin(BaseModel):
    em_usuario: EmailStr
    pwd_usuario: str