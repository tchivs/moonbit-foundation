---
phase: 30-public-png-chunk-encoder
verified: 2026-07-21T14:19:44Z
status: passed
score: 8/8 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 30: Public PNG Chunk Encoder Verification Report

**Phase Goal:** Library users can emit exactly one canonical PNG through arbitrary caller-owned mutable output buffers with exact progress and sticky terminals.
**Verified:** 2026-07-21T14:19:44Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The public `PngChunkEncoder` pull contract is available to library users. | ✓ VERIFIED | `png.mbt:83-119` declares the public encoder, `NeedOutput`/`Finished`/`Failed(CoreError)` outcome, result, and three accessors. Regenerated `pkg.generated.mbti` exposes the same constructor and pull signatures. |
| 2 | Construction uses the Phase 29 machine admission path only, preserving typed preflight rejection before a destination exists. | ✓ VERIFIED | `stream_encode.mbt:9-19` makes one direct `PngEncodeMachine::new` call and immediately returns its `CoreError`; `PngEncodeMachine::new` calls `_png_encode_preflight` at lines 132-141. There is no alternative preflight or public byte source in the Phase 30 diff. |
| 3 | Empty, one-byte, and irregular caller-owned leases report exact per-call and cumulative progress through completion. | ✓ VERIFIED | Focused native test `PNG chunk encoder reports empty, one-byte, and irregular exact progress` asserts `0/0/NeedOutput`, then `1/1`, then `3/4`. The drain helper checks every `total_written()` equals the actually collected prefix. Fresh focused run: 5/5 passed. |
| 4 | Every accepted byte comes from the canonical machine exactly once; concatenation is eager-equivalent without duplication or omission. | ✓ VERIFIED | `pull` executes `present → destination.set → acknowledge` (`stream_encode.mbt:41-83`) and derives cumulative progress from `machine.completed()` only after acknowledgement. The focused RGB8 and straight-RGBA8 test drains `[1,3,2,5]` schedules and compares each aggregate byte-for-byte with existing eager `PngEncoder`; it passed. |
| 5 | The adapter does not retain a caller lease, view, owner, or staged PNG output. | ✓ VERIFIED | `PngChunkEncoder` has only `state` and scalar `total_written`; its private state has only `Active(PngEncodeMachine)`, `Finished`, or `Failed(CoreError)`. `pull` receives `MutByteLease` only as a parameter and no adapter state contains a lease/view/owner/`Bytes` buffer. The ownership test mutates the completed first owner, drains through new owners, and still equals eager bytes; it passed. |
| 6 | Successful terminals are sticky, zero-progress, and do not touch later destinations. | ✓ VERIFIED | Finished branch returns before observing `destination` (`stream_encode.mbt:27-32`); final acknowledgement changes state to `Finished` (`82-90`). The ownership/terminal test drains completion, supplies a sentinel-filled fresh owner, gets `0`, final total, `Finished`, and unchanged sentinel. Code makes each repeated terminal call identical. |
| 7 | Typed failure is retained and replayed with zero progress and no later destination mutation. | ✓ VERIFIED | On a failed `set`, the original error is persisted in `Failed(error)` (`60-67`); the terminal failure branch returns `0`, preserved total, and that error (`33-37`) without reading/writing destination. The released-lease regression compares category, code, operation, context, requested, completed, and limit across first/replay results, and confirms replay sentinel remains unchanged; it passed. |
| 8 | The approved public API is exactly generated/locked by policy and policy negatives fail closed. | ✓ VERIFIED | `Assert-PngFoundationPolicy` regenerates `pkg.generated.mbti` for all targets and exact-compares semantic lines to `policy/foundation.json`; it requires the three new public declarations and rejects obsolete `PngStreamEncoder`. `Assert-PngQualificationNegativeFixtures` rejects a missing pull result and extra public stream types. Fresh policy run passed. |

