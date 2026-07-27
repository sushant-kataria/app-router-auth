# PR 36 — json.ts: stop infinite loop on unterminated strings

**Issue:** https://github.com/abatef/json.ts/issues/2  
**Impact:** Scanner hang / unbounded memory on missing closing quote  
**File:** `src/scanner.ts`

## Claim
I'll take this — bounding `scanString()` with an end-of-input check and reporting `unterminated string` instead of looping forever.

## Change
In `scanString()`, loop while `current_ < data_.length && currentChar() !== quote`. If the quote is never found, `reportError('unterminated string', …)` and return without emitting a token.

## Competing PRs
None open when drafted.
