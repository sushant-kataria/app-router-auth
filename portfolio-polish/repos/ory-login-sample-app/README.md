# Ory JWT Sample (`ory-jwt`)

Next.js sample that **verifies Ory Network JWTs** and protects API routes.

Shows middleware + JWKS-based verification for a protected endpoint (see `pages/api` / `lib`).

## Quick start

```bash
npm install
cp .env.example .env.local
npm run dev
```

Hit the protected API with a Bearer token issued by your Ory project.

## Environment

Configure your Ory project JWKS / issuer values in `.env.local` (see `.env.example`).

> **Security note:** Do not commit real signing keys. Prefer env-injected JWKS in production. Rotate any keys that were previously committed to this repo.

## Stack

Next.js · Ory Network · JWKS JWT verification
