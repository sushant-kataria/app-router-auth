# Portfolio polish pack

Presentable READMEs + light finish patches for **owned** (non-fork) GitHub repos.

Cloud agents cannot push to these repos — run the apply script **locally** as `sushant-kataria`.

## What this does

1. Sets clear GitHub repo **descriptions**
2. Replaces boilerplate / empty **READMEs**
3. Adds missing **`.env.example`** / `.gitignore` where needed
4. Replaces default Next.js **home pages** on the Ory demos
5. **Finishes hushvoice** by publishing draft PR #1 (full app currently only on that branch)
6. Renames `sweep-app` package from `my-gemini-chat` → `sweep-app`

## Run

```bash
cd /c/grantpath-work/app-router-auth   # or your Grantpath clone
git pull
gh auth login                          # must be sushant-kataria
bash scripts/polish-owned-repos.sh
```

Optional flags:

```bash
SKIP_HUSHVOICE_MERGE=1 bash scripts/polish-owned-repos.sh   # README-only; don't merge hushvoice PR
DRY_RUN=1 bash scripts/polish-owned-repos.sh                # print actions only
