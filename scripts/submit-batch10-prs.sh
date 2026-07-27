#!/usr/bin/env bash
# Batch 10 — merge-velocity external PRs (proven repos + real bugs)
#   bash scripts/submit-batch10-prs.sh
#
# Targets:
#   35) abatef/json.ts#1 — scanner infinite loop on unrecognized char
#   36) abatef/json.ts#2 — scanner infinite loop on unterminated string
#   37) Avenx-JS/avenx-js#647 — document data-ax-class
#   38) Avenx-JS/avenx-js#638 — warn on multiple <state> tags
#   39) crackedstudio/sharibo#111 — favicon + social meta tags
#
# Windows: grantpath-submit-lib.sh (relative clone + python shim + textio).
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=grantpath-submit-lib.sh
source "$SCRIPT_DIR/grantpath-submit-lib.sh"

need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need git; need gh
grantpath_resolve_python
grantpath_init_workdir "batch10"

ACTIVE="$(gh api user --jq .login 2>/dev/null || true)"
if [[ -z "$ACTIVE" || "$ACTIVE" != "$USER_LOGIN" ]]; then
  echo "Need gh auth as $USER_LOGIN (got: '${ACTIVE:-none}'). Run: gh auth login"
  exit 1
fi

echo "==> Authenticated as $ACTIVE"
echo "==> Batch 10: merge-velocity (json.ts / avenx / sharibo)"

########################################
# 35) json.ts #1 — unrecognized character
########################################
echo ""
echo "======== PR 35: abatef/json.ts#1 ========"
if skip_if_assigned_elsewhere "abatef/json.ts" 1; then
claim_issue "abatef/json.ts" 1 "I'll take this — reporting an error and advancing past unrecognized characters so \`scan()\` always makes progress."
fork_and_clone "abatef/json.ts"
(
  cd "$WORKDIR/json.ts"
  DEFAULT="$(gh api repos/abatef/json.ts --jq .default_branch)"
  git checkout -B "fix/scanner-unrecognized-char" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("src/scanner.ts")
text = path.read_text(encoding="utf-8")
old = """      if (char === '"') {
        this.scanString();
      } else if (this.isDigit(char) || this.currentChar() === '-' || this.currentChar() === '.') {
        this.scanNumber();
      } else if (this.isChar(char)) {
        this.scanLiteral();
      }
    }
  }"""
new = """      if (char === '"') {
        this.scanString();
      } else if (this.isDigit(char) || this.currentChar() === '-' || this.currentChar() === '.') {
        this.scanNumber();
      } else if (this.isChar(char)) {
        this.scanLiteral();
      } else if (
        char !== undefined &&
        !['[', ']', '{', '}', ':', ','].includes(char)
      ) {
        // Unrecognized input must advance — otherwise scan() spins forever (#1).
        this.reportError('unrecognized character', String(char));
        this.current_++;
      }
    }
  }"""
if "unrecognized character" in text:
    print("already patched")
elif old not in text:
    raise SystemExit("scanner scan() dispatch block not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched scanner.ts (#1 unrecognized char)")
PY
  git add src/scanner.ts
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(scanner): advance past unrecognized characters

Unrecognized input (e.g. `@`) previously fell through without advancing
`current_`, hanging `scan()` forever. Report an error and skip the char.

Fixes #1
EOF
)"
  fi
  git push -u origin "fix/scanner-unrecognized-char" --force-with-lease
  if gh pr list --repo abatef/json.ts --head "$USER_LOGIN:fix/scanner-unrecognized-char" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo abatef/json.ts \
      --head "$USER_LOGIN:fix/scanner-unrecognized-char" \
      --title "fix(scanner): advance past unrecognized characters" \
      --body "$(cat <<'EOF'
## Summary
`Scanner.scan()` could loop forever on unrecognized characters (`@`, `#`, …): the `default` branch and post-switch handlers neither advanced `current_` nor reported an error.

This reports `unrecognized character` and advances one byte so every iteration makes progress.

Fixes #1

## Test plan
- [ ] Input `@` or `{"a":@}` no longer hangs; error is logged
- [ ] Valid JSON (`{}`, `[1,2]`, `"hi"`) still tokenizes
EOF
)"
  else
    gh pr list --repo abatef/json.ts --head "$USER_LOGIN:fix/scanner-unrecognized-char" --state open
  fi
)
fi

