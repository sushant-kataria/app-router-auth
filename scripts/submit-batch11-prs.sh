#!/usr/bin/env bash
# Batch 11 — startups only (no avenx, no bigcos)
#   bash scripts/submit-batch11-prs.sh
#
# Targets:
#   40) umami-software/umami#4398 — header Edit label matches empty-dashboard copy
#   41) Synapse-bridgez/synapse-core#1002 — close paren in tx search summary
#   42) Open-Source-Kigali/osk-frontend#253 — Suspense uses Loader
#   43) Open-Source-Kigali/osk-frontend#254 — dynamic hamburger aria-label
#   44) midday-ai/midday#785 — README AGPL wording
#
# Verify first: bash scripts/verify-batch11.sh
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=grantpath-submit-lib.sh
source "$SCRIPT_DIR/grantpath-submit-lib.sh"

need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need git; need gh
grantpath_resolve_python
grantpath_init_workdir "batch11"

ACTIVE="$(gh api user --jq .login 2>/dev/null || true)"
if [[ -z "$ACTIVE" || "$ACTIVE" != "$USER_LOGIN" ]]; then
  echo "Need gh auth as $USER_LOGIN (got: '${ACTIVE:-none}'). Run: gh auth login"
  exit 1
fi

echo "==> Authenticated as $ACTIVE"
echo "==> Batch 11: startups (umami / synapse / osk / midday)"

########################################
# 40) umami #4398
########################################
echo ""
echo "======== PR 40: umami-software/umami#4398 ========"
if skip_if_assigned_elsewhere "umami-software/umami" 4398; then
claim_issue "umami-software/umami" 4398 "I'll take this — the empty dashboard copy says to click Edit, but the header button was hardcoded as Design. Switching the button to \`t(labels.edit)\`."
fork_and_clone "umami-software/umami"
(
  cd "$WORKDIR/umami"
  DEFAULT="$(gh api repos/umami-software/umami --jq .default_branch)"
  git checkout -B "fix/dashboard-edit-label" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("src/app/(main)/dashboard/DashboardViewHeader.tsx")
text = path.read_text(encoding="utf-8")
old = """      <LinkButton href={renderUrl('/dashboard/edit', false)}>
        <IconLabel icon={<LayoutDashboard />}>Design</IconLabel>
      </LinkButton>"""
new = """      <LinkButton href={renderUrl('/dashboard/edit', false)}>
        <IconLabel icon={<LayoutDashboard />}>{t(labels.edit)}</IconLabel>
      </LinkButton>"""
if "{t(labels.edit)}" in text and "Design</IconLabel>" not in text:
    print("already patched")
elif old not in text:
    raise SystemExit("DashboardViewHeader Design button block not found")
elif "const { t, labels }" not in text:
    raise SystemExit("expected useMessages() to provide labels")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched DashboardViewHeader.tsx")
PY
  git add "src/app/(main)/dashboard/DashboardViewHeader.tsx"
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(dashboard): use Edit label to match empty-state copy

Empty dashboard message tells users to click Edit, but the header
button was hardcoded as Design. Use t(labels.edit) so the control
matches the i18n empty-state string.

Fixes #4398
EOF
)"
  fi
  git push -u origin "fix/dashboard-edit-label" --force-with-lease
  if gh pr list --repo umami-software/umami --head "$USER_LOGIN:fix/dashboard-edit-label" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo umami-software/umami \
      --head "$USER_LOGIN:fix/dashboard-edit-label" \
      --title "fix(dashboard): use Edit label to match empty-state copy" \
      --body "$(cat <<'EOF'
## Summary
`message.empty-dashboard` tells users to click **Edit**, but `DashboardViewHeader` rendered a hardcoded **Design** label. The button now uses `t(labels.edit)`.

Fixes #4398

## Test plan
- [ ] Empty dashboard: header button label matches the empty-state “Edit” wording
- [ ] Locale still resolves `label.edit`
- [ ] `npm test` / typecheck for touched files
EOF
)"
  else
    gh pr list --repo umami-software/umami --head "$USER_LOGIN:fix/dashboard-edit-label" --state open
  fi
)
fi

