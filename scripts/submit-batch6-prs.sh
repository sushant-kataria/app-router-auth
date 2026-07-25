#!/usr/bin/env bash
# Batch 6 — higher-impact external PRs (code / packaging, not typo docs)
#   bash scripts/submit-batch6-prs.sh
#
# Windows/Git Bash notes:
# - Uses git clone (not `gh repo clone`) to avoid path bugs under MSYS.
# - Workdir defaults under $HOME/.cache on Windows-like shells.
# - Python patches normalize CRLF/NUL via scripts/textio_bootstrap.py.
#
# Status: Nevo / c-text-editor / nl6 already submitted; Linkora skipped (assigned).
# Re-running is safe — skips assigned issues and existing open PR heads.
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prefer a home-cache workdir on Windows (MSYS/MINGW/Cygwin); /tmp pathing breaks gh/git there.
_uname="$(uname -s 2>/dev/null || echo unknown)"
if [[ -n "${LOCALAPPDATA:-}" || "$_uname" == MINGW* || "$_uname" == MSYS* || "$_uname" == CYGWIN* ]]; then
  WORKDIR="${GRANTPATH_WORKDIR:-$HOME/.cache/grantpath-batch6-$$}"
else
  WORKDIR="${GRANTPATH_WORKDIR:-${TMPDIR:-/tmp}/grantpath-batch6-$$}"
fi
mkdir -p "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT

need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need git; need gh; need python3

# Run a patch with CRLF/NUL-normalized Path.read_text / write_text.
run_python_patch() {
  {
    cat "$SCRIPT_DIR/textio_bootstrap.py"
    echo
    cat
  } | python3 -
}

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
  for _ in $(seq 1 10); do
    gh api "repos/$USER_LOGIN/$name" --jq .full_name >/dev/null 2>&1 && break
    sleep 2
  done
  rm -rf "$WORKDIR/$name"
  # git clone is more reliable than `gh repo clone` on Windows/MSYS pathing.
  git clone --depth=50 "https://github.com/$USER_LOGIN/$name.git" "$WORKDIR/$name"
  (
    cd "$WORKDIR/$name"
    git remote add upstream "https://github.com/$upstream.git" 2>/dev/null || true
    git fetch upstream
  )
}

echo "==> Authenticated as $ACTIVE"
echo "==> Batch 6 targets: Linkora#941 (likely skip), Nevo#860, c-text-editor#3, nl6#342"
echo "==> Workdir: $WORKDIR"

