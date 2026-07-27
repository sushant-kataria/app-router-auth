#!/usr/bin/env bash
# Batch 8 — higher-signal external PRs
#   bash scripts/submit-batch8-prs.sh
#
# Targets:
#   25) Synapse-bridgez/synapse-core#1011 — cliff.toml commit URL hrefs
#   26) Web3Novalabs/Nevo#971 — root .editorconfig
#   27) SakethSumanBathini/triageiq#14 — Clear button on email form
#   28) SakethSumanBathini/triageiq#15 — dashboard empty state
#   29) Avenx-JS/avenx-js#639 — warn when guards return undefined
#
# Windows: relative git clone in workdir + python3/python/py shim + textio bootstrap.
# Prefer `git commit -s` if a maintainer requires DCO (e.g. nl6).
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=grantpath-submit-lib.sh
source "$SCRIPT_DIR/grantpath-submit-lib.sh"

need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need git; need gh
grantpath_resolve_python
grantpath_init_workdir "batch8"

ACTIVE="$(gh api user --jq .login 2>/dev/null || true)"
if [[ -z "$ACTIVE" || "$ACTIVE" != "$USER_LOGIN" ]]; then
  echo "Need gh auth as $USER_LOGIN (got: '${ACTIVE:-none}'). Run: gh auth login"
  exit 1
fi

echo "==> Authenticated as $ACTIVE"

########################################
# 25) Synapse #1011
########################################
echo ""
echo "======== PR 25: Synapse-bridgez/synapse-core#1011 ========"
if skip_if_assigned_elsewhere "Synapse-bridgez/synapse-core" 1011; then
claim_issue "Synapse-bridgez/synapse-core" 1011 "I'll take this — prefixing the git-cliff commit-hash href with \`https://github.com/Synapse-bridgez/synapse-core/commit/\`."
fork_and_clone "Synapse-bridgez/synapse-core"
(
  cd "$WORKDIR/synapse-core"
  DEFAULT="$(gh api repos/Synapse-bridgez/synapse-core --jq .default_branch)"
  git checkout -B "fix/cliff-commit-link-url" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("cliff.toml")
text = path.read_text(encoding="utf-8")
old = '([`{{ commit.id | truncate(length=7, end="") }}`]({{ commit.id }}))'
new = '([`{{ commit.id | truncate(length=7, end="") }}`](https://github.com/Synapse-bridgez/synapse-core/commit/{{ commit.id }}))'
if "synapse-core/commit/{{ commit.id }}" in text:
    print("already patched")
elif old not in text:
    raise SystemExit("cliff.toml commit link template not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched cliff.toml")
PY
  git add cliff.toml
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(cliff): use GitHub URLs for commit-hash links

The changelog body template used the raw commit SHA as the markdown
href, producing broken relative links. Prefix with the GitHub commit URL.

Fixes #1011
EOF
)"
  fi
  git push -u origin "fix/cliff-commit-link-url" --force-with-lease
  if gh pr list --repo Synapse-bridgez/synapse-core --head "$USER_LOGIN:fix/cliff-commit-link-url" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Synapse-bridgez/synapse-core \
      --head "$USER_LOGIN:fix/cliff-commit-link-url" \
      --title "fix(cliff): use GitHub URLs for commit-hash links" \
      --body "$(cat <<'EOF'
## Summary
`cliff.toml`'s changelog body used `]({{ commit.id }})` as the href, so every commit-hash link in generated changelogs was a bare SHA instead of a GitHub URL.

This prefixes the href with `https://github.com/Synapse-bridgez/synapse-core/commit/`, matching the existing issue/link parsers in the same file.

Fixes #1011

## Test plan
- [ ] `git cliff` (or project changelog regen) produces clickable `…/commit/<sha>` links
- [ ] Short SHA display text is unchanged
EOF
)"
  else
    gh pr list --repo Synapse-bridgez/synapse-core --head "$USER_LOGIN:fix/cliff-commit-link-url" --state open
  fi
)
fi

