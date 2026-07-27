# PR 38 — avenx-js: warn on multiple `<state>` tags

**Issue:** https://github.com/Avenx-JS/avenx-js/issues/638  
**Impact:** DevExp — silent ignored state tags become visible at compile time  
**Files:** `lib/compiler/expressionParser.js`, `lib/core/runtime/AvenxError.js`, `test/unit/expression_parser.test.js`

## Claim
I'll take this — emitting `AVX_W28` via `logger.warn` when more than one `<state … />` tag is present; only the first remains reactive.

## Change
1. Add `COMPILER_MULTIPLE_STATE_TAGS: 'AVX_W28'` + message in `AvenxError.js`
2. In `ExpressionParser.parseState`, match all `<state>` tags; if `length > 1`, `logger.warn(new TemplateValidationError(...).message)`
3. Unit test: two `<state>` tags → warning + only first tag’s attrs parsed

## Competing PRs
None open when drafted.
