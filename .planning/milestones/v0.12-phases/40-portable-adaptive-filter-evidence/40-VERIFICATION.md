---
phase: 40-portable-adaptive-filter-evidence
verified: 2026-07-22T14:11:04Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 40: Portable Adaptive-Filter Evidence Verification Report

**Phase Goal:** Library users have reproducible evidence that the opt-in adaptive route improves intended cases and preserves portable eager/caller-buffered interoperability.
**Verified:** 2026-07-22T14:11:04Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A bounded, documented candidate probe selects only RGB8 and straight-RGBA8 sources with a FixedOrStored Adaptive strict win over FixedOrStored None on every portable target before final cases are codified. | ✓ VERIFIED | `encode_test.mbt:237-273` defines all six unique R1–R3/A1–A3 public selectors. Each calls the same explicit `FixedOrStored` None/Adaptive encoder helper at `208-232`, which aborts unless Adaptive is strictly shorter. The runner retains the exact ordered six-selector matrix, processes all four targets without early candidate exit, then selects the first all-target R and A winner at `scripts/quality/Invoke-PngEncodeEvidence.ps1:10-88`. `40-RESEARCH.md:295-310` records the resulting all-pass matrix and R1/A1 selection. |
| 2 | The named generated RGB8 and straight-RGBA8 eager cases encode with FixedOrStored plus Adaptive to strictly fewer bytes than the same source with FixedOrStored plus None. | ✓ VERIFIED | Final sources are the documented R1 and A1 formulas (`encode_test.mbt:276-300`), and each reaches the explicit strict helper. The supplied 2026-07-22 FinalEvidence run exited 0: all four targets passed both eager selectors. |
| 3 | For both generated sources, a public PngChunkEncoder driven through zero, one-byte, and ragged capacities produces exactly eager Adaptive bytes and preserves hostile terminal behavior. | ✓ VERIFIED | The final chunk selectors use public `PngChunkEncoder::new_with_strategies(FixedOrStored, Adaptive)` and `[0,8,4,1,13,2,5,3,21]` at `stream_encode_test.mbt:1022-1038`. Their drain helper checks zero-capacity NeedOutput, exact cumulative progress, two unchanged terminal leases, sticky Finished, and byte equality with public eager output at `891-946`. The supplied FinalEvidence run exited 0 for both chunk selectors on every target. |
| 4 | Each named evidence case runs independently on js, wasm, wasm-gc, and native from a fresh temporary target root, and PngDecoder restores exact source descriptor/components. | ✓ VERIFIED | The runner's fixed target list, four final selectors, one-process-per-selector call, GUID-root containment checks, and `finally` cleanup are concrete at `Invoke-PngEncodeEvidence.ps1:10-117`. Both eager and chunk tests call public `PngDecoder` source/component oracles (`encode_test.mbt:93-123`, `stream_encode_test.mbt:149-180`); current decoder construction maps PNG channels to RGB8/RGBA8 and straight alpha (`raster_decode.mbt:44-52`, `13-19`). The supplied FinalEvidence run exited 0, reporting all four selectors passed on js, wasm, wasm-gc, and native. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode_test.mbt` | Candidate selection plus named eager strict-win/decode evidence | ✓ VERIFIED | Exists, substantive, and is a package `*_test.mbt` file. It generates source pixels; no hardcoded PNG result feeds the assertions. |
| `modules/mb-image/png/stream_encode_test.mbt` | Hostile chunk/eager parity plus decode evidence | ✓ VERIFIED | Exists, substantive, and its final tests flow from generated sources through the public chunk factory, hostile drain, eager bytes, and decoder oracle. |
| `scripts/quality/Invoke-PngEncodeEvidence.ps1` | Fail-closed candidate selection and selector-isolated four-target execution/cleanup | ✓ VERIFIED | Exists, has no stub return path, validates its two modes, records all candidate exits before selection, stops FinalEvidence on a final selector failure, and guards cleanup in `finally`. |
| `.planning/phases/40-portable-adaptive-filter-evidence/40-RESEARCH.md` | Recorded candidate matrix and resolved/blocked A1 outcome | ✓ VERIFIED | Records the exact CandidateSelection command, all 24 target/candidate results, and deterministic R1/A1 choices at `295-310`. |

