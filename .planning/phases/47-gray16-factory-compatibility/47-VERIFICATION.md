---
phase: 47-gray16-factory-compatibility
plan: "01"
status: passed
score: 100
requirements:
  - id: GRAY16-01
    status: passed
evidence:
  - storage component-byte access and U16 construction regression
  - public eager/chunk Gray16 Stored factory and exact wire-byte regressions
  - native storage and PNG package verification
gaps: []
human: []
verified: 2026-07-22
---

# Phase 47 Goal-Backward Verification

## Verdict

**Passed — 100/100.** The current implementation retains the Phase 47
`GRAY16-01` public Stored/non-interlaced baseline. Later Phase 48–49 strategy
and portability work extends this boundary without replacing its public
factories, wire format, or compatibility protections.

## Goal Evidence

| Goal-backward truth | Evidence | Verdict |
| --- | --- | --- |
| Packed U16 Gray callers can construct and read storage-order component bytes without weakening U8 byte access. | `ImageView::get_component_byte` and `MutImageView::{get,set}_component_byte` accept only packed U8/U16, validate coordinates/channels/component-byte bounds, and use checked offsets. `OwnedImage::with_mut_view` grants the same callback-scoped U8/U16 authority. The storage regression writes and reads `34,12,cd,ab`, rejects component byte 2 and U16 `get_byte`, and confirms U8 compatibility. | PASS |
| Explicit eager and caller-buffered Gray16 Stored factories exist and bind the non-interlaced baseline. | `PngEncoder::new_gray16()` and `PngChunkEncoder::new_gray16()` each delegate to their Gray16 strategy constructor with `Stored`, `None`, and `PngInterlaceStrategy::None`; their public profile is `Gray16`. Legacy `new()` remains on `LegacyRgbOrRgba`, so Gray16 is never implicit. | PASS |
| A valid packed U16 Gray source emits standards-compliant PNG type 0, bit depth 16, non-interlaced samples in PNG big-endian order. | Gray16 source admission requires `ChannelOrder::Gray`, U16, no alpha, packed/tightly packed rows, canonical sRGB metadata, and top-left orientation. `_png_wire_byte` selects storage byte `1,0` for little-endian and `0,1` for big-endian sources. IHDR emission selects depth `0x10`, type `0x00`, and interlace `0x00`. Native eager and chunk tests assert exact `12 34 ab cd` wire bytes and IHDR fields. | PASS |
| Unsupported inputs are rejected before eager output or a usable caller-buffered encoder is exposed. | The shared preflight checks semantic source facts before budget charging/output. The eager Gray16 test passes RGB input and requires `gray16-required`, writer position 0, and unchanged budget; the chunk test requires the same error and unchanged budget. Current Gray16 strategy admission regressions additionally cover capability, geometry, output, work, and budget failures with untouched sentinels. | PASS |
| Gray16 remains non-interlaced and Adam7 cannot be selected through its public factories. | Every public Gray16 factory hard-codes `PngInterlaceStrategy::None`. Shared preflight also rejects a Gray16 profile with any other strategy using `gray16-noninterlaced-required`, so the invariant is enforced defensively rather than relying solely on the API shape. | PASS (source-level boundary) |
| Gray8, RGB8, and straight-RGBA8 behavior remains protected. | Eager and chunk PNG suites retain literal frozen Gray8/RGB8/RGBA8 Stored compatibility vectors, configured/default route assertions, and complete public decode regressions. The full native PNG suite passes with all of these tests present. | PASS |

## Independent Commands

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test storage --target native --frozen` | PASS — 15/15 |
| `moon -C modules/mb-image test png --target native --frozen` | PASS — 190/190 |

## Scope Notes

- The goal is satisfied by the explicit Stored/non-interlaced public baseline;
  all-six strategy matrices and hostile lease schedules are later Phase 48–49
  evidence and were not treated as Phase 47 obligations.
- `ROADMAP.md` and `REQUIREMENTS.md` still display Phase 47 / `GRAY16-01` as
  pending. This verification records the implementation result only and does
  not modify those orchestrator-owned planning files.
