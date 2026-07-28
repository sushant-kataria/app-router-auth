# PR 8 — sharibo: rename Sharabo → Sharibo types

**Issue:** https://github.com/crackedstudio/sharibo/issues/55  
**Status when drafted:** open, unassigned, **no competing PR**  
**Primary file:** `packages/client/src/contract.ts` (+ all usages)

## Claim comment

```text
Happy to take this — renaming `SharaboNetworkConfig` / `SharaboClient` to `Sharibo*` across the repo.
```

## Change

Rename everywhere:

- `SharaboNetworkConfig` → `ShariboNetworkConfig`
- `SharaboClient` → `ShariboClient`

```bash
rg -n 'Sharabo'   # find all
# after edit:
rg -ni 'sharabo'  # should be empty in source
```

Known hits start in `packages/client/src/contract.ts` (exports + function signatures). Update `app/` and `scripts/` too if they import the old names.
