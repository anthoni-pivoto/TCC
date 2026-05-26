from pydantic import BaseModel


class LesaoResponse(BaseModel):
    id_lesao: int
    nm_lesao: str

    class Config:
        from_attributes = True
