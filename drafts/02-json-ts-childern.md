# PR 2 — json.ts: fix `childern` typo

**Issue:** https://github.com/abatef/json.ts/issues/11  
**Status when drafted:** open, **0 comments, no competing PR** (issue #9’s PR is unrelated)  
**File:** `src/main.ts` line 36  
**Change:** `childern` → `children`

## Claim comment (post on the issue first)

```text
Hi! I'd like to take this — fixing `childern` → `children` in `src/main.ts`.
```

## Commands

```bash
# Fork https://github.com/abatef/json.ts then:
git clone https://github.com/sushant-kataria/json.ts.git
cd json.ts
git checkout -b fix/typo-children-key

# Apply the one-line fix (see below), then:
git add src/main.ts
git commit -m "fix: correct childern typo in test JSON key"
git push -u origin fix/typo-children-key
```

## Exact diff

In `src/main.ts`, function `testNonPrettyJson`:

**Before:**
```ts
  const json = `{"name": "Max", "age": 22, "married": true, "wife": "Vivian", "childern": ["Luke", "Emma", "Ellie"]}`;
```

**After:**
```ts
  const json = `{"name": "Max", "age": 22, "married": true, "wife": "Vivian", "children": ["Luke", "Emma", "Ellie"]}`;
```

## PR title

```
fix: correct childern typo in test JSON key
```

## PR body

```markdown
## Summary
Fixes a typo in the sample JSON used by `testNonPrettyJson`.

`childern` → `children`

Fixes #11

## Test plan
- [ ] Confirmed only `src/main.ts` changed
- [ ] Ran the existing main/test script if available
```

Compare URL pattern:  
`https://github.com/abatef/json.ts/compare/main...sushant-kataria:json.ts:fix/typo-children-key`
