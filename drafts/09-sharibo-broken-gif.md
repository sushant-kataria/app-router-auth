# PR 9 — sharibo: fix broken demo GIF reference

**Issue:** https://github.com/crackedstudio/sharibo/issues/6  
**Status when drafted:** open, unassigned, **no competing PR**  
**File:** `README.md`

## Claim comment

```text
I'll take this — removing/replacing the broken `docs/demo.gif` README image so the docs don't 404.
```

## Exact approach

`README.md` currently has:

```markdown
![Sharibo demo — live proof generation and anonymous claim](docs/demo.gif)
```

but `docs/demo.gif` does not exist.

**Preferred fix (no new binary asset):** remove that image line (keep the placeholder HTML comment above it if useful), and rely on the existing live app / demo video links on the next line.

Do **not** invent a fake GIF. If maintainers prefer adding a real asset later, that can be a follow-up.
