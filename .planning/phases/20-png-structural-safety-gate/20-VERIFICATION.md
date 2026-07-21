---
phase: 20-png-structural-safety-gate
verified: 2026-07-21T03:57:39Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 6/6
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 20: PNG Structural Safety Gate Verification Report

**Phase Goal:** Library users can safely identify and structurally validate the supported PNG subset before image output is exposed.
**Verified:** 2026-07-21T03:57:39Z
**Status:** passed
**Re-verification:** Yes — independent audit after Plan 20-05

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can non-consumingly classify an eight-byte PNG prefix as `Match`, `NoMatch`, or `NeedMore(8)` within the probe ceiling. | ✓ VERIFIED | `PngDecoder::probe` in `png.mbt` examines only its `ByteView`, rejects an over-limit prefix before comparison, and the all-target public probe matrix asserts `NeedMore(8)`, `NoMatch`, `Match`, and `probe-bytes`. |
| 2 | Invalid framing, type form, order, CRC, unsupported semantic/critical chunks, IEND form, and trailing input receive deterministic typed rejection before a `DecodeResult` can be returned. | ✓ VERIFIED | `_png_read_stream_transport` validates signature/IHDR/preflight, chunk length/type form, and pre-IDAT metadata; `PngIdatSource::next_byte` authenticates every IDAT CRC and prohibits non-contiguous IDAT; `PngIdatSource::finish` validates post-IDAT order, IEND CRC/form, and `_png_require_eof` before the only `DecodeResult::new`. The fresh 89-case public and white-box loops execute these routes on all four targets. |
| 3 | Checked dimensions, pixels, input, output, work, allocation, Budget, and metadata policy reject safely before an image result is visible. | ✓ VERIFIED | `_png_preflight_ihdr` / `_png_output_budget_for` use checked arithmetic, `CodecLimits`, and `Budget::child` before `OwnedImage::new_operation`; unknown ancillary metadata is CRC-authenticated then rejected when preservation is requested. Generated resource and immutable-state cases execute through `PngDecoder`; rejected cases are asserted as `Err`, so no `DecodeResult` is exposed. |
| 4 | Later decode, encoder, and colour work has not bypassed the Phase-20 structural boundary. | ✓ VERIFIED | The sole public decoder entry first calls `_png_read_stream_transport`. Later Phase 21 retained the structural parser while moving physical-IDAT completion to `PngIdatSource::finish`; Phases 22–25 added downstream encode/colour behavior. `_png_inflate_zlib_to_raster` calls `finish()` before `png.mbt` can construct `DecodeResult`, preserving CRC/IEND/EOF as terminal guards. |
| 5 | The hostile structural corpus is generated from its source and still executes at both required boundaries. | ✓ VERIFIED | Fresh `Generate-PngStructuralVectors.ps1 -Check` passed with 89 P+W cases. `cases.json` has 89 unique IDs and the generator requires `routes.public` plus `routes.whitebox`; it regenerated neither 89-row MoonBit table. `png_test.mbt` and `structural_wbtest.mbt` each loop their corresponding table through `PngDecoder`. |
| 6 | The isolated Png policy lane remains fail-closed and portable. | ✓ VERIFIED | Fresh `Invoke-MoonQuality.ps1 -Lane Png` passed foundation/interface policy, scoped negative fixtures, exact inventory, both vector freshness stages, colour evidence, four-target PNG tests, and the exact isolation trace. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public probe/decode boundary | ✓ VERIFIED | Substantive `PngDecoder` implementation; its only public decode route invokes private structural transport before allocation/raster work. The later public `PngEncoder` is Phase 22 scope and is policy-accounted, not a Phase-20 bypass. |
| `modules/mb-image/png/structural.mbt` | Private framing, CRC, ordering, metadata, resource, and EOF guards | ✓ VERIFIED | Substantive private parser with fixed reader scratch, checked byte metering, type-form validation, CRC scope, IHDR/preflight, `PngIdatSource`, terminal IEND/EOF checks, and no public parser API. |
| `fixtures/png/cases.json` | Provenance-tagged structural corpus | ✓ VERIFIED | 89 unique generated-source records, each with deterministic expected outcome, limits, Budget profile, immutable-state flag, and both routes. |
| `scripts/fixtures/Generate-PngStructuralVectors.ps1` | Deterministic corpus generator/checker | ✓ VERIFIED | Fresh check validated case schema/IDs/routes, bytes, manifest identity/digest, and exact generated output; exited 0 with `89 P+W cases`. |
| `modules/mb-image/png/generated_vectors*.mbt` | Executable public and white-box structural tables | ✓ VERIFIED | Each generated table contains 89 `PngGeneratedCase` rows and is consumed by the corresponding test loop. |
| `scripts/quality/Assert-Policy.ps1` / `scripts/quality/Invoke-MoonQuality.ps1` | Isolated Png policy gate | ✓ VERIFIED | Live lane passed exact interface/import/target/source/inventory checks and scoped negative fixtures; all-target checks passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `png.mbt` | `structural.mbt` | `_png_read_stream_transport` before descriptor/allocation | ✓ WIRED | `PngDecoder::decode` returns immediately on transport failure; no alternate public decode seam was found. |
| `PngIdatSource` | terminal PNG framing | `next_byte` CRC and `finish()` tail traversal | ✓ WIRED | `next_byte` checks each completed IDAT CRC; `finish()` rejects resumed IDAT, validates IEND CRC/form, and calls strict EOF. `_png_inflate_zlib_to_raster` invokes `finish()` before `DecodeResult::new`. |
| `cases.json` | generated public/private vectors | `Generate-PngStructuralVectors.ps1 -Check` | ✓ WIRED | Generator requires P+W routes and exact output; fresh check passed. |
| generated tables | `PngDecoder` | legacy Phase-20 public and white-box loops | ✓ WIRED | Both loops construct readers and call `ImageDecoder::decode(PngDecoder)`, not parser helpers or ID-only checks. |
| Png lane | policy/generator/tests | `Assert-PngLaneIsolation` | ✓ WIRED | Fresh lane completed the exact seven-stage Png trace without broad required/release or QOI routes. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| structural transport | Forward-reader bytes and consumed count | Caller-owned `@io.Reader` through `_png_read_one` | Yes — signature, headers, type, payload, CRC, and EOF all use the metered reader. | ✓ FLOWING |
| IDAT lifecycle | `PngIdatSource` | Authenticated physical IDAT chunks | Yes — bytes are CRC-accounted while DEFLATE consumes them; `finish()` consumes the remaining PNG tail before result creation. | ✓ FLOWING |
| generated test data | `PngGeneratedCase` | `cases.json` via deterministic generator | Yes — 89 source records feed matching public and white-box decoder loops. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Structural corpus remains current and provenance-valid | `pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` | `PNG structural vector generation/check passed (89 P+W cases).` | ✓ PASS |
| Probe, framing, CRC/order/IDAT/IEND/EOF, metadata, and limits execute on supported targets | `moon -C modules/mb-image test png --target all --frozen` | 40/40 passed on wasm, wasm-gc, js, and native. | ✓ PASS |
| Isolated Png package/policy evidence remains fail-closed | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Exit 0; all seven Png stages and lane isolation passed. | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no Phase-20 executable probe was declared and no conventional `scripts/*/tests/probe-*.sh` file exists. The generator, package tests, and isolated policy lane above are the declared runnable checks.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNG-01 | 20-01, 20-02, 20-05 | Bounded non-consuming deterministic PNG probe | ✓ SATISFIED | Public ByteView-only probe matrix and fresh four-target test pass. |
| PNG-02 | 20-01, 20-02, 20-05 | Typed framing/order/CRC/semantic/IEND/trailing rejection | ✓ SATISFIED | Live stream parser plus 89 P+W structural matrix and all-target pass. |
| PNG-03 | 20-01, 20-02, 20-05 | Checked geometry/input/output/work/allocation/Budget/metadata policy before output | ✓ SATISFIED | Live checked preflight and generated limit/immutability assertions exercised through `PngDecoder`. |

