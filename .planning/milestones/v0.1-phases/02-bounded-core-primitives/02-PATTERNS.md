# Phase 2: Bounded Core Primitives - Pattern Map

**Mapped:** 2026-07-16
**Mode:** generic-agent workaround for `gsd-pattern-mapper`
**Files classified:** 40 create/modify/delete targets across 6 public packages, 5 integration files, and 3 scaffold removals
**Analogs found:** 22 / 40 (structural matches dominate; no existing domain implementation exists)

## Scope Extraction

`02-CONTEXT.md` fixes the behavior but leaves exact package/type decomposition to planning. `02-RESEARCH.md` makes the package spine explicit and dependency ordered:

```text
error -> checked -> budget -> bytes -> io -> host
```

The file list below is therefore the concrete minimum implied by the six-package recommendation, mandatory public black-box tests, internal invariant tests, executable documentation, and integration with the existing root quality lane. Names inside a package are planning defaults, not additional public-contract decisions.

## File Classification

| New/Modified File | Action | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|---|
| `modules/mb-core/error/moon.pkg` | create | config | dependency/target metadata | `modules/mb-core/moon.pkg` | exact structural |
| `modules/mb-core/error/core_error.mbt` | create | model/utility | transform | `modules/mb-core/scaffold.mbt` | syntax-only |
| `modules/mb-core/error/diagnostics.mbt` | create | model/utility | ordered event collection + transform | none | no analog |
| `modules/mb-core/error/error_test.mbt` | create | test | batch/public request-response | none | no black-box analog |
| `modules/mb-core/error/error_wbtest.mbt` | create | test | batch/internal transform | `modules/mb-core/scaffold_wbtest.mbt` | role-match |
| `modules/mb-core/checked/moon.pkg` | create | config | dependency/target metadata | `modules/mb-color/moon.pkg` + `moon.mod.json` dependency direction | structural |
| `modules/mb-core/checked/checked.mbt` | create | utility | request-response transform | `modules/mb-core/scaffold.mbt` | syntax-only |
| `modules/mb-core/checked/range.mbt` | create | model/utility | request-response transform | none | no analog |
| `modules/mb-core/checked/dimensions.mbt` | create | model/utility | request-response transform | none | no analog |
| `modules/mb-core/checked/checked_test.mbt` | create | test | batch/public request-response | none | no black-box analog |
| `modules/mb-core/checked/checked_wbtest.mbt` | create | test | batch/internal invariants | `modules/mb-core/scaffold_wbtest.mbt` | role-match |
| `modules/mb-core/budget/moon.pkg` | create | config | dependency/target metadata | `modules/mb-core/moon.pkg` | structural |
| `modules/mb-core/budget/budget.mbt` | create | store/service | atomic state transition | none | no analog |
| `modules/mb-core/budget/budget_test.mbt` | create | test | batch/public state transitions | none | no black-box analog |
| `modules/mb-core/budget/budget_wbtest.mbt` | create | test | batch/internal invariants | `modules/mb-core/scaffold_wbtest.mbt` | role-match |
| `modules/mb-core/bytes/moon.pkg` | create | config | dependency/target metadata | `modules/mb-core/moon.pkg` | structural |
| `modules/mb-core/bytes/owned_bytes.mbt` | create | model/service | in-memory allocation + transform | none | no analog |
| `modules/mb-core/bytes/views.mbt` | create | model/service | validated zero-copy window transform | none | no analog |
| `modules/mb-core/bytes/bytes_test.mbt` | create | test | batch/public memory access | none | no black-box analog |
| `modules/mb-core/bytes/bytes_wbtest.mbt` | create | test | batch/lease and range invariants | `modules/mb-core/scaffold_wbtest.mbt` | role-match |
| `modules/mb-core/io/moon.pkg` | create | config | dependency/target metadata | `modules/mb-core/moon.pkg` | structural |
| `modules/mb-core/io/traits.mbt` | create | provider/model | streaming | none | no analog |
| `modules/mb-core/io/exact.mbt` | create | service/utility | streaming state machine | none | no analog |
| `modules/mb-core/io/memory.mbt` | create | provider/store | bounded in-memory streaming | none | no analog |
| `modules/mb-core/io/bounded.mbt` | create | middleware/provider | bounded streaming window | none | no analog |
| `modules/mb-core/io/io_test.mbt` | create | test | batch/public streaming | none | no black-box analog |
| `modules/mb-core/io/io_wbtest.mbt` | create | test | batch/internal state-machine invariants | `modules/mb-core/scaffold_wbtest.mbt` | role-match |
| `modules/mb-core/host/moon.pkg` | create | config | dependency/target metadata | `modules/mb-core/moon.pkg` | structural |
| `modules/mb-core/host/capabilities.mbt` | create | provider | request-response + event-driven contracts | none | no analog |
| `modules/mb-core/host/fakes.mbt` | create | provider/test double | deterministic request-response + events | none | no analog |
| `modules/mb-core/host/host_test.mbt` | create | test | batch/public capability conformance | none | no black-box analog |
| `modules/mb-core/host/host_wbtest.mbt` | create | test | batch/internal fake invariants | `modules/mb-core/scaffold_wbtest.mbt` | role-match |
| `modules/mb-core/README.mbt.md` | modify | documentation/test | executable examples + contract summary | same file | exact |
| `modules/mb-core/CHANGELOG.md` | modify | documentation | release/migration log | same file | exact |
| `policy/foundation.json` | modify | config/source of truth | machine-readable package inventory | same file | exact role, new cardinality |
| `scripts/quality/Assert-Policy.ps1` | modify | validator | batch metadata verification | same file, lines 673-711 | exact role, new cardinality |
| `scripts/quality/Invoke-MoonQuality.ps1` | modify | orchestrator/validator | batch four-target/docs/interface/package gates | same file, lines 92-145 | exact role, new package shape |
| `modules/mb-core/moon.pkg` | delete or deliberately replace with a non-public facade | config | package identity | same file | exact; decision required in plan |
| `modules/mb-core/scaffold.mbt` | delete | private utility | deterministic probe | same file | exact |
| `modules/mb-core/scaffold_wbtest.mbt` | delete | private test | batch | same file | exact |

