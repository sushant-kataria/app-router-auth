#!/usr/bin/env bash
# Batch 11 — recent startups / mid-size OSS (no bigcos)
#   bash scripts/submit-batch11-prs.sh
#
# Targets:
#   40) Avenx-JS/avenx-js#664 — document StateFactory options / onChange
#   41) Avenx-JS/avenx-js#663 — document setRoute mock route shape
#   42) Open-Source-Kigali/osk-frontend#253 — Suspense uses Loader
#   43) Open-Source-Kigali/osk-frontend#254 — dynamic hamburger aria-label
#   44) midday-ai/midday#785 — README license wording vs AGPL
#
# Avoid major companies (MS/Hashi/etc.) — they reject AI-looking PRs.
# Windows: grantpath-submit-lib.sh (relative clone + python shim + textio).
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
echo "==> Batch 11: startups (avenx / osk / midday)"

########################################
# 40) Avenx #664 — StateFactory onChange docs
########################################
echo ""
echo "======== PR 40: Avenx-JS/avenx-js#664 ========"
if skip_if_assigned_elsewhere "Avenx-JS/avenx-js" 664; then
claim_issue "Avenx-JS/avenx-js" 664 "I'll take this — documenting \`StateFactory.create\` options, especially \`onChange\`, in the utils API reference."
fork_and_clone "Avenx-JS/avenx-js"
(
  cd "$WORKDIR/avenx-js"
  DEFAULT="$(gh api repos/Avenx-JS/avenx-js --jq .default_branch)"
  git checkout -B "docs/statefactory-onchange" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("docs/src/content/docs/api-reference/utils.md")
text = path.read_text(encoding="utf-8")
old = """Options supplied to `create()` are forwarded to the underlying `ProxyHandlerFactory`.

```javascript
const state = stateFactory.create(
  {
    count: 0,
  },
  {
    onChange() {
      console.log('State changed');
    },
  },
);
```

## 7. `AvenxWatcher`"""
new = """Options supplied to `create()` are forwarded to the underlying `ProxyHandlerFactory`.

### `create()` options

| Option | Type | Description |
| ------ | ---- | ----------- |
| `onChange` | `() => void` | Called after a reactive property is set or deleted (and after related mutating operations). Receives **no arguments**. |
| `computedKeys` | `string[]` | Keys treated as computed properties (advanced; usually set by the component runtime). |
| `getComputedValue` | `(key, receiver) => any` | Evaluator for computed keys (advanced). |
| `instance` | `object` | Component instance used for fallback property lookups (advanced). |

#### `onChange`

Use `onChange` when you create standalone reactive state outside a component and need a hook whenever the proxy mutates:

```javascript
import { StateFactory } from 'avenx-core/runtime';

const stateFactory = new StateFactory();

const state = stateFactory.create(
  {
    count: 0,
    user: { name: 'Avenx User' },
  },
  {
    onChange() {
      // Fires after set/delete on the proxy (and nested reactive objects).
      console.log('State changed', state.count, state.user.name);
    },
  },
);

state.count++; // logs via onChange
delete state.user; // logs via onChange
```

> **Note:** `onChange` is a zero-argument callback. For dependency-aware reactions with old/new values, prefer `AvenxWatcher` (below) or `component.watch()`.

## 7. `AvenxWatcher`"""
if "### `create()` options" in text:
    print("already patched")
elif old not in text:
    raise SystemExit("StateFactory options insert block not found in utils.md")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched utils.md (StateFactory onChange)")
PY
  git add docs/src/content/docs/api-reference/utils.md
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
docs: document StateFactory create() options and onChange

Expand the utils API reference with the options schema forwarded to
ProxyHandlerFactory, focusing on the zero-arg onChange callback.

Fixes #664
EOF
)"
  fi
  git push -u origin "docs/statefactory-onchange" --force-with-lease
  if gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:docs/statefactory-onchange" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Avenx-JS/avenx-js \
      --head "$USER_LOGIN:docs/statefactory-onchange" \
      --title "docs: document StateFactory create() options and onChange" \
      --body "$(cat <<'EOF'
## Summary
Documents `StateFactory.create(initialState, options)` — especially `options.onChange` (`() => void`) — in `docs/src/content/docs/api-reference/utils.md`, with a standalone example.

Fixes #664

## Test plan
- [ ] Docs section renders with the options table + example
- [ ] Matches `ProxyHandlerFactory` JSDoc (`onChange` zero-arg)
EOF
)"
  else
    gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:docs/statefactory-onchange" --state open
  fi
)
fi

