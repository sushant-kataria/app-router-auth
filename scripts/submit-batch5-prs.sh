#!/usr/bin/env bash
# Batch 5 — open 3 more external PRs as sushant-kataria
#   bash scripts/submit-batch5-prs.sh
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
WORKDIR="${TMPDIR:-/tmp}/grantpath-batch5-$$"
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
# 13) E-vara #184
########################################
echo ""
echo "======== PR 13: SHAURYASANYAL3/E-vara#184 ========"
claim_issue "SHAURYASANYAL3/E-vara" 184 "I'll take this — updating README Getting Started with clone + \`npm run dev\` (setup was build-only / outdated)."
fork_and_clone "SHAURYASANYAL3/E-vara"
(
  cd "$WORKDIR/E-vara"
  DEFAULT="$(gh api repos/SHAURYASANYAL3/E-vara --jq .default_branch)"
  git checkout -B "docs/update-local-setup" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("README.md")
text = path.read_text(encoding="utf-8")
old = """### Deployment

1. **Database Setup**: Execute `schema.sql` in the Supabase SQL Editor.
2. **Edge Functions**: Deploy monitoring functions:
   ```bash
   supabase functions deploy breach-check
   ```
3. **Frontend**:
   ```bash
   npm install
   npm run build
   ```"""
new = """### Local setup

```bash
git clone https://github.com/SHAURYASANYAL3/E-vara.git
cd E-vara
npm install
```

Create a `.env` file in the project root (there is no committed `.env.example`):

```env
VITE_SUPABASE_URL=your_instance_url
VITE_SUPABASE_ANON_KEY=your_anon_key
```

Start the dev server:

```bash
npm run dev
```

### Deployment

1. **Database Setup**: Execute `schema.sql` in the Supabase SQL Editor.
2. **Edge Functions**: Deploy monitoring functions:
   ```bash
   supabase functions deploy breach-check
   ```
3. **Frontend**:
   ```bash
   npm install
   npm run build
   ```"""
if "npm run dev" in text and "git clone https://github.com/SHAURYASANYAL3/E-vara.git" in text:
    print("already updated")
elif old not in text:
    raise SystemExit("Expected Deployment section not found — re-check README")
else:
    # Also dedupe Environment Configuration if we inlined env — keep existing env section
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched README.md")
PY
  git add README.md
  if ! git diff --cached --quiet; then
    git commit -m "docs: update README with local clone and npm run dev setup"
  fi
  git push -u origin "docs/update-local-setup" --force-with-lease
  if gh pr list --repo SHAURYASANYAL3/E-vara --head "$USER_LOGIN:docs/update-local-setup" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo SHAURYASANYAL3/E-vara \
      --head "$USER_LOGIN:docs/update-local-setup" \
      --title "docs: update README with local clone and npm run dev setup" \
      --body "$(cat <<'EOF'
## Summary
Updates Getting Started so local development is clear:
- clone URL + `cd E-vara`
- `npm install` / `npm run dev`
- manual `.env` note (no `.env.example` in-repo)

Keeps existing deployment steps.

Fixes #184

## Test plan
- [x] Docs-only change
- [x] Scripts match `package.json` (`dev`, `build`)
EOF
)"
  else
    gh pr list --repo SHAURYASANYAL3/E-vara --head "$USER_LOGIN:docs/update-local-setup" --state open
  fi
)

