# PR 37 — avenx-js: document `data-ax-class` in templates guide

**Issue:** https://github.com/Avenx-JS/avenx-js/issues/647  
**Impact:** Docs — developers can discover string + object class bindings  
**File:** `docs/src/content/docs/core-concepts/templates.md`

## Claim
I'll take this — adding a `data-ax-class` section (string + object formats) next to the existing `data-ax-style` docs.

## Change
Document:
- String form: `data-ax-class="state.activeClass"` (space-separated class names from the expression)
- Object form: `data-ax-class="{ active: state.isActive, 'text-large': state.isLarge }"` (truthy keys applied)
- Note that static `class="…"` attributes are preserved alongside dynamic classes

## Competing PRs
None open when drafted.
