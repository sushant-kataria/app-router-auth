# PR 21 — c-text-editor: fix undo leak + implement editor_actions

**Issues:** https://github.com/andrewthecodertx/c-text-editor/issues/8 · https://github.com/andrewthecodertx/c-text-editor/issues/17  
**Impact:** High — frees discarded `ACTION_DELETE_LINE` buffers; raises undo depth 20→1000; fills empty `editor_actions.c`

## Claim
I'll take the undo leak (#8) and wire `editor_action_free` into the empty `editor_actions` module (#17): free discarded/overflowed actions, bump `MAX_UNDO_STATES` to 1000.

## Change
- Implement `editor_action_free` in `editor_actions.c` / `.h`
- Call it when truncating future undo entries and when shifting on capacity overflow
- Use it in editor teardown; set `MAX_UNDO_STATES` to 1000
