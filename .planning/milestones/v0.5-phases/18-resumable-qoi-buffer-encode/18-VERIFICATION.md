---
phase: 18-resumable-qoi-buffer-encode
verified: 2026-07-20T13:53:11Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 18: Resumable QOI Buffer Encode Verification Report

**Phase Goal:** Library users can preflight a compatible image once and drain its canonical QOI representation through caller-supplied output buffers or leases with resumable progress.
**Verified:** 2026-07-20T13:53:11Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Arbitrary callback-scoped output leases, including zero and one byte, produce exact per-call progress and `NeedOutput` until the final marker byte. | ✓ VERIFIED | `pull` copies only while `written < destination.length()` and advances `pending_offset`/`total_copied` only after a successful `set` ([stream_encode.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode.mbt:75)). The public test exercises zero then 24 one-byte pulls, checking zero progress, one byte per call, total 24, and final completion ([stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode_test.mbt:19)). |
| 2 | Every zero, one-byte, and mixed-capacity schedule yields the eager canonical QOI byte sequence exactly once, in order, with an exact completed total. | ✓ VERIFIED | Eager and stream paths share `QoiEncodeTokens::next` for opcode selection ([encode.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/encode.mbt:340)); stream drains each complete pending token without regeneration. Generated vectors compare zero/one/mixed schedules byte-for-byte against canonical expected bytes and validate cumulative total ([stream_encode_wbtest.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode_wbtest.mbt:41)). Four-target suite passed. |
| 3 | Compatibility, exact-length, limits, metadata, and the single work-budget charge complete before an output byte is exposed. | ✓ VERIFIED | Constructor builds metadata disposition, then calls the shared preflight before returning an encoder ([stream_encode.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode.mbt:19)). Preflight validates source, exact chunk length, ordered output/width/height/pixels/work limits, then charges exactly once ([encode.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/encode.mbt:454)). The tests confirm underfunded construction is atomic and the successful charge neither waits for nor repeats on a zero-capacity pull ([stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode_test.mbt:44), [stream_encode_wbtest.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode_wbtest.mbt:71)). |
| 4 | The encoder retains no mutable lease or whole-output staging buffer, and documents the stable immutable-source contract. | ✓ VERIFIED | Public contract explicitly retains an immutable `ImageView`, requires unchanged backing through terminal state, and prohibits snapshot/lock/output staging ([qoi.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/qoi.mbt:70)). `QoiStreamEncoder` stores state, bounded pending bytes, counters, length, and metadata only; `MutByteLease` is a `pull` parameter and is not a field ([qoi.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/qoi.mbt:74), [stream_encode.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode.mbt:75)). The lease API scopes live leases to `with_mut` ([views.mbt](D:/source/moonbit-foundation/modules/mb-core/bytes/views.mbt:124)). |
| 5 | Completion is reported only after copying the eighth marker byte; terminal pulls are sticky and deterministically reject further use with zero written. | ✓ VERIFIED | The final marker byte transitions to `Finished` only after copy and exact-total check ([stream_encode.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode.mbt:123)); a later `pull` returns zero and `Failed(qoi-stream-terminal)` ([stream_encode.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode.mbt:79)). The public one-byte test exercises both final-marker timing and the next terminal call ([stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/qoi/stream_encode_test.mbt:30)). |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/qoi/qoi.mbt` | Public stream contract beside unchanged eager traits | ✓ VERIFIED | Compiler-derived interface exports encoder, pull outcome/result, and all three accessors. Diff from the phase baseline adds only stream public types; eager `QoiEncoder` surface remains unchanged. |
| `modules/mb-image/qoi/encode.mbt` | Shared bounded canonical token generator | ✓ VERIFIED | Substantive shared `QoiEncodeTokens` implementation is consumed by both eager chunk writing and stream pending generation. |
| `modules/mb-image/qoi/stream_encode.mbt` | Caller-lease pull encoder | ✓ VERIFIED | Implements construction preflight, bounded pending drain, exact counters, marker timing, and sticky terminal state. |
| `modules/mb-image/qoi/stream_encode_test.mbt` | Public contract tests | ✓ VERIFIED | Contains executable zero/one-byte, final-marker, terminal, preflight, lease-lifetime, and eager-byte tests. |
| `modules/mb-image/qoi/stream_encode_wbtest.mbt` | Canonical schedule and resource tests | ✓ VERIFIED | Iterates generated vectors and checks schedules, pending split state, and one-time work charge. |
| `policy/foundation.json` | Exact QOI production/test/interface inventory | ✓ VERIFIED | Includes `stream_encode.mbt`, both test files, and compiler-derived stream public interface in ordered inventory. |
| `scripts/quality/Assert-Policy.ps1` | Broad and scoped assertions with negative fixtures | ✓ VERIFIED | Both assertions require the same exact production order; scoped validator checks directory/interface and negatives reject missing/extra/reordered stream entries. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `stream_encode.mbt` | `encode.mbt` | Shared private token generator | ✓ WIRED | Same package accesses `qoi_encode_preflight`, `qoi_encode_tokens_new`, and `QoiEncodeTokens::next`; eager uses that same token state in `qoi_write_chunks`. |
| `stream_encode.mbt` | `bytes/views.mbt` | Live caller lease only | ✓ WIRED | `pull` accepts and writes through `@bytes.MutByteLease`; no lease is retained. The package import and callback-scoped `with_mut` contract compile on all four targets. |
| `stream_encode.mbt` | `codec/contracts.mbt` | Preflight limits and budget before output | ✓ WIRED | Constructor accepts `CodecLimits` and `Budget`; shared preflight applies exact ordered limits and one `ResourceCharge` before a stream object exists. |
| `foundation.json` | `Assert-Policy.ps1` | Broad and scoped ordered inventory | ✓ WIRED | `Assert-FoundationPolicy` and `Assert-QoiFoundationPolicy` both assert `moon.pkg` through `stream_encode.mbt` order; executed negative fixtures reject reordered, missing, and extra entries. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `stream_encode.mbt` | `pending` | Header from validated source; subsequent bytes from `QoiEncodeTokens::next` over retained `ImageView`; fixed QOI marker | Caller image pixels and shared canonical encoder state; no static whole-output fallback | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| All QOI public and white-box stream tests on portable targets | `moon -C modules/mb-image test qoi --target all --frozen` | 30/30 passed on wasm, wasm-gc, js, and native | ✓ PASS |
| Generated public interface and QOI policy inventory | `moon -C modules/mb-image info --target all --frozen`; scoped/broad assertion command | Generated interface matched policy; broad/scoped assertions and all negative fixtures passed | ✓ PASS |
| Scoped QOI quality integration lane | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Qoi` | Exit 0 | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no phase-declared or conventional `probe-*.sh` files exist.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| QSTR-04 | 18-01 | Arbitrary caller-owned capacities with deterministic non-terminal progress and no loss, duplication, or reorder | ✓ SATISFIED | Shared token generation plus generated zero/one/mixed schedule comparisons; four-target tests pass. |
| QSTR-05 | 18-01 | Eager-equivalent preflight failures before output and exact completed byte total | ✓ SATISFIED | Constructor-only shared preflight, one-charge test, final-marker/cumulative-total test, and four-target suite pass. |

No Phase 18 requirements are orphaned: the plan declares both roadmap-mapped IDs, QSTR-04 and QSTR-05.

### Anti-Patterns Found

None. The only `TODO`-like text found in a changed file is the literal forbidden-word matcher in `Assert-Policy.ps1`; it is a quality check, not a debt marker. No `TBD`, `FIXME`, or `XXX` marker exists in Phase 18 implementation files.

### Human Verification Required

None. The completed terminal transition, canonical output schedules, constructor-only preflight, and policy fail-closed behavior have executable four-target coverage. The source-stability condition is an explicit caller contract, not a GUI/external-system behavior requiring UAT.

### Gaps Summary

No gaps found. The generic artifact/link query cannot infer same-package MoonBit relationships from file names, so it reported four non-references; direct code tracing above verifies each connection and the runnable suite exercises them.

---

_Verified: 2026-07-20T13:53:11Z_
_Verifier: the agent (gsd-verifier)_
