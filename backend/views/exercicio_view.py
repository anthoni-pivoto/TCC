import httpx
from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from services.firestore_service import buscar_exercicio

router = APIRouter(prefix="/exercicios")


@router.get("/detalhe/{slug}")
def get_detalhe_exercicio(slug: str):
    dados = buscar_exercicio(slug)
    if not dados:
        raise HTTPException(status_code=404, detail="Exercício não encontrado no Firestore")
    return dados


@router.get("/gif/{slug}")
def get_gif_exercicio(slug: str):
    dados = buscar_exercicio(slug)
    if not dados or not dados.get("gif_url"):
        raise HTTPException(status_code=404, detail="GIF não encontrado")

    gif_url = dados["gif_url"]
    try:
        r = httpx.get(gif_url, timeout=10, follow_redirects=True)
        r.raise_for_status()
    except httpx.HTTPError as e:
        raise HTTPException(status_code=502, detail=f"Erro ao buscar GIF: {e}")

    return Response(
        content=r.content,
        media_type=r.headers.get("content-type", "image/gif"),
        headers={"Cache-Control": "public, max-age=86400"},
    )
