---
phase: 16-qoi-policy-and-public-example-quality-alignment
verified: 2026-07-20T12:40:41Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 16: QOI Policy and Public Example Quality Alignment Verification Report

**Phase Goal:** Make the existing foundation policy and public-example quality checks recognize the existing QOI package and `qoi-portable` consumer, fail closed on QOI drift, and remain outside release/registry operations.
**Verified:** 2026-07-20T12:40:41Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The exact six-member workspace and seven-package mb-image policy include QOI while preserving existing members/packages. | ✓ VERIFIED | `moon.work` contains exactly the six required members; `Assert-Policy.ps1:720-722` asserts that exact set and `:765-769` asserts the ordered seven-package mb-image spine. Direct JSON/source cross-check passed. |
| 2 | QOI imports, targets, compiler-derived interface, source order, and QOI inventory are exact and fail closed on drift. | ✓ VERIFIED | `Assert-QoiFoundationPolicy` validates exact policy/source data and compiler interface; its nine QOI negative fixtures all rejected the required missing, extra, and reorder cases in an independent run. |
| 3 | The Qoi lane runs only QOI policy/package/example checks, verifies the portable public example on all four targets, and does not enter qualification, registry, release, publication, or credential paths. | ✓ VERIFIED | Direct `qoi-portable` runs emitted the exact required line on js, wasm, wasm-gc, and native. `Assert-QoiLaneIsolation` passed with forbidden-path traps and exact four-stage trace; dispatched `-Lane Qoi` passed. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `policy/foundation.json` | Exact QOI public-package and mb-image publication inventory | ✓ VERIFIED | One candidate `tchivs/mb-image/qoi` record has 11 imports, five ordered production sources, 17 compiler-interface lines, four portable targets, and exactly the approved QOI publication entries. |
| `scripts/quality/Assert-Policy.ps1` | Scoped QOI foundation and negative-fixture helpers | ✓ VERIFIED | Substantive helpers at `:884-955`; called from the Qoi lane and full foundation policy. Fixtures exercise package presence, imports, target, interface, ordering, and contents. |
| `scripts/quality/Invoke-MoonQuality.ps1` | Bounded Qoi route and isolation proof | ✓ VERIFIED | `Invoke-QoiQualityLane` at `:707-731` contains only four allowlisted stages; `Assert-QoiLaneIsolation` at `:733-762` traps broad, qualification, registry, reporting, release, publication, and credential routes. |
| `scripts/quality/Test-PublicExamples.ps1` | Four-target qoi-portable public-consumer check | ✓ VERIFIED | The qoi workspace branch at `:318-337` validates source/import allowlists and invokes all four targets with the exact output; qualification work remains under the `-Mode qualify` branch at `:340-352`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `policy/foundation.json` | `scripts/quality/Assert-Policy.ps1` | `Assert-QoiFoundationPolicy` selects and validates only QOI policy data | ✓ WIRED | The helper reads the policy, selects one `qoi` package, then checks policy against `moon.pkg`, QOI files, and generated interface. |
| `scripts/quality/Invoke-MoonQuality.ps1` | `scripts/quality/Test-PublicExamples.ps1` | `Invoke-QoiQualityLane` invokes qoi workspace mode | ✓ WIRED | The public-example stage runs exactly `-Example qoi -Mode workspace -Target all`; the isolation proof executes the same call with traps. |
| `scripts/quality/Test-PublicExamples.ps1` | `examples/qoi-portable/main/main.mbt` | `moon run` on every required target | ✓ WIRED | Four direct `moon -C examples/qoi-portable run main --target ... --frozen` calls each produced the required single status line. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| QOI policy helper | QOI policy record / generated interface | Checked `foundation.json`, `moon.pkg`, QOI directory, and `moon info --target all` output | Yes — direct compiler and filesystem data | ✓ FLOWING |
| Public-example checker | Runtime evidence line | `moon run` for qoi-portable on four targets | Yes — exact live output on every target | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Compiler-derived QOI interface is usable by scoped policy checks | `moon -C modules/mb-image info --target all --frozen` plus `Assert-QoiFoundationPolicy` | Exit 0; policy helper verified 17 semantic interface lines | ✓ PASS |
| QOI drift checks fail closed | `Assert-QoiQualificationNegativeFixtures -PolicyPath policy/foundation.json` | Exit 0; all nine required synthetic drift cases rejected | ✓ PASS |
| Public example has exact four-target evidence | `moon -C examples/qoi-portable run main --target {js,wasm,wasm-gc,native} --frozen` | Each exit 0 with the identical required QOI evidence line | ✓ PASS |
| QOI lane is isolated and dispatches | `Assert-QoiLaneIsolation`; `Invoke-MoonQuality.ps1 -Lane Qoi` | Both exit 0; isolation trace contains only four allowlisted stages | ✓ PASS |
| Broad foundation-policy regression scope | `Assert-FoundationPolicy -PolicyPath policy/foundation.json` | Exit 1 only at pre-existing `tchivs/mb-image/ops` 10-vs-12 import-count mismatch; no QOI failure | ℹ️ OUT OF SCOPE |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| QOI-05 | 16-01 | Four-target QOI conformance quality evidence | ✓ SATISFIED | Scoped interface/policy verification and direct public-example evidence passed on js, wasm, wasm-gc, and native. |
| QOI-06 | 16-01 | Deterministic portable QOI public example | ✓ SATISFIED | qoi-portable's exact one-line decode/flip/encode evidence passed through its public workspace path on all targets. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, or empty-implementation markers in the Phase 16 implementation diff | — | None |

### Scope and Disconfirmation Checks

- The Phase 16 implementation diff modifies only the four planned policy/quality files plus its summary; it does not modify qualification, registry, release, publication, credential, or unrelated inventory artifacts.
- Static inspection of `Invoke-QoiQualityLane` found no forbidden broad/qualification/release call. The executable isolation proof also replaces each forbidden function with a fail-fast trap and passed.
- The full foundation assertion remains blocked only by the known pre-existing `ops` import-policy drift (`expected 10, got 12`). This phase neither suppresses nor changes that non-QOI issue, and the failure output contains no QOI error.

### Human Verification Required

None. The phase's runtime-dependent claims are covered by direct four-target commands and the executable isolation proof.

---

_Verified: 2026-07-20T12:40:41Z_
_Verifier: the agent (gsd-verifier)_
