#!/usr/bin/env bash
# Open next 3 external PRs (batch 3).
# Requires: gh auth as sushant-kataria
#
#   bash scripts/submit-batch3-prs.sh
#
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
WORKDIR="${TMPDIR:-/tmp}/grantpath-batch3-$$"
mkdir -p "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT

need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need git; need gh; need python3

ACTIVE="$(gh api user --jq .login 2>/dev/null || true)"
if [[ -z "$ACTIVE" || "$ACTIVE" != "$USER_LOGIN" ]]; then
  echo "Need gh auth as $USER_LOGIN (got: '${ACTIVE:-none}'). Run: gh auth login"
  exit 1
fi

claim_issue() {
  local repo="$1" number="$2" body="$3"
  if gh api "repos/$repo/issues/$number/comments" --jq '.[].user.login' | grep -qx "$USER_LOGIN"; then
    echo "    (already commented on $repo#$number)"
    return 0
  fi
  gh issue comment "$number" --repo "$repo" --body "$body" >/dev/null
  echo "    claimed $repo#$number"
}

fork_and_clone() {
  local upstream="$1"
  local name="${upstream##*/}"
  echo "==> Forking $upstream"
  gh repo fork "$upstream" --remote=false --default-branch-only 2>/dev/null || true
  for _ in $(seq 1 10); do
    gh api "repos/$USER_LOGIN/$name" --jq .full_name >/dev/null 2>&1 && break
    sleep 2
  done
  rm -rf "$WORKDIR/$name"
  gh repo clone "$USER_LOGIN/$name" "$WORKDIR/$name" -- --depth=50
  (
    cd "$WORKDIR/$name"
    git remote add upstream "https://github.com/$upstream.git" 2>/dev/null || true
    git fetch upstream
  )
}

echo "==> Authenticated as $ACTIVE"

########################################
# 7) osk-frontend #277
########################################
echo ""
echo "======== PR 7: Open-Source-Kigali/osk-frontend#277 ========"
claim_issue "Open-Source-Kigali/osk-frontend" 277 "I'd like to take this — fixing the Footer logo alt text typo (\`Opeen\` → \`Open Source Kigali Logo\`)."
fork_and_clone "Open-Source-Kigali/osk-frontend"
(
  cd "$WORKDIR/osk-frontend"
  DEFAULT="$(gh api repos/Open-Source-Kigali/osk-frontend --jq .default_branch)"
  git checkout -B "fix/footer-logo-alt-typo" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("src/components/Footer.tsx")
text = path.read_text()
old = 'alt="Opeen source kigali logo"'
new = 'alt="Open Source Kigali Logo"'
if new in text:
    print("already fixed")
elif old not in text:
    raise SystemExit("expected alt text not found")
else:
    path.write_text(text.replace(old, new, 1))
    print("patched Footer.tsx")
PY
  git add src/components/Footer.tsx
  if ! git diff --cached --quiet; then
    git commit -m "fix: correct Footer logo alt text typo"
  fi
  git push -u origin "fix/footer-logo-alt-typo" --force-with-lease
  if gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/footer-logo-alt-typo" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Open-Source-Kigali/osk-frontend \
      --head "$USER_LOGIN:fix/footer-logo-alt-typo" \
      --title "fix: correct Footer logo alt text typo" \
      --body "$(cat <<'EOF'
## Summary
Fixes Footer logo alt text: `Opeen source kigali logo` → `Open Source Kigali Logo`.

Fixes #277

## Test plan
- [x] Only alt text changed in `src/components/Footer.tsx`
EOF
)"
  else
    gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/footer-logo-alt-typo" --state open
  fi
)

