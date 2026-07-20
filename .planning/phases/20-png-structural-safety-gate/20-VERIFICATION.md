---
phase: 20-png-structural-safety-gate
verified: 2026-07-20T15:36:09Z
status: gaps_found
score: 3/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A structurally valid PNG whose byte length exactly equals max_input_bytes reaches the Phase-20 capability result."
    status: failed
    reason: "The strict-EOF probe uses the ordinary consuming read helper. That helper rejects consumed + 1 before attempting the reader operation, so a complete stream at its declared input ceiling fails with input-bytes=max+1 instead of accepting EOF."
    artifacts:
      - path: "modules/mb-image/png/structural.mbt"
        issue: "_png_require_eof calls _png_read_one; its pre-read limit check treats the non-consuming EOF probe as one more input byte."
    missing:
      - "Perform EOF detection without advancing or charging the consumed input count, and add an all-target boundary test where a valid 57-byte structural PNG has max_input_bytes=57."
  - truth: "The generated hostile corpus proves every planned structural, metadata, resource, and caller-state guard through PngDecoder.decode."
    status: failed
    reason: "The corpus has only 15 cases and omits the plan-required duplicate/misordered IHDR, unsupported IHDR fields, ancillary CRC, opaque-preservation, and width/height/pixels/input/output/work/allocation/budget cases. Generated vectors are not used by png_test.mbt as specified."
    artifacts:
      - path: "fixtures/png/cases.json"
        issue: "Only 15 vectors; the required categories and every resource/budget ceiling are absent."
      - path: "modules/mb-image/png/png_test.mbt"
        issue: "Contains no _generated_png_structural_cases reference; generated cases are driven only by structural_wbtest.mbt."
    missing:
      - "Expand the generated cases and direct decoder assertions to cover every Plan 20-01/20-02 category, including CRC-before-discard and immutable Budget/Diagnostics for every limit/preflight rejection."
      - "Wire the generated vector loop into the declared public test layer, or revise the plan contract with an accepted override."
  - truth: "The isolated Png quality lane fails closed on actual public API, import, target, source-order, and file-inventory drift."
    status: failed
    reason: "Invoke-PngQualityLane only reads selected JSON fields, regenerates vectors, and runs package tests. No Png-specific validator or scoped negative fixtures exist in Assert-Policy.ps1, so a newly exposed streaming API/encoder is not checked against policy."
    artifacts:
      - path: "scripts/quality/Invoke-MoonQuality.ps1"
        issue: "Png lane has no actual compiler-interface or negative-policy stage."
      - path: "scripts/quality/Assert-Policy.ps1"
        issue: "No Png-specific policy/negative-fixture implementation is present."
    missing:
      - "Add and invoke Png policy/interface and scoped negative checks that inspect the real package surface, imports, targets, source order, and file inventory."
---

# Phase 20: PNG Structural Safety Gate Verification Report

**Phase Goal:** Library users can safely identify and structurally validate the supported PNG subset before image output is exposed.
**Verified:** 2026-07-20T15:36:09Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can non-consumingly classify a PNG prefix as `Match`, `NoMatch`, or `NeedMore(8)` within the probe ceiling. | ✓ VERIFIED | `png.mbt` implements the eight-byte ByteView-only comparison and checks `max_probe_bytes` before returning; no `Reader` is accepted by `probe`. |
| 2 | Invalid framing, order, CRC, type form, unsupported chunks, IEND form, and trailing input receive typed rejection. | ✓ VERIFIED | `structural.mbt` uses a reader-driven state machine, type-form gate, streaming CRC comparison, IHDR/IDAT/IEND state checks, metadata policy branch, and strict EOF. The all-target suite executes real malformed cases. |
| 3 | Checked input, geometry, pixel, output, work, allocation, Budget, and metadata policy are enforced before image exposure. | ✗ FAILED | Exact `max_input_bytes` is not honored for a complete structural transport because the EOF probe charges a hypothetical extra byte; see Gap 1. |
| 4 | Validation uses bounded private storage and a valid Phase-20 transport can only terminate in `deflate-and-raster-pending`, never a `DecodeResult`. | ✓ VERIFIED | The validator creates a one-byte `OwnedBytes` scratch; only bounded 4-byte type and 13-byte IHDR arrays are accumulated. `PngDecoder.decode` unconditionally returns `Err(capability_unavailable(...))` after validation and contains no image construction or diagnostics mutation. |
| 5 | Generated hostile vectors provide the complete all-target behavioral proof promised by both Phase 20 plans. | ✗ FAILED | `cases.json` has 15 cases and misses many stated categories; the generated loop is absent from `png_test.mbt`. |
| 6 | The Png lane is the promised fail-closed policy/public-surface gate. | ✗ FAILED | The lane passes generator freshness and tests but has no Png-specific actual-interface or scoped negative-policy validation. |

