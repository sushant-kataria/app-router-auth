#!/usr/bin/env bash
# Batch 7 — higher-signal external PRs
#   bash scripts/submit-batch7-prs.sh
#
# Windows/Git Bash: git clone + home-cache workdir + CRLF/NUL text matching.
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_uname="$(uname -s 2>/dev/null || echo unknown)"
if [[ -n "${LOCALAPPDATA:-}" || "$_uname" == MINGW* || "$_uname" == MSYS* || "$_uname" == CYGWIN* ]]; then
  WORKDIR="${GRANTPATH_WORKDIR:-$HOME/.cache/grantpath-batch7-$$}"
else
  WORKDIR="${GRANTPATH_WORKDIR:-${TMPDIR:-/tmp}/grantpath-batch7-$$}"
fi
mkdir -p "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT

need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need git; need gh; need python3

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
  git clone --depth=50 "https://github.com/$USER_LOGIN/$name.git" "$WORKDIR/$name"
  (
    cd "$WORKDIR/$name"
    git remote add upstream "https://github.com/$upstream.git" 2>/dev/null || true
    git fetch upstream
  )
}

echo "==> Authenticated as $ACTIVE"
echo "==> Workdir: $WORKDIR"

########################################
# 20) Synapse #1012
########################################
echo ""
echo "======== PR 20: Synapse-bridgez/synapse-core#1012 ========"
if skip_if_assigned_elsewhere "Synapse-bridgez/synapse-core" 1012; then
claim_issue "Synapse-bridgez/synapse-core" 1012 "I'll take this — reading \`DATABASE_URL\` via \`std::env::var\` in \`seed_data()\` and passing the resolved value to \`psql\` (Command does not shell-expand \`\${…}\`)."
fork_and_clone "Synapse-bridgez/synapse-core"
(
  cd "$WORKDIR/synapse-core"
  DEFAULT="$(gh api repos/Synapse-bridgez/synapse-core --jq .default_branch)"
  git checkout -B "fix/xtask-seed-database-url" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("xtask/src/commands/setup.rs")
text = path.read_text(encoding="utf-8")
old = """fn seed_data() -> anyhow::Result<()> {
    println!("\\n-- Seeding initial data --");
    // Feature flags seed — non-fatal if psql is unavailable or row already exists.
    let result = run_cmd(
        "psql",
        &[
            "${DATABASE_URL}",
            "-c",
            "INSERT INTO feature_flags (name, enabled) VALUES ('dev_seed', true) ON CONFLICT DO NOTHING;",
        ],
    );
    if let Err(e) = result {
        println!("  Warning: seed step skipped or failed (non-fatal): {e}");
    }
    println!("  Seed complete.");
    Ok(())
}"""
new = """fn seed_data() -> anyhow::Result<()> {
    println!("\\n-- Seeding initial data --");
    // Feature flags seed — non-fatal if psql is unavailable or row already exists.
    // `run_cmd` uses `Command` (no shell), so `${DATABASE_URL}` would be passed
    // literally; resolve the env var in Rust first.
    let database_url = match std::env::var("DATABASE_URL") {
        Ok(url) if !url.is_empty() => url,
        _ => {
            println!("  Warning: DATABASE_URL not set — seed step skipped.");
            return Ok(());
        }
    };
    let result = run_cmd(
        "psql",
        &[
            database_url.as_str(),
            "-c",
            "INSERT INTO feature_flags (name, enabled) VALUES ('dev_seed', true) ON CONFLICT DO NOTHING;",
        ],
    );
    if let Err(e) = result {
        println!("  Warning: seed step skipped or failed (non-fatal): {e}");
    }
    println!("  Seed complete.");
    Ok(())
}"""
if 'database_url.as_str()' in text and '"${DATABASE_URL}"' not in text:
    print("already patched")
elif old not in text:
    raise SystemExit("seed_data block not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched setup.rs")
PY
  git add xtask/src/commands/setup.rs
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(xtask): resolve DATABASE_URL before psql seed

Command::new does not expand shell ${VAR} syntax, so seed_data always
passed the literal string `${DATABASE_URL}` and silently failed. Read
the env var in Rust and pass the real connection string.

Fixes #1012
EOF
)"
  fi
  git push -u origin "fix/xtask-seed-database-url" --force-with-lease
  if gh pr list --repo Synapse-bridgez/synapse-core --head "$USER_LOGIN:fix/xtask-seed-database-url" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Synapse-bridgez/synapse-core \
      --head "$USER_LOGIN:fix/xtask-seed-database-url" \
      --title "fix(xtask): resolve DATABASE_URL before psql seed" \
      --body "$(cat <<'EOF'
