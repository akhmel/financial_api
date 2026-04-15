# Financial API

A concise Ruby on Rails API-only application for basic financial operations: user management, balance operations, and internal transfers between users.

## Tech Stack

- Ruby 4.0.2 + Rails 8.1 (API-only)
- PostgreSQL
- JWT authentication (HS256)
- [money-rails](https://github.com/RubyMoney/money-rails) — all monetary values are stored as integers (cents) to avoid floating-point precision issues
- Mandatory `Idempotency-Key` header on all mutation endpoints to guarantee safe retries

## Setup

```bash
bundle install
bin/rails db:create db:migrate
bin/rails server
```

The API is available at `http://localhost:3000`.

## API Endpoints

| Method | Endpoint                     | Auth | Description              |
|--------|------------------------------|------|--------------------------|
| POST   | `/api/v1/users`              | No   | Create a user            |
| POST   | `/api/v1/session`            | No   | Log in (get a new token) |
| GET    | `/api/v1/users/:id`          | Yes  | Get user details         |
| GET    | `/api/v1/balance`            | Yes  | Check current balance    |
| POST   | `/api/v1/balance/deposit`    | Yes  | Deposit funds            |
| POST   | `/api/v1/balance/withdraw`   | Yes  | Withdraw funds           |
| POST   | `/api/v1/transfers`          | Yes  | Transfer to another user |

## curl Examples

### 1. Create a user

```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "alice@example.com", "password": "secure-password-123", "password_confirmation": "secure-password-123"}}'
```

Response (`201 Created`):

```json
{
  "user": { "id": "a1b2c3d4-...", "email": "alice@example.com", "balance": 0 },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

Save the `token` value — it is used for all authenticated requests.

### 2. Log in (create session)

```bash
curl -X POST http://localhost:3000/api/v1/session \
  -H "Content-Type: application/json" \
  -d '{"session": {"email": "alice@example.com", "password": "secure-password-123"}}'
```

Response (`201 Created`):

```json
{ "token": "eyJhbGciOiJIUzI1NiJ9..." }
```

### 3. Check user balance

```bash
curl http://localhost:3000/api/v1/balance \
  -H "Authorization: Bearer <TOKEN>"
```

Response (`200 OK`):

```json
{ "user_id": "a1b2c3d4-...", "balance": 0 }
```

### 4. Deposit / Withdraw funds

All amounts are in **cents** (integer). For example, `100000` = $1,000.00.

Every mutation request (deposit, withdraw, transfer) **requires** an `Idempotency-Key` header (any unique string, e.g. a UUID). The server rejects duplicate requests with `409 Conflict`, guaranteeing each operation is applied exactly once even on network retries.

**Deposit:**

```bash
curl -X POST http://localhost:3000/api/v1/balance/deposit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"amount": 100000}'
```

**Withdraw:**

```bash
curl -X POST http://localhost:3000/api/v1/balance/withdraw \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"amount": 20000}'
```

Response (`200 OK`):

```json
{ "user_id": "a1b2c3d4-...", "balance": 80000 }
```

### 5. Transfer funds between users

First create a second user and note their `id`. Then transfer from the authenticated user:

```bash
curl -X POST http://localhost:3000/api/v1/transfers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SENDER_TOKEN>" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"recipient_id": "<RECIPIENT_UUID>", "amount": 30000}'
```

Response (`201 Created`):

```json
{
  "sender": { "id": "a1b2c3d4-...", "balance": 50000 },
  "recipient": { "id": "e5f6a7b8-..." },
  "amount": 30000
}
```
