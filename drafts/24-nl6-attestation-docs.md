# PR 24 — nl6: fix RELEASING attestation verify docs

**Issue:** https://github.com/labmonkeys-space/nl6/issues/343  
**Impact:** Release verification docs currently look broken (`gh attestation verify` silent on gh 2.96)  
**File:** `RELEASING.md`

## Claim
I'll take this — documenting the reliable digest/API attestation check and noting that `gh attestation verify` may exit 0 with empty output on some gh versions.

## Change
Replace silent `gh attestation verify …` steps with sha256 + `gh api …/attestations/sha256:…` verification (keep working cosign steps).
