---
phase: 67-resumable-rgba16-png-preservation
verified: 2026-07-23T10:48:08Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 67: Resumable RGBA16 PNG Preservation Verification Report

**Phase Goal:** Library users can obtain the same exact RGBA16 result through caller-owned input chunks with the established bounded decoder lifecycle.
**Verified:** 2026-07-23T10:48:08Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A user can select `PngChunkDecoder::new_rgba16` and receive component-byte-identical output to fresh eager `decode_rgba16` for empty, one-byte, and ragged Type-6/16 schedules, including Adam7. | ✓ VERIFIED | The sole public selector is `png.mbt:127-145`; it constructs `PngDecodeMachine::new_with_profile(PngDecodeProfile::Rgba16, ...)`. The public test begins every schedule with an empty view (`stream_decode_test.mbt:770-775`), then runs one-byte and ragged schedules for both normal and Adam7 literals (`802-835`). Its comparator checks descriptor, metadata, byte accounting/disposition, and every channel’s two component bytes (`423-481`) against a fresh eager decode. Focused test: 7/7 passed. |
| 2 | Chunk callers observe accepted-only input progress and receive the one decoded image only through successful `finish()`, with no partial image or retained caller view exposed. | ✓ VERIFIED | `push` iterates the supplied `ByteView` synchronously and returns only accepted bytes; terminal input is refused with zero consumption (`stream_decode.mbt:734-771`). `PngDecodeMachine` declares no `ByteView` field (`1-45`), and `finish` alone moves the private outcome to `DecodeResult`, then marks the facade `Finished` (`775-797`; `645-659`). The white-box facade test confirms a live lifecycle but no private outcome before `finish` (`stream_decode_wbtest.mbt:463-491`). |
| 3 | Truncated, malformed, profile-invalid, and resource-limited RGBA16 streams fail before a result is exposed and retain sticky typed terminals under later pushes and repeated `finish`; generic Type-6/16 chunks remain RGBA8 high-byte compatible. | ✓ VERIFIED | The terminal test drives early EOF, bad signature, authenticated `gAMA` profile rejection, and one-less output limit; it asserts their typed contexts then calls the existing sticky replay helper (`stream_decode_test.mbt:867-938`). The same public parity test asserts generic output remains `Rhi,Ghi,Bhi,Ahi` (`837-853`). The profile/resource gate is executed through the shared `Rgba16` machine, not an alternate parser (`png.mbt:135-143`; Phase 66 verified its pre-allocation gate and 8-byte layout). Focused test: 7/7 passed. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Additive `new_rgba16` constructor selecting the shared Rgba16 profile | ✓ VERIFIED | Exists; substantive 19-line constructor; wired directly to `PngDecodeMachine::new_with_profile(PngDecodeProfile::Rgba16, ...)`. `PngChunkDecoder::new` remains a separate generic constructor using the generic machine (`80-98`), so generic selection was not widened. |
| `modules/mb-image/png/stream_decode_test.mbt` | Public exact parity, compatibility, progress, and terminal evidence | ✓ VERIFIED | Exists; substantive schedule, comparator, compatibility, and error tests are reachable by the PNG test target. The focused RGBA16 filter completed 7/7 successfully. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | Internal outcome/lifecycle privacy evidence | ✓ VERIFIED | Exists; substantive white-box test reaches the public facade’s first-IDAT boundary, observes a private lifecycle, and verifies `has_private_outcome() == false` before finish. It is compiled and exercised by the PNG package test target. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | `PngDecodeProfile::Rgba16` | `new_rgba16` creates the established private byte-fed machine | ✓ WIRED | `new_rgba16` calls `new_with_profile` and passes `Rgba16` at `png.mbt:135-143`. The generated one-line regex reported false because the symbols span lines; direct source inspection confirms the link. |
| `modules/mb-image/png/stream_decode_test.mbt` | `modules/mb-image/png/png.mbt` | Fresh `decode_rgba16` is the component-byte oracle | ✓ WIRED | `png_rgba16_chunk_eager` calls `PngDecoder::decode_rgba16` (`743-758`); each chunk result is compared with that new eager result (`815-833`). |
| `PngChunkDecoder::push/finish` | private `PngDecodeMachine` outcome | accepted-byte progression and sole terminal transfer | ✓ WIRED | The facade feeds bytes one at a time to `machine.accept`, retains the first error in `Failed`, and calls `into_decode_result` only after a successful explicit EOF (`734-797`). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PngChunkDecoder::new_rgba16` | `state: Active(machine)` | Public constructor passes `Rgba16` to the existing byte-fed machine | `push` synchronously accepts the caller's bytes; `finish` transfers that machine’s actual decode result | ✓ FLOWING |
| Public schedule test | `scheduled` / `eager` decode results | Normal and Adam7 Type-6/16 literals passed through real chunk/eager decode paths | Comparator reads all real image component bytes, descriptor, metadata, accounting, disposition, budget, and diagnostics | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| RGBA16 selector, schedules, terminal behavior, and lifecycle regressions | `moon -C modules/mb-image test png --target js --frozen --filter '*rgba16*'` | `Total tests: 7, passed: 7, failed: 0.` | ✓ PASS |
| Ordinary PNG package, serial wasm | `moon -C modules/mb-image test png --target wasm --frozen` | `242/242` passed (serial phase evidence). | ✓ PASS |
| Ordinary PNG package, serial wasm-gc | `moon -C modules/mb-image test png --target wasm-gc --frozen` | `242/242` passed (serial phase evidence). | ✓ PASS |
| Ordinary PNG package, serial js | `moon -C modules/mb-image test png --target js --frozen` | `242/242` passed (serial phase evidence). | ✓ PASS |
| Ordinary PNG package, serial native | `moon -C modules/mb-image test png --target native --frozen` | `242/242` passed (serial phase evidence). | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `RGBA16DEC-03` | `67-01-PLAN.md` | Caller-selected chunk RGBA16 preservation with eager equivalence, accepted-only progress, atomic failure, sticky terminals, and frozen generic behavior | ✓ SATISFIED | The three roadmap truths above cover the selector/parity, lifecycle/privacy, and typed failure/generic compatibility portions of the requirement. |

No orphaned Phase 67 requirements were found: `RGBA16DEC-03` is the sole roadmap-mapped requirement and is declared by the sole plan.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No phase-introduced `TBD`/`FIXME`/`XXX`, placeholder implementations, empty handlers, hard-coded empty results, or console-only behavior found in the three modified files. | ℹ️ Info | No blocker. The two prose matches for “not available” describe lifecycle/previous-phase scope, not unfinished code. |

## Gaps Summary

No gaps found. The phase adds exactly one public chunk selector, routes it to Phase 66’s established bounded Rgba16 machine, and preserves the generic constructor’s RGBA8 route. No later-phase deferral was needed: Phase 68’s broader adversarial qualification is outside this phase’s contracted success criteria.

---

_Verified: 2026-07-23T10:48:08Z_
_Verifier: the agent (gsd-verifier)_
