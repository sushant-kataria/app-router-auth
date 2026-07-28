# SquarePG (Ashirwad)

PG / hostel management for **owners** and **tenants**.

Owners manage rooms, tenants, payments, expenses, and complaints. Tenants get a lighter portal for dues and tickets. Optional AI assistant via Gemini. Ships as a web app and Capacitor Android project.

## Quick start

```bash
npm install
cp .env.example .env
npm run dev
```

Open the Vite URL (usually [http://localhost:5173](http://localhost:5173)).

### Supabase (cloud sync)

1. Create a Supabase project
2. Run [`supabase_migration.sql`](./supabase_migration.sql) in the SQL editor
3. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `.env`

Without Supabase, the app still runs on a local Dexie (IndexedDB) seed.

### Android (Capacitor)

```bash
npm run build
npm run cap:sync
npm run cap:open
```

## Environment

See [`.env.example`](./.env.example).

## Stack

React · TypeScript · Vite · Supabase · Dexie · Capacitor · Gemini (optional AI assistant)
