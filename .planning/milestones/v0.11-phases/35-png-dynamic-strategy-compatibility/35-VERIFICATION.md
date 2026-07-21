---
phase: 35-png-dynamic-strategy-compatibility
verified: 2026-07-21T22:36:07Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 4/4
  reason: "Commit d0a3451 corrected only the private Dynamic replay comment in stream_encode.mbt."
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 35: Dynamic Strategy Compatibility Verification Report

**Phase Goal:** Library users can explicitly select a documented dynamic compression route without changing the frozen Stored defaults or established FixedOrStored byte sequences.
**Verified:** 2026-07-21T22:36:07Z
**Status:** passed
**Re-verification:** Yes — freshness refresh after `d0a3451` corrected a stale private replay comment; no code or public API changed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can pass `PngCompressionStrategy::DynamicOrFixedOrStored` to the documented eager and caller-buffered PNG factories. | ✓ VERIFIED | `png.mbt` publicly declares the additive equality-comparable enum case and eager factory; `stream_encode.mbt` exposes the caller-buffered factory and passes the selected strategy to shared construction. The two Phase 35 compatibility tests passed on js, wasm, wasm-gc, and native. |
| 2 | `PngEncoder::new()` and `PngChunkEncoder::new(...)` retain their independently frozen complete Stored RGB8 and straight-RGBA8 PNG bytes. | ✓ VERIFIED | Both legacy constructors still pass `Stored` directly. The named eager and hostile-capacity chunk tests compare complete RGB8/RGBA8 output to independent Stored literals and passed on all four declared targets. |
| 3 | Explicit FixedOrStored eager and caller-buffered factories retain their frozen complete byte sequences, and only DynamicOrFixedOrStored is eligible to select a Dynamic DEFLATE representation. | ✓ VERIFIED | The `FixedOrStored` preflight branch remains separate and never calls `_png_dynamic_plan`; its frozen-vector checks passed. `_png_dynamic_plan` has one call site, inside the `DynamicOrFixedOrStored` branch, which selects `PngDeflatePlan::Dynamic` only on a strict complete-PNG size win. |
| 4 | Public strategy documentation states the strict-win policy and excludes adaptive filters, broader matching, and host-streaming expansion. | ✓ VERIFIED | Public docs in `png.mbt` and `stream_encode.mbt` specify the strict-complete-PNG win over unchanged FixedOrStored output, tie retention, and exclusions including adaptive filtering, matching beyond distance four, 32 KiB history, staging, FFI, host streaming, APNG, colour, and metadata. `moon -C modules/mb-image info --target all --frozen` exited 0. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public additive strategy and eager contract | ✓ VERIFIED | Substantive public enum and factory documentation; `new()` remains direct Stored and the configured eager factory stores the selected strategy. |
| `modules/mb-image/png/encode.mbt` | Exhaustive compatibility-preserving strategy admission | ✓ VERIFIED | Stored and FixedOrStored retain their separate admissions; only the new opt-in branch invokes the dynamic planner after establishing the unchanged FixedOrStored winner. |
| `modules/mb-image/png/stream_encode.mbt` | Caller-buffered strategy construction | ✓ VERIFIED | Configured factory passes strategy to the shared machine and legacy construction is direct Stored. The corrected private comment accurately describes owned `PngDynamicState` replay: `present` previews pending state and `acknowledge` alone commits it. |
| `modules/mb-image/png/encode_test.mbt` | Eager frozen-vector coverage | ✓ VERIFIED | The named Phase 35 eager test contains independent complete Stored and FixedOrStored RGB8/RGBA8 literals and checks the compatible dynamic-route fallback. |
| `modules/mb-image/png/stream_encode_test.mbt` | Caller-buffered frozen-vector coverage | ✓ VERIFIED | The named chunk test drains only accepted bytes under `[0, 1, 3, 2, 5]` and checks the same independent compatibility vectors. |
| `policy/foundation.json` | Exact semantic-interface registration | ✓ VERIFIED | The PNG semantic interface registers `DynamicOrFixedOrStored` together with the existing configured factory signatures; no policy or public-source declaration changed after the Phase 35 feature commit. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `encode.mbt` | Eager factory retains the strategy through `ImageEncoder::encode` to shared preflight. | ✓ WIRED | `ImageEncoder::encode` calls `PngEncodeMachine::new_with_compression_strategy(source, _self.strategy, ...)`, and that construction calls `_png_encode_preflight`. |
| `stream_encode.mbt` | `stream_encode_test.mbt` | Configured caller-buffered factory to shared machine and hostile-capacity drain. | ✓ WIRED | `PngChunkEncoder::new_with_compression_strategy` calls the shared constructor; the named test invokes it and drains accepted lease prefixes. |
| `png.mbt` | `policy/foundation.json` | Public enum/interface contract. | ✓ WIRED | Source and policy both expose `Stored`, `FixedOrStored`, and `DynamicOrFixedOrStored`; the all-target public interface command passed. |

### Data-Flow Trace (Level 4)

Not applicable: these are encoder control-path artifacts rather than dynamic-data rendering. The strategy is traced from both public factories through the shared machine to `_png_encode_preflight`; only the opt-in variant reaches `_png_dynamic_plan`.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Eager and caller-buffered frozen compatibility vectors. | `moon -C modules/mb-image test png --target all --frozen -f '*dynamic strategy*'` | 2/2 passed on wasm, wasm-gc, js, and native. | ✓ PASS |
| Public PNG interface compiles on every declared target. | `moon -C modules/mb-image info --target all --frozen` | Exit 0. | ✓ PASS |
| Comment-only change is behavior/API-neutral. | `git diff --check d0a3451^ d0a3451` and `git diff --name-only d0a3451^ d0a3451` | No whitespace errors; the sole changed file is `stream_encode.mbt`, and the patch changes only `///` comment text. | ✓ PASS |

### Probe Execution

**SKIPPED:** no phase-declared or conventional `probe-*.sh` script exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| PNGD-01 | `35-01-PLAN.md` | Explicit DynamicOrFixedOrStored opt-in while legacy Stored and FixedOrStored bytes remain frozen; only new route may select Dynamic. | ✓ SATISFIED | Public factories and documentation are wired, independent eager/chunk frozen-vector tests pass on all four targets, and the sole dynamic planner call is in the new strategy branch. No Phase 35 requirement is orphaned. |

### Anti-Patterns Found

No phase-introduced `TBD`, `FIXME`, `XXX`, placeholder, empty handler, static empty-output, or console-only implementation was found. The phrase “not available here” in `png.mbt` documents the intentional decoder terminal-result boundary; it is not a placeholder.

### Re-verification Scope

`d0a3451` changes four removed and four added comment lines in the private `PngEncodeMachine` docblock only. The corrected description is consistent with current code: the machine owns `PngDynamicState`, `dynamic_preview_byte` returns a private successor, `dynamic_zlib_byte` stores it as pending, and `acknowledge` commits it only after the byte is accepted. No public declaration, factory signature, test, policy interface, or executable statement changed in that commit.

### Gaps Summary

No blocking gaps found. PNGD-01 remains satisfied: the public dynamic route is explicit and documented, legacy Stored and FixedOrStored compatibility baselines remain covered by immutable eager and caller-buffered vectors, and Dynamic selection is confined to the new opt-in strategy.

---

_Verified: 2026-07-21T22:36:07Z_
_Verifier: the agent (gsd-verifier)_