########################################
# 36) json.ts #2 — unterminated string
########################################
echo ""
echo "======== PR 36: abatef/json.ts#2 ========"
if skip_if_assigned_elsewhere "abatef/json.ts" 2; then
claim_issue "abatef/json.ts" 2 "I'll take this — bounding \`scanString()\` with an end-of-input check and reporting unterminated strings instead of looping forever."
fork_and_clone "abatef/json.ts"
(
  cd "$WORKDIR/json.ts"
  DEFAULT="$(gh api repos/abatef/json.ts --jq .default_branch)"
  git checkout -B "fix/scanner-unterminated-string" "upstream/$DEFAULT"
  # Re-apply #1 fix if that PR is not merged yet (independent branch from upstream).
  run_python_patch <<'PY'
from pathlib import Path
path = Path("src/scanner.ts")
text = path.read_text(encoding="utf-8")
old = """  private scanString(): void {
    const quote = this.currentChar();
    this.current_++;
    let string: string = '';
    while (this.currentChar() !== quote) {
      string += this.currentChar();
      this.current_++;
    }
    this.current_++;
    this.makeToken('String', string);
  }"""
new = """  private scanString(): void {
    const quote = this.currentChar();
    this.current_++;
    let string: string = '';
    while (this.current_ < this.data_.length && this.currentChar() !== quote) {
      string += this.currentChar();
      this.current_++;
    }
    if (this.current_ >= this.data_.length || this.currentChar() !== quote) {
      // Missing closing quote previously looped forever (#2).
      this.reportError('unterminated string', String(quote));
      return;
    }
    this.current_++;
    this.makeToken('String', string);
  }"""
if "unterminated string" in text:
    print("already patched")
elif old not in text:
    raise SystemExit("scanString() block not found")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("patched scanner.ts (#2 unterminated string)")
PY
  git add src/scanner.ts
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(scanner): reject unterminated strings without hanging

`scanString()` compared `currentChar() !== quote` with no end check, so
a missing closer made `undefined !== quote` forever and grew memory.
Bound the loop and report `unterminated string`.

Fixes #2
EOF
)"
  fi
  git push -u origin "fix/scanner-unterminated-string" --force-with-lease
  if gh pr list --repo abatef/json.ts --head "$USER_LOGIN:fix/scanner-unterminated-string" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo abatef/json.ts \
      --head "$USER_LOGIN:fix/scanner-unterminated-string" \
      --title "fix(scanner): reject unterminated strings without hanging" \
      --body "$(cat <<'EOF'
## Summary
`scanString()` looped forever on a missing closing quote (`"abc`), appending `"undefined"` unboundedly.

The loop is now bounded by `current_ < data_.length`. If the quote is never found, we log `unterminated string` and return without emitting a token.

Fixes #2

## Test plan
- [ ] Input `"abc` (no closer) no longer hangs; error is logged
- [ ] Normal `"hello"` still produces a String token
EOF
)"
  else
    gh pr list --repo abatef/json.ts --head "$USER_LOGIN:fix/scanner-unterminated-string" --state open
  fi
)
fi

