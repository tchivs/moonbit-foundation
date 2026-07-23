---
phase: 77-indexed-png-transparency
verified: 2026-07-23T19:00:29Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 77: Indexed PNG Transparency Verification Report

**Phase Goal:** Add canonical optional `tRNS` emission and exact RGB/RGBA decode evidence.
**Verified:** 2026-07-23T19:00:29Z
**Status:** `passed` — all four behavior-dependent truths have completed portable runtime evidence.
**Re-verification:** No — initial verification. No prior `77-VERIFICATION.md` existed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | User can create an immutable indexed source with alpha cardinality equal to palette-entry cardinality; mismatches are atomic. | ✓ VERIFIED | `PngIndexedImage::new` accepts `palette_alpha` at [png.mbt:224](../../../../modules/mb-image/png/png.mbt:224), checks it before allocation/charge at [png.mbt:255](../../../../modules/mb-image/png/png.mbt:255), and owns it after indices and RGB bytes at [png.mbt:267](../../../../modules/mb-image/png/png.mbt:267), [png.mbt:294](../../../../modules/mb-image/png/png.mbt:294). Its mismatch/budget assertions are at [encode_test.mbt:1073](../../../../modules/mb-image/png/encode_test.mbt:1073) and passed in the completed 272/272 all-target run. |
| 2 | An all-opaque palette emits no `tRNS` and preserves the exact Phase 76 eager bytes. | ✓ VERIFIED | Preflight sets `trns_length` only on `alpha != 0xff` at [encode.mbt:2075](../../../../modules/mb-image/png/encode.mbt:2075); zero length leaves IDAT at the tRNS start at [encode.mbt:315](../../../../modules/mb-image/png/encode.mbt:315). The literal 89-byte compatibility/no-tRNS assertion at [encode_test.mbt:990](../../../../modules/mb-image/png/encode_test.mbt:990) passed on all four targets. |
| 3 | A non-opaque palette emits one canonical `tRNS` after PLTE, with valid independent CRC, and public generic decode is exact RGBA8. | ✓ VERIFIED | Last-non-opaque scanning derives the canonical span at [encode.mbt:2076](../../../../modules/mb-image/png/encode.mbt:2076); the byte machine emits it between PLTE and IDAT at [stream_encode.mbt:1431](../../../../modules/mb-image/png/stream_encode.mbt:1431), [stream_encode.mbt:1448](../../../../modules/mb-image/png/stream_encode.mbt:1448). The independent CRC/wire and public RGBA8 tests at [encode_test.mbt:920](../../../../modules/mb-image/png/encode_test.mbt:920), [encode_test.mbt:1028](../../../../modules/mb-image/png/encode_test.mbt:1028) passed on all four targets. |
| 4 | Invalid sources and transparent-frame preflight rejections expose no writer bytes and do not mutate the affected budget. | ✓ VERIFIED | Limits are evaluated before the single work charge at [encode.mbt:2090](../../../../modules/mb-image/png/encode.mbt:2090) and [encode.mbt:2107](../../../../modules/mb-image/png/encode.mbt:2107). The no-writer-progress/unchanged-budget tests at [encode_test.mbt:1105](../../../../modules/mb-image/png/encode_test.mbt:1105) passed on all four targets. |

**Score:** 4/4 truths behavior-verified (0 present-but-behavior-unverified).

## Required Artifacts

| Artifact | Expected | L1/L2/L3 status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Validated, single-allocation Indexed8 source with alpha ownership. | ✓ EXISTS / ✓ SUBSTANTIVE / ✓ WIRED | 360+ lines; validated before `OwnedBytes::new_with_allocator_and_charge`, explicit stored palette length prevents alpha from changing RGB lookup boundaries, and preflight calls `alpha_at`. |
| `modules/mb-image/png/encode.mbt` | Atomic preflight and optional canonical tRNS frame facts. | ✓ EXISTS / ✓ SUBSTANTIVE / ✓ WIRED | `PngFrameFacts` carries `trns_length`/`trns_start` ([encode.mbt:290](../../../../modules/mb-image/png/encode.mbt:290)); indexed preflight derives it and machine construction consumes the result ([stream_encode.mbt:918](../../../../modules/mb-image/png/stream_encode.mbt:918)). |
| `modules/mb-image/png/stream_encode.mbt` | Single acknowledged byte machine that emits PLTE/tRNS with independent CRC. | ✓ EXISTS / ✓ SUBSTANTIVE / ✓ WIRED | `trns_crc` is independently type-seeded ([stream_encode.mbt:901](../../../../modules/mb-image/png/stream_encode.mbt:901)), payload is previewed from the owned alpha segment ([stream_encode.mbt:1454](../../../../modules/mb-image/png/stream_encode.mbt:1454)), and advances only after acknowledgement ([stream_encode.mbt:1522](../../../../modules/mb-image/png/stream_encode.mbt:1522)). |
| `modules/mb-image/png/encode_test.mbt` | Independent wire/CRC, public decode, opaque compatibility, and atomicity evidence. | ✓ EXISTS / ✓ SUBSTANTIVE / ✓ WIRED | Has its own CRC-32 implementation, direct `PngDecoder` decode, frozen bytes, and no-writer-progress/budget assertions; it imports no production wire helper. These tests passed in the completed all-target run. |
| `modules/mb-image/png/encode_wbtest.mbt` | White-box frame-layout and tRNS acknowledgement-timing evidence. | ✓ EXISTS / ✓ SUBSTANTIVE / ✓ WIRED | Explicit tRNS offsets and preview-versus-ack state checks at [encode_wbtest.mbt:1127](../../../../modules/mb-image/png/encode_wbtest.mbt:1127); passed in the completed all-target run. |

