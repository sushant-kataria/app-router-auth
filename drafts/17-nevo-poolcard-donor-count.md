# PR 17 — Nevo: remove mock donor-count fallback in PoolCard

**Issue:** https://github.com/Web3Novalabs/Nevo/issues/860  
**Impact:** Stops fake donor numbers in production UI (project “no mock data” rule)  
**File:** `nevo_frontend/components/PoolCard.tsx`

**Status when drafted:** open, unassigned, no competing PR

## Claim

```text
I'll take this — removing the hardcoded id-based donor-count mock in `PoolCard` so missing `donorCount` renders as 0 instead of fake numbers.
```

## Change summary

Replace:

```ts
const displayDonorCount =
  donorCount ??
  (id === '1' ? 42 : id === '2' ? 87 : id === '3' ? 31 : Math.floor((raised * 7.3) / 100) + 1);
```

With:

```ts
const displayDonorCount = donorCount ?? 0;
```

Footer still shows `N donor(s)` including the honest zero state.
