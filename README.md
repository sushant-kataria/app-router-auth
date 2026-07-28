# Grantpath

Fastest **legitimate** path to Anthropic’s **Claude for Open Source** (6 months Claude Max 20x) and OpenAI’s **Codex for Open Source** (6 months ChatGPT Pro + Codex) when you have **no prior OSS history**.

> Clearing a demo repo does not qualify you. These programs reward real contribution impact.

## The strategy (do this)

| Priority | Action | Why |
|----------|--------|-----|
| **1 — Speed path** | Land **100 merged PRs** in repos **you do not own** (last 12 months) | Official Anthropic **Active contributors** track |
| **2 — Parallel** | Maintain this public MIT project with a clear README + ongoing commits | Gives OpenAI a primary-maintainer story |
| **3 — Apply** | Anthropic at ~100 external merges; OpenAI once the maintainer story is real | Both programs accept rolling applications |

**Do not** chase: fake stars, download bots, or empty “critical infrastructure” claims. That burns the application.

## Official links

- Anthropic: [claude.com/open-source-max](https://claude.com/open-source-max)
- OpenAI: [openai.com/form/codex-for-oss](https://openai.com/form/codex-for-oss/)

### Anthropic tracks (summary)

1. Maintainer/library: 500+ dependent repos **or** 100+ dependent packages **or** 200k+ monthly downloads  
2. Core contributor on major foundation projects  
3. **Active contributor: 100+ merged PRs to repos you don’t own (12 months)** ← your main target  
4. Community builder: 20+ unique external contributors on one of your repos  
5. Critical infra: OpenSSF criticality ≥ 0.4  
6. Soft: apply anyway if the ecosystem quietly depends on your work  

## Start here (drafted PRs)

Ready-to-submit drafts live in [`drafts/`](./drafts/README.md).

Merged external: **12 / 100**.

**Batch 11 ready** (startups only — no avenx / no bigcos):

| # | Startup | Target |
|---|---------|--------|
| 40 | Umami | [#4398](https://github.com/umami-software/umami/issues/4398) empty-dashboard Edit label |
| 41 | Synapse | [#1002](https://github.com/Synapse-bridgez/synapse-core/issues/1002) tx search paren |
| 42 | Open Source Kigali | [#253](https://github.com/Open-Source-Kigali/osk-frontend/issues/253) Suspense Loader |
| 43 | Open Source Kigali | [#254](https://github.com/Open-Source-Kigali/osk-frontend/issues/254) hamburger aria-label |
| 44 | Midday | [#785](https://github.com/midday-ai/midday/issues/785) README AGPL wording |

```bash
bash scripts/verify-batch11.sh    # test patches first
bash scripts/submit-batch11-prs.sh
```

Active open + merged: [`drafts/README.md`](./drafts/README.md).

## Portfolio polish (owned repos)

Cloud agents cannot push to your other repos. To make owned projects presentable (READMEs, env examples, finish hushvoice stub):

```bash
gh auth login   # sushant-kataria
bash scripts/polish-owned-repos.sh
```

Details: [`portfolio-polish/README.md`](./portfolio-polish/README.md).

## Daily loop

1. Verify then submit Batch 11 (`bash scripts/verify-batch11.sh` → `bash scripts/submit-batch11-prs.sh`). Prefer startups; skip bigcos and skip piling on avenx.
2. Prefer **real bug/behavior fixes** over typo-only PRs when both are available.
3. Filter issues: labeled, recently touched, not already claimed, maintainer active. Claim first; follow PR templates; include repro/tests on larger repos.
4. Comment “I’d like to take this” → wait for a nod when the project expects it.
5. One concern per PR. Respond to review the same day when you can.
6. Log the merge in [`data/progress.json`](./data/progress.json).

## Commands

```bash
npm install
npm run dev          # local Grantpath site
npm run count-prs    # count merged external PRs (last 12 months)
npm run progress     # refresh data/progress.json from GitHub Search API
```

Optional: set `GITHUB_TOKEN` (or `GH_TOKEN`) for higher API rate limits.

```bash
GITHUB_TOKEN=ghp_... npm run count-prs
```

## Apply packets

- [`apply/anthropic-draft.md`](./apply/anthropic-draft.md)
- [`apply/openai-draft.md`](./apply/openai-draft.md)

Fill these only with **true** metrics from `npm run count-prs`.

## What “as soon as possible” really means

With no history, the bottleneck is **merged external PR volume**, not rewriting this repository. Treat contribution like a job: several small, mergeable PRs in flight across a few active repos. When `count-prs` shows ≥100, submit Anthropic immediately. Use this repo’s maintainer story for OpenAI once it is more than a blank template.

## License

MIT
