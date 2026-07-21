---
phase: 31-portable-png-encode-evidence
verified: 2026-07-21T14:52:46Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 31: Portable PNG Encode Evidence Verification Report

**Phase Goal:** Maintainers and library users can verify the public resumable PNG encode contract across all portable targets in hostile and end-to-end workflows.
**Verified:** 2026-07-21T14:52:46Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainers can run target-directory-isolated js, wasm, wasm-gc, and native evidence that proves public `PngChunkEncoder` output under empty, one-byte, and ragged caller capacities has exact progress, canonical eager-byte parity, atomic preflight parity, and non-mutating sticky terminals. | ✓ VERIFIED | `Invoke-PngEncodeEvidence.ps1` accepts only the four required targets, gives each `_build/png-encode-evidence/<target>` directory, and selects four named regressions. Independent runs on js, wasm, wasm-gc, and native each passed 4/4. The new selected test drains RGB8 and straight-RGBA8 through `[0,1]`, `[1]`, and `[0,8,4,1,13,2,5,3,21]`; it checks per-pull/cumulative progress and complete eager-byte equality. It additionally verifies repeated Finished sentinels and released-lease Failed replay are zero-progress and unmodified, then compares output-limit, work-budget, and opaque-metadata constructor errors and uncharged rejected budgets with the eager oracle. |
| 2 | The sole `png-portable` executable uses only public `PngChunkDecoder`, `resize_bilinear`, and `PngChunkEncoder` contracts to emit the frozen 78-byte PNG with digest `626208771` through its caller-owned output schedule. | ✓ VERIFIED | `main.mbt` performs the fixed 16 decoder pushes, calls `finish()` once, performs the 3×1 bilinear resize, and drains public `PngChunkEncoder` through one reusable 21-byte `OwnedBytes` owner with the required ragged schedule. It checks exact accepted prefixes/progress, 14 pulls, 78 exact bytes, and the digest. Independent direct runs on all four targets each emitted exactly the one required evidence line. |
| 3 | The scoped PNG lane exact-matches the one public chunk-decode-resize-chunk-encode evidence line on every required target without reaching Required, QOI, release, registry, or credential paths. | ✓ VERIFIED | `Invoke-PngQualityLane` exact-compares one evidence line per js/wasm/wasm-gc/native run; `Assert-PngLaneIsolation` replaces broad-foundation, QOI, Required, and release entries with throws and exact-checks the ordered PNG-only stage trace. The completed independent `-Lane Png` run reported `PNG quality lane passed` and `PNG lane isolation proof passed`; its Phase 31 commit changed only the expected public-workflow stage/line, not policy, release, registry, credential, configuration, or target-controller files. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_encode_test.mbt` | Named public hostile-capacity, preflight-parity, progress, canonical-byte, and sticky-terminal evidence selected by the isolated target runner. | ✓ VERIFIED | 430 substantive lines. The selected test is executable public-API evidence, not a presence-only fixture: it constructs `PngChunkEncoder`, passes callback-scoped `MutByteLease` values to `pull`, copies only accepted prefixes after the callback, and compares full aggregates/errors with an eager public oracle. |
| `examples/png-portable/main/main.mbt` | The repository's single public portable PNG chunk-decode, bilinear-resize, and chunk-encode workflow with frozen output evidence. | ✓ VERIFIED | 133 substantive lines. The runtime path contains decoder → `finish()` → `resize_bilinear` → public chunk encoder; there is no eager `PngEncoder` or `MemoryWriter` output route in this executable. Four direct target executions prove the path and output. |
| `scripts/quality/Invoke-MoonQuality.ps1` | PNG-only exact four-target gate for the chunk-decode-resize-chunk-encode workflow. | ✓ VERIFIED | The PNG lane loops exactly over js/wasm/wasm-gc/native, requires exactly one status line equal to the frozen 14-pull/78-byte/digest evidence, and preserves its ordered isolation trace. The full scoped lane passed independently. |

`gsd-tools query verify.artifacts` also reported 3/3 declared artifacts substantive and present.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `stream_encode_test.mbt` | `png.mbt` / public chunk encoder | Black-box `PngChunkEncoder::new` and `pull` calls with callback-scoped leases, compared with separate eager `PngEncoder` output. | ✓ WIRED | The selected test has no private-machine assertion or alternate encoder. Its passing per-target execution exercises the public linkage. |
| `Invoke-PngEncodeEvidence.ps1` | `stream_encode_test.mbt` | Shared `*PNG encoder isolated four-target evidence*` selector and a target-specific build directory. | ✓ WIRED | The selector finds the three existing Phase 29 regressions plus the Phase 31 hostile/preflight test; each independently run target reported 4/4 passing. |
| `png-portable/main.mbt` | `Invoke-MoonQuality.ps1` | Exact evidence-line extraction and comparison in `Invoke-PngQualityLane`. | ✓ WIRED | The lane invokes the executable once per required target, rejects zero/multiple/mismatched evidence lines, and passed its isolation proof. |

`gsd-tools query verify.key-links` independently reported 3/3 declared links verified; source inspection and runtime checks above supplied the behavioral proof.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `stream_encode_test.mbt` hostile drain | collected `output` prefix | `PngChunkEncoder::pull` writes into each newly owned callback lease; only `[0, written)` is copied after callback close. | The aggregate is compared byte-for-byte to a separately encoded eager PNG for both RGB8 and straight-RGBA8. | ✓ FLOWING |
| `examples/png-portable/main/main.mbt` | `output` and `encoded` | Fixed public chunk decoder output is resized, then public encoder pulls write accepted bytes into the reusable owner. | The materialized aggregate must equal the frozen 78-byte PNG and digest before it is printed. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Four-target hostile schedules, eager parity, preflight parity, and sticky terminals | `pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target {js,wasm,wasm-gc,native}` | Each target: 4 passed, 0 failed. | ✓ PASS |
| Public decode → resize → chunk-encode portable workflow | `moon -C examples/png-portable run main --target {js,wasm,wasm-gc,native} --frozen` | Each target emitted exactly `example=png-portable ... output_schedule=zero-tiny-ragged output_pulls=14 bytes_written=78 ... digest=626208771`. | ✓ PASS |
| Generated decode corpus freshness and scoped quality/isolation gate | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Structural vectors: 89 P+W cases; decode vectors: 3,850 cases; four per-target PNG runs: 98/98 each; `PNG quality lane passed`; `PNG lane isolation proof passed`. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGE-04 | `31-01-PLAN.md` | Maintainers can verify hostile output capacities, eager/chunk byte parity, limits, budgets, and terminal behavior unchanged on js, wasm, wasm-gc, and native. | ✓ SATISFIED | The runner's four target-isolated executions passed the test that explicitly covers RGB/RGBA schedules, progress, full canonical bytes, preflight error/budget parity, Finished sentinel non-mutation, and Failed replay. |
| PNGE-05 | `31-01-PLAN.md` | A library user can run one public portable PNG chunk-decode → image operation → chunk-encode workflow that prints deterministic output evidence using only public MoonBit contracts. | ✓ SATISFIED | The sole executable source uses the public decoder, operation, and encoder; direct four-target executions and the exact scoped-lane gate produced the frozen line. |

No Phase 31 requirement is orphaned: the sole plan declares PNGE-04 and PNGE-05. There are no later milestone phases to which a failed item could be deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, empty-output, or console-only implementation marker in the three Phase 31 implementation artifacts. | — | No blocker or warning. |
| `examples/png-portable/main/moon.pkg` | 5 | `tchivs/mb-core/io` is now reported by MoonBit as unused after the eager writer route was removed. | ℹ️ Info | This manifest was not changed by Phase 31; the exact package-policy lane passed. It does not affect the required workflow or broaden policy/release/config scope. |

### Disconfirmation Checks

- A passing selector test could have covered only a prefix. The new drain checks every `written()` against capacity and cumulative output, then compares the completed byte sequence to the eager oracle for all three schedules and both image formats.
- A test could have exercised the old eager output path. The executable's runtime path contains `PngChunkEncoder::new` and `pull`, while the former `MemoryWriter`/eager `PngEncoder` output route is absent; all four target runs reached the new exact output assertion.
- The quality line could have been updated without runnable isolation. The independently executed lane passed the ordered trace after substituted QOI/Required/release/broad-foundation functions would throw; the Phase 31 commit scope contains only the three planned source/test/quality files and no policy, release, registry, credential, config, or public-interface change.

### Gaps Summary

No gaps found. All roadmap criteria, the three merged plan truths, declared artifacts, key links, runtime transitions, and PNGE-04/PNGE-05 have direct four-target behavioral evidence. The phase goal is achieved.

---

_Verified: 2026-07-21T14:52:46Z_
_Verifier: the agent (gsd-verifier)_
