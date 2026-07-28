# PR 20 — synapse-core: expand DATABASE_URL in xtask seed

**Issue:** https://github.com/Synapse-bridgez/synapse-core/issues/1012  
**Impact:** Dev seeding currently always no-ops (`psql` gets literal `${DATABASE_URL}`)  
**File:** `xtask/src/commands/setup.rs`

## Claim
I'll take this — reading `DATABASE_URL` via `std::env::var` in `seed_data()` and passing the resolved value to `psql` (Command does not shell-expand `${…}`).

## Change
Replace `"${DATABASE_URL}"` arg with `std::env::var("DATABASE_URL")` (skip with warning if unset).
