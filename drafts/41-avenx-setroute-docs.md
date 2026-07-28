# PR 41 — avenx-js: document AvenxSandbox.setRoute mock shape

**Startup:** Avenx.js  
**Issue:** https://github.com/Avenx-JS/avenx-js/issues/663  
**File:** `docs/src/content/docs/api-reference/testing.md`

## Claim
I'll take this — documenting the mocked `route` object (`hash`, `page`, `params`) for `setRoute`, with a mount example.

## Change
Under `setRoute(route)`, document:
- `hash` (string) — mocked URL path/hash
- `page` (string) — active page name
- `params` (object) — route params (may include nested query fields as used by the app)
- Example: `sandbox.setRoute({ hash: '#/users', page: 'users', params: { id: '99' } })`

## Competing PRs
None open when drafted.
