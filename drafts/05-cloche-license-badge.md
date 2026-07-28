# PR 5 — cloche: fix license badge (MIT → Apache-2.0)

**Issue:** https://github.com/escoffier-labs/cloche/issues/24  
**Status when drafted:** open, unassigned, 0 comments, **no competing PR**  
**File:** `README.md` line 25  
**Default branch:** `master`

## Claim comment

```text
I'd like to take this — updating the README license badge from MIT to Apache-2.0 to match Cargo.toml/LICENSE.
```

## Exact change

**Before:**
```html
  <img src="https://shieldcn.dev/badge/license-MIT-green.svg" alt="MIT license">
```

**After:**
```html
  <img src="https://shieldcn.dev/badge/license-Apache--2.0-green.svg" alt="Apache-2.0 license">
```

(Note the escaped `--` in shield badge URLs for `Apache-2.0`.)

## Commands

```bash
gh repo fork escoffier-labs/cloche --clone
cd cloche
git checkout -b docs/fix-license-badge
# edit README.md as above
git add README.md
git commit -m "docs: fix license badge to Apache-2.0"
git push -u origin docs/fix-license-badge
gh pr create --repo escoffier-labs/cloche \
  --title "docs: fix license badge to Apache-2.0" \
  --body "$(cat <<'EOF'
## Summary
README license badge said MIT while `Cargo.toml`, `LICENSE`, and `CONTRIBUTING.md` are Apache-2.0.

Fixes #24

## Test plan
- [x] Badge alt/text/URL now say Apache-2.0
- [x] No other files changed
EOF
)"
```
