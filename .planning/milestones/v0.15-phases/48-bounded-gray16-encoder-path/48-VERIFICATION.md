---
phase: 48-bounded-gray16-encoder-path
plan: "01"
status: passed
score: 100
requirements:
  - id: GRAY16-02
    status: passed
gaps: []
human: []
verified: 2026-07-22
---

# Phase 48 Goal-Backward Verification

## Verdict

**Passed — 100/100.** The implementation delivers `GRAY16-02` within the
declared Phase 48 boundary. Phase 49-only hostile-capacity and four-target
evidence were not treated as omissions.

## Goal Evidence

| Goal-backward truth | Evidence | Verdict |
| --- | --- | --- |
| Gray16 reaches the common bounded None/Adaptive × Stored/Fixed/Dynamic path. | `PngEncoder` and `PngChunkEncoder` expose all three Gray16 factory families; each binds `Gray16` and `None` interlace. Shared preflight selects Stored, FixedOrStored, or DynamicOrFixedOrStored and all Gray16 replay states construct profile-aware filtered match cursors. The native six-pair eager/chunk test passes. | PASS |
| Every U16 source value becomes a high-byte/low-byte PNG wire stream, and filters use a two-byte pixel stride. | `_png_wire_byte` maps little-endian component byte `1,0` and big-endian `0,1`; both raw/filter and fixed scanline producers consume it. Gray16 profile admission returns `2UL` channels, which is used as the left predictor distance. Native tests check little/big-endian equality, Stored wire bytes, and an Adaptive Sub residual at byte stride two. | PASS |
| Fixed and Dynamic plans/replay consume that same bounded producer. | All Fixed/Dynamic frequency, bit-count, plan, and replay cursor construction passes `profile=profile`; match storage is the existing fixed 262-byte window. No `gray16_stored_none`, `gray16-stored-none-required`, or Gray16-only scanline bypass remains. | PASS |
| Fixed/Dynamic Gray16 source mutation causes the next caller lease to fail without writing it, then remains sticky. | The machine captures `source.mutation_revision()` after admission. `PngChunkEncoder::pull` invokes `validate_gray16_replay_revision()` before inspecting or writing the destination. The Gray16 test forces Fixed BTYPE `011` and Dynamic BTYPE `101`, accepts framing bytes, calls `set_component_byte`, requires the immediate pull to be `Failed` with zero bytes and unchanged total, then checks same error/progress and untouched later sentinel. | PASS |
| Revision state is shared and mutation-safe. | `LeaseOwner` owns one `MutationRevision`, propagated to `ByteView`, retained views, mutable leases, split children, and `OwnedBytes::view`. `MutByteLease::set` checks exhaustion before the backing write and increments only after success. `MutImageView::set_component_byte` delegates to that primitive; `ImageView::mutation_revision()` observes the retained backing. | PASS (source inspection; bytes/storage native regressions pass) |
| Capability, geometry, output, work, budget, and Gray16 Adam7 rejection are atomic. | Shared profile preflight validates source facts, dimensions/limits, and performs its budget charge only after planning. `gray16-noninterlaced-required` remains before preflight traversal/charge. The Gray16 all-pair admission helper checks eager writer position, no usable chunk result, unchanged budget, and untouched lease sentinels for capability, geometry, output, work, and budget failures. | PASS |
| No image-sized conversion/staging was introduced, and legacy/Gray8 behavior remains covered. | Cursor state holds scalar positions, bit accumulators, and the pre-existing 262-byte matcher window only; no converted image rows or second Gray16 stream driver exists. Full PNG suite covers Gray8/RGB/RGBA regressions. | PASS |

## Independent Commands

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test png --target native --frozen --filter 'PNG Gray16 Fixed and Dynamic replay mutations are sticky'` | PASS — 1/1 |
| `moon -C modules/mb-image test png --target native --frozen` | PASS — 188/188 |
| `moon -C modules/mb-core test bytes --target native --frozen` | PASS — 16/16 |
| `moon -C modules/mb-image test storage --target native --frozen` | PASS — 15/15 |

## Scope Notes

- Phase 49 owns zero/one/ragged public capacity matrices and independent js,
  wasm, wasm-gc, and native public evidence; those were intentionally excluded.
- No human validation is required for the Phase 48 acceptance boundary.