## Summary
`seed_data()` passed `"${DATABASE_URL}"` to `psql` via `Command`, which does not shell-expand env vars — so seeding always failed and was swallowed as a warning.

This reads `DATABASE_URL` with `std::env::var` and passes the resolved value (or skips with a clear warning when unset).

Fixes #1012

## Test plan
- [ ] `DATABASE_URL=… cargo xtask setup` (or equivalent) inserts `dev_seed` when Postgres is up
- [ ] Unset `DATABASE_URL` prints the skip warning instead of a psql connection error to a literal `${DATABASE_URL}`
EOF
)"
  else
    gh pr list --repo Synapse-bridgez/synapse-core --head "$USER_LOGIN:fix/xtask-seed-database-url" --state open
  fi
)
fi

########################################
# 21) c-text-editor #8 + #17
########################################
echo ""
echo "======== PR 21: andrewthecodertx/c-text-editor#8+#17 ========"
if skip_if_assigned_elsewhere "andrewthecodertx/c-text-editor" 8; then
claim_issue "andrewthecodertx/c-text-editor" 8 "I'll take the undo leak (#8) and wire \`editor_action_free\` into the empty \`editor_actions\` module (#17): free discarded/overflowed actions, bump \`MAX_UNDO_STATES\` to 1000."
claim_issue "andrewthecodertx/c-text-editor" 17 "Taking this together with #8 — implementing \`editor_action_free\` in \`editor_actions.c\` and using it from the undo recorder."
fork_and_clone "andrewthecodertx/c-text-editor"
(
  cd "$WORKDIR/c-text-editor"
  DEFAULT="$(gh api repos/andrewthecodertx/c-text-editor --jq .default_branch)"
  git checkout -B "fix/undo-leak-and-actions" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path

# editor.h — capacity
eh = Path("editor.h")
t = eh.read_text(encoding="utf-8")
if "MAX_UNDO_STATES 1000" not in t:
    if "#define MAX_UNDO_STATES 20" not in t:
        raise SystemExit("MAX_UNDO_STATES not found")
    eh.write_text(t.replace("#define MAX_UNDO_STATES 20", "#define MAX_UNDO_STATES 1000", 1), encoding="utf-8")
    print("bumped MAX_UNDO_STATES")

# editor_actions.h — declare free
eah = Path("editor_actions.h")
h = eah.read_text(encoding="utf-8")
if "editor_action_free" not in h:
    h = h.replace(
        "} EditorAction;\n\n#endif // EDITOR_ACTIONS_H",
        "} EditorAction;\n\nvoid editor_action_free(EditorAction *action);\n\n#endif // EDITOR_ACTIONS_H",
        1,
    )
    eah.write_text(h, encoding="utf-8")
    print("patched editor_actions.h")

# editor_actions.c — implement free
Path("editor_actions.c").write_text(
    '''#include "editor_actions.h"

#include <stdlib.h>

void editor_action_free(EditorAction *action) {
  if (action == NULL) {
    return;
  }
  if (action->type == ACTION_DELETE_LINE && action->line_content != NULL) {
    free(action->line_content);
    action->line_content = NULL;
    action->line_len = 0;
  }
}
''',
    encoding="utf-8",
)
print("wrote editor_actions.c")

# editor.c — free on discard / overflow + teardown helper
ec = Path("editor.c")
c = ec.read_text(encoding="utf-8")
old_teardown = """  for (int i = 0; i < E.undo_history_len; ++i) {
    if (E.undo_history[i].type == ACTION_DELETE_LINE &&
        E.undo_history[i].line_content) {
      free(E.undo_history[i].line_content);
    }
  }
}"""
new_teardown = """  for (int i = 0; i < E.undo_history_len; ++i) {
    editor_action_free(&E.undo_history[i]);
  }
}"""
if old_teardown in c:
    c = c.replace(old_teardown, new_teardown, 1)
    print("patched teardown")

old_rec = """  if (E.undo_history_idx < E.undo_history_len) {
    for (int i = E.undo_history_idx; i < E.undo_history_len; ++i) {
      // In a real implementation, you'd free any memory associated with these
      // discarded actions For now, we're just overwriting them.
    }
    E.undo_history_len = E.undo_history_idx;
  }

  if (E.undo_history_len == MAX_UNDO_STATES) {
    // In a real implementation, you'd free any memory associated with the
    // oldest action For now, we're just overwriting it.
    memmove(&E.undo_history[0], &E.undo_history[1],
            (MAX_UNDO_STATES - 1) * sizeof(EditorAction));
    E.undo_history_len--;
    E.undo_history_idx--;
  }"""
new_rec = """  if (E.undo_history_idx < E.undo_history_len) {
    for (int i = E.undo_history_idx; i < E.undo_history_len; ++i) {
      editor_action_free(&E.undo_history[i]);
    }
    E.undo_history_len = E.undo_history_idx;
  }

  if (E.undo_history_len == MAX_UNDO_STATES) {
    editor_action_free(&E.undo_history[0]);
    memmove(&E.undo_history[0], &E.undo_history[1],
            (MAX_UNDO_STATES - 1) * sizeof(EditorAction));
    E.undo_history_len--;
    E.undo_history_idx--;
  }"""
if old_rec not in c:
    raise SystemExit("editor_record_action discard block not found")
c = c.replace(old_rec, new_rec, 1)
ec.write_text(c, encoding="utf-8")
print("patched editor_record_action")
PY
  git add editor.h editor.c editor_actions.c editor_actions.h
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(undo): free discarded actions and raise undo capacity

Implement editor_action_free in the previously empty editor_actions
module, free ACTION_DELETE_LINE buffers when truncating/shifting the
undo stack, and raise MAX_UNDO_STATES from 20 to 1000.

Fixes #8
Fixes #17
EOF
)"
  fi
  git push -u origin "fix/undo-leak-and-actions" --force-with-lease
  if gh pr list --repo andrewthecodertx/c-text-editor --head "$USER_LOGIN:fix/undo-leak-and-actions" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo andrewthecodertx/c-text-editor \
      --head "$USER_LOGIN:fix/undo-leak-and-actions" \
      --title "fix(undo): free discarded actions and raise undo capacity" \
      --body "$(cat <<'EOF'
