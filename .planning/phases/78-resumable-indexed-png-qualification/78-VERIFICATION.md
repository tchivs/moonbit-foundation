---
phase: 78-resumable-indexed-png-qualification
verified: 2026-07-23T20:01:09Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 78: Resumable Indexed PNG & Qualification Verification Report

**Phase Goal:** Library users can emit Indexed8 PNGs through caller-owned output leases with eager parity, hostile lifecycle safety, independently qualified wire/decode behavior, and four-target portability.

**Verified:** 2026-07-23T20:01:09Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A public Indexed8 chunk factory uses the existing checked indexed machine rather than a second encoder. | ✓ VERIFIED | `PngChunkEncoder::new_indexed8` is public and directly calls `PngEncodeMachine::new_with_indexed` in `stream_encode.mbt:23-35`; that machine invokes indexed preflight before creating state and fixes Stored, filter-None, non-interlaced output in `stream_encode.mbt:929-958`. |
| 2 | Opaque and transparent Indexed8 sources drain to eager-identical bytes under zero, one-byte, and ragged caller leases, advancing only accepted bytes and retaining untouched tails. | ✓ VERIFIED | The lifecycle test drains both palette variants on `[0,1]`, `[1]`, and `[0,1,3,2,5]` schedules in `stream_encode_test.mbt:5029-5036`. Its drain helper checks bounded writes, accepted-only totals, untouched sentinel tails, and eager byte parity in `stream_encode_test.mbt:4982-5020`. The supplied all-target execution passed these behavioral tests. |
| 3 | Indexed8 chunk construction and terminals retain atomic, caller-owned semantics: invalid admission consumes no budget, completed and failed terminals are sticky, and released/split leases do not corrupt ownership. | ✓ VERIFIED | Construction calls preflight before returning an active encoder (`stream_encode.mbt:29-35`, `stream_encode.mbt:935-958`). `pull` returns sticky Finished/Failed results (`stream_encode.mbt:617-627`) and only increments state after `set` then `acknowledge` (`stream_encode.mbt:641-697`); acknowledgement advances CRC/state only for accepted bytes (`stream_encode.mbt:1519-1581`). Executed tests cover completed replay (`stream_encode_test.mbt:5011-5019`), released-lease failure replay (`5041-5065`), split parent/child ownership (`5071-5137`), and output/pixel/work atomic admission with unchanged budget snapshots (`5142-5172`). |
| 4 | Chunk-produced Indexed8 PNGs have independently checked framing/CRCs, retain the 89-byte opaque compatibility vector, decode through public RGB8/RGBA8 paths, and pass every supported target. | ✓ VERIFIED | The test-local CRC implementation is independent of PNG helpers (`encode_test.mbt:956-970`). Opaque chunk output is compared to eager bytes and the literal 89-byte vector, with IHDR→PLTE→IDAT→IEND CRC checks and public RGB decode assertions (`2849-2935`). Transparent output checks IHDR→PLTE→tRNS→IDAT→IEND/CRCs and public RGBA palette/alpha values (`2937-2977`). The supplied ordinary package command completed in 187.3 s with exit 0 and 279/279 passing on wasm, wasm-gc, js, and native. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_encode.mbt` | `PngChunkEncoder::new_indexed8` direct shared-machine adapter | ✓ VERIFIED | Exists and substantive; public factory is at lines 23-35, shared preflight/profile construction at 929-958, and the existing acknowledgement-safe pull path is at 613-700. |
| `modules/mb-image/png/stream_encode_test.mbt` | Hostile lease, ownership, terminal, and atomic-admission evidence | ✓ VERIFIED | Exists and substantive; Indexed8 behavioral coverage is at 4917-5172 and is exercised by the supplied all-target package run. |
| `modules/mb-image/png/encode_test.mbt` | Independent wire/CRC, compatibility, and public-decode evidence | ✓ VERIFIED | Exists and substantive; independent CRC helper is at 956-985 and public opaque/transparent chunk qualification is at 2849-2977. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PngChunkEncoder::new_indexed8` | `PngEncodeMachine::new_with_indexed` | Direct construction | ✓ WIRED | Direct call at `stream_encode.mbt:29-30`; the callee begins indexed preflight at `935-938`. |
| `PngChunkEncoder::pull` | Caller-owned lease | write → acknowledgement → state advance | ✓ WIRED | `destination.set` precedes `machine.acknowledge` at `661-684`; `acknowledge` advances CRCs and emitted state at `1530-1580`. |
| Chunk-produced Indexed8 bytes | Test-local parser and `PngDecoder` | Independent structural assertions and public decode | ✓ WIRED | `png_indexed_chunk_drain` invokes the public chunk constructor at `encode_test.mbt:2851-2879`; both outputs feed CRC/frame checks and `@codec.ImageDecoder::decode` at `2911-2934` and `2947-2977`. |

`gsd-tools verify.key-links` reports these plan links as unparseable because its current adapter expects file paths in `from`; the manual source trace above verifies the actual symbol-level contracts.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `stream_encode.mbt` | `machine` / emitted PNG bytes | `PngIndexedImage` → indexed preflight frame facts → `PngEncodeMachine` → caller lease | Yes — source, frame, CRC, and cursor state are held by the shared machine | ✓ FLOWING |
| `encode_test.mbt` | `bytes` | Public `PngChunkEncoder::new_indexed8` drained through caller leases | Yes — the same bytes are compared to eager output, parsed, and handed to the public decoder | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| All Indexed8 lifecycle, wire, decode, compatibility, and portability tests | `moon -C modules/mb-image test png --target all --frozen --target-dir D:\source\moonbit-foundation-v019\.moon-phase78-main` | Supplied execution evidence: exit 0 in 187.3 s; 279/279 tests passed on wasm, wasm-gc, js, and native. Verifier confirmed the target directory is absent afterward. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| INDEX-04 | `78-01-PLAN.md` | Caller-buffered indexed output shares the bounded layout machine, is eager-identical under hostile capacities, preserves lease ownership, and retains sticky terminals. | ✓ SATISFIED | Truths 1-3; direct adapter, acknowledgement trace, and executed hostile/terminal/atomic tests. |
| INDEX-05 | `78-01-PLAN.md` | Independent indexed wire/decode vectors, hostile lifecycle evidence, frozen legacy compatibility, and ordinary full PNG package coverage on four targets. | ✓ SATISFIED | Truth 4; independent CRC/frame oracle, 89-byte vector, public RGB/RGBA decoding, and supplied 279/279 four-target execution. |

No Phase 78 requirement is orphaned: the plan declares both IDs mapped to Phase 78 in `REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hard-coded-empty-output marker in the three Phase 78 files. | ℹ️ Info | No audit-blocking implementation debt found. |

### Disconfirmation Pass

The likely failure modes were separately checked: a thin but orphaned constructor (direct call and test consumers found), progress that advances before a lease accepts data (source order and accepted-only behavioral tests found), and wire tests that merely reuse encoder internals (test-local CRC parser plus public generic decoder found). No partial requirement, misleading test path, or uncovered phase error path remained after the all-target behavioral evidence.

### Gaps Summary

None. The source implementation, lifecycle/wiring tests, independent wire/decode tests, compatibility vector, and supplied four-target execution evidence establish the Phase 78 goal.

---

_Verified: 2026-07-23T20:01:09Z_
_Verifier: the agent (gsd-verifier)_
