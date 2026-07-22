# PR 1 — First Contributions (warmup)

**Goal:** land your first merged PR and learn the GitHub flow.  
**Repo:** https://github.com/firstcontributions/first-contributions  
**Change:** add your name to `Contributors.md`

## Exact steps

```bash
# 1) Fork on GitHub UI: https://github.com/firstcontributions/first-contributions/fork

# 2) Clone YOUR fork
git clone https://github.com/sushant-kataria/first-contributions.git
cd first-contributions

# 3) Branch
git checkout -b add-sushant-kataria

# 4) Edit Contributors.md — add this line at the END of the file:
# - [Sushant Kataria](https://github.com/sushant-kataria)

# 5) Commit + push
git add Contributors.md
git commit -m "Add Sushant Kataria to Contributors list"
git push -u origin add-sushant-kataria
```

## PR title

```
Add Sushant Kataria to Contributors list
```

## PR body

```markdown
## What
Adds my name to `Contributors.md` as my first open-source contribution.

## Checklist
- [x] Added `- [Sushant Kataria](https://github.com/sushant-kataria)` at the end of `Contributors.md`
```

Then open:  
https://github.com/firstcontributions/first-contributions/compare/main...sushant-kataria:first-contributions:add-sushant-kataria

## After merge
This counts toward Anthropic’s external-PR total (repo you don’t own). Then immediately start **PR 2**.