## Summary
- Implements `editor_action_free` in the empty `editor_actions` module
- Frees discarded / overflowed `ACTION_DELETE_LINE` buffers in `editor_record_action`
- Raises `MAX_UNDO_STATES` from 20 → 1000

Fixes #8
Fixes #17

## Test plan
- [ ] Build with ASan if available; cycle undo after delete-line actions
- [ ] Confirm undo/redo still works after truncating redo history
EOF
)"
  else
    gh pr list --repo andrewthecodertx/c-text-editor --head "$USER_LOGIN:fix/undo-leak-and-actions" --state open
  fi
)
fi

########################################
# 22) triageiq #22
########################################
echo ""
echo "======== PR 22: SakethSumanBathini/triageiq#22 ========"
if skip_if_assigned_elsewhere "SakethSumanBathini/triageiq" 22; then
claim_issue "SakethSumanBathini/triageiq" 22 ".take — wiring \`CORSMiddleware\` to the parsed \`CORS_ORIGINS\` list (comma-separated), failing closed to localhost when unset/empty."
fork_and_clone "SakethSumanBathini/triageiq"
(
  cd "$WORKDIR/triageiq"
  DEFAULT="$(gh api repos/SakethSumanBathini/triageiq --jq .default_branch)"
  git checkout -B "fix/cors-origins-allowlist" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("backend/app/main.py")
text = path.read_text(encoding="utf-8")
old = """origins = os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)"""
new = """# Comma-separated allowlist. Fail closed to localhost when unset/empty.
_raw_origins = os.getenv("CORS_ORIGINS", "http://localhost:5173")
origins = [o.strip() for o in _raw_origins.split(",") if o.strip()]
if not origins:
    origins = ["http://localhost:5173"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)"""
if 'allow_origins=origins' in text and 'allow_origins=["*"]' not in text:
    print("already patched")
elif old not in text:
    raise SystemExit("CORS block not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched main.py")

env = Path("backend/.env.example")
e = env.read_text(encoding="utf-8")
if "Fail closed" not in e and "CORS_ORIGINS=" in e:
    e = e.replace(
        "CORS_ORIGINS=http://localhost:5173,http://localhost:3000",
        "# Comma-separated. When unset/empty, API allows only http://localhost:5173.\nCORS_ORIGINS=http://localhost:5173,http://localhost:3000",
        1,
    )
    env.write_text(e, encoding="utf-8")
    print("patched .env.example")
PY
  git add backend/app/main.py backend/.env.example
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(api): honor CORS_ORIGINS allowlist instead of wildcard

CORSMiddleware was still allow_origins=["*"] while CORS_ORIGINS was
parsed and ignored. Use the env allowlist (comma-separated) and fail
closed to localhost when unset/empty.

Fixes #22
EOF
)"
  fi
  git push -u origin "fix/cors-origins-allowlist" --force-with-lease
  if gh pr list --repo SakethSumanBathini/triageiq --head "$USER_LOGIN:fix/cors-origins-allowlist" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo SakethSumanBathini/triageiq \
      --head "$USER_LOGIN:fix/cors-origins-allowlist" \
      --title "fix(api): honor CORS_ORIGINS allowlist instead of wildcard" \
      --body "$(cat <<'EOF'
