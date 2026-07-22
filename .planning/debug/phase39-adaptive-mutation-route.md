---
status: diagnosed
trigger: "Diagnose Plan06 draft: Adaptive mutation replay reaches Finished; determine selection, producer timing, correct public test contract, and fingerprint coverage."
created: 2026-07-22T12:32:05.6866614+08:00
updated: 2026-07-22T12:46:00+08:00
---

## Current Focus

hypothesis: Confirmed. The Adaptive fixture selects Fixed; mutating its final pixel channel changes a three-byte match to literals, increasing replay DEFLATE bytes. Emission is capped at the preflight `plan.deflate_bytes`, so it transitions to Adler/IEND before the EOB-only Fixed fingerprint check runs.
test: Trace exact filtered bytes/tokens and the Fixed zlib offset guard; execute only the two target-isolated public selectors on JS.
expecting: The Fixed selector ends Finished; the Dynamic selector fails as currently intended.
next_action: Return the diagnose-only report and recommended minimal test edits to the parent agent.

## Symptoms

expected: A public Adaptive mutation regression test should exercise the Fixed replay drift detector and return the documented mutation error.
actual: The current uncommitted Plan06 public Adaptive mutation test reaches Finished after mutating the final pixel immediately after construction.
errors: No error; encoder returns Finished.
reproduction: Construct the public PNG stream encoder for png_fixed_or_stored_replay_image() using PngFilterStrategy::Adaptive, mutate the final pixel immediately after construction, then drive the encoder.
started: Uncommitted Plan06 draft.

## Eliminated

## Evidence

- timestamp: 2026-07-22T12:32:05.6866614+08:00
  checked: Debug-session initialization
  found: Investigation created specifically for the Adaptive Fixed fingerprint/mutation-route report; no source, tests, policy, or QOI files may be changed.
  implication: All subsequent work is read-only apart from this session file.
- timestamp: 2026-07-22T12:46:00+08:00
  checked: Adaptive FixedOrStored preflight for `png_fixed_or_stored_replay_image()`.
  found: The one RGB row selects Sub (score 50 versus None 164). Its 16 filtered bytes are `01 0a 0c 0c 00 fe 00 01 02 fe 01 fe 01 fe 02 ff`; Fixed emits 129 bits/17 DEFLATE bytes, hence total PNG 80, while Stored is 84. Fixed is the deterministic winner.
  implication: The observed Finished outcome is not a Stored-route fallback.
- timestamp: 2026-07-22T12:46:00+08:00
  checked: Source ownership and producer timing.
  found: `ImageView` retains a zero-copy `ByteView` over `OwnedImage` storage; Fixed's Adaptive `PngFilteredMatchCursor` is created empty after preflight and only calls its producer from replay. The mutation occurs before the first pull/source read.
  implication: Neither a source snapshot nor an early producer capture hides the mutation.
- timestamp: 2026-07-22T12:46:00+08:00
  checked: Fixed mutation at `(width - 1, 0, channel 0) = 0`.
  found: It changes filtered byte 13 from `fe` to `f4`, destroys the original length-3/distance-2 match at positions 11..13, and raises actual Fixed replay from 129 to 143 bits. `fixed_zlib_byte` invokes `fixed_preview_byte` only while `offset < plan.deflate_bytes + 2`; after the planned 17 bytes it emits Adler/IEND without another preview. The fingerprint is compared only in the EOB branch of `fixed_preview_byte`, which was deferred to byte 18 and is never reached.
  implication: The test is a token/bit-length drift test, not a safe checksum-fingerprint test; it exercises an existing bounded-replay boundary rather than the new check.
- timestamp: 2026-07-22T12:46:00+08:00
  checked: Target-isolated JS public selectors; temporary `_build/phase39-adaptive-debug-probe-js` was removed after each run.
  found: The Adaptive Fixed selector fails only by reaching `Finished`; the Adaptive Dynamic selector passes its current generic sticky-failure helper.
  implication: The reported symptom is reproduced without persistent build output. The Dynamic helper still needs an explicit BTYPE/error-context assertion to prove the route it claims to test.
- timestamp: 2026-07-22T12:46:00+08:00
  checked: Existing Dynamic and None replay checks.
  found: Dynamic already computes the same Adler-style full-stream fingerprint in `_png_dynamic_frequencies` and compares replay `adler` with `plan.fingerprint` at phase 5 (`png-encode-dynamic-replay-drift`). The None Fixed test mutates after the Fixed header but before the first source-producing preview and deliberately receives `png-encode-fixed-replay-work`; it is a matcher-work drift test.
  implication: Fixed's added scalar fingerprint is consistent and minimal, but both Fixed and Dynamic compare at EOB/phase 5 and a test that changes exact bit length can bypass that boundary.

## Resolution

root_cause: "The Adaptive Fixed test mutates a byte that destroys a planned length-3 match. Replay now needs one additional DEFLATE byte, but `fixed_zlib_byte` stops calling the replay producer at the old planned byte count. Since the new fingerprint is checked only when the producer reaches EOB, the check is never executed and the public wrapper returns Finished."
fix: "Do not alter encoder behavior for this test gap. Change the Fixed public mutation to a shape-preserving, same-code-width literal mutation and assert the selected Fixed header plus `png-encode-fixed-replay-drift`; strengthen the Dynamic test to assert its Dynamic header and existing dynamic-drift context."
verification: "Static code/data-flow trace plus isolated JS reproduction: Fixed test reaches Finished; Dynamic test passes; both probe target directories were deleted."
files_changed: []