`modules/mb-core/moon.mod.json` should normally remain unchanged: it already has the correct independent module identity, candidate version, preferred target, and exact four-target set. `moon.work` also remains unchanged because package decomposition occurs inside the existing workspace member.

## Pattern Assignments

### All six `moon.pkg` files (config, dependency/target metadata)

**Primary analog:** `modules/mb-core/moon.pkg`

**Portable target pattern** (line 1):

```moonbit
supported_targets = "+js+wasm+wasm-gc+native"
```

Every new public package must repeat this exact declaration. Do not infer support from the module manifest.

**Dependency-direction analog:** `modules/mb-color/moon.mod.json` lines 7-10 and `modules/mb-image/moon.mod.json` lines 7-11 demonstrate explicit inward dependencies and no umbrella dependency. For Phase 2, apply that principle at package level: import only earlier packages in the declared spine, never a later package and never a future native adapter.

**No exact repository analog:** the repository has no module with multiple package directories and no package-level import block. The planner must use the pinned MoonBit `moon.pkg` syntax verified during research, then immediately compile each new package on all four targets.

### `error/core_error.mbt` and `error/diagnostics.mbt` (model/utility, transform/events)

**Structural analog:** `modules/mb-core/scaffold.mbt` lines 1-4

```moonbit
///|
fn _scaffold_probe() -> String {
  "mb-core"
}
```

Copy only the repository's `///|` item separator and compact MoonBit formatting. Do not copy the private visibility or string-only contract.

**Domain pattern from research (no codebase analog):** public category/code enums; opaque `CoreError`; typed context accessors; optional source offsets; deterministic renderer with fixed field order and escaping; diagnostics retain encounter order. Adapter errors must be mapped into bounded portable context and must not expose paths, clocks, foreign exception names, or platform numbers.

### `checked/*.mbt` (utility/model, request-response transform)

**Structural analog:** `modules/mb-core/scaffold.mbt` lines 1-4 only.

**Required implementation pattern (no codebase analog):**

```moonbit
pub fn checked_add(a : UInt64, b : UInt64) -> Result[UInt64, CoreError] {
  if a > @uint64.MAX_VALUE - b {
    Err(CoreError::overflow(operation="add", left=a, right=b))
  } else {
    Ok(a + b)
  }
}
```

Apply the guard-before-operator shape to addition, multiplication, alignment, range construction, dimensions, offsets, allocation sizes, and `UInt64 -> Int` narrowing. `Range` stores a validated half-open `[start, end)` window computed from checked `start + length`; empty ranges remain valid.

### `budget/budget.mbt` (store/service, atomic state transition)

**No repository analog.** Use the research ledger pattern:

- represent one shared mutable ledger;
- validate every counter in a multi-dimensional charge before modifying any counter;
- commit the whole charge atomically;
- child scopes share the parent ledger and may narrow but never reset limits;
- acquire depth before work and balance leave with `defer` on every exit path.

The public tests must prove rejected charges leave every counter unchanged and child scopes cannot bypass the parent.

### `bytes/owned_bytes.mbt` and `bytes/views.mbt` (model/service, memory transform)

**No repository analog.** Wrap MoonBit built-ins rather than expose them:

- opaque owned storage backed by `Bytes`/`FixedArray[Byte]`;
- opaque immutable view stores backing identity plus validated start/length;
- subviews validate relative to the current view, then use zero-copy backing access;
- mutable access uses a shared active lease and never returns raw `MutArrayView`;
- `split_mut` invalidates/consumes the parent logical lease and produces children only after checked disjoint partitioning;
- budget/range rejection precedes allocation or access.

The physical OOM seam has no portable repository or runtime analog. Keep an injectable allocator/adapter mapping path for `AllocationFailed`; do not claim that built-in unrecoverable OOM is catchable.

### `io/*.mbt` (provider/service/middleware, streaming)

**No repository analog.** Use separate object-safe `Reader`, `Writer`, and `Seeker` traits. Seeking is capability presence, not a mandatory method that commonly fails.

**Outcome-state pattern from research:**

```moonbit
pub(all) enum ReadOutcome {
  Progress(UInt64)
  EndOfStream
  Failed(CoreError, completed~ : UInt64)
}

pub(open) trait Reader {
  read(Self, MutByteLease) -> ReadOutcome
}
```

Exact helpers return immediately for zero-length requests, loop over partial progress, preserve completed counts on failure, distinguish EOS, and reject one no-progress transition deterministically. In-memory and bounded providers own a checked cursor/window and cap each operation by both buffer capacity and logical remaining length.

### `host/*.mbt` (provider and test doubles, request-response/events)

**No repository analog.** Define small independent open traits for files/resources, diagnostics/logging, clock, cancellation, and resource resolution. Do not create a global fallback or all-capabilities singleton. Portable fakes must be explicit, deterministic, bounded, and individually composable.

### Public `*_test.mbt` files (test, batch/public API)

**No repository analog:** Phase 1 intentionally created only private white-box scaffold tests. These tests must import the public package as an external consumer and validate only public API behavior. Each package needs success, boundary, and structured-failure cases; adversarial categories include overflow/narrowing, overlapping lease rejection, use-after-scope, exact-I/O no-progress, shared-budget bypass, and deterministic rendering.

### Internal `*_wbtest.mbt` files (test, batch/internal invariants)

**Analog:** `modules/mb-core/scaffold_wbtest.mbt` lines 1-4

```moonbit
///|
test "private scaffold is deterministic" {
  inspect(_scaffold_probe(), content="mb-core")
}
```

Copy the concise named-test structure and deterministic `inspect` expectations. Replace the scaffold probe with package-local invariants that cannot be observed through the public API. Keep snapshots small and textual; binary behavior should use semantic assertions or checked bytes/digests.

### `modules/mb-core/README.mbt.md` (documentation and doc tests)

**Analog:** same file, especially lines 8-16 (candidate/publication status), 18-25 (scope boundary), 27-39 (target matrix), and 41-50 (design commitments).

Preserve the candidate label, namespace publication block, exact target table, native-leaf rule, and independent lifecycle language. Replace the Phase 1 “no public API” statements at lines 5-6, 10-11, 25, and 52-55 with checked Phase 2 examples. Examples must be executable `.mbt.md` black-box documentation tests and show structured failure handling rather than panic paths.

### `policy/foundation.json` (machine-owned package inventory)

**Analog:** lines 30-56 define the current `mb-core` record. Preserve module identity, version, candidate stability, targets, and zero module dependencies. Replace the single root `public_packages` entry at lines 44-55 with the six public package paths/names selected by planning.

**Cross-module pattern:** lines 118-130 encode exact allowed dependency edges. Phase 2 internal package edges need their own machine-readable representation only if the policy validator is expanded to verify them; do not misstate internal package edges as module dependencies.

### `scripts/quality/Assert-Policy.ps1` (validator, batch metadata)

**Analog:** lines 673-711.

Copy these fail-closed techniques:

- exact normalized set comparisons for targets and identities;
- read values from `policy/foundation.json`, then compare manifests/files to that source;
- use case-sensitive comparisons for canonical names/paths;
- emit contextual failure messages;
- verify every declared package rather than assuming the root package.

The current lines 677-681 hard-code exactly one root public package and must be generalized for six package records. Lines 701-704 also read only the root `moon.pkg`; iterate policy-owned package paths instead.

### `scripts/quality/Invoke-MoonQuality.ps1` (quality orchestrator, batch)

**Analog:** lines 6-19 provide a named fail-fast stage wrapper; lines 92-145 define the Required lane.

```powershell
Invoke-QualityStage "WORK-05 test target $target" {
  Invoke-MoonCommand -Context "workspace test target $target" -Arguments @('test', '--target', $target, '--frozen')
}
```

