import sys
import os

# Metodo para garantir que o Python encontre os modulos sem erros
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models.exercicio_model import ExercicioDB, LesaoDB 

def popular_banco():
    db = SessionLocal()
    try:
        print("🚀 Iniciando população do banco de dados local (PostgreSQL)...")

        # 1. POPULAR LESÕES 
        lesoes_iniciais = [
            {"nm_lesao": "Nenhuma"},
            
            # Coluna e Tronco
            {"nm_lesao": "Hérnia de Disco"},
            {"nm_lesao": "Lombalgia (Dor Lombar)"},
            {"nm_lesao": "Hérnia de Disco Cervical"},
            {"nm_lesao": "Lesão na Coluna Torácica"},
            {"nm_lesao": "Escoliose Acentuada"},

            # Membros Inferiores
            {"nm_lesao": "Lesão no Joelho"},
            {"nm_lesao": "Condromalácia"},
            {"nm_lesao": "Tendinite Patelar"},
            {"nm_lesao": "Lesão de Ligamento (LCA/LCP)"},
            {"nm_lesao": "Instabilidade de Tornozelo"},
            {"nm_lesao": "Fascite Plantar"},
            {"nm_lesao": "Tendinite de Aquiles"},
            {"nm_lesao": "Pubalgia / Dor na Virilha"},
            {"nm_lesao": "Bursite Trocantérica (Quadril)"},

            # Membros Superiores
            {"nm_lesao": "Tendinite no Ombro"},
            {"nm_lesao": "Lesão no Manguito Rotador"},
            {"nm_lesao": "Síndrome do Impacto (Ombro)"},
            {"nm_lesao": "Bursite no Ombro"},
            {"nm_lesao": "Epicondilite Lateral (Cotovelo)"},
            {"nm_lesao": "Epicondilite Medial (Cotovelo)"},
            {"nm_lesao": "Tendinite no Pulso / Síndrome do Túnel do Carpo"},
            
            # Outros
            {"nm_lesao": "Estiramento Muscular Recente"},
            {"nm_lesao": "Pós-Operatório Recente"}
        ]

        for item in lesoes_iniciais:
            existe = db.query(LesaoDB).filter(LesaoDB.nm_lesao == item["nm_lesao"]).first()
            if not existe:
                db.add(LesaoDB(**item))
                print(f"✅ Lesão adicionada: {item['nm_lesao']}")

        # 2. POPULAR EXERCÍCIOS
        exercicios_iniciais = [
            # --- Perna e Glúteos ---
            {"nm_exercicio": "Agachamento Livre",       "slug_firebase": "agachamento-livre",        "grupo_muscular": "quadriceps"},
            {"nm_exercicio": "Leg Press",               "slug_firebase": "leg-press",                "grupo_muscular": "quadriceps"},
            {"nm_exercicio": "Leg Press Horizontal",    "slug_firebase": "leg-press-horizontal",     "grupo_muscular": "quadriceps"},
            {"nm_exercicio": "Cadeira Extensora",       "slug_firebase": "cadeira-extensora",        "grupo_muscular": "quadriceps"},
            {"nm_exercicio": "Afundo",                  "slug_firebase": "afundo",                   "grupo_muscular": "quadriceps"},
            {"nm_exercicio": "Mesa Flexora",            "slug_firebase": "mesa-flexora",             "grupo_muscular": "isquiotibiais"},
            {"nm_exercicio": "Stiff",                   "slug_firebase": "stiff",                    "grupo_muscular": "isquiotibiais"},
            {"nm_exercicio": "Elevação Pélvica",        "slug_firebase": "elevacao-pelvica",         "grupo_muscular": "gluteos"},
            {"nm_exercicio": "Cadeira Adutora (Fecha)", "slug_firebase": "cadeira-adutora-fecha",    "grupo_muscular": "adutores"},
            {"nm_exercicio": "Cadeira Abdutora (Abre)", "slug_firebase": "cadeira-abdutora-abre",    "grupo_muscular": "abdutores"},
            {"nm_exercicio": "Panturrilha em pé",       "slug_firebase": "panturrilha-em-pe",        "grupo_muscular": "panturrilha"},
            {"nm_exercicio": "Panturrilha sentado",     "slug_firebase": "panturrilha-sentado",      "grupo_muscular": "panturrilha"},

            # --- Peito ---
            {"nm_exercicio": "Supino Reto",             "slug_firebase": "supino-reto",              "grupo_muscular": "peito"},
            {"nm_exercicio": "Supino Inclinado",        "slug_firebase": "supino-inclinado",         "grupo_muscular": "peito"},
            {"nm_exercicio": "Crucifixo",               "slug_firebase": "crucifixo",                "grupo_muscular": "peito"},
            {"nm_exercicio": "Cross over Polia Alta",   "slug_firebase": "cross-over-polia-alta",    "grupo_muscular": "peito"},
            {"nm_exercicio": "Cross over Polia Baixa",  "slug_firebase": "cross-over-polia-baixa",   "grupo_muscular": "peito"},
            {"nm_exercicio": "Crucifixo Inclinado",     "slug_firebase": "crucifixo-inclinado",      "grupo_muscular": "peito"},

            # --- Ombro ---
            {"nm_exercicio": "Desenvolvimento com Halteres", "slug_firebase": "desenvolvimento-com-halteres", "grupo_muscular": "ombro"},
            {"nm_exercicio": "Elevação Lateral",        "slug_firebase": "elevacao-lateral",         "grupo_muscular": "ombro"},
            {"nm_exercicio": "Elevação Frontal",        "slug_firebase": "elevacao-frontal",         "grupo_muscular": "ombro"},

            # --- Biceps ---
            {"nm_exercicio": "Rosca Direta Sentado",    "slug_firebase": "rosca-direta-sentado",     "grupo_muscular": "biceps"},
            {"nm_exercicio": "Rosca Scott",             "slug_firebase": "rosca-scott",              "grupo_muscular": "biceps"},
            {"nm_exercicio": "Rosca Martelo",           "slug_firebase": "rosca-martelo",            "grupo_muscular": "biceps"},
            {"nm_exercicio": "Bíceps Unilateral Polia", "slug_firebase": "biceps-unilateral-polia",  "grupo_muscular": "biceps"},

            # --- Triceps ---
            {"nm_exercicio": "Tríceps Frances",         "slug_firebase": "triceps-frances",          "grupo_muscular": "triceps"},
            {"nm_exercicio": "Tríceps Testa na Polia",  "slug_firebase": "triceps-testa-na-polia",   "grupo_muscular": "triceps"},
            {"nm_exercicio": "Tríceps Unilateral Polia","slug_firebase": "triceps-unilateral-polia",  "grupo_muscular": "triceps"},
            {"nm_exercicio": "Triceps Mergulho",        "slug_firebase": "triceps-mergulho",         "grupo_muscular": "triceps"},
            {"nm_exercicio": "Tríceps Corda",           "slug_firebase": "triceps-corda",            "grupo_muscular": "triceps"},
            {"nm_exercicio": "Tríceps Pulley",          "slug_firebase": "triceps-pulley",           "grupo_muscular": "triceps"},

            # --- Costas ---
            {"nm_exercicio": "Puxada Frontal",          "slug_firebase": "puxada-frontal",           "grupo_muscular": "costas"},
            {"nm_exercicio": "Remada Curvada",          "slug_firebase": "remada-curvada",           "grupo_muscular": "costas"},
            {"nm_exercicio": "Remada Cavalinho Curvada","slug_firebase": "remada-cavalinho-curvada",  "grupo_muscular": "costas"},
            {"nm_exercicio": "Remada Unilateral Halter","slug_firebase": "remada-unilateral-halter",  "grupo_muscular": "costas"},
            {"nm_exercicio": "Remada Baixa Polia",      "slug_firebase": "remada-baixa-polia",       "grupo_muscular": "costas"},
            {"nm_exercicio": "Pull Down",               "slug_firebase": "pull-down",                "grupo_muscular": "costas"},
            {"nm_exercicio": "Face Pull",               "slug_firebase": "face-pull",                "grupo_muscular": "costas"},
            {"nm_exercicio": "Voador Inverso",          "slug_firebase": "voador-inverso",           "grupo_muscular": "costas"},
        ]

        for item in exercicios_iniciais:
            existe = db.query(ExercicioDB).filter(ExercicioDB.nm_exercicio == item["nm_exercicio"]).first()
            if not existe:
                db.add(ExercicioDB(**item))
                print(f"✅ Exercício adicionado: {item['nm_exercicio']}")
            elif existe.grupo_muscular != item["grupo_muscular"]:
                existe.grupo_muscular = item["grupo_muscular"]
                print(f"🔄 Exercício atualizado: {item['nm_exercicio']} → {item['grupo_muscular']}")

        # 3. COMMIT PARA SALVAR LESÕES E EXERCÍCIOS ANTES DE VINCULAR
        db.commit()

        # 4. VINCULAR EXERCÍCIOS ÀS LESÕES (N:N) ---
        print("\n🔗 Criando vínculos de contraindicação...")
        
        # Regras de contraindicação
        vinculos_contraindicados = {
            # PERNA
            "Agachamento Livre": ["Lesão no Joelho", "Hérnia de Disco", "Lombalgia (Dor Lombar)"],
            "Leg Press": ["Hérnia de Disco", "Lombalgia (Dor Lombar)", "Condromalácia"],
            "Leg Press Horizontal": ["Hérnia de Disco", "Lombalgia (Dor Lombar)", "Condromalácia"],
            "Cadeira Extensora": ["Tendinite Patelar"],
            "Afundo": ["Instabilidade de Tornozelo", "Lesão no Joelho"],
            "Mesa Flexora": ["Lombalgia (Dor Lombar)"],
            "Cadeira Adutora (Fecha)": ["Pubalgia / Dor na Virilha"],
            "Stiff": ["Hérnia de Disco", "Lombalgia (Dor Lombar)"],
            "Elevação Pélvica": ["Lesão na Coluna Torácica", "Lombalgia (Dor Lombar)"],
            "Cadeira Abdutora (Abre)": ["Bursite Trocantérica (Quadril)"],
            "Panturrilha em pé": ["Fascite Plantar", "Tendinite de Aquiles"],
            "Panturrilha sentado": ["Tendinite de Aquiles"],

            # PEITO
            "Supino Reto": ["Tendinite no Ombro", "Lesão no Manguito Rotador"],
            "Supino Inclinado": ["Síndrome do Impacto (Ombro)"],
            "Crucifixo": ["Estiramento Muscular Recente"],
            "Cross over Polia Alta": ["Lesão no Manguito Rotador"],
            "Cross over Polia Baixa": ["Síndrome do Impacto (Ombro)"],
            "Crucifixo Inclinado": ["Estiramento Muscular Recente"],

            # OMBRO
            "Desenvolvimento com Halteres": ["Síndrome do Impacto (Ombro)", "Hérnia de Disco Cervical"],
            "Elevação Lateral": ["Bursite no Ombro", "Síndrome do Impacto (Ombro)"],
            "Elevação Frontal": ["Tendinite no Ombro"],

            # BICEPS
            "Rosca Direta Sentado": ["Epicondilite Medial (Cotovelo)", "Lombalgia (Dor Lombar)"],
            "Rosca Scott": ["Epicondilite Medial (Cotovelo)"],
            "Rosca Martelo": ["Epicondilite Lateral (Cotovelo)"],
            "Bíceps Unilateral Polia": ["Epicondilite Lateral (Cotovelo)"],

            # TRICEPS
            "Tríceps Frances": ["Síndrome do Impacto (Ombro)"],
            "Tríceps Testa na Polia": ["Epicondilite Lateral (Cotovelo)"],
            "Tríceps Unilateral Polia": ["Epicondilite Lateral (Cotovelo)"],
            "Tríceps Corda": ["Epicondilite Lateral (Cotovelo)"],

            # COSTAS
            "Puxada Frontal": ["Síndrome do Impacto (Ombro)", "Hérnia de Disco Cervical"],
            "Remada Curvada": ["Hérnia de Disco", "Lombalgia (Dor Lombar)"],
            "Remada Cavalinho Curvada": ["Lombalgia (Dor Lombar)", "Hérnia de Disco"],
            "Remada Unilateral Halter": ["Lombalgia (Dor Lombar)"],
            "Remada Baixa Polia": ["Lombalgia (Dor Lombar)"],
            "Pull Down": ["Síndrome do Impacto (Ombro)"],
            "Face Pull": ["Lesão no Manguito Rotador"],
            "Voador Inverso": ["Bursite no Ombro"]
        }

        for nome_exercicio, lista_lesoes in vinculos_contraindicados.items():
            # 4. 1. Busca o exercicio
            exercicio_obj = db.query(ExercicioDB).filter(ExercicioDB.nm_exercicio == nome_exercicio).first()
            
            if exercicio_obj:
                for nome_lesao in lista_lesoes:
                    # 4. 2. Busca a lesao
                    lesao_obj = db.query(LesaoDB).filter(LesaoDB.nm_lesao == nome_lesao).first()
                    
                    # 4. 3. Verifica se a lesão existe E se já não está vinculada
                    if lesao_obj and lesao_obj not in exercicio_obj.lesoes_contraindicadas:
                        exercicio_obj.lesoes_contraindicadas.append(lesao_obj)
                        print(f"   🚫 {nome_exercicio} contraindicado para {nome_lesao}")
            else:
                print(f"⚠️ Atenção: Exercício '{nome_exercicio}' não encontrado na hora de vincular lesões.")

        db.commit()
        print("\n✨ Banco de dados populado com sucesso e linkado com o Firestore!")

    except Exception as e:
        print(f"❌ Erro ao popular: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    popular_banco()