########################################
# 26) Nevo #971
########################################
echo ""
echo "======== PR 26: Web3Novalabs/Nevo#971 ========"
if skip_if_assigned_elsewhere "Web3Novalabs/Nevo" 971; then
claim_issue "Web3Novalabs/Nevo" 971 "I'll take this — adding a root \`.editorconfig\` aligned with Prettier (2-space TS/JS) and 4-space Rust."
fork_and_clone "Web3Novalabs/Nevo"
(
  cd "$WORKDIR/Nevo"
  DEFAULT="$(gh api repos/Web3Novalabs/Nevo --jq .default_branch)"
  git checkout -B "chore/root-editorconfig" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path(".editorconfig")
if path.exists():
    print("already exists")
else:
    path.write_text(
        "root = true\n"
        "\n"
        "[*]\n"
        "charset = utf-8\n"
        "end_of_line = lf\n"
        "insert_final_newline = true\n"
        "trim_trailing_whitespace = true\n"
        "\n"
        "[*.{js,jsx,ts,tsx,mjs,cjs,json,yml,yaml,css,scss,html}]\n"
        "indent_style = space\n"
        "indent_size = 2\n"
        "\n"
        "[*.{rs,toml}]\n"
        "indent_style = space\n"
        "indent_size = 4\n"
        "\n"
        "[*.md]\n"
        "trim_trailing_whitespace = false\n",
        encoding="utf-8",
    )
    print("wrote .editorconfig")
PY
  git add .editorconfig
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
chore: add root .editorconfig for consistent formatting

Align editor defaults with Prettier (2-space JS/TS) and typical Rust
indent (4 spaces) across nevo_frontend, nevo_server, and nevo_contract.

Fixes #971
EOF
)"
  fi
  git push -u origin "chore/root-editorconfig" --force-with-lease
  if gh pr list --repo Web3Novalabs/Nevo --head "$USER_LOGIN:chore/root-editorconfig" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Web3Novalabs/Nevo \
      --head "$USER_LOGIN:chore/root-editorconfig" \
      --title "chore: add root .editorconfig for consistent formatting" \
      --body "$(cat <<'EOF'
## Summary
Adds a root `.editorconfig` so editors share charset/EOL/indent defaults across TypeScript layers (2-space, matching Prettier) and Rust/TOML (4-space).

Fixes #971

## Test plan
- [x] File-only change
- [ ] Open a `.ts` and `.rs` file in an EditorConfig-aware editor and confirm indent hints
EOF
)"
  else
    gh pr list --repo Web3Novalabs/Nevo --head "$USER_LOGIN:chore/root-editorconfig" --state open
  fi
)
fi

