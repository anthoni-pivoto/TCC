from sqlalchemy import Column, BigInteger, VARCHAR
from sqlalchemy.orm import relationship
from models.base import Base
from models.associativas import tb_exercicio_lesao, tb_usuario_lesao

class LesaoDB(Base):
    __tablename__ = 'tb_lesoes'

    id_lesao = Column(BigInteger, primary_key=True, index=True)
    nm_lesao = Column(VARCHAR, nullable=False)

    # Relacionamentos usando strings para evitar importação circular
    usuarios = relationship("UsuarioDB", secondary=tb_usuario_lesao, back_populates="lesoes")
    exercicios = relationship("ExercicioDB", secondary=tb_exercicio_lesao, back_populates="lesoes_contraindicadas")


class ExercicioDB(Base):
    __tablename__ = 'tb_exercicios'

    id_exercicio = Column(BigInteger, primary_key=True, index=True)
    nm_exercicio = Column(VARCHAR, nullable=False)
    slug_firebase = Column(VARCHAR)

    # Relacionamento com as lesões que impedem este exercício
    lesoes_contraindicadas = relationship("LesaoDB", secondary=tb_exercicio_lesao, back_populates="exercicios")
    
    # Relacionamento com a tabela de treinos (N:N com atributos)
    treinos_associados = relationship("TreinoExercicioDB", back_populates="exercicio")