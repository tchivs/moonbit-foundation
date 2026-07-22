---
status: resolved
trigger: "Phase 43 public 5x5 Adam7 eager RGB8/RGBA8 round-trip succeeds with Stored but native exits 0xc0000409 with FixedOrStored before assertions."
created: 2026-07-22
updated: 2026-07-22
---

# Debug: Phase 43 Fixed Adam7 Public Crash

## Symptoms

- Expected: Public Adam7 eager encoding and decoding of generated 5x5 RGB8 and straight-RGBA8 sources completes for Stored, FixedOrStored, and DynamicOrFixedOrStored.
- Actual: The focused native test passes with Stored only, but the executable aborts with exit code `0xc0000409` when FixedOrStored is included, before test assertions can report a mismatch.
- Reproduction: `moon -C modules/mb-image test png --target native --frozen -f "PNG Adam7 public eager fidelity and frozen None compatibility"` after enabling the generated all-strategy loop in `encode_test.mbt`.
- Timeline: Newly exposed by Phase 43 public decode-fidelity evidence; Phase 42 verified Adam7 framing and stream identity but not a Fixed Adam7 public eager decode round trip.

## Current Focus

hypothesis: "Resolved: the focused test used the legacy eager helper's 1,024-unit work ceiling; Fixed Adam7 preflight legitimately exceeds it while Stored does not."
next_action: "None — retain the all-strategy public round trip under explicit ample Adam7 evidence limits."

## Evidence

- timestamp: 2026-07-22
  observation: "Stored-only generated 5x5 Adam7 selector passed; FixedOrStored-only selector aborted native with 0xc0000409."
- timestamp: 2026-07-22
  observation: "Replacing the eager helper unwrap with a Result probe returned the normal error context `work`; the abort was the test's unwrap, not a native memory fault or decode crash."
- timestamp: 2026-07-22
  observation: "The restored public all-strategy eager encode/decode selector passed on js, wasm, wasm-gc, and native when its 5x5 Adam7 evidence uses the existing 1,048,576-unit Adam7 admission limits and budget."

## Eliminated


## Resolution

root_cause: "The new 5x5 all-pass Fixed Adam7 public evidence was run through png_encode_with, whose legacy default CodecLimits and Budget each cap work at 1,024; Fixed planning/replay needs more work while Stored fits, so unwrap aborted with 0xc0000409."
fix: "Added a test-local png_adam7_encode_with helper that keeps the original all-strategy, public encode/decode assertions but uses the already-established 1,048,576-unit Adam7 admission limits and budget."
verification: "moon -C modules/mb-image test png --target native --frozen -f \"PNG Adam7 public eager fidelity and frozen None compatibility\"; moon -C modules/mb-image test png --target all --frozen -f \"PNG Adam7 public eager fidelity and frozen None compatibility\" (js, wasm, wasm-gc, native all passed)."
files_changed:
  - modules/mb-image/png/encode_test.mbt
  - .planning/debug/phase43-fixed-adam7-crash.md
