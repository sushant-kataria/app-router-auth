# PR 27 — triageiq: Clear button on email input form

**Issue:** https://github.com/SakethSumanBathini/triageiq/issues/14  
**Impact:** Users can reset the form without deleting each field by hand  
**File:** `frontend/src/components/EmailInput/LandingPage.tsx`

## Claim
`.take` — adding a Clear button that resets subject/body/sender/sender_name on the active email and disables when those fields are already empty.

## Change
- `clearActiveEmail()` sets the active `EmailInput` back to `emptyEmail()`
- Disable when active subject, body, sender, and sender_name are all empty
- Place Clear beside the Analyze submit button (`btn-secondary`)