**Score:** 8/8 truths verified (0 present but behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public encoder/pull types and accessors | ✓ VERIFIED | Public declarations are substantive and surface in generated MBTI. |
| `modules/mb-image/png/stream_encode.mbt` | Thin sticky adapter over private canonical machine | ✓ VERIFIED | Direct construction, transient write, acknowledgement ordering, scalar accounting, and terminal state are implemented. |
| `modules/mb-image/png/stream_encode_test.mbt` | Native contract evidence | ✓ VERIFIED | Contains public progress, RGB/RGBA parity, ownership, terminal, and typed-error regressions. |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | Private accounting/order regression | ✓ VERIFIED | White-box test confirms one accepted byte advances machine/wrapper counts together. |
| `policy/foundation.json` | Exact semantic interface | ✓ VERIFIED | Exact generated semantic sequence includes the approved encoder family. |
| `scripts/quality/Assert-Policy.ps1` | Fail-closed policy and negatives | ✓ VERIFIED | Requires approved declarations, rejects obsolete additions, and exact-compares generated MBTI. |

`gsd-tools query verify.artifacts` independently reported 6/6 substantive artifacts passed.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `stream_encode.mbt` | Public constructor/pull → `PngEncodeMachine` | ✓ WIRED | Constructor calls the machine once; pull uses only machine `present`/`acknowledge`. |
| `stream_encode.mbt` | `mb-core/bytes/views.mbt` | Current `MutByteLease` | ✓ WIRED | `destination.set(written, byte)` is the only output mutation; no mutable-output capability is state. |
| `stream_encode.mbt` | `stream_encode_test.mbt` | Executable public contract | ✓ WIRED | Tests use the public constructor/pull API and collect accepted callback-scoped output. |
| `foundation.json` | `pkg.generated.mbti` | Policy regeneration/comparison | ✓ WIRED | Fresh `moon info --target all --frozen` plus policy assertion succeeded. |

`gsd-tools query verify.key-links` independently reported 4/4 verified links.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PngChunkEncoder::pull` | `byte`, `written`, `total_written` | `PngEncodeMachine::present()` and `completed()` | The canonical private machine computes bytes from admitted `ImageView`; the public wrapper writes each current byte then acknowledges it. | ✓ FLOWING |

There is no UI/data-fetch layer or static-output fallback. The only data source is the Phase 29 canonical machine, and focused byte-parity tests exercise the complete flow against eager output.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Empty/tiny/irregular progress, RGB/RGBA parity, ownership, and sticky terminals | `moon -C modules/mb-image test png --target native --frozen -f '*PNG chunk encoder*'` | 5 passed, 0 failed | ✓ PASS |
| Full native PNG regression | `moon -C modules/mb-image test png --target native --frozen` | 97 passed, 0 failed | ✓ PASS |
| Generated public surface across declared targets | `moon -C modules/mb-image info --target all --frozen` | exit 0 | ✓ PASS |
| Exact policy and negative fixtures | `pwsh -NoProfile -Command ". ./scripts/quality/Assert-Policy.ps1; Assert-PngFoundationPolicy -PolicyPath policy/foundation.json; Assert-PngQualificationNegativeFixtures -PolicyPath policy/foundation.json"` | Interface/policy verification and scoped negatives passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGE-02 | `30-01-PLAN.md` | Arbitrary caller-owned mutable buffers make deterministic, exact, once-only canonical progress without retained output buffers. | ✓ SATISFIED | Public transient-lease implementation plus focused empty/one/irregular, parity, and ownership regressions passed. |
| PNGE-03 | `30-01-PLAN.md` | Canonical eager semantics and sticky completion/failure, with no later output. | ✓ SATISFIED | Direct lifecycle branches and passed success/error replay/sentinel tests prove the required terminal behavior. |

No requirements mapped to Phase 30 are orphaned: both PNGE-02 and PNGE-03 are declared by the sole plan.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No Phase-30 debt markers, placeholder implementations, hardcoded empty output, or console-only handlers found. | — | — |

The phrase “not available here” in `png.mbt:24` describes the pre-existing decoder API’s terminal-result availability; it does not flow to caller output and is not a stub. The policy script’s placeholder-token matcher is an intentional validation rule, not a debt marker.

### Phase 31 Boundary

Phase 30 does not claim Phase 31’s four-target hostile-schedule qualification or public decode → operation → chunk-encode workflow. The implementation’s all-target interface generation is only API-surface validation; behavioral proof is deliberately the focused native Phase 30 suite. No Phase 31 success criterion was counted in this report.

### Disconfirmation Pass

- **Partial-requirement check:** looked for a separate public preflight path or a parallel byte emitter; neither exists. Construction is a single direct `PngEncodeMachine::new` call.
- **Misleading-test check:** parity is not merely prefix checking: the drain helper copies exactly each reported output prefix after callback close, checks cumulative count on every pull, and compares the complete RGB8/RGBA8 aggregate to eager bytes.
- **Error-path check:** the released-lease error reaches `destination.set`, is persisted as the original typed `CoreError`, and is replayed to a fresh sentinel owner without mutation. The test passed.

### Gaps Summary

No gaps found. The public wrapper is substantively implemented and connected to the sole canonical byte source, its runtime behaviors are exercised by focused native tests, and its exact public surface is enforced by generated-interface policy and negatives.

---

_Verified: 2026-07-21T14:19:44Z_
_Verifier: the agent (gsd-verifier)_