The current v0.7 `REQUIREMENTS.md` supersedes these historical IDs with PNGCM requirements; Phase 20’s ROADMAP contract and its three declared plan requirements remain the authoritative traceability source for this re-verification. No orphaned Phase-20 requirement was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/quality/Assert-Policy.ps1` | 227 | Literal `placeholder` in a rejection policy | ℹ️ Info | The assertion rejects placeholder evidence; it is not a stub or debt marker. |
| — | — | No unreferenced `TBD`, `FIXME`, `XXX`, placeholder implementation, empty handler, or hardcoded visible-data stub in Phase-20 artifacts. | ℹ️ Info | No blocker or warning. |

### Audit Note

The Phase-20 source corpus retains its historical `deflate-and-raster-pending` expectation for structurally accepted rows. The current legacy public and white-box loops intentionally translate those rows to the downstream `zlib-truncated` outcome because Phase 21 now owns actual decoding. This does not weaken malformed structural cases: their category/code/context remain asserted, and successful decode behavior is separately covered by the later generated decode corpus. It is documented here as test-boundary context, not a Phase-20 gap.

### Gaps Summary

No Phase-20 gaps found. Structural parser state remains live ahead of the downstream decode pipeline, its deferred physical-IDAT tail checks run before the sole `DecodeResult` construction, and fresh corpus, all-target, and isolated-policy evidence all passed. Later decode, encoding, and colour extensions are downstream behavior and do not bypass the Phase-20 safety gate.

---

_Verified: 2026-07-21T03:57:39Z_
_Verifier: the agent (gsd-verifier)_
