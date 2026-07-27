# PR 25 — synapse-core: fix git-cliff commit link hrefs

**Issue:** https://github.com/Synapse-bridgez/synapse-core/issues/1011  
**Impact:** CHANGELOG commit hashes link to bare SHAs instead of GitHub commit URLs  
**File:** `cliff.toml`

## Claim
I'll take this — prefixing the git-cliff commit-hash href with `https://github.com/Synapse-bridgez/synapse-core/commit/`.

## Change
In the `body` template, replace:

```
([`{{ commit.id | truncate(length=7, end="") }}`]({{ commit.id }}))
```

with:

```
([`{{ commit.id | truncate(length=7, end="") }}`](https://github.com/Synapse-bridgez/synapse-core/commit/{{ commit.id }}))
```