########################################
# 41) synapse #1002
########################################
echo ""
echo "======== PR 41: Synapse-bridgez/synapse-core#1002 ========"
if skip_if_assigned_elsewhere "Synapse-bridgez/synapse-core" 1002; then
claim_issue "Synapse-bridgez/synapse-core" 1002 "I'll take this — closing the parenthesis in the \`tx search\` summary format string."
fork_and_clone "Synapse-bridgez/synapse-core"
(
  cd "$WORKDIR/synapse-core"
  DEFAULT="$(gh api repos/Synapse-bridgez/synapse-core --jq .default_branch)"
  git checkout -B "fix/tx-search-summary-paren" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("src/cli.rs")
text = path.read_text(encoding="utf-8")
# Source contains a Rust string escape \n (backslash + n), not a real newline.
old = '"\\n✓ {} results (total: {}",'
new = '"\\n✓ {} results (total: {})",'
if new in text and old not in text:
    print("already patched")
elif old not in text:
    raise SystemExit("tx search format string not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    final = path.read_text(encoding="utf-8")
    if old in final or new not in final:
        raise SystemExit("patch did not apply cleanly")
    print("patched cli.rs tx search summary")
PY
  git add src/cli.rs
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(cli): close parenthesis in tx search summary

The table-format summary printed `✓ N results (total: M` without a
closing `)`. Match other list summaries.

Fixes #1002
EOF
)"
  fi
  git push -u origin "fix/tx-search-summary-paren" --force-with-lease
  if gh pr list --repo Synapse-bridgez/synapse-core --head "$USER_LOGIN:fix/tx-search-summary-paren" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Synapse-bridgez/synapse-core \
      --head "$USER_LOGIN:fix/tx-search-summary-paren" \
      --title "fix(cli): close parenthesis in tx search summary" \
      --body "$(cat <<'EOF'
## Summary
`tx search` (table format) used `"\n✓ {} results (total: {}"` without the closing `)`, so output looked like `✓ 5 results (total: 12`.

Fixes #1002

## Test plan
- [ ] Format string is `"\n✓ {} results (total: {})"`
- [ ] Matches other summary lines in `src/cli.rs`
EOF
)"
  else
    gh pr list --repo Synapse-bridgez/synapse-core --head "$USER_LOGIN:fix/tx-search-summary-paren" --state open
  fi
)
fi

########################################
# 42) OSK #253
########################################
echo ""
echo "======== PR 42: Open-Source-Kigali/osk-frontend#253 ========"
if skip_if_assigned_elsewhere "Open-Source-Kigali/osk-frontend" 253; then
claim_issue "Open-Source-Kigali/osk-frontend" 253 "I'll take this — swapping the plain \`Loading...\` Suspense fallback for the shared \`<Loader />\` component."
fork_and_clone "Open-Source-Kigali/osk-frontend"
(
  cd "$WORKDIR/osk-frontend"
  DEFAULT="$(gh api repos/Open-Source-Kigali/osk-frontend --jq .default_branch)"
  git checkout -B "fix/suspense-loader-fallback" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("src/App.tsx")
text = path.read_text(encoding="utf-8")
if 'import Loader from "./components/UI/Loader"' not in text:
    needle = 'import { lazy, Suspense } from "react";\n'
    if needle not in text:
        raise SystemExit("react import not found")
    text = text.replace(needle, needle + 'import Loader from "./components/UI/Loader";\n', 1)
old = "<Suspense fallback={<div>Loading...</div>}>"
new = "<Suspense fallback={<Loader />}>"
if "fallback={<Loader" in text and "Loading..." not in text.split("Suspense")[1][:80]:
    print("already patched")
elif old not in text:
    raise SystemExit("Suspense Loading fallback not found")
else:
    text = text.replace(old, new, 1)
    print("patched App.tsx")
path.write_text(text, encoding="utf-8")
PY
  git add src/App.tsx
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix: use Loader component for Suspense fallback

Replace plain "Loading..." text with the shared Loader spinner for
lazy-loaded routes.

Fixes #253
EOF
)"
  fi
  git push -u origin "fix/suspense-loader-fallback" --force-with-lease
  if gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/suspense-loader-fallback" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Open-Source-Kigali/osk-frontend \
      --head "$USER_LOGIN:fix/suspense-loader-fallback" \
      --title "fix: use Loader component for Suspense fallback" \
      --body "$(cat <<'EOF'
## Summary
Lazy routes used `<div>Loading...</div>` as the Suspense fallback. This uses the shared `<Loader />` spinner.

Fixes #253

## Test plan
- [ ] `/partnersform` shows styled Loader
- [ ] `npm run lint` and `npm run build`
EOF
)"
  else
    gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/suspense-loader-fallback" --state open
  fi
)
fi

