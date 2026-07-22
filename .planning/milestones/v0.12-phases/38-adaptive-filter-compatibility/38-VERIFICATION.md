---
phase: 38-adaptive-filter-compatibility
verified: 2026-07-22T00:41:21Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 38: Adaptive Filter Compatibility Verification Report

**Phase Goal:** Library users can explicitly select adaptive PNG row filtering without changing the bytes produced by existing filter-None constructors or compression routes.
**Verified:** 2026-07-22T00:41:21Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can choose `PngFilterStrategy::Adaptive` through documented eager and caller-buffered factories. | ✓ VERIFIED | `PngFilterStrategy::{None, Adaptive}` is public and equality-comparable in `png.mbt:88`; documented eager and chunk factories are public at `png.mbt:128` and `stream_encode.mbt:45`. Their generated semantic-interface declarations are present in `policy/foundation.json:1360,1393-1398`. The two public factory tests passed on JS, Wasm, Wasm-GC, and native. |
| 2 | `PngEncoder::new()`, `PngChunkEncoder::new(...)`, and every existing compression-strategy factory retain their exact pre-Phase-38 filter-None PNG bytes. | ✓ VERIFIED | Legacy eager constructors explicitly set `None` at `png.mbt:103-120`; legacy chunk constructors pass `None` to the shared constructor at `stream_encode.mbt:9-37`. Immutable complete-PNG Stored/Fixed-or-Stored vectors are compared by public eager tests (`encode_test.mbt:122-172`) and hostile chunk drains (`stream_encode_test.mbt:289-334`); the strict Dynamic winner has its own immutable eager/chunk vector at `stream_encode_test.mbt:415-433`. All four complete PNG suites passed 133/133. |
| 3 | Adaptive is a filter-None compatibility shim: it changes no scanline byte, compression selection, preflight admission, checksum, progress, or terminal behavior. | ✓ VERIFIED | Both filter factories force `Stored` then enter the same `PngEncodeMachine::new_with_strategies` path (`png.mbt:128-134`, `stream_encode.mbt:45-68`). The only filter-case dispatch normalizes `Adaptive` to `None` before the unchanged `_png_encode_preflight` (`stream_encode.mbt:248-267`; preflight begins at `encode.mbt:493`). Exact adaptive PNG vectors—including checksums—match Stored vectors, and the chunk test drains hostile `[0,1,3,2,5]` capacities through the established acknowledgement/terminal helper. |
| 4 | Frozen Stored, FixedOrStored, and strict Dynamic winners are exercised through eager and hostile caller-buffered output on JS, Wasm, Wasm-GC, and native. | ✓ VERIFIED | The new eager and chunk vector tests cover Stored, FixedOrStored, and Dynamic fallback; the existing public strict-winner test freezes its Dynamic PNG bytes, checks BTYPE `10`, complete-input decode, and hostile chunk parity. Focused public tests passed 2/2 on each declared target; the complete `png` suite passed 133/133 separately on every target. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public strategy and eager factory | ✓ VERIFIED | Exists, substantive, documented, and wired into `ImageEncoder::encode` through stored `filter_strategy`. |
| `modules/mb-image/png/encode.mbt` | Shared eager construction | ✓ VERIFIED | The only Phase-38 behavioral change is forwarding both strategies to the existing machine; preflight and compression planning diff cleanly unchanged. |
| `modules/mb-image/png/stream_encode.mbt` | Caller-buffered factory using the shared atomic machine | ✓ VERIFIED | Legacy and new routes use `new_with_strategies`; `pull`/acknowledgement logic is unchanged. |
| `modules/mb-image/png/encode_test.mbt` | Immutable eager compatibility vectors | ✓ VERIFIED | Independent complete literals and public decode comparisons cover RGB8/RGBA8 Stored plus Fixed/Dynamic compatibility routes. |
| `modules/mb-image/png/stream_encode_test.mbt` | Immutable hostile-drain compatibility vectors | ✓ VERIFIED | New chunk test uses the established hostile schedule; strict Dynamic test holds the complete strict-winner literal and eager/chunk parity. |
| `policy/foundation.json` | Public semantic-interface registration | ✓ VERIFIED | Exact additions register the enum and both configured filter factories; the PNG policy stage passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `encode.mbt` | `PngEncoder` carries both strategies into the one private machine constructor | ✓ WIRED | `ImageEncoder::encode` calls `PngEncodeMachine::new_with_strategies` with `_self.strategy` and `_self.filter_strategy` at `encode.mbt:632-634`. |
| `stream_encode.mbt` | `stream_encode_test.mbt` | Public chunk factory and hostile acceptance path | ✓ WIRED | Factory calls the shared machine at `stream_encode.mbt:66-68`; the public test drives it with zero/tiny/ragged capacity at `stream_encode_test.mbt:293-334`. |
| `encode.mbt` | `encode_test.mbt` | Unchanged preflight/compression routes protected by independent vectors | ✓ WIRED | Tests invoke only public `PngEncoder` factories and compare complete literals, rather than deriving a second runtime oracle. |
| `png.mbt` | `policy/foundation.json` | Generated public semantic interface | ✓ WIRED | Declarations in policy match the actual public enum and signatures. |

