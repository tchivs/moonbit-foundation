# Phase 78: Resumable Indexed PNG & Qualification - Research

**Researched:** 2026-07-24
**Domain:** bounded caller-buffered Indexed8 PNG encoding and portable qualification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Caller-buffered API and machine reuse
- **D-01:** Add one explicit `PngChunkEncoder` Indexed8 constructor which accepts `PngIndexedImage`, limits, budget, and diagnostics and delegates to the same indexed preflight/frame facts/acknowledged `PngEncodeMachine` used by eager encoding. No generic model widening or parallel traversal. — **Reversibility:** costly — later consumers will use this public constructor and its lifecycle contract.
- **D-02:** Limit the streaming profile to Type-3/8, non-interlaced, Stored DEFLATE, filter None, RGB palette plus Phase 77 canonical optional tRNS. Do not add strategy families, low bit depths, Adam7, quantization, staging, chunks, or FFI.

### Lifecycle and atomicity
- **D-03:** Require chunk output to be byte-identical to eager output under zero-capacity, one-byte, and ragged caller leases; progress and CRC state advance only for bytes the caller accepts. — **Reversibility:** costly — this is the established public streaming ownership rule.
- **D-04:** Preserve atomic preflight before output/lease exposure and retain the established sticky success/error terminals, including repeated pull/finish behavior and rejected or unaccepted leases.

### Qualification evidence
- **D-05:** Use test-local independent PNG wire and CRC parsing, public generic RGB8/RGBA8 decode, hostile lease schedules, frozen opaque compatibility, and the ordinary all-target PNG package test. No copied source trees, release automation, or test wrappers.

### the agent's Discretion
- The exact public constructor spelling should follow the closest existing PNG profile constructor and established error vocabulary.
- The planner may split implementation and qualification into multiple plans only when that makes test ownership clearer; no scope expansion is allowed.

### Deferred Ideas (OUT OF SCOPE)

None — Indexed1/2/4, indexed Adam7, quantization, strategy expansion, generic model changes, FFI, release automation, target wrappers, and source-tree copying remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| INDEX-04 | Caller-buffered indexed output shares the bounded layout machine, has eager-identical bytes under hostile capacities, preserves lease ownership, and retains sticky terminals. | Reuse `PngEncodeMachine::new_with_indexed` and the single `PngChunkEncoder::pull` state path; qualify zero/one/ragged parity, accepted-only counters, lease tails, and success/error replay. [VERIFIED: codebase inspection] |
| INDEX-05 | Independent indexed wire/decode vectors, hostile lifecycle evidence, frozen legacy compatibility, and the ordinary full PNG package pass cover wasm, wasm-gc, js, and native. | Reuse the test-local Indexed CRC/chunk parser and public decoder assertions already in `encode_test.mbt`; add chunk-origin evidence and run the ordinary four-target package command. [VERIFIED: codebase inspection] |
</phase_requirements>

## Summary

Phase 78 should be a narrow adapter plus qualification phase. The current eager entry, `PngEncoder::encode_indexed8`, constructs `PngEncodeMachine::new_with_indexed`; that constructor runs `_png_encode_indexed_preflight`, stores the immutable `PngIndexedImage`, fixes `Indexed8`/Stored/None/non-interlaced facts, and initializes the same pending-byte/CRC machine already used by all output paths. The only production change required is one profile-specific chunk factory that constructs that same machine and stores it in the established `PngChunkEncoderState::Active` state. [VERIFIED: codebase inspection]

The existing chunk `pull` loop is already the ownership boundary: a byte is previewed, written to the caller lease, then acknowledged; only acknowledgement advances emitted position, total progress, CRC, and DEFLATE state. A zero-capacity lease cannot enter that loop, completed and failed states return zero writes without touching a later lease, and a rejected lease becomes a sticky error. Indexed sources are immutable owning values, so this phase must prove that lifecycle rather than create a second traversal, source revision scheme, or output buffer. [VERIFIED: codebase inspection]