########################################
# 16) Linkora-social #941
########################################
echo ""
echo "======== PR 16: Epta-Node/Linkora-social#941 ========"
if skip_if_assigned_elsewhere "Epta-Node/Linkora-social" 941; then
claim_issue "Epta-Node/Linkora-social" 941 "I'll take this — adding a minimum username length (3) in \`validate_username\`, aligning the existing unit tests, and wiring \`set_profile_tests\` into the test module so the panic expectations actually run."
fork_and_clone "Epta-Node/Linkora-social"
(
  cd "$WORKDIR/Linkora-social"
  DEFAULT="$(gh api repos/Epta-Node/Linkora-social --jq .default_branch)"
  git checkout -B "fix/username-min-length" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path

# 1) validation.rs
val = Path("packages/contracts/contracts/linkora-contracts/src/validation.rs")
text = val.read_text(encoding="utf-8")
if "MIN_USERNAME_LEN" not in text:
    text = text.replace(
        "pub const MAX_NAME_LEN: u32 = 50;\n",
        "pub const MAX_NAME_LEN: u32 = 50;\npub const MIN_USERNAME_LEN: u32 = 3;\n",
        1,
    )
old_fn = """pub fn validate_username(env: &Env, username: &String) {
    validate_string_max_len(env, "username", username, MAX_NAME_LEN);
}"""
new_fn = """pub fn validate_username(env: &Env, username: &String) {
    require_with_error!(
        env,
        username.len() >= MIN_USERNAME_LEN,
        "username too short"
    );
    validate_string_max_len(env, "username", username, MAX_NAME_LEN);
}"""
if "username too short" not in text:
    if old_fn not in text:
        raise SystemExit("validate_username body not found")
    text = text.replace(old_fn, new_fn, 1)
val.write_text(text, encoding="utf-8")
print("patched validation.rs")

# 2) test.rs — flip test_username_too_short to should_panic
test_rs = Path("packages/contracts/contracts/linkora-contracts/src/test.rs")
t = test_rs.read_text(encoding="utf-8")
old_test = """#[test]
fn test_username_too_short() {
    let env = Env::default();
    env.mock_all_auths();
    let (client, _, _) = setup_contract(&env);

    let user = Address::generate(&env);
    let token = Address::generate(&env);

    // 2-character username is valid (no min length enforcement in contract)
    client.set_profile(&user, &String::from_str(&env, "ab"), &token);
    let profile = client.get_profile(&user).unwrap();
    assert_eq!(profile.username, String::from_str(&env, "ab"));
}"""
new_test = """#[test]
#[should_panic(expected = "username too short")]
fn test_username_too_short() {
    let env = Env::default();
    env.mock_all_auths();
    let (client, _, _) = setup_contract(&env);

    let user = Address::generate(&env);
    let token = Address::generate(&env);

    // 2-character username must be rejected (MIN_USERNAME_LEN = 3)
    client.set_profile(&user, &String::from_str(&env, "ab"), &token);
}"""
if '#[should_panic(expected = "username too short")]\nfn test_username_too_short()' in t:
    print("test_username_too_short already updated")
elif old_test not in t:
    raise SystemExit("test_username_too_short block not found — re-check test.rs")
else:
    t = t.replace(old_test, new_test, 1)
    test_rs.write_text(t, encoding="utf-8")
    print("patched test.rs")

# 3) wire set_profile_tests
mod_rs = Path("packages/contracts/contracts/linkora-contracts/src/tests/mod.rs")
mod_text = mod_rs.read_text(encoding="utf-8")
if "set_profile_tests" not in mod_text:
    mod_rs.write_text(mod_text.rstrip() + "\nmod set_profile_tests;\n", encoding="utf-8")
    print("patched tests/mod.rs")
else:
    print("tests/mod.rs already wires set_profile_tests")

# 4) rewrite set_profile_tests.rs (was nested/broken; align with invariants helpers)
spf = Path("packages/contracts/contracts/linkora-contracts/src/tests/set_profile_tests.rs")
spf.write_text(
    '''//! Unit tests for `set_profile` username length validation (issue #941).

#![cfg(test)]

use crate::*;
use soroban_sdk::{testutils::Address as _, Address, Env, String};

fn setup_test_env(env: &Env) -> (LinkoraContractClient<'_>, Address, Address) {
    let contract_id = env.register(LinkoraContract, ());
    let client = LinkoraContractClient::new(env, &contract_id);
    let admin = Address::generate(env);
    let treasury = Address::generate(env);
    client.initialize(&admin, &treasury, &0);
    (client, admin, treasury)
}

#[test]
#[should_panic(expected = "username too short")]
fn test_set_profile_username_too_short_panics() {
    let env = Env::default();
    env.mock_all_auths();
    let (client, _, _) = setup_test_env(&env);

    let user = Address::generate(&env);
    let token = Address::generate(&env);
    // 2-character username should panic
    client.set_profile(&user, &String::from_str(&env, "ab"), &token);
}

#[test]
fn test_set_profile_username_minimum_length_succeeds() {
    let env = Env::default();
    env.mock_all_auths();
    let (client, _, _) = setup_test_env(&env);

    let user = Address::generate(&env);
    let token = Address::generate(&env);
    // 3-character username should succeed
    client.set_profile(&user, &String::from_str(&env, "abc"), &token);
    let profile = client.get_profile(&user).unwrap();
    assert_eq!(profile.username, String::from_str(&env, "abc"));
}
''',
    encoding="utf-8",
)
print("rewrote set_profile_tests.rs")
PY
  git add \
    packages/contracts/contracts/linkora-contracts/src/validation.rs \
    packages/contracts/contracts/linkora-contracts/src/test.rs \
    packages/contracts/contracts/linkora-contracts/src/tests/mod.rs \
    packages/contracts/contracts/linkora-contracts/src/tests/set_profile_tests.rs
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(contracts): enforce minimum username length of 3

validate_username only checked the max length, so 1–2 character names
could be registered. Add MIN_USERNAME_LEN, reject shorter names, update
the conflicting unit test, and wire set_profile_tests into the suite.

Fixes #941
EOF
)"
  fi
  git push -u origin "fix/username-min-length" --force-with-lease
  if gh pr list --repo Epta-Node/Linkora-social --head "$USER_LOGIN:fix/username-min-length" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Epta-Node/Linkora-social \
      --head "$USER_LOGIN:fix/username-min-length" \
      --title "fix(contracts): enforce minimum username length of 3" \
      --body "$(cat <<'EOF'
## Summary
`validate_username` only enforced a maximum length, so users could register 1–2 character usernames. This PR:

- Adds `MIN_USERNAME_LEN = 3` and rejects shorter names with `"username too short"`
- Updates `test_username_too_short` to expect that panic (it previously asserted short names were allowed)
- Rewrites and wires `src/tests/set_profile_tests.rs` so the orphaned length tests actually run

Fixes #941

## Test plan
- [ ] `cargo test` in `packages/contracts/contracts/linkora-contracts` (or project-standard contract test command)
- [ ] Confirm `"ab"` panics and `"abc"` succeeds via `set_profile`
EOF
)"
  else
    gh pr list --repo Epta-Node/Linkora-social --head "$USER_LOGIN:fix/username-min-length" --state open
  fi
)
fi

########################################
# 17) Nevo #860
########################################
echo ""
echo "======== PR 17: Web3Novalabs/Nevo#860 ========"
if skip_if_assigned_elsewhere "Web3Novalabs/Nevo" 860; then
claim_issue "Web3Novalabs/Nevo" 860 "I'll take this — removing the hardcoded id-based donor-count mock in \`PoolCard\` so missing \`donorCount\` renders as 0 instead of fake numbers."
fork_and_clone "Web3Novalabs/Nevo"
(
  cd "$WORKDIR/Nevo"
  DEFAULT="$(gh api repos/Web3Novalabs/Nevo --jq .default_branch)"
  git checkout -B "fix/poolcard-remove-mock-donors" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("nevo_frontend/components/PoolCard.tsx")
text = path.read_text(encoding="utf-8")
old = """  // Mock donor count if not provided
  const displayDonorCount =
    donorCount ??
    (id === '1'
      ? 42
      : id === '2'
        ? 87
        : id === '3'
          ? 31
          : Math.floor((raised * 7.3) / 100) + 1);"""
new = """  // Use real donor count when provided; otherwise show an honest zero state
  const displayDonorCount = donorCount ?? 0;"""
if "const displayDonorCount = donorCount ?? 0;" in text and "id === '1'" not in text:
    print("already patched")
elif old not in text:
    # try a looser match
    import re
    pat = re.compile(
        r"  // Mock donor count if not provided\n"
        r"  const displayDonorCount =\n"
        r"    donorCount \?\?\n"
        r"    \(id === '1'\n"
        r"      \? 42\n"
        r"      : id === '2'\n"
        r"        \? 87\n"
        r"        : id === '3'\n"
        r"          \? 31\n"
        r"          : Math\.floor\(\(raised \* 7\.3\) / 100\) \+ 1\);",
        re.M,
    )
    if not pat.search(text):
        raise SystemExit("Mock donorCount block not found — re-check PoolCard.tsx")
    text = pat.sub(new, text, count=1)
    path.write_text(text, encoding="utf-8")
    print("patched PoolCard.tsx (regex)")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched PoolCard.tsx")
PY
  git add nevo_frontend/components/PoolCard.tsx
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(frontend): remove mock donor-count fallback in PoolCard

Hardcoded id-based donor numbers contradicted the no-mock-data rule.
Missing donorCount now renders as 0.

Fixes #860
EOF
)"
  fi
  git push -u origin "fix/poolcard-remove-mock-donors" --force-with-lease
  if gh pr list --repo Web3Novalabs/Nevo --head "$USER_LOGIN:fix/poolcard-remove-mock-donors" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Web3Novalabs/Nevo \
      --head "$USER_LOGIN:fix/poolcard-remove-mock-donors" \
      --title "fix(frontend): remove mock donor-count fallback in PoolCard" \
      --body "$(cat <<'EOF'
## Summary
Removes the leftover id-based mock donor counts in `PoolCard`. When `donorCount` is omitted, the card shows `0 donors` instead of fabricated numbers.

Fixes #860

## Test plan
- [ ] `npm run build` in `nevo_frontend`
- [ ] Pool cards without `donorCount` show `0 donors`
- [ ] Pool cards with a real `donorCount` still display that value
EOF
)"
  else
    gh pr list --repo Web3Novalabs/Nevo --head "$USER_LOGIN:fix/poolcard-remove-mock-donors" --state open
  fi
)
fi

