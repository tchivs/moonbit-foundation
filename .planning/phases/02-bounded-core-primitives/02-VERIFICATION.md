---
phase: 02-bounded-core-primitives
verified: 2026-07-16T16:21:53Z
status: gaps_found
score: 11/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Callers can repeatedly use validated mutable byte views, including callback-scoped split leases, without escaping allocation or leaving the owner permanently leased."
    status: failed
    reason: "OwnedBytes::with_mut defers release of only the original lease. split_mut invalidates that parent and replaces its live-handle count with two children, so the deferred parent release is a no-op. If the callback does not explicitly release both children, owner.leased never returns to false and all later mutable acquisitions fail. The checked README example follows this path."
    artifacts:
      - path: "modules/mb-core/bytes/views.mbt"
        issue: "Callback cleanup does not invalidate/release descendant leases created by split_mut."
      - path: "modules/mb-core/bytes/bytes_wbtest.mbt"
        issue: "Split coverage releases both children explicitly; there is no callback-exit cleanup regression test after a split."
      - path: "modules/mb-core/README.mbt.md"
        issue: "The public split-lease example omits child release and never proves that a later with_mut call remains possible."
    missing:
      - "Make callback-scope cleanup invalidate the entire lease group, including live split descendants, and restore owner availability exactly once."
      - "Add an all-target regression test that splits inside with_mut, omits explicit child release, exits normally and through Err, verifies stale child rejection, then successfully reacquires mutable access."
      - "Keep the README example honest by demonstrating post-callback reacquisition or by documenting and using the required scoped cleanup API."
---

# Phase 2: Bounded Core Primitives Verification Report

**Phase Goal:** `mb-core` provides the safe, backend-neutral primitives required to process untrusted binary data without unchecked ranges, ambient capabilities, or unbounded work.
**Verified:** 2026-07-16T16:21:53Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Checked arithmetic, ranges, dimensions, offsets, alignment, casts, and allocation sizes reject overflow before effects. | ✓ VERIFIED | Guard-before-operator implementations are present in `checked.mbt`, `range.mbt`, and `dimensions.mbt`; boundary tests run in the independent four-target Required lane. |
| 2 | Owned bytes, immutable views, mutable views, and bounded in-memory readers/writers stay within declared ranges and remain reusable after scoped operations. | ✗ FAILED | Bounds checks and retained views are substantive, but split children escape callback cleanup: `with_mut` defers only `lease.release()` while `split_mut` first sets the parent inactive and changes the group to two live handles. The owner therefore remains leased unless callers explicitly release both children. |
| 3 | Backend-neutral I/O distinguishes progress, EOS, partial failure, no-progress, and optional seeking. | ✓ VERIFIED | `ReadOutcome`, `WriteOutcome`, separate `Seeker`, `read_exact`, and `write_all` are wired; tests cover partial/EOS/failure/no-progress/zero-length behavior on all four targets. |
| 4 | Errors and diagnostics provide stable machine-readable codes/context and deterministic rendering. | ✓ VERIFIED | Opaque `CoreError`, stable enums, typed fields, bounded context, canonical escaping/order, host-detail discard, and encounter-ordered diagnostics are implemented and tested. |
| 5 | Resource budgets stop prohibited work atomically and share hierarchical state. | ✓ VERIFIED | `Budget::charge` preflights every ancestor before any commit; `child`, `enter_depth`, idempotent `leave`, and `with_depth` share and balance state. Atomic rollback, thresholds, parent sharing, and success/error cleanup tests passed on all targets. |
| 6 | Host effects are granular, explicit, optional capabilities with deterministic portable doubles and no ambient fallback. | ✓ VERIFIED | Five independent open traits and instance-local fakes exist; source/policy scans reject ambient access, native aggregates, and globals; host tests passed on all targets. |
| 7 | Logical quantities remain `UInt64`, half-open empty ranges are valid, and backend narrowing never truncates. | ✓ VERIFIED | The sole direct `UInt64.to_int()` is guarded inside `checked_narrow_int`; exact/one-over boundaries, empty ranges, adjacency, and overflowed endpoints are tested. |
| 8 | Budget rejection, injected allocator rejection, and unrecoverable built-in physical OOM are represented honestly and distinctly. | ✓ VERIFIED | `Allocator::approve` exposes injected `AllocationFailed`; budget/range failures are distinct; source, tests, README, and negative prose fixture explicitly reject a catchable physical-OOM claim. |
| 9 | Exactly six public packages replace the root scaffold in the required acyclic order. | ✓ VERIFIED | Policy owns `error -> checked -> budget -> bytes -> io -> host`; every `moon.pkg` has exact four-target metadata/imports; root `moon.pkg`, `scaffold.mbt`, and `scaffold_wbtest.mbt` are absent. |
| 10 | Policy-driven classifiers fail closed for topology, imports, interfaces, package contents, and prohibitions. | ✓ VERIFIED | Independent Required run rejected root/extra/missing/reverse topology, undeclared surface, raw mutable backing, unchecked narrowing, ambient access, false OOM prose, and broken README input. |
| 11 | Root Required qualifies all four targets, executable docs, exact artifacts, and read-only behavior. | ✓ VERIFIED | `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` exited 0; js/wasm/wasm-gc/native each reported 62/62 tests, README checks ran per target, interfaces/package lists matched exactly, and tracked-read-only proof passed. |
| 12 | Public examples demonstrate checked failures, budgets, ownership, bounded I/O, separate seeking, diagnostics, OOM distinctions, and explicit host injection. | ✓ VERIFIED | README literate checks compile on all four targets and cover each family. The split-lease example compiles but also exposes the failed lifecycle truth in item 2. |

