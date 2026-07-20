---
phase: 12-strict-ppm-end-to-end-filter-coverage
verified: 2026-07-20T00:00:00Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 12: Strict PPM End-to-End Filter Coverage Verification Report

**Phase Goal:** Close the v0.3 audit's sole partial strict-PPM integration path with portable crop, rotation, grayscale, blur, and source-over evidence before encoding.
**Verified:** 2026-07-20T00:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

`ROADMAP.md` gives Phase 12 a goal but no separate success-criteria array, so the three `must_haves.truths` in `12-01-PLAN.md` are the observable contract. SUMMARY claims were not used as evidence.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The portable strict-P6 example decodes, crops, rotates, converts, grayscales, radius-one blurs, composites, converts, and encodes one fixed vector on every supported target. | ✓ VERIFIED | `main.mbt` invokes the exact public chain `PpmDecoder -> crop -> rotate_90 -> rgb8_to_straight_rgba8 -> grayscale -> box_blur(1) -> composite_source_over -> straight_rgba8_to_rgb8 -> PpmEncoder`; independent `moon ... run ... --frozen` executions passed on js, wasm, wasm-gc, and native. |
| 2 | The resulting strict-P6 payload is exactly 29 bytes and proven by exact bytes, rolling digest, SHA-256 identity, and intermediate semantic assertions. | ✓ VERIFIED | The example compares all 29 output bytes, checks `bytes_written` and writer position, digest `714923673`, zero diagnostics, rotated extent/endpoint pixels, grayscale alpha/channels, and blur pixels. Every target emitted `bytes_written=29`, the required digest, and SHA-256 `005700d6602b144bafcf3d869deee85619c8279c749bf33ca6fea8b43dbe78bf`. |
| 3 | An otherwise successful crop-to-filter route rejects a 53-work blur budget atomically with the typed box-blur budget error on every supported target. | ✓ VERIFIED | The white-box test completes crop, rotation, RGB-to-RGBA conversion, and grayscale, then calls `box_blur(..., 1UL, ... work=53UL)`. It asserts Resource/BudgetExceeded, `image-box-blur`, `image-box-blur-output-budget`, and equality of bytes, allocations, allocation_size, width, height, pixels, depth, and work before/after. The named test passed on all four targets. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/ppm-portable/main/main.mbt` | Runnable strict-P6 pipeline with staged budgets and byte oracle | ✓ VERIFIED | Substantive 93-line executable; wired through executable `moon.pkg`; decodes real fixed P6 byte inputs and sends their decoded images through the public operation chain to a real in-memory encoded result. |
| `examples/ppm-portable/main/moon.pkg` | Local model import for public `Rect` crop argument | ✓ VERIFIED | Diff from execution baseline adds exactly `tchivs/mb-image/model`; it is consumed as `@model.Rect::new` in the executable. No external dependency was added. |
| `modules/mb-image/ops/processing_pipeline_test.mbt` | Public semantic crop/filter/source-over coverage | ✓ VERIFIED | Named black-box test constructs the discriminating 3x3 vector and asserts crop/rotation positions, grayscale, radius-one clamp-edge values, alpha/source-over semantics, and strict RGB conversion. It ran in each target suite. |
| `modules/mb-image/ops/processing_pipeline_wbtest.mbt` | Hostile blur preflight and budget atomicity proof | ✓ VERIFIED | Named white-box test reaches the non-degenerate blur boundary and compares the complete `ResourceLimits` snapshot after rejection. It ran in each target suite. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `examples/ppm-portable/main/main.mbt` | `tchivs/mb-image/ppm`, `tchivs/mb-image/ops` | Decode → geometry/filter/composite chain → encode | ✓ WIRED | Both packages are declared in `moon.pkg`, public symbols are called in order, and the executable passes on all four configured targets. |
| `processing_pipeline_wbtest.mbt` | `modules/mb-image/ops/processing.mbt` | Successful precursor path followed by public `box_blur` at 53 work | ✓ WIRED | The test directly calls the implementation-under-test public operation and observes its typed rejection plus unchanged budget on all four targets. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `main.mbt` | `decoded_foreground` / `decoded_background` → `encoded` | Strict P6 byte inputs are decoded by `PpmDecoder`; produced images are transformed and encoded through `MemoryWriter` | Yes — output is compared byte-for-byte to the 29-byte oracle, not a hardcoded success string | ✓ FLOWING |
| `processing_pipeline_test.mbt` | `foreground` / `destination` → `output` | Owned RGB fixtures populated pixel-by-pixel and transformed through exported `ops` APIs | Yes — decisive intermediate and output pixels are inspected | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Portable strict-P6 complete pipeline | `moon -C examples/ppm-portable run main --target {js,wasm,wasm-gc,native} --frozen` | Each target exited 0 and emitted all three required output markers | ✓ PASS |
| Public and hostile operation paths | `moon test modules/mb-image/ops --target {js,wasm,wasm-gc,native} --frozen -v` | Each target exited 0; 40/40 tests passed and both Phase-12 named tests were reported `ok` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| INTEG-01 | 12-01 | Public PPM composition evidence | ✓ SATISFIED | Four-target public executable proves the strict P6 decode-to-encode geometry/filter route. |
| INTEG-02 | 12-01 | Four-target behavioral and adversarial evidence | ✓ SATISFIED | Named public and white-box tests executed successfully on js, wasm, wasm-gc, and native. |
| RASTER-02 | 12-01 | Deterministic grayscale and bounded box blur | ✓ SATISFIED | Radius-one vector asserts grayscale and clamp-edge blur output with a 54-work successful budget. |
| RASTER-03 | 12-01 | Typed deterministic resource-limit error | ✓ SATISFIED | 53-work radius-one blur asserts the precise typed error and full budget atomicity. |

`REQUIREMENTS.md` maps these existing requirements to prior implementation phases because Phase 12 is audit closure, not a new requirement; no additional Phase-12 requirement is orphaned.

### Scope and Anti-Patterns

| Check | Result |
| --- | --- |
| Phase completion scope | ✓ `git diff --name-only 21312f2..fe16823` contains only the four approved implementation artifacts plus `12-01-PLAN.md` and `12-01-SUMMARY.md`; `git diff --check` passed. |
| Product/API scope | ✓ No production `ops` or `ppm` implementation file changed. The only manifest change is the local `tchivs/mb-image/model` import required for `Rect`. |
| Debt/stub scan | ✓ No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, or empty-implementation markers in any Phase-12 implementation artifact. |

The current repository `HEAD` also contains later commit `1cf33a6` modifying three `scripts/quality/*` files. That post-Phase-12 quality change makes a literal `21312f2..HEAD` scope command non-zero-scope, but it is outside the completed Phase-12 commit boundary `fe16823` and is not a Phase-12 scope violation.

### Disconfirmation Pass

- Partial-requirement check: the public test does not decode PPM itself, but the executable independently does, so the required codec-to-ops boundary is covered rather than merely simulated.
- Misleading-test check: the 53-work test reaches blur only after successful crop/rotate/convert/grayscale precursor stages and checks every resource counter, so it is not a generic low-budget test.
- Error-path check: the exact `Resource/BudgetExceeded` category/code/operation/context and unchanged budget are asserted; all four target executions exercised that path.

### Gaps Summary

No gaps found. The goal's strict-PPM path, exact deterministic output identity, and atomic radius-one blur boundary have direct source, wiring, data-flow, and four-target behavioral evidence.

---

_Verified: 2026-07-20T00:00:00Z_
_Verifier: the agent (gsd-verifier)_