########################################
# 18) c-text-editor #3
########################################
echo ""
echo "======== PR 18: andrewthecodertx/c-text-editor#3 ========"
if skip_if_assigned_elsewhere "andrewthecodertx/c-text-editor" 3; then
claim_issue "andrewthecodertx/c-text-editor" 3 "I'll take this — replacing the fixed 128-byte prompt buffer in \`editor_prompt\` with a heap buffer that doubles on growth, freeing on cancel/error and returning the buffer on success (caller still frees)."
fork_and_clone "andrewthecodertx/c-text-editor"
(
  cd "$WORKDIR/c-text-editor"
  DEFAULT="$(gh api repos/andrewthecodertx/c-text-editor --jq .default_branch)"
  git checkout -B "fix/growable-prompt-buffer" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("ui.c")
text = path.read_text(encoding="utf-8")
if "#include <stdlib.h>" not in text:
    # insert after string.h
    if "#include <string.h>\n" in text:
        text = text.replace("#include <string.h>\n", "#include <string.h>\n#include <stdlib.h>\n", 1)
    else:
        text = text.replace('#include "ui.h"\n', '#include "ui.h"\n#include <stdlib.h>\n', 1)

old = """char *editor_prompt(const char *prompt_fmt, ...) {
  char buffer[128];
  int buflen = 0;
  buffer[0] = '\\0';

  while (1) {
    editor_set_status_message(prompt_fmt, buffer);
    editor_refresh_screen();

    int c = getch();
    if (c == '\\r' || c == '\\n') {
      if (buflen > 0) {
        return strdup(buffer);
      }
      editor_set_status_message("");
      return NULL;
    } else if (c == CTRL('c') || c == CTRL('q') || c == 27) {
      editor_set_status_message("");
      return NULL;
    } else if (c == KEY_BACKSPACE || c == 127 || c == KEY_DC) {
      if (buflen > 0) {
        buflen--;
        buffer[buflen] = '\\0';
      }
    } else if (c >= 32 && c <= 126) {
      if ((size_t)buflen < sizeof(buffer) - 1) {
        buffer[buflen++] = c;
        buffer[buflen] = '\\0';
      }
    }
  }
}"""

new = """char *editor_prompt(const char *prompt_fmt, ...) {
  size_t capacity = 256;
  char *buffer = malloc(capacity);
  int buflen = 0;

  if (buffer == NULL) {
    return NULL;
  }
  buffer[0] = '\\0';

  while (1) {
    editor_set_status_message(prompt_fmt, buffer);
    editor_refresh_screen();

    int c = getch();
    if (c == '\\r' || c == '\\n') {
      if (buflen > 0) {
        /* Caller frees; return the growable buffer directly. */
        return buffer;
      }
      free(buffer);
      editor_set_status_message("");
      return NULL;
    } else if (c == CTRL('c') || c == CTRL('q') || c == 27) {
      free(buffer);
      editor_set_status_message("");
      return NULL;
    } else if (c == KEY_BACKSPACE || c == 127 || c == KEY_DC) {
      if (buflen > 0) {
        buflen--;
        buffer[buflen] = '\\0';
      }
    } else if (c >= 32 && c <= 126) {
      if ((size_t)buflen + 1 >= capacity) {
        size_t new_capacity = capacity * 2;
        char *grown = realloc(buffer, new_capacity);
        if (grown == NULL) {
          free(buffer);
          editor_set_status_message("");
          return NULL;
        }
        buffer = grown;
        capacity = new_capacity;
      }
      buffer[buflen++] = (char)c;
      buffer[buflen] = '\\0';
    }
  }
}"""

if "size_t capacity = 256;" in text and "char buffer[128];" not in text:
    print("already patched")
elif old not in text:
    raise SystemExit("editor_prompt body not found — re-check ui.c")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched ui.c")
PY
  git add ui.c
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(ui): grow prompt buffer instead of truncating at 128 bytes

editor_prompt used a fixed stack array, so long Save-as paths and search
queries were silently truncated. Allocate on the heap, double capacity as
needed, free on cancel/OOM, and return the buffer on success.

Fixes #3
EOF
)"
  fi
  git push -u origin "fix/growable-prompt-buffer" --force-with-lease
  if gh pr list --repo andrewthecodertx/c-text-editor --head "$USER_LOGIN:fix/growable-prompt-buffer" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo andrewthecodertx/c-text-editor \
      --head "$USER_LOGIN:fix/growable-prompt-buffer" \
      --title "fix(ui): growable prompt buffer (remove 128-byte limit)" \
      --body "$(cat <<'EOF'
## Summary
Replaces the fixed 128-byte stack buffer in `editor_prompt` with a heap buffer that starts at 256 bytes and doubles on growth.

- Long Save-as paths and search queries no longer truncate
- Buffer is freed on ESC / Ctrl+C / empty Enter / OOM
- Success still returns a `char*` the caller must `free` (same contract as before)

Fixes #3

