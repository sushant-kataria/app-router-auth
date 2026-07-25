# Draft PR pack

Your GitHub: **sushant-kataria**

## Bot reviews (FAQ)

**No — not “your” bot on every PR.**  
CodeRabbit (and similar) only runs on repos where **that project’s maintainers** installed it.  
- On [cloche#26](https://github.com/escoffier-labs/cloche/pull/26) you saw **their** CodeRabbit.  
- It does **not** auto-review every PR you open elsewhere unless that repo has the app.  
- On your own repos, a bot reviews only if **you** install/configure it.

## Status

| | |
|--|--|
| Merged external | **1** |
| Open (batch 1–2) | json.ts#17 · cloche#26 · avenx-js#625 |
| Next batch | run script below |

## Open next batch (3 PRs)

```bash
cd app-router-auth
git fetch origin && git checkout cursor/oss-grant-path-ba5d && git pull
bash scripts/submit-batch3-prs.sh
```

| # | Issue | Draft |
|---|-------|-------|
| 7 | [osk-frontend#277](https://github.com/Open-Source-Kigali/osk-frontend/issues/277) alt typo | [`07-osk-footer-alt.md`](./07-osk-footer-alt.md) |
| 8 | [sharibo#55](https://github.com/crackedstudio/sharibo/issues/55) rename Sharabo→Sharibo | [`08-sharibo-rename.md`](./08-sharibo-rename.md) |
| 9 | [sharibo#6](https://github.com/crackedstudio/sharibo/issues/6) broken demo.gif | [`09-sharibo-broken-gif.md`](./09-sharibo-broken-gif.md) |

Skipped: eventradar#36 (already fixed in code), Nevo#970 (competing PR), caspian (closed).

After merges: `npm run count-prs`
