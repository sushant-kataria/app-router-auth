#!/usr/bin/env bash
# Apply portfolio-polish READMEs + light finish patches to owned repos.
# Must run locally as sushant-kataria (cloud agent cannot push to these repos).
#
#   bash scripts/polish-owned-repos.sh
#   DRY_RUN=1 bash scripts/polish-owned-repos.sh
#   SKIP_HUSHVOICE_MERGE=1 bash scripts/polish-owned-repos.sh
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACK="$ROOT/portfolio-polish"
DRY_RUN="${DRY_RUN:-0}"
SKIP_HUSHVOICE_MERGE="${SKIP_HUSHVOICE_MERGE:-0}"

_uname="$(uname -s 2>/dev/null || echo unknown)"
if [[ -n "${LOCALAPPDATA:-}" || "$_uname" == MINGW* || "$_uname" == MSYS* || "$_uname" == CYGWIN* ]]; then
  WORKDIR="${GRANTPATH_WORKDIR:-$HOME/.cache/grantpath-polish-$$}"
else
  WORKDIR="${GRANTPATH_WORKDIR:-${TMPDIR:-/tmp}/grantpath-polish-$$}"
fi
mkdir -p "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT

need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need git; need gh; need python3

ACTIVE="$(gh api user --jq .login 2>/dev/null || true)"
if [[ -z "$ACTIVE" || "$ACTIVE" != "$USER_LOGIN" ]]; then
  echo "Need gh auth as $USER_LOGIN (got: '${ACTIVE:-none}'). Run: gh auth login"
  exit 1
fi

echo "==> Authenticated as $ACTIVE"
echo "==> Pack: $PACK"
echo "==> Workdir: $WORKDIR"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY: $*"
    return 0
  fi
  "$@"
}

########################################
# 1) GitHub descriptions
########################################
echo ""
echo "======== Updating repo descriptions ========"
python3 - <<PY
import json, subprocess, os
from pathlib import Path
descs = json.loads(Path(r"$PACK/descriptions.json").read_text())
user = "$USER_LOGIN"
dry = os.environ.get("DRY_RUN", "0") == "1"
for name, desc in descs.items():
    short = desc if len(desc) <= 70 else desc[:70] + "…"
    print(f"  {name}: {short}")
    if dry:
        continue
    subprocess.run(
        ["gh", "repo", "edit", f"{user}/{name}", "--description", desc],
        check=False,
    )
PY

########################################
# 2) Finish hushvoice (merge draft PR #1)
########################################
echo ""
echo "======== hushvoice: publish unfinished app ========"
if [[ "$SKIP_HUSHVOICE_MERGE" == "1" ]]; then
  echo "SKIP_HUSHVOICE_MERGE=1 — leaving draft PR alone"
else
  STATE="$(gh pr view 1 --repo "$USER_LOGIN/hushvoice" --json state,isDraft,mergeable --jq '{state,isDraft,mergeable}' 2>/dev/null || echo '{}')"
  echo "  PR #1: $STATE"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY: would gh pr ready + merge hushvoice#1"
  else
    # Mark ready if still draft, then merge into main
    gh pr ready 1 --repo "$USER_LOGIN/hushvoice" 2>/dev/null || true
    MERGED="$(gh pr view 1 --repo "$USER_LOGIN/hushvoice" --json state --jq .state)"
    if [[ "$MERGED" != "MERGED" ]]; then
      gh pr merge 1 --repo "$USER_LOGIN/hushvoice" --merge --delete-branch=false || {
        echo "WARN: could not auto-merge hushvoice#1 — open it and merge in the UI"
        gh pr view 1 --repo "$USER_LOGIN/hushvoice" --web 2>/dev/null || true
      }
    else
      echo "  already merged"
    fi
  fi
fi