### Data-Flow Trace (Level 4)

Not applicable: this phase adds library construction and encoder-state wiring, not a dynamic UI/data artifact. The relevant value flow is nevertheless complete: caller enum → factory → `new_with_strategies` → `Adaptive => None` normalization → existing scanline/preflight/emitter path.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| New public eager/chunk compatibility tests on native | `moon -C modules/mb-image test png --target native --target-dir _build/phase38-verification-native --frozen -f '*filter strategy*'` | 2 passed, 0 failed | ✓ PASS |
| New public eager/chunk compatibility tests on JS, Wasm, and Wasm-GC | Same command per target in isolated target directories | 2 passed, 0 failed on each target | ✓ PASS |
| Full PNG package on native | `moon -C modules/mb-image test png --target native --target-dir _build/phase38-verification-native --frozen` | 133 passed, 0 failed | ✓ PASS |
| Full PNG package on JS | Same command with `--target js` | 133 passed, 0 failed | ✓ PASS |
| Full PNG package on Wasm | Same command with `--target wasm` | 133 passed, 0 failed | ✓ PASS |
| Full PNG package on Wasm-GC | Same command with `--target wasm-gc` | 133 passed, 0 failed | ✓ PASS |
| PNG quality lane | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Recorded runner exit code 0; log ends `PNG quality lane passed` and `PNG lane isolation proof passed`, including the final 133/133 PNG suites on Wasm, Wasm-GC, JS, and native. | ✓ PASS |

### Probe Execution

No phase-declared or conventional `probe-*.sh` scripts exist for this PNG library phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| PNGF-01 | `38-01-PLAN.md` | Eager and caller-buffered adaptive opt-in while legacy constructors retain filter-None bytes. | ✓ SATISFIED | Both documented public factories compile and execute on all supported targets; legacy and configured routes are explicitly normalized to `None` and protected by immutable full-PNG vectors. |

No orphaned Phase 38 requirements found: `PNGF-01` is the sole roadmap requirement and is claimed by the plan.

### Anti-Patterns Found

No blocker or warning anti-patterns found in Phase-38-modified source/tests/policy files. The only text match, `not available here` in `png.mbt:24`, is an existing terminal-state documentation sentence, not an implementation placeholder. `git diff --check 551af71..68fb0ac` is clean. The current dirty files are confined to uncommitted QOI work and were not inspected as Phase-38 implementation.

### Disconfirmation Pass

- **Partial-requirement check:** `PngFilterStrategy` is not merely declared: both public factories propagate it to the same machine, and `Adaptive` has an explicit two-case normalization before preflight.
- **Misleading-test check:** compatibility assertions use immutable complete PNG byte literals and public decoder checks; they do not compare one live encoder route to another.
- **Error-path check:** no Adaptive-specific unsupported-image test was added, but its factory reaches the identical `_png_encode_preflight` call used by legacy routes. The full existing package suites pass on all targets; this is not an unconnected bypass.

### Gaps Summary

None. The goal is achieved: the additive opt-in seam is public, uses the existing filter-None/Stored representation, and preserves legacy compression behavior and byte vectors across the declared portable targets. The complete PNG quality lane passed with a recorded exit code of zero and its lane-isolation proof.

---

_Verified: 2026-07-22T00:41:21Z_
_Verifier: the agent (gsd-verifier)_
