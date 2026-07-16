---
phase: 03-reference-color-semantics
verified: 2026-07-16T19:25:46Z
status: gaps_found
score: 10/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Reference evidence is described with provenance claims that match its actual derivation."
    status: failed
    reason: "The README calls values in the primary formula-derived fixture 'official sample values', although the fixture identifies them as generator-produced formula derivatives and Plan 03-02 explicitly forbids calling derived values official."
    artifacts:
      - path: "modules/mb-color/README.mbt.md"
        issue: "Lines 218-220 overstate project-selected formula-derived points as official samples."
      - path: "fixtures/color/srgb-reference-vectors.json"
        issue: "The artifact correctly classifies itself as primary-formula-derived, which conflicts with the README wording."
    missing:
      - "Replace 'official sample values' with provenance-accurate language such as project-selected formula-derived reference points, preserving the distinction between published formulas and repository-generated cases."
  - truth: "Each package-local generated vector table is wired to the relevant canonical fixture cases, including bounded profile payload cases."
    status: failed
    reason: "The canonical dataset and derived JSON contain profile.payload_cases, but Render-ProfileMoon emits only accepted and rejected tag arrays. The generated profile test therefore does not consume the planned limit, budget, or opaque-byte cases."
    artifacts:
      - path: "scripts/fixtures/Generate-ColorVectors.ps1"
        issue: "Render-ProfileMoon reads only Data.profile.accepted_tags and rejected_tags; Data.profile.payload_cases is unused."
      - path: "modules/mb-color/profile/reference_vectors_wbtest.mbt"
        issue: "The generated table checks only 4 accepted and 5 rejected tags, despite Plan 03-06 promising generated tag/limit/budget/opaque-byte cases."
      - path: "fixtures/color/derived-edge-vectors.json"
        issue: "Profile payload cases are emitted into canonical evidence but have no generated package-local consumer."
    missing:
      - "Generate profile payload/limit vectors from Data.profile.payload_cases and exercise them in profile/reference_vectors_wbtest.mbt, including exact-limit acceptance, one-over rejection, budget ordering, and opaque byte preservation."
---

# Phase 3: Reference Color Semantics Verification Report

**Phase Goal:** `mb-color` makes color-space, transfer, component, and alpha behavior explicit and reproducible enough to serve as the semantic oracle for images and later graphics modules.
**Verified:** 2026-07-16T19:25:46Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Public values carry explicit component, color-space, transfer, and alpha-state identities without implicit defaults. | ✓ VERIFIED | `model` exposes distinct opaque encoded/linear/alpha/8-bit types and explicit identity enums; constructors reject invalid values. |
| 2 | Normalized values are finite and in `[0,1]`, encoded values retain full-width validation, and invalid input is rejected rather than clamped. | ✓ VERIFIED | `validate_normalized` rejects NaN, infinities, and both range violations; encoded-8 validation checks `UInt` before narrowing. Source scans found no implementation clamp. |
| 3 | Encoded↔linear sRGB follows the published inclusive thresholds, formulas, tolerances, range, and monotonicity contract on every target. | ✓ VERIFIED | Typed transfer implementation and boundary/neighbor/vector tests are substantive; the named threshold test passed on wasm, wasm-gc, js, and native. |
| 4 | Quantization uses explicit nearest-ties-to-even behavior without backend rounding or hidden clamping. | ✓ VERIFIED | Floor/fraction/parity and checked ratio implementations are explicit; all 256 encoded codes dequantize/requantize identically on all four targets. |
| 5 | Straight/premultiplied and encoded/linear alpha states are distinct, reject `p > a`, canonicalize zero alpha, and use documented rounding. | ✓ VERIFIED | Four opaque states, constructor guards, zero rules, checked arithmetic, boundary tests, and exhaustive encoded-pair invariants are present; the exhaustive test passed on all targets. |
| 6 | Bounded profile identity and opaque bytes round-trip exactly without an ICC parser. | ✓ VERIFIED | Tag grammar, caller limits, independent budget charging, built-in sRGB identity, opaque ownership/views, and manual exact-byte tests are substantive; the exact-limit round-trip test passed on all targets. |
| 7 | Primary formula-derived and repository-derived evidence remain honestly distinguished. | ✗ FAILED | JSON classifications are honest, but README line 219 calls formula-derived points “official sample values,” contradicting the plan’s explicit provenance rule. |
| 8 | Selective generation wires every package to its relevant canonical reference cases. | ✗ FAILED | Transfer, quantize, and alpha tables consume canonical data. Profile generation ignores `payload_cases`, so planned limit/budget/opaque-byte evidence is not connected to the package-local generated test. |
| 9 | Exactly five focused public packages form the declared acyclic dependency graph and the obsolete root package is absent. | ✓ VERIFIED | Policy declares `model -> transfer -> quantize -> alpha -> profile` publication order with exact imports; root scaffolding is absent and policy negative checks cover topology. |
| 10 | Public documentation states thresholds, tolerances, ties-even, zero-alpha behavior, maximum encoded error, profile limits, target policy, and release order. | ✓ VERIFIED | The executable README covers these contracts; only the provenance wording in truth 7 is inaccurate. |
| 11 | Quality policy fails closed for interfaces, contents, targets, prohibited rounding/clamping/defaults/ICC parsing, fixtures, and tracked immutability. | ✓ VERIFIED | Classifiers and negative fixtures are present. Fixture-policy negatives passed independently; Plan 03-07 records two complete Required runs with 110/110 tests per target and read-only proof. |
| 12 | Deferred broad color-space, adaptation, blending, codec, native-adapter, and ICC parsing scope is absent from v0.1. | ✓ VERIFIED | Public surfaces remain limited to the five planned packages; scans found no hidden default or ICC parser implementation. |