########################################
# 3) Apply file packs per repo
########################################
apply_repo_pack() {
  local repo="$1"
  local pack_dir="$PACK/repos/$repo"
  [[ -d "$pack_dir" ]] || return 0

  echo ""
  echo "======== $repo ========"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY: would copy files from $pack_dir and push"
    find "$pack_dir" -type f | sed 's|^|  |'
    return 0
  fi

  local dest="$WORKDIR/$repo"
  rm -rf "$dest"
  git clone --depth=20 "https://github.com/$USER_LOGIN/$repo.git" "$dest"
  (
    cd "$dest"
    DEFAULT="$(gh api "repos/$USER_LOGIN/$repo" --jq .default_branch)"
    git checkout -B "cursor/portfolio-polish-ba5d" "origin/$DEFAULT" 2>/dev/null \
      || git checkout -B "cursor/portfolio-polish-ba5d"

    # Copy pack files (preserve relative paths)
    python3 - <<PY
from pathlib import Path
import shutil
src = Path(r"$pack_dir")
dst = Path(r"$dest")
for f in src.rglob("*"):
    if not f.is_file():
        continue
    # special: package.name.txt → rewrite package.json name
    if f.name == "package.name.txt":
        name = f.read_text(encoding="utf-8").strip()
        pkg = dst / "package.json"
        if pkg.exists():
            import json
            data = json.loads(pkg.read_text(encoding="utf-8"))
            data["name"] = name
            pkg.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
            print("renamed package.json name ->", name)
        continue
    rel = f.relative_to(src)
    target = dst / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(f, target)
    print("copied", rel)
PY

    # docker-app: drop committed node_modules from the index if present
    if [[ "$repo" == "docker-app" ]] && [[ -d node_modules ]]; then
      git rm -r --cached node_modules 2>/dev/null || true
    fi

    git add -A
    if git diff --cached --quiet; then
      echo "  (no file changes)"
      return 0
    fi

    git commit -m "$(cat <<EOF
docs: presentable README and project polish

Replace boilerplate/empty docs, add env examples where missing, and
finish obvious unfinished stubs for a cleaner public portfolio.
EOF
)"
    git push -u origin "cursor/portfolio-polish-ba5d" --force-with-lease

    # Open PR (or merge directly for tiny doc repos — PR is safer)
    if gh pr list --repo "$USER_LOGIN/$repo" --head "$USER_LOGIN:cursor/portfolio-polish-ba5d" --state open --json number --jq 'length' | grep -qx 0; then
      gh pr create --repo "$USER_LOGIN/$repo" \
        --head "$USER_LOGIN:cursor/portfolio-polish-ba5d" \
        --base "$DEFAULT" \
        --title "docs: presentable README and project polish" \
        --body "$(cat <<EOF
## Summary
Makes this public repo presentable: real README, env examples, and light finish patches (replacing create-next-app / Vite / Nest boilerplate where it was still showing).

Part of the Grantpath portfolio polish pass.

## Test plan
- [ ] README matches the actual project
- [ ] \`npm install && npm run dev\` (or equivalent) still works when applicable
EOF
)"
    else
      gh pr list --repo "$USER_LOGIN/$repo" --head "$USER_LOGIN:cursor/portfolio-polish-ba5d" --state open
    fi
  )
}

# Apply in priority order, then archives
for repo in \
  sweep-app \
  squarepg-app \
  pg-analytics-dashboard \
  auth-verify \
  ory-auth-app \
  ory-login-sample-app \
  terraformAKS \
  docker-app \
  jenkins \
  terraform-azure-infra \
  azuredevops-cicd-del \
  project1ncpl \
  azure-automation \
  AzureAutomationScripts \
  helloworld \
  DSpythontrack \
  Feature-engineering-and-classification-models \
  Teachers-without-frontiers \
  Hockey_case_study \
  Vanderbilt_case_study \
  Decision-tree-using-Random-Forest-
do
  apply_repo_pack "$repo"
done

echo ""
echo "======== Done ========"
echo "Review the opened PRs, merge when happy."
echo "hushvoice: confirm main now has the studio app (PR #1 merged)."
echo "Already-strong READMEs (pageagent, ctxpack, Octo-health-mcp, Resume-Roast-AI, orchestrate-mcp, gharsetu) only got description updates."
