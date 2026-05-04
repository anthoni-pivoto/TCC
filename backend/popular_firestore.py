import firebase_admin
from firebase_admin import credentials, firestore
import unicodedata
import re

# 1. Carrega a sua chave secreta do Firebase
cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# 2. Lista Enriquecida com Metadados (A Mágica do NoSQL)
exercicios_ricos = [
    # --- PERNA E GLÚTEOS ---
    {
        "nm_exercicio": "Agachamento Livre", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/agachamento%20livre.gif?alt=media&token=42e23347-e979-4ebe-826c-e42a3769e792",
        "grupo_principal": "Quadríceps", "musculos_secundarios": ["Glúteos", "Isquiotibiais", "Lombar"],
        "equipamento": "Barra e Anilhas",
        "dicas_execucao": ["Mantenha o peito estufado e a coluna neutra.", "Os joelhos devem acompanhar a linha das pontas dos pés."]
    },
    {
        "nm_exercicio": "Leg Press", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/legpress.gif?alt=media&token=c9e1bce5-63f9-4c9f-be56-39d88c8347ac",
        "grupo_principal": "Quadríceps", "musculos_secundarios": ["Glúteos", "Isquiotibiais"],
        "equipamento": "Máquina Leg Press",
        "dicas_execucao": ["Não estique os joelhos completamente no topo do movimento.", "Mantenha a lombar totalmente apoiada no banco."]
    },
    {
        "nm_exercicio": "Leg Press Horizontal", 
        "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/leg_press_horitzontal.gif?alt=media&token=f87832b8-c8e4-401e-8666-e77d8d942c59",
        "grupo_principal": "Quadríceps", 
        "musculos_secundarios": ["Glúteos", "Isquiotibiais"],
        "equipamento": "Máquina Leg Press Horizontal",
        "dicas_execucao": [
            "Empurre a plataforma usando toda a planta do pé, focando a força nos calcanhares.", 
            "Evite que os joelhos se fechem (apontem para dentro) durante a descida do peso."
        ]
    },
    {
        "nm_exercicio": "Cadeira Extensora", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/cadeira_extensora.gif?alt=media&token=a57068c0-c24f-40ef-ae32-9c4b54611e48",
        "grupo_principal": "Quadríceps", "musculos_secundarios": [],
        "equipamento": "Máquina Extensora",
        "dicas_execucao": ["Ajuste o encosto para que o joelho fique alinhado com o eixo da máquina.", "Controle a descida do peso."]
    },
    {
        "nm_exercicio": "Afundo", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/afundo.gif?alt=media&token=5501daf2-05eb-4db9-8623-a0460456954a",
        "grupo_principal": "Quadríceps", "musculos_secundarios": ["Glúteos"],
        "equipamento": "Halteres ou Peso do Corpo",
        "dicas_execucao": ["Dê um passo largo o suficiente para formar ângulos de 90 graus nos dois joelhos.", "Mantenha o tronco reto."]
    },
    {
        "nm_exercicio": "Mesa Flexora", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/maesa-flexora.gif?alt=media&token=5cd1a9d5-274e-4fcb-bcd7-4edb9a96820c",
        "grupo_principal": "Isquiotibiais", "musculos_secundarios": ["Panturrilhas"],
        "equipamento": "Máquina Flexora",
        "dicas_execucao": ["Mantenha o quadril colado no banco durante todo o movimento.", "Aponte as pontas dos pés para frente."]
    },
    {
        "nm_exercicio": "Cadeira Adutora (Fecha)", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/cadeira_abdutora.gif?alt=media&token=f0cf71c0-84f6-48b5-8580-66ced6aba4e5",
        "grupo_principal": "Adutores", "musculos_secundarios": [],
        "equipamento": "Máquina Adutora",
        "dicas_execucao": ["Abra a máquina o máximo que sua flexibilidade permitir.", "Faça um movimento controlado, sem bater as placas."]
    },
    {
        "nm_exercicio": "Stiff", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/stiff.gif?alt=media&token=d43acf44-7564-442f-9067-24ecb1925dce",
        "grupo_principal": "Isquiotibiais", "musculos_secundarios": ["Glúteos", "Lombar"],
        "equipamento": "Barra e Anilhas ou Halteres",
        "dicas_execucao": ["Mantenha as pernas semi-flexionadas e a coluna reta.", "O movimento é focado em jogar o quadril para trás."]
    },
    {
        "nm_exercicio": "Elevação Pélvica", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/elevacao_pelvica.gif?alt=media&token=4da60d92-a7a4-4c24-8d0c-bd0735494920",
        "grupo_principal": "Glúteos", "musculos_secundarios": ["Isquiotibiais", "Lombar"],
        "equipamento": "Barra, Anilhas e Banco",
        "dicas_execucao": ["Apoie a parte inferior das escápulas no banco.", "Contraia os glúteos com força no topo do movimento."]
    },
    {
        "nm_exercicio": "Cadeira Abdutora (Abre)", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/cadeira_adutora.gif?alt=media&token=f710f2dc-7cc6-4f42-a842-243cdae321e0",
        "grupo_principal": "Glúteos (Médio)", "musculos_secundarios": [],
        "equipamento": "Máquina Abdutora",
        "dicas_execucao": ["Sente-se com a coluna totalmente apoiada.", "Afaste as pernas empurrando com os joelhos, não com os pés."]
    },
    {
        "nm_exercicio": "Panturrilha em pé", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/panturilha_em_pe.gif?alt=media&token=74415150-5c5d-4396-b279-b1be27ba7863",
        "grupo_principal": "Panturrilhas (Gastrocnêmio)", "musculos_secundarios": [],
        "equipamento": "Máquina ou Step",
        "dicas_execucao": ["Desça o calcanhar o máximo possível para alongar.", "Suba contraindo bem até a ponta dos pés."]
    },
    {
        "nm_exercicio": "Panturrilha sentado", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/panturilha_sentado.gif?alt=media&token=d3a7f83e-28da-4b8b-9a91-a569010b94ad",
        "grupo_principal": "Panturrilhas (Sóleo)", "musculos_secundarios": [],
        "equipamento": "Máquina Específica",
        "dicas_execucao": ["Não tenha pressa. Faça uma pausa de 1 segundo no topo.", "Mantenha o foco na amplitude do movimento."]
    },

    # --- PEITO ---
    {
        "nm_exercicio": "Supino Reto", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/supino_reto.gif?alt=media&token=e17dacc5-5fe6-4199-88b2-4bbf0ed78815",
        "grupo_principal": "Peitoral", "musculos_secundarios": ["Tríceps", "Ombro (Deltoide Anterior)"],
        "equipamento": "Banco Plano e Barra",
        "dicas_execucao": ["Mantenha as escápulas retraídas (apertadas para trás).", "A barra deve tocar o meio do peito."]
    },
    {
        "nm_exercicio": "Supino Inclinado", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/supino-inclinado.gif?alt=media&token=4649b552-fb62-4916-a173-521866898577",
        "grupo_principal": "Peitoral (Superior)", "musculos_secundarios": ["Tríceps", "Ombro Anterior"],
        "equipamento": "Banco Inclinado e Barra",
        "dicas_execucao": ["A inclinação ideal do banco é entre 30 e 45 graus.", "Desça a barra na direção da clavícula."]
    },
    {
        "nm_exercicio": "Crucifixo", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/crucifixo.gif?alt=media&token=525631e4-ff4b-45a6-a0c9-cbdddaa1f0ad",
        "grupo_principal": "Peitoral", "musculos_secundarios": [],
        "equipamento": "Banco Plano e Halteres",
        "dicas_execucao": ["Mantenha os cotovelos levemente flexionados.", "Imagine que está abraçando uma árvore grossa."]
    },
    {
        "nm_exercicio": "Cross over Polia Alta", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/crossover-polia-alta.gif?alt=media&token=f511d02b-ceac-4889-a4a6-3999932e8bc2",
        "grupo_principal": "Peitoral (Inferior)", "musculos_secundarios": ["Ombro Anterior"],
        "equipamento": "Polia (Cross Over)",
        "dicas_execucao": ["Incline o tronco levemente para frente.", "Feche os braços apontando para o chão, cruzando as mãos."]
    },
    {
        "nm_exercicio": "Cross over Polia Baixa", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/crossover-na-polia-baixa.gif?alt=media&token=215f5b5c-67a8-4234-9b84-9283ace9d1c7",
        "grupo_principal": "Peitoral (Superior)", "musculos_secundarios": ["Ombro Anterior"],
        "equipamento": "Polia (Cross Over)",
        "dicas_execucao": ["Puxe as alças de baixo para cima, na direção do queixo.", "Contraia o peito no topo do movimento."]
    },
    {
        "nm_exercicio": "Crucifixo Inclinado", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/crucifixo-inclinado.gif?alt=media&token=4de78fb5-f8ff-4375-a083-726bc91acd50",
        "grupo_principal": "Peitoral (Superior)", "musculos_secundarios": [],
        "equipamento": "Banco Inclinado e Halteres",
        "dicas_execucao": ["Controle o peso na descida para focar no alongamento do peito.", "Não deixe os halteres baterem no topo."]
    },

    # --- OMBRO ---
    {
        "nm_exercicio": "Desenvolvimento com Halteres", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/desenvolvimento-com-halteres.gif?alt=media&token=3e8efeb7-5d13-4596-97a9-c7a5effe23e3",
        "grupo_principal": "Ombros (Deltoide Anterior e Médio)", "musculos_secundarios": ["Tríceps"],
        "equipamento": "Banco com Encosto e Halteres",
        "dicas_execucao": ["Mantenha os cotovelos levemente à frente da linha dos ombros.", "Empurre os halteres até quase esticar os braços."]
    },
    {
        "nm_exercicio": "Elevação Lateral", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/elevacao-lateral.gif?alt=media&token=794ffc8e-f4af-4299-977c-c783444601d2",
        "grupo_principal": "Ombros (Deltoide Médio)", "musculos_secundarios": [],
        "equipamento": "Halteres",
        "dicas_execucao": ["Eleve os braços até a altura dos ombros, não mais que isso.", "Mantenha uma leve flexão nos cotovelos."]
    },
    {
        "nm_exercicio": "Elevação Frontal", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/elevacao-frontal.gif?alt=media&token=6900dec0-52c5-4c5f-8a2d-28a113874a69",
        "grupo_principal": "Ombros (Deltoide Anterior)", "musculos_secundarios": [],
        "equipamento": "Halteres, Barra ou Polia",
        "dicas_execucao": ["Não balance o corpo para subir o peso.", "Concentre-se em usar apenas a força dos ombros."]
    },

    # --- BÍCEPS ---
    {
        "nm_exercicio": "Rosca Direta Sentado", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/rosca-concentrada.gif?alt=media&token=198f21e6-6b79-41fe-8ff8-6aaf610eabb6",
        "grupo_principal": "Bíceps", "musculos_secundarios": ["Antebraços"],
        "equipamento": "Banco e Halteres",
        "dicas_execucao": ["Mantenha os cotovelos colados ao lado do corpo.", "Gire o punho para fora (supinação) ao subir o peso."]
    },
    {
        "nm_exercicio": "Rosca Scott", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/rosca_scott.gif?alt=media&token=93d57a01-91e9-4eb2-b82a-f63569ff3b07",
        "grupo_principal": "Bíceps", "musculos_secundarios": ["Antebraços"],
        "equipamento": "Banco Scott e Barra W",
        "dicas_execucao": ["Apoie bem a axila no banco para isolar o bíceps.", "Não estenda os braços completamente na descida para evitar lesões."]
    },
    {
        "nm_exercicio": "Rosca Martelo", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/rosca-martelo.gif?alt=media&token=ead5173c-ed09-422c-ae9c-899c8a574022",
        "grupo_principal": "Bíceps (Braquial)", "musculos_secundarios": ["Antebraços (Braquiorradial)"],
        "equipamento": "Halteres",
        "dicas_execucao": ["Segure os halteres com a pegada neutra (palmas viradas para dentro).", "Suba alternando ou juntos, sem roubar com o corpo."]
    },
    {
        "nm_exercicio": "Bíceps Unilateral Polia", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/biceps_polia_alta.gif?alt=media&token=e8cfbe16-8612-4a03-b03f-5bc10126cd27",
        "grupo_principal": "Bíceps", "musculos_secundarios": [],
        "equipamento": "Polia e Puxador",
        "dicas_execucao": ["Deixe a polia na altura baixa.", "Mantenha tensão contínua no cabo durante toda a série."]
    },

    # --- TRÍCEPS ---
    {
        "nm_exercicio": "Tríceps Frances", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/triceps-frances.gif?alt=media&token=c6615376-5722-448e-b5d4-1b1d6a651860",
        "grupo_principal": "Tríceps (Cabeça Longa)", "musculos_secundarios": [],
        "equipamento": "Halter e Banco",
        "dicas_execucao": ["Mantenha os cotovelos apontados para o teto, próximos às orelhas.", "Desça o peso atrás da cabeça até alongar bem."]
    },
    {
        "nm_exercicio": "Tríceps Testa na Polia", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/triceps_testa.gif?alt=media&token=85c3528e-71c6-41b1-a059-0f4dff4ad3d2",
        "grupo_principal": "Tríceps", "musculos_secundarios": [],
        "equipamento": "Polia e Barra Reta/W",
        "dicas_execucao": ["Trave os cotovelos; apenas os antebraços devem se mover.", "Leve a barra em direção à testa ou um pouco atrás."]
    },
    {
        "nm_exercicio": "Tríceps Unilateral Polia", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/triceps-unilateral.gif?alt=media&token=889b338c-2f18-4af7-a622-8fea8eb83559",
        "grupo_principal": "Tríceps", "musculos_secundarios": [],
        "equipamento": "Polia (Sem pegador ou com alça)",
        "dicas_execucao": ["Estenda o braço completamente contraindo o tríceps no final.", "Faça o movimento de forma concentrada."]
    },
    {
        "nm_exercicio": "Tríceps Corda", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/triceps-corda.gif?alt=media&token=a7bd6d57-f510-4d6a-89f1-2eeaa24322e3",
        "grupo_principal": "Tríceps", "musculos_secundarios": [],
        "equipamento": "Polia Alta e Corda",
        "dicas_execucao": ["No final do movimento, abra as pontas da corda para fora.", "Mantenha o peito estufado e os ombros para trás."]
    },
    {
        "nm_exercicio": "Tríceps Pulley", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/triceps-pulley.gif?alt=media&token=6e4ede3d-89a4-4fea-ae49-2928ab4e4a4f",
        "grupo_principal": "Tríceps", "musculos_secundarios": [],
        "equipamento": "Polia Alta e Barra Reta/V",
        "dicas_execucao": ["Traga a barra até tocar as coxas.", "Controle a subida para que o peso não puxe seus cotovelos para cima."]
    },

    # --- COSTAS ---
    {
        "nm_exercicio": "Puxada Frontal", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/puxada-alta.gif?alt=media&token=9ddbd568-2a2b-4e0b-8767-23a50bd0b59c",
        "grupo_principal": "Costas (Dorsais)", "musculos_secundarios": ["Bíceps"],
        "equipamento": "Máquina Puxador (Lat Pulldown)",
        "dicas_execucao": ["Incline-se ligeiramente para trás e puxe a barra na direção do peito superior.", "Inicie o movimento puxando com as escápulas."]
    },
    {
        "nm_exercicio": "Remada Curvada", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/remada-curvada.gif?alt=media&token=bd39d965-e5cd-44e5-94e9-d30e1dba2059",
        "grupo_principal": "Costas", "musculos_secundarios": ["Lombar", "Bíceps"],
        "equipamento": "Barra e Anilhas",
        "dicas_execucao": ["Mantenha a coluna reta e quase paralela ao chão.", "Puxe a barra em direção ao umbigo, apertando as costas."]
    },
    {
        "nm_exercicio": "Remada Cavalinho Curvada", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/costas-remada-curvada-.gif?alt=media&token=e3672d65-7724-4cdd-b7fb-48d1b60a91da",
        "grupo_principal": "Costas (Miolo)", "musculos_secundarios": ["Bíceps", "Lombar"],
        "equipamento": "Barra em T ou Máquina",
        "dicas_execucao": ["Evite usar o impulso da lombar para levantar o peso.", "Mantenha os cotovelos fechados, raspando no corpo."]
    },
    {
        "nm_exercicio": "Remada Unilateral Halter", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/serrote.gif?alt=media&token=764214b9-9766-4eff-a10d-7470ff8bf5bb",
        "grupo_principal": "Costas", "musculos_secundarios": ["Bíceps"],
        "equipamento": "Halter e Banco Plano",
        "dicas_execucao": ["Apoie um joelho e uma mão no banco para estabilizar a coluna.", "Puxe o halter na direção do quadril."]
    },
    {
        "nm_exercicio": "Remada Baixa Polia", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/remada-baixa.gif?alt=media&token=b6bbad63-30e9-4550-807f-d8c80b10d029",
        "grupo_principal": "Costas", "musculos_secundarios": ["Bíceps"],
        "equipamento": "Polia Baixa e Puxador Triângulo",
        "dicas_execucao": ["Mantenha o tronco firme, sem jogar para frente e para trás.", "Estufe o peito ao puxar o peso."]
    },
    {
        "nm_exercicio": "Pull Down", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/pulldown.gif?alt=media&token=4d0a84d6-35f3-4c45-a266-1e34b4824c65",
        "grupo_principal": "Costas (Dorsais)", "musculos_secundarios": [],
        "equipamento": "Polia Alta e Corda/Barra Reta",
        "dicas_execucao": ["Mantenha os braços esticados durante todo o movimento.", "Empurre o peso para baixo contraindo as \"asas\" das costas."]
    },
    {
        "nm_exercicio": "Face Pull", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/facepull.gif?alt=media&token=38a8f792-9ba0-4ee2-bbdc-501879d96435",
        "grupo_principal": "Ombro (Deltoide Posterior)", "musculos_secundarios": ["Costas (Trapézio Superior)"],
        "equipamento": "Polia Alta e Corda",
        "dicas_execucao": ["Puxe a corda em direção ao rosto, separando as mãos.", "Mantenha os cotovelos altos, acima da linha dos ombros."]
    },
    {
        "nm_exercicio": "Voador Inverso", "vid_path": "https://firebasestorage.googleapis.com/v0/b/treine-se-32a66.firebasestorage.app/o/voador-inverso.gif?alt=media&token=e3b05242-0c92-4b02-baee-4430e234c8fb",
        "grupo_principal": "Ombro (Deltoide Posterior)", "musculos_secundarios": ["Costas (Romboides)"],
        "equipamento": "Máquina Pec Deck",
        "dicas_execucao": ["Ajuste a máquina para empurrar as hastes para trás.", "Concentre-se em espremer o meio das costas no final do movimento."]
    }
]

