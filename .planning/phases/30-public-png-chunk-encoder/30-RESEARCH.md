# Phase 30: Public PNG Chunk Encoder - Research

**Researched:** 2026-07-21
**Domain:** Public portable, caller-buffered canonical PNG emission
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

No `CONTEXT.md` exists for Phase 30. The approved roadmap, requirements, project state, Phase 29 handoff, and repository policy are controlling scope. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/phases/29-pausable-png-encode-substrate/29-VERIFICATION.md`]

### Locked Decisions

- Publish the decode-independent public type named `PngChunkEncoder`; it emits one canonical eager-equivalent PNG to arbitrary caller-owned mutable output buffers. [VERIFIED: codebase: `.planning/PROJECT.md`, `.planning/ROADMAP.md`]
- Satisfy PNGE-02 and PNGE-03 only: exact pull progress, no retained caller output lease, eager byte/failure equivalence, and sticky success/failure terminals. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`]
- Preserve Phase 29's single `PngEncodeMachine` admission and byte source. Its direct eager Writer adapter, exact preflight ordering, byte acknowledgement, and provider-error preservation are already verified. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/stream_encode.mbt`, `.planning/phases/29-pausable-png-encode-substrate/29-VERIFICATION.md`]
- Keep the encoder pure MoonBit with the existing PNG package imports and all four declared portable targets; add no FFI, packages, host stream adapter, compression change, APNG, metadata/colour feature, registry work, or release automation. [VERIFIED: codebase: `AGENTS.md`, `modules/mb-image/png/moon.pkg`, `.planning/REQUIREMENTS.md`]

### the agent's Discretion

- Choose the exact public pull-result type names and internal wrapper-state layout, provided the policy snapshot records the resulting public API exactly and the established `PngChunk*` naming family is retained. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`, `policy/foundation.json`, `.planning/PROJECT.md`]
- Add focused native public behavioral tests needed to make the Phase 30 contract executable; do not substitute Phase 31's four-target hostile corpus or public workflow for those tests. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/milestones/v0.8-phases/27-public-png-chunk-decoder/27-01-GAP-CLOSURE-REPORT.md`]

### Deferred Ideas (OUT OF SCOPE)

- Four-target hostile-capacity qualification, broad eager/chunk resource evidence, and the public chunk-decode → operation → chunk-encode example are Phase 31 (PNGE-04 and PNGE-05). [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- Alternate compression, FFI codecs, host-I/O adapters, image-colour work, APNG, registry publication, and release automation remain excluded. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PNGE-02 | Caller-owned mutable output buffers receive deterministic exact progress until the canonical representation is emitted once, without retained buffers or duplicate/omitted bytes. | Thin `pull(MutByteLease)` adapter copies only a presently owned private byte, acknowledges exactly after `set` succeeds, and derives both per-call and cumulative counts from accepted bytes. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `modules/mb-core/bytes/views.mbt`] |
| PNGE-03 | The public encoder has eager-equivalent canonical bytes and terminal failure semantics; completion and failure are sticky and later calls expose no bytes. | Constructor delegates to `PngEncodeMachine::new`; wrapper stores either `Active(machine)`, `Finished`, or `Failed(CoreError)`, so later pulls return zero bytes with the same terminal outcome/error. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `modules/mb-image/png/stream_decode.mbt`, `.planning/REQUIREMENTS.md`] |

## Project Constraints (from AGENTS.md)

- Implement shared algorithms and data models in MoonBit; native is primary, while portable target support is deliberate and contractual. [VERIFIED: codebase: `AGENTS.md`]
- Keep FFI narrow and replaceable, retain acyclic explicit public dependencies, preserve Semantic Versioning discipline, and make public operations deterministic and GUI-independent. [VERIFIED: codebase: `AGENTS.md`]
- Do not modify repository files outside the GSD workflow; this research must guide planned implementation rather than direct code edits. [VERIFIED: codebase: `AGENTS.md`]
- Prefer codebase-memory graph discovery; this runtime exposes no graph MCP tool and `.planning/graphs/graph.json` is absent, so targeted repository inspection was used. [VERIFIED: runtime tool availability; codebase: `.planning/graphs/graph.json`]

