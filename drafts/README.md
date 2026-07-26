# Draft PR pack

## Status
- Merged external: **7 / 100** (7%) — sharibo×2 + Nevo merged
- Batch 6: Nevo merged; c-text-editor#22 + nl6#345 still open; Linkora skipped
- Portfolio polish applied; hushvoice PR #1 merged; owned-repo polish PRs open (merge when ready)


## Batch 7 — run locally (higher-signal)

```bash
cd /c/grantpath-work/app-router-auth
git fetch origin && git checkout cursor/oss-grant-path-ba5d && git pull
bash scripts/submit-batch7-prs.sh
```

| # | Issue | Why | Draft |
|---|-------|-----|-------|
| 20 | [synapse-core#1012](https://github.com/Synapse-bridgez/synapse-core/issues/1012) | Dev seed always no-ops (`${DATABASE_URL}` literal) | [`20-synapse-seed-database-url.md`](./20-synapse-seed-database-url.md) |
| 21 | [c-text-editor#8](https://github.com/andrewthecodertx/c-text-editor/issues/8) + [#17](https://github.com/andrewthecodertx/c-text-editor/issues/17) | Undo memory leak + empty `editor_actions` | [`21-ctext-undo-leak.md`](./21-ctext-undo-leak.md) |
| 22 | [triageiq#22](https://github.com/SakethSumanBathini/triageiq/issues/22) | CORS still `*` despite `CORS_ORIGINS` | [`22-triageiq-cors-origins.md`](./22-triageiq-cors-origins.md) |
| 23 | [osk-frontend#279](https://github.com/Open-Source-Kigali/osk-frontend/issues/279) | Broken Footer `/events` + dead Blog link | [`23-osk-footer-routes.md`](./23-osk-footer-routes.md) |
| 24 | [nl6#343](https://github.com/labmonkeys-space/nl6/issues/343) | Silent `gh attestation verify` in release docs | [`24-nl6-attestation-docs.md`](./24-nl6-attestation-docs.md) |

**Skip:** Synapse#1002 (claim comments), osk#278 (PR already open).

## Batch 6 — submitted

| # | Issue → PR | Status |
|---|------------|--------|
| 16 | Linkora-social#941 | **Skipped** — assigned to @morelucks; issue closed |
| 17 | [Nevo#988](https://github.com/Web3Novalabs/Nevo/pull/988) | Open — remove mock donor counts |
| 18 | [c-text-editor#22](https://github.com/andrewthecodertx/c-text-editor/pull/22) | Open — growable prompt buffer |
| 19 | [nl6#345](https://github.com/labmonkeys-space/nl6/pull/345) | Open — Debian copyright in `.deb` |

Submitted locally via flat runner (Windows: original `submit-batch6-prs.sh` hit `gh clone` path + CRLF match issues; script hardened afterward for next batches).

## Still open from earlier batches

| PR | Notes |
|----|-------|
| [E-vara#237](https://github.com/SHAURYASANYAL3/E-vara/pull/237) | **APPROVED** — waiting on merge |
| [osk-frontend#290](https://github.com/Open-Source-Kigali/osk-frontend/pull/290) | Open |
| [sharibo#127](https://github.com/crackedstudio/sharibo/pull/127) / [#128](https://github.com/crackedstudio/sharibo/pull/128) | Open |
| [TSIA2Math#33](https://github.com/jd-oviedo/TSIA2Math/pull/33) | Open |
| [triageiq#24](https://github.com/SakethSumanBathini/triageiq/pull/24) | Open |
| [sanjeevani-landing#7](https://github.com/Sanjeevaniai-in/sanjeevani-landing-page/pull/7) | Open |
| [sanjeevani-mobile#10](https://github.com/Sanjeevaniai-in/sanjeevani-mobile-apps/pull/10) | Open |
| [sanjeevani-core-backend#17](https://github.com/Sanjeevaniai-in/sanjeevani-core-backend/pull/17) | Open |

After merges: `npm run count-prs` / `npm run progress`

## Portfolio polish (owned repos)

Presentable READMEs + finish unfinished owned projects (hushvoice stub, boilerplate Next homes, etc.):

```bash
bash scripts/polish-owned-repos.sh
```

See [`portfolio-polish/README.md`](../portfolio-polish/README.md).
