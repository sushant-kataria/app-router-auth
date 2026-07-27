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

**Batch 8 submitted** (5/5 — **avenx#655 merged same day**):

| # | PR | Status |
|---|-----|--------|
| 25 | [synapse-core#1041](https://github.com/Synapse-bridgez/synapse-core/pull/1041) | Open |
| 26 | [Nevo#1004](https://github.com/Web3Novalabs/Nevo/pull/1004) | Open |
| 27 | [triageiq#26](https://github.com/SakethSumanBathini/triageiq/pull/26) | Open |
| 28 | [triageiq#27](https://github.com/SakethSumanBathini/triageiq/pull/27) | Open |
| 29 | [avenx-js#655](https://github.com/Avenx-JS/avenx-js/pull/655) | **Merged** |

**Batch 7 submitted** (4/5 — nl6 skipped):

| # | PR | Status |
|---|-----|--------|
| 20 | [synapse-core#1040](https://github.com/Synapse-bridgez/synapse-core/pull/1040) | Open |
| 21 | [c-text-editor#25](https://github.com/andrewthecodertx/c-text-editor/pull/25) | Open |
| 22 | [triageiq#25](https://github.com/SakethSumanBathini/triageiq/pull/25) | Open |
| 23 | [osk-frontend#291](https://github.com/Open-Source-Kigali/osk-frontend/pull/291) | Open |
| 24 | nl6#343 | Skipped |

Merged external: **8 / 100**. Details: [`drafts/`](./drafts/README.md). Ask for Batch 9 when ready.

## Portfolio polish (owned repos)

Cloud agents cannot push to your other repos. To make owned projects presentable (READMEs, env examples, finish hushvoice stub):

```bash
gh auth login   # sushant-kataria
bash scripts/polish-owned-repos.sh
```

Details: [`portfolio-polish/README.md`](./portfolio-polish/README.md).

## Daily loop

1. Watch Batch 7–8 reviews; ask for Batch 9 when ready. Pick more from [`data/targets.json`](./data/targets.json) (or [goodfirstissue.dev](https://goodfirstissue.dev/) / [up-for-grabs.net](https://up-for-grabs.net/)).
2. Prefer **real bug/behavior fixes** over typo-only PRs when both are available.
3. Filter issues: labeled, recently touched, not already claimed, maintainer active.
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
