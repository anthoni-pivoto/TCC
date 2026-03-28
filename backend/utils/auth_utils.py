from passlib.context import CryptContext

# Configura o bcrypt como o algoritmo padrao de hash
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    """Recebe a senha em texto puro e retorna o Hash embaralhado."""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica se a senha digitada no Login bate com o Hash salvo no banco."""
    return pwd_context.verify(plain_password, hashed_password)