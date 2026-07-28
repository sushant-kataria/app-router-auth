# PR 40 — avenx-js: document StateFactory options / onChange

**Startup:** Avenx.js  
**Issue:** https://github.com/Avenx-JS/avenx-js/issues/664  
**File:** `docs/src/content/docs/api-reference/utils.md`

## Claim
I'll take this — documenting `create(initialState, options)` schema, especially `options.onChange` (zero-arg callback on set/delete), with a standalone example.

## Change
Expand the StateFactory `create()` docs with:
- `options.onChange` — `() => void`, invoked after reactive property set/delete (and related mutations)
- Note other forwarded options (`computedKeys`, etc.) at a high level
- Example using standalone `StateFactory` outside a component

## Competing PRs
None open when drafted.