## Summary

Phase 29 already provides the only correct byte source: `PngEncodeMachine::new` runs eager-equivalent source/capability, checked-size, limit, disposition, and budget admission before returning a machine; `present()` holds one canonical byte until `acknowledge()` commits it. Its `total_length()` and `completed()` counters are exact, it holds no output destination, and its byte sequence is the eager PNG representation. The public work therefore must be a lifecycle/copy adapter, not a parallel PNG encoder or a buffered facade. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/stream_encode.mbt`, `.planning/phases/29-pausable-png-encode-substrate/29-VERIFICATION.md`]

Expose `PngChunkEncoder::new(source, limits, budget, diagnostics) -> Result[PngChunkEncoder, CoreError]` and `pull(destination) -> PngChunkPullResult`. The constructor must call the private machine constructor exactly once. While active, each `pull` synchronously writes up to `destination.length()` presently pending/generated bytes and acknowledges each only after `MutByteLease::set` succeeds. This yields exact `written` and cumulative `total_written` counters, permits zero-length leases as ordinary `NeedOutput`, and leaves no `MutByteLease`, `ByteView`, destination owner, or copied PNG buffer in persistent state. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `modules/mb-core/bytes/views.mbt`, `modules/mb-image/qoi/stream_encode.mbt`]

**Primary recommendation:** Implement a `PngChunkEncoder` wrapper in the existing `png.mbt`/`stream_encode.mbt` split, register its exact generated interface in PNG policy, and add focused native API/ownership/terminal/parity tests. Reserve the exhaustive four-target schedules and public decode-process-encode evidence for Phase 31. [VERIFIED: codebase: `.planning/ROADMAP.md`, `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public constructor admission | API / Backend | Storage | The PNG package owns preflight; `ImageView` supplies only immutable image facts/pixels. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/storage`] |
| Canonical PNG byte production | API / Backend | — | `PngEncodeMachine` owns canonical framing, stored-DEFLATE cursors, CRC, Adler, and exact completion. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`] |
| Caller output mutation | API / Backend | Storage | The wrapper writes only through the current callback-scoped `MutByteLease`; `OwnedBytes` owns/reclaims the backing storage. [VERIFIED: codebase: `modules/mb-core/bytes/views.mbt`, `modules/mb-core/bytes/owned_bytes.mbt`] |
| Public API compatibility enforcement | API / Backend | CI / Static policy | Generated MBTI must equal `policy/foundation.json`, with negative fixtures rejecting unapproved surface drift. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Existing `tchivs/mb-image/png` package | repository current | Public PNG types plus private canonical machine | It is the established pure-MoonBit PNG surface, already declared for js, wasm, wasm-gc, and native. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `modules/mb-image/png/png.mbt`] |
| `PngEncodeMachine` | Phase 29 | Preflight and one-byte canonical output state | Its pending-byte/acknowledgement boundary is the verified single source for eager and chunk output. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/phases/29-pausable-png-encode-substrate/29-VERIFICATION.md`] |
| `@bytes.MutByteLease` | repository current | Caller-owned mutable destination capability | Its callback-scoped, range-checked lifetime prevents a public encoder from retaining a mutable owner. [VERIFIED: codebase: `modules/mb-core/bytes/views.mbt`, `modules/mb-core/bytes/owned_bytes.mbt`] |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Existing `QoiStreamEncoder` pull shape | Public `new`/`pull`, per-call and cumulative output accounting precedent | Reuse the synchronous lease pattern only; do not import or generalize QOI token internals. [VERIFIED: codebase: `modules/mb-image/qoi/qoi.mbt`, `modules/mb-image/qoi/stream_encode.mbt`] |
| `PngChunkDecoder` state replay pattern | Original-error sticky failure precedent | Mirror `Active`/`Failed(CoreError)` lifecycle and zero-progress terminal calls, while PNG encode additionally keeps `Finished` sticky. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `modules/mb-image/png/stream_decode_test.mbt`] |
| PNG policy assertions | Public API and source inventory gate | Update in the same plan task as declarations and regenerate MBTI. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Thin wrapper over `PngEncodeMachine` | Build a second public byte generator | Rejected: separate framing/checksum/acknowledgement paths can drift from eager bytes and preflight/error order. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/stream_encode.mbt`] |
| Caller-provided lease each pull | Store an `OwnedBytes`, `MutByteLease`, or `ByteView` on the encoder | Rejected: it violates PNGE-02 ownership and the capability's callback-scoped lifetime. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-core/bytes/views.mbt`] |
| Sticky `Finished` and original `Failed(error)` outcomes | Reuse QOI's post-finish state error | Rejected: PNGE-03 explicitly requires the same terminal outcome/error after success or failure; QOI's older post-finish failure is not sufficient. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/qoi/stream_encode.mbt`] |

**Installation:** None. This phase installs no external package. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `.planning/REQUIREMENTS.md`]

## Architecture Patterns

### System Architecture Diagram

```text
immutable ImageView + limits + budget
                 |
                 v
   PngChunkEncoder::new (one call to PngEncodeMachine::new)
                 |
       preflight failure -> Result::Err, no public encoder/output
                 |
                 v
 Active(PngEncodeMachine) --pull(current MutByteLease)-->
     present pending byte -> lease.set -> acknowledge byte -> exact counters
                 |                 ^       (lease is parameter only)
                 |                 |
                 +-- empty lease -> NeedOutput, 0 written
                 |
                 +-- machine complete -> Finished
                 +-- set/present/ack error -> Failed(original CoreError)
                                       |
                 later pull -> 0 written + same Finished / Failed(error)
