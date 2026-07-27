# PR 30 — Microsoft PowerToys: fix ProviderContext contamination (P0)

**Company:** Microsoft  
**Issue:** https://github.com/microsoft/PowerToys/issues/46401  
**Impact (profound):** Commands opened from Command Palette while Dock is pinned can resolve the **wrong extension provider context** (e.g. Dad Jokes runs as All Apps). Breaks extension identity, settings, and host services — Priority-0.  
**File:** `src/modules/cmdpal/Microsoft.CmdPal.UI/PowerToysAppHostService.cs` (+ callers that pass `currentContext`)

## Why this counts
Wrong provider context can route extension commands through another extension’s host — silent functional corruption of CmdPal + Dock.

## Claim
I'll take this P0 — fixing `GetProviderContextForCommand` so Dock-pinned providers are not contaminated by the palette’s current page context (`All Apps` → Dad Jokes repro).

## Approach
1. Reproduce: pin extension to Dock → hotkey palette → All Apps → invoke Dock extension command → observe `currentContext` winning over the command’s provider.
2. Today:
   ```csharp
   return topLevelId ?? currentContext ?? throw ...;
   ```
   Nested commands are often **not** `TopLevelViewModel`, so `currentContext` (All Apps) leaks in.
3. Fix direction: resolve context from the **command’s owning provider / ListItem ancestry**, not the navigated page’s context when they differ; add a regression test around Dock vs palette contexts.
4. CLA: Microsoft CLA required on first PR.

## Competing PRs
None open when drafted.