Preserve target-by-target check/test execution (lines 116-123), per-module docs/info generation (124-132), package listing through Moon itself (133-137), and read-only tracked-checkout proof (139-144).

The current generated-interface classifier at lines 41-57 expects one empty root package, while the package allowlist at lines 59-84 permits exactly six Phase 1 files. Generalize both to policy-owned multi-package expectations and exact publication content; do not weaken them to “file exists” or a broad wildcard.

### Scaffold/root-package removal

`modules/mb-core/scaffold.mbt` and `scaffold_wbtest.mbt` are explicitly private Phase 1 proofs and should disappear when real packages land. The root `moon.pkg` should also disappear if planning adopts the research-recommended six-package-only structure. If a root facade is retained, it must be an intentional seventh public package with documented dependency/API purpose; leaving the empty root package accidentally would contradict the package-spine recommendation and complicate interface/package assertions.

## Shared Patterns

### Portability and dependency direction

**Sources:** `modules/mb-core/moon.mod.json` lines 1-8; `modules/mb-core/moon.pkg` line 1; `policy/foundation.json` lines 30-56.

Apply exact `+js+wasm+wasm-gc+native` metadata to every public package. Native remains preferred at module level, but no Phase 2 package imports native FFI or ambient host state. Dependencies point only toward earlier packages in the Phase 2 spine.

### Structured failure before effects

**Source:** no existing code analog; locked by D-01, D-07, D-09, D-12, and D-15.

Apply to checked arithmetic, view construction, allocation, cursor changes, stream helpers, budget charges, and adapter mapping. Validate before operator/access/allocation/work; return stable category/code plus typed bounded context.

### Test layering

**Source:** `modules/mb-core/scaffold_wbtest.mbt` lines 1-4 plus repository stack policy.

- `*_test.mbt`: mandatory public black-box contract tests.
- `*_wbtest.mbt`: representation, lease, parser/state-machine, and arithmetic invariants.
- `README.mbt.md`: executable consumer examples.
- root Required lane: all four declared targets, docs, interfaces, package contents, and read-only proof.

### Determinism

**Sources:** scaffold test deterministic naming; README lines 43-46; Required lane lines 116-145.

No locale, clock, filesystem, path, backend exception text, unordered diagnostic output, or implicit capabilities may affect public results. Use exact textual assertions only for canonical renderers and small structured diagnostics.

## No Analog Found

| File/Area | Role | Data Flow | Reason / Planning Guidance |
|---|---|---|---|
| All public `*_test.mbt` files | test | batch/public API | Repository currently has only white-box scaffold tests; establish black-box import convention in the first package and copy it forward. |
| `error/diagnostics.mbt` | model/utility | ordered events + transform | No structured diagnostic vocabulary or renderer exists. Use research contract, not `Debug`. |
| `checked/range.mbt`, `checked/dimensions.mbt` | model/utility | transform | No checked public value types exist. Use opaque validated constructors. |
| `budget/budget.mbt` | store/service | atomic state transitions | No shared mutable ledger or hierarchical scope exists. Spike atomic charge/defer behavior early. |
| `bytes/*.mbt` | model/service | memory I/O/transform | No owned/view/lease abstraction exists. Run the mutable-lease API spike before publishing names. |
| `io/*.mbt` | provider/service | streaming | No stream traits, explicit outcomes, cursor, bounded adapter, or exact helper exists. Follow the research state machine. |
| `host/*.mbt` | provider | request-response/events | No capability interfaces or fakes exist. Keep interfaces granular and explicitly injected. |
| Multi-package interface/package validation | validator | batch | Current scripts assume one empty root package. Generalize against policy-owned exact package records, not hard-coded broad acceptance. |

## Planner Notes

1. Land `error` first so every later package shares one failure vocabulary.
2. Compile a minimal `checked` package next to confirm exact constants/conversions on the pinned toolchain.
3. Treat mutable lease ergonomics and allocator-failure injection as explicit early spikes inside their owning plans; both are research open questions.
4. Add black-box and white-box tests beside each package, not as a final testing plan.
5. Update policy and quality classifiers in the same plan that first changes package topology, so the Required lane never has an intentionally weakened interval.
6. Keep source filenames package-local and modest; MoonBit packages, not individual files, are the public namespace boundary.

## Metadata

**Graph search:** `moonbit-foundation` graph scoped to `modules/`; 57 indexed nodes, documentation/config only, no MoonBit function symbols.  
**Fallback search scope:** `modules/`, `scripts/quality/`, `.github/workflows/quality.yml`, `policy/foundation.json`, and `moon.work`.  
**Strong repository analogs read:** 17 files across the three module scaffolds, root quality workflow, CI, and foundation policy.  
**Pattern extraction date:** 2026-07-16
