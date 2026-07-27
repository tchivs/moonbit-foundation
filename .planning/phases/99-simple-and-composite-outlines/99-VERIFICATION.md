---
phase: 99-simple-and-composite-outlines
verified: 2026-07-27T12:22:13Z
status: gaps_found
score: 12/14 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The Phase 99 publication contract is internally consistent and enforced by repository policy."
    status: failed
    reason: "The focused font selector passes, but the repository-wide policy gate fails with `Manifest description drift in modules/mb-font`: policy/foundation.json describes Phase 99 outlines while modules/mb-font/moon.mod.json still has the Phase 98-only description."
    artifacts:
      - path: "modules/mb-font/moon.mod.json"
        issue: "The public module description omits simple/composite outline extraction and does not match policy/foundation.json."
      - path: "scripts/quality/Assert-Policy.ps1"
        issue: "Assert-FontFoundationPolicy does not check module-manifest description equality, so its green result misses the drift that Assert-FoundationPolicy catches."
    missing:
      - "Update modules/mb-font/moon.mod.json description to the exact approved Phase 99 module description."
      - "Make the focused font policy gate fail on manifest-description drift, or include the repository-wide policy gate in the Phase 99 closure command."
  - truth: "Public outline documentation accurately describes the five-way error taxonomy."
    status: failed
    reason: "modules/mb-font/README.mbt.md classifies `maxp` exhaustion as Resource, but production code and executable tests classify an actual glyph exceeding a maxp claim as malformed Data."
    artifacts:
      - path: "modules/mb-font/README.mbt.md"
        issue: "Line 283 says Resource covers `maxp` exhaustion; outline.mbt returns Data for maxp underclaims and font_test.mbt asserts that behavior."
    missing:
      - "Document maxp underclaims as Data, reserving Resource for retained FontLimits, max_work, and caller Budget exhaustion."
---

# Phase 99: Simple and Composite Outlines Verification Report

**Phase Goal:** Library authors can extract complete unhinted `Path2`-compatible outlines for valid simple glyphs and bounded one-level composites without partial geometry on failure.
**Verified:** 2026-07-27T12:22:13Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The outline implementation and its executable behavior achieve FONT-03. The phase does not pass as a complete publication unit because two Phase 99 closure truths are false in the current codebase: module metadata disagrees with policy, and the public README misstates one error category.

SUMMARY, review, and security reports were treated as claims only. Evidence below comes from the current implementation, generated interface, policy, documentation, and fresh commands.