########################################
# 37) Avenx #647 — data-ax-class docs
########################################
echo ""
echo "======== PR 37: Avenx-JS/avenx-js#647 ========"
if skip_if_assigned_elsewhere "Avenx-JS/avenx-js" 647; then
claim_issue "Avenx-JS/avenx-js" 647 "I'll take this — documenting \`data-ax-class\` (string + object formats) in the templates guide next to \`data-ax-style\`."
fork_and_clone "Avenx-JS/avenx-js"
(
  cd "$WORKDIR/avenx-js"
  DEFAULT="$(gh api repos/Avenx-JS/avenx-js --jq .default_branch)"
  git checkout -B "docs/data-ax-class" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("docs/src/content/docs/core-concepts/templates.md")
text = path.read_text(encoding="utf-8")
marker = "Using object syntax keeps templates more readable and maintainable than manually constructing inline style strings.\n\n## 4. Loops (`<@for>`)"
section = """Using object syntax keeps templates more readable and maintainable than manually constructing inline style strings.

## Dynamic Class Bindings (`data-ax-class`)

Use the `data-ax-class` directive to add or remove CSS classes reactively. Static `class=\"…\"` attributes on the same element are preserved.

### String Format

When the expression evaluates to a string, its space-separated tokens are applied as class names:

```html
<div class=\"card\" data-ax-class=\"state.themeClass\">
  Themed card
</div>
```

```js
// e.g. in <state />
themeClass=\"theme-dark highlight\"
```

When `state.themeClass` changes, previously applied dynamic classes from this directive are replaced with the new set. The static `card` class remains.

### Object Format

Pass an object whose **truthy** keys become class names (quote keys that are not valid identifiers):

```html
<button
  class=\"btn\"
  data-ax-class=\"{ active: state.isActive, 'text-large': state.isLarge, disabled: state.isDisabled }\"
>
  Action
</button>
```

| Expression value | Result |
| ---------------- | ------ |
| `{ active: true, 'text-large': false }` | adds `active`; removes `text-large` if it was previously set by this directive |
| `\"theme-blue\"` | applies `theme-blue` |
| `\"\"` / falsy | clears dynamic classes from this directive |

> **Note:** Object and string forms are evaluated as template expressions in the component scope (same rules as other `data-ax-*` bindings). Prefer object form for multiple independent toggles.

## 4. Loops (`<@for>`)"""
if "Dynamic Class Bindings (`data-ax-class`)" in text:
    print("already patched")
elif marker not in text:
    raise SystemExit("templates.md insert marker not found")
else:
    path.write_text(text.replace(marker, section, 1), encoding="utf-8")
    print("patched templates.md (data-ax-class)")
PY
  git add docs/src/content/docs/core-concepts/templates.md
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
docs: document data-ax-class string and object bindings

The templates guide covered data-ax-style but omitted data-ax-class.
Add string and object format examples next to the style section.

Fixes #647
EOF
)"
  fi
  git push -u origin "docs/data-ax-class" --force-with-lease
  if gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:docs/data-ax-class" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Avenx-JS/avenx-js \
      --head "$USER_LOGIN:docs/data-ax-class" \
      --title "docs: document data-ax-class string and object bindings" \
      --body "$(cat <<'EOF'
## Summary
Adds a **Dynamic Class Bindings (`data-ax-class`)** section to `docs/src/content/docs/core-concepts/templates.md`, covering:

- String format (space-separated class names)
- Object format (truthy keys applied as classes)
- Preservation of static `class` attributes

Fixes #647

## Test plan
- [ ] Docs site / markdown preview renders the new section
- [ ] Examples match runtime behavior in `test/unit/directives.test.js`
EOF
)"
  else
    gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:docs/data-ax-class" --state open
  fi
)
fi

