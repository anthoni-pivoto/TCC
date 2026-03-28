import sys
import os

# Metodo para garantir que o Python encontre os modulos sem erros
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models.exercicio_model import ExercicioDB, LesaoDB 

def popular_banco():
    db = SessionLocal()
    try:
        print("🚀 Iniciando população do banco de dados local...")

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
            # Perna !!
            # Quadríceps
            {"nm_exercicio": "Agachamento Livre", "vid_path": "https://link-do-firebase-video1.mp4"}, 
            {"nm_exercicio": "Leg Press", "vid_path": "https://link-do-firebase-video1.mp4"},
            {"nm_exercicio": "Cadeira Extensora", "vid_path": "https://link-do-firebase-video1.mp4"},
            {"nm_exercicio": "Afundo", "vid_path": "https://link-do-firebase-video1.mp4"},

            # Isoquiotibiais
            {"nm_exercicio": "Mesa Flexora", "vid_path": "https://link-do-firebase-video1.mp4"},
            {"nm_exercicio": "Cadeira Adutora (Fecha)", "vid_path": "https://link-do-firebase-video1.mp4"},
            {"nm_exercicio": "Stiff", "vid_path": "https://link-do-firebase-video1.mp4"},
            
            # Glúteos
            {"nm_exercicio": "Elevação Pélvica", "vid_path": "https://link-do-firebase-video1.mp4"},
            {"nm_exercicio": "Cadeira Abdutora (Abre)", "vid_path": "https://link-do-firebase-video1.mp4"},

            # Panturrilha
            {"nm_exercicio": "Panturilha em pé", "vid_path": "https://link-do-firebase-video1.mp4"},
            {"nm_exercicio": "Panturilha sentado", "vid_path": "https://link-do-firebase-video1.mp4"},

            # Peito
            {"nm_exercicio": "Supino Reto", "vid_path": "https://link-do-firebase-video2.mp4"},
            {"nm_exercicio": "Supino Inclinado", "vid_path": "https://link-do-firebase-video2.mp4"},
            {"nm_exercicio": "Crucifixo", "vid_path": "https://link-do-firebase-video2.mp4"},
            {"nm_exercicio": "Cross over Polia Alta", "vid_path": "https://link-do-firebase-video2.mp4"},
            {"nm_exercicio": "Cross over Polia Baixa", "vid_path": "https://link-do-firebase-video2.mp4"},
            {"nm_exercicio": "Crucifixo Inclinado", "vid_path": "https://link-do-firebase-video2.mp4"},
            
            # Ombro
            {"nm_exercicio": "Desenvolvimento com Halteres", "vid_path": "https://link-do-firebase-video3.mp4"},
            {"nm_exercicio": "Elevação Lateral", "vid_path": "https://link-do-firebase-video3.mp4"},
            {"nm_exercicio": "Elevação Frontal", "vid_path": "https://link-do-firebase-video3.mp4"},
            
            # Biceps
            {"nm_exercicio": "Rosca Direta Sentado", "vid_path": "https://link-do-firebase-video3.mp4"},
            {"nm_exercicio": "Rosca Scott", "vid_path": "https://link-do-firebase-video3.mp4"},
            {"nm_exercicio": "Rosca Martelo", "vid_path": "https://link-do-firebase-video3.mp4"},
            {"nm_exercicio": "Bíceps Unilateral Polia", "vid_path": "https://link-do-firebase-video3.mp4"},
            
            # Triceps
            {"nm_exercicio": "Tríceps Frances Polia", "vid_path": "https://link-do-firebase-video3.mp4"},
            {"nm_exercicio": "Tríceps Testa", "vid_path": "https://link-do-firebase-video3.mp4"},
            {"nm_exercicio": "Tríceps Unilateral Polia", "vid_path": "https://link-do-firebase-video3.mp4"},
            {"nm_exercicio": "Triceps Mergulho", "vid_path": "https://link-do-firebase-video3.mp4"},
            {"nm_exercicio": "Tríceps Corda Polia", "vid_path": "https://link-do-firebase-video3.mp4"},
            
            # Costas
            {"nm_exercicio": "Puxada Frontal", "vid_path": "https://link-do-firebase-video4.mp4"},
            {"nm_exercicio": "Remada Curvada", "vid_path": "https://link-do-firebase-video4.mp4"},
            {"nm_exercicio": "Remada Cavalinho Curvada", "vid_path": "https://link-do-firebase-video4.mp4"},
            {"nm_exercicio": "Remada Unilateral Halter", "vid_path": "https://link-do-firebase-video4.mp4"},
            {"nm_exercicio": "Remada Baixa Polia", "vid_path": "https://link-do-firebase-video4.mp4"},
            {"nm_exercicio": "Pull Down", "vid_path": "https://link-do-firebase-video4.mp4"},
            {"nm_exercicio": "Face Pull", "vid_path": "https://link-do-firebase-video4.mp4"},
            {"nm_exercicio": "Voador Inverso", "vid_path": "https://link-do-firebase-video4.mp4"},
    
        ]

        for item in exercicios_iniciais:
            existe = db.query(ExercicioDB).filter(ExercicioDB.nm_exercicio == item["nm_exercicio"]).first()
            if not existe:
                db.add(ExercicioDB(**item))
                print(f"✅ Exercício adicionado: {item['nm_exercicio']}")

        # 3. COMMIT PARA SALVAR LESÕES E EXERCÍCIOS ANTES DE VINCULAR
        db.commit()

        # 4. VINCULAR EXERCÍCIOS ÀS LESÕES (N:N) ---
        print("\n🔗 Criando vínculos de contraindicação...")
        
        # Regras de contraindicação 
        vinculos_contraindicados = {
            # PERNA
            "Agachamento Livre": ["Lesão no Joelho", "Hérnia de Disco", "Lombalgia"],
            "Leg Press": ["Hérnia de Disco", "Lombalgia", "Condromalácia"],
            "Cadeira Extensora": ["Tendinite Patelar", "Lesão no LCA"],
            "Afundo": ["Instabilidade de Tornozelo", "Lesão no Joelho"],
            "Mesa Flexora": ["Lombalgia"],
            "Cadeira Adutora (Fecha):": ["Pubalgia", "Estiramento de Virilha"],
            "Stiff": ["Hérnia de Disco", "Lombalgia", "Encurtamento Severo de Isquiotibiais"],
            "Elevação Pélvica": ["Lesão na Coluna Torácica", "Lombalgia"],
            "Cadeira Abdutora (Abre)": ["Bursite Trocantérica"],
            "Panturilha em pé": ["Fascite Plantar", "Tendinite de Aquiles"],
            "Panturilha sentado": ["Tendinite de Aquiles"],

            # PEITO
            "Supino Reto": ["Tendinite no Ombro", "Lesão no Manguito Rotador"],
            "Supino Inclinado": ["Impacto no Ombro", "Lesão na Acromioclavicular"],
            "Crucifixo": ["Instabilidade de Ombro", "Estiramento de Peitoral"],
            "Cross over Polia Alta": ["Lesão no Manguito Rotador"],
            "Cross over Polia Baixa": ["Impacto no Ombro"],
            "Crucifixo Inclinado": ["Instabilidade de Ombro"],

            # OMBRO
            "Desenvolvimento com Halteres": ["Impacto no Ombro", "Hérnia de Disco Cervical"],
            "Elevação Lateral": ["Bursite no Ombro", "Síndrome do Impacto"],
            "Elevação Frontal": ["Tendinite de Bíceps (Cabeça Longa)"],

            # BICEPS
            "Rosca Direta Sentado": ["Epicondilite Medial", "Lombalgia"],
            "Rosca Scott": ["Tendinite no Cotovelo", "Risco de Estiramento de Bíceps"],
            "Rosca Martelo": ["Epicondilite Lateral"],
            "Bíceps Unilateral Polia": ["Instabilidade de Cotovelo"],

            # TRICEPS
            "Tríceps Frances Polia": ["Impacto no Ombro", "Bursite Olecraniana"],
            "Tríceps Testa": ["Epicondilite Lateral", "Tendinite Triceptal"],
            "Tríceps Unilateral Polia": ["Epicondilite Lateral"],
            "Triceps Mergulho": ["Impacto no Ombro", "Lesão no Pulso"],
            "Tríceps Corda Polia": ["Tendinite no Cotovelo"],

            # COSTAS
            "Puxada Frontal": ["Impacto no Ombro", "Hérnia de Disco Cervical"],
            "Remada Curvada": ["Hérnia de Disco", "Lombalgia Crônica"],
            "Remada Cavalinho Curvada": ["Lombalgia", "Hérnia de Disco"],
            "Remada Unilateral Halter": ["Lombalgia"],
            "Remada Baixa Polia": ["Lombalgia"],
            "Pull Down": ["Instabilidade de Ombro"],
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
                    
                    # 4. 3. Verifica se a lesão existe E se já não está vinculada a este exercício
                    if lesao_obj and lesao_obj not in exercicio_obj.lesoes_contraindicadas:
                        # .append() insere na tb_exercicio_lesao automaticamente por conta das relações definidas nos models
                        exercicio_obj.lesoes_contraindicadas.append(lesao_obj)
                        print(f"   🚫 {nome_exercicio} contraindicado para {nome_lesao}")

        db.commit()
        print("\n✨ Banco de dados populado com sucesso!")

    except Exception as e:
        print(f"❌ Erro ao popular: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    popular_banco()