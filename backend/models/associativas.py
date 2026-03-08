from sqlalchemy import Table, Column, BigInteger, ForeignKey
from models.base import Base

tb_usuario_lesao = Table(
    'tb_usuario_lesao', Base.metadata,
    Column('id_usuario', BigInteger, ForeignKey('tb_usuario.id_usuario'), primary_key=True),
    Column('id_lesao', BigInteger, ForeignKey('tb_lesoes.id_lesao'), primary_key=True)
)

tb_exercicio_lesao = Table(
    'tb_exercicio_lesao', Base.metadata,
    Column('id_lesao', BigInteger, ForeignKey('tb_lesoes.id_lesao'), primary_key=True),
    Column('id_exercicio', BigInteger, ForeignKey('tb_exercicios.id_exercicio'), primary_key=True)
)