########################################
# 38) Avenx #638 — multiple <state> warning
########################################
echo ""
echo "======== PR 38: Avenx-JS/avenx-js#638 ========"
if skip_if_assigned_elsewhere "Avenx-JS/avenx-js" 638; then
claim_issue "Avenx-JS/avenx-js" 638 "I'll take this — emitting \`AVX_W28\` when more than one \`<state>\` tag is present (only the first is reactive)."
fork_and_clone "Avenx-JS/avenx-js"
(
  cd "$WORKDIR/avenx-js"
  DEFAULT="$(gh api repos/Avenx-JS/avenx-js --jq .default_branch)"
  git checkout -B "fix/warn-multiple-state-tags" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path

# --- AvenxError.js ---
err = Path("lib/core/runtime/AvenxError.js")
etext = err.read_text(encoding="utf-8")
if "COMPILER_MULTIPLE_STATE_TAGS" in etext:
    print("AvenxError already has AVX_W28")
else:
    old_code = "  ROUTER_GUARD_UNDEFINED_RETURN: 'AVX_W27',\n};"
    new_code = """  ROUTER_GUARD_UNDEFINED_RETURN: 'AVX_W27',
  COMPILER_MULTIPLE_STATE_TAGS: 'AVX_W28',
};"""
    if old_code not in etext:
        raise SystemExit("AvenxErrorCodes insert point not found")
    etext = etext.replace(old_code, new_code, 1)
    old_msg = """  [AvenxErrorCodes.ROUTER_GUARD_UNDEFINED_RETURN]:
    'Navigation guard for route "{0}" returned undefined. Guards should explicitly return true, false, a redirect string, or a control object. Defaulting to allow.',
};"""
    new_msg = """  [AvenxErrorCodes.ROUTER_GUARD_UNDEFINED_RETURN]:
    'Navigation guard for route "{0}" returned undefined. Guards should explicitly return true, false, a redirect string, or a control object. Defaulting to allow.',
  [AvenxErrorCodes.COMPILER_MULTIPLE_STATE_TAGS]:
    'Multiple <state> tags found in component source. Only the first <state> declaration is reactive; subsequent tags are ignored.',
};"""
    if old_msg not in etext:
        raise SystemExit("AvenxErrorMessages insert point not found")
    etext = etext.replace(old_msg, new_msg, 1)
    # JSDoc near other W codes if present
    old_doc = " * @property {string} ROUTER_GUARD_UNDEFINED_RETURN - AVX_W27: A navigation guard returned undefined.\n"
    new_doc = old_doc + " * @property {string} COMPILER_MULTIPLE_STATE_TAGS - AVX_W28: Multiple <state> tags; only the first is used.\n"
    if old_doc in etext and "COMPILER_MULTIPLE_STATE_TAGS - AVX_W28" not in etext:
        etext = etext.replace(old_doc, new_doc, 1)
    err.write_text(etext, encoding="utf-8")
    print("patched AvenxError.js")

# --- expressionParser.js ---
ep = Path("lib/compiler/expressionParser.js")
etext = ep.read_text(encoding="utf-8")
if "COMPILER_MULTIPLE_STATE_TAGS" in etext:
    print("expressionParser already patched")
else:
    if "from '../core/runtime/AvenxLogger.js'" not in etext:
        etext = (
            "import { logger } from '../core/runtime/AvenxLogger.js';\n"
            "import { AvenxErrorCodes } from '../core/runtime/AvenxError.js';\n"
            "import { TemplateValidationError } from './errors/TemplateValidationError.js';\n"
            + etext
        )
    old_fn = """  parseState(content) {
    const state = {};
    const match = content.match(/<state\\s+([\\s\\S]*?)\\s*\\/>/);
    if (match) {"""
    new_fn = """  parseState(content) {
    const state = {};
    const stateTags = content.match(/<state\\s+[\\s\\S]*?\\s*\\/>/g) || [];
    if (stateTags.length > 1) {
      logger.warn(
        new TemplateValidationError(AvenxErrorCodes.COMPILER_MULTIPLE_STATE_TAGS).message,
      );
    }
    const match = content.match(/<state\\s+([\\s\\S]*?)\\s*\\/>/);
    if (match) {"""
    if old_fn not in etext:
        raise SystemExit("parseState() block not found")
    ep.write_text(etext.replace(old_fn, new_fn, 1), encoding="utf-8")
    print("patched expressionParser.js")

# --- test ---
tpath = Path("test/unit/expression_parser.test.js")
t = tpath.read_text(encoding="utf-8")
if "COMPILER_MULTIPLE_STATE_TAGS" in t:
    print("test already patched")
else:
    if "from '../../lib/core/runtime/AvenxLogger.js'" not in t:
        t = t.replace(
            "import ExpressionParser from '../../lib/compiler/expressionParser.js';\n",
            "import ExpressionParser from '../../lib/compiler/expressionParser.js';\n"
            "import { logger } from '../../lib/core/runtime/AvenxLogger.js';\n"
            "import { AvenxErrorCodes } from '../../lib/core/runtime/AvenxError.js';\n",
            1,
        )
    append = """
  // Multiple <state> tags: warn (AVX_W28) and only parse the first
  {
    const warnings = [];
    const originalWarn = logger.warn;
    logger.warn = (msg) => warnings.push(String(msg));
    try {
      const multiState = `
        <state a="1" label="first" />
        <state b="2" label="second" />
      `;
      const multi = ep.parseState(multiState);
      assert.strictEqual(multi.a, 1);
      assert.strictEqual(multi.label, 'first');
      assert.strictEqual(multi.b, undefined);
      assert.ok(
        warnings.some((w) => w.includes(AvenxErrorCodes.COMPILER_MULTIPLE_STATE_TAGS)),
        'expected AVX_W28 warning for multiple <state> tags',
      );
    } finally {
      logger.warn = originalWarn;
    }
  }

"""
    needle = "  console.log('  ✅ ExpressionParser upgrades tests passed!');"
    if needle not in t:
        raise SystemExit("expression_parser.test.js success log not found")
    tpath.write_text(t.replace(needle, append + needle, 1), encoding="utf-8")
    print("patched expression_parser.test.js")
PY
  git add lib/core/runtime/AvenxError.js lib/compiler/expressionParser.js test/unit/expression_parser.test.js
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(compiler): warn when multiple <state> tags are present

Only the first <state /> is parsed for reactivity; extra tags were
silently ignored. Emit AVX_W28 via logger.warn so authors notice.

Fixes #638
EOF
)"
  fi
  git push -u origin "fix/warn-multiple-state-tags" --force-with-lease
  if gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:fix/warn-multiple-state-tags" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo Avenx-JS/avenx-js \
      --head "$USER_LOGIN:fix/warn-multiple-state-tags" \
      --title "fix(compiler): warn when multiple <state> tags are present" \
      --body "$(cat <<'EOF'
## Summary
`ExpressionParser.parseState` only ever registers the first `<state … />` tag. Additional tags were ignored with no signal.

This adds `AVX_W28` (`COMPILER_MULTIPLE_STATE_TAGS`) and logs it via `logger.warn` when more than one `<state>` tag is present. Parsing behavior for the first tag is unchanged.

Fixes #638

## Test plan
- [ ] `test/unit/expression_parser.test.js` — multiple tags warn and only first attrs are returned
- [ ] Single `<state>` components produce no new warning
EOF
)"
  else
    gh pr list --repo Avenx-JS/avenx-js --head "$USER_LOGIN:fix/warn-multiple-state-tags" --state open
  fi
)
fi