## Summary
`CORS_ORIGINS` was parsed but unused — middleware still allowed `*`. This wires the comma-separated allowlist through and fails closed to `http://localhost:5173` when unset/empty.

Fixes #22

## Test plan
- [ ] Default local: frontend on `:5173` still works
- [ ] Set `CORS_ORIGINS` to a staging URL and confirm other origins are rejected
EOF
)"
  else
    gh pr list --repo SakethSumanBathini/triageiq --head "$USER_LOGIN:fix/cors-origins-allowlist" --state open
  fi
)
fi

########################################
# 23) osk-frontend #279
########################################
echo ""
echo "======== PR 23: Open-Source-Kigali/osk-frontend#279 ========"
if skip_if_assigned_elsewhere "Open-Source-Kigali/osk-frontend" 279; then
claim_issue "Open-Source-Kigali/osk-frontend" 279 "I'll take this — point Events at \`/event\` and remove the non-existent Blog footer link."
fork_and_clone "Open-Source-Kigali/osk-frontend"
(
  cd "$WORKDIR/osk-frontend"
  DEFAULT="$(gh api repos/Open-Source-Kigali/osk-frontend --jq .default_branch)"
  git checkout -B "fix/footer-resource-routes" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("src/components/Footer.tsx")
text = path.read_text(encoding="utf-8")
old = """    links: [
      { label: "Blog", to: "/blog" },
      { label: "Events", to: "/events" },
    ],"""
new = """    links: [
      // Blog route does not exist yet — omit until the page ships.
      { label: "Events", to: "/event" },
    ],"""
if '{ label: "Events", to: "/event" }' in text and "/blog" not in text.split("Resources")[1].split("Connect")[0]:
    print("already patched")
elif old not in text:
    raise SystemExit("Footer Resources links not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched Footer.tsx")
PY
  git add src/components/Footer.tsx
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix: correct Footer resource routes

Point Events at /event (actual route) and remove the Blog link until
that page exists.

Fixes #279
EOF
)"
  fi
  git push -u origin "fix/footer-resource-routes" --force-with-lease
  if gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/footer-resource-routes" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Open-Source-Kigali/osk-frontend \
      --head "$USER_LOGIN:fix/footer-resource-routes" \
      --title "fix: correct Footer resource routes" \
      --body "$(cat <<'EOF'
## Summary
- Events link: `/events` → `/event`
- Remove Blog link (route does not exist yet)

Fixes #279

## Test plan
- [ ] Footer Events navigates to the Events page
- [ ] No 404 from Blog in the footer
EOF
)"
  else
    gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/footer-resource-routes" --state open
  fi
)
fi