########################################
# 41) Avenx #663 — setRoute docs
########################################
echo ""
echo "======== PR 41: Avenx-JS/avenx-js#663 ========"
if skip_if_assigned_elsewhere "Avenx-JS/avenx-js" 663; then
claim_issue "Avenx-JS/avenx-js" 663 "I'll take this — documenting the mocked \`route\` object shape for \`AvenxSandbox.setRoute\` in the testing guide."
fork_and_clone "Avenx-JS/avenx-js"
(
  cd "$WORKDIR/avenx-js"
  DEFAULT="$(gh api repos/Avenx-JS/avenx-js --jq .default_branch)"
  git checkout -B "docs/setroute-mock-shape" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("docs/src/content/docs/api-reference/testing.md")
text = path.read_text(encoding="utf-8")
old = """### `setRoute(route)`

Mocks the current router state, useful for testing route-dependent components without a real router.

**Parameters**

- `route` (object): The route object to set as the current route.

**Returns**

- `AvenxSandbox`: The sandbox instance (chainable).

### `waitForUpdate()`"""
new = """### `setRoute(route)`

Mocks the current router state, useful for testing route-dependent components without a real router.

**Parameters**

- `route` (object): The route object to set as the current route. Expected fields:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `hash` | `string` | Mocked URL path/hash (e.g. `'#/users'`). |
| `page` | `string` | Active page/component name registered with the router. |
| `params` | `object` | Route parameters available to the page (path params and any app-specific fields such as nested query data). |

**Returns**

- `AvenxSandbox`: The sandbox instance (chainable).

**Example**

```javascript
sandbox.setRoute({
  hash: '#/users',
  page: 'users',
  params: { id: '99' },
});

const { html } = sandbox.mount(UsersPage);
```

### `waitForUpdate()`"""
if "| `hash` | `string` |" in text and "setRoute" in text:
    # might already be partially there
    if "Mocked URL path/hash" in text:
        print("already patched")
    elif old not in text:
        raise SystemExit("setRoute block not found in testing.md")
    else:
        path.write_text(text.replace(old, new, 1), encoding="utf-8")
        print("patched testing.md")
elif old not in text:
    raise SystemExit("setRoute block not found in testing.md")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched testing.md (setRoute shape)")
PY
  git add docs/src/content/docs/api-reference/testing.md
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
docs: document AvenxSandbox.setRoute mock route shape

Document hash/page/params fields and add a mount example so isolated
route-dependent tests have a clear contract.

Fixes #663
EOF
)"
  fi
  git push -u origin "docs/setroute-mock-shape" --force-with-lease
  if gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:docs/setroute-mock-shape" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Avenx-JS/avenx-js \
      --head "$USER_LOGIN:docs/setroute-mock-shape" \
      --title "docs: document AvenxSandbox.setRoute mock route shape" \
      --body "$(cat <<'EOF'
## Summary
Documents the mocked `route` object for `setRoute` (`hash`, `page`, `params`) in the testing API guide, with an example matching unit tests.

Fixes #663

## Test plan
- [ ] Docs render correctly
- [ ] Example aligns with `test/unit/mock.test.js` usage
EOF
)"
  else
    gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:docs/setroute-mock-shape" --state open
  fi
)
fi

########################################
# 42) OSK #253 — Suspense Loader
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
if "from \"./components/UI/Loader\"" in text or "from './components/UI/Loader'" in text:
    print("Loader import already present")
else:
    needle = 'import { lazy, Suspense } from "react";\n'
    if needle not in text:
        raise SystemExit("react import block not found")
    text = text.replace(
        needle,
        needle + 'import Loader from "./components/UI/Loader";\n',
        1,
    )
old = "<Suspense fallback={<div>Loading...</div>}>"
new = "<Suspense fallback={<Loader />}>"
if "fallback={<Loader" in text and "Loading..." not in text:
    print("already patched fallback")
elif old not in text:
    raise SystemExit("Suspense Loading... fallback not found")
else:
    text = text.replace(old, new, 1)
    print("patched App.tsx Suspense fallback")
path.write_text(text, encoding="utf-8")
PY
  git add src/App.tsx
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix: use Loader component for Suspense fallback

Replace the plain "Loading..." text fallback with the shared Loader
spinner for lazy-loaded routes.

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
Lazy routes used a plain `<div>Loading...</div>` Suspense fallback. This switches to the shared `<Loader />` spinner.

Fixes #253

## Test plan
- [ ] Open `/partnersform` (lazy) — styled loader appears instead of raw text
- [ ] `npm run lint` / `npm run build`
EOF
)"
  else
    gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/suspense-loader-fallback" --state open
  fi
)
fi

########################################
# 43) OSK #254 — hamburger aria-label
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
    print("patched MainNavigation.tsx aria-label")
PY
  git add src/components/MainNavigation.tsx
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(a11y): dynamic aria-label for mobile menu button

Announce Open vs Close navigation menu based on mobileOpen so screen
readers match the hamburger/X icon state.

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
The mobile menu button always announced "Toggle menu". It now uses:
- closed → `Open navigation menu`
- open → `Close navigation menu`

Fixes #254

## Test plan
- [ ] Toggle mobile menu — `aria-label` updates with state
- [ ] Visual behavior unchanged
EOF
)"
  else
    gh pr list --repo Open-Source-Kigali/osk-frontend --head "$USER_LOGIN:fix/hamburger-aria-label" --state open
  fi
)
fi

########################################
# 44) Midday #785 — README license
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
if "does **not** restrict commercial use" in text or "does not restrict commercial use" in text:
    print("already patched")
elif old not in text:
    # try looser match
    if "for non-commercial use" not in text:
        raise SystemExit("README license non-commercial wording not found — may already be fixed")
    raise SystemExit("README license block not found exactly — check formatting")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched README.md license section")
PY
  git add README.md
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
docs: align README license wording with AGPL-3.0

The README said AGPL was "for non-commercial use", which contradicts
the LICENSE file and AGPL terms. Clarify AGPL applies as written and
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
The README License section said the project is AGPL-3.0 \"for non-commercial use\". That contradicts the `LICENSE` file (unmodified AGPL-3.0) and AGPL §10 (no further restrictions).

This update:
- States the project is AGPL-3.0 per `LICENSE`
- Clarifies AGPL does not itself ban commercial use
- Keeps the commercial/dual-license contact as a separate option

Fixes #785

## Test plan
- [ ] README License section no longer claims AGPL is non-commercial-only
- [ ] Commercial contact email preserved
EOF
)"
  else
    gh pr list --repo midday-ai/midday --head "$USER_LOGIN:docs/readme-agpl-license-wording" --state open
  fi
)
fi

echo ""
echo "Batch 11 done (startups)."
gh search prs --author "$USER_LOGIN" --state open --limit 30
