---
status: root_cause_found
trigger: "Phase 39 Plan 05 bounded Adaptive Fixed/Dynamic matcher ring fails JS preflight and crashes native with 0xc0000409."
created: 2026-07-22
updated: 2026-07-22
---

# Debug: Phase 39 Dynamic Matcher Ring

## Symptoms

- Expected: FixedOrStored and DynamicOrFixedOrStored obtain all Adaptive match probes and emitted bytes from one fixed-memory, acknowledgement-safe cursor, while preflight exactly admits the resulting filter work.
- Actual: the Plan 05 262-byte cursor attempt fails preflight on JS and native exits with `0xc0000409`; implementation was restored to the Plan 04 baseline.
- Reproduction: Plan 05 native focused RED observed Fixed planning facts `2` instead of expected `4` and Dynamic `6` instead of expected `8`; the attempted GREEN then failed before scoped four-target evidence.
- Timeline: introduced while replacing the stateless Adaptive supplier used by `_png_filtered_match_at` with a bounded look-ahead/history ring.

## Current Focus

hypothesis: "Confirmed: the cursor producer, matcher look-ahead, logical consumer, and acknowledgement successor must be distinct state roles; the Plan 04 baseline measures a separate traversal instead of the actual source."
next_action: "Implement the single-source match cursor with deep-owned pending successor state, then reproduce the discarded GREEN failure under explicit window-bound assertions before accepting it."

## Evidence

- timestamp: 2026-07-22
  observation: "Plan 04 added traversal work accounting for sequential Adaptive replay, but Fixed/Dynamic `_png_filtered_match_at` still uses the stateless byte supplier for random offsets."
- timestamp: 2026-07-22
  observation: "Plan 05 RED test committed as fee6fe2 proves undercounted selector rows: Fixed 2 versus 4 and Dynamic 6 versus 8."
- timestamp: 2026-07-22
  observation: "The Plan 05 Green ring attempt failed preflight on JS and crashed native with 0xc0000409; source was restored rather than accepted."
- timestamp: 2026-07-22
  observation: "Static trace of the restored Plan 04 baseline: `_png_encode_preflight_with_filter` adds standalone `_png_adaptive_traverse` passes (Stored=1, FixedOrStored=1, DynamicOrFixedOrStored=3) but `_png_fixed_plan`, `_png_dynamic_frequencies`, and `_png_dynamic_plan` each invoke `_png_filtered_match_at`; that matcher reads both operands through stateless `_png_filtered_scanline_byte`, which calls `_png_filter_image_row_winner` for every Adaptive lookup. The planning facts therefore do not describe those walks."
- timestamp: 2026-07-22
  observation: "Replay trace: `stored_cursor`, `PngFixedState.filtered_cursor`, and `PngDynamicState.filtered_cursor` are all initialized to `None`. Stored falls back to `scanline_byte` (the stateless supplier); Fixed/Dynamic call the stateless matcher and then fall back to `_png_fixed_scanline_byte` while consuming literals/matches. `present` caches only a pending byte; `acknowledge` commits pending scalar state, but no current Adaptive cursor exists to commit."
- timestamp: 2026-07-22
  checked: "isolated native `moon -C modules/mb-image test png --target native --target-dir _build/debug-phase39-match-red --frozen -f '*adaptive match cursor*'`; target directory removed in finally"
  found: "All three committed RED tests fail exactly as recorded: Fixed planning facts are 2 rather than 4, and Dynamic facts are 6 rather than 8; the stream Fixed assertion is 2 rather than 4."
  implication: "The missing walks are the real Fixed matcher traversal and the two real Dynamic matcher traversals; the RED expectations are valid regression requirements, not a test-only discrepancy."

## Eliminated

- hypothesis: "The Phase 39 requirement can be met by the Plan 04 sequential cursor alone."
  reason: "Fixed/Dynamic matcher random probing bypasses it and the committed RED facts show the ledger remains undercharged."

## Resolution

- root_cause: "The design split the Adaptive byte source in two: a measured sequential `PngFilteredCursor` is used only for synthetic preflight facts, while all real Fixed/Dynamic matcher reads and all active replay fallbacks use an unmeasured random/stateless source. A 262-byte ring cannot safely repair this by replacing the producer cursor alone: matcher look-ahead advances the producer up to 258 bytes ahead of the logical DEFLATE consumer, so the state also needs an absolute consumer position, retained-window bounds, and a successor that is not aliased with the committed preview state."
- fix: "Make one private, persistent `PngFilteredMatchCursor` the sole Adaptive source for each Fixed/Dynamic planning walk and replay state. It must own a forward producer `PngFilteredCursor`, logical consume position, produced-exclusive position, retained-from position, and a deep-owned 262-slot circular byte window. `ensure(position + length)` may only advance the producer; `read(position)` serves retained bytes; consuming a token advances only logical position. Return a fresh/deep-copied successor for `present` and commit it only from `acknowledge`. Return each actual cursor's traversal facts from Fixed/frequency/bit planning and sum those facts directly; preflight uses a fresh full selected-replay cursor only to predict its admitted facts."
- verification: "The discarded Green implementation is not retained, so the exact JS error and native crash instruction cannot be proven from source. The failure is nevertheless explained by the missing producer/consumer split and pending-state ownership: advancing the one cursor for a probe and then using it as the emitter skips logical bytes; shallow-copying a mutable MoonBit ring lets preview mutate committed state; and a ring lookup without explicit retained bounds can index before/after its live window. Reproduce with explicit invariants (`retained_from <= requested < produced_exclusive`, capacity=262, `produced_exclusive - retained_from <= 262`) before attributing a more specific native runtime fault."
- tests: "Keep the committed Fixed=4 and Dynamic=8 assertions. Strengthen, rather than relax, them to obtain per-walk facts returned by the real planner cursors and add a stream test that calls `present` twice and verifies logical position, producer position, facts, and window contents remain unchanged until one successful `acknowledge`."
