# PR 26 — Nevo: add root `.editorconfig`

**Issue:** https://github.com/Web3Novalabs/Nevo/issues/971  
**Impact:** Editors get consistent charset/EOL/indent across frontend, server (TS), and contract (Rust)  
**File:** `.editorconfig` (new, repo root)

## Claim
I'll take this — adding a root `.editorconfig` aligned with Prettier (2-space TS/JS) and rustfmt-style 4-space Rust.

## Change
Add root `.editorconfig`:

- `[*]`: utf-8, LF, final newline, trim trailing whitespace
- `*.{js,jsx,ts,tsx,…}`: spaces, indent 2 (matches frontend Prettier `tabWidth: 2`)
- `*.{rs,toml}`: spaces, indent 4
- `*.md`: keep trailing whitespace (common markdown exception)
