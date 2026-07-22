---
status: resolved
trigger: "Phase 29 private PNG encoder native black-box focused test exits with 0xc0000409."
created: 2026-07-21
updated: 2026-07-21
---

## Current Focus

hypothesis: "Confirmed: the private encoder's zlib state machine omitted the Adler-32 trailer rather than a stale main-worktree build artifact causing the crash."
next_action: "Use the focused PNG encoder checks during Phase 29 validation."

## Evidence

- timestamp: 2026-07-21
  observation: "moon -C modules/mb-image test png --target native --frozen failed to run png.blackbox_test.exe with exit code 0xc0000409 during Phase 29 Plan 01 Task 2 validation."
- timestamp: 2026-07-21
  observation: "A detached worktree at 446fc42 plus only the four in-progress PNG files reproduced the focused native failure, eliminating stale artifacts and unrelated QOI/config changes."
- timestamp: 2026-07-21
  observation: "The portable focused test returned CoreError context png-encode-stored-cursor from PngEncodeMachine::zlib_byte; the eager test's unwrap caused the native process failure."
- timestamp: 2026-07-21
  observation: "After emitting the four Adler-32 trailer bytes and excluding them from Adler accumulation, the focused eager encoder test passed on JS and native in the detached worktree."

## Eliminated

- timestamp: 2026-07-21
  hypothesis: "The crash came from stale main-worktree native build artifacts."
  reason: "It reproduced in a detached worktree with a fresh target directory and only the PNG changes applied."

## Resolution

root_cause: "PngEncodeMachine::zlib_byte stopped after the final stored block and did not emit the Adler-32 trailer; acknowledge also treated trailer bytes as payload."
fix: "Emit the four trailer bytes from the completed Adler state and bound accumulation to the stored-payload region."
verification: "Focused PNG eager encoder test passed with --target js and --target native in the detached worktree."
files_changed: ["modules/mb-image/png/stream_encode.mbt"]
