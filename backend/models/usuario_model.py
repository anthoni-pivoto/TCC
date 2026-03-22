from sqlalchemy import Column, BigInteger, VARCHAR, Integer, REAL
from sqlalchemy.orm import relationship
from models.base import Base
from models.associativas import tb_usuario_lesao

class UsuarioDB(Base):
    __tablename__ = 'tb_usuario'

    id_usuario = Column(BigInteger, primary_key=True, index=True)
    nm_usuario = Column(VARCHAR, nullable=False)
    em_usuario = Column(VARCHAR, nullable=False, unique=True)
    pwd_usuario = Column(VARCHAR, nullable=False)
    qtd_dias = Column(Integer)
    objetivo = Column(VARCHAR)
    peso = Column(REAL)
    altura = Column(REAL)
    foco = Column(VARCHAR) 

    lesoes = relationship("LesaoDB", secondary=tb_usuario_lesao, back_populates="usuarios")
    treinos = relationship("TreinoDB", back_populates="usuario")