# PR 22 — triageiq: honor CORS_ORIGINS allowlist

**Issue:** https://github.com/SakethSumanBathini/triageiq/issues/22  
**Impact:** Security — stop `allow_origins=["*"]` while env allowlist is ignored  
**File:** `backend/app/main.py`

## Claim
`.take` — wiring `CORSMiddleware` to the parsed `CORS_ORIGINS` list (comma-separated), failing closed to localhost when unset/empty.

## Change
`allow_origins=origins` after strip/filter; keep `.env.example` docs for `CORS_ORIGINS`.
