#!/usr/bin/env bash
# Shared helpers for Grantpath submit scripts (Windows/Git Bash safe).
# Source from batch scripts:  # shellcheck source=grantpath-submit-lib.sh
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/grantpath-submit-lib.sh"
#
# Provides: grantpath_init_workdir, grantpath_resolve_python, run_python_patch,
#           claim_issue, skip_if_assigned_elsewhere, fork_and_clone
# Expects: USER_LOGIN set before fork/claim helpers are used.

grantpath_init_workdir() {
  local label="${1:-batch}"
  local _uname
  _uname="$(uname -s 2>/dev/null || echo unknown)"
  # SCRIPT_DIR should already be set by the caller (the batch script).
  if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
  # Prefer home-cache on Windows — absolute /tmp paths break git/gh under MSYS.
  if [[ -n "${LOCALAPPDATA:-}" || "$_uname" == MINGW* || "$_uname" == MSYS* || "$_uname" == CYGWIN* ]]; then
    WORKDIR="${GRANTPATH_WORKDIR:-$HOME/.cache/grantpath-${label}-$$}"
  else
    WORKDIR="${GRANTPATH_WORKDIR:-${TMPDIR:-/tmp}/grantpath-${label}-$$}"
  fi
  mkdir -p "$WORKDIR"
  # shellcheck disable=SC2064
  trap 'rm -rf "$WORKDIR"' EXIT
  echo "==> Workdir: $WORKDIR"
}

grantpath_resolve_python() {
  # Windows often has `python` / `py -3` but not `python3`.
  if command -v python3 >/dev/null 2>&1; then
    GRANTPATH_PYTHON=(python3)
  elif command -v python >/dev/null 2>&1; then
    GRANTPATH_PYTHON=(python)
  elif command -v py >/dev/null 2>&1; then
    GRANTPATH_PYTHON=(py -3)
  else
    echo "Missing: python3 (or python / py -3)" >&2
    return 1
  fi
  # Sanity: must be Python 3
  "${GRANTPATH_PYTHON[@]}" -c 'import sys; assert sys.version_info[0] >= 3' >/dev/null 2>&1 \
    || { echo "Need Python 3+"; return 1; }
  echo "==> Python: ${GRANTPATH_PYTHON[*]}"
}

run_python_patch() {
  # CRLF/NUL-normalized Path.read_text / write_text via textio_bootstrap.py
  {
    cat "$SCRIPT_DIR/textio_bootstrap.py"
    echo
    cat
  } | "${GRANTPATH_PYTHON[@]}" -
}

claim_issue() {
  local repo="$1" number="$2" body="$3"
  if gh api "repos/$repo/issues/$number/comments" --jq '.[].user.login' | grep -qx "$USER_LOGIN"; then
    echo "    (already commented on $repo#$number)"
    return 0
  fi
  gh issue comment "$number" --repo "$repo" --body "$body" >/dev/null
  echo "    claimed $repo#$number"
}

skip_if_assigned_elsewhere() {
  local repo="$1" number="$2"
  local assignee state
  state="$(gh api "repos/$repo/issues/$number" --jq .state)"
  if [[ "$state" == "closed" ]]; then
    echo "SKIP $repo#$number — issue is closed"
    return 1
  fi
  assignee="$(gh api "repos/$repo/issues/$number" --jq '.assignees[0].login // empty')"
  if [[ -n "$assignee" && "$assignee" != "$USER_LOGIN" ]]; then
    echo "SKIP $repo#$number — already assigned to @$assignee"
    return 1
  fi
  return 0
}

fork_and_clone() {
  local upstream="$1"
  local name="${upstream##*/}"
  echo "==> Forking $upstream"
  gh repo fork "$upstream" --remote=false --default-branch-only 2>/dev/null || true
  for _ in $(seq 1 15); do
    gh api "repos/$USER_LOGIN/$name" --jq .full_name >/dev/null 2>&1 && break
    sleep 2
  done
  # Relative clone inside WORKDIR — avoids Windows absolute-path bugs with git/gh.
  (
    cd "$WORKDIR"
    rm -rf "$name"
    git clone --depth=50 "https://github.com/$USER_LOGIN/$name.git" "$name"
    cd "$name"
    git remote add upstream "https://github.com/$upstream.git" 2>/dev/null || true
    git fetch upstream
  )
}
