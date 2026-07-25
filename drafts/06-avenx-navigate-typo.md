# PR 6 — avenx-js: fix Router-Guard API typo (`Maps` → `navigate`)

**Issue:** https://github.com/Avenx-JS/avenx-js/issues/618  
**Status when drafted:** open, unassigned, **no competing PR**  
**File:** `docs/src/content/docs/api-reference/router-guard.md` line 34  
**Default branch:** `main`

## Claim comment

```text
Happy to take this — replacing `Maps(hash)` with `navigate(hash)` in the Router-Guard API docs.
```

## Exact change

In `docs/src/content/docs/api-reference/router-guard.md`:

**Before:**
```markdown
- ### `Maps(hash)`
```

**After:**
```markdown
- ### `navigate(hash)`
```

If nearby prose still says `Maps`, update those mentions too — but the issue’s acceptance criteria is the heading/method name.

## Commands

```bash
gh repo fork Avenx-JS/avenx-js --clone
cd avenx-js
git checkout -b docs/fix-navigate-method-name
# edit file as above
git add docs/src/content/docs/api-reference/router-guard.md
git commit -m "docs: replace Maps(hash) with navigate(hash) in router-guard API"
git push -u origin docs/fix-navigate-method-name
gh pr create --repo Avenx-JS/avenx-js \
  --title "docs: replace Maps(hash) with navigate(hash) in router-guard API" \
  --body "$(cat <<'EOF'
## Summary
The Router-Guard API docs listed `Maps(hash)`, but the runtime method is `navigate(hash)`.

Fixes #618

## Test plan
- [x] Docs now document `navigate(hash)`
- [x] Docs-only change
EOF
)"
```