```

### Recommended Public Contract

Declare the public values in `png.mbt`, with behavior implemented beside the private machine in `stream_encode.mbt`:

```moonbit
pub struct PngChunkEncoder { /* private lifecycle state only */ }

pub(all) enum PngChunkPullOutcome {
  NeedOutput
  Finished
  Failed(@error.CoreError)
}

pub struct PngChunkPullResult { /* written, total_written, outcome */ }

pub fn PngChunkEncoder::new(
  @storage.ImageView, @codec.CodecLimits, @budget.Budget, @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError]
pub fn PngChunkEncoder::pull(Self, @bytes.MutByteLease) -> PngChunkPullResult
pub fn PngChunkPullResult::written(Self) -> UInt64
pub fn PngChunkPullResult::total_written(Self) -> UInt64
pub fn PngChunkPullResult::outcome(Self) -> PngChunkPullOutcome
```

The `PngChunkPull*` spellings are a Phase-30 recommendation that follows the existing `PngChunkDecoder` and QOI `*Pull*` vocabulary; lock them in policy only after implementation compiles. [ASSUMED]

### Pattern 1: Copy Then Acknowledge

**What:** `pull` asks the machine for its current byte, writes it to the transient destination, and calls `acknowledge` only after `destination.set` returns `Ok`.

**When to use:** Every active byte; no alternative fast path may update `completed` or expose a later byte.

```moonbit
let byte = machine.present().unwrap().unwrap()
match destination.set(written, byte) {
  Err(error) => self.state = Failed(error)
  Ok(_) => {
    machine.acknowledge(byte).unwrap()
    written = written + 1UL
  }
}
```

This is the public equivalent of the verified private present/acknowledge protocol. Production code must propagate rather than `unwrap`; the snippet shows the required ordering only. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]

### Pattern 2: Sticky Public Lifecycle

**What:** Persist only `Active(machine)`, `Finished`, or `Failed(error)`. Terminal branches do not inspect or mutate a destination.

**When to use:** At the start of every `pull`, after the final acknowledgment, and after any typed failure.

```moonbit
match self.state {
  Finished => result(0UL, machine_completed, Finished)
  Failed(error) => result(0UL, machine_completed, Failed(error))
  Active(machine) => drain_current_lease(machine, destination)
}
```

`total_written` remains the machine's accepted count; after normal completion it equals its precomputed total exactly. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/REQUIREMENTS.md`]

