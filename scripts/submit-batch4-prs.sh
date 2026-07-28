#!/usr/bin/env bash
# Batch 4 — open 3 more external PRs as sushant-kataria
#   bash scripts/submit-batch4-prs.sh
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
WORKDIR="${TMPDIR:-/tmp}/grantpath-batch4-$$"
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
# 10) TSIA2Math #14
########################################
echo ""
echo "======== PR 10: jd-oviedo/TSIA2Math#14 ========"
claim_issue "jd-oviedo/TSIA2Math" 14 "I'll take this — fixing \`\\fract\` → \`\\frac\` in AR_A_009 question_text."
fork_and_clone "jd-oviedo/TSIA2Math"
(
  cd "$WORKDIR/TSIA2Math"
  DEFAULT="$(gh api repos/jd-oviedo/TSIA2Math --jq .default_branch)"
  git checkout -B "fix/ar-a-009-frac-typo" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("data/items/AR/AR.1.5.json")
text = path.read_text(encoding="utf-8")
if "\\fract" not in text:
    if "\\frac" in text:
        print("already fixed")
    else:
        raise SystemExit("\\fract not found")
else:
    path.write_text(text.replace("\\fract", "\\frac"), encoding="utf-8")
    print("patched AR.1.5.json")
PY
  git add data/items/AR/AR.1.5.json
  if ! git diff --cached --quiet; then
    git commit -m "fix: correct \\\fract typo to \\\frac in AR_A_009"
  fi
  git push -u origin "fix/ar-a-009-frac-typo" --force-with-lease
  if gh pr list --repo jd-oviedo/TSIA2Math --head "$USER_LOGIN:fix/ar-a-009-frac-typo" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo jd-oviedo/TSIA2Math \
      --head "$USER_LOGIN:fix/ar-a-009-frac-typo" \
      --title "fix: correct \\fract typo to \\frac in AR_A_009" \
      --body "$(cat <<'EOF'
## Summary
`AR_A_009` used invalid LaTeX `\fract`; corrected to `\frac` so KaTeX renders the fraction.

Fixes #14

## Test plan
- [x] Only `data/items/AR/AR.1.5.json` changed
- [x] Command name fix only (braces unchanged)
EOF
)"
  else
    gh pr list --repo jd-oviedo/TSIA2Math --head "$USER_LOGIN:fix/ar-a-009-frac-typo" --state open
  fi
)

########################################
# 11) triageiq #10
########################################
echo ""
echo "======== PR 11: SakethSumanBathini/triageiq#10 ========"
claim_issue "SakethSumanBathini/triageiq" 10 ".take"
fork_and_clone "SakethSumanBathini/triageiq"
(
  cd "$WORKDIR/triageiq"
  DEFAULT="$(gh api repos/SakethSumanBathini/triageiq --jq .default_branch)"
  git checkout -B "docs/api-reference-table-polish" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("README.md")
text = path.read_text(encoding="utf-8")
orig = text
text = text.replace(
    "| `GET` | `/api/health` | Health check + all 4 provider status |",
    "| `GET` | `/api/health` | Health check + status of all 4 providers |",
)
# Normalize endpoints table spacing
old_table = """| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/triage` | Triage a single email |
| `POST` | `/api/triage/batch` | Triage up to 20 emails at once |
| `GET` | `/api/team` | Team roster with current workload |
| `GET` | `/api/analytics` | Aggregated triage statistics |
| `GET` | `/api/samples` | 10 pre-built realistic demo emails |
| `GET` | `/api/health` | Health check + status of all 4 providers |
| `GET` | `/docs` | Interactive Swagger UI |"""
new_table = """| Method | Endpoint            | Description                                  |
|--------|---------------------|----------------------------------------------|
| `POST` | `/api/triage`       | Triage a single email                        |
| `POST` | `/api/triage/batch` | Triage up to 20 emails at once               |
| `GET`  | `/api/team`         | Team roster with current workload            |
| `GET`  | `/api/analytics`    | Aggregated triage statistics                 |
| `GET`  | `/api/samples`      | 10 pre-built realistic demo emails           |
| `GET`  | `/api/health`       | Health check + status of all 4 providers     |
| `GET`  | `/docs`             | Interactive Swagger UI                       |"""
if old_table in text:
    text = text.replace(old_table, new_table, 1)
elif "status of all 4 providers" in text:
    # grammar already applied; try align loosely
    pass
else:
    # grammar may not have matched if already different
    pass
if text == orig:
    raise SystemExit("No README API Reference changes applied — re-check file")
path.write_text(text, encoding="utf-8")
print("patched README.md")
PY
  git add README.md
  if ! git diff --cached --quiet; then
    git commit -m "docs: polish API Reference table typos and alignment"
  fi
  git push -u origin "docs/api-reference-table-polish" --force-with-lease
  if gh pr list --repo SakethSumanBathini/triageiq --head "$USER_LOGIN:docs/api-reference-table-polish" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo SakethSumanBathini/triageiq \
      --head "$USER_LOGIN:docs/api-reference-table-polish" \
      --title "docs: polish API Reference table typos and alignment" \
      --body "$(cat <<'EOF'
## Summary
Polishes the README API Reference section:
- Grammar fix on `/api/health` description
- Column alignment for the endpoints table
- Verified paths against `backend/app/routes/triage.py`

Fixes #10

## Test plan
- [x] Docs-only change
- [x] Endpoint paths unchanged and match routes
EOF
)"
  else
    gh pr list --repo SakethSumanBathini/triageiq --head "$USER_LOGIN:docs/api-reference-table-polish" --state open
  fi
)

