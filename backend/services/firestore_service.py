import os
import firebase_admin
from firebase_admin import credentials, firestore

_db = None


def get_firestore_client():
    global _db
    if _db is None:
        if not firebase_admin._apps:
            key_path = os.path.abspath(
                os.path.join(os.path.dirname(__file__), '..', 'firebase-key.json')
            )
            cred = credentials.Certificate(key_path)
            firebase_admin.initialize_app(cred)
        _db = firestore.client()
    return _db


def buscar_exercicio(slug: str) -> dict | None:
    db = get_firestore_client()
    doc = db.collection('exercicios_gifs').document(slug).get()
    return doc.to_dict() if doc.exists else None
