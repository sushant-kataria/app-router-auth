# Draft PR pack

## Status
- Merged external: **2 / 100**
- Several open from batches 1–5 (mostly docs)

## Batch 6 — higher-impact (run locally)

These are **code/packaging** fixes, not typo docs. Prefer merging these for stronger contribution signal.

```bash
cd /c/grantpath-work/app-router-auth
git fetch origin && git checkout cursor/oss-grant-path-ba5d && git pull
bash scripts/submit-batch6-prs.sh
```

| # | Issue | Why it matters | Draft |
|---|-------|----------------|-------|
| 16 | [Linkora-social#941](https://github.com/Epta-Node/Linkora-social/issues/941) | Smart-contract username min-length + wire orphaned tests | [`16-linkora-username-min-length.md`](./16-linkora-username-min-length.md) |
| 17 | [Nevo#860](https://github.com/Web3Novalabs/Nevo/issues/860) | Remove fake donor counts from production UI | [`17-nevo-poolcard-donor-count.md`](./17-nevo-poolcard-donor-count.md) |
| 18 | [c-text-editor#3](https://github.com/andrewthecodertx/c-text-editor/issues/3) | Critical: growable prompt buffer (was truncating at 128) | [`18-ctext-growable-prompt.md`](./18-ctext-growable-prompt.md) |
| 19 | [nl6#342](https://github.com/labmonkeys-space/nl6/issues/342) | Debian Policy copyright file + SBOM license fix | [`19-nl6-deb-copyright.md`](./19-nl6-deb-copyright.md) |

**Note:** Linkora#941 has Stellar Wave applicants but was unassigned with no PR when drafted. The script skips if someone else gets assigned first.

## Batch 5 (already submitted if you ran it)

| # | Issue | Draft |
|---|-------|-------|
| 13 | [E-vara#184](https://github.com/SHAURYASANYAL3/E-vara/issues/184) | [`13-evara-readme-setup.md`](./13-evara-readme-setup.md) |
| 14 | [sanjeevani-mobile-apps#2](https://github.com/Sanjeevaniai-in/sanjeevani-mobile-apps/issues/2) | [`14-sanjeevani-mobile-docs.md`](./14-sanjeevani-mobile-docs.md) |
| 15 | [sanjeevani-core-backend#2](https://github.com/Sanjeevaniai-in/sanjeevani-core-backend/issues/2) | [`15-sanjeevani-backend-contributing.md`](./15-sanjeevani-backend-contributing.md) |

After merges: `npm run count-prs`
