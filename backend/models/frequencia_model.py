from sqlalchemy import Column, BigInteger, Integer, Boolean, TIMESTAMP, ForeignKey, Sequence, func
from sqlalchemy.orm import relationship
from models.base import Base

id_frequencia_seq = Sequence('tb_frequencia_id_freq_seq', schema='public')


class FrequenciaDB(Base):
    __tablename__ = 'tb_frequencia'

    id_frequencia             = Column(BigInteger, id_frequencia_seq, primary_key=True,
                                       server_default=id_frequencia_seq.next_value())
    id_usuario                = Column(BigInteger, ForeignKey('tb_usuario.id_usuario'), nullable=False)
    dt_registro               = Column(TIMESTAMP, nullable=False, server_default=func.now())
    treino_completo           = Column(Boolean, nullable=False, default=False)
    qtd_exercicios_concluidos = Column(Integer, nullable=False, default=0)

    usuario = relationship("UsuarioDB", back_populates="frequencias")
