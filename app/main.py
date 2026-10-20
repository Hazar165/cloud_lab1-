import os
from datetime import datetime
from urllib.parse import quote_plus

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
DB_HOST = os.environ["DB_HOST"]
DB_PORT = os.environ["DB_PORT"]
DB_NAME = os.environ["DB_NAME"]

DATABASE_URL = (
    f"postgresql+psycopg2://{quote_plus(DB_USER)}:{quote_plus(DB_PASSWORD)}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 5},
)

bearer_scheme = HTTPBearer(auto_error=False)
EXPECTED_TOKEN = "my-secret-token"

app = FastAPI(title="Lab 1 API")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/db-check")
def db_check():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="database unavailable",
        ) from None
    return {"database": "ok"}


class NoteCreate(BaseModel):
    message: str = Field(min_length=1, max_length=500)


class NoteRead(BaseModel):
    id: int
    message: str
    created_at: datetime


def ensure_notes_table() -> None:
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS notes (
                    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                    message TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """
            )
        )


@app.post("/api/notes", response_model=NoteRead, status_code=status.HTTP_201_CREATED)
def create_note(note: NoteCreate):
    try:
        ensure_notes_table()
        with engine.begin() as connection:
            row = connection.execute(
                text(
                    """
                    INSERT INTO notes (message)
                    VALUES (:message)
                    RETURNING id, message, created_at
                    """
                ),
                {"message": note.message},
            ).one()
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="database unavailable",
        ) from None
    return NoteRead(id=row.id, message=row.message, created_at=row.created_at)


@app.get("/api/notes", response_model=list[NoteRead])
def list_notes():
    try:
        ensure_notes_table()
        with engine.begin() as connection:
            rows = connection.execute(
                text("SELECT id, message, created_at FROM notes ORDER BY id")
            ).all()
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="database unavailable",
        ) from None
    return [
        NoteRead(id=row.id, message=row.message, created_at=row.created_at)
        for row in rows
    ]


@app.get("/api/protected")
def protected(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
):
    if credentials is None or credentials.credentials != EXPECTED_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return {"message": "access granted"}
