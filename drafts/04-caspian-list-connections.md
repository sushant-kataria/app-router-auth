# PR 4 — caspian-sdk: remove stale `list_connections()` docs

**Issue:** https://github.com/TryCaspian/caspian-sdk/issues/16  
**Status when drafted:** open, **unassigned, 0 comments, no competing PR**  
**File:** `sdks/python/src/caspian_sdk/client.py`  
**Do this after PR 3** (same fork/repo).

## Claim comment

```text
Happy to take this next — I'll update the `start_whatsapp_onboarding` docstring to drop the non-existent `list_connections()` reference and point at `get_connection()` / the connection.active event only.
```

## Exact diff

In `sdks/python/src/caspian_sdk/client.py`, docstring of `start_whatsapp_onboarding` (~lines 311–313):

**Before:**
```python
        Omit customer_id/agent_id to onboard onto this project's default scope, or
        pass both to target a specific customer+agent. Poll list_connections() /
        get_connection() (or watch for a connection.active event) until it's active.
```

**After:**
```python
        Omit customer_id/agent_id to onboard onto this project's default scope, or
        pass both to target a specific customer+agent. Poll get_connection()
        (or watch for a connection.active event) until it's active.
```

Also search the repo for any other `list_connections` docs references:

```bash
rg "list_connections" -n
```

Only change documentation mentions unless maintainers ask for a new API.

## Commit / PR

```bash
git checkout main
git pull upstream main   # if you added upstream
git checkout -b docs/fix-list-connections-docstring
# edit file...
git add sdks/python/src/caspian_sdk/client.py
git commit -m "docs: remove stale list_connections reference from onboarding docstring"
git push -u origin docs/fix-list-connections-docstring
```

### PR title
```
docs: remove stale list_connections reference from onboarding docstring
```

### PR body
```markdown
## Summary
The `start_whatsapp_onboarding` docstring told callers to poll `list_connections()`, but that method is not part of the public Python SDK.

Updated the guidance to `get_connection()` and/or the `connection.active` event.

Fixes #16

## Test plan
- [ ] `rg list_connections` shows no remaining public-doc references (or only intentional historical ones)
- [ ] No API surface added
```
