#!/usr/bin/env bash
# Open two replacement external PRs (caspian-sdk replacements).
# Requires: git, gh authenticated as sushant-kataria
#
#   bash scripts/submit-next-prs.sh
#
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
WORKDIR="${TMPDIR:-/tmp}/grantpath-next-prs-$$"
mkdir -p "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT

need() { command -v "$1" >/dev/null || { echo "Missing dependency: $1"; exit 1; }; }
need git
need gh
need python3

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
  for _ in 1 2 3 4 5 6 7 8; do
    if gh api "repos/$USER_LOGIN/$name" --jq .full_name >/dev/null 2>&1; then
      break
    fi
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
# 5) cloche #24
########################################
echo ""
echo "======== PR 5: escoffier-labs/cloche#24 ========"
claim_issue "escoffier-labs/cloche" 24 "I'd like to take this — updating the README license badge from MIT to Apache-2.0 to match Cargo.toml/LICENSE."
fork_and_clone "escoffier-labs/cloche"
(
  cd "$WORKDIR/cloche"
  DEFAULT="$(gh api repos/escoffier-labs/cloche --jq .default_branch)"
  git checkout -B "docs/fix-license-badge" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("README.md")
text = path.read_text()
old = 'https://shieldcn.dev/badge/license-MIT-green.svg" alt="MIT license"'
new = 'https://shieldcn.dev/badge/license-Apache--2.0-green.svg" alt="Apache-2.0 license"'
if new.split('"')[0] in text and "Apache-2.0 license" in text:
    print("already fixed")
elif old not in text:
    # try looser match
    if "license-MIT" in text:
        text = text.replace("license-MIT-green.svg", "license-Apache--2.0-green.svg")
        text = text.replace('alt="MIT license"', 'alt="Apache-2.0 license"')
        path.write_text(text)
        print("patched via loose match")
    else:
        raise SystemExit("MIT license badge not found — re-check README")
else:
    path.write_text(text.replace(old, new, 1))
    print("patched README.md")
PY
  git add README.md
  if ! git diff --cached --quiet; then
    git commit -m "docs: fix license badge to Apache-2.0"
  fi
  git push -u origin "docs/fix-license-badge" --force-with-lease
  if gh pr list --repo escoffier-labs/cloche --head "$USER_LOGIN:docs/fix-license-badge" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo escoffier-labs/cloche \
      --head "$USER_LOGIN:docs/fix-license-badge" \
      --title "docs: fix license badge to Apache-2.0" \
      --body "$(cat <<'EOF'
## Summary
README license badge said MIT while `Cargo.toml`, `LICENSE`, and `CONTRIBUTING.md` are Apache-2.0.

Fixes #24

## Test plan
- [x] Badge now says Apache-2.0
- [x] Docs-only change
EOF
)"
  else
    gh pr list --repo escoffier-labs/cloche --head "$USER_LOGIN:docs/fix-license-badge" --state open
  fi
)

########################################
# 6) avenx-js #618
########################################
echo ""
echo "======== PR 6: Avenx-JS/avenx-js#618 ========"
claim_issue "Avenx-JS/avenx-js" 618 "Happy to take this — replacing \`Maps(hash)\` with \`navigate(hash)\` in the Router-Guard API docs."
fork_and_clone "Avenx-JS/avenx-js"
(
  cd "$WORKDIR/avenx-js"
  DEFAULT="$(gh api repos/Avenx-JS/avenx-js --jq .default_branch)"
  git checkout -B "docs/fix-navigate-method-name" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("docs/src/content/docs/api-reference/router-guard.md")
text = path.read_text()
if "`navigate(hash)`" in text and "`Maps(hash)`" not in text:
    print("already fixed")
elif "`Maps(hash)`" not in text:
    raise SystemExit("Maps(hash) not found — re-check docs file")
else:
    path.write_text(text.replace("`Maps(hash)`", "`navigate(hash)`"))
    print("patched router-guard.md")
PY
  git add docs/src/content/docs/api-reference/router-guard.md
  if ! git diff --cached --quiet; then
    git commit -m "docs: replace Maps(hash) with navigate(hash) in router-guard API"
  fi
  git push -u origin "docs/fix-navigate-method-name" --force-with-lease
  if gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:docs/fix-navigate-method-name" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Avenx-JS/avenx-js \
      --head "$USER_LOGIN:docs/fix-navigate-method-name" \
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
  else
    gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:docs/fix-navigate-method-name" --state open
  fi
)

echo ""
echo "Done. Your open external PRs:"
gh search prs --author "$USER_LOGIN" --state open --limit 15
echo ""
echo "After merges: npm run count-prs"
