---
phase: 02-bounded-core-primitives
verified: 2026-07-16T16:45:50Z
status: passed
score: 12/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 11/12
  gaps_closed:
    - "Callback exit now invalidates the complete mutable lease group, including nested split descendants, and restores owner availability exactly once on normal and structured-error exits."
  gaps_remaining: []
  regressions: []
---

# Phase 2: Bounded Core Primitives Verification Report

**Phase Goal:** `mb-core` provides the safe, backend-neutral primitives required to process untrusted binary data without unchecked ranges, ambient capabilities, or unbounded work.
**Verified:** 2026-07-16T16:45:50Z
**Status:** passed
**Re-verification:** Yes — after Plan 02-08 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Checked arithmetic, ranges, dimensions, offsets, alignment, casts, and allocation sizes reject overflow before effects. | ✓ VERIFIED | Quick regression: implementations and boundary tests remain present; the independent Required lane passed all four targets. |
| 2 | Owned bytes, immutable views, mutable views, and bounded in-memory readers/writers stay within declared ranges and remain reusable after scoped operations. | ✓ VERIFIED | Full re-verification: callback cleanup now defers `LeaseGroup::cleanup_scope`, every descendant operation checks shared `scope_active`, cleanup normalizes handle state and restores the owner once, and normal/error/nested/mixed-release behavioral tests pass on all targets. |
| 3 | Backend-neutral I/O distinguishes progress, EOS, partial failure, no-progress, and optional seeking. | ✓ VERIFIED | Quick regression: interfaces and implementations are unchanged; Required exercised all I/O tests on four targets. |
| 4 | Errors and diagnostics provide stable machine-readable codes/context and deterministic rendering. | ✓ VERIFIED | Quick regression: exact interface remained 57 semantic lines and deterministic tests passed in Required. |
| 5 | Resource budgets stop prohibited work atomically and share hierarchical state. | ✓ VERIFIED | Quick regression: budget artifacts are unchanged and atomic/hierarchical tests passed in Required. |
| 6 | Host effects are granular, explicit, optional capabilities with deterministic portable doubles and no ambient fallback. | ✓ VERIFIED | Quick regression: exact host interface remained 48 lines; ambient/native prohibition scans and tests passed. |
| 7 | Logical quantities remain `UInt64`, half-open empty ranges are valid, and backend narrowing never truncates. | ✓ VERIFIED | Quick regression: checked interface remained 32 lines; source prohibition and boundary tests passed. |
| 8 | Budget rejection, injected allocator rejection, and unrecoverable built-in physical OOM are represented honestly and distinctly. | ✓ VERIFIED | Quick regression: allocator/budget tests, README language, and false-OOM negative fixture passed unchanged. |
| 9 | Exactly six public packages replace the root scaffold in the required acyclic order. | ✓ VERIFIED | Quick regression: exact policy/DAG/package inventory passed; no root scaffold returned. |
| 10 | Policy-driven classifiers fail closed for topology, imports, interfaces, package contents, and prohibitions. | ✓ VERIFIED | Required rejected all ten negative fixtures, including topology, reverse dependency, surface, backing, narrowing, ambient access, OOM prose, and missing README. |
| 11 | Root Required qualifies all four targets, executable docs, exact artifacts, and read-only behavior. | ✓ VERIFIED | `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` exited 0 with 66/66 tests per target, four README checks, exact interfaces/package lists, and tracked-read-only proof. |
| 12 | Public examples demonstrate checked failures, budgets, ownership, bounded I/O, separate seeking, diagnostics, OOM distinctions, and explicit host injection. | ✓ VERIFIED | README now performs a second `with_mut` after an unreleased split callback; its literate checks pass on js, wasm, wasm-gc, and native. |

**Score:** 12/12 truths verified (0 present-but-behavior-unverified)

### Gap Closure Verification

