---
phase: 61-portable-grayalpha8-adam7-public-evidence
verified: 2026-07-23T04:29:27Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 61: Portable GrayAlpha8 Adam7 Public Evidence Verification Report

**Phase Goal:** Library users have independent public proof that GrayAlpha8 Adam7 output is pass-faithful, caller-buffered-safe, compatible with frozen routes, and portable on every supported target.
**Verified:** 2026-07-23T04:29:27Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A public non-symmetric all-seven-pass vector proves literal Type-4/8 `G,A` wire data and decodes through straight-RGBA8 `(G,G,G,A)` canonicalization. | ✓ VERIFIED | `png_encode_graya8_adam7_expected_passes` independently enumerates all seven Adam7 geometries and emits different `0x20+sample` / `0xa0+sample` G,A pairs. `PNG GrayAlpha8 Adam7 eager pass profile` checks IHDR depth 8, type 4, Adam7 1, extracts exactly 61 Stored/None inflated scanline bytes with the bounded public parser, compares them to that oracle, then decodes all 25 pixels through `ImageDecoder::decode(PngDecoder::new(), ...)`. The focused test passed. |
| 2 | Fresh zero-capacity, one-byte, and ragged caller-buffer schedules remain eager-byte-identical, report accepted-only progress, preserve untouched lease tails, and retain sticky terminal outcomes. | ✓ VERIFIED | `png_graya8_adam7_chunk_drain` constructs fresh eager and chunk peers per invocation, proves a zero-length sublease of a one-byte `Z` owner returns `NeedOutput` with zero progress, appends only `written()` bytes, checks accepted-only totals and every remaining `Z` tail, then checks a later seven-byte sentinel lease remains untouched and `Finished`. The six-pair matrix covers Stored/FixedOrStored/DynamicOrFixedOrStored × None/Adaptive under `[0,1]`, `[1]`, and the locked ragged schedule; the focused tracer and full schedule tests passed. |
| 3 | Frozen non-interlaced GrayAlpha8 and legacy Gray8, Gray16, GrayAlpha16, RGB8, and straight-RGBA8 PNG vectors remain unchanged, and the full PNG package passes on js, wasm, wasm-gc, and native. | ✓ VERIFIED | Both eager and chunk frozen-vector tests retain literal anchors for all six formats. Their GrayAlpha16 constants independently decode to the identical 77 bytes (depth 16, type 4, IHDR interlace byte 0), and default/configured routes equal that literal. `moon -C modules/mb-image test png --target all --frozen` passed 227 tests on each supported target. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode_test.mbt` | Public GrayAlpha8 Adam7 wire/inflate/decode conformance and eager frozen-vector evidence | ✓ VERIFIED | L1 exists; L2 is substantive (`png_encode_graya8_adam7_expected_passes`, bounded Stored-block parser, public decoder helper, literal compatibility matrix); L3 is wired into the named eager profile and frozen-vector tests. `verify.artifacts` passed it. |
| `modules/mb-image/png/stream_encode_test.mbt` | Public hostile caller-drain matrix and chunk frozen-vector evidence | ✓ VERIFIED | L1 exists; L2 has real fresh-peer, lease, progress, tail, terminal, and matrix assertions; L3 is wired into named tracer/schedule and frozen-vector tests. `verify.artifacts` passed it. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PngEncoder::new_graya8_with_all_strategies` | `png_encode_gray16_public_stored_scanlines` | Stored/None public stream → bounded Stored-block extraction → independent seven-pass oracle | ✓ WIRED | The eager test creates the public encoder result, passes the resulting `bytes` to the parser with expected length 61, and compares the result to the test-local all-seven-pass G,A array. |
| `PngDecoder::new` | `png_encode_graya8_adam7_public_decode_is_canonical` | Completed public PNG bytes → `ImageDecoder::decode` → all-pixel RGBA8 checks | ✓ WIRED | The eager profile test calls the helper on completed output; the helper calls the public decoder and checks descriptor plus R/G/B/A for all 25 source coordinates. |
| `PngChunkEncoder::new_graya8_with_all_strategies` | `PngChunkEncoder::pull` | Fresh zero/one/ragged sentinel-backed leases per strategy/filter pair | ✓ WIRED | The drain helper creates the public caller-buffered encoder and calls `pull` first with the zero-length sublease, then each scheduled lease, and finally the terminal sentinel lease. |
| `png_graya8_adam7_chunk_drain` | `PngEncoder::new_graya8_with_all_strategies` | Separately constructed eager peer provides completed-stream identity oracle | ✓ WIRED | Its eager helper encodes a separate fresh image through the public eager all-strategy selector before the chunk source is constructed. |