### Pattern 3: Exact Policy Registration with the Public Change

**What:** Regenerate `pkg.generated.mbti`, copy its semantic sequence into `policy/foundation.json`, and extend the PNG policy's required/negative type checks.

**When to use:** In the same plan task as public declarations, before claiming the API exists.

**Implementation files:**

```text
modules/mb-image/png/
├── png.mbt                 # public PngChunkEncoder / pull result declarations
├── stream_encode.mbt       # lifecycle wrapper over PngEncodeMachine; no new byte generator
├── stream_encode_test.mbt  # public schedule, ownership, parity, terminal tests
└── stream_encode_wbtest.mbt# private machine/wrapper invariant regressions as needed
policy/foundation.json      # exact generated semantic interface
scripts/quality/Assert-Policy.ps1 # required + negative PNG interface checks
```

The package inventory and production-source order already include `stream_encode.mbt`; Phase 30 should not add a file solely for the public adapter. [VERIFIED: codebase: `scripts/quality/Assert-Policy.ps1`, `policy/foundation.json`]

### Anti-Patterns to Avoid

- **Second PNG emitter or full-output staging:** never generate public bytes from a separate `Bytes` buffer; call only `PngEncodeMachine::present`/`acknowledge`. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/REQUIREMENTS.md`]
- **Acknowledging before destination mutation:** it would make a failed `set` omit a canonical byte and corrupt exact progress. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]
- **Retaining the caller lease/view:** a lease becomes inactive when its `OwnedBytes::with_mut` callback exits, so any retained use is invalid. [VERIFIED: codebase: `modules/mb-core/bytes/views.mbt`, `modules/mb-core/bytes/owned_bytes.mbt`]
- **Replacing the first failure:** store and replay the original `CoreError`; do not turn it into a generic terminal error on later pulls. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `.planning/REQUIREMENTS.md`]
- **Treating Phase 31 evidence as a substitute for Phase 30 tests:** Phase 27's initial verification found that plausible public code without focused schedule/ownership/parity/terminal tests was insufficient. [VERIFIED: codebase: `.planning/milestones/v0.8-phases/27-public-png-chunk-decoder/27-01-GAP-CLOSURE-REPORT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PNG frame/zlib/checksum output | Public duplicate PNG formatter | `PngEncodeMachine` | It is the verified canonical private source and preserves existing CRC/Adler behavior. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/phases/29-pausable-png-encode-substrate/29-VERIFICATION.md`] |
| Admission/errors/budget accounting | Stream-specific preflight | `PngEncodeMachine::new` / `_png_encode_preflight` | Public construction must preserve eager error type/order and atomic budget admission. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/stream_encode.mbt`] |
| Mutable-output lifetime | Retained output object or custom unsafe buffer | `MutByteLease` supplied to each `pull` | It is the established range-checked, callback-scoped capability. [VERIFIED: codebase: `modules/mb-core/bytes/views.mbt`, `modules/mb-image/qoi/stream_encode.mbt`] |
| Public interface validation | Hand-maintained API claim | `moon info` plus exact policy/negative fixtures | Existing policy fails closed on MBTI, imports, targets, source order, and inventory drift. [VERIFIED: codebase: `scripts/quality/Assert-Policy.ps1`, `policy/foundation.json`] |