## Key Link Verification

| From | To | Via | Status | Evidence |
| --- | --- | --- | --- | --- |
| `png.mbt` | `encode.mbt` | Indexed source supplies palette length and alpha. | ✓ WIRED | `palette_length()` and `alpha_at(entry)` are consumed by `_png_encode_indexed_preflight` at [encode.mbt:2074](../../../../modules/mb-image/png/encode.mbt:2074). |
| `encode.mbt` | `stream_encode.mbt` | Preflight creates shared `PngFrameFacts`; indexed machine stores it. | ✓ WIRED | Frame facts are created at [encode.mbt:2083](../../../../modules/mb-image/png/encode.mbt:2083) and assigned to the machine at [stream_encode.mbt:931](../../../../modules/mb-image/png/stream_encode.mbt:931). |
| `stream_encode.mbt` | `encode_test.mbt` | Produced Type-3 chunks are independently parsed and decoded publicly. | ✓ WIRED | The encoder is invoked at [encode_test.mbt:1037](../../../../modules/mb-image/png/encode_test.mbt:1037); the subsequent test independently parses `tRNS` and its CRC at [encode_test.mbt:1048](../../../../modules/mb-image/png/encode_test.mbt:1048). |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Indexed tRNS machine path | `trns_length`, then `source.alpha_at(...)` | Caller `palette_alpha` → owned source → preflight scan → `PngFrameFacts` → byte machine | Caller-provided bytes; no static fallback or empty prop path | ✓ FLOWING (static trace) |
| Generic decode evidence | Encoded Type-3 bytes → `PngDecoder` image view | `PngEncoder::encode_indexed8` output supplied to `MemoryReader` | Actual encoded byte buffer, not fixture-only data | ✓ FLOWING (static trace) |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Completed main-branch portable validation | `moon -C modules/mb-image test png --target all --frozen --target-dir D:\\source\\moonbit-foundation-v019\\.moon-phase77-main` | Exit 0 in 187.4 s; wasm, wasm-gc, js, and native each reported 272/272. The dedicated target directory was removed after success. | ✓ PASS |
| Verifier full-package attempt | `moon -C modules/mb-image test png --target all --frozen --target-dir C:\\Users\\Admin\\AppData\\Local\\Temp\\mnf-phase77-verifier-20260724-01` | Exited 124 after 64 s with no completed test output; created target directory was removed. | ℹ️ SUPERSEDED by completed main-branch result |
| Verifier filtered attempt | `moon -C modules/mb-image test png --target all --frozen --target-dir C:\\Users\\Admin\\AppData\\Local\\Temp\\mnf-phase77-verifier-20260724-02 --filter '*Indexed8*'` | Still compiling after more than two minutes; emitted only existing warnings and no test result. The verifier terminated only this child test tree and removed its target directory. | ℹ️ SUPERSEDED by completed main-branch result |

## Probe Execution

No phase-declared or conventional `probe-*.sh` scripts were found; not applicable.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| INDEX-03 | `77-01-PLAN.md` | Palette alpha emits canonical optional tRNS and decodes publicly as RGB8 or RGBA8 with exact palette semantics. | ✓ SATISFIED | Requirement is mapped to Phase 77 in [REQUIREMENTS.md:15](../../../../.planning/REQUIREMENTS.md:15); implementation/wiring evidence is present and the completed main-branch all-target run passed 272/272 per target. |

No orphaned Phase 77 requirement was found: `INDEX-03` is the only traceability row for Phase 77 ([REQUIREMENTS.md:38](../../../../.planning/REQUIREMENTS.md:38)).

## Anti-Patterns Found

No Phase 77 blocker markers (`TBD`, `FIXME`, or `XXX`), placeholder implementations, hard-coded empty render/data paths, or unreferenced new production paths were found in the five phase artifacts. An older unrelated `not implemented yet` historical comment appears in `encode_wbtest.mbt:10`; it predates and does not govern the Phase 77 assertions.

## Disconfirmation Pass

- **Partial requirement risk resolved:** the stronger completed main-branch portable run supplies runtime evidence for all source tests; the verifier's incomplete attempts are retained below only for audit transparency.
- **Misleading-test check:** `png_indexed_crc32` in [encode_test.mbt:956](../../../../modules/mb-image/png/encode_test.mbt:956) is test-local and does not invoke the production CRC implementation, so the wire CRC test is independent rather than circular.
- **Uncovered error-path note:** Phase 77 proves preflight rejection before writer exposure, but it has no phase-specific test that makes a writer reject a `tRNS` payload after output has begun. This is outside INDEX-03's stated eager-preflight atomicity contract; it is informational, not a Phase 77 gap.

## Gaps Summary

No observable implementation failure, broken wiring, or unexecuted required behavior remains. The completed main-branch portable test run establishes the executable proof; Phase 77 achieves INDEX-03.

---

_Verified: 2026-07-23T19:00:29Z_
_Verifier: gsd-verifier_
