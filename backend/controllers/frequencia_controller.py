from datetime import datetime, timedelta
from sqlalchemy import func, cast, Date
from sqlalchemy.orm import Session
from models.frequencia_model import FrequenciaDB
from schemas.frequencia_schema import FrequenciaCreate, FrequenciaDiaResponse

_DIAS_PT = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']


def registrar_frequencia(db: Session, dados: FrequenciaCreate) -> FrequenciaDB:
    registro = FrequenciaDB(
        id_usuario=dados.id_usuario,
        treino_completo=dados.treino_completo,
        qtd_exercicios_concluidos=dados.qtd_exercicios_concluidos,
    )
    db.add(registro)
    db.commit()
    db.refresh(registro)
    return registro


def buscar_frequencia_semanal(db: Session, id_usuario: int) -> list[FrequenciaDiaResponse]:
    hoje = datetime.now().date()
    inicio = hoje - timedelta(days=6)

    # Soma exercícios por dia
    rows = (
        db.query(
            cast(FrequenciaDB.dt_registro, Date).label('dia'),
            func.sum(FrequenciaDB.qtd_exercicios_concluidos).label('total'),
        )
        .filter(
            FrequenciaDB.id_usuario == id_usuario,
            cast(FrequenciaDB.dt_registro, Date) >= inicio,
        )
        .group_by(cast(FrequenciaDB.dt_registro, Date))
        .all()
    )

    por_dia = {row.dia: int(row.total) for row in rows}

    resultado = []
    for i in range(7):
        data = inicio + timedelta(days=i)
        qtd = por_dia.get(data, 0)
        resultado.append(FrequenciaDiaResponse(
            data=data,
            dia_semana=_DIAS_PT[data.weekday()],
            treinou=qtd > 0,
            qtd_exercicios=qtd,
        ))
    return resultado