The artifact verifier also reports all four plan artifacts present and substantive. Current Phase 40-owned artifacts have no uncommitted modifications; unrelated QOI edits were preserved.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `encode_test.mbt` | `png.mbt` | Public `PngEncoder::new_with_strategies(FixedOrStored, None/Adaptive)` and `PngDecoder` | ✓ WIRED | The eager helper calls the public factory exactly once per baseline/candidate and feeds returned bytes to the public decoder oracle. |
| `stream_encode_test.mbt` | `stream_encode.mbt` / `png.mbt` | Public chunk factory under hostile schedule | ✓ WIRED | The generic hostile drain obtains eager bytes through the public eager factory and creates `PngChunkEncoder` with the identical supplied strategy/filter. `PngChunkEncoder::new_with_strategies` and `pull` are public at `stream_encode.mbt:60-81`. |
| `Invoke-PngEncodeEvidence.ps1` | public test selectors | Individual `moon ... test png -f $Selector` processes | ✓ WIRED | Candidate and final selector arrays exactly match the ten uniquely named public tests; no similarly named selector was found. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Eager evidence | generated `OwnedImage` pixels | R1/A1 builders → explicit public encoder → `Bytes` → `PngDecoder` | Yes | ✓ FLOWING |
| Chunk evidence | generated `OwnedImage` pixels and hostile output | local R1/A1 builders → public eager/chunk factories → accumulated bytes → `PngDecoder` | Yes | ✓ FLOWING |
| Runner | candidate matrix and target root | real `moon` exit codes, a fresh GUID child of the OS temp root, and guarded `finally` removal | Yes | ✓ FLOWING (static trace) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| CandidateSelection matrix | `Invoke-PngEncodeEvidence.ps1 -Mode CandidateSelection` | Not re-run; persisted matrix is present in `40-RESEARCH.md`. | ✓ RECORDED EVIDENCE |
| Final eager/chunk/decode matrix | `Invoke-PngEncodeEvidence.ps1 -Mode FinalEvidence` | Supplied runtime evidence: exit 0 on 2026-07-22; js, wasm, wasm-gc, and native each passed all four final selectors. | ✓ PASS |

### Probe Execution

No phase-declared or conventional `probe-*.sh` files were found; this phase uses the focused PowerShell evidence runner instead.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGF-04 | 40-01 | Generated RGB8/RGBA8 strict win, hostile eager/chunk identity, and complete public decode on four targets | ✓ SATISFIED | Public tests/wiring and candidate matrix are present; supplied FinalEvidence execution exited 0 with every final selector passing on js, wasm, wasm-gc, and native. |

No Phase 40 requirement is orphaned from plan frontmatter. No later milestone phase explicitly covers an unfulfilled Phase 40 item, so nothing is deferred.

### Anti-Patterns Found

None. Phase-owned files contain no `TBD`, `FIXME`, or `XXX` debt marker; no placeholder output, hardcoded empty render/data path, or console-only implementation was found. The Phase 40 commit `6b5ca4e` changes only the two public test files, the evidence runner, research, and its summary. No subsequent change touches these artifacts, production PNG implementation, public API declarations, package metadata, or legacy filter-None vectors. No `mnf-png-adaptive-evidence-*` root is currently present under the OS temporary directory.

### Gaps Summary

None. Static inspection found no code, wiring, data-flow, safety, or scope-fence gap, and the supplied focused FinalEvidence execution closes every behavior-dependent truth.

---

_Verified: 2026-07-22T14:11:04Z_
_Verifier: the agent (gsd-verifier)_