########################################
# 39) sharibo #111 — favicon + meta
########################################
echo ""
echo "======== PR 39: crackedstudio/sharibo#111 ========"
if skip_if_assigned_elsewhere "crackedstudio/sharibo" 111; then
claim_issue "crackedstudio/sharibo" 111 "I'll take this — adding an SVG favicon (ring motif) plus description / Open Graph / Twitter meta tags aligned with the README one-liner."
fork_and_clone "crackedstudio/sharibo"
(
  cd "$WORKDIR/sharibo"
  DEFAULT="$(gh api repos/crackedstudio/sharibo --jq .default_branch)"
  git checkout -B "feat/favicon-social-meta" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path

public = Path("app/public")
public.mkdir(parents=True, exist_ok=True)
favicon = public / "favicon.svg"
if not favicon.exists():
    favicon.write_text(
        """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" role="img" aria-label="Sharibo">
  <rect width="64" height="64" rx="14" fill="#0b1220"/>
  <circle cx="32" cy="32" r="18" fill="none" stroke="#7dd3fc" stroke-width="4"/>
  <circle cx="32" cy="32" r="6" fill="#38bdf8"/>
</svg>
""",
        encoding="utf-8",
    )
    print("wrote favicon.svg")
else:
    print("favicon.svg exists")

html_path = Path("app/index.html")
html = html_path.read_text(encoding="utf-8")
if 'rel="icon"' in html or "og:title" in html:
    print("index.html already has meta/icon")
else:
    old = """  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Sharibo — private savings circles on Stellar</title>
  </head>"""
    new = """  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Sharibo — private savings circles on Stellar</title>
    <meta
      name="description"
      content="Private rotating savings circles on Stellar — real Groth16 zero-knowledge proofs, verified on-chain. Testnet only."
    />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta property="og:type" content="website" />
    <meta property="og:title" content="Sharibo — private savings circles on Stellar" />
    <meta
      property="og:description"
      content="Private rotating savings circles on Stellar — real Groth16 zero-knowledge proofs, verified on-chain. Testnet only."
    />
    <meta name="twitter:card" content="summary" />
    <meta name="twitter:title" content="Sharibo — private savings circles on Stellar" />
    <meta
      name="twitter:description"
      content="Private rotating savings circles on Stellar — real Groth16 zero-knowledge proofs, verified on-chain. Testnet only."
    />
  </head>"""
    if old not in html:
        raise SystemExit("app/index.html head block not found")
    html_path.write_text(html.replace(old, new, 1), encoding="utf-8")
    print("patched index.html")
PY
  git add app/index.html app/public/favicon.svg
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
feat(app): add favicon and social meta tags

Give the demo a ring-motif SVG favicon and Open Graph / Twitter tags
so link previews match the README one-liner.

Fixes #111
EOF
)"
  fi
  git push -u origin "feat/favicon-social-meta" --force-with-lease
  if gh pr list --repo crackedstudio/sharibo --head "$USER_LOGIN:feat/favicon-social-meta" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo crackedstudio/sharibo \
      --head "$USER_LOGIN:feat/favicon-social-meta" \
      --title "feat(app): add favicon and social meta tags" \
      --body "$(cat <<'EOF'
## Summary
- Adds `app/public/favicon.svg` (simple ring motif) and links it from `app/index.html`
- Adds `meta description`, Open Graph (`og:title` / `og:description` / `og:type`), and Twitter card tags aligned with the README one-liner

Fixes #111

## Test plan
- [ ] `npm run dev` in `app/` — tab shows the SVG icon
- [ ] View page source / social debugger shows title + description
EOF
)"
  else
    gh pr list --repo crackedstudio/sharibo --head "$USER_LOGIN:feat/favicon-social-meta" --state open
  fi
)
fi

echo ""
echo "Batch 10 done."
gh search prs --author "$USER_LOGIN" --state open --limit 30
