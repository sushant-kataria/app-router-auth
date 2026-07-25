# PR 18 — c-text-editor: growable prompt buffer

**Issue:** https://github.com/andrewthecodertx/c-text-editor/issues/3  
**Impact:** Critical UX/correctness — long Save-as paths and search queries no longer truncate at 128 bytes  
**File:** `ui.c` (`editor_prompt`)

**Status when drafted:** open, unassigned, labeled `priority: critical`

## Claim

```text
I'll take this — replacing the fixed 128-byte prompt buffer in `editor_prompt` with a heap buffer that doubles on growth, freeing on cancel/error and returning the buffer on success (caller still frees).
```

## Change summary

- `#include <stdlib.h>`
- Start at capacity 256, `realloc` ×2 when `buflen + 1 >= capacity`
- `free(buffer)` on ESC / Ctrl+C / empty Enter / OOM
- On successful Enter, return the buffer pointer directly (same caller-free contract as old `strdup`)