**Key insight:** The public encoder is a byte-transfer protocol, not a new codec. Its only durable state should be the private machine plus a terminal discriminator; byte creation, exact totals, resource admission, and checksum correctness remain exclusively below that boundary. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/REQUIREMENTS.md`]

## Common Pitfalls

### Pitfall 1: Terminal success converted to a generic failure

**What goes wrong:** A final successful pull returns `Finished`, but a later pull returns a new state error, so completion is not sticky as PNGE-03 requires.

**How to avoid:** Store `Finished` in the public wrapper and return `{ written: 0, total_written: fixed_total, outcome: Finished }` on every later call. Test both the call that writes the last byte and at least two later calls. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/qoi/stream_encode.mbt`]

### Pitfall 2: Failure loses its original typed error

**What goes wrong:** The initial lease/machine failure is replaced with a wrapper error on the next call.

**How to avoid:** Persist `Failed(error)` and return the stored value unchanged with zero new bytes. Compare category, code, operation, requested, completed, limit, and context in the terminal test, following the existing PNG error-identity practice. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `modules/mb-image/png/encode_test.mbt`]

### Pitfall 3: Lease retention hidden by passing simple tests

**What goes wrong:** A wrapper accidentally stores a lease/view; initial output may pass but later access uses an invalid capability or a mutated old buffer.

**How to avoid:** Keep the lease only as the `pull` parameter. Test a first pull, mutate/reuse that caller owner after return, then finish through a fresh owner and compare concatenated bytes with eager output. [VERIFIED: codebase: `modules/mb-core/bytes/owned_bytes.mbt`, `modules/mb-image/png/stream_decode_test.mbt`]

### Pitfall 4: Accounting the copied byte before acknowledgement

**What goes wrong:** Counters report a byte that the private machine did not commit, or the next pull repeats/omits bytes.

**How to avoid:** Increment public `written` only after `set` and `acknowledge` both succeed; use `machine.completed()` as cumulative truth. Test zero, one-byte, and irregular capacity leases, checking every returned total against collected bytes. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `modules/mb-image/qoi/stream_encode_test.mbt`]

## Phase 30 / Phase 31 Boundary

| Deliver in Phase 30 | Reserve for Phase 31 |
|---------------------|----------------------|
| Public declarations, thin wrapper, exact interface-policy update, and focused native behavior tests for empty/tiny/irregular output, byte parity, no retained lease, and sticky terminals. [VERIFIED: codebase: `.planning/ROADMAP.md`, `policy/foundation.json`] | Target-isolated js/wasm/wasm-gc/native hostile-capacity suite, broad limit/budget parity evidence, deterministic public decode → operation → chunk-encode workflow, and output evidence. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`] |
| Constructor delegates directly to Phase 29 preflight and rejects before a pull can occur. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`] | No new transport/wrapper semantics; Phase 31 validates the Phase 30 contract rather than extending it. [VERIFIED: codebase: `.planning/ROADMAP.md`] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The chosen public result names should be `PngChunkPullOutcome` and `PngChunkPullResult`. | Recommended Public Contract | Policy/API naming would need a small coordinated rename before implementation, but the lifecycle semantics remain unchanged. |
| A2 | A repeated successful terminal pull should report `Finished`, rather than the QOI wrapper's generic terminal failure. | Alternatives; Pitfall 1 | If maintainers interpret PNGE-03 differently, downstream callers could observe a different terminal result; resolve in plan review before locking MBTI. |
| A3 | A released/inactive `MutByteLease` can be used in a focused test to induce a typed `set` failure and prove error replay. | Test guidance | MoonBit ownership restrictions may require a dedicated test seam; terminal replay still must be tested through an executable typed error. |

## Open Questions (RESOLVED)

1. **Approved public pull-result names**
   - Resolution: publish `PngChunkPullOutcome` and `PngChunkPullResult`. The names retain the existing `PngChunk*` family and QOI's established `*Pull*` vocabulary, and Task 3 locks their generated semantic interface in policy. [DECIDED: Phase 30 plan review; VERIFIED: codebase: `.planning/PROJECT.md`, `modules/mb-image/png/png.mbt`, `modules/mb-image/qoi/qoi.mbt`]