########################################
# 8) sharibo #55
########################################
echo ""
echo "======== PR 8: crackedstudio/sharibo#55 ========"
claim_issue "crackedstudio/sharibo" 55 "Happy to take this — renaming \`SharaboNetworkConfig\` / \`SharaboClient\` to \`Sharibo*\` across the repo."
fork_and_clone "crackedstudio/sharibo"
(
  cd "$WORKDIR/sharibo"
  DEFAULT="$(gh api repos/crackedstudio/sharibo --jq .default_branch)"
  git checkout -B "fix/rename-sharabo-types" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
changed = 0
for path in Path('.').rglob('*'):
    if not path.is_file():
        continue
    if any(p in path.parts for p in ('.git', 'node_modules', 'target', 'dist', '.next')):
        continue
    if path.suffix not in {'.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.md'} and path.name not in {'contract.ts'}:
        # still allow other text-ish
        if path.suffix not in {'.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.json', '.md'}:
            continue
    try:
        text = path.read_text(encoding='utf-8')
    except Exception:
        continue
    if 'Sharabo' not in text:
        continue
    new = text.replace('SharaboNetworkConfig', 'ShariboNetworkConfig').replace('SharaboClient', 'ShariboClient')
    # leftover Sharabo*
    new = new.replace('Sharabo', 'Sharibo')
    if new != text:
        path.write_text(new, encoding='utf-8')
        print('patched', path)
        changed += 1
print('files changed', changed)
if changed == 0:
    raise SystemExit('No Sharabo occurrences found')
PY
  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "fix: rename Sharabo types to Sharibo"
  fi
  git push -u origin "fix/rename-sharabo-types" --force-with-lease
  if gh pr list --repo crackedstudio/sharibo --head "$USER_LOGIN:fix/rename-sharabo-types" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo crackedstudio/sharibo \
      --head "$USER_LOGIN:fix/rename-sharabo-types" \
      --title "fix: rename Sharabo types to Sharibo" \
      --body "$(cat <<'EOF'
## Summary
Renames misspelled exported types/usages:
- `SharaboNetworkConfig` → `ShariboNetworkConfig`
- `SharaboClient` → `ShariboClient`

Fixes #55

## Test plan
- [x] `rg -ni sharabo` clean in source
- [ ] typecheck / workspace tests if available
EOF
)"
  else
    gh pr list --repo crackedstudio/sharibo --head "$USER_LOGIN:fix/rename-sharabo-types" --state open
  fi
)

########################################
# 9) sharibo #6
########################################
echo ""
echo "======== PR 9: crackedstudio/sharibo#6 ========"
claim_issue "crackedstudio/sharibo" 6 "I'll take this — removing the broken \`docs/demo.gif\` README image so the docs don't 404."
(
  cd "$WORKDIR/sharibo"
  DEFAULT="$(gh api repos/crackedstudio/sharibo --jq .default_branch)"
  git fetch upstream
  git checkout -B "docs/remove-broken-demo-gif" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path('README.md')
text = path.read_text(encoding='utf-8')
line = '![Sharibo demo — live proof generation and anonymous claim](docs/demo.gif)\n'
# also handle possible dash variants
import re
new, n = re.subn(r'!\[Sharibo demo[^\]]*\]\(docs/demo\.gif\)\n?', '', text, count=1)
if n == 0:
    if 'docs/demo.gif' not in text:
        print('already fixed')
    else:
        raise SystemExit('demo.gif reference found but pattern unmatched')
else:
    path.write_text(new, encoding='utf-8')
    print('removed broken demo.gif image markdown')
PY
  git add README.md
  if ! git diff --cached --quiet; then
    git commit -m "docs: remove broken demo.gif README image"
  fi
  git push -u origin "docs/remove-broken-demo-gif" --force-with-lease
  if gh pr list --repo crackedstudio/sharibo --head "$USER_LOGIN:docs/remove-broken-demo-gif" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo crackedstudio/sharibo \
      --head "$USER_LOGIN:docs/remove-broken-demo-gif" \
      --title "docs: remove broken demo.gif README image" \
      --body "$(cat <<'EOF'
## Summary
`README.md` linked to `docs/demo.gif`, which does not exist. Removed the broken image markdown (live app / demo links remain).

Fixes #6

## Test plan
- [x] No remaining `docs/demo.gif` image reference
- [x] Docs-only change
EOF
)"
  else
    gh pr list --repo crackedstudio/sharibo --head "$USER_LOGIN:docs/remove-broken-demo-gif" --state open
  fi
)

echo ""
echo "Done."
gh search prs --author "$USER_LOGIN" --state open --limit 20
