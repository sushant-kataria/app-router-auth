# PR 41 — synapse-core: fix unbalanced parenthesis in tx search summary

**Startup:** Synapse  
**Issue:** https://github.com/Synapse-bridgez/synapse-core/issues/1002  
**File:** `src/cli.rs`

## Claim
I'll take this — closing the parenthesis in the `tx search` summary format string.

## Change
```rust
// before
"\n✓ {} results (total: {}",
// after
"\n✓ {} results (total: {})",
```

## Verify
- Apply patch and assert the closed format string is present
- `rg` confirms no remaining unbalanced `(total: {}` in that println

## Competing PRs
None open when drafted.
