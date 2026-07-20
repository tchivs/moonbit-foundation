---
phase: 11-portable-processing-pipeline-evidence
verified: 2026-07-20T17:20:00+08:00
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 11: Portable Processing Pipeline Evidence Verification Report

**Phase Goal:** Library users and maintainers can rely on a demonstrated, portable image-processing workflow and reproducible performance evidence.

**Verified:** 2026-07-20T17:20:00+08:00
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can run one public MoonBit example that combines geometry and raster operations and encodes the resulting image as PPM. | ✓ VERIFIED | `examples/ppm-portable/main/main.mbt` performs real strict `PpmDecoder` decode of two P6 inputs, `resize_nearest`, both RGB8→straight-RGBA8 conversions, `composite_source_over`, strict straight-RGBA8→RGB8, and `PpmEncoder` encode. It asserts dimensions, both semantic RGB triples, diagnostic emptiness, the complete 17-byte P6 output, and rolling digest `9386158`. Independent runs on js/wasm/wasm-gc/native printed the same expected SHA-256 `cf8f…76464`. |
| 2 | Public behavioral and adversarial tests demonstrate the new API's expected results and failure behavior on `js`, `wasm`, `wasm-gc`, and `native`. | ✓ VERIFIED | The named public test `public processing pipeline resize-composite opaque PPM vector` exercises the complete exported resize/convert/composite/convert route and checks output pixels plus operand order. The named adversarial test `processing pipeline insufficient resource leaves budget unchanged` reaches composite work preflight, asserts typed `BudgetExceeded`, and compares every budget resource counter. `moon test modules/mb-image/ops --target <target> --frozen -v` reported both names and `38 passed, 0 failed` on each of all four targets. |
| 3 | A maintainer can reproduce a declared resize-and-compositing benchmark workload and compare it with its recorded baseline without running or depending on release automation. | ✓ VERIFIED | Native-only `ppm/pipeline/resize-composite/256x256` decodes deterministic 128×128 and 256×256 strict PPM sources, performs public resize/conversions/source-over/conversion/encode, and validates exact output length and independently constructed rolling digest before timing the same closure. The tracked local record declares one warmup and exactly seven timestamped direct-command captures with toolchain, source, and correctness provenance; it contains no release-harness, release-qualification, schema, or release-baseline reference. Independent direct run printed the named workload as `ok` and `Total tests: 9, passed: 9, failed: 0`. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/ppm-portable/main/main.mbt` | Public strict PPM processing proof | ✓ VERIFIED | Substantive consumer code, not a fixture/stub. The actual values flow from decoded PPM bytes through public operations to the encoder and exact output assertions. |
| `modules/mb-image/ops/processing_pipeline_test.mbt` | Public fixed-vector and failure-boundary evidence | ✓ VERIFIED | Uses exported `@ops` APIs; asserts 2×1 opaque vector, metadata disposition, operand order, and typed conversion rejection. |
| `modules/mb-image/ops/processing_pipeline_wbtest.mbt` | Adversarial resource/budget atomicity proof | ✓ VERIFIED | Runs an otherwise successful composed route through composite resource preflight; checks type, code, operation/context, and the complete budget snapshot. |
| `benchmarks/ppm/ppm_bench.mbt` | Named native resize-composite workload | ✓ VERIFIED | Native package uses the existing `@bench.T`, validates correctness before `it.bench`, and measures the exact public route. No production algorithm or public API was added. |
| `benchmarks/ppm/phase-11-resize-composite-baseline.md` | Isolated reproducibility record | ✓ VERIFIED | Workload, dimensions, direct frozen command, target/build mode, Moon identities, source/correctness digests, one warmup, and seven UTC captures are present. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Portable example | strict codec and public operations | `PpmDecoder` → resize → conversions → source-over → conversion → `PpmEncoder` | ✓ WIRED | Direct source inspection and four successful program executions. |
| Pipeline public test | exported processing APIs | direct calls in one fixed vector | ✓ WIRED | The named black-box test executed on all four targets. |
| Pipeline adversarial test | composite preflight/resource policy | public route reaches `composite_source_over` with insufficient work budget | ✓ WIRED | The named white-box test executed on all four targets and asserts no mutation. |
| Benchmark workload | public codec/ops route | `resize_composite_public` in the named `@bench.T` test | ✓ WIRED | The workload executed successfully in the independent native benchmark output. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Portable example | encoded PPM bytes | strict decoded foreground/background → resize/conversion/composite → encoder writer | Yes — expected bytes are checked against computed writer content | ✓ FLOWING |
| Public pipeline test | output RGB bytes | caller-built RGB image bytes → exported operations → output view | Yes — both pixels are asserted to `0c 22 38` | ✓ FLOWING |
| Benchmark workload | encoded-output digest | deterministic PPM sources → full public pipeline → writer | Yes — expected digest is independently generated from nearest-resized source bytes before timing | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Portable public pipeline on js | `moon -C examples/ppm-portable run main --target js --frozen` | Expected 17-byte/digest/SHA line | ✓ PASS |
| Same on wasm | `moon -C examples/ppm-portable run main --target wasm --frozen` | Same line | ✓ PASS |
| Same on wasm-gc | `moon -C examples/ppm-portable run main --target wasm-gc --frozen` | Same line | ✓ PASS |
| Same on native | `moon -C examples/ppm-portable run main --target native --frozen` | Same line | ✓ PASS |
| Named public and adversarial tests | `moon test modules/mb-image/ops --target js|wasm|wasm-gc|native --frozen -v` | Both named tests listed; 38/38 pass on every target | ✓ PASS |
| Native benchmark workload | `moon -C benchmarks bench --release --target native --frozen ppm` | Named workload `ok`; total `9 passed, 0 failed` | ✓ PASS |

### Probe Execution

SKIPPED — Phase 11 declares no probe and no `scripts/*/tests/probe-*.sh` probe applies.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| INTEG-01 | 11-01 | One public PPM example composes geometry/raster operations before encoding. | ✓ SATISFIED | Truth 1; strict decode/encode, explicit representation bridge, exact vector/digest and four target executions. |
| INTEG-02 | 11-02 | Public behavioral/adversarial tests validate APIs on all supported targets. | ✓ SATISFIED | Truth 2; discriminating named positive and resource-failure tests each execute on js, wasm, wasm-gc, and native. |
| INTEG-03 | 11-03 | Reproducible local resize/composite baseline without release automation. | ✓ SATISFIED | Truth 3; named native workload, correctness gate, 1 warmup + 7 timestamped captures, direct command and no prohibited release references. |

No orphaned Phase 11 requirements: INTEG-01, INTEG-02, and INTEG-03 are each declared by a Phase 11 plan and have executable evidence.

### Anti-Patterns Found

No blocker or warning anti-patterns found in the six phase implementation/test/documentation artifacts. The source scan found no untracked `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or prohibited release-harness reference. `git diff --check 9fa0348..HEAD -- examples modules/mb-image benchmarks` is clean.

### Scope and Regression Checks

- Phase commits change only the planned example, package documentation, two test files, benchmark source, and the Phase-11-local baseline record. No `release/`, `scripts/`, or `.github/` file changed in `9fa0348..HEAD`.
- No new `mb-image` production algorithm or public API was introduced: the phase is a consumer/evidence layer over existing codec, resize, conversion, and source-over APIs.
- The baseline checker independently found exactly seven capture rows and no `release/qualification`, `Invoke-PpmBenchmarks.ps1`, `schema`, or `baseline.json` reference.
- Pre-existing unrelated working-tree changes are left untouched: `.planning/config.json`, `scripts/quality/ReleaseQualification.Common.ps1`, and untracked tooling/planning directories were not used as phase evidence.

### Gaps Summary

None. The three roadmap contracts and INTEG-01/02/03 are substantiated by code, direct four-target output, named test output, the native benchmark output, and scope/provenance checks. Phase 11 is complete; therefore all v0.3 image-processing phases (9–11) are verified complete.

---

_Verified: 2026-07-20T17:20:00+08:00_
_Verifier: the agent (gsd-verifier)_
