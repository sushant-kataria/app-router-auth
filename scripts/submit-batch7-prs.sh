#!/usr/bin/env bash
# Batch 7 — higher-signal external PRs
#   bash scripts/submit-batch7-prs.sh
#
# Status: c-text abandoned (closed unmerged). Synapse / triageiq / osk remain.
# Windows: relative git clone in workdir + python3/python/py shim + textio bootstrap.
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=grantpath-submit-lib.sh
source "$SCRIPT_DIR/grantpath-submit-lib.sh"

need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need git; need gh
grantpath_resolve_python
grantpath_init_workdir "batch7"

ACTIVE="$(gh api user --jq .login 2>/dev/null || true)"
if [[ -z "$ACTIVE" || "$ACTIVE" != "$USER_LOGIN" ]]; then
  echo "Need gh auth as $USER_LOGIN (got: '${ACTIVE:-none}'). Run: gh auth login"
  exit 1
fi

echo "==> Authenticated as $ACTIVE"

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

echo ""
echo "Batch 7 done."
gh search prs --author "$USER_LOGIN" --state open --limit 30
