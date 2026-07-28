# PR 13 — E-vara: update README local setup

**Issue:** https://github.com/SHAURYASANYAL3/E-vara/issues/184  
**File:** `README.md`  
**Status when drafted:** open, unassigned, no competing PR

## Claim

```text
I'll take this — updating README Getting Started with clone + `npm run dev` (setup was build-only / outdated).
```

## Change

Replace the Frontend deploy snippet under Getting Started so local setup includes:

```bash
git clone https://github.com/SHAURYASANYAL3/E-vara.git
cd E-vara
npm install
npm run dev
```

Keep env var docs (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`). Note there is no `.env.example` in-repo — document creating a `.env` manually.