########################################
# 14) sanjeevani-mobile-apps #2
########################################
echo ""
echo "======== PR 14: Sanjeevaniai-in/sanjeevani-mobile-apps#2 ========"
claim_issue "Sanjeevaniai-in/sanjeevani-mobile-apps" 2 "Happy to help with docs — adding a proper clone step to Getting Started and aligning the Dart version badge with the Tech Stack table."
fork_and_clone "Sanjeevaniai-in/sanjeevani-mobile-apps"
(
  cd "$WORKDIR/sanjeevani-mobile-apps"
  DEFAULT="$(gh api repos/Sanjeevaniai-in/sanjeevani-mobile-apps --jq .default_branch)"
  git checkout -B "docs/readme-clone-and-dart-badge" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("README.md")
text = path.read_text(encoding="utf-8")
orig = text
text = text.replace(
    "https://img.shields.io/badge/Dart-3.5%2B-0175C2",
    "https://img.shields.io/badge/Dart-3.9%2B-0175C2",
)
clone_block = """### Clone this repository

```bash
git clone https://github.com/Sanjeevaniai-in/sanjeevani-mobile-apps.git
cd sanjeevani-mobile-apps
```

"""
marker = "### 🔧 Running Sanjeevani Hub"
if "git clone https://github.com/Sanjeevaniai-in/sanjeevani-mobile-apps.git" in text:
    print("clone already present")
elif marker not in text:
    raise SystemExit("Running Hub marker not found")
else:
    text = text.replace(marker, clone_block + marker, 1)
if text == orig:
    raise SystemExit("No mobile README changes applied")
path.write_text(text, encoding="utf-8")
print("patched README.md")
PY
  git add README.md
  if ! git diff --cached --quiet; then
    git commit -m "docs: add clone step and align Dart version badge"
  fi
  git push -u origin "docs/readme-clone-and-dart-badge" --force-with-lease
  if gh pr list --repo Sanjeevaniai-in/sanjeevani-mobile-apps --head "$USER_LOGIN:docs/readme-clone-and-dart-badge" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Sanjeevaniai-in/sanjeevani-mobile-apps \
      --head "$USER_LOGIN:docs/readme-clone-and-dart-badge" \
      --title "docs: add clone step and align Dart version badge" \
      --body "$(cat <<'EOF'
## Summary
- Adds clone instructions before Running Hub/Nexus
- Aligns Dart badge with Tech Stack (`3.9+`)

Fixes #2

## Test plan
- [x] Docs-only change
EOF
)"
  else
    gh pr list --repo Sanjeevaniai-in/sanjeevani-mobile-apps --head "$USER_LOGIN:docs/readme-clone-and-dart-badge" --state open
  fi
)

########################################
# 15) sanjeevani-core-backend #2
########################################
echo ""
echo "======== PR 15: Sanjeevaniai-in/sanjeevani-core-backend#2 ========"
claim_issue "Sanjeevaniai-in/sanjeevani-core-backend" 2 "I'll take a focused docs fix — replacing CONTRIBUTING clone placeholders with this repo's real name so newcomers aren't stuck on \`<REPOSITORY-NAME>\`."
fork_and_clone "Sanjeevaniai-in/sanjeevani-core-backend"
(
  cd "$WORKDIR/sanjeevani-core-backend"
  DEFAULT="$(gh api repos/Sanjeevaniai-in/sanjeevani-core-backend --jq .default_branch)"
  git checkout -B "docs/contributing-clone-paths" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("CONTRIBUTING.md")
text = path.read_text(encoding="utf-8")
old = """```bash
git clone https://github.com/<YOUR-USERNAME>/<REPOSITORY-NAME>.git
cd <REPOSITORY-NAME>
```"""
new = """```bash
git clone https://github.com/<YOUR-USERNAME>/sanjeevani-core-backend.git
cd sanjeevani-core-backend
```"""
if "sanjeevani-core-backend.git" in text and "<REPOSITORY-NAME>" not in text:
    print("already fixed")
elif old not in text:
    raise SystemExit("Expected CONTRIBUTING clone block not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched CONTRIBUTING.md")
PY
  git add CONTRIBUTING.md
  if ! git diff --cached --quiet; then
    git commit -m "docs: use real repo name in CONTRIBUTING clone steps"
  fi
  git push -u origin "docs/contributing-clone-paths" --force-with-lease
  if gh pr list --repo Sanjeevaniai-in/sanjeevani-core-backend --head "$USER_LOGIN:docs/contributing-clone-paths" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Sanjeevaniai-in/sanjeevani-core-backend \
      --head "$USER_LOGIN:docs/contributing-clone-paths" \
      --title "docs: use real repo name in CONTRIBUTING clone steps" \
      --body "$(cat <<'EOF'
## Summary
Replaces `<REPOSITORY-NAME>` placeholders in CONTRIBUTING with `sanjeevani-core-backend`.

Fixes #2

## Test plan
- [x] Docs-only change
EOF
)"
  else
    gh pr list --repo Sanjeevaniai-in/sanjeevani-core-backend --head "$USER_LOGIN:docs/contributing-clone-paths" --state open
  fi
)

echo ""
echo "Batch 5 done."
gh search prs --author "$USER_LOGIN" --state open --limit 25
