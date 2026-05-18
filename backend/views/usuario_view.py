from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from schemas.usuario_schema import UsuarioCreate, UsuarioResponse, UsuarioLogin, UsuarioPerfilResponse, UsuarioPreferenciasUpdate

from controllers import usuario_controller 

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])

@router.post("/", response_model=UsuarioResponse)
def criar_usuario(usuario: UsuarioCreate, db: Session = Depends(get_db)):
    try:
        novo_usuario = usuario_controller.cadastrar_novo_usuario(db, usuario)
        return novo_usuario
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Erro ao cadastrar: {str(e)}")
    
@router.post("/login", response_model=UsuarioResponse)
def login_usuario(login_data: UsuarioLogin, db: Session = Depends(get_db)):
    usuario_logado = usuario_controller.autenticar_usuario(db, login_data)
    return usuario_logado

@router.get("/{id_usuario}", response_model=UsuarioPerfilResponse)
def get_perfil_usuario(id_usuario: int, db: Session = Depends(get_db)):
    from models.usuario_model import UsuarioDB
    usuario = db.query(UsuarioDB).filter(UsuarioDB.id_usuario == id_usuario).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return usuario

@router.put("/{id_usuario}", response_model=UsuarioPerfilResponse)
def put_preferencias_usuario(id_usuario: int, dados: UsuarioPreferenciasUpdate, db: Session = Depends(get_db)):
    return usuario_controller.atualizar_preferencias(db, id_usuario, dados)