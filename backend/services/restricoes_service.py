"""Contraindicações do usuário e o que elas deixam de fora do catálogo.

Vive fora do serviço de IA de propósito: quem consulta isso é a tela de perfil e
a de treinos, que não têm nada a ver com geração. O serviço de IA reaproveita a
mesma função para filtrar o catálogo antes de montar o prompt.
"""

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from models.associativas import tb_exercicio_lesao
from models.exercicio_model import ExercicioDB, LesaoDB
from models.usuario_model import UsuarioDB

# nome do grupo no banco -> como ele aparece para o usuário
ROTULOS_GRUPOS = {
    "abdutores": "abdutores",
    "adutores": "adutores",
    "biceps": "bíceps",
    "costas": "costas",
    "gluteos": "glúteos",
    "isquiotibiais": "isquiotibiais (posterior da coxa)",
    "ombro": "ombros",
    "panturrilha": "panturrilhas",
    "peito": "peito",
    "quadriceps": "quadríceps",
    "triceps": "tríceps",
}


def contraindicacoes(db: Session, usuario: UsuarioDB) -> tuple[set, dict]:
    """Separa as contraindicações do usuário nos dois níveis.

    Devolve os ids que saem do catálogo e, para os de cautela, os nomes das
    lesões que motivam o aviso.
    """
    ids_lesoes = {lesao.id_lesao for lesao in usuario.lesoes}
    if not ids_lesoes:
        return set(), {}

    linhas = db.execute(
        select(
            tb_exercicio_lesao.c.id_exercicio,
            tb_exercicio_lesao.c.nivel,
            LesaoDB.nm_lesao,
        )
        .join(LesaoDB, LesaoDB.id_lesao == tb_exercicio_lesao.c.id_lesao)
        .where(tb_exercicio_lesao.c.id_lesao.in_(ids_lesoes))
        .order_by(tb_exercicio_lesao.c.id_exercicio, LesaoDB.nm_lesao)
    ).all()

    bloqueados = {linha.id_exercicio for linha in linhas if linha.nivel == "bloqueio"}
    avisos = {}
    for linha in linhas:
        # Exercício bloqueado por outra lesão não precisa de aviso: não chega ao
        # catálogo de qualquer forma.
        if linha.nivel == "cautela" and linha.id_exercicio not in bloqueados:
            avisos.setdefault(linha.id_exercicio, []).append(linha.nm_lesao)
    return bloqueados, avisos


def grupos_sem_exercicio(db: Session, id_usuario: int) -> list[str]:
    """Grupos musculares que ficaram sem nenhum exercício liberado.

    É o caso em que o app não consegue prescrever nada seguro para uma região —
    a informação que justifica recomendar acompanhamento profissional.
    """
    usuario = (
        db.query(UsuarioDB)
        .options(joinedload(UsuarioDB.lesoes))
        .filter(UsuarioDB.id_usuario == id_usuario)
        .first()
    )
    if usuario is None:
        return []

    bloqueados, _ = contraindicacoes(db, usuario)
    if not bloqueados:
        return []

    todos = db.query(ExercicioDB.id_exercicio, ExercicioDB.grupo_muscular).all()
    com_exercicio = {g for i, g in todos if i not in bloqueados}
    zerados = {g for _, g in todos} - com_exercicio

    return sorted(ROTULOS_GRUPOS.get(g, g) for g in zerados)
