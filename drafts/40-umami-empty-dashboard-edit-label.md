# PR 40 — umami: empty dashboard says “Edit” but button is “Design”

**Startup:** Umami  
**Issue:** https://github.com/umami-software/umami/issues/4398  
**File:** `src/app/(main)/dashboard/DashboardViewHeader.tsx`

## Claim
I'll take this — the empty-state copy tells users to click **Edit**, but the header button is hardcoded **Design**. Align the button label with `t(labels.edit)`.

## Change
In `DashboardViewHeader`, replace hardcoded `Design` with `{t(labels.edit)}` so it matches `message.empty-dashboard` across locales.

## Verify
- Confirm empty copy references Edit (`empty-dashboard` in `en-US.json`)
- Confirm header previously said `Design`
- Run `Empty` unit tests / typecheck if available

## Competing PRs
None open when drafted.
