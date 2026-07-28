# PR 11 — triageiq: API Reference table polish

**Issue:** https://github.com/SakethSumanBathini/triageiq/issues/10  
**File:** `README.md` (API Reference section)  
**Claim protocol:** comment **`.take`** on the issue first.

## Claim

```text
.take
```

## Changes (concrete)

1. Grammar: `all 4 provider status` → `status of all 4 providers`
2. Align the Endpoints markdown table columns for readability
3. Confirm paths match `backend/app/routes/triage.py` (`/api/triage`, `/batch`, `/team`, `/analytics`, `/samples`, `/health`) — leave `/docs` (FastAPI Swagger) as-is

Do not invent endpoint changes.