The codebase-memory graph was queried first as required. It contains repository/file structure but no MoonBit function/call nodes, so symbol-level verification used the project-authorized direct-source fallback.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | `Font::outline` is a direct shared-`Path2`, caller-Budget query that revalidates the receiving font's glyph, guards source revision before decode and after private work, and publishes only one complete path. | ✓ VERIFIED | `font.mbt:411-455` performs pre-guard, glyph range validation, `font_decode_outline`, private after-decode seam, post-guard, then `Ok(path)`. Empty paths use the same facade. Mutation tests at `font_wbtest.mbt:674-730` pass in the four-target suite. |
| 2 | Simple glyphs strictly decode endpoints, instruction envelopes, packed/repeated flags, signed x/y deltas, exact padding, bounds, and maxp claims. | ✓ VERIFIED | `outline.mbt:502-809` enforces increasing endpoints, exact repeat expansion, reserved-bit/overlap placement, complete x-then-y streams, exact/one-zero-byte trailing rule, header bounds, and maxp-before-caller-limit ordering. Public hostile tests at `font_test.mbt:2212-2310` execute these paths. |
| 3 | Simple contours preserve encoded order/winding and implement exact TrueType quadratic starts, implied midpoints, lines, quadratics, deterministic `Close`, empty glyphs, and degenerate contours without executing instructions. | ✓ VERIFIED | `outline.mbt:399-499` lowers in stored order with the standard start/midpoint rules and one `Close` per endpoint. Zero-contour instructions are validated/skipped at `838-891`. Public/private exact-command and zero/degenerate tests execute these cases. |
| 4 | Coordinates, implied points, transforms, offsets, and attachments remain checked signed `Int64` Q15 until final `Point2` construction. | ✓ VERIFIED | Private representation and checked arithmetic are at `outline.mbt:2-20,105-247`; `Double` appears only in `font_outline_point`. Matrix-order, midpoint, subtraction, and exact public-coordinate tests pass. |
| 5 | Actual outline work is bounded by maxp, four nonzero retained outline limits, cumulative `max_work`, caller Budget, and precharged scratch/output allocations. | ✓ VERIFIED | `limits.mbt` validates and exposes all four ceilings. `outline.mbt:251-333` owns staged work/allocation charges; simple and composite paths preflight before arrays/path creation. Post-review graph-state slots use checked `num_glyphs * 8` at `1196-1205`. Exact-fit, one-short, empty-allocation, failure-consumption, and overflow tests pass. |
| 6 | Composite extraction classifies the complete reachable graph iteratively, reports cycles/malformed graphs as Data, reports only fully validated deeper acyclic graphs as Capability, and lowers no nested geometry. | ✓ VERIFIED | `outline.mbt:1178-1317` uses dense tri-color state plus an explicit frame stack. Visiting edges return `font-outline-composite-cycle`; `saw_deeper` is returned only after traversal and becomes Capability at `1357-1359`. Self-, multi-cycle, and deeper-acyclic tests pass. |
| 7 | One-level composites support first-component signed XY placement and later signed XY or real encoded-point attachment after transforming the child; implied points never enter attachment numbering. | ✓ VERIFIED | Descriptor parsing distinguishes `ComponentXY` and `ComponentPoints`; placement at `1521-1575` transforms child real points first and translates by parent-minus-child. The separate geometry point arrays exclude lowerer-created implied points. Exact attachment tests pass. |
| 8 | Uniform, independent-axis, and 2×2 F2DOT14 transforms use exact OpenType matrix ordering; scaled, unscaled, and default offsets remain distinct; grid rounding is Capability. | ✓ VERIFIED | Mutually exclusive transform parsing is at `970-1127`; `transform_q15` uses `xscale*x + scale10*y` and `scale01*x + yscale*y`. Offset handling is at `1534-1541`. Public matrix/cross-term/offset and grid tests pass. |
| 9 | Component order and contour winding are preserved; overlap and unique `USE_MY_METRICS` are geometry/metric neutral; reserved flags, duplicate metrics flags, phantom references, and invalid references keep their specified taxonomy. | ✓ VERIFIED | Parser validation is at `958-988`; components append in record order at `1387-1598`; point-index classification is at `1321-1337`. Public exact order, late overlap, metrics-neutral, phantom, bad point/glyph, and reserved-flag tests pass. |
| 10 | Malformed streams, invalid references/flags, cycles, arithmetic failures, mutation, and resource exhaustion return structured errors without exposing partial commands. | ✓ VERIFIED | Decoder/graph/lowerer state is private; only `Font::outline_after_decode` publishes. Data/Capability/Resource/State paths are directly asserted; foreign glyph tests assert InvalidInput. Fresh 92-test suites pass on every target. |
| 11 | The permanent generated public/private matrix exercises simple, empty/degenerate, transformed/attached composite, hostile, resource, mutation, and prior font behavior identically on all four targets. | ✓ VERIFIED | Fresh independent runs report 92/92 on native, js, wasm, and wasm-gc. The public tracer at `font_test.mbt:1357-1480` freezes exact `PathCommand` values; private tests freeze Q15, descriptors, graph state, allocation size, and mutation ordering. |
| 12 | The generated public interface contains only the intended Phase 99 additions over the repaired Phase 98 baseline and leaks no parser/descriptor/Q15 state. | ✓ VERIFIED | Fresh `moon info --target all` succeeds; generated SHA-256 is `d5bb5e76fe1448554aff2cf58e84b7a316d6f2255740736540cca956d89906e0`. The 50→56 semantic-line comparison adds math, `Font::outline`, four accessors, and the expanded constructor only. The independent private/deferred surface classifier passes. |
| 13 | The Phase 99 publication contract is internally consistent and enforced by repository policy. | ✗ FAILED | `Assert-FontFoundationPolicy` passes, but `Assert-FoundationPolicy -PolicyPath policy/foundation.json` fails: `Manifest description drift in modules/mb-font`. The actual `moon.mod.json` description omits outlines while policy describes them. |
| 14 | Public documentation accurately describes the delivered outline API, limits, five-way taxonomy, and exclusions without Phase 100 overclaim. | ✗ FAILED | Executable README checks pass on all targets and the delivered/excluded scope is accurate, but `README.mbt.md:283` incorrectly assigns maxp underclaim/exhaustion to Resource; code and `font_test.mbt:2303-2310` assign it to Data. |