**Score:** 10/12 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact group | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-color/model/*` | Explicit identity-bearing primitives and validation | ✓ VERIFIED | Substantive implementation, endpoint/non-finite/range tests, exact policy interface. |
| `modules/mb-color/transfer/*` | Normative sRGB transfer and vectors | ✓ VERIFIED | Inclusive thresholds, formulas, tolerances, monotonicity and round-trip coverage. |
| `modules/mb-color/quantize/*` | Ties-even quantization and exhaustive code coverage | ✓ VERIFIED | Explicit backend-neutral rounding; no `Double::round` or clamp. |
| `modules/mb-color/alpha/*` | Four alpha states and exhaustive conversions | ✓ VERIFIED | Zero/boundary/full-range behavior and directional identities are exercised. |
| `modules/mb-color/profile/profile.mbt` and manual tests | Bounded opaque metadata seam | ✓ VERIFIED | Exact bytes, tag grammar, limits, budgets, and no-parse behavior are implemented. |
| `modules/mb-color/profile/reference_vectors_wbtest.mbt` | Generated tag/limit/budget/opaque-byte cases | ✗ PARTIAL | Generated artifact contains tag lists only; canonical payload cases are not emitted or consumed. |
| `fixtures/color/*.json` and `fixtures/manifest.json` | Deterministic provenance-recorded evidence | ✓ VERIFIED | Generator `-Artifacts all -Check` reported every fixture, manifest, and package vector byte-identical; fixture identity/containment matrix passed. |
| `modules/mb-color/README.mbt.md` | Executable semantic and provenance contract | ✗ PARTIAL | Semantic contract is comprehensive, but “official sample values” is not supported by the artifact classification. |
| `policy/foundation.json` and quality scripts | Exact five-package qualification | ✓ VERIFIED | Exact package order, DAG, semantic interfaces, contents, targets, prohibitions, and negative fixtures are declared. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Identity constructors | transfer/quantize/alpha operations | opaque typed parameters/results | ✓ WIRED | Public seams do not accept identity-erasing raw `Double` values. |
| Published sRGB formulas | transfer vectors/tests | deterministic canonical dataset | ✓ WIRED | Threshold and adjacent reference cases are emitted and exercised. |
| Quantize/alpha canonical cases | package-local generated tests | selector-specific generator output | ✓ WIRED | Generated ratio/alpha data is present and tests run across all targets. |
| Profile canonical payload cases | package-local generated profile tests | `Render-ProfileMoon` | ✗ NOT WIRED | `payload_cases` enters JSON but is never read by the renderer; only tag arrays are generated. |
| Fixture classifications | README provenance prose | public explanation | ✗ MISWIRED | The artifact says formula-derived while the README labels values official. |
| Policy | five package manifests/interfaces | exact classifiers and negative fixtures | ✓ WIRED | Declared imports and publication contents match the implemented graph. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Inclusive decode threshold | `moon -C modules/mb-color test transfer --target all --frozen --filter "decode uses inclusive low branch at the published threshold"` | 1/1 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Exhaustive encoded-code quantize identity | `moon -C modules/mb-color test quantize --target all --frozen --filter "dequantize and requantize preserve all encoded codes"` | 1/1 passed on all four targets | ✓ PASS |
| Exhaustive encoded alpha pairs | `moon -C modules/mb-color test alpha --target all --frozen --filter "exhaustive encoded pairs establish directional identities and bounds"` | 1/1 passed on all four targets | ✓ PASS |
| Empty/exact-limit opaque profile round-trip | `moon -C modules/mb-color test profile --target all --frozen --filter "empty and exact-limit opaque payloads round-trip exactly"` | 1/1 passed on all four targets | ✓ PASS |
| Deterministic generated artifacts | `pwsh -NoProfile -File scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts all -Check` | All fixtures, manifest, and four package-local tables byte-identical | ✓ PASS |
| Fixture policy fail-closed matrix | `pwsh -NoProfile -File scripts/quality/Test-FixturePolicy.ps1` | Valid case and 12 invalid/containment cases behaved as expected | ✓ PASS |
| Root Required lane | `pwsh -NoProfile -File scripts/quality.ps1 -Lane Required` | Independent invocation exceeded the 60-second verifier command budget and was stopped without a verdict; Plan 03-07 records two prior complete passing runs with 110/110 tests per target. | ◇ INCONCLUSIVE THIS RUN |

### Probe Execution

SKIPPED: no phase plan declares a probe script. Named MoonBit tests, deterministic generator checks, fixture-policy checks, and the root quality contract provide executable evidence.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| COLR-01 | 03-01, 03-03, 03-05 | ✓ SATISFIED | Explicit typed identities and alpha states are implemented and tested. |
| COLR-02 | 03-03, 03-04 | ✓ SATISFIED | Transfer and ties-even contracts pass targeted four-target checks. |
| COLR-03 | 03-05 | ✓ SATISFIED | Zero, boundary, rejection, rounding, and exhaustive pair behavior pass. |
| COLR-04 | 03-02 through 03-07 | ✗ BLOCKED | Core behavior is validated on all targets, but provenance prose is inaccurate and profile payload fixture cases are not wired into the generated package table. |
| COLR-05 | 03-06 | ✓ SATISFIED | Bounded profile identity and opaque byte preservation work without ICC parsing. |

No Phase 3 requirements are orphaned.

### Prohibition Verification

| Prohibition | Evidence | Verdict |
|---|---|---|
| No implicit default identity, transfer, or alpha state | Opaque typed interfaces, explicit identity accessors, source scans, and negative policy fixtures. | ✓ VERIFIED |
| No clamp or backend-dependent rounding | Source scan found only documentation/tests saying “never clamp”; explicit ties-even implementation and exhaustive test pass. | ✓ VERIFIED |
| No full ICC parser or semantic interpretation of opaque bytes | Profile implementation stores bounded owner/view/tag only; source scan found README deferral, no parser code. | ✓ VERIFIED |
| No out-of-phase broad color/codec/native adapter surfaces | Exact interfaces and package policy remain within Phase 3 scope. | ✓ VERIFIED |
| No dishonest provenance claim | README calls generator-derived points official. | ✗ FAILED |

### Anti-Patterns Found

- **Blocker:** Unsupported “official sample values” provenance language in the executable README.
- **Blocker:** Dead canonical profile payload data: emitted into JSON but not rendered into the profile package’s generated test table.
- No `TODO`, `FIXME`, `XXX`, implementation placeholder, panic/abort seam, `Double::round`, implementation clamp, hidden default, or ICC parser was found in the Phase 3 source surface.

### Disconfirmation Pass

- **Potential false pass checked:** generator byte identity proves reproducibility, not completeness. Tracing `payload_cases -> Render-ProfileMoon -> reference_vectors_wbtest.mbt` exposed the missing consumer despite a green generator check.
- **Potential misleading provenance checked:** the source formulas are official publications, but the fixture’s sampled numeric points are generator-derived; those facts do not justify calling the samples official.
- **Potential semantic weakness checked:** manual profile tests do cover exact bytes, independent budgets, and arbitrary ICC-tagged bytes, so the implementation is sound; the gap is the promised canonical generated-evidence wiring, not profile behavior itself.
- **Potential cross-target weakness checked:** transfer threshold, all-256 quantization, exhaustive alpha pairs, and profile round-trip tests each passed independently on all four declared targets.

### Human Verification Required

None. Both gaps and all verified semantic contracts are deterministically inspectable and testable.

### Gaps Summary

Two deterministic gaps block Phase 3 completion:

1. Correct the README so published formulas are distinguished from repository-generated reference points.
2. Extend `Render-ProfileMoon` and the generated profile test to consume canonical profile payload/limit/budget cases rather than tags alone.

The implementation semantics themselves are strong and portable; closing these evidence-integrity gaps should not require public API changes.

---

_Verified: 2026-07-16T19:25:46Z_
_Verifier: the agent (gsd-verifier)_
