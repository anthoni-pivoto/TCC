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


def resumo_restricoes(db: Session, id_usuario: int) -> dict:
    """Tudo o que o aviso das telas precisa saber sobre as lesões do usuário.

    O aviso aparece para quem marcou qualquer lesão, e não só para quem ficou
    com uma região inteira sem exercício: mesmo quando sobra o que treinar, o
    usuário precisa saber quais músculos o app passou a tratar com cuidado.

    - `lesoes`: o que ele marcou, já sem a opção "Nenhuma".
    - `grupos_afetados`: músculos com ao menos um exercício restrito (bloqueio
      ou cautela) por essas lesões.
    - `grupos_sem_exercicio`: subconjunto em que nada sobrou — o caso grave.
    """
    vazio = {"lesoes": [], "grupos_afetados": [], "grupos_sem_exercicio": []}

    usuario = (
        db.query(UsuarioDB)
        .options(joinedload(UsuarioDB.lesoes))
        .filter(UsuarioDB.id_usuario == id_usuario)
        .first()
    )
    if usuario is None:
        return vazio

    # "Nenhuma" existe só para o usuário conseguir dizer que não tem lesão; ela
    # não restringe nada e não pode disparar o aviso.
    lesoes = sorted(
        lesao.nm_lesao
        for lesao in usuario.lesoes
        if lesao.nm_lesao.strip().lower() != "nenhuma"
    )
    if not lesoes:
        return vazio

    bloqueados, avisos = contraindicacoes(db, usuario)
    restritos = bloqueados | set(avisos)

    todos = db.query(ExercicioDB.id_exercicio, ExercicioDB.grupo_muscular).all()

    afetados = {g for i, g in todos if i in restritos}
    com_exercicio = {g for i, g in todos if i not in bloqueados}
    zerados = {g for _, g in todos if g in afetados} - com_exercicio

    def rotular(grupos):
        return sorted(ROTULOS_GRUPOS.get(g, g) for g in grupos)

    return {
        "lesoes": lesoes,
        "grupos_afetados": rotular(afetados),
        "grupos_sem_exercicio": rotular(zerados),
    }