########################################
# 24) nl6 #343
########################################
echo ""
echo "======== PR 24: labmonkeys-space/nl6#343 ========"
if skip_if_assigned_elsewhere "labmonkeys-space/nl6" 343; then
claim_issue "labmonkeys-space/nl6" 343 "I'll take this — documenting the reliable digest/API attestation check and noting that \`gh attestation verify\` may exit 0 with empty output on some gh versions."
fork_and_clone "labmonkeys-space/nl6"
(
  cd "$WORKDIR/nl6"
  DEFAULT="$(gh api repos/labmonkeys-space/nl6 --jq .default_branch)"
  git checkout -B "docs/attestation-verify-guidance" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("RELEASING.md")
text = path.read_text(encoding="utf-8")
old = """# 3. SLSA build provenance (binaries + image), via the GitHub attestation API.
gh attestation verify nl6-linux-amd64 --repo labmonkeys-space/nl6
gh attestation verify oci://ghcr.io/labmonkeys-space/nl6:vX.Y.Z --repo labmonkeys-space/nl6
```"""
new = """# 3. SLSA build provenance via the attestations API.
# Note: `gh attestation verify <file>` can exit 0 with *empty* output on some
# gh versions (observed on 2.96.x), which is indistinguishable from a no-op.
# Prefer the digest + API check below — it prints the provenance payload.
d=$(shasum -a 256 nl6-linux-amd64 | cut -d' ' -f1)
gh api "/repos/labmonkeys-space/nl6/attestations/sha256:$d" \\
  --jq '.attestations[0].bundle.dsseEnvelope.payload' | base64 -d | jq .
# Expect predicateType https://slsa.dev/provenance/v1 and a matching subject.
# Optional (may be silent on some gh versions — do not treat empty output as OK):
#   gh attestation verify nl6-linux-amd64 --repo labmonkeys-space/nl6 --format json
#   gh attestation verify oci://ghcr.io/labmonkeys-space/nl6:vX.Y.Z --repo labmonkeys-space/nl6 --format json
```"""
if "attestations/sha256:" in text:
    print("already patched")
elif old not in text:
    raise SystemExit("RELEASING attestation block not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched RELEASING.md")
PY
  git add RELEASING.md
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
docs(releasing): reliable SLSA attestation verification steps

gh attestation verify can exit 0 with empty output on some gh versions.
Document the digest + API check that actually prints provenance, and
demote the silent CLI form to an optional note.

Fixes #343
EOF
)"
  fi
  git push -u origin "docs/attestation-verify-guidance" --force-with-lease
  if gh pr list --repo labmonkeys-space/nl6 --head "$USER_LOGIN:docs/attestation-verify-guidance" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo labmonkeys-space/nl6 \
      --head "$USER_LOGIN:docs/attestation-verify-guidance" \
      --title "docs(releasing): reliable SLSA attestation verification steps" \
      --body "$(cat <<'EOF'
## Summary
`gh attestation verify` can exit 0 with empty stdout/stderr on some gh versions, so the previous RELEASING steps gave no confirmation. Document the digest + `gh api …/attestations/sha256:…` check that prints provenance, and note the silent CLI behavior.

Fixes #343

## Test plan
- [x] Docs-only change
- [ ] Follow the new steps against a release asset (e.g. latest `nl6-linux-amd64`)
EOF
)"
  else
    gh pr list --repo labmonkeys-space/nl6 --head "$USER_LOGIN:docs/attestation-verify-guidance" --state open
  fi
)
fi

echo ""
echo "Batch 7 done."
gh search prs --author "$USER_LOGIN" --state open --limit 30