########################################
# 43) OSK #254
########################################
echo ""
echo "======== PR 43: Open-Source-Kigali/osk-frontend#254 ========"
if skip_if_assigned_elsewhere "Open-Source-Kigali/osk-frontend" 254; then
claim_issue "Open-Source-Kigali/osk-frontend" 254 "I'll take this — making the mobile hamburger \`aria-label\` reflect open vs closed menu state."
fork_and_clone "Open-Source-Kigali/osk-frontend"
(
  cd "$WORKDIR/osk-frontend"
  DEFAULT="$(gh api repos/Open-Source-Kigali/osk-frontend --jq .default_branch)"
  git checkout -B "fix/hamburger-aria-label" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("src/components/MainNavigation.tsx")
text = path.read_text(encoding="utf-8")
old = 'aria-label="Toggle menu"'
new = 'aria-label={mobileOpen ? "Close navigation menu" : "Open navigation menu"}'
if "Close navigation menu" in text:
    print("already patched")
elif old not in text:
    raise SystemExit("Toggle menu aria-label not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched MainNavigation.tsx")
PY
  git add src/components/MainNavigation.tsx
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(a11y): dynamic aria-label for mobile menu button

Announce Open vs Close navigation menu based on mobileOpen.

Fixes #254
EOF
)"
  fi
  git push -u origin "fix/hamburger-aria-label" --force-with-lease
  if gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/hamburger-aria-label" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Open-Source-Kigali/osk-frontend \
      --head "$USER_LOGIN:fix/hamburger-aria-label" \
      --title "fix(a11y): dynamic aria-label for mobile menu button" \
      --body "$(cat <<'EOF'
## Summary
Mobile menu button now uses:
- closed → `Open navigation menu`
- open → `Close navigation menu`

Fixes #254

## Test plan
- [ ] Toggle mobile menu — aria-label updates
- [ ] `npm run lint`
EOF
)"
  else
    gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/hamburger-aria-label" --state open
  fi
)
fi

########################################
# 44) Midday #785
########################################
echo ""
echo "======== PR 44: midday-ai/midday#785 ========"
if skip_if_assigned_elsewhere "midday-ai/midday" 785; then
claim_issue "midday-ai/midday" 785 "I'll take this — aligning the README License section with the AGPL-3.0 LICENSE file (AGPL cannot restrict commercial use)."
fork_and_clone "midday-ai/midday"
(
  cd "$WORKDIR/midday"
  DEFAULT="$(gh api repos/midday-ai/midday --jq .default_branch)"
  git checkout -B "docs/readme-agpl-license-wording" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("README.md")
text = path.read_text(encoding="utf-8")
old = """## License

This project is licensed under the **[AGPL-3.0](https://opensource.org/licenses/AGPL-3.0)** for non-commercial use. 

### Commercial Use

For commercial use or deployments requiring a setup fee, please contact us
for a commercial license at [engineer@midday.ai](mailto:engineer@midday.ai).

By using this software, you agree to the terms of the license."""
new = """## License

This project is licensed under the **[AGPL-3.0](https://opensource.org/licenses/AGPL-3.0)**. See the [`LICENSE`](./LICENSE) file for the full terms.

AGPL-3.0 is an OSI-approved open-source license and does **not** restrict commercial use by itself. If you need a separate commercial / dual license (for example proprietary SaaS use without AGPL obligations), contact [engineer@midday.ai](mailto:engineer@midday.ai).

By using this software, you agree to the terms of the license."""
if "does **not** restrict commercial use" in text:
    print("already patched")
elif old not in text:
    raise SystemExit("README license block not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched README.md")
PY
  git add README.md
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
docs: align README license wording with AGPL-3.0

Remove the incorrect "for non-commercial use" qualifier on AGPL and
keep commercial dual-license contact separately.

Fixes #785
EOF
)"
  fi
  git push -u origin "docs/readme-agpl-license-wording" --force-with-lease
  if gh pr list --repo midday-ai/midday --head "$USER_LOGIN:docs/readme-agpl-license-wording" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo midday-ai/midday \
      --head "$USER_LOGIN:docs/readme-agpl-license-wording" \
      --title "docs: align README license wording with AGPL-3.0" \
      --body "$(cat <<'EOF'
## Summary
README said AGPL was \"for non-commercial use\", which contradicts `LICENSE` and AGPL §10. Clarify AGPL terms and keep dual-license contact separate.

Fixes #785

## Test plan
- [ ] README no longer claims AGPL is non-commercial-only
- [ ] Commercial contact preserved
EOF
)"
  else
    gh pr list --repo midday-ai/midday --head "$USER_LOGIN:docs/readme-agpl-license-wording" --state open
  fi
)
fi

echo ""
echo "Batch 11 done."
gh search prs --author "$USER_LOGIN" --state open --limit 30
