# Draft PR pack — do these in order

Your GitHub: **sushant-kataria** · Display name: **Sushant Kataria**

## Fastest path (recommended)

From your own machine (must be logged in as you):

```bash
gh auth login          # choose GitHub.com → sushant-kataria
git clone https://github.com/sushant-kataria/app-router-auth.git
cd app-router-auth
git checkout cursor/oss-grant-path-ba5d   # or main after merge
bash scripts/submit-first-prs.sh
```

That script claims the issues, forks, commits, and opens all 4 PRs under **your** account (required for Anthropic’s `author:sushant-kataria` count).

| # | Repo | Issue | Status | Why |
|---|------|-------|--------|-----|
| 1 | [firstcontributions/first-contributions](https://github.com/firstcontributions/first-contributions) | (no issue — add your name) | Ready | Learns fork→PR workflow; almost always merges |
| 2 | [abatef/json.ts#11](https://github.com/abatef/json.ts/issues/11) | Typo `childern`→`children` | **Unclaimed, 0 PRs** | Tiny real code/docs-adjacent fix |
| 3 | [TryCaspian/caspian-sdk#11](https://github.com/TryCaspian/caspian-sdk/issues/11) | Stale test counts in READMEs | **Unclaimed, 0 PRs** | Real docs PR on an active SDK |
| 4 (next) | [TryCaspian/caspian-sdk#16](https://github.com/TryCaspian/caspian-sdk/issues/16) | Stale `list_connections()` docs | **Unclaimed, 0 PRs** | Follow-up after #11 |

Manual step-by-step versions of each PR are in the files below if you prefer not to use the script.

After each merge, run from Grantpath:

```bash
npm run count-prs
```