**Primary recommendation:** Add `PngChunkEncoder::new_indexed8(source, limits, budget, diagnostics)` as the only new public production API, call `PngEncodeMachine::new_with_indexed` directly, and concentrate all remaining work in independent wire/decode, hostile-lease, admission, compatibility, and four-target tests. [VERIFIED: codebase inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Indexed source validation and ownership | API / Backend | Database / Storage — | `PngIndexedImage` validates and defensively owns index/palette/alpha bytes before the streaming factory receives it. [VERIFIED: codebase inspection] |
| Indexed frame/resource admission | API / Backend | — | `_png_encode_indexed_preflight` derives Type-3 frame facts, enforces limits, then charges work before a machine exists. [VERIFIED: codebase inspection] |
| Byte emission, CRC and accepted-only progress | API / Backend | — | `PngEncodeMachine` previews bytes and commits cursors/CRCs in `acknowledge`; `PngChunkEncoder::pull` owns caller leases. [VERIFIED: codebase inspection] |
| Portable qualification | API / Backend | CI / Static | The `mb-image` module explicitly supports js, wasm, wasm-gc, and native, and existing phase evidence uses the ordinary package test across all targets. [VERIFIED: codebase inspection] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be MoonBit-first; native stubs must stay isolated, documented, and replaceable. [VERIFIED: AGENTS.md]
- Public packages must retain acyclic, explicitly documented dependencies; public API stability follows SemVer once stable. [VERIFIED: AGENTS.md]
- Public operations must be deterministic and GUI-independent; benchmark claims need reproducible workloads and baselines. [VERIFIED: AGENTS.md]
- New modules and breaking architectural changes require RFCs. [VERIFIED: AGENTS.md]
- `mb-image` is portable across js, wasm, wasm-gc, and native. [VERIFIED: modules/mb-image/moon.mod.json]

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Compile and execute the existing portable PNG package. | Installed local toolchain and project baseline; no new package is needed. [VERIFIED: local toolchain] |
| Existing `mb-image/png` package | repository source | Indexed source, eager preflight, shared byte machine, caller-buffered transport, and tests. | Adding a new dependency or encoder would contradict locked scope; all required seams already exist locally. [VERIFIED: codebase inspection] |

### Supporting

| Component | Purpose | When to Use |
|---|---|---|
| `PngIndexedImage` | Immutable indexed raster with RGB palette and per-entry alpha. | Accept this exact type at the new explicit constructor; do not widen `ImageView`/`ImageFormat`. [VERIFIED: codebase inspection] |
| `_png_encode_indexed_preflight` and `PngEncodeMachine::new_with_indexed` | Shared bounded facts and acknowledged byte emission. | Use unchanged in the constructor; do not duplicate layout or frame calculations. [VERIFIED: codebase inspection] |
| Existing test-local `png_indexed_crc32` and public `PngDecoder` | Independent structural CRC oracle and observable RGB8/RGBA8 decode oracle. | Use against chunk-produced bytes, not production PNG helpers. [VERIFIED: codebase inspection] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| One `new_indexed8` factory over the shared machine | A separate Indexed chunk encoder/traversal | Rejected: creates divergent byte, preflight, budget, and terminal semantics, contradicting D-01. [VERIFIED: 78-CONTEXT.md] |
| Fixed Indexed8 profile | Strategy/low-bit/Adam7 selectors | Rejected: explicitly deferred and would broaden public behavior beyond INDEX-04/05. [VERIFIED: 78-CONTEXT.md] |

**Installation:** None — Phase 78 installs no external packages. [VERIFIED: 78-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
PngIndexedImage (immutable, validated, owned)
        |
        v
PngChunkEncoder::new_indexed8  [recommended public entry]
        |
        v
PngEncodeMachine::new_with_indexed
        |
        +--> indexed preflight: Type-3/8 frame + PLTE + optional canonical tRNS
        |     limits check --> budget work charge --> Active machine
        |
        v
caller lease -- pull() --> present() -- set(lease byte) --> acknowledge(byte)
                         |                              |
                         |                              +--> CRC/cursor/progress commit
                         v
                   NeedOutput / Finished / Failed (sticky)
```

The machine path above already exists except for the public factory label. In particular, PLTE and optional tRNS are byte-previewed from the indexed source and their CRCs are advanced only inside `acknowledge`. [VERIFIED: codebase inspection]

### Recommended Project Structure

```text
modules/mb-image/png/
├── stream_encode.mbt          # add only the Indexed8 chunk factory
├── stream_encode_test.mbt     # hostile leases, atomic factory errors, sticky terminals
├── encode_test.mbt            # independent Indexed wire/CRC and public decode evidence
└── encode_wbtest.mbt          # frame-fact and acknowledgement timing assertions
```

This uses the five-file Phase 76/77 ownership split without creating a parallel transport, test wrapper, or copied source tree. [VERIFIED: Phase 76/77 summaries and 78-CONTEXT.md]

### Pattern 1: Profile-specific factory delegates to one machine

**What:** The factory performs no local framing, allocation, or lease work. It calls the profile machine constructor, returns its error unchanged, or wraps the constructed machine in `Active` with `total_written: 0`. Existing explicit Gray1/Gray2/Gray4 factories establish that exact shape. [VERIFIED: codebase inspection]

**When to use:** Use for the sole Indexed8 caller-buffered entry; do not add generic overloads or strategy variants. [VERIFIED: 78-CONTEXT.md]

**Recommended implementation shape:**

```moonbit
// Recommended signature/name; exact spelling is discretionary. [ASSUMED]
pub fn PngChunkEncoder::new_indexed8(
  source : PngIndexedImage,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = PngEncodeMachine::new_with_indexed(source, limits, budget, diagnostics)?
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}
```

### Pattern 2: Acknowledge only bytes accepted by the caller

**What:** `present` caches a pending byte but does not mutate emission state; `pull` calls `destination.set` and then `acknowledge`; `acknowledge` updates PLTE/tRNS/IDAT CRCs, clears pending state, and increments emitted bytes. [VERIFIED: codebase inspection]

**When to use:** Do not special-case indexed PLTE or tRNS in `pull`; its existing `PngEncodeMachine` methods already apply this sequencing to those spans. [VERIFIED: codebase inspection]

### Anti-Patterns to Avoid

- **A second Indexed transport or writer loop:** duplicates `present`/`acknowledge` and risks byte or CRC divergence from eager. [VERIFIED: 78-CONTEXT.md]
- **Calling preflight after exposing a lease:** violates D-04; preflight and work charging must occur during factory construction. [VERIFIED: codebase inspection]
- **Using production CRC/wire helpers in qualification:** makes the wire test circular; retain test-local parser/CRC logic. [VERIFIED: 77-VERIFICATION.md]
- **Adding low-bit, Adam7, compression/filter strategies, model changes, FFI, release automation, wrappers, or copied trees:** all are expressly out of scope. [VERIFIED: 78-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Indexed frame layout | A duplicate IHDR/PLTE/tRNS/IDAT/IEND calculator | `_png_encode_indexed_preflight` → `PngFrameFacts` | Existing code computes canonical optional tRNS spans, checked output length, limits, and work charge. [VERIFIED: codebase inspection] |
| Resumable byte state | A second cursor/CRC/state machine | `PngEncodeMachine::new_with_indexed` plus existing `pull` | One pending-byte protocol already makes PLTE/tRNS CRC and progress acknowledgement-safe. [VERIFIED: codebase inspection] |
| Hostile-lease harness | New capacity/terminal framework | `png_stream_packed_hostile_drain` pattern and `png_chunk_test_owner` helpers | Existing tests verify zero, one, ragged capacities, accepted-only counters, unchanged tails, success replay, and released-lease errors. [VERIFIED: codebase inspection] |
| PNG structural oracle | Production codec internals | Test-local `png_indexed_crc32`, chunk slicing, and public `PngDecoder` | Keeps wire/CRC qualification independent and user-observable. [VERIFIED: codebase inspection] |

**Key insight:** correctness here is the order `preflight -> factory Active -> lease.set -> acknowledge`, not merely producing a valid PNG. Reusing the established machine preserves all four resource, progress, CRC, and terminal contracts simultaneously. [VERIFIED: codebase inspection]

## Common Pitfalls

### Pitfall 1: Correct bytes but wrong lifecycle

**What goes wrong:** A factory that manually emits palette chunks can match one eager vector yet advance CRC/progress before a lease accepts the byte or mutate terminal leases. [VERIFIED: codebase inspection]

**How to avoid:** Make the factory a direct `new_with_indexed` wrapper and drive all bytes through `PngChunkEncoder::pull`. Add zero/one/ragged tests that check `total_written == previously collected + written`, caller-tail sentinels, and repeated completed pulls. [VERIFIED: codebase inspection]

### Pitfall 2: Non-atomic resource admission

**What goes wrong:** A late limit/work check can charge the supplied budget or make a machine visible before rejection. Indexed preflight currently checks dimensions/pixels/output/work before calling `budget.charge`. [VERIFIED: codebase inspection]

**How to avoid:** Do not add any preliminary charge or temporary output allocation in the chunk factory. Test an output-limit failure, an exhausted work budget, and zero pixel budget against snapshots of every resource-limit field. [VERIFIED: codebase inspection]

### Pitfall 3: Opaque and transparent paths are not both qualified

**What goes wrong:** Testing only a transparent image misses the Phase 76 frozen opaque 89-byte vector; testing only opaque data misses tRNS offsets and its independent CRC. [VERIFIED: codebase inspection]

**How to avoid:** Drain one opaque and one partial-alpha source through hostile schedules; apply the exact opaque frozen vector and independently parse the transparent `IHDR -> PLTE -> tRNS -> IDAT -> IEND` sequence. Decode opaque bytes as RGB8 and transparent bytes as RGBA8 through the public generic decoder. [VERIFIED: codebase inspection]

### Pitfall 4: Weak sticky-error proof

**What goes wrong:** A post-error pull may mutate a later lease or report a different error. Existing `pull` caches `Failed(error)` and returns it before touching the destination. [VERIFIED: codebase inspection]

**How to avoid:** Release the first 1-byte lease before `pull`, capture its typed error, then pull into a fresh `Z`-filled lease and assert zero writes, unchanged total, same error, and unchanged lease byte. [VERIFIED: codebase inspection]

## Code Examples

### Hostile Indexed8 test plan

```moonbit
// Reuse the established packed-grayscale hostile-drain structure. [VERIFIED: codebase inspection]
let eager = encode_indexed8_to_memory(source)
let encoder = PngChunkEncoder::new_indexed8(source, limits, budget, diagnostics).unwrap()
// First: a 0-byte lease must be NeedOutput, 0 total, and preserve sentinel.
// Then drain fresh encoders with [0UL, 1UL], [1UL], and [0UL, 1UL, 3UL, 2UL, 5UL].
// At every pull: collect only written bytes and assert untouched tail remains 'Z'.
// At Finished: output == eager; a later lease is untouched and returns Finished.
```

The test naming/API call above is a recommended composition, not an existing source snippet; the hostile-drain invariants and schedules are established by the current packed grayscale tests. [ASSUMED]

### Independent transparent wire and public decode plan

```moonbit
// In encode_test.mbt, use the existing test-local png_indexed_crc32/slice/u32 helpers.
// Parse chunk lengths/types and assert PLTE then canonical tRNS then IDAT.
// Validate each independent CRC; decode the produced bytes via PngDecoder and
// assert public RGBA8 components. Repeat with an opaque palette and RGB8 decode.
```

The existing eager tests already supply both a 89-byte opaque vector and a 112-byte partial-alpha vector with these oracle styles; Phase 78 should apply them to chunk-origin bytes and preserve the opaque literal unchanged. [VERIFIED: codebase inspection]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Eager-only Indexed8 source/output (Phase 76) | Eager Type-3/8 with optional canonical tRNS (Phase 77) | The machine now already models PLTE/tRNS facts and acknowledgement-safe CRC; Phase 78 only exposes caller-buffered reuse. [VERIFIED: Phase 76/77 summaries] |
| Profile-specific streaming adapters for image views | Explicit Indexed8 source-specific adapter is needed | `PngIndexedImage` cannot enter generic `ImageView` APIs by design, so its factory must remain explicit. [VERIFIED: Phase 76/77 context and codebase inspection] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The preferred public spelling is `PngChunkEncoder::new_indexed8`. It is inferred from `PngEncoder::encode_indexed8` and profile factory naming; the context leaves spelling discretionary. | Architecture Patterns / Code Examples | Public API naming could conflict with project convention; planner must confirm before implementation. |
| A2 | The shown `?`-based MoonBit implementation shape is illustrative rather than syntax-verified in this session. | Architecture Patterns | The executor may need the repository's explicit `match` error-return style instead. |

## Open Questions (RESOLVED)

1. **Exact public constructor spelling**
   - What we know: Existing generic explicit profile factories use names such as `new_gray1`, and eager Indexed8 uses `encode_indexed8`. [VERIFIED: codebase inspection]
   - Resolution: Use `PngChunkEncoder::new_indexed8(source, limits, budget, diagnostics)`, following `new_gray1`'s direct `match`/`Active` factory shape. This is the Phase 78 public API. [RESOLVED]

2. **Test file split**
   - What we know: `stream_encode_test.mbt` owns hostile leases/lifecycles; `encode_test.mbt` owns independent Indexed wire/CRC/public decode; `encode_wbtest.mbt` owns frame and acknowledgement internals. [VERIFIED: codebase inspection]
   - Resolution: Task 1 owns the adapter plus lifecycle, lease, terminal, and atomicity tests; Task 2 owns independent public wire/decode and frozen-compatibility qualification. Existing `encode_wbtest.mbt` acknowledgement-CRC coverage remains exercised by the unfiltered ordinary package suite. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` / `moonc` / `moonrun` | Four-target PNG package test | ✓ | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | — [VERIFIED: local toolchain] |
| `modules/mb-image` target declaration | INDEX-05 portability | ✓ | `+js+wasm+wasm-gc+native` | — [VERIFIED: modules/mb-image/moon.mod.json] |

**Missing dependencies with no fallback:** None. [VERIFIED: local toolchain]

**Missing dependencies with fallback:** None. [VERIFIED: local toolchain]

**Required portable qualification command:**

```powershell
moon -C modules/mb-image test png --target all --frozen
```

This is the ordinary source-tree PNG package command for wasm, wasm-gc, js, and native; do not add `--filter`, copied trees, target wrappers, or release automation as Phase 78 substitutes. [VERIFIED: 78-CONTEXT.md and modules/mb-image/moon.mod.json]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity boundary is added. [VERIFIED: 78-CONTEXT.md] |
| V3 Session Management | no | No session state is added. [VERIFIED: 78-CONTEXT.md] |
| V4 Access Control | no | No authorization decision is added. [VERIFIED: 78-CONTEXT.md] |
| V5 Input Validation | yes | Preserve validated `PngIndexedImage` construction plus width/height/pixel/output/work checks in preflight; never expose a lease on rejected admission. [VERIFIED: codebase inspection] |
| V6 Cryptography | no | PNG CRC is an integrity checksum for file structure, not a security control; no cryptography is in scope. [VERIFIED: 78-CONTEXT.md] |

### Known Threat Patterns for bounded PNG encoding

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Malformed dimensions, palette cardinality, or index values | Tampering | Source validates all indexed inputs before its sole owned allocation. [VERIFIED: codebase inspection] |
| Resource exhaustion through dimensions/output/work | Denial of service | Preflight uses checked arithmetic, codec limits, and one work charge after checks. [VERIFIED: codebase inspection] |
| State/progress corruption from unaccepted output | Tampering | Pending byte is committed only via acknowledgement after lease write; failure is sticky. [VERIFIED: codebase inspection] |

## Validation Architecture

Skipped: `.planning/config.json` explicitly sets `workflow.nyquist_validation` to `false`. [VERIFIED: .planning/config.json]

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/stream_encode.mbt` — current profile factories, `PngChunkEncoder::pull`, Indexed machine construction, frame emission, acknowledgement, and terminal state. [VERIFIED: codebase inspection]
- `modules/mb-image/png/encode.mbt` and `png.mbt` — immutable Indexed8 ownership and atomic preflight facts. [VERIFIED: codebase inspection]
- `modules/mb-image/png/stream_encode_test.mbt`, `encode_test.mbt`, and `encode_wbtest.mbt` — existing hostile lease, independent CRC/wire, public decode, frozen vector, and acknowledgement-time assertions. [VERIFIED: codebase inspection]
- `76-01-SUMMARY.md`, `77-01-SUMMARY.md`, and `77-VERIFICATION.md` — established scope, 89-/112-byte evidence, and completed all-target prior qualification. [VERIFIED: phase artifacts]
- `78-CONTEXT.md`, `REQUIREMENTS.md`, and `ROADMAP.md` — locked scope and INDEX-04/05 requirement boundary. [VERIFIED: planning artifacts]

### Secondary (MEDIUM confidence)

- None — no external dependency or framework decision is needed for this codebase-constrained phase.

### Tertiary (LOW confidence)

- Constructor spelling and illustrative implementation syntax only; listed in the Assumptions Log. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new library/package choice; exact local toolchain and module targets were inspected. [VERIFIED: local toolchain]
- Architecture: HIGH — the eager Indexed machine and caller-buffered state loop were inspected directly. [VERIFIED: codebase inspection]
- Pitfalls: HIGH — each derives from existing preflight, lease, CRC, and terminal test/code paths. [VERIFIED: codebase inspection]

**Research date:** 2026-07-24
**Valid until:** implementation start; this is tied to the present worktree and should be refreshed if Phase 76/77 seams change. [VERIFIED: codebase inspection]