## Test plan
- [ ] Build the editor
- [ ] Save-as with a path longer than 128 characters
- [ ] Search with a query longer than 128 characters
- [ ] ESC / Ctrl+C / Backspace still behave correctly
EOF
)"
  else
    gh pr list --repo andrewthecodertx/c-text-editor --head "$USER_LOGIN:fix/growable-prompt-buffer" --state open
  fi
)
fi

########################################
# 19) nl6 #342
########################################
echo ""
echo "======== PR 19: labmonkeys-space/nl6#342 ========"
if skip_if_assigned_elsewhere "labmonkeys-space/nl6" 342; then
claim_issue "labmonkeys-space/nl6" 342 "I'll take this — packaging the Apache-2.0 LICENSE at \`/usr/share/doc/nl6/copyright\` via nfpm so debs satisfy Debian Policy §12.5 and SBOMs can declare the license (same as RPM already does)."
fork_and_clone "labmonkeys-space/nl6"
(
  cd "$WORKDIR/nl6"
  DEFAULT="$(gh api repos/labmonkeys-space/nl6 --jq .default_branch)"
  git checkout -B "fix/deb-copyright-file" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path

nfpm = Path("deploy/packages/nfpm.yaml")
text = nfpm.read_text(encoding="utf-8")
marker = "  - src: ./deploy/packages/config/nl6.conf\n    dst: /etc/nl6/nl6.conf\n    type: config|noreplace\n"
insert = marker + """
  # Debian Policy §12.5 requires /usr/share/doc/<pkg>/copyright. Syft also
  # derives the deb license from this path (the non-standard control
  # `License:` field is ignored for dpkg cataloging).
  - src: ./LICENSE
    dst: /usr/share/doc/nl6/copyright
"""
if "/usr/share/doc/nl6/copyright" in text:
    print("nfpm already has copyright entry")
elif marker not in text:
    raise SystemExit("nfpm contents marker not found")
else:
    nfpm.write_text(text.replace(marker, insert, 1), encoding="utf-8")
    print("patched nfpm.yaml")

smoke = Path("deploy/packages/smoke-test.sh")
s = smoke.read_text(encoding="utf-8")
needle = '[ -d /usr/share/nl6/web ]                  || fail "web/ data not installed"\n'
extra = needle + """# Debian Policy §12.5 — deb packages must ship a copyright file.
case "$pkg" in
  *.deb)
    [ -f /usr/share/doc/nl6/copyright ] || fail "Debian copyright file missing"
    ;;
esac
"""
if "/usr/share/doc/nl6/copyright" in s:
    print("smoke-test already asserts copyright")
elif needle not in s:
    raise SystemExit("smoke-test marker not found")
else:
    smoke.write_text(s.replace(needle, extra, 1), encoding="utf-8")
    print("patched smoke-test.sh")
PY
  git add deploy/packages/nfpm.yaml deploy/packages/smoke-test.sh
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(packages): ship /usr/share/doc/nl6/copyright in debs

Debian Policy §12.5 requires a copyright file; without it Syft reports
NOASSERTION for the deb while RPMs already declare Apache-2.0. Install
LICENSE at the standard path and assert it in the deb smoke test.

Fixes #342
EOF
)"
  fi
  git push -u origin "fix/deb-copyright-file" --force-with-lease
  if gh pr list --repo labmonkeys-space/nl6 --head "$USER_LOGIN:fix/deb-copyright-file" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo labmonkeys-space/nl6 \
      --head "$USER_LOGIN:fix/deb-copyright-file" \
      --title "fix(packages): ship Debian copyright file in .deb packages" \
      --body "$(cat <<'EOF'
## Summary
`.deb` packages did not include `/usr/share/doc/nl6/copyright`, which:
1. Violates Debian Policy §12.5 (`lintian: no-copyright-file`)
2. Causes Syft/SBOM to report `NOASSERTION` for deb license while RPMs correctly show Apache-2.0

This adds the repo `LICENSE` to the nfpm payload at the required path and asserts it in the deb smoke test.

Fixes #342

## Test plan
- [ ] `make packages` (or CI packaging workflow)
- [ ] `dpkg-deb -c dist/nl6_*_amd64.deb | grep copyright`
- [ ] Deb smoke path checks for `/usr/share/doc/nl6/copyright`
EOF
)"
  else
    gh pr list --repo labmonkeys-space/nl6 --head "$USER_LOGIN:fix/deb-copyright-file" --state open
  fi
)
fi

echo ""
echo "Batch 6 done (higher-impact code/packaging PRs)."
gh search prs --author "$USER_LOGIN" --state open --limit 30
