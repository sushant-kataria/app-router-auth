# PR 28 — triageiq: friendly dashboard empty state

**Issue:** https://github.com/SakethSumanBathini/triageiq/issues/15  
**Impact:** Empty triage results no longer look like a broken dashboard  
**File:** `frontend/src/components/Dashboard/Dashboard.tsx`

## Claim
`.take` — rendering a lucide empty-state (icon + heading + subtitle + New Analysis CTA) when `results.results` is empty.

## Change
When `results.results.length === 0`, skip KPI/queue chrome and show:

- `Inbox` (lucide-react) icon
- Heading: “No emails triaged yet”
- Subtitle prompting the user to triage their first email
- Button calling `onReset` (“Triage your first email”)

Keep the existing “No emails match current filters” copy for non-empty results that filter to zero.
