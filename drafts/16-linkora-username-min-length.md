# PR 16 — Linkora: enforce minimum username length

**Issue:** https://github.com/Epta-Node/Linkora-social/issues/941  
**Impact:** Smart-contract input validation (stops 1–2 char username squatting) + wires orphaned tests  
**Files:**
- `packages/contracts/contracts/linkora-contracts/src/validation.rs`
- `packages/contracts/contracts/linkora-contracts/src/test.rs`
- `packages/contracts/contracts/linkora-contracts/src/tests/mod.rs`
- `packages/contracts/contracts/linkora-contracts/src/tests/set_profile_tests.rs`

**Status:** **SKIPPED** — assigned to @morelucks; issue closed before submit. Do not open a competing PR.

## Claim

```text
I'll take this — adding a minimum username length (3) in `validate_username`, aligning the existing unit tests, and wiring `set_profile_tests` into the test module so the panic expectations actually run.
```

## Change summary

1. Add `MIN_USERNAME_LEN = 3` and reject shorter names with panic `"username too short"`.
2. Flip `test_username_too_short` in `test.rs` from “allows `ab`” to `#[should_panic]`.
3. Rewrite `set_profile_tests.rs` to match the `invariants` helper style and register it in `tests/mod.rs`.

## Why this is stronger than a typo PR

Contract validation gap + dead test file. Fixes real registration abuse surface and makes CI enforce the rule.
