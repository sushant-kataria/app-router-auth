#!/usr/bin/env bash
# Submit the first Grantpath external PRs as YOUR GitHub user.
# Requires: git, gh (authenticated as sushant-kataria), network.
#
# Usage:
#   gh auth login   # once, as sushant-kataria
#   bash scripts/submit-first-prs.sh
#
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
DISPLAY_NAME="${GIT_AUTHOR_NAME:-Sushant Kataria}"
WORKDIR="${TMPDIR:-/tmp}/grantpath-prs-$$"
mkdir -p "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT

need() { command -v "$1" >/dev/null || { echo "Missing dependency: $1"; exit 1; }; }
need git
need gh

ACTIVE="$(gh api user --jq .login 2>/dev/null || true)"
if [[ -z "$ACTIVE" ]]; then
  echo "Could not read GitHub user (token missing user scope)."
  echo "On your laptop run: gh auth login  (as $USER_LOGIN), then re-run this script."
  exit 1
fi
if [[ "$ACTIVE" != "$USER_LOGIN" ]]; then
  echo "gh is logged in as '$ACTIVE', expected '$USER_LOGIN'."
  echo "Run: gh auth login"
  exit 1
fi

echo "==> Authenticated as $ACTIVE"
echo "==> Work dir: $WORKDIR"

claim_issue() {
  local repo="$1" number="$2" body="$3"
  # Skip if we already commented
  if gh api "repos/$repo/issues/$number/comments" --jq '.[].user.login' | grep -qx "$USER_LOGIN"; then
    echo "    (already commented on $repo#$number)"
    return 0
  fi
  gh issue comment "$number" --repo "$repo" --body "$body" >/dev/null
  echo "    claimed $repo#$number"
}

fork_and_clone() {
  local upstream="$1" # owner/name
  local name="${upstream##*/}"
  echo "==> Forking $upstream"
  gh repo fork "$upstream" --remote=false --default-branch-only 2>/dev/null || true
  # Wait briefly for fork availability
  for _ in 1 2 3 4 5; do
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
    DEFAULT="$(gh api "repos/$upstream" --jq .default_branch)"
    git checkout -B "sync-main" "upstream/$DEFAULT"
  )
}

