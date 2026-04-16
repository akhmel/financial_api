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
  "user": { "id": "a1b2c3d4-...", "email": "alice@example.com" }
}
```

Use the session endpoint below to obtain a JWT token for authenticated requests.

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

All amounts are in **cents** (integer). For example, `100000` = $1,000.00. Minimum amount is **100** cents ($1.00), maximum is **10,000,000,000** cents ($100M).

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

First create a second user. Then transfer from the authenticated user using the recipient's email:

```bash
curl -X POST http://localhost:3000/api/v1/transfers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SENDER_TOKEN>" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"recipient_email": "bob@example.com", "amount": 30000}'
```

Response (`201 Created`):

```json
{
  "sender": { "email": "alice@example.com", "balance": 50000 },
  "recipient": { "email": "bob@example.com", "balance": 50000 },
  "amount": 30000
}
```
