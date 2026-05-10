import math
from sqlalchemy.orm import Session, joinedload
from models.usuario_model import UsuarioDB
from models.exercicio_model import ExercicioDB
from controllers.treino_controller import criar_treino
from schemas.treino_schema import TreinoCreate, TreinoExercicioCreate

# Splits: foco -> qtd_dias -> lista de dias (cada dia = lista de grupos musculares)
SPLITS = {
    "superiores": {
        2: [
            ["peito", "triceps", "ombro"],
            ["costas", "biceps"],
        ],
        3: [
            ["peito", "triceps"],
            ["costas", "biceps"],
            ["ombro"],
        ],
        4: [
            ["peito", "triceps"],
            ["costas", "biceps"],
            ["ombro"],
            ["peito", "costas"],
        ],
        5: [
            ["peito", "triceps"],
            ["costas", "biceps"],
            ["ombro"],
            ["peito"],
            ["costas"],
        ],
    },
    "inferiores": {
        2: [
            ["quadriceps", "gluteos", "panturrilha"],
            ["isquiotibiais", "adutores", "abdutores"],
        ],
        3: [
            ["quadriceps", "panturrilha"],
            ["isquiotibiais", "gluteos"],
            ["adutores", "abdutores"],
        ],
        4: [
            ["quadriceps"],
            ["isquiotibiais", "gluteos"],
            ["adutores", "abdutores"],
            ["quadriceps", "panturrilha"],
        ],
        5: [
            ["quadriceps"],
            ["isquiotibiais"],
            ["gluteos"],
            ["adutores", "abdutores"],
            ["quadriceps", "panturrilha"],
        ],
    },
    "full_body": {
        2: [
            ["peito", "costas", "quadriceps", "panturrilha"],
            ["ombro", "biceps", "triceps", "isquiotibiais", "gluteos"],
        ],
        3: [
            ["peito", "triceps", "quadriceps"],
            ["costas", "biceps", "isquiotibiais"],
            ["ombro", "gluteos", "panturrilha"],
        ],
        4: [
            ["peito", "triceps", "quadriceps"],
            ["costas", "biceps", "isquiotibiais"],
            ["ombro", "gluteos"],
            ["peito", "costas", "panturrilha"],
        ],
        5: [
            ["peito", "triceps"],
            ["costas", "biceps"],
            ["quadriceps", "gluteos"],
            ["ombro", "isquiotibiais"],
            ["adutores", "abdutores", "panturrilha"],
        ],
    },
}

# Parâmetros de séries/reps/descanso por objetivo
PARAMS_OBJETIVO = {
    "hipertrofia":     {"qtd_series": 4, "qtd_repeticoes": 10, "tempo_descanso_s": 60},
    "emagrecimento":   {"qtd_series": 3, "qtd_repeticoes": 15, "tempo_descanso_s": 30},
    "forca":           {"qtd_series": 5, "qtd_repeticoes":  5, "tempo_descanso_s": 120},
    "condicionamento": {"qtd_series": 3, "qtd_repeticoes": 12, "tempo_descanso_s": 45},
}

EXERCICIOS_POR_DIA = 5  # total alvo de exercícios por dia


def gerar_treino_personalizado(db: Session, id_usuario: int) -> list:
    usuario: UsuarioDB = (
        db.query(UsuarioDB)
        .options(
            joinedload(UsuarioDB.lesoes),
        )
        .filter(UsuarioDB.id_usuario == id_usuario)
        .first()
    )

    # IDs das lesões do usuário
    ids_lesoes_usuario = {lesao.id_lesao for lesao in usuario.lesoes}

    # Todos os exercícios com suas lesões contraindicadas carregadas
    todos_exercicios = (
        db.query(ExercicioDB)
        .options(joinedload(ExercicioDB.lesoes_contraindicadas))
        .all()
    )

    # Remove exercícios contraindicados pelas lesões do usuário
    exercicios_validos = [
        e for e in todos_exercicios
        if not any(l.id_lesao in ids_lesoes_usuario for l in e.lesoes_contraindicadas)
    ]

    # Agrupa por grupo muscular
    por_grupo: dict[str, list[ExercicioDB]] = {}
    for e in exercicios_validos:
        por_grupo.setdefault(e.grupo_muscular, []).append(e)

    # Determina split com fallback para full_body / 3 dias
    foco = usuario.foco or "full_body"
    qtd_dias = usuario.qtd_dias or 3

    splits_foco = SPLITS.get(foco, SPLITS["full_body"])
    # Usa o qtd_dias mais próximo disponível se o exato não existir
    dias_disponiveis = sorted(splits_foco.keys())
    qtd_dias_real = min(dias_disponiveis, key=lambda d: abs(d - qtd_dias))
    split = splits_foco[qtd_dias_real]

    # Parâmetros do objetivo com fallback
    params = PARAMS_OBJETIVO.get(usuario.objetivo, PARAMS_OBJETIVO["hipertrofia"])

    treinos_criados = []
    for dia_idx, grupos_do_dia in enumerate(split, start=1):
        qtd_por_grupo = max(1, math.ceil(EXERCICIOS_POR_DIA / len(grupos_do_dia)))

        exercicios_do_dia: list[TreinoExercicioCreate] = []
        for grupo in grupos_do_dia:
            selecionados = por_grupo.get(grupo, [])[:qtd_por_grupo]
            for e in selecionados:
                exercicios_do_dia.append(
                    TreinoExercicioCreate(
                        id_exercicio=e.id_exercicio,
                        **params,
                    )
                )

        if not exercicios_do_dia:
            continue

        treino_data = TreinoCreate(
            id_usuario=id_usuario,
            dia_treino=dia_idx,
            exercicios=exercicios_do_dia,
        )
        treinos_criados.append(criar_treino(db, treino_data))

    return treinos_criados