########################################
# 1) firstcontributions
########################################
echo ""
echo "======== PR 1: firstcontributions ========"
fork_and_clone "firstcontributions/first-contributions"
(
  cd "$WORKDIR/first-contributions"
  git checkout -B "add-$USER_LOGIN"
  if grep -q "github.com/$USER_LOGIN)" Contributors.md; then
    echo "    already listed in Contributors.md"
  else
    printf '\n- [%s](https://github.com/%s)\n' "$DISPLAY_NAME" "$USER_LOGIN" >> Contributors.md
  fi
  git add Contributors.md
  if git diff --cached --quiet; then
    echo "    no commit needed"
  else
    git commit -m "Add $DISPLAY_NAME to Contributors list"
  fi
  git push -u origin "add-$USER_LOGIN" --force-with-lease
  # Open PR if missing
  if gh pr list --repo firstcontributions/first-contributions --author "$USER_LOGIN" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo firstcontributions/first-contributions \
      --head "$USER_LOGIN:add-$USER_LOGIN" \
      --title "Add $DISPLAY_NAME to Contributors list" \
      --body "$(cat <<EOF
## What
Adds my name to \`Contributors.md\` as my first open-source contribution.

## Checklist
- [x] Added \`- [$DISPLAY_NAME](https://github.com/$USER_LOGIN)\` to \`Contributors.md\`
EOF
)"
  else
    echo "    open PR already exists"
    gh pr list --repo firstcontributions/first-contributions --author "$USER_LOGIN" --state open
  fi
)

########################################
# 2) json.ts #11
########################################
echo ""
echo "======== PR 2: abatef/json.ts#11 ========"
claim_issue "abatef/json.ts" 11 "Hi! I'd like to take this — fixing \`childern\` → \`children\` in \`src/main.ts\`."
fork_and_clone "abatef/json.ts"
(
  cd "$WORKDIR/json.ts"
  DEFAULT="$(gh api repos/abatef/json.ts --jq .default_branch)"
  git checkout -B "fix/typo-children-key" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("src/main.ts")
text = path.read_text()
old = '"childern"'
new = '"children"'
if old not in text:
    if new in text:
        print("already fixed")
    else:
        raise SystemExit("expected childern typo not found — issue may be outdated")
else:
    path.write_text(text.replace(old, new, 1))
    print("patched src/main.ts")
PY
  git add src/main.ts
  if git diff --cached --quiet; then
    echo "    no commit needed"
  else
    git commit -m "fix: correct childern typo in test JSON key"
  fi
  git push -u origin "fix/typo-children-key" --force-with-lease
  if gh pr list --repo abatef/json.ts --head "$USER_LOGIN:fix/typo-children-key" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo abatef/json.ts \
      --head "$USER_LOGIN:fix/typo-children-key" \
      --title "fix: correct childern typo in test JSON key" \
      --body "$(cat <<'EOF'
## Summary
Fixes a typo in the sample JSON used by `testNonPrettyJson`.

`childern` → `children`

Fixes #11

## Test plan
- [x] Only `src/main.ts` changed
EOF
)"
  else
    echo "    open PR already exists"
    gh pr list --repo abatef/json.ts --head "$USER_LOGIN:fix/typo-children-key" --state open
  fi
)

########################################
# 3) caspian-sdk #11
########################################
echo ""
echo "======== PR 3: TryCaspian/caspian-sdk#11 ========"
claim_issue "TryCaspian/caspian-sdk" 11 "I'd like to work on this. I'll update the English and Chinese READMEs to 70 Python / 15 TypeScript (85 total) and verify against the test suites."
fork_and_clone "TryCaspian/caspian-sdk"
(
  cd "$WORKDIR/caspian-sdk"
  DEFAULT="$(gh api repos/TryCaspian/caspian-sdk --jq .default_branch)"
  git checkout -B "docs/update-test-counts" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path

def patch(path, replacements):
    p = Path(path)
    text = p.read_text()
    original = text
    for old, new in replacements:
        if old not in text:
            print(f"WARN: pattern not found in {path}: {old!r}")
        else:
            text = text.replace(old, new, 1)
    if text != original:
        p.write_text(text)
        print(f"patched {path}")
    else:
        print(f"no changes for {path}")

patch("README.md", [
    ("80 tests across Python + TS", "85 tests across Python + TS"),
    ("# 10 vitest tests", "# 15 vitest tests"),
])
patch("README.zh-CN.md", [
    ("共 80 个测试", "共 85 个测试"),
    ("# 10 个 vitest 测试", "# 15 个 vitest 测试"),
])
PY
  git add README.md README.zh-CN.md
  if git diff --cached --quiet; then
    echo "    no commit needed"
  else
    git commit -m "docs: update stale Python/TS test counts in READMEs"
  fi
  git push -u origin "docs/update-test-counts" --force-with-lease
  if gh pr list --repo TryCaspian/caspian-sdk --head "$USER_LOGIN:docs/update-test-counts" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo TryCaspian/caspian-sdk \
      --head "$USER_LOGIN:docs/update-test-counts" \
      --title "docs: update stale Python/TS test counts in READMEs" \
      --body "$(cat <<'EOF'
## Summary
Updates documented offline test counts to match the current suites:
- Python: 70
- TypeScript (Vitest): 15
- Combined: 85

Touched both `README.md` and `README.zh-CN.md`.

Fixes #11

## Test plan
- [ ] `uv run pytest --collect-only -q` → 70
- [ ] `cd sdks/typescript && npm test` → 15
- [x] No test code changed
EOF
)"
  else
    echo "    open PR already exists"
    gh pr list --repo TryCaspian/caspian-sdk --head "$USER_LOGIN:docs/update-test-counts" --state open
  fi
)

########################################
# 4) caspian-sdk #16
########################################
echo ""
echo "======== PR 4: TryCaspian/caspian-sdk#16 ========"
claim_issue "TryCaspian/caspian-sdk" 16 "Happy to take this — I'll update the \`start_whatsapp_onboarding\` docstring to drop the non-existent \`list_connections()\` reference and point at \`get_connection()\` / the connection.active event only."
(
  cd "$WORKDIR/caspian-sdk"
  DEFAULT="$(gh api repos/TryCaspian/caspian-sdk --jq .default_branch)"
  git fetch upstream
  git checkout -B "docs/fix-list-connections-docstring" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("sdks/python/src/caspian_sdk/client.py")
text = path.read_text()
old = "Poll list_connections() /\n        get_connection() (or watch for a connection.active event) until it's active."
new = "Poll get_connection()\n        (or watch for a connection.active event) until it's active."
# also try single-line variant
old2 = "Poll list_connections() / get_connection() (or watch for a connection.active event) until it's active."
new2 = "Poll get_connection() (or watch for a connection.active event) until it's active."
if old in text:
    text = text.replace(old, new, 1)
    path.write_text(text)
    print("patched multiline docstring")
elif old2 in text:
    path.write_text(text.replace(old2, new2, 1))
    print("patched single-line docstring")
elif "list_connections()" not in text:
    print("already fixed or wording changed")
else:
    # fallback: softer replace
    text2 = text.replace("list_connections() /", "").replace("list_connections()/", "")
    text2 = text2.replace("Poll  get_connection()", "Poll get_connection()")
    if text2 == text:
        raise SystemExit("could not patch list_connections reference")
    path.write_text(text2)
    print("patched via fallback")
PY
  git add sdks/python/src/caspian_sdk/client.py
  if git diff --cached --quiet; then
    echo "    no commit needed"
  else
    git commit -m "docs: remove stale list_connections reference from onboarding docstring"
  fi
  git push -u origin "docs/fix-list-connections-docstring" --force-with-lease
  if gh pr list --repo TryCaspian/caspian-sdk --head "$USER_LOGIN:docs/fix-list-connections-docstring" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo TryCaspian/caspian-sdk \
      --head "$USER_LOGIN:docs/fix-list-connections-docstring" \
      --title "docs: remove stale list_connections reference from onboarding docstring" \
      --body "$(cat <<'EOF'
## Summary
The `start_whatsapp_onboarding` docstring told callers to poll `list_connections()`, but that method is not part of the public Python SDK.

Updated the guidance to `get_connection()` and/or the `connection.active` event.

Fixes #16

## Test plan
- [x] Docstring-only change
- [x] No new public API added
EOF
)"
  else
    echo "    open PR already exists"
    gh pr list --repo TryCaspian/caspian-sdk --head "$USER_LOGIN:docs/fix-list-connections-docstring" --state open
  fi
)

echo ""
echo "Done. Open PRs authored by you:"
gh search prs --author "$USER_LOGIN" --state open --limit 10
echo ""
echo "Track Anthropic progress later with: npm run count-prs"