**Score:** 11/12 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact group | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-core/error/{core_error,diagnostics}.mbt` | Stable structured errors/diagnostics | ✓ VERIFIED | Substantive implementation, public tests, policy interface, and consumers in every later package. |
| `modules/mb-core/checked/{checked,range,dimensions}.mbt` | Safe logical arithmetic/ranges | ✓ VERIFIED | Substantive guards and all-target boundary coverage; imported by budget/bytes/io/host. |
| `modules/mb-core/budget/budget.mbt` | Atomic hierarchical budget ledger | ✓ VERIFIED | Full preflight/commit separation, shared windows, balanced depth, and behavioral tests. |
| `modules/mb-core/bytes/{owned_bytes,views}.mbt` | Owned storage and safe immutable/mutable views | ✗ PARTIAL | Bounds and alias validation exist, but scoped cleanup is not group-wide after `split_mut`. |
| `modules/mb-core/io/{traits,exact,memory,bounded}.mbt` | Explicit stream states and bounded providers | ✓ VERIFIED | Wired to bytes/budget/checked/error; behavioral tests cover exact and bounded transitions. |
| `modules/mb-core/host/{capabilities,fakes}.mbt` | Explicit capability contracts and doubles | ✓ VERIFIED | Five traits, one fake per trait, deterministic instance-local behavior, no native adapter. |
| `modules/mb-core/README.mbt.md` | Executable public contract | ✓ VERIFIED WITH GAP NOTE | Compiles on four targets; its split example does not detect the lease-group cleanup defect. |
| `policy/foundation.json` and quality scripts | Exact six-package qualification | ✓ VERIFIED | Exact metadata/interfaces/contents plus fail-closed negative fixtures and README execution. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `checked/moon.pkg` | `mb-core/error` | sole failure dependency | ✓ WIRED | Exact import and public error use. |
| `budget/moon.pkg` | checked/error | checked counters and structured limits | ✓ WIRED | Preflight calls checked subtraction; errors use `CoreError`. |
| `owned_bytes.mbt` | budget | charge before built-in allocation | ✓ WIRED | `budget.charge` completes before `FixedArray::make`. |
| `io/*.mbt` | bytes | retained views and leases | ✓ WIRED | Reader windows wrap leases; writers consume ByteView; memory providers use OwnedBytes. |
| `host/fakes.mbt` | host traits | explicit `impl` per capability | ✓ WIRED | File, diagnostic, clock, cancellation, and resolver doubles implement their individual traits. |
| `Invoke-MoonQuality.ps1` | `README.mbt.md` | target-qualified `moon check` | ✓ WIRED | Required loop executes exact check for js, wasm, wasm-gc, and native. |
| `foundation.json` | six `moon.pkg` files | exact identity/target/import comparison | ✓ WIRED | Policy assertion and package/interface classifiers passed. |
| `OwnedBytes::with_mut` | split descendant cleanup | deferred lease-group release | ✗ NOT WIRED | Deferred cleanup targets the invalidated parent handle, not the live group descendants. |

### Data-Flow Trace (Level 4)

Not applicable: Phase 2 produces library primitives and policy automation, not dynamic UI/data-rendering artifacts. The equivalent state-flow checks were performed on budget ledgers, stream cursors, and lease-group ownership.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Complete required qualification | `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` | Exit 0; 62/62 tests on each of four targets; docs/interfaces/packages/negative fixtures/read-only proof passed | ✓ PASS |
| Mutable callback cleanup without split | Existing test `callback cleanup invalidates stale handles and permits reacquisition` in the full Required run | Passed on all targets | ✓ PASS |
| Mutable callback cleanup after split | Source trace: `with_mut` defer at `views.mbt:109`, parent invalidation/live-handle replacement at `views.mbt:255-256`, owner reset only at `views.mbt:232-233` | No regression test; source path deterministically leaves two live handles after callback | ✗ FAIL |

### Probe Execution

SKIPPED: no phase plan declares a probe script and no conventional `probe-*.sh` applies. The executable verification contract is the root Required lane.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| CORE-01 | 02-02, 02-07 | ✓ SATISFIED | Checked arithmetic/range/dimension/narrowing implementations and boundary tests. |
| CORE-02 | 02-04, 02-07 | ✗ BLOCKED | Bounds safety exists, but the documented callback-scoped split lease can permanently poison future mutable acquisition. |
| CORE-03 | 02-05, 02-07 | ✓ SATISFIED | Explicit read/write outcomes and exact helpers with partial/EOS/failure/no-progress tests. |
| CORE-04 | 02-05, 02-07 | ✓ SATISFIED | Bounded nested reader/writer and memory providers operate without filesystem/full buffering. |
| CORE-05 | 02-05, 02-07 | ✓ SATISFIED | `Seeker` is independent; seek boundaries validate before cursor mutation. |
| CORE-06 | 02-01, 02-07 | ✓ SATISFIED | Stable codes, typed context, deterministic rendering, and host-detail exclusion. |
| CORE-07 | 02-03, 02-07 | ✓ SATISFIED | Atomic multidimensional budgets, shared children, and balanced depth tests. |
| CORE-08 | 02-06, 02-07 | ✓ SATISFIED | Explicit optional host traits/doubles and fail-closed ambient/native prohibition scans. |

No Phase 2 requirements are orphaned from the plans.

### Prohibition Verification

| Prohibition | Enforcement evidence | Verdict |
|---|---|---|
| No prose parsing or ambient/backend error semantics | Exact structured API, deterministic snapshots, foreign-detail discard tests | ✓ VERIFIED |
| No catchable built-in physical OOM claim | Allocator-double tests, README/source language, negative prose fixture | ✓ VERIFIED |
| No ambient host fallback/native adapter/all-capabilities singleton | Exact interface/source policy and negative ambient fixture | ✓ VERIFIED |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `modules/mb-core/bytes/views.mbt` | 109, 230-256 | Parent-handle cleanup used for a group whose parent can be consumed into children | 🛑 Blocker | Normal documented callback use can permanently prevent future mutable access. |
| Phase-modified files | — | `TBD` / `FIXME` / `XXX` | None | No unreferenced debt markers found. Matches for `fake`/long test strings are intentional capability doubles and fixtures, not stubs. |

### Disconfirmation Pass

- **Partially met requirement:** CORE-02 has strong bounds and alias checks, but callback-scoped split cleanup is incomplete.
- **Misleading passing test:** `checked split consumes parent and yields disjoint active children` passes only because it explicitly releases both children; it does not exercise the public `with_mut` cleanup promise. The README example omits those releases and still compiles because it never attempts reacquisition.
- **Uncovered error/cleanup path:** normal or `Err` callback exit after `split_mut` with retained/unreleased children has no test and cannot reset the owner under the current implementation.

### Human Verification Required

None. The blocking lifecycle outcome is deterministically established by the source state transitions; visual, external-service, and performance judgments are not part of this phase.

### Gaps Summary

One root-cause gap blocks Phase 2 completion: mutable lease cleanup is handle-local while splitting creates group descendants. The fix must make callback exit invalidate the entire lease group and restore owner availability exactly once, then add all-target regression coverage for normal and error exits. This concern is not deferred by Phases 3-5; those phases consume `mb-core` and therefore require the lifecycle invariant now.

---

_Verified: 2026-07-16T16:21:53Z_
_Verifier: the agent (gsd-verifier)_
