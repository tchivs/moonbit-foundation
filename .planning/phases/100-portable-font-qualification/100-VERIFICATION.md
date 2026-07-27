---
phase: 100-portable-font-qualification
verified: 2026-07-27T16:01:56Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 4/4
  gaps_closed:
    - "Every published supported DejaVu outline fingerprint is now bound to a complete independently generated command vector and an exhaustive target-side assertion executed before evidence publication."
  gaps_remaining: []
  regressions: []
---

# Phase 100: Portable Font Qualification Verification Report

**Phase Goal:** Maintainers can reproduce the complete public font workflow and hostile-input behavior with immutable fixtures on every supported target.
**Verified:** 2026-07-27T16:01:56Z
**Status:** passed
**Re-verification:** Yes — after closing the fingerprint evidence gap in Plan 100-06

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A maintainer can run one immutable public workflow that opens a font, maps BMP and supplementary scalars, reads metrics, extracts simple and composite outlines, and queries kerning with identical facts on all four targets. | ✓ VERIFIED | Fresh `FontQualification` execution passed the exact exhaustive DejaVu test 1/1 and the complete package 102/102 on each of `js`, `wasm`, `wasm-gc`, and `native`. Compact workflow coverage remains intact. |
| 2 | Generated adversarial fixtures produce identical structured malformed-input, unsupported-feature, mutation, arithmetic, and resource-limit outcomes on all targets. | ✓ VERIFIED | The complete four-target package suite still passes, including the closed 11-case public hostile matrix and transactional exact/one-short assertions. |
| 3 | A licensed real-font specimen has immutable bytes, provenance/license, digest, inventory, and reproducible public interoperability facts. | ✓ VERIFIED | Exact DejaVu Sans 2.37 TTF/notice identities and license remain unchanged. Oracle schema/reader 1.1.0 contains complete ordered command vectors; all supported fingerprints were independently recomputed and matched. |
| 4 | Isolated font and workspace controls preserve `mb-font -> mb-core` only and exclude forbidden ambient/deferred capabilities. | ✓ VERIFIED | Exact 56-line public interface still matches the Phase 100 baseline and policy. Module dependency remains solely `tchivs/mb-core`; package imports and four targets are unchanged. Plan 100-06 changes only tests, generated test data, offline tooling, policy, and evidence gating. |

**Score:** 4/4 truths verified (0 present-but-behavior-unverified)

### FONT-05

**Status: ✓ SATISFIED.**

Fresh command:

`./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/font-reverification`

Result:

- exact DejaVu exhaustive assertion: 1/1 on each target;
- complete font package: 102/102 on each target;
- semantic comparison: `equal=true`;
- normalization removes only `target` and `runner`;
- semantic SHA-256: `65b63177ed296ffa4cb1f46a4c6943d6036a71d70eb1b8409830a35e65fcdef8`.

## Re-verification of Previous Gap

### Independent complete oracle vectors

The offline PowerShell oracle now emits `path.commands` under schema/reader version 1.1.0. I independently recomputed SHA-256 over each UTF-8 pipe-joined complete vector:

| Scalar | Commands | Recomputed / Stored Fingerprint | Status |
|---|---:|---|---|
| U+0041 | 13 | `ccb4bab2977fff264d8a8421ccb01e333b837e02bc7b5eb6c67e435ffcd2d308` | ✓ MATCH |
| U+034C | 48 | `f5dfde0b4b9620c9de27a766cdd3fee9efa89f7fd1044c9d9f68ce2e94aed827` | ✓ MATCH |
| U+10300 | 13 | `c082fb5502ff6694c084a4ebce10d0208171a9c8079051cb544868b44e92267a` | ✓ MATCH |

The partition is exactly 13 + 48 + 13 = 74 commands. Every command matches the closed `M`, `L`, `Q`, or `Z` grammar.

### Oracle-to-generated-test link

`Generate-FontQualification.ps1`:

1. independently parses the immutable TTF into complete ordered commands;
2. computes each fingerprint from that same complete vector;
3. requires count, vector length, and fingerprint equality;
4. converts every command to structured test-private fields;
5. emits `font_qualification_dejavu_supported_outlines()` in deterministic generated MoonBit;
6. rejects drift through `-Check`.

Fresh generator `-Check` and `Assert-FontFoundationPolicy` both passed.

### Exhaustive public Path2 assertions

`font_qualification_test.mbt` consumes all three generated outline expectations. For every command index it checks:

- exact path length, preventing missing or extra commands;
- exact `MoveTo` and `LineTo` coordinates;
- exact `QuadTo` control and endpoint coordinates;
- exact `Close` variant;
- rejection of unexpected cubic or missing commands.

The test iterates every generated expectation and every command. This is complete target-side verification of all 74 commands, not selected-coordinate sampling.

### Target-test-to-evidence gate

`Invoke-FontQualification.ps1` executes, in this order for each target:

1. target-specific `moon check`;
2. the exact filtered DejaVu test;
3. require exit 0 and exactly `Total tests: 1, passed: 1, failed: 0.`;
4. the complete 102-test package suite;
5. only then construct and validate the target evidence record.

Each fresh record has:

- `runner.outline_assertion_passed=true`;
- exact test name `font-complete-public freezes DejaVu Sans 2.37 public facts`;
- a target-bound assertion command;
- exactly three supported path fingerprints matching the independent oracle.

The previous partial key link is now **✓ WIRED**.

## Required Artifacts

| Artifact | Status | Re-verification evidence |
|---|---|---|
| `fixtures/font/dejavu-sans-2.37/oracle.json` | ✓ VERIFIED | Schema 1.1.0; complete vectors; exact counts and independently recomputed fingerprints. |
| `scripts/fixtures/Generate-FontQualification.ps1` | ✓ VERIFIED | Complete vector derivation, closed grammar conversion, fingerprint/count validation, deterministic generation, passing `-Check`. |
| `modules/mb-font/font/generated_font_qualification_test.mbt` | ✓ VERIFIED | Test-private structured expectations for all 74 commands and three stored fingerprints. |
| `modules/mb-font/font/font_qualification_test.mbt` | ✓ VERIFIED | Exhaustive ordered PathCommand assertions through the public Font/Path2 API. |
| `scripts/quality/Invoke-FontQualification.ps1` | ✓ VERIFIED | Per-target focused test gate precedes full suite and evidence construction. |
| `scripts/quality/Assert-Policy.ps1` | ✓ VERIFIED | Freezes oracle schema, command counts/vectors, generated symbols, interface, dependencies, and source boundaries. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Immutable DejaVu TTF | Independent oracle | Closed offline SFNT parser | ✓ WIRED | Complete vectors and hashes are recomputed from immutable bytes without mb-font output. |
| Independent oracle | Generated MoonBit expectations | Deterministic structured generator | ✓ WIRED | Count/vector/hash invariants and generated drift checks pass. |
| Generated expectations | Public Path2 results | Exhaustive black-box test | ✓ WIRED | All 74 ordered commands are structurally checked on every target. |
| Focused target test | Target evidence record | Exit/pass-summary gate before record construction | ✓ WIRED | Each target records exact assertion provenance and publishes matching fingerprints only after the test and full suite pass. |
| Target records | Canonical comparison | Remove only target/runner | ✓ WIRED | Four records compare equal; semantic fields remain byte-visible. |

## Data-Flow Trace (Level 4)

| Data | Source | Consumer | Status |
|---|---|---|---|
| Complete DejaVu commands | Independent parsed TTF geometry | Oracle `path.commands` | ✓ FLOWING |
| Structured expectations | Oracle complete commands | Generated MoonBit black-box test | ✓ FLOWING |
| Actual runtime geometry | Public `Font::outline` Path2 | Exhaustive target assertions | ✓ FLOWING |
| Supported fingerprints | Independently validated oracle vectors | Evidence records gated by matching complete assertions | ✓ FLOWING |

## Public Surface, Dependency, and Scope Regression

| Check | Result | Status |
|---|---|---|
| Public semantic interface | 56 generated lines = 56 baseline lines = 56 policy lines | ✓ PASS |
| Runtime module dependency | Exactly `tchivs/mb-core: 0.1.0` | ✓ PASS |
| Package imports | Existing five mb-core packages only | ✓ PASS |
| Supported targets | `+js+wasm+wasm-gc+native` | ✓ PASS |
| Production source changes in 100-06 | None | ✓ PASS |
| Public/runtime SHA addition | None; SHA-256 remains offline PowerShell tooling | ✓ PASS |
| Forbidden/deferred capabilities | No FFI, filesystem/host discovery, GUI/canvas/image/color, shaping, hinting, CFF/CFF2, or rasterization expansion | ✓ PASS |

## Behavioral Spot-Checks

| Behavior | Result | Status |
|---|---|---|
| Independent vector/hash invariant | Exact 13/48/13 vectors; all three recomputed hashes match | ✓ PASS |
| Generator and policy drift gates | Both pass | ✓ PASS |
| Target exhaustive assertion | 1/1 on js, wasm, wasm-gc, native | ✓ PASS |
| Complete font regression suite | 102/102 on js, wasm, wasm-gc, native | ✓ PASS |
| Evidence provenance/fingerprints | All four records target-bound and oracle-equal | ✓ PASS |
| Semantic comparison | `equal=true`, target/runner-only normalization | ✓ PASS |
| Exact public interface | Unchanged 56-line sequence | ✓ PASS |

## Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| FONT-05 | ✓ SATISFIED | Licensed immutable complete workflow and hostile qualification pass on all four targets; complete supported DejaVu geometry is now target-asserted before fingerprint evidence publication. |

## Anti-Patterns Found

No unresolved debt marker, placeholder implementation, test skip, runtime/public hash dependency, production parser change, public API expansion, or evidence-before-test construction was found in Plan 100-06.

## Workspace-Wide Required Diagnostic

The existing bounded Windows Required record remains an honest separate failure (`timed_out=true`, process tree terminated, status `failure`) at the known unscoped `mb-image/png` workspace boundary. Plan 100-06 does not modify or relabel it. The fresh focused four-target font gate passes independently.

## Human Verification Required

None.

## Gaps Summary

The previous fingerprint evidence gap is closed. No gaps, regressions, behavior-unverified truths, or human decisions remain.

---

_Verified: 2026-07-27T16:01:56Z_
_Verifier: the agent (gsd-verifier)_
