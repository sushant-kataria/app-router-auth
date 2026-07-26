# Sweep

AI workspace for **finance screens**, **real-estate intel**, and **general chat**.

Built with Next.js App Router, Turso (SQLite/libSQL), Stripe Pro, and multi-provider LLM routing (OpenRouter / Gemini / Groq).

## Features

- **Chat** — general Q&A with fallback across configured model providers
- **Finance** — stock screens, SEC/EDGAR-backed fundamentals, Yahoo/Finnhub market data
- **Real estate** — market map and deal-oriented views
- **Pro billing** — Stripe subscriptions with free-tier samples

## Quick start

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

### Optional data seeds

```bash
npm run db:init
npm run seed:finance
npm run seed:real-estate
```

## Environment

See [`.env.example`](./.env.example). Minimum for local chat: at least one of `OPENROUTER_API_KEY`, `GOOGLE_GENERATIVE_AI_API_KEY`, or `GROQ_API_KEY`. Turso + Stripe unlock finance caching and Pro billing.

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Dev server |
| `npm run build` / `start` | Production |
| `npm run db:init` | Initialize Turso schema |
| `npm run seed:finance` | Seed finance data |
| `npm run seed:real-estate` | Seed real-estate data |

## Stack

Next.js · TypeScript · Tailwind · Turso · Stripe · WorkOS (auth where configured)