########################################
# 27) triageiq #14
########################################
echo ""
echo "======== PR 27: SakethSumanBathini/triageiq#14 ========"
if skip_if_assigned_elsewhere "SakethSumanBathini/triageiq" 14; then
claim_issue "SakethSumanBathini/triageiq" 14 ".take — adding a Clear button that resets subject/body/sender/sender_name on the active email and disables when those fields are already empty."
fork_and_clone "SakethSumanBathini/triageiq"
(
  cd "$WORKDIR/triageiq"
  DEFAULT="$(gh api repos/SakethSumanBathini/triageiq --jq .default_branch)"
  git checkout -B "feat/clear-email-form" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("frontend/src/components/EmailInput/LandingPage.tsx")
text = path.read_text(encoding="utf-8")

if "clearActiveEmail" in text or 'aria-label="Clear email form"' in text:
    print("already patched")
else:
    if "Eraser" not in text:
        text = text.replace(
            "import { Zap, Plus, Trash2, Mail, ChevronDown, AlertCircle, Sparkles } from 'lucide-react'",
            "import { Zap, Plus, Trash2, Mail, ChevronDown, AlertCircle, Sparkles, Eraser } from 'lucide-react'",
            1,
        )

    helper = (
        "\n"
        "  const clearActiveEmail = () => {\n"
        "    setEmails(prev => prev.map((e, i) => i === activeIndex ? emptyEmail() : e))\n"
        "  }\n"
        "\n"
        "  const isActiveEmpty = !emails[activeIndex]?.subject.trim()\n"
        "    && !emails[activeIndex]?.body.trim()\n"
        "    && !emails[activeIndex]?.sender.trim()\n"
        "    && !emails[activeIndex]?.sender_name.trim()\n"
        "\n"
        "  const canSubmit = emails.some(e => e.subject.trim() && e.body.trim())\n"
    )
    needle = "  const canSubmit = emails.some(e => e.subject.trim() && e.body.trim())\n"
    if needle not in text:
        raise SystemExit("canSubmit line not found")
    text = text.replace(needle, helper, 1)

    old_submit = (
        "        {/* Submit */}\n"
        "        <motion.div className=\"mt-6 flex items-center gap-4\">\n"
        "          <button\n"
        "            onClick={() => onSubmit(emails.filter(e => e.subject.trim() && e.body.trim()))}\n"
        "            disabled={!canSubmit || isLoading}\n"
        "            className=\"btn-primary flex-1 py-4 text-base\"\n"
        "          >\n"
        "            <Zap size={18} />\n"
        "            {isLoading ? 'Analyzing…' : `Analyze ${emails.filter(e => e.subject.trim()).length} Email${emails.filter(e => e.subject.trim()).length !== 1 ? 's' : ''}`}\n"
        "          </button>\n"
        "        </motion.div>"
    )
    new_submit = (
        "        {/* Submit */}\n"
        "        <motion.div className=\"mt-6 flex items-center gap-4\">\n"
        "          <button\n"
        "            type=\"button\"\n"
        "            onClick={clearActiveEmail}\n"
        "            disabled={isActiveEmpty || isLoading}\n"
        "            className=\"btn-secondary py-4 px-5\"\n"
        "            aria-label=\"Clear email form\"\n"
        "          >\n"
        "            <Eraser size={16} />\n"
        "            Clear\n"
        "          </button>\n"
        "          <button\n"
        "            onClick={() => onSubmit(emails.filter(e => e.subject.trim() && e.body.trim()))}\n"
        "            disabled={!canSubmit || isLoading}\n"
        "            className=\"btn-primary flex-1 py-4 text-base\"\n"
        "          >\n"
        "            <Zap size={18} />\n"
        "            {isLoading ? 'Analyzing…' : `Analyze ${emails.filter(e => e.subject.trim()).length} Email${emails.filter(e => e.subject.trim()).length !== 1 ? 's' : ''}`}\n"
        "          </button>\n"
        "        </motion.div>"
    )
    if old_submit not in text:
        raise SystemExit("Submit block not found")
    text = text.replace(old_submit, new_submit, 1)
    path.write_text(text, encoding="utf-8")
    print("patched LandingPage.tsx")
PY
  git add frontend/src/components/EmailInput/LandingPage.tsx
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
feat(ui): add Clear button to email input form

Reset subject, body, sender, and sender_name on the active email.
Disable Clear when those fields are already empty.

Fixes #14
EOF
)"
  fi
  git push -u origin "feat/clear-email-form" --force-with-lease
  if gh pr list --repo SakethSumanBathini/triageiq --head "$USER_LOGIN:feat/clear-email-form" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo SakethSumanBathini/triageiq \
      --head "$USER_LOGIN:feat/clear-email-form" \
      --title "feat(ui): add Clear button to email input form" \
      --body "$(cat <<'EOF'
## Summary
Adds a Clear button next to Analyze that resets the active email's subject, body, sender, and sender_name. The button is disabled when the active email is already empty.

Fixes #14

## Test plan
- [ ] Fill fields → Clear empties them
- [ ] Clear stays disabled on a blank form
- [ ] Analyze still works after clearing and re-entering data
EOF
)"
  else
    gh pr list --repo SakethSumanBathini/triageiq --head "$USER_LOGIN:feat/clear-email-form" --state open
  fi
)
fi

########################################
# 28) triageiq #15
########################################
echo ""
echo "======== PR 28: SakethSumanBathini/triageiq#15 ========"
if skip_if_assigned_elsewhere "SakethSumanBathini/triageiq" 15; then
claim_issue "SakethSumanBathini/triageiq" 15 ".take — rendering a lucide empty-state (icon + heading + subtitle + CTA) when the triaged-email list is empty."
if [[ ! -d "$WORKDIR/triageiq/.git" ]]; then
  fork_and_clone "SakethSumanBathini/triageiq"
