# Portfolio polish pack

Presentable READMEs + light finish patches for **owned** (non-fork) GitHub repos.

## Status (applied 2026-07-26)

| Item | Result |
|------|--------|
| Repo descriptions | Updated on priority repos |
| **hushvoice** | Draft [PR #1](https://github.com/sushant-kataria/hushvoice/pull/1) **merged** — studio app is on `main` |
| Polish PRs | Open on owned repos (merge when ready) |

### Open polish PRs to merge

```bash
# Bulk-merge your own polish PRs (optional)
for repo in sweep-app squarepg-app pg-analytics-dashboard auth-verify \
  ory-auth-app ory-login-sample-app terraformAKS docker-app jenkins \
  terraform-azure-infra azuredevops-cicd-del; do
  gh pr merge --repo "sushant-kataria/$repo" --head cursor/portfolio-polish-ba5d --merge 2>/dev/null \
    || gh pr list --repo "sushant-kataria/$repo" --head cursor/portfolio-polish-ba5d --state open
done
```

| Repo | PR |
|------|-----|
| sweep-app | [#45](https://github.com/sushant-kataria/sweep-app/pull/45) |
| squarepg-app | [#1](https://github.com/sushant-kataria/squarepg-app/pull/1) |
| pg-analytics-dashboard | [#1](https://github.com/sushant-kataria/pg-analytics-dashboard/pull/1) |
| auth-verify | [#1](https://github.com/sushant-kataria/auth-verify/pull/1) |
| ory-auth-app | [#1](https://github.com/sushant-kataria/ory-auth-app/pull/1) |
| ory-login-sample-app | [#2](https://github.com/sushant-kataria/ory-login-sample-app/pull/2) |
| terraformAKS | [#2](https://github.com/sushant-kataria/terraformAKS/pull/2) |
| docker-app | [#1](https://github.com/sushant-kataria/docker-app/pull/1) |
| jenkins | [#1](https://github.com/sushant-kataria/jenkins/pull/1) |
| terraform-azure-infra | [#1](https://github.com/sushant-kataria/terraform-azure-infra/pull/1) |
| azuredevops-cicd-del | [#1](https://github.com/sushant-kataria/azuredevops-cicd-del/pull/1) |

## Re-run

```bash
gh auth login                          # must be sushant-kataria
bash scripts/polish-owned-repos.sh
```

Optional:

```bash
SKIP_HUSHVOICE_MERGE=1 bash scripts/polish-owned-repos.sh
DRY_RUN=1 bash scripts/polish-owned-repos.sh
```
