# PR 29 — avenx-js: warn when route guards return undefined

**Issue:** https://github.com/Avenx-JS/avenx-js/issues/639  
**Impact:** DevExp — accidental missing `return` in guards no longer fails silently  
**Files:** `lib/core/runtime/AvenxRouter.js`, `lib/core/runtime/AvenxError.js`, `test/integration/router.test.js`

## Claim
I'll take this — warning via `logger.warn` when a guard’s `canActivate` resolves to `undefined`, while still allowing navigation (least-breaking default).

## Change
1. Add `ROUTER_GUARD_UNDEFINED_RETURN: 'AVX_W27'` + message template in `AvenxError.js`
2. In `#runGuards`, after the guard settles, if `result === undefined` → `logger.warn(formatMessage(...))` then continue to next guard (same as allow/`true`)
3. Integration test: spy/capture logger.warn when a guard returns nothing; confirm boolean/`redirect` returns stay silent
