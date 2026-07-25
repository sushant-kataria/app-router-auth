# Draft PR pack

## Status
- Merged external: **2 / 100**
- Open: watch list from batches 1–3
- Cloche: merged (credit kept after maintainer relicense)

## Batch 4 — run locally

```bash
cd /c/grantpath-work/app-router-auth   # or your clone path
git fetch origin && git checkout cursor/oss-grant-path-ba5d && git pull
bash scripts/submit-batch4-prs.sh
```

| # | Issue | Draft |
|---|-------|-------|
| 10 | [TSIA2Math#14](https://github.com/jd-oviedo/TSIA2Math/issues/14) `\fract`→`\frac` | [`10-tsia2math-fract.md`](./10-tsia2math-fract.md) |
| 11 | [triageiq#10](https://github.com/SakethSumanBathini/triageiq/issues/10) API table (claim with `.take`) | [`11-triageiq-api-table.md`](./11-triageiq-api-table.md) |
| 12 | [sanjeevani-landing-page#1](https://github.com/Sanjeevaniai-in/sanjeevani-landing-page/issues/1) clone docs | [`12-sanjeevani-clone-docs.md`](./12-sanjeevani-clone-docs.md) |

## Realistic time to 100 (rate math, not a promise)

You need **~98 more merged external PRs**. Time is mostly **merge latency**, not typing.

| Pace | What it means | Ballpark to ~100 |
|------|----------------|------------------|
| Casual | ~3–5 merges/week | on the order of **several months** |
| Steady | ~1–2 merges/day, 5–8 PRs always in flight | on the order of **1–2 months** |
| Aggressive | full-time grind, 10+ in flight, many tiny docs/typo PRs | possibly **a few weeks**, if maintainers merge quickly |

What speeds it up: small diffs, active repos, fast review replies, many PRs in parallel.  
What slows it up: abandoned issues, DCO/GPG repos, waiting on one PR at a time, spammy low-quality PRs (can get ignored).

Anthropic also accepts other tracks (downloads/dependents, 100 external PRs, etc.) — Active contributor is still your most controllable path from here.
