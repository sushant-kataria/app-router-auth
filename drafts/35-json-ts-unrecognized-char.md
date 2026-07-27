# PR 35 — json.ts: stop infinite loop on unrecognized characters

**Issue:** https://github.com/abatef/json.ts/issues/1  
**Impact:** Scanner hang / DoS on any unrecognized input char (`@`, `#`, etc.)  
**File:** `src/scanner.ts`

## Claim
I'll take this — reporting an error and advancing past unrecognized characters so `scan()` always makes progress.

## Change
After the structural `switch` / string / number / literal handlers, if the char was not consumed, call `reportError('unrecognized character', …)` and `this.current_++`.

## Competing PRs
None open when drafted.