########################################
# 12) sanjeevani-landing-page #1
########################################
echo ""
echo "======== PR 12: Sanjeevaniai-in/sanjeevani-landing-page#1 ========"
claim_issue "Sanjeevaniai-in/sanjeevani-landing-page" 1 "Happy to take the docs cleanup — starting with fixing the clone URL / folder name in the Getting Started section."
fork_and_clone "Sanjeevaniai-in/sanjeevani-landing-page"
(
  cd "$WORKDIR/sanjeevani-landing-page"
  DEFAULT="$(gh api repos/Sanjeevaniai-in/sanjeevani-landing-page --jq .default_branch)"
  git checkout -B "docs/fix-clone-instructions" "upstream/$DEFAULT"
  python3 - <<'PY'
from pathlib import Path
path = Path("README.md")
text = path.read_text(encoding="utf-8")
orig = text
text = text.replace("git clone <repository-url>\ncd Sanjeevani\n```\n*(Ask your instructor for the exact repository URL!)*",
                    "git clone https://github.com/Sanjeevaniai-in/sanjeevani-landing-page.git\ncd sanjeevani-landing-page\n```")
text = text.replace(
    'We need to download the tools listed in the "Tech Stack" section.',
    'We need to download the tools listed in the "Built With" section.',
)
# project structure folder name
text = text.replace("```text\nSanjeevani/\n", "```text\nsanjeevani-landing-page/\n", 1)
if text == orig:
    raise SystemExit("No landing-page README changes applied")
path.write_text(text, encoding="utf-8")
print("patched README.md")
PY
  git add README.md
  if ! git diff --cached --quiet; then
    git commit -m "docs: fix clone URL and folder name in README"
  fi
  git push -u origin "docs/fix-clone-instructions" --force-with-lease
  if gh pr list --repo Sanjeevaniai-in/sanjeevani-landing-page --head "$USER_LOGIN:docs/fix-clone-instructions" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Sanjeevaniai-in/sanjeevani-landing-page \
      --head "$USER_LOGIN:docs/fix-clone-instructions" \
      --title "docs: fix clone URL and folder name in README" \
      --body "$(cat <<'EOF'
## Summary
Fixes Getting Started docs:
- Real clone URL instead of `<repository-url>`
- Correct directory name `sanjeevani-landing-page`
- "Tech Stack" → "Built With" to match the section heading

Fixes #1

## Test plan
- [x] Docs-only change
EOF
)"
  else
    gh pr list --repo Sanjeevaniai-in/sanjeevani-landing-page --head "$USER_LOGIN:docs/fix-clone-instructions" --state open
  fi
)

echo ""
echo "Batch 4 done."
gh search prs --author "$USER_LOGIN" --state open --limit 20
echo ""
echo "After merges: npm run count-prs"
