from sqlalchemy import Column, BigInteger, Integer, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from models.base import Base

class TreinoExercicioDB(Base):
    __tablename__ = 'tb_treino_exercicio'
    id_treino = Column(BigInteger, ForeignKey('tb_treino.id_treino'), primary_key=True)
    id_exercicio = Column(BigInteger, ForeignKey('tb_exercicios.id_exercicio'), primary_key=True)
    qtd_series = Column(Integer, nullable=False)
    tempo_descanso_s = Column(Integer, nullable=False)
    qtd_repeticoes = Column(Integer, nullable=False)

    treino = relationship("TreinoDB", back_populates="exercicios_associados")
    exercicio = relationship("ExercicioDB", back_populates="treinos_associados")

class TreinoDB(Base):
    __tablename__ = 'tb_treino'
    id_treino = Column(BigInteger, primary_key=True, index=True)
    id_usuario = Column(BigInteger, ForeignKey('tb_usuario.id_usuario'), nullable=False)
    dia_treino = Column(Integer, nullable=False)
    st_ativo = Column(Boolean, default=True, nullable=False)

    usuario = relationship("UsuarioDB", back_populates="treinos")
    exercicios_associados = relationship("TreinoExercicioDB", back_populates="treino")