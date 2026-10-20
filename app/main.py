import hmac
import os
from datetime import datetime, timedelta, timezone
from urllib.parse import quote_plus

import jwt
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
JWT_SECRET = os.environ["JWT_SECRET"]
API_USERNAME = os.environ["API_USERNAME"]
API_PASSWORD = os.environ["API_PASSWORD"]
JWT_ALGORITHM = "HS256"
JWT_TTL = timedelta(hours=1)

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


class Login(BaseModel):
    username: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


def _unauthorized() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or missing token",
        headers={"WWW-Authenticate": "Bearer"},
    )


def require_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> str:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise _unauthorized()
    try:
        payload = jwt.decode(
            credentials.credentials,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
        )
    except jwt.PyJWTError:
        raise _unauthorized() from None
    subject = payload.get("sub")
    if not isinstance(subject, str) or subject == "":
        raise _unauthorized()
    return subject


@app.post("/api/token", response_model=Token)
def issue_token(login: Login):
    username_ok = hmac.compare_digest(login.username, API_USERNAME)
    password_ok = hmac.compare_digest(login.password, API_PASSWORD)
    if not username_ok or not password_ok:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
        )
    now = datetime.now(timezone.utc)
    token = jwt.encode(
        {"sub": login.username, "iat": now, "exp": now + JWT_TTL},
        JWT_SECRET,
        algorithm=JWT_ALGORITHM,
    )
    return Token(access_token=token)


@app.post("/api/notes", response_model=NoteRead, status_code=status.HTTP_201_CREATED)
def create_note(note: NoteCreate, _user: str = Depends(require_user)):
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
def list_notes(_user: str = Depends(require_user)):
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
def protected(_user: str = Depends(require_user)):
    return {"message": "access granted", "user": _user}