`verify.key-links` cannot evaluate these declarative component-name links because its current query requires file paths for `from`; manual source traces above verified all four links rather than treating that tool limitation as a broken connection.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `encode_test.mbt` | Stored Adam7 scanlines and decoded pixels | Fresh non-symmetric 5×5 public GrayAlpha8 image → public eager encoder → complete PNG bytes | Yes — expected wire samples and decoded channels are coordinate-derived (`G=0x20+sample`, `A=0xa0+sample`), not encoder-derived. | ✓ FLOWING |
| `stream_encode_test.mbt` | Eager peer bytes, chunk accepted prefixes, pull totals, and lease tails | Independently fresh public eager/chunk encoders and caller-owned `Z` leases | Yes — each of the 18 schedule executions drains actual output and compares its completed byte stream to a fresh eager peer. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Independent all-seven-pass wire/inflate and public RGBA8 canonicalization | `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 eager pass profile'` | 1 passed, 0 failed | ✓ PASS |
| Direct hostile lease tracer | `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 public hostile tracer'` | 1 passed, 0 failed | ✓ PASS |
| Six-pair zero/one/ragged hostile-schedule matrix | `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 public hostile schedules'` | 1 passed, 0 failed | ✓ PASS |
| Eager frozen vector anchors | `moon -C modules/mb-image test png --target native --frozen -f 'PNG filter strategy eager frozen compatibility vectors'` | 1 passed, 0 failed | ✓ PASS |
| Chunk frozen vector anchors | `moon -C modules/mb-image test png --target native --frozen -f 'PNG filter strategy chunk frozen compatibility vectors'` | 1 passed, 0 failed | ✓ PASS |
| Full portable package qualification | `moon -C modules/mb-image test png --target all --frozen` | 227 passed, 0 failed on wasm; 227 on wasm-gc; 227 on js; 227 on native | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 61 declares no probe, no `scripts/**/probe-*.sh` exists, and no plan/summary documents a probe path.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GRAYA8A7-03 | `61-01-PLAN.md`, `61-02-PLAN.md` | Public non-symmetric wire/decode proof, hostile fresh caller schedules, frozen vectors, and all-target PNG qualification. | ✓ SATISFIED | The three roadmap truths above have direct source, data-flow, and passing runtime evidence. Both Phase 61 plans declare the requirement; no Phase-61 requirement is orphaned. |

### Scope and Anti-Pattern Audit

| File / Scope | Finding | Severity | Impact |
| --- | --- | --- | --- |
| Phase 61 commit range `edd193c..HEAD` | Production diff is limited to `encode_test.mbt` and `stream_encode_test.mbt`, plus Phase 61 planning artifacts and `STATE.md`; no production PNG, decoder, FFI, wrapper, staging, generated fixture, or copied-source file changed. | ℹ️ Verified | The evidence uses the existing public PNG paths only. |
| Phase-added test hunks | No `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded-empty-output pattern found. | ℹ️ None | No debt-marker blocker or test stub found. |
| `git diff --check edd193c..HEAD` | Three trailing-whitespace notices occur only in Phase 61 research Markdown. | ℹ️ Documentation hygiene | Not a production/test behavior gap and does not affect the phase goal. |

### Disconfirmation Pass

- Partial-requirement check: the raw-wire proof does not merely compare two encoder paths; it compares a 61-byte extracted Stored/None payload to an independent all-seven-pass G,A enumerator, then separately exercises the public decoder.
- Misleading-test check: the chunk matrix does not reuse a completed encoder. Each strategy/filter/schedule invocation constructs a new source and encoder, checks the zero-length lease independently, and uses a separately constructed eager peer.
- Uncovered-error-path check: no Phase 61 error outcome is claimed. The phase's terminal invariant is positive sticky `Finished`; that path is directly exercised by a post-finish seven-byte sentinel pull. Failure/replay semantics remain covered by the previously verified Phase 60 tests.

### Human Verification Required

None. Every behavior-dependent roadmap truth has a named passing runtime test, including the full supported-target package command.

### Gaps Summary

No gaps found. The implementation supplies independent public wire/decode evidence, fresh six-pair caller-buffer safety evidence, literal frozen compatibility anchors, and successful unwrapped qualification on all four supported targets.

---

_Verified: 2026-07-23T04:29:27Z_
_Verifier: the agent (gsd-verifier)_
