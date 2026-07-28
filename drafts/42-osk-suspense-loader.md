# PR 42 — osk-frontend: use Loader in Suspense fallback

**Startup:** Open Source Kigali  
**Issue:** https://github.com/Open-Source-Kigali/osk-frontend/issues/253  
**File:** `src/App.tsx`

## Claim
I'll take this — replacing the plain `Loading...` Suspense fallback with the shared `<Loader />` component.

## Change
1. Import `Loader` from `./components/UI/Loader`
2. Change `wrap()` fallback from `<div>Loading...</div>` to `<Loader />`

## Competing PRs
None open when drafted.
