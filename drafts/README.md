# Draft PR pack

## Status
- Merged external: **12 / 100** (12%)
- Closest: [E-vara#237](https://github.com/SHAURYASANYAL3/E-vara/pull/237) **APPROVED**

## Batch 11 — ready (startups only; no avenx / no bigcos)

| # | Startup | Target | Notes |
|---|---------|--------|-------|
| 40 | Umami | [#4398](https://github.com/umami-software/umami/issues/4398) | Header label Edit matches empty copy |
| 41 | Synapse | [#1002](https://github.com/Synapse-bridgez/synapse-core/issues/1002) | Close paren in `tx search` summary |
| 42 | Open Source Kigali | [#253](https://github.com/Open-Source-Kigali/osk-frontend/issues/253) | Suspense → `<Loader />` |
| 43 | Open Source Kigali | [#254](https://github.com/Open-Source-Kigali/osk-frontend/issues/254) | Dynamic hamburger aria-label |
| 44 | Midday | [#785](https://github.com/midday-ai/midday/issues/785) | README AGPL wording |

```bash
bash scripts/verify-batch11.sh   # apply + test patches first
bash scripts/submit-batch11-prs.sh
```

**Verified:** umami patch asserts; synapse format + `rustc` snippet; osk `eslint` + production `build`; midday README vs `LICENSE`.

## Active open

| PR | Status |
|----|--------|
| [E-vara#237](https://github.com/SHAURYASANYAL3/E-vara/pull/237) | **APPROVED** |
| [Vault#32050](https://github.com/hashicorp/vault/pull/32050) | Open — CLA ✅ |
| [azurerm#32879](https://github.com/hashicorp/terraform-provider-azurerm/pull/32879) | Open |
| [synapse-core#1040](https://github.com/Synapse-bridgez/synapse-core/pull/1040) | Open |
| [synapse-core#1041](https://github.com/Synapse-bridgez/synapse-core/pull/1041) | Open |
| [triageiq#24](https://github.com/SakethSumanBathini/triageiq/pull/24)–[#27](https://github.com/SakethSumanBathini/triageiq/pull/27) | Open |
| [sanjeevani-core-backend#17](https://github.com/Sanjeevaniai-in/sanjeevani-core-backend/pull/17) | Open |
| [sanjeevani-mobile-apps#10](https://github.com/Sanjeevaniai-in/sanjeevani-mobile-apps/pull/10) | Open |
| [sanjeevani-landing-page#7](https://github.com/Sanjeevaniai-in/sanjeevani-landing-page/pull/7) | Open |
| [TSIA2Math#33](https://github.com/jd-oviedo/TSIA2Math/pull/33) | Open |

After merges: `npm run count-prs` / `npm run progress`
