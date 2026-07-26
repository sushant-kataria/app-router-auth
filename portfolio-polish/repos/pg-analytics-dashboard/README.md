# PG Analytics Dashboard

Password-gated analytics for **SquarePG** product events: overview cards, activity feed, user table, and event charts. Backed by Supabase; auto-refreshes every 30s.

## Quick start

```bash
npm install
cp .env.example .env
npm run dev
```

## Environment

| Variable | Description |
|----------|-------------|
| `VITE_SUPABASE_URL` | Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Supabase anon key |
| `VITE_DASHBOARD_PASSWORD` | Gate password (default in code is for local demos only — set this in prod) |

## Scripts

`npm run dev` · `npm run build` · `npm run preview`

## Stack

React · TypeScript · Vite · Supabase · Recharts / Lucide