| Previous gap condition | Current evidence | Status |
|---|---|---|
| Callback deferred cleanup released only the consumed parent handle. | `LeaseOwner::with_mut` now defers `lease.group.cleanup_scope()`. | ✓ CLOSED |
| Split descendants could remain active after callback exit. | `checked_index` and `split_mut` require both handle activity and shared group-scope activity; retained descendants fail closed after cleanup. | ✓ CLOSED |
| Owner could remain permanently leased after unreleased children. | `cleanup_scope` marks scope inactive, normalizes `live_handles` to zero, and invokes idempotent `restore_owner_once`. Reacquisition passes after normal and Err exits. | ✓ CLOSED |
| Nested split and mixed explicit release paths were uncovered. | Named nested-descendant and zero/one/all explicit-release tests pass on every required target. | ✓ CLOSED |
| README example did not prove reuse. | The executable example reacquires mutable access and writes after the split callback exits. | ✓ CLOSED |

### Required Artifacts

| Artifact group | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-core/error/{core_error,diagnostics}.mbt` | Stable structured errors/diagnostics | ✓ VERIFIED | Quick regression; exact interface and tests pass. |
| `modules/mb-core/checked/{checked,range,dimensions}.mbt` | Safe logical arithmetic/ranges | ✓ VERIFIED | Quick regression; exact interface and tests pass. |
| `modules/mb-core/budget/budget.mbt` | Atomic hierarchical budget ledger | ✓ VERIFIED | Quick regression; exact interface and tests pass. |
| `modules/mb-core/bytes/views.mbt` | Group-wide callback cleanup and descendant invalidation | ✓ VERIFIED | Substantive shared-scope implementation; wired from `with_mut`, checked by all descendant access/split paths, and behaviorally exercised. |
| `modules/mb-core/bytes/bytes_test.mbt` | Public normal/Err lifecycle regressions | ✓ VERIFIED | Normal exit checks stale get/set/split and reacquisition; Err exit checks error preservation, repeated release, staleness, and reacquisition. |
| `modules/mb-core/bytes/bytes_wbtest.mbt` | Nested/mixed/exact-once invariants | ✓ VERIFIED | Nested descendants, normalized count, owner restoration, repeated release, and zero/one/all explicit release cases pass. |
| `modules/mb-core/io/{traits,exact,memory,bounded}.mbt` | Explicit stream states and bounded providers | ✓ VERIFIED | Quick regression; exact interface and tests pass. |
| `modules/mb-core/host/{capabilities,fakes}.mbt` | Explicit capability contracts and doubles | ✓ VERIFIED | Quick regression; exact interface, tests, and prohibitions pass. |
| `modules/mb-core/README.mbt.md` | Executable public contract with post-split reacquisition | ✓ VERIFIED | Reacquisition is explicit and all four target-qualified checks pass. |
| `policy/foundation.json` and quality scripts | Exact six-package qualification | ✓ VERIFIED | Private lifecycle fix preserved the 30-line bytes interface and exact package contents. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `LeaseOwner::with_mut` | `LeaseGroup` | deferred group cleanup | ✓ WIRED | `defer lease.group.cleanup_scope()` executes on both normal and structured-error returns. |
| `LeaseGroup::cleanup_scope` | owner availability | shared scope close and exact-once restoration | ✓ WIRED | Scope becomes inactive, live handles normalize to zero, and `restore_owner_once` clears `owner.leased` once. |
| `MutByteLease::{checked_index,split_mut,release}` | shared group lifecycle | group-scope checks/accounting | ✓ WIRED | Access/split reject inactive scope; release is idempotent and cannot underflow after cleanup. |
| Public/internal lifecycle tests | `OwnedBytes::with_mut` | retained descendants and reacquisition | ✓ WIRED | Normal, Err, nested, mixed-release, stale-operation, and reacquisition paths are directly exercised. |
| `Invoke-MoonQuality.ps1` | README and package policy | four-target checks/classifiers | ✓ WIRED | Required executes docs/tests and exact interface/package checks for all targets. |

Previously passed key links for checked/error, budget, bytes allocation precharge, I/O, host capabilities, and six-package policy remain present and passed the quick regression gate.

### Data-Flow Trace (Level 4)

Not applicable to UI data. Mutable lifecycle state flow was traced directly:

`with_mut acquisition -> shared LeaseGroup -> nested split net handle increments -> optional explicit releases -> deferred cleanup_scope -> scope inactive/live_handles=0 -> restore_owner_once -> later reacquisition`.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Normal split callback exit, stale get/set/split, reacquisition | `moon -C modules/mb-core test bytes --target all --frozen --filter "split descendants are stale after normal callback exit and owner reacquires"` | 1/1 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Structured Err preservation, stale descendants, repeated release, reacquisition | `moon -C modules/mb-core test bytes --target all --frozen --filter "split descendants are stale after structured error and error is preserved"` | 1/1 passed on all four targets | ✓ PASS |
| Nested descendants, live-count normalization, exact-once owner restoration | `moon -C modules/mb-core test bytes --target all --frozen --filter "callback cleanup invalidates nested descendants and restores owner once"` | 1/1 passed on all four targets | ✓ PASS |
| Zero/one/all explicit child release before callback exit | `moon -C modules/mb-core test bytes --target all --frozen --filter "callback cleanup tolerates zero one or all explicit child releases"` | 1/1 passed on all four targets | ✓ PASS |
| Complete regression and qualification | `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` | Exit 0; 66/66 per target, docs/interfaces/packages/negative fixtures/read-only proof passed | ✓ PASS |

### Probe Execution

SKIPPED: no phase plan declares a probe script. Named MoonBit tests and the root Required lane are the executable verification contract.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| CORE-01 | 02-02, 02-07 | ✓ SATISFIED | Quick regression passed. |
| CORE-02 | 02-04, 02-07, 02-08 | ✓ SATISFIED | Full lifecycle re-verification closed the sole gap across normal, Err, nested, mixed-release, stale-operation, and reacquisition paths. |
| CORE-03 | 02-05, 02-07 | ✓ SATISFIED | Quick regression passed. |
| CORE-04 | 02-05, 02-07 | ✓ SATISFIED | Quick regression passed. |
| CORE-05 | 02-05, 02-07 | ✓ SATISFIED | Quick regression passed. |
| CORE-06 | 02-01, 02-07 | ✓ SATISFIED | Quick regression passed. |
| CORE-07 | 02-03, 02-07 | ✓ SATISFIED | Quick regression passed. |
| CORE-08 | 02-06, 02-07 | ✓ SATISFIED | Quick regression passed. |

No Phase 2 requirements are orphaned.

### Prohibition Verification

| Prohibition | Regression evidence | Verdict |
|---|---|---|
| No prose parsing or ambient/backend error semantics | Exact error interface/tests and Required scans passed. | ✓ VERIFIED |
| No catchable built-in physical OOM claim | README/source checks and false-OOM negative fixture passed. | ✓ VERIFIED |
| No ambient host fallback/native adapter/all-capabilities singleton | Exact interface/source checks and ambient-access negative fixture passed. | ✓ VERIFIED |

### Anti-Patterns Found

No blocker or warning anti-pattern remains in Plan 02-08 files. No `TBD`, `FIXME`, `XXX`, implementation placeholder, unchecked narrowing, raw mutable backing, ambient access, or false catchable-OOM claim was found. The changed files are limited to the intended private implementation, lifecycle tests, and README example.

### Disconfirmation Pass

- **Potential partial requirement checked:** explicit release of all children can restore owner availability before deferred cleanup; all handles are inactive at that point, group restoration is idempotent, and mixed-release plus subsequent reacquisition tests confirm no overlapping authority or double restoration.
- **Potential misleading test checked:** the README no longer stops after a compiling split; it performs and validates a second mutable acquisition.
- **Potential uncovered error path checked:** structured `Err` preserves the original error while deferred group cleanup invalidates descendants and permits reacquisition.

### Human Verification Required

None. All lifecycle invariants and portable package contracts have deterministic automated evidence; no visual, external-service, or performance judgment is involved.

### Gaps Summary

All previous gaps are closed. No regressions or new gaps were found, and later phases may consume the Phase 2 core contracts.

---

_Verified: 2026-07-16T16:45:50Z_
_Verifier: the agent (gsd-verifier)_
