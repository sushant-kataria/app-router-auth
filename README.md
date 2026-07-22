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

Ready-to-submit drafts live in [`drafts/`](./drafts/README.md):

1. First Contributions (warmup)
2. `abatef/json.ts#11` — `childern` → `children`
3. `TryCaspian/caspian-sdk#11` — stale test counts
4. `TryCaspian/caspian-sdk#16` — remove stale `list_connections()` docs

## Daily loop

1. Finish the drafted PRs above, then pick more from [`data/targets.json`](./data/targets.json) (or [goodfirstissue.dev](https://goodfirstissue.dev/) / [up-for-grabs.net](https://up-for-grabs.net/)).
2. Filter issues: labeled, recently touched, not already claimed, maintainer active.
3. Comment “I’d like to take this” → wait for a nod when the project expects it.
4. Ship a **small** PR (docs/typo/test/bugfix). One concern per PR.
5. Respond to review the same day when you can.
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
