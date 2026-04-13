from fastapi import HTTPException
from sqlalchemy.orm import Session
from utils.auth_utils import get_password_hash
from models.usuario_model import UsuarioDB
from models.associativas import tb_usuario_lesao
from schemas.usuario_schema import UsuarioCreate, UsuarioLogin
from utils.auth_utils import verify_password

def cadastrar_novo_usuario(db: Session, user_data: UsuarioCreate):
    senha_criptografada = get_password_hash(user_data.pwd_usuario)
    
    novo_usuario = UsuarioDB(
        nm_usuario=user_data.nm_usuario,
        em_usuario=user_data.em_usuario,
        pwd_usuario=senha_criptografada,
        qtd_dias=user_data.qtd_dias,
        objetivo=user_data.objetivo,
        peso=user_data.peso,
        altura=user_data.altura,
        foco=user_data.foco
    )
    
    db.add(novo_usuario)
    db.commit()
    db.refresh(novo_usuario)

    if user_data.ids_lesoes:
        for lesao_id in user_data.ids_lesoes:
            statement = tb_usuario_lesao.insert().values(
                id_usuario=novo_usuario.id_usuario, 
                id_lesao=lesao_id
            )
            db.execute(statement)
        db.commit()

    return novo_usuario

def autenticar_usuario(db: Session, login_data: UsuarioLogin):
    usuario = db.query(UsuarioDB).filter(UsuarioDB.em_usuario == login_data.em_usuario).first()
    
    if not usuario or not verify_password(login_data.pwd_usuario, usuario.pwd_usuario):
        raise HTTPException(status_code=401, detail="E-mail ou senha incorretos")
        
    return usuario