# auth-verify

NestJS microservice that **verifies Azure AD JWTs** using JWKS.

## Endpoint

`POST /verifier/verify`

Pass the token in the `Authorization: Bearer …` header **or** JSON body:

```json
{ "token": "<jwt>", "serviceCode": "optional" }
```

## Quick start

```bash
npm install
cp .env.example .env
npm run start:dev
```

Service listens on `PORT` (default `3001`).

## Environment

| Variable | Description |
|----------|-------------|
| `PORT` | Listen port (default 3001) |
| `AZURE_TENANT_ID` | Azure AD tenant |
| `AZURE_CLIENT_ID` | Expected audience / client ID |
| `AZURE_ISSUER` | Optional issuer override |
| `AZURE_JWKS_URI` | Optional JWKS URI override |

## Scripts

`npm run start:dev` · `npm run build` · `npm run start:prod` · `npm test` (via jest config)

## Stack

NestJS · jsonwebtoken · Azure AD JWKS