2. **Success-terminal replay shape**
   - Resolution: the final successful pull and every later pull return a zero-byte `PngChunkPullOutcome::Finished` result with the preserved final cumulative total. A successful encoder never converts later pulls into a synthetic state failure. [DECIDED: Phase 30 plan review; VERIFIED: codebase: `.planning/REQUIREMENTS.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | Build/test and generated interface | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` | MoonBit compiler | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local `moonc -v`] |
| `moonrun` | Test execution | ✓ | `0.1.20260713` | — [VERIFIED: local `moonrun --version`] |
| PowerShell | Policy checks | ✓ | `7.6.3` | — [VERIFIED: local `pwsh --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local command probes]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Portable codec has no identity boundary. [VERIFIED: codebase: `modules/mb-image/png`] |
| V3 Session Management | no | No session state exists. [VERIFIED: codebase: `modules/mb-image/png`] |
| V4 Access Control | no | No authorization surface exists. [VERIFIED: codebase: `modules/mb-image/png`] |
| V5 Input Validation | yes | Preserve private source/capability/checked-limit/budget preflight and validate lease writes through the existing range-checked capability. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-core/bytes/views.mbt`] |
| V6 Cryptography | no | PNG CRC/Adler are format checksums, not security controls; do not add cryptography. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`] |

### Known Threat Patterns for Public PNG Output

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Large image/limit/budget admission | Denial of Service | Constructor delegates to the Phase-29 checked preflight before a public output call exists. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/stream_encode.mbt`] |
| Replayed, omitted, or duplicated byte across pulls | Tampering | Present → set → acknowledge order and exact private completed counter. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`] |
| Stale destination access after a pull | Information Disclosure / Tampering | Do not retain `MutByteLease`/`ByteView`; lease is callback-scoped and each pull receives a new capability. [VERIFIED: codebase: `modules/mb-core/bytes/views.mbt`] |
| Terminal error substitution | Repudiation / Tampering | Store/replay the first typed `CoreError` exactly and test every exposed field. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `modules/mb-image/png/encode_test.mbt`] |

## Sources

### Primary (HIGH confidence)

- Codebase: `modules/mb-image/png/stream_encode.mbt` — private preflight consumer, canonical byte source, pending-byte acknowledgement, exact counters, and ownership shape.
- Codebase: `modules/mb-image/png/encode.mbt` and Phase 29 verification — eager adapter/preflight/error identity and shipped handoff guarantees.
- Codebase: `modules/mb-image/png/png.mbt`, `stream_decode.mbt`, and `stream_decode_test.mbt` — current public PNG state/result/policy/testing conventions.
- Codebase: `modules/mb-image/qoi/qoi.mbt`, `stream_encode.mbt`, and stream tests — caller-lease pull precedent and its terminal limitation.
- Codebase: `policy/foundation.json` and `scripts/quality/Assert-Policy.ps1` — exact generated-interface and fail-closed policy contract.

### Secondary (MEDIUM confidence)

- None; the phase extends an internal repository contract and does not adopt an external library/API.

### Tertiary (LOW confidence)

- A1-A3 in the Assumptions Log; resolve before public MBTI is locked.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — existing package and no new external dependency. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`]
- Architecture: HIGH — direct private-machine, public-decoder, QOI-pull, and policy precedents exist; exact public result spelling is explicitly logged as an assumption. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `modules/mb-image/png/stream_decode.mbt`]
- Pitfalls: HIGH — based on an explicit Phase 27 missing-test finding and live ownership/terminal implementations. [VERIFIED: codebase: `.planning/milestones/v0.8-phases/27-public-png-chunk-decoder/27-01-GAP-CLOSURE-REPORT.md`, `modules/mb-core/bytes/views.mbt`]

**Research date:** 2026-07-21
**Valid until:** 2026-08-20 (repository-local public API phase; revisit if a Phase 30 CONTEXT.md is added).
