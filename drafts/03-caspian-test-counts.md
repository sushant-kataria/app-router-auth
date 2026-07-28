# PR 3 — caspian-sdk: update stale test counts

**Issue:** https://github.com/TryCaspian/caspian-sdk/issues/11  
**Status when drafted:** open, **unassigned, 0 comments, no competing PR**  
**Files:** `README.md`, `README.zh-CN.md`

## Claim comment (post on the issue first)

```text
I'd like to work on this. I'll update the English and Chinese READMEs to 70 Python / 15 TypeScript (85 total) and verify against the test suites.
```

Wait for a maintainer nod if they reply quickly; if silent after a bit, still open the PR and link the issue.

## Commands

```bash
git clone https://github.com/sushant-kataria/caspian-sdk.git   # after forking
cd caspian-sdk
git checkout -b docs/update-test-counts
```

## Exact edits

### `README.md`

1. Line ~191 — combined count:

**Before:** `Fakes consume each platform's *real* payload shapes — 80 tests across Python + TS, zero network.`  
**After:** `Fakes consume each platform's *real* payload shapes — 85 tests across Python + TS, zero network.`

2. Line ~346 — TypeScript count (Python line already says 70):

**Before:** `cd sdks/typescript && npm ci && npm test   # 10 vitest tests`  
**After:** `cd sdks/typescript && npm ci && npm test   # 15 vitest tests`

### `README.zh-CN.md`

1. Line ~183:

**Before:** `fake 消费各平台*真实*的入站消息格式——Python + TS 共 80 个测试，零网络请求。`  
**After:** `fake 消费各平台*真实*的入站消息格式——Python + TS 共 85 个测试，零网络请求。`

2. Line ~339:

**Before:** `cd sdks/typescript && npm ci && npm test   # 10 个 vitest 测试`  
**After:** `cd sdks/typescript && npm ci && npm test   # 15 个 vitest 测试`

## Verify counts (from repo root)

```bash
uv run pytest --collect-only -q    # expect 70
cd sdks/typescript && npm ci && npx vitest run --reporter=dot
# or: npm test  — expect 15
```

If counts differ from 70/15 when you run them, **use the numbers you actually observe** and note that in the PR.

## Commit

```bash
git add README.md README.zh-CN.md
git commit -m "docs: update stale Python/TS test counts in READMEs"
git push -u origin docs/update-test-counts
```

## PR title

```
docs: update stale Python/TS test counts in READMEs
```

## PR body

```markdown
## Summary
Updates documented offline test counts to match the current suites:
- Python: 70
- TypeScript (Vitest): 15
- Combined: 85

Touched both `README.md` and `README.zh-CN.md`.

Fixes #11

## Test plan
- [ ] `uv run pytest --collect-only -q` → 70
- [ ] `cd sdks/typescript && npm test` → 15
- [ ] No test code changed
```

## After this merges
Immediately claim **#16** (`drafts/04-caspian-list-connections.md`) for a second PR in the same repo (builds maintainer familiarity → faster reviews).
