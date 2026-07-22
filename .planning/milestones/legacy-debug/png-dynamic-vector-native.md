---
status: resolved
trigger: Native PNG filter-compatibility test aborts when it embeds the strict-Dynamic complete PNG vector.
created: 2026-07-22
updated: 2026-07-22
---

# Debug: PNG Dynamic Vector Native

## Symptoms

- Expected: the Phase 38 frozen Dynamic compatibility assertion runs on native and all portable targets.
- Actual: native `png.blackbox_test.exe` exits `0xc0000409` before Dynamic encoding when the new test evaluates the complete 128×1 periodic RGB8 Dynamic PNG expected vector.
- Reproduction: `moon -C modules/mb-image test png --target native --target-dir _build/phase38-recover7-native --frozen --no-parallelize -f 'PNG filter strategy eager frozen compatibility vectors'`.
- Timeline: introduced by the Phase 38 test-only frozen-vector assertion; native package compile remains successful.

## Resolution

- Restored `encode_test.mbt` to the bounded Stored, FixedOrStored, and Adaptive-filter-factory compatibility vectors; removed its experimental Dynamic helper and standalone test.
- Moved the immutable complete 202-byte strict-Dynamic PNG equality into the existing `stream_encode_test.mbt` public strict-winner test. That test already proves final `BTYPE=10`, eager/chunk hostile-capacity parity, complete-input decode, and every RGB component.
- This retains exact public compatibility coverage for all three compression routes without the native abort.
- Removed the duplicate Dynamic block from the large chunk filter-vector test; the immutable Dynamic vector remains asserted only by the stable strict-winner test, which independently checks eager/chunk parity and decode.

## Evidence

- Native `moon ... check png --target native` passed after the Phase 38 API seam.
- Removing the Dynamic vector section makes the new eager test pass; RGB8, RGBA8, and FixedOrStored sections pass.
- One literal, chunked literals, and scalar-byte construction were reported to reproduce the crash.
- Before the move, `moon -C modules/mb-image test png --target native --target-dir _build/phase38-recover-current-native --frozen --no-parallelize -f 'PNG filter strategy eager freezes strict Dynamic compatibility vector'` reproduced exit `0xc0000409`.
- After the move, the strict-Dynamic public-vector/decode test and the eager Stored/Fixed/Adaptive compatibility test each passed on `native`, `js`, `wasm`, and `wasm-gc` using separate `phase38-recover-{stream,filter}-{target}` target directories.

## Eliminated

- hypothesis: the Phase 38 filter factory implementation corrupts Dynamic encoding.
  - reason: an early return before Dynamic encoding still crashed when the vector helper was present.
- hypothesis: exact strict-Dynamic coverage must remain in `encode_test.mbt`.
  - reason: the existing stream public test exercises the same public eager encoder strategy and adds caller-buffered parity plus complete decode coverage, while safely hosting the frozen full vector.
