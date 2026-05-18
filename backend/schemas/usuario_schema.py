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

class UsuarioPerfilResponse(BaseModel):
    id_usuario: int
    nm_usuario: str
    em_usuario: str
    qtd_dias: Optional[int]
    objetivo: Optional[str]
    foco: Optional[str]
    peso: Optional[float]
    altura: Optional[float]

    class Config:
        from_attributes = True
        
class UsuarioLogin(BaseModel):
    em_usuario: EmailStr
    pwd_usuario: str

class UsuarioPreferenciasUpdate(BaseModel):
    qtd_dias: Optional[int] = None
    objetivo: Optional[str] = None
    foco: Optional[str] = None
    peso: Optional[float] = None
    altura: Optional[float] = None