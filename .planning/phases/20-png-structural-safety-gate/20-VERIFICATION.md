---
phase: 20-png-structural-safety-gate
verified: 2026-07-20T16:32:38Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/6
  gaps_closed:
    - "A structurally valid PNG whose byte length exactly equals max_input_bytes reaches the Phase-20 capability result."
    - "The generated hostile corpus proves every planned structural, metadata, resource, and caller-state guard through PngDecoder.decode."
    - "The isolated Png quality lane fails closed on actual public API, import, target, source-order, and file-inventory drift."
  gaps_remaining: []
  regressions: []
---

# Phase 20: PNG Structural Safety Gate Verification Report

**Phase Goal:** Library users can safely identify and structurally validate the supported PNG subset before image output is exposed.
**Verified:** 2026-07-20T16:32:38Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can non-consumingly classify a PNG prefix as `Match`, `NoMatch`, or `NeedMore(8)` within the probe ceiling. | ✓ VERIFIED | `PngDecoder::probe` accepts only the caller-owned `ByteView`, checks `max_probe_bytes` first, and delegates to an eight-byte comparison. The public probe test exercises `NeedMore(8)`, `NoMatch`, `Match`, and the `probe-bytes` limit on all four targets. |
| 2 | Invalid framing, order, CRC, type form, unsupported chunks, IEND form, and trailing input receive typed rejection. | ✓ VERIFIED | The private transport state machine enforces signature, type form, first/only IHDR, contiguous IDAT, CRC-before-policy, IEND, and strict EOF. The generated 89-case matrix contains header/order/payload/CRC/IEND/EOF/metadata rows, and both generated tables execute through `PngDecoder` on wasm, wasm-gc, js, and native. |
| 3 | Checked input, geometry, pixel, output, work, allocation, Budget, and metadata policy are enforced before image exposure. | ✓ VERIFIED | `_png_preflight_ihdr` uses checked arithmetic and `Budget::child`; the matrix includes exact/below input, width, height, pixels, shared output/image bytes, filtered output, work, allocation, and all inherited Budget envelopes. `PngDecoder::decode` returns only the pending capability error after validation, never a decode result. |
| 4 | Validation uses bounded private storage and a valid Phase-20 transport can only terminate in `deflate-and-raster-pending`, never a `DecodeResult`. | ✓ VERIFIED | The validator allocates one private byte of scratch and only captures a four-byte type or 13-byte IHDR. The public decoder handles every validator error before its sole terminal `CapabilityUnavailable("png-decode", "deflate-and-raster-pending")` return. |
| 5 | Generated hostile vectors provide the complete all-target behavioral proof promised by both Phase 20 plans. | ✓ VERIFIED | Fresh generator validation reports 89 P+W cases. Independent audit found 89 unique JSON IDs, 89 rows in each generated public/private table, `routes.public` and `routes.whitebox` on every source row, and real loops over both tables in `png_test.mbt` and `structural_wbtest.mbt`. |
| 6 | The Png lane is the promised fail-closed policy/public-surface gate. | ✓ VERIFIED | The Png lane runs actual interface, import, target, directory, allowlist, fixture, and four-target checks, plus scoped negative fixtures for import/target/interface/source-order/production-inventory/file-inventory drift. Its isolation assertion verifies the exact Png-only stage trace. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Sole public probe/decode seam | ✓ VERIFIED | Substantive public `PngDecoder`; no public streaming or encoder type; validator errors return before the sole capability terminal. |
| `modules/mb-image/png/structural.mbt` | Fixed-scratch structural validator | ✓ VERIFIED | 463-line private parser with metered reads, direct EOF probe, CRC/state/type/profile enforcement, checked resource preflight, and no image construction. |
| `fixtures/png/cases.json` | Provenance-tagged complete hostile corpus | ✓ VERIFIED | 89 unique records with expected typed outcome, options, limits, Budget profile, immutable-state flag, and P+W routes; generator validates IDs and manifest digest. |
| `scripts/fixtures/Generate-PngStructuralVectors.ps1` | Deterministic fixture generator/checker | ✓ VERIFIED | `-Check` regenerated neither table and confirmed schema, bytes, required IDs, profiles, provenance, and digest. |
| `modules/mb-image/png/generated_vectors_test.mbt` | Generated public-boundary table | ✓ VERIFIED | Contains 89 generated rows consumed only by the public test loop. |
| `modules/mb-image/png/generated_vectors.mbt` | Generated private-boundary table | ✓ VERIFIED | Contains the matching 89 private rows consumed by the white-box loop. |
| `modules/mb-image/png/png_test.mbt` | Public decoder/probe proof | ✓ VERIFIED | Uses only `ImageDecoder::probe` / `ImageDecoder::decode(PngDecoder)` and verifies errors, contexts, Budget, and diagnostics. |
| `modules/mb-image/png/structural_wbtest.mbt` | Internal CRC/state/preflight proof | ✓ VERIFIED | Executes every private row and separately checks five CRC-precedence cases, resource preflight, and EOF reader-error propagation. |
| `scripts/quality/Assert-Policy.ps1` / `scripts/quality/Invoke-MoonQuality.ps1` | Isolated Png policy gate | ✓ VERIFIED | Actual Png package policy and generated interface are checked before scoped negatives, exact allowlist, vector freshness, and all-target tests. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `structural.mbt` | `_png_validate_transport` | ✓ WIRED | `PngDecoder::decode` invokes validation and immediately returns its error before capability terminal. |
| `structural.mbt` | caller reader | `_png_require_eof` | ✓ WIRED | Direct one-byte read treats only actual EOF as success; it charges/checks input only after a byte is read. Exact 57-byte and 58-byte trailing tests pass. |
| `cases.json` | both generated tables | `Generate-PngStructuralVectors.ps1 -Check` | ✓ WIRED | Generator checks every case has P+W routing and writes both 89-row tables from the same JSON source. |
| `generated_vectors_test.mbt` | `png_test.mbt` | `_generated_png_public_cases()` | ✓ WIRED | Public loop invokes `ImageDecoder::decode(PngDecoder)` for every row and checks category/code/context and immutable caller state. |
| `generated_vectors.mbt` | `structural_wbtest.mbt` | `_generated_png_structural_cases()` | ✓ WIRED | Private loop invokes the same public decoder seam for every row; focused white-box checks additionally prove CRC precedence and parser invariants. |
| `Invoke-MoonQuality.ps1` | `Assert-Policy.ps1` | Png lane stages | ✓ WIRED | The lane calls `Assert-PngFoundationPolicy` and `Assert-PngQualificationNegativeFixtures` before vector and target stages; isolation validates the exact trace. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `png.mbt` / `structural.mbt` | Forward reader bytes | Caller-provided `@io.Reader` through `_png_read_one` | Yes — signature, chunk fields, payload, CRC, and strict EOF all consume from the provided reader under limits. | ✓ FLOWING |
| Generated public/private tests | `PngGeneratedCase` records | `fixtures/png/cases.json` through the deterministic generator | Yes — fresh check found 89 source records and each emitted table has 89 byte-exact rows. | ✓ FLOWING |
| Preflight / terminal seam | Validated IHDR and caller Budget | Parser state and `Budget::child` | Yes — all limits are checked before `png.mbt` emits the only Phase-20 capability terminal. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generated matrix is current and provenance-valid | `pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` | `PNG structural vector generation/check passed (89 P+W cases).` | ✓ PASS |
| PNG public/private behavior executes on all supported targets | `moon -C modules/mb-image test png --target all --frozen` | 11/11 tests passed on wasm, wasm-gc, js, and native. The generated loops execute all 89 records at both boundaries within those tests. | ✓ PASS |
| Isolated Png quality gate is executable and fail-closed | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Passed policy/interface, scoped negatives, exact allowlist, freshness, four-target tests, and lane-isolation trace. | ✓ PASS |
| Exact input ceiling distinguishes EOF from a trailing byte | Targeted `png_test.mbt` case plus four-target command above | A 57-byte valid RGB transport reaches `deflate-and-raster-pending`; a 58th byte under the same ceiling returns `BudgetExceeded(input-bytes)`. | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 20 declares no executable probe and no conventional `scripts/*/tests/probe-*.sh` file exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNG-01 | 20-01, 20-03, 20-04 | Bounded non-consuming signature probe with deterministic outcomes | ✓ SATISFIED | ByteView-only probe, four required outcomes in public test, and four-target pass. |
| PNG-02 | 20-01, 20-03, 20-04 | Typed framing/order/CRC/unsupported/IEND/trailing rejection | ✓ SATISFIED | Fixed-scratch state machine plus complete 89-case public/private generated matrix, including five CRC and 13 semantic-family records. |
| PNG-03 | 20-01, 20-03, 20-04 | Checked dimension, pixel, input, output, work, allocation, and metadata-policy enforcement before output | ✓ SATISFIED | Checked IHDR envelope, non-mutating Budget preflight, exact/below resource pairs, immutable-state assertions, and no image-returning path. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder return, empty handler, or hardcoded user-visible empty-data stub found in Phase-20 artifacts. | ℹ️ Info | No blocker or warning. |

### Gaps Summary

All three prior blockers are closed. The EOF reader now distinguishes absent input from an actually consumed byte, the finite hostile corpus is generated and executed through both required routes, and the isolated Png lane verifies actual package policy/interface state with scoped fail-closed negatives. No later-phase deferral, override, or human verification is required for the Phase-20 goal.

---

_Verified: 2026-07-20T16:32:38Z_
_Verifier: the agent (gsd-verifier)_
