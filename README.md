# Lab 1 API

Невеликий REST API на FastAPI і PostgreSQL. Локально він запускається в Docker Compose, у хмарі — в Azure: Container Apps за Application Gateway, база без публічної адреси, деплой з GitHub Actions.

Публічна адреса: http://4.233.88.84

Після `terraform apply` актуальна адреса лежить в output `public_ip`.

## Ендпоінти

| Метод | Шлях | Що робить |
|---|---|---|
| GET | `/health` | Перевірка, що процес живий |
| GET | `/db-check` | `SELECT 1` до PostgreSQL |
| POST | `/api/notes` | Записує нотатку в базу. Тіло: `{"message":"..."}` |
| GET | `/api/notes` | Повертає збережені нотатки |
| GET | `/api/protected` | Потребує заголовок `Authorization: Bearer my-secret-token` |
| GET | `/docs` | Swagger UI |

## Локальний запуск

```bash
docker compose up --build
```

API слухає `http://localhost:8000`, Postgres — порт 5432. Дані бази лежать у volume `postgres_data` і залишаються після `docker compose down`.

## Структура

```text
app/                 FastAPI, Dockerfile
compose.yaml         локальні API і PostgreSQL
terraform/           мережа, база, Container Apps, шлюз, моніторинг, OIDC
.github/workflows/   збірка образу і оновлення Container App на пуш у main
```

Інфраструктура в групі ресурсів `lab1-rg`, регіон France Central. З інтернету відкритий лише Application Gateway. PostgreSQL приймає порт 5432 тільки з підмережі застосунку і зі своєї власної підмережі.