**Score:** 3/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Sole public `PngDecoder` probe/decode seam | ✓ VERIFIED | Substantive 56-line trait implementation; calls `_png_validate_transport` before the sole terminal capability error; compiled on four targets. |
| `modules/mb-image/png/structural.mbt` | Fixed-scratch structural validator, CRC and state enforcement | ✓ VERIFIED | 451-line private parser with one-byte I/O scratch, checked counters/arithmetic, CRC-32, profile/resource preflight, and terminal framing state. |
| `fixtures/png/cases.json` | Provenance-tagged hostile structural corpus | ⚠️ INCOMPLETE | Exists, is regenerated and digest-checked, but its 15 vectors do not meet either plan's required coverage. |
| `modules/mb-image/png/generated_vectors.mbt` | Executable generated fixture data | ⚠️ PARTIAL | Generator link is real and checked fresh; coverage inherits the incomplete JSON corpus. |
| `policy/foundation.json` / Png lane | Exact package inventory and fail-closed policy guard | ⚠️ PARTIAL | The JSON record is present, but no Png-specific actual-surface/negative enforcement is wired into the lane. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `structural.mbt` | `_png_validate_transport` | ✓ WIRED | `PngDecoder.decode` calls the private transport validator and returns before capability on its error. |
| `Generate-PngStructuralVectors.ps1` | `generated_vectors.mbt` | deterministic Check-mode rendering | ✓ WIRED | Fresh `-Check` passed and its output function matches the generated helper. |
| `png_test.mbt` | generated vectors / fixture cases | public decoder vector loop | ✗ NOT_WIRED | The Plan 20-02 link is absent: zero helper references in `png_test.mbt`; only `structural_wbtest.mbt` references it. |
| `Invoke-MoonQuality.ps1` | actual PNG public-policy checks | Png lane | ✗ NOT_WIRED | The lane reads JSON but does not invoke a Png policy/interface or negative-fixture check. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `png.mbt` / `structural.mbt` | forward reader bytes | caller-owned `@io.Reader` via `_png_read_one` | Yes; every parser byte read uses the single helper | ✓ FLOWING |
| generated vector tests | `(id, bytes, expected)` | `fixtures/png/cases.json` via generator | Yes, but the source corpus is incomplete | ⚠️ PARTIAL |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generated corpus is fresh and manifest digest is valid | `pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` | Passed | ✓ PASS |
| PNG package executes on every supported target | `moon -C modules/mb-image test png --target all --frozen` | 8/8 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Isolated PNG lane is runnable | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Passed; reran freshness and 8/8 four-target tests | ✓ PASS |
| Exact input ceiling accepts a valid transport | source audit of `_png_read_one` + `_png_require_eof` | Fails deterministically by construction at `consumed == max_input_bytes` | ✗ FAIL |

### Probe Execution

Step 7c: SKIPPED — no phase-declared or conventional `probe-*.sh` executable was found.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNG-01 | 20-01, 20-02 | Bounded non-consuming signature probe with deterministic outcomes | ✓ SATISFIED | ByteView-only eight-byte probe and ceiling check in `png.mbt`; four-target package tests pass. |
| PNG-02 | 20-01, 20-02 | Typed framing/order/CRC/unsupported/IEND/trailing rejection | ✓ SATISFIED | Reader-driven state machine and typed contexts in `structural.mbt`; generated malformed tests execute through `PngDecoder.decode`. Corpus completeness remains a plan gap. |
| PNG-03 | 20-01, 20-02 | Checked input/output/resource/metadata enforcement before image output | ✗ BLOCKED | Exact input-limit boundary incorrectly rejects an otherwise valid complete stream. No later phase explicitly schedules this structural-limit repair. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | 59-69, 353 | Consuming input-limit helper reused for an EOF probe | 🛑 Blocker | Converts a valid exact-limit transport into a resource error. |
| `fixtures/png/cases.json` | 1-19 | Materially incomplete generated coverage against explicit plan categories | 🛑 Blocker | Four-target green tests do not prove all required structural/resource guards. |
| `scripts/quality/Invoke-MoonQuality.ps1` | 765-775 | JSON-only Png policy check; no Png negative/interface enforcement | 🛑 Blocker | Public-surface drift can pass the isolated quality lane. |

### Gaps Summary

The parser is substantive and most of the requested structural safeguards are genuinely implemented and wired. The phase is nevertheless not achieved as a completed safety gate: a valid transport at the declared input limit is rejected by the EOF implementation, and the test/policy evidence claimed by both plans does not exist. The later PNG phases own DEFLATE, raster output, and encoding—not these structural-limit, corpus, or policy-lane repairs—so none of the gaps are deferred.

The roadmap also still records only one of two plans executed and the phase directory has no `20-01-SUMMARY.md`. Commits for the 20-01 work exist, but this workflow-state inconsistency is informational; the blockers above are based on the current source and test wiring, not that missing summary.

---

_Verified: 2026-07-20T15:36:09Z_
_Verifier: the agent (gsd-verifier)_