fi
(
  cd "$WORKDIR/triageiq"
  git fetch upstream
  DEFAULT="$(gh api repos/SakethSumanBathini/triageiq --jq .default_branch)"
  git checkout -B "feat/dashboard-empty-state" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("frontend/src/components/Dashboard/Dashboard.tsx")
text = path.read_text(encoding="utf-8")

if "No emails triaged yet" in text:
    print("already patched")
else:
    text = text.replace(
        "import {\n"
        "  Zap, RotateCcw, AlertTriangle, CheckCircle,\n"
        "  Clock, Users, Filter, ChevronDown\n"
        "} from 'lucide-react'",
        "import {\n"
        "  Zap, RotateCcw, AlertTriangle, CheckCircle,\n"
        "  Clock, Users, Filter, ChevronDown, Inbox\n"
        "} from 'lucide-react'",
        1,
    )

    marker = "  return (\n    <div className=\"min-h-screen flex flex-col\">\n      {/* Header */}"
    empty_block = (
        "  if (results.results.length === 0) {\n"
        "    return (\n"
        "      <div className=\"min-h-screen flex flex-col\">\n"
        "        <motion.header\n"
        "          initial={{ opacity: 0, y: -20 }}\n"
        "          animate={{ opacity: 1, y: 0 }}\n"
        "          className=\"flex items-center justify-between px-6 py-4 border-b border-[rgba(0,212,255,0.08)]\"\n"
        "        >\n"
        "          <div className=\"flex items-center gap-3\">\n"
        "            <div className=\"w-8 h-8 rounded-xl bg-gradient-to-br from-cyan-400 to-blue-600 flex items-center justify-center\">\n"
        "              <Zap size={16} className=\"text-white\" />\n"
        "            </div>\n"
        "            <span className=\"font-bold text-lg text-white\" style={{ fontFamily: 'Syne, sans-serif' }}>\n"
        "              Triage<span className=\"text-electric\">IQ</span>\n"
        "            </span>\n"
        "          </div>\n"
        "          <button onClick={onReset} className=\"btn-secondary py-2\">\n"
        "            <RotateCcw size={14} />\n"
        "            New Analysis\n"
        "          </button>\n"
        "        </motion.header>\n"
        "        <div className=\"flex-1 flex items-center justify-center p-8\">\n"
        "          <motion.div\n"
        "            initial={{ opacity: 0, y: 16 }}\n"
        "            animate={{ opacity: 1, y: 0 }}\n"
        "            className=\"text-center max-w-md\"\n"
        "          >\n"
        "            <div className=\"w-16 h-16 mx-auto mb-5 rounded-2xl bg-electric/10 border border-electric/20 flex items-center justify-center\">\n"
        "              <Inbox size={28} className=\"text-electric\" />\n"
        "            </div>\n"
        "            <h2 className=\"text-2xl font-bold text-white mb-2\" style={{ fontFamily: 'Syne, sans-serif' }}>\n"
        "              No emails triaged yet\n"
        "            </h2>\n"
        "            <p className=\"text-[#8ba3c4] text-sm leading-relaxed mb-6\" style={{ fontFamily: 'DM Sans, sans-serif' }}>\n"
        "              Paste a support email on the input screen to get AI classification, urgency scores, and routing suggestions.\n"
        "            </p>\n"
        "            <button onClick={onReset} className=\"btn-primary py-3 px-6\">\n"
        "              <Zap size={16} />\n"
        "              Triage your first email\n"
        "            </button>\n"
        "          </motion.div>\n"
        "        </div>\n"
        "      </div>\n"
        "    )\n"
        "  }\n"
        "\n"
    ) + marker
    if marker not in text:
        raise SystemExit("Dashboard return marker not found")
    text = text.replace(marker, empty_block, 1)
    path.write_text(text, encoding="utf-8")
    print("patched Dashboard.tsx")
PY
  git add frontend/src/components/Dashboard/Dashboard.tsx
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
feat(ui): show friendly empty state when no emails are triaged

Render an Inbox icon, heading, subtitle, and CTA instead of empty
KPI grids when results.results is empty.

Fixes #15
EOF
)"
  fi
  git push -u origin "feat/dashboard-empty-state" --force-with-lease
  if gh pr list --repo SakethSumanBathini/triageiq --head "$USER_LOGIN:feat/dashboard-empty-state" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo SakethSumanBathini/triageiq \
      --head "$USER_LOGIN:feat/dashboard-empty-state" \
      --title "feat(ui): show friendly empty state when no emails are triaged" \
      --body "$(cat <<'EOF'
## Summary
When `results.results` is empty, the dashboard now shows a lucide Inbox empty state with a heading, short prompt, and Triage your first email CTA instead of blank KPI/queue chrome.

Filter-empty copy ("No emails match current filters") is unchanged for non-empty result sets.

Fixes #15

