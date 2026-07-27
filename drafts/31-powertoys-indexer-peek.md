# PR 31 — Microsoft PowerToys: Indexer “Open in Peek” does nothing

**Company:** Microsoft  
**Issue:** https://github.com/microsoft/PowerToys/issues/49183  
**Impact (profound):** File Search (Indexer) → Peek is a core discovery→preview path. Today the palette dismisses and **Peek never appears**, so users cannot preview files from CmdPal search.  
**File:** `src/modules/cmdpal/ext/Microsoft.CmdPal.Ext.Indexer/Commands/PeekFileCommand.cs`

## Claim
I'll take this — launching Peek.UI with the correct working directory / activation so Indexer Peek actually shows the file (palette currently dismisses with no window).

## Root cause (investigation)
`Peek.UI` is normally started from the Peek module with CWD = PowerToys install root and relative `WinUI3Apps\PowerToys.Peek.UI.exe` (`dllmain.cpp` `launch_process`).  

`PeekFileCommand` starts the absolute exe with `UseShellExecute = false` and **no WorkingDirectory**. WinUI3 apps commonly fail to activate when dependencies are resolved from the wrong CWD — matching “palette closes, Peek nowhere”.

`App.xaml.cs` already supports CLI file paths via `SelectedItemByPath` when the last arg is a valid path.

## Proposed fix
In `PeekFileCommand.Invoke()`:
- Set `WorkingDirectory` to `Path.GetDirectoryName(peekExe)` (the `WinUI3Apps` folder) **or** the PowerToys install root (match module launcher).
- Prefer `UseShellExecute = true` (align with `ShellExecuteEx` in Peek module) **or** keep `false` but set CWD + `PATH` carefully.
- Keep args as the file path; verify `File.Exists(_fullPath)` before launch and toast on failure.
- Consider `CommandResult.KeepOpen` vs `Dismiss` only if focus still races after launch is fixed.

## Competing PRs
None open when drafted. CLA required.
