# PR 19 — nl6: ship Debian copyright file in .deb packages

**Issue:** https://github.com/labmonkeys-space/nl6/issues/342  
**Impact:** Fixes Debian Policy §12.5 violation + SBOM `NOASSERTION` license for debs  
**Files:**
- `deploy/packages/nfpm.yaml`
- `deploy/packages/smoke-test.sh` (assert path on `.deb`)

**Status when drafted:** open, unassigned, 0 comments

## Claim

```text
I'll take this — packaging the Apache-2.0 LICENSE at `/usr/share/doc/nl6/copyright` via nfpm so debs satisfy Debian Policy §12.5 and SBOMs can declare the license (same as RPM already does).
```

## Change summary

In `nfpm.yaml` `contents:`:

```yaml
  # Debian Policy §12.5; Syft reads this for deb license (control License: is ignored).
  - src: ./LICENSE
    dst: /usr/share/doc/nl6/copyright
```

In smoke-test, for `*.deb` only:

```bash
[ -f /usr/share/doc/nl6/copyright ] || fail "Debian copyright file missing"
```
