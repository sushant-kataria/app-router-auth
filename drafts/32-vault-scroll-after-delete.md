# PR 32 — HashiCorp Vault: list scroll dies after delete (UI)

**Company:** HashiCorp  
**Issue:** https://github.com/hashicorp/vault/issues/31852  
**Impact (profound):** After deleting an item in any long scrollable list (KV secrets, policies, auth methods), **scrolling is completely disabled** (scrollbar gone, wheel/trackpad dead) until full page reload. Operators cannot continue managing secrets/policies without refreshing — breaks day-to-day Vault UI workflows.  
**Area:** Vault Ember UI list / overflow containers (ui package)

## Claim
I'll take this — restoring scroll-container overflow/state after list mutations so delete doesn’t leave KV/policies/auth lists stuck until reload.

## Approach
1. Reproduce on Vault OSS ≥1.21: long KV/policies/auth list → delete one row → confirm overflow locked.
2. Likely cause: list re-render after mutation leaves the scroll parent with `overflow: hidden` / height 0 / sticky body lock (similar class of bugs fixed in namespace picker refresh PRs `#30737` / `#30947`).
3. Fix: ensure list component remeasures after `delete` success (reset scroll parent style, `didUpdate` height, or replace tracked array so overflow recalculates). Mirror patterns from recent namespace-picker refresh fixes.
4. Add UI acceptance: delete in scrolled list → wheel still scrolls.

## Competing PRs
None open when drafted. HashiCorp CLA required.
