# PR 33 — Elastic Kibana: Anomaly Explorer empty for jobs with no influencers

**Company:** Elastic  
**Issue:** https://github.com/elastic/kibana/issues/262561  
**Impact (profound):** Regression vs 7.17 — “View in Anomaly Explorer” from time-series charts lands on **No results found** for ML jobs that legitimately have **zero influencers**, even when anomaly points exist. Hides swimlane + anomaly table for a common job configuration.  
**Files (starting points):**
- `x-pack/platform/plugins/shared/ml/public/ui_actions/open_in_anomaly_explorer_action.tsx` (sets `filterActive: true` + `influencersFilterQuery`)
- `x-pack/platform/plugins/shared/ml/public/application/explorer/explorer.tsx` (early `ExplorerNoResultsFound` branch)
- `…/anomaly_explorer_common_state.ts`

## Claim
I'll take this — when selected ML jobs have no influencers configured, don’t apply influencer URL filters that force an empty explorer; show swimlane/table when anomaly data exists.

## Approach
1. Repro: job with no influencers → single metric viewer → “View in Anomaly Explorer” → empty state on 9.3.x.
2. Redirect currently stamps `filterActive: true` + `influencersFilterQuery` into explorer URL state. For zero-influencer jobs that filter yields no swimlane points → `!hasResultsWithAnomalies` → `ExplorerNoResultsFound`.
3. Fix options (prefer smallest):
   - In open-in-explorer action: if job `influencers.length === 0`, omit `influencersFilterQuery` / set `filterActive: false`.
   - Or in explorer state hydrate: drop influencer filters when none of the selected jobs declare influencers.
4. Keep true empty state when there is genuinely no anomaly data.
5. Add unit/Jest coverage for zero-influencer redirect.

## Competing PRs
None open when drafted. Elastic CLA required.
