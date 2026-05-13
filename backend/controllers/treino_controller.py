from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload
from models.treino_model import TreinoDB, TreinoExercicioDB
from models.exercicio_model import ExercicioDB
from schemas.treino_schema import TreinoCreate, TreinoDetalhadoResponse, ExercicioDetalhadoResponse

def criar_treino(db: Session, treino_data: TreinoCreate) -> TreinoDB:
    ids_exercicios = [e.id_exercicio for e in treino_data.exercicios]
    exercicios_existentes = db.query(ExercicioDB.id_exercicio).filter(
        ExercicioDB.id_exercicio.in_(ids_exercicios)
    ).all()
    ids_encontrados = {row.id_exercicio for row in exercicios_existentes}
    ids_invalidos = set(ids_exercicios) - ids_encontrados
    if ids_invalidos:
        raise HTTPException(status_code=404, detail=f"Exercícios não encontrados: {sorted(ids_invalidos)}")

    novo_treino = TreinoDB(
        id_usuario=treino_data.id_usuario,
        dia_treino=treino_data.dia_treino,
        st_ativo=True
    )
    db.add(novo_treino)
    db.flush()

    for exercicio_data in treino_data.exercicios:
        associacao = TreinoExercicioDB(
            id_treino=novo_treino.id_treino,
            id_exercicio=exercicio_data.id_exercicio,
            qtd_series=exercicio_data.qtd_series,
            tempo_descanso_s=exercicio_data.tempo_descanso_s,
            qtd_repeticoes=exercicio_data.qtd_repeticoes
        )
        db.add(associacao)

    db.commit()
    db.refresh(novo_treino)
    return novo_treino

def buscar_treinos_usuario(db: Session, id_usuario: int) -> list[TreinoDetalhadoResponse]:
    treinos = (
        db.query(TreinoDB)
        .options(
            joinedload(TreinoDB.exercicios_associados).joinedload(TreinoExercicioDB.exercicio)
        )
        .filter(TreinoDB.id_usuario == id_usuario, TreinoDB.st_ativo == True)
        .order_by(TreinoDB.dia_treino)
        .all()
    )

    resultado = []
    for treino in treinos:
        exercicios = [
            ExercicioDetalhadoResponse(
                id_exercicio=te.id_exercicio,
                nm_exercicio=te.exercicio.nm_exercicio,
                slug_firebase=te.exercicio.slug_firebase or '',
                grupo_muscular=te.exercicio.grupo_muscular,
                qtd_series=te.qtd_series,
                qtd_repeticoes=te.qtd_repeticoes,
                tempo_descanso_s=te.tempo_descanso_s,
            )
            for te in treino.exercicios_associados
        ]
        resultado.append(
            TreinoDetalhadoResponse(
                id_treino=treino.id_treino,
                dia_treino=treino.dia_treino,
                st_ativo=treino.st_ativo,
                exercicios=exercicios,
            )
        )
    return resultado


def gerar_treino_automatico(db: Session, id_usuario: int, objetivo: str):
    # aqui vira logica da geracao dos treinos
    # Exemplo de inserção de cabeçalho de treino:
    novo_treino = TreinoDB(id_usuario=id_usuario, dia_treino=1, st_ativo=True)
    db.add(novo_treino)
    db.commit()
    db.refresh(novo_treino)
    return novo_treino