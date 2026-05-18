from fastapi import HTTPException
from sqlalchemy.orm import Session
from utils.auth_utils import get_password_hash, verify_password
from models.usuario_model import UsuarioDB
from models.associativas import tb_usuario_lesao
from schemas.usuario_schema import UsuarioCreate, UsuarioLogin, UsuarioPreferenciasUpdate
from services.treino_service import gerar_treino_personalizado
from controllers.treino_controller import desativar_treinos_usuario

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

    gerar_treino_personalizado(db, novo_usuario.id_usuario)

    return novo_usuario

def atualizar_preferencias(db: Session, id_usuario: int, dados: UsuarioPreferenciasUpdate) -> UsuarioDB:
    usuario = db.query(UsuarioDB).filter(UsuarioDB.id_usuario == id_usuario).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")

    _CAMPOS_TREINO = {'qtd_dias', 'foco', 'objetivo'}
    update_data = dados.model_dump(exclude_none=True)

    regerar = any(
        campo in _CAMPOS_TREINO and getattr(usuario, campo) != valor
        for campo, valor in update_data.items()
    )

    for campo, valor in update_data.items():
        setattr(usuario, campo, valor)

    db.commit()
    db.refresh(usuario)

    if regerar:
        desativar_treinos_usuario(db, id_usuario)
        gerar_treino_personalizado(db, id_usuario)

    return usuario


def autenticar_usuario(db: Session, login_data: UsuarioLogin):
    usuario = db.query(UsuarioDB).filter(UsuarioDB.em_usuario == login_data.em_usuario).first()
    
    if not usuario or not verify_password(login_data.pwd_usuario, usuario.pwd_usuario):
        raise HTTPException(status_code=401, detail="E-mail ou senha incorretos")
        
    return usuario