# Função para transformar "Rosca Direta Sentado" em "rosca-direta-sentado"
def gerar_slug(nome: str) -> str:
    processado = unicodedata.normalize('NFKD', nome).encode('ASCII', 'ignore').decode('utf-8')
    processado = re.sub(r'[^\w\s-]', '', processado).strip().lower()
    return re.sub(r'[-\s]+', '-', processado)

def enviar_para_firestore():
    colecao = db.collection('exercicios_gifs')
    
    print("Iniciando envio dos dados ricos para o Firestore...")
    for ex in exercicios_ricos:
        slug = gerar_slug(ex['nm_exercicio'])
        
        # Estrutura JSON profissional completa para o Firestore
        documento = {
            "nome": ex['nm_exercicio'],
            "gif_url": ex['vid_path'],
            "grupo_muscular_principal": ex['grupo_principal'],
            "musculos_secundarios": ex['musculos_secundarios'],
            "equipamento": ex['equipamento'],
            "dicas_execucao": ex['dicas_execucao']
        }
        
        # Cria ou atualiza o documento no Firebase
        colecao.document(slug).set(documento)
        print(f"✅ Salvo com Metadados: {slug}")

    print("\n🚀 Finalizado! Seu NoSQL está populado com dados dignos de um App Profissional.")

if __name__ == "__main__":
    enviar_para_firestore()