**Score:** 12/14 truths verified (0 present-but-behavior-unverified)

### Roadmap and PLAN Must-Have Coverage

| Contract source | Resolution |
|---|---|
| ROADMAP SC1 — complete simple outlines with repeated flags, deltas, implied points, winding/order, closure | Truths 2-4 and 11 |
| ROADMAP SC2 — bounded one-level composites with XY/point placement and all supported transforms | Truths 6-9 and 11 |
| ROADMAP SC3 — deterministic empty/degenerate results, no hinting/rasterization | Truths 3, 10, and 11 |
| ROADMAP SC4 — structured failure for malformed/reference/flag/cycle/arithmetic/mutation/resource cases with no partial geometry | Truths 1, 5, 6, 9-11 |
| Plan 99-01 truths and D-01-D-07/D-10/D-16-D-23 | Truths 1-5 and 10-12 |
| Plan 99-02 truths and D-08-D-15/D-17-D-23 | Truths 5-11 |
| Plan 99-03 portability/interface/policy/documentation truths | Truths 11-14 |

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/font/outline.mbt` | Transactional simple/composite decoder and lowerer | ✓ VERIFIED | 1,647 substantive lines; private Q15, strict framing, iterative graph, placement, charging, and complete path construction are wired through `Font::outline`. |
| `modules/mb-font/font/font.mbt` | Public guarded query and retained limits | ✓ VERIFIED | Public signature is generated; retained `FontLimits`, two guards, receiving-font validation, and one publication point are present. |
| `modules/mb-font/font/limits.mbt` | Four explicit nonzero outline ceilings | ✓ VERIFIED | Constructor validation, storage, and accessors are substantive and public. |
| `modules/mb-font/font/tables.mbt` | Seven version-1 maxp outline facts | ✓ VERIFIED | One existing maxp decoder reads all required fields and retains them in `RequiredTableFacts`. |
| `modules/mb-font/font/metrics.mbt` | Shared admitted glyph-window helper | ✓ VERIFIED | `font_glyph_window` is used by metric bounds and outline root/component lookup. |
| `modules/mb-font/font/font_test.mbt` | Public exact-path/error/resource matrix | ✓ VERIFIED | Public tests call only public font, glyph, metrics, budget, and `Path2` APIs; 92-test package passes on four targets. |
| `modules/mb-font/font/font_wbtest.mbt` | Private Q15/graph/charging/mutation evidence | ✓ VERIFIED | Direct invariants include matrix order, point numbering, graph-state allocation, failure charging, and post-decode drift. |
| `modules/mb-font/font/generated_fonts_wbtest.mbt` | Checksum-correct independent generated fixtures | ✓ VERIFIED | Test-only builders produce simple/composite graphs and are consumed by white-box tests. |
| `modules/mb-font/font/pkg.generated.mbti` | Minimal final public interface | ✓ VERIFIED | Freshly regenerated, byte-stable, 56 semantic lines, ignored by repository policy but reproducible through `moon info`. |
| `policy/foundation.json` | Exact sources/imports/targets/interface contract | ⚠️ PARTIAL | Internal record and focused selector are exact, but its module description disagrees with the actual module manifest. |
| `scripts/quality/Assert-Policy.ps1` | Independent fail-closed font classifier | ⚠️ PARTIAL | Correctly rejects private/deferred surface but its focused font function does not catch manifest-description drift. The broader policy function does. |
| `modules/mb-font/README.mbt.md` | Executable accurate public contract | ⚠️ PARTIAL | Four-target literate checks pass; one taxonomy sentence contradicts implementation/tests. |
| `modules/mb-font/CHANGELOG.md` | Candidate release record | ✓ VERIFIED | Accurately records the direct query, limits, Q15, transactional behavior, and exclusions. |
| `README.md` | Equivalent English/Chinese discovery text | ✓ VERIFIED | Both language sections state generated-evidence simple/one-level composite outlines and reserve Phase 100 qualification. |

The literal artifact checker passed all 20 artifact declarations across the three plans. Substance and wiring were then checked manually because the generic key-link query cannot infer MoonBit same-package private-symbol relationships.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `font.mbt` | `outline.mbt` | `Font::outline_after_decode` → `font_decode_outline` | ✓ WIRED | Arguments include admitted metric index, retained maxp/limits, glyph index, and caller Budget; post-guard precedes return. |
| `outline.mbt` | `metrics.mbt` | `font_glyph_window` | ✓ WIRED | Root and component reads use admitted `loca` offsets and table-local `glyf` view. |
| `outline.mbt` | `tables.mbt`/`limits.mbt` | `MaxpFacts` then `FontLimits` then work/Budget | ✓ WIRED | Point, contour, component, depth, and instruction claims have executable precedence tests. |
| `outline.mbt` | `mb-core/math` | final `Point2`/`PathCommand`/`Path2` construction | ✓ WIRED | Private Q15 converts only at final point construction; path stays local until the facade returns it. |
| Tests | public/private implementation | generated bytes and exact result assertions | ✓ WIRED | Public tracer and hostile cases execute in the same 92-test package on each target. |
| `pkg.generated.mbti` | `policy/foundation.json` | exact semantic interface sequence | ✓ WIRED | Current generated semantic lines match policy and the focused selector. |
| `policy/foundation.json` | `scripts/quality/Assert-Policy.ps1` | exact-set/interface/deferred-surface classifier | ✓ WIRED | Focused selector passes. |
| `policy/foundation.json` | `modules/mb-font/moon.mod.json` | module description | ✗ NOT WIRED | Descriptions differ; the repository-wide policy gate fails. |
| `README.mbt.md` | implementation/tests | documented error taxonomy | ⚠️ PARTIAL | API/exclusions match, but maxp failure classification does not. |

## Data-Flow Trace

| Query | Data | Source | Produces real data | Status |
|---|---|---|---|---|
| Simple outline | `PathCommand` sequence | caller bytes → admitted `loca`/`glyf` window → strict flags/deltas → private Q15 points → contour lowerer | Yes; exact move/line/quad/close values asserted | ✓ FLOWING |
| Composite outline | placed child points/contours | descriptor graph → direct simple/empty child windows → Q15 transform → XY/real-point translation → ordered lowerer | Yes; two-component transformed/attached path asserted | ✓ FLOWING |
| Structured failure | `CoreError` fields | identity, framing, maxp, limits, graph, arithmetic, Budget, and revision gates | Yes; category/code/context/requested/limit assertions cover all five categories | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Native full font regression/Phase 99 behavior | `moon -C modules/mb-font test font --target native ... --no-parallelize` | 92 passed, 0 failed | ✓ PASS |
| JavaScript full font regression/Phase 99 behavior | same with `--target js` | 92 passed, 0 failed | ✓ PASS |
| Wasm full font regression/Phase 99 behavior | same with `--target wasm` | 92 passed, 0 failed | ✓ PASS |
| Wasm-GC full font regression/Phase 99 behavior | same with `--target wasm-gc` | 92 passed, 0 failed | ✓ PASS |
| Native package check | `moon -C modules/mb-font check --target native --frozen` | exit 0 | ✓ PASS |
| Four-target literate README | `moon -C modules/mb-font check README.mbt.md --target <target> ... --serial` | exit 0 on all targets | ✓ PASS |
| Fresh generated interface | `moon -C modules/mb-font info --target all --frozen ...` | exit 0; expected hash | ✓ PASS |
| Focused font policy | `Assert-FontFoundationPolicy ...` | verified | ✓ PASS |
| Repository-wide policy | `Assert-FoundationPolicy ...` | `Manifest description drift in modules/mb-font` | ✗ FAIL |
| JSON and whitespace integrity | policy JSON parse; `git diff --check` | pass | ✓ PASS |

Only installed MoonBit core `builtin/result.mbt` emitted the known unused-value warnings; project sources reported no failure.

## Probe Execution

Step 7c: **SKIPPED** — no Phase 99 plan/summary declares a probe and no conventional Phase 99 probe exists.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| FONT-03 | 99-01, 99-02, 99-03 | Complete unhinted simple and bounded one-level composite `Path2` outlines with checked arithmetic and no partial geometry on failure | ✓ SATISFIED | All four ROADMAP success criteria are behaviorally verified by code inspection and fresh 92/92 four-target execution. Publication metadata/docs gaps do not invalidate the runtime behavior, but they block phase closure. |

No other requirement maps to Phase 99. Phase 100's licensed real-font/full-workflow qualification is later scope and does not cover either current gap.

## Prohibitions and Scope Fences

| Prohibition | Status | Evidence |
|---|---|---|
| No failed query exposes any partial `Path2` | ✓ VERIFIED | Private state plus single guarded return; late mutation/resource/error tests return only `Err`. |
| No simple contour normalization/reversal/flattening/overlap processing | ✓ VERIFIED | Stored arrays are traversed directly in encoded order; overlap bit is metadata. |
| No TrueType instruction execution | ✓ VERIFIED | Instruction bytes are length-checked, charged, window-validated, and skipped. |
| No recursive nested geometry | ✓ VERIFIED | Iterative structural traversal only; `saw_deeper` returns Capability before geometry lowering. |
| No implied point enters attachment numbering | ✓ VERIFIED | Attachment uses encoded `OutlineGeometry.points`; implied points exist only inside the path lowerer. |
| No `USE_MY_METRICS` rewrite of path or horizontal metrics | ✓ VERIFIED | Unique flag is parser metadata; metrics-neutral public test passes. |
| No private glyf/loca/maxp/descriptor/graph/Q15 public surface | ✓ VERIFIED | Generated interface and independent negative classifier contain/reject only the intended public types. |
| No nested/hint/raster/host/FFI/target-specific/dependency expansion | ✓ VERIFIED | Package has only mb-core imports and four targets; interface/policy negative probes pass; source scan found no implementation surface. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `scripts/quality/Assert-Policy.ps1` | 227 | Literal placeholder/TODO/TBD words in a rejection regex | ℹ️ Info | Validator text, not debt or a stub. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker, runtime placeholder, empty handler, or stub was found in Phase 99 implementation/test/policy/docs scope.

## Human Verification Required

None. This is a deterministic library/parser contract. Runtime transitions, ordering, mutation, resource, and portability behavior have executable tests; `behavior_unverified: 0`.

## Deferred Items

None. Phase 100 specifically owns licensed real-font and complete workflow qualification. It does not explicitly own current module-description synchronization or the incorrect maxp taxonomy sentence, so neither gap is deferred.

## Gaps Summary

The implementation achieves the user-facing outline goal and passes all fresh behavioral gates, including 92/92 on each supported target. Phase closure remains blocked by two auditable publication defects:

1. `modules/mb-font/moon.mod.json` is stale relative to `policy/foundation.json`, and the repository-wide policy gate fails.
2. `modules/mb-font/README.mbt.md` documents maxp underclaim/exhaustion as Resource even though the contract and tests correctly return Data.

Next action: run `$gsd-plan-phase --gaps` for these two publication-contract fixes, then re-run Phase 99 verification.

---

_Verified: 2026-07-27T12:22:13Z_
_Verifier: the agent (gsd-verifier)_