## Test plan
- [ ] Load dashboard with an empty `results.results` array → empty state visible
- [ ] CTA / New Analysis returns to the input screen
- [ ] Normal triage results still render KPIs + queue
EOF
)"
  else
    gh pr list --repo SakethSumanBathini/triageiq --head "$USER_LOGIN:feat/dashboard-empty-state" --state open
  fi
)
fi

########################################
# 29) avenx-js #639
########################################
echo ""
echo "======== PR 29: Avenx-JS/avenx-js#639 ========"
if skip_if_assigned_elsewhere "Avenx-JS/avenx-js" 639; then
claim_issue "Avenx-JS/avenx-js" 639 "I'll take this — warning via \`logger.warn\` when a guard's \`canActivate\` resolves to \`undefined\`, while still allowing navigation (least-breaking default)."
fork_and_clone "Avenx-JS/avenx-js"
(
  cd "$WORKDIR/avenx-js"
  DEFAULT="$(gh api repos/Avenx-JS/avenx-js --jq .default_branch)"
  git checkout -B "fix/warn-undefined-guard-return" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path

err = Path("lib/core/runtime/AvenxError.js")
e = err.read_text(encoding="utf-8")
if "ROUTER_GUARD_UNDEFINED_RETURN" in e:
    print("AvenxError already patched")
else:
    e = e.replace(
        " * @property {string} ROUTER_GUARD_TIMEOUT - AVX_R14: A navigation guard execution timed out.\n",
        " * @property {string} ROUTER_GUARD_TIMEOUT - AVX_R14: A navigation guard execution timed out.\n"
        " * @property {string} ROUTER_GUARD_UNDEFINED_RETURN - AVX_W27: A navigation guard returned undefined.\n",
        1,
    )
    e = e.replace(
        "  DIRECTIVE_CLASS_EVALUATION_FAILED: 'AVX_W23',\n};",
        "  DIRECTIVE_CLASS_EVALUATION_FAILED: 'AVX_W23',\n"
        "  ROUTER_GUARD_UNDEFINED_RETURN: 'AVX_W27',\n};",
        1,
    )
    e = e.replace(
        "  [AvenxErrorCodes.DIRECTIVE_CLASS_EVALUATION_FAILED]: 'Failed to evaluate data-ax-class: {0}. Error: {1}',\n};",
        "  [AvenxErrorCodes.DIRECTIVE_CLASS_EVALUATION_FAILED]: 'Failed to evaluate data-ax-class: {0}. Error: {1}',\n"
        "  [AvenxErrorCodes.ROUTER_GUARD_UNDEFINED_RETURN]:\n"
        "    'Navigation guard for route \"{0}\" returned undefined. Guards should explicitly return true, false, a redirect string, or a control object. Defaulting to allow.',\n};",
        1,
    )
    err.write_text(e, encoding="utf-8")
    print("patched AvenxError.js")

rpath = Path("lib/core/runtime/AvenxRouter.js")
r = rpath.read_text(encoding="utf-8")
old = (
    "        Promise.race([Promise.resolve(instance.canActivate(to, from)), timeoutPromise])\n"
    "          .then((result) => {\n"
    "            clearTimeout(timeoutId);\n"
    "            const isControlObject =\n"
    "              typeof result === 'object' &&\n"
    "              result !== null &&\n"
    "              (result.cancel === true || typeof result.redirect === 'string');\n"
    "\n"
    "            if (result === false || typeof result === 'string' || isControlObject) {\n"
    "              resolve(result);\n"
    "            } else {\n"
    "              nextGuard(index + 1);\n"
    "            }\n"
    "          })"
)
new = (
    "        Promise.race([Promise.resolve(instance.canActivate(to, from)), timeoutPromise])\n"
    "          .then((result) => {\n"
    "            clearTimeout(timeoutId);\n"
    "            if (result === undefined) {\n"
    "              logger.warn(formatMessage(AvenxErrorCodes.ROUTER_GUARD_UNDEFINED_RETURN, to.hash));\n"
    "              nextGuard(index + 1);\n"
    "              return;\n"
    "            }\n"
    "            const isControlObject =\n"
    "              typeof result === 'object' &&\n"
    "              result !== null &&\n"
    "              (result.cancel === true || typeof result.redirect === 'string');\n"
    "\n"
    "            if (result === false || typeof result === 'string' || isControlObject) {\n"
    "              resolve(result);\n"
    "            } else {\n"
    "              nextGuard(index + 1);\n"
    "            }\n"
    "          })"
)
if "ROUTER_GUARD_UNDEFINED_RETURN" in r and "result === undefined" in r:
    print("AvenxRouter already patched")
elif old not in r:
    raise SystemExit("#runGuards Promise.race block not found")
else:
    rpath.write_text(r.replace(old, new, 1), encoding="utf-8")
    print("patched AvenxRouter.js")

tpath = Path("test/integration/router.test.js")
t = tpath.read_text(encoding="utf-8")
if "undefined guard return should warn" in t:
    print("test already patched")
else:
    append = """

describe('AvenxRouter guard undefined return warning', () => {
  it('undefined guard return should warn and still allow navigation', async () => {
    const { AvenxApp } = await import('../../lib/core/runtime/AvenxApp.js');
    const { AvenxGuard } = await import('../../lib/core/runtime/AvenxGuard.js');
    const { logger } = await import('../../lib/core/runtime/AvenxLogger.js');
    const { AvenxErrorCodes } = await import('../../lib/core/runtime/AvenxError.js');
    const assert = await import('node:assert');

    const warnings = [];
    const originalWarn = logger.warn.bind(logger);
    logger.warn = (...args) => {
      warnings.push(args.join(' '));
      return originalWarn(...args);
    };

    try {
      document.body.innerHTML = '<div id="app"></div>';
      class TestPage {
        mount() {}
        unmount() {}
      }
      const app = new AvenxApp({ target: '#app' });
      app.registerPage('TestPage', TestPage);

      class UndefinedGuard extends AvenxGuard {
        canActivate() {
          // intentionally no return
        }
      }
      class AllowGuard extends AvenxGuard {
        canActivate() {
          return true;
        }
      }

      app.initRouter({
        '': 'TestPage',
        '#/': 'TestPage',
        '#/secure': {
          page: 'TestPage',
          guards: [UndefinedGuard],
        },
        '#/ok': {
          page: 'TestPage',
          guards: [AllowGuard],
        },
      });
      await new Promise((r) => setTimeout(r, 0));

      warnings.length = 0;
      window.location.hash = '#/secure';
      await new Promise((r) => setTimeout(r, 20));
      assert.ok(
        warnings.some((w) => w.includes(AvenxErrorCodes.ROUTER_GUARD_UNDEFINED_RETURN)),
        'expected AVX_W27 warning for undefined guard return',
      );

      warnings.length = 0;
      window.location.hash = '#/ok';
      await new Promise((r) => setTimeout(r, 20));
      assert.ok(
        !warnings.some((w) => w.includes(AvenxErrorCodes.ROUTER_GUARD_UNDEFINED_RETURN)),
        'explicit true should not warn',
      );
    } finally {
      logger.warn = originalWarn;
    }
  });
});
"""
    tpath.write_text(t + append, encoding="utf-8")
    print("appended router test")
PY
  git add lib/core/runtime/AvenxError.js lib/core/runtime/AvenxRouter.js test/integration/router.test.js
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(router): warn when route guards return undefined

Guards that omit a return currently allow navigation silently. Emit
AVX_W27 via logger.warn when canActivate resolves to undefined, while
preserving allow-by-default behavior for compatibility.

Fixes #639
EOF
)"
  fi
  git push -u origin "fix/warn-undefined-guard-return" --force-with-lease
  if gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:fix/warn-undefined-guard-return" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Avenx-JS/avenx-js \
      --head "$USER_LOGIN:fix/warn-undefined-guard-return" \
      --title "fix(router): warn when route guards return undefined" \
      --body "$(cat <<'EOF'
## Summary
When a route guard's `canActivate` returns `undefined` (or a Promise that resolves to `undefined`), the router now logs `AVX_W27` via `logger.warn` and continues to allow navigation (least-breaking default). Explicit `true` / `false` / redirect strings / control objects are unchanged and do not warn.

Fixes #639

## Test plan
- [ ] Integration test: undefined return triggers warning; `return true` does not
- [ ] Existing guard allow/deny/redirect cases still pass
EOF
)"
  else
    gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:fix/warn-undefined-guard-return" --state open
  fi
)
fi

echo ""
echo "Batch 8 done."
gh search prs --author "$USER_LOGIN" --state open --limit 30
