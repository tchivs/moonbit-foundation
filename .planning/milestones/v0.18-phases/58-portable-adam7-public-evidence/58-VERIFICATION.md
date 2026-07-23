---
phase: 58-portable-adam7-public-evidence
verified: 2026-07-23T10:15:00+08:00
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 58: Portable Adam7 Public Evidence Verification Report

**Phase Goal:** Library users have independent public proof that GrayAlpha16 Adam7 PNG output is pass-faithful, caller-buffered-safe, compatible with frozen routes, and portable on every supported target.

**Verified:** 2026-07-23T10:15:00+08:00  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A public Stored/None GrayAlpha16 Adam7 PNG exposes literal Type-4/16 `Ghi,Glo,Ahi,Alo` data with correct seven-pass placement. | ✓ VERIFIED | `encode_test.mbt:214-272` independently creates a non-symmetric little-endian 5×5 source and seven-pass oracle. `:1226-1242` uses public `PngEncoder::new_graya16_with_all_strategies`, checks IHDR depth/type/interlace, and compares the complete bounded 111-byte Stored raster. Named native test passed. |
| 2 | The public decoder canonicalizes every GrayAlpha16 Adam7 source pixel to straight RGBA8 high bytes. | ✓ VERIFIED | `encode_test.mbt:582-614` decodes emitted bytes with public `PngDecoder`, requires 5×5 U8/Rgba, and checks all 25 pixels as `(Ghi,Ghi,Ghi,Ahi)`. The wire/decode named native test passed. |
| 3 | Every legal compression/filter pair retains public Type-4/16 Adam7 framing and decode behavior. | ✓ VERIFIED | `encode_test.mbt:1317-1391` enumerates Stored/FixedOrStored/DynamicOrFixedOrStored × None/Adaptive, constructs each through the public all-strategy factory, checks framing, then applies the complete decoder oracle. |
| 4 | Fresh public chunk encoders are byte-identical to fresh eager output under zero, one-byte, and ragged caller leases, with accepted-only progress, untouched tails, and sticky completion. | ✓ VERIFIED | `stream_encode_test.mbt:3517-3613` creates a new public all-strategy chunk encoder per schedule and pair; it directly checks the zero-capacity `NeedOutput` lease, reported-prefix accounting, sentinel tails, eager equality, and a later zero-write `Finished` lease for all six pairs. Named native hostile-schedule test passed. |
| 5 | Frozen legacy non-interlaced vectors stay unchanged and all public PNG evidence passes on js, wasm, wasm-gc, and native without implementation-scope leakage. | ✓ VERIFIED | Eager literals/method-0 checks are in `encode_test.mbt:979-1058`; chunk equivalents are in `stream_encode_test.mbt:1488-1579`. The authoritative serialized `moon -C modules/mb-image test png --target all --frozen` capture supplied by the orchestrator exited 0 with 219/219 on wasm, wasm-gc, js, and native. `git diff --check <phase-58-base>..HEAD` exited 0 and the phase range has exactly two functional paths. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode_test.mbt` | Public Adam7 wire/decode, selector, and frozen eager evidence | ✓ VERIFIED | Substantive independent fixture/oracle, bounded parser, public decoder assertions, all-selector loop, and literal legacy vectors; no debt markers found. |
| `modules/mb-image/png/stream_encode_test.mbt` | Public hostile-schedule and frozen chunk evidence | ✓ VERIFIED | Substantive fresh-encoder drain helper plus all-selector matrix, accepted-prefix/tail/sticky assertions, and literal legacy vectors; no debt markers found. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `encode_test.mbt` | public eager encoder and `PngDecoder` seams | `PngEncoder::new_graya16_with_all_strategies` → `ImageEncoder::encode`; `PngDecoder::new` → `ImageDecoder::decode` | ✓ WIRED | The emitted bytes, not a private traversal helper, feed the bounded wire parser and all-pixel public decoder check. |
| `stream_encode_test.mbt` | `stream_encode.mbt` public chunk seam | `PngChunkEncoder::new_graya16_with_all_strategies` → caller-owned `pull` leases | ✓ WIRED | The helper consumes reported public outcomes and compares its assembled accepted prefixes to separately constructed public eager bytes. |
| Both evidence files | PNG package test runner | `moon -C modules/mb-image test png --target all --frozen` | ✓ WIRED | The ordinary package runner completed 219 tests on each supported target in the authoritative final capture. |

### Data-Flow Trace

Not applicable: these are deterministic library tests, not dynamic UI/data-rendering artifacts. Their data flows were nevertheless traced from non-symmetric source fixture → public encoder bytes → bounded test parser/public decoder and from public chunk `pull` leases → accepted prefix → eager-byte comparison.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Literal public Adam7 wire plus high-byte decode | `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 public wire and decode'` | 1/1 passed | ✓ PASS |
| All-selector hostile caller-buffer schedules | `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 public hostile schedules'` | 1/1 passed | ✓ PASS |
| Frozen eager vectors | `moon -C modules/mb-image test png --target native --frozen -f 'PNG filter strategy eager frozen compatibility vectors'` | 1/1 passed | ✓ PASS |
| Frozen chunk vectors | `moon -C modules/mb-image test png --target native --frozen -f 'PNG filter strategy chunk frozen compatibility vectors'` | 1/1 passed | ✓ PASS |
| Portable package proof | `moon -C modules/mb-image test png --target all --frozen` | orchestrator's direct final capture: wasm, wasm-gc, js, native each 219/219 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- |
| GRAYA16A7-03 / D-01 | 58-01 | Public non-symmetric Adam7 Type-4/16 wire/pass evidence | ✓ SATISFIED | Independent 5×5 fixture and exact 111-byte seven-pass expectation at `encode_test.mbt:214-272`, asserted through public output at `:1226-1242`. |
| GRAYA16A7-03 / D-02 | 58-01 | Documented straight-RGBA8 high-byte decode canonicalization | ✓ SATISFIED | Public decoder checks every position and channel at `encode_test.mbt:582-614`. |
| GRAYA16A7-03 / D-03 | 58-02 | All six fresh hostile schedules, progress, tails, sticky terminal | ✓ SATISFIED | Matrix and drain invariants at `stream_encode_test.mbt:3517-3613`; named test passed. |
| GRAYA16A7-03 / D-04 | 58-01, 58-02 | Frozen Gray8, Gray16, GrayAlpha8, RGB8, straight-RGBA8 method-0 bytes | ✓ SATISFIED | Exact literal comparisons plus IHDR interlace byte checks in eager and chunk vector tests. |
| GRAYA16A7-03 / D-05 | 58-03 | One public all-target package gate and confined public-test scope | ✓ SATISFIED | Final captured four-target 219/219 run; phase-base range lists only the two functional test files, no production/API/FFI/script/fixture/target/source-copy additions, and `git diff --check` is clean. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, or placeholder marker in either Phase 58 functional test file. | — | No blocker or warning. |

The previously reported whitespace warning in `58-REVIEW.md` was falsified against the current state: `git diff --check <phase-58-base>..HEAD` now exits 0 after commit `3398613`; no phase-range whitespace gap remains.

### Human Verification Required

None. The phase delivers deterministic public-library behavior; the required observable outputs, byte-level invariants, caller-buffer state transitions, frozen vectors, and target matrix all have automated evidence.

### Gaps Summary

No gaps found. The implementation is confined to the two planned public PNG test files; planning/verification records are the only other Phase 58 paths. No production route, private traversal assertion, Big-endian admission, staging buffer, target branch, release wrapper, fixture, copied source, debug, recover, or probe artifact was introduced.

---

_Verified: 2026-07-23T10:15:00+08:00_  
_Verifier: gsd-verifier_
