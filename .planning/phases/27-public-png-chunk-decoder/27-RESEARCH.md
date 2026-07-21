# Phase 27: Public PNG Chunk Decoder - Research

**Researched:** 2026-07-21
**Domain:** Portable MoonBit streaming codec API over an existing private PNG continuation machine
**Confidence:** HIGH

## User Constraints

No `27-CONTEXT.md` exists. The following locked scope is taken from the active roadmap, requirements, Phase 26 verification, and the parent assignment.

### Locked Decisions

- Publish the API as `PngChunkDecoder`, accept arbitrary caller-owned `ByteView` chunks, and make `finish()` the only EOF declaration. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- Preserve the existing `PngDecoder` Reader contract unchanged; the public chunk decoder must use the Phase 26 `PngDecodeMachine`, not a second parser. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/phases/26-pausable-png-decode-substrate/26-01-SUMMARY.md`]
- Preserve deterministic full-profile PNG results and typed errors, including limits, budgets, no-result-before-final-integrity, and four portable targets. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/phases/26-pausable-png-decode-substrate/26-01-VERIFICATION.md`]
- Match the established QOI streaming API conventions where they do not conflict with PNG's stricter terminal/error requirements. [VERIFIED: codebase: `modules/mb-image/qoi/qoi.mbt`, `modules/mb-image/qoi/stream_decode.mbt`]
- Do not add FFI, an external package, a PNG streaming encoder, a release/registry workflow, a new reader EOF interpretation, or a second PNG parser. [VERIFIED: codebase: `AGENTS.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

### the agent's Discretion

- Choose exact public push/result type names, the sticky-terminal representation, and the public-vs-private test split. The recommendation below selects the smallest QOI-shaped API that makes the PNG error contract explicit. [ASSUMED]

### Deferred Ideas (OUT OF SCOPE)

- Phase 28 owns the broad hostile-schedule corpus and public workflow/example evidence; Phase 27 supplies the API contract and focused public regressions. [VERIFIED: codebase: `.planning/ROADMAP.md`]
- APNG, HDR/cICP, text/EXIF, full ICC transforms, public streaming encode, FFI codecs, and publication automation remain out of scope. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `AGENTS.md`]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PNGS-01 | A caller submits arbitrary caller-owned PNG chunks, receives deterministic non-terminal progress, and sees no image before strict completion. | The QOI-shaped `push(ByteView)` result reports this-call consumption; Phase 26 already accepts one owned byte at every PNG continuation boundary and withholds its private outcome. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/qoi/{qoi,stream_decode}.mbt`, `modules/mb-image/png/stream_decode.mbt`] |
| PNGS-02 | `finish()` produces one eager-equivalent image or a typed sticky terminal error for all incomplete, malformed, trailing, limit, and budget paths. | A public terminal wrapper must retain the first machine error, classify active incomplete states, move the owned outcome exactly once, and reject subsequent input with zero consumption. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `modules/mb-image/png/stream_decode.mbt`] |

## Summary

Phase 26 provides the hard part: a single private `PngDecodeMachine` that consumes owned `Byte` values, holds no `ByteView`, pauses across framing/DEFLATE/raster work, and creates `PngMachineOutcome` only after IDAT CRC, Adler, IEND CRC, and EOF all pass. Its eager `PngDecoder` already delegates to that machine and current PNG tests pass 68/68 on wasm, wasm-gc, js, and native. [VERIFIED: codebase: `modules/mb-image/png/{png,stream_decode}.mbt`, `.planning/phases/26-pausable-png-decode-substrate/26-01-VERIFICATION.md`; command: `moon -C modules/mb-image test png --target all --frozen`]

**Primary recommendation:** Add a thin public `PngChunkDecoder` in the existing PNG package, shaped like QOI's stream decoder but with a PNG-specific sticky-error wrapper. Keep all parsing, image allocation, byte accounting, and terminal integrity work in `PngDecodeMachine`; add no source package, parser, or buffer.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Caller chunk ownership and per-call progress | Library public API | Private PNG machine | The public adapter enumerates a transient `ByteView`; the machine owns only individual accepted bytes and continuation state. [VERIFIED: codebase: `modules/mb-image/qoi/stream_decode.mbt`, `modules/mb-image/png/stream_decode.mbt`] |
| PNG framing, CRC, IDAT, DEFLATE, raster, and completion | Private PNG machine | — | The verified Phase 26 machine already owns these transitions and its eager facade uses the same route. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `.planning/phases/26-pausable-png-decode-substrate/26-01-VERIFICATION.md`] |
| Owned image/result transfer | Private machine then public API | Storage | The private outcome contains the sole `OwnedImage`; `finish()` transfers it once into `DecodeResult`. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `modules/mb-image/codec/contracts.mbt`] |
| Public API policy and portable evidence | PNG package policy/tests | Quality lane | The package interface is exact-allowlisted and all four targets are already required by the PNG quality gate. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/{Assert-Policy,Invoke-MoonQuality}.ps1`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Existing `tchivs/mb-image/png` package | repository-local | Public `PngChunkDecoder` facade over `PngDecodeMachine` | The private machine already covers every required PNG continuation and is the eager decoder's implementation path. [VERIFIED: codebase: `modules/mb-image/png/{png,stream_decode}.mbt`] |
| Existing `tchivs/mb-core/bytes` | repository-local | Ephemeral caller `ByteView` input | The QOI stream precedent accepts this type and its `get` operation makes per-byte consumption explicit. [VERIFIED: codebase: `modules/mb-image/qoi/stream_decode.mbt`, `policy/foundation.json`] |
| Existing `tchivs/mb-image/codec` | repository-local | `CodecLimits` and the single-transfer `DecodeResult` | These are the current codec limits/result contracts and maintain package consistency. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`, `modules/mb-image/png/stream_decode.mbt`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing `tchivs/mb-core/budget` | repository-local | Resource budget passed unchanged to the private machine | Construct the public decoder with the caller's budget; do not add a buffering budget. [VERIFIED: codebase: `modules/mb-image/qoi/qoi.mbt`, `modules/mb-image/png/stream_decode.mbt`] |
| Existing `tchivs/mb-core/error` | repository-local | Typed terminal errors | Preserve the first terminal `CoreError` so its category, code, context, requested/completed, and limit fields stay observable. [VERIFIED: codebase: `modules/mb-core/error/core_error.mbt`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Thin facade over `PngDecodeMachine` | Buffer all chunks and invoke `PngDecoder` at `finish()` | Rejected: this would retain the full caller input and would not expose real progress through DEFLATE/raster boundaries. [VERIFIED: codebase: `.planning/phases/26-pausable-png-decode-substrate/26-01-VERIFICATION.md`] |
| `PngChunk*` QOI-shaped public types | Generic cross-codec stream trait | Rejected: no such public trait exists; it would expand surface area and policy work beyond the one decoder requested. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`, `modules/mb-image/qoi/pkg.generated.mbti`] |
| Sticky original failure | Replace every later operation with generic terminal state error | Rejected: roadmap explicitly requires typed sticky terminal errors; retaining the original preserves CRC/resource/truncation diagnostics. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-core/error/core_error.mbt`] |

**Installation:** None. Phase 27 installs no external package and adds no runtime/service dependency. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `policy/foundation.json`]

## Package Legitimacy Audit

Not applicable: no package is installed or recommended.

## Architecture Patterns

### System Architecture Diagram

```text
caller-owned ByteView chunks
          |
          v
 PngChunkDecoder::push
          |  enumerate bytes transiently; report consumed
          v
 private PngDecodeMachine::accept(Byte)
  signature -> chunks/CRC -> IDAT -> DEFLATE -> raster -> IEND
          |                                                |
          | failure                                        | needs explicit EOF
          v                                                v
 StickyError(CoreError)                         PngChunkDecoder::finish
          |                                                |
          +---------------- zero-consumption ------------+---> DecodeResult once
                                                           |
                                                           +---> StickyError(CoreError)
```

### Recommended Public API

Use the QOI naming and result pattern, but call the PNG type `Chunk` because the roadmap has already locked `PngChunkDecoder`. The constructor intentionally takes the same three operational dependencies as QOI: the chunk contract always requires complete input at `finish()`, and the current supported public PNG path uses non-preserved opaque metadata. Do **not** add an options parameter that suggests `require_complete_input=false` can weaken the mandatory finish/EOF validation. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/qoi/qoi.mbt`, `modules/mb-image/codec/contracts.mbt`]

```moonbit
pub struct PngChunkDecoder {
  // private: limits, budget, diagnostics, private PngDecodeMachine,
  // and public terminal state; no ByteView field
}

pub(all) enum PngChunkPushOutcome {
  NeedInput
  Failed(@error.CoreError)
}

pub struct PngChunkPushResult {
  // private: consumed_value, outcome_value
}

pub fn PngChunkPushResult::consumed(Self) -> UInt64
pub fn PngChunkPushResult::outcome(Self) -> PngChunkPushOutcome
pub fn PngChunkDecoder::new(
  @codec.CodecLimits,
  @budget.Budget,
  @error.Diagnostics,
) -> Self
pub fn PngChunkDecoder::push(Self, @bytes.ByteView) -> PngChunkPushResult
pub fn PngChunkDecoder::finish(Self) -> Result[@codec.DecodeResult, @error.CoreError]
```

This is deliberately not an `ImageDecoder` implementation: its input is caller chunks and its EOF signal is `finish()`, while `PngDecoder` remains the Reader-based `ImageDecoder`. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`, `modules/mb-image/png/png.mbt`, `.planning/ROADMAP.md`]

### Push and Ownership Contract

1. An active `push(empty_view)` returns `{ consumed: 0, outcome: NeedInput }` and changes no machine/budget state. [ASSUMED]
2. For an active non-empty view, read one byte, invoke `PngDecodeMachine::accept`, then proceed only while it succeeds. The public wrapper retains no `ByteView`, subview, lease, or complete input buffer after `push` returns. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `modules/mb-image/qoi/stream_decode.mbt`]
3. `consumed` means bytes taken from the supplied view for this call. A malformed byte that is passed into the machine and triggers CRC/DEFLATE/raster failure is counted; a byte refused before dispatch because `max_input_bytes` is already reached is not counted. This is QOI's established consumption convention and removes ambiguity at terminal boundaries. [VERIFIED: codebase: `modules/mb-image/qoi/stream_decode.mbt`, `modules/mb-image/qoi/stream_decode_test.mbt`; [ASSUMED] public PNG application]
4. Return `NeedInput` after every successful active push, including after an IEND CRC, because only `finish()` declares EOF and may transfer a result. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/stream_decode.mbt`]
5. On the first terminal error, store exactly that error in the public wrapper and return it in `Failed`; stop iterating the supplied view immediately. [ASSUMED]

### Finish, Result, and Sticky Terminal Contract

Use a public wrapper state such as `Active(PngDecodeMachine) | Failed(CoreError) | Finished`. It is separate from the private PNG framing enum only to enforce public one-result ownership. [ASSUMED]

| State when `finish()` is called | Required result | Later `push` / `finish` |
|---|---|---|
| `Active` at private `NeedEof` | Invoke the private terminal transition; on success move its single private outcome to `DecodeResult`, mark `Finished`. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`] | `push` consumes 0 and reports a typed state-terminal error; a second `finish` returns that state-terminal error. [ASSUMED] |
| `Active` before complete framing/IEND/raster | Convert the active continuation into a `Data/UnexpectedEndOfStream` error with the continuation's stable context, store it, and return it. [ASSUMED] | Both operations expose the same stored terminal error; `push` consumes 0. [ASSUMED] |
| `Failed(error)` | Return the original stored `error`, without replacing its structured fields. [ASSUMED] | Same original error, zero consumption. [ASSUMED] |
| `Finished` | Never manufacture or expose a second image. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`] | Typed state-terminal error, zero consumption. [ASSUMED] |

The planner must add a private helper that classifies *only* active incomplete states. Do not call Phase 26's internal `finish()` for an arbitrary state and leak its generic `png-finished` fallback: that is not a useful public incomplete-stream diagnosis. Preserve first-error precedence over a later `finish()` call. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `.planning/ROADMAP.md`]

Recommended incomplete contexts to freeze with tests are `png-signature`, `png-chunk-length`, `png-chunk-type`, `png-chunk-payload`, `png-chunk-crc`, `png-idat-crc`, `zlib-truncated`, and `png-iend-crc`; choose the exact state-to-context table while implementing the helper and use it for all four targets. The key invariant is that an active IDAT whose inflater has not completed reports `zlib-truncated` before a generic framing suffix, matching the existing private precedence around separated IDAT/IEND transitions. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`; [ASSUMED] stable public incomplete-context names]

### Error Precedence

1. A failure from `accept` wins immediately and becomes sticky: signature/chunk/order/CRC, IDAT/zlib/DEFLATE/raster, opaque-metadata capability, input limit, or allocation/budget failure. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`]
2. A complete IEND followed by another pushed byte fails as `png-trailing-data` before `finish()`; it remains sticky. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`]
3. `finish()` supplies incomplete-input classification only if no earlier failure exists; it must not overwrite a prior `png-crc`, resource, or inflater error. [ASSUMED]
4. `finish()` at `NeedEof` checks inflater completion and raster completion before publishing the private image; no result exists on Adler/raster failure. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`]
5. Successful `finish()` consumes/transfers the outcome once. A later operation is a state error, not an image replay. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`; [ASSUMED] wrapper behavior]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # public PngChunk* declarations and constructor
├── stream_decode.mbt       # public adapter methods plus existing private machine
├── stream_decode_test.mbt  # public API: chunks, results, finish, eager parity
├── stream_decode_wbtest.mbt # precise active-state/incomplete precedence evidence
└── pkg.generated.mbti      # regenerated; policy is updated to exact interface
```

### Anti-Patterns to Avoid

- **Buffer-then-decode facade:** violates the private-machine design and erases meaningful chunk progress.
- **Store `ByteView` or a lease in public/private state:** lets caller mutation change future decode behavior and conflicts with QOI/Phase 26 ownership rules.
- **Return an image from `push`:** violates strict explicit EOF, allows output before trailing-data validation, and makes result ownership ambiguous.
- **Turn all terminal paths into `png-chunk-terminal`:** loses typed failure evidence required by PNGS-02; reserve the generic state error for operations after a completed successful transfer.
- **Modify QOI API or its inventories:** this is a PNG-only public surface change.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PNG chunk parsing/DEFLATE/raster continuation | A public parallel parser | Existing private `PngDecodeMachine` | It is the verified eager path and already pauses at every byte boundary. [VERIFIED: codebase: `modules/mb-image/png/{png,stream_decode}.mbt`, `.planning/phases/26-pausable-png-decode-substrate/26-01-VERIFICATION.md`] |
| Input retention | Chunk accumulator or copied full stream | Per-byte dispatch into existing machine | The machine's fields contain no `ByteView` and no IDAT payload retention. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`] |
| Result container | A PNG-specific image/result type | Existing `@codec.DecodeResult` | It already holds `OwnedImage`, disposition, and exact bytes read. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`] |
| Public progress convention | New bool/callback protocol | QOI-style `PushOutcome` + `PushResult` | This is the repository's established caller-buffer streaming vocabulary. [VERIFIED: codebase: `modules/mb-image/qoi/{qoi,stream_decode}.mbt`] |
| Interface validation | Ad-hoc declaration scan | Existing exact `semantic_interface` policy and generated MBTI | Quality scripts already regenerate and compare the complete public contract. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/{Assert-Policy,Invoke-MoonQuality}.ps1`] |

## Common Pitfalls

### Pitfall 1: Wrong per-call consumption on terminal bytes

**What goes wrong:** The adapter reports zero for a byte that actually reached the parser, or continues consuming the rest of a chunk after the first terminal error.

**Why it happens:** `PngDecodeMachine::accepted` advances only after a successful transition, while public caller consumption must distinguish parser-dispatched malformed bytes from a byte rejected at the input limit. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `modules/mb-image/qoi/stream_decode.mbt`]

**How to avoid:** Keep a public `consumed_total`/this-call counter at the dispatch boundary, preflight the input ceiling before reading the next source byte, and stop at the first machine error. Test CRC-failing and input-limit chunks separately. [ASSUMED]

### Pitfall 2: EOF validation accidentally happens at IEND

**What goes wrong:** `push` returns a result as soon as IEND CRC arrives, missing a trailing byte supplied later.

**How to avoid:** Keep IEND at `NeedInput`; only `finish()` changes the machine from `NeedEof` to its one private outcome. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `.planning/ROADMAP.md`]

### Pitfall 3: Generic terminal errors hide useful diagnostics

**What goes wrong:** A CRC, budget, or truncated-DEFLATE error becomes an `InvalidRange` state error on the next caller operation.

**How to avoid:** Store the first `CoreError` in public state and replay it for all failure-terminal operations. Use a distinct state-terminal error only after a successful result has been moved. [ASSUMED]

### Pitfall 4: Public options weaken strict completion

**What goes wrong:** Reusing `DecodeOptions.require_complete_input=false` suggests callers may obtain a chunk result without `finish()`.

**How to avoid:** Do not add this option to the Phase 27 constructor. The new API is intrinsically complete-input-only; existing configurable Reader decoding remains `PngDecoder`. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`, `.planning/ROADMAP.md`]

### Pitfall 5: Policy change is incomplete

**What goes wrong:** Source tests pass but the generated interface or negative policy fixtures still forbid `PngChunkDecoder`.

**How to avoid:** Update `policy/foundation.json`, `Assert-PngFoundationPolicy`, and PNG negative fixtures in the same commit as public declarations; retain four targets and all existing imports/files/source ordering. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`]

## Code Examples

### Public caller flow

```moonbit
let decoder = @png.PngChunkDecoder::new(
  limits, budget, @error.Diagnostics::new(),
)
let progress = decoder.push(first_chunk)
if progress.outcome() is @png.PngChunkPushOutcome::NeedInput {
  ignore(decoder.push(last_chunk))
}
let decoded = decoder.finish().unwrap()
```

The outcome remains `NeedInput` even when `last_chunk` contains a complete IEND; `finish()` is deliberately the only EOF declaration and result-transfer point. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/qoi/stream_decode.mbt`; [ASSUMED] PNG type names]

### Correct adapter loop sketch

```moonbit
// Pseudocode for the public wrapper; the machine remains the only parser.
for index = 0UL; index < source.length(); index = index + 1UL {
  if total == limits.max_input_bytes() { return fail_without_consuming_limit_byte() }
  let byte = source.get(index).unwrap()
  total = total + 1UL
  consumed = consumed + 1UL
  match machine.accept(byte) {
    Ok(_) => ()
    Err(error) => { terminal = Failed(error); return failed(consumed, error) }
  }
}
need_input(consumed)
```

This deliberately follows QOI's source enumeration/returned-result shape while routing every byte to the Phase 26 machine. [VERIFIED: codebase: `modules/mb-image/qoi/stream_decode.mbt`, `modules/mb-image/png/stream_decode.mbt`; [ASSUMED] exact public wrapper code]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Public PNG is only `PngDecoder` over `Reader`; no caller chunk surface exists. [VERIFIED: codebase: `modules/mb-image/png/pkg.generated.mbti`] | Phase 26 now provides a private byte-fed state machine beneath that same eager facade. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`] | Phase 27 can expose chunks without changing PNG parsing behavior. [ASSUMED] |
| QOI public streaming returns `NeedInput`/`Failed` plus a consumed count, then moves an owned `DecodeResult` at `finish()`. [VERIFIED: codebase: `modules/mb-image/qoi/{qoi,stream_decode}.mbt`] | PNG adopts the same user-facing shape with its own exact interface policy. [ASSUMED] | Consumers learn one streaming idiom across codecs while PNG preserves its stronger integrity gate. [ASSUMED] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | QOI-shaped `PngChunkPushOutcome`/`PngChunkPushResult` names are the best stable public PNG vocabulary. | Recommended Public API | Interface policy and future consumers would need a rename. |
| A2 | A public wrapper can retain/replay the first `CoreError` without impacting MoonBit ownership or target portability. | Finish / Sticky Terminal Contract | Terminal error behavior could require a different representation. |
| A3 | The listed incomplete contexts are the most useful stable public table. | Finish / Error Precedence | Tests might need to freeze a narrower context table that better matches existing eager errors. |
| A4 | Omit `DecodeOptions` from the new constructor because `finish()` is intrinsically strict and current opaque-metadata preservation is unsupported. | Recommended Public API | A later requirement may need an explicit options-bearing constructor. |

## Open Questions

1. **Exact incomplete-state context table**
   - What we know: Phase 26 can identify each active framing/IDAT/inflater state, and the roadmap requires typed terminal errors. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `.planning/ROADMAP.md`]
   - What's unclear: The pre-Phase-27 public interface has no established names for every truncated suffix.
   - Recommendation: Add one private classifier, write focused tests first, and freeze the selected contexts in the public policy/test suite; never return the generic `png-finished` fallback for active incomplete input. [ASSUMED]

2. **Exposure of opaque-metadata policy**
   - What we know: existing `DecodeOptions` has `preserve_opaque_metadata`, while PNG currently reports capability-unavailable for unknown ancillary preservation. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`, `modules/mb-image/png/stream_decode.mbt`]
   - Recommendation: Keep Phase 27's constructor strict/default-only; do not expand the public API for a currently unsupported behavior. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | compile/test all targets | yes | `0.1.20260713` | — |
| `moonc` | compiler transitively used by MoonBit | yes | `v0.10.4+2cc641edf` | — |
| `moonrun` | MoonBit execution | yes | `0.1.20260713` | — |
| PowerShell | existing policy and quality commands | yes | repository commands execute under `pwsh` | — |

No missing external dependency blocks Phase 27. [VERIFIED: command output: `moon --version`, `moonc -v`, `moonrun --version`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | MoonBit package tests, black-box `*_test.mbt` and white-box `*_wbtest.mbt` [VERIFIED: codebase: `modules/mb-image/png`] |
| Config file | `modules/mb-image/png/moon.pkg` [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`] |
| Quick run command | `moon -C modules/mb-image test png --target native --frozen` |
| Full suite command | `moon -C modules/mb-image test png --target all --frozen` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PNGS-01 | Empty, one-byte, boundary-split, and mixed-size public `ByteView` pushes give exact per-call consumption/`NeedInput`, retain no caller bytes, and publish no result. | black-box API plus focused white-box ownership | `moon -C modules/mb-image test png --target all --frozen` | Existing stream files; add Phase 27 cases |
| PNGS-02 | Explicit finish returns exactly one result only after IEND/EOF or a sticky typed failure for truncated/malformed/trailing/limit/budget cases. | black-box API plus white-box state classifier | `moon -C modules/mb-image test png --target all --frozen` | Existing stream files; add Phase 27 cases |
| PNGS-01/02 | Public interface, imports, files, source order, and four targets remain exact. | policy/qualification | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Existing policy/quality lanes; update expected interface |

### Sampling Rate

- **Per task commit:** `moon -C modules/mb-image test png --target native --frozen`
- **Per wave merge:** `moon -C modules/mb-image test png --target all --frozen`
- **Phase gate:** `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check`; `moon -C modules/mb-image test png --target all --frozen`; `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png`

### Wave 0 Gaps

- [ ] Add public `PngChunkDecoder` tests to `stream_decode_test.mbt`: empty chunk, every basic chunk partition, exact consumption, caller mutation after return, IEND-before-finish, success transfer once, trailing byte, sticky malformed/limit/budget failures, and eager-result equality.
- [ ] Add `stream_decode_wbtest.mbt` cases for the incomplete-state classifier and first-error precedence that cannot be selected reliably through broad generated input alone.
- [ ] Update `policy/foundation.json` and `Assert-PngFoundationPolicy` expected semantic interface/negative fixtures in the same plan task as declarations.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Codec has no identity or authentication path. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`] |
| V3 Session Management | no | Codec has no session state beyond one caller-owned decoder instance. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`] |
| V4 Access Control | no | No authorization boundary exists. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`] |
| V5 Input Validation | yes | Per-byte machine transitions retain chunk ordering/CRC, zlib, raster, limits, and finish validation. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`] |
| V6 Cryptography | no | CRC and Adler are format-integrity checks, not cryptographic controls. [CITED: https://www.w3.org/TR/png-3/] [CITED: https://www.rfc-editor.org/rfc/rfc1950.html] |
| V8 Data Protection | yes | Keep the allocated image/private outcome hidden until terminal validation and avoid retaining caller input views. [VERIFIED: codebase: `.planning/phases/26-pausable-png-decode-substrate/26-01-VERIFICATION.md`] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Caller mutates/reuses a source buffer after `push` | Tampering | Read individual bytes during the call and retain no `ByteView`; test mutation after a partial token/chunk. [VERIFIED: codebase: `modules/mb-image/qoi/stream_decode_test.mbt`, `modules/mb-image/png/stream_decode.mbt`] |
| Oversized input or allocation exhausts resources | Denial of service | Preflight `max_input_bytes`, retain existing machine limits/budget, stop at first failure, and return typed resource error. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `modules/mb-image/qoi/stream_decode.mbt`] |
| Image is visible before final integrity | Information disclosure/tampering | Never return a result from `push`; only transfer the private outcome after `finish()` validates EOF. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt`, `.planning/ROADMAP.md`] |
| Error replacement hides hostile-input diagnosis | Tampering | Persist first terminal `CoreError`; do not substitute generic terminal state until a successful result was already moved. [ASSUMED] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared models remain MoonBit-owned; native is primary but js, wasm, wasm-gc, and native all require conformance evidence. [VERIFIED: codebase: `AGENTS.md`, `modules/mb-image/png/moon.pkg`]
- FFI must remain absent from this pure portable decoder path. [VERIFIED: codebase: `AGENTS.md`, `.planning/ROADMAP.md`]
- Keep public package dependencies acyclic and use the existing allowed import set; do not import the whole ecosystem for one primitive. [VERIFIED: codebase: `AGENTS.md`, `policy/foundation.json`]
- Preserve candidate public API stability through explicit semantic-interface policy updates and deterministic CLI-testable behavior. [VERIFIED: codebase: `AGENTS.md`, `scripts/quality/Assert-Policy.ps1`]
- Public operations must be deterministic and usable without GUI state. [VERIFIED: codebase: `AGENTS.md`]
- Public package tests use black-box `*_test.mbt`; internal transition invariants use `*_wbtest.mbt`; binary evidence uses semantic assertions rather than opaque snapshots. [VERIFIED: codebase: `AGENTS.md`, `modules/mb-image/png/*_test.mbt`]
- Repository code discovery normally prefers codebase-memory MCP, but it is unavailable in this agent runtime; this research used repository text inspection as the documented fallback. [VERIFIED: environment/tool availability and `AGENTS.md`]

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/stream_decode.mbt` - private byte machine, EOF outcome gate, existing failure precedence, and eager bridge.
- `modules/mb-image/qoi/{qoi,stream_decode,stream_decode_test}.mbt` - public streaming type, push/result, ownership, consumption, and explicit-finish precedent.
- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` - locked API name, completion behavior, requirements PNGS-01/02, and Phase 28 boundary.
- `.planning/phases/26-pausable-png-decode-substrate/{26-01-SUMMARY,26-01-VERIFICATION}.md` - verified substrate scope and portable baseline.
- `policy/foundation.json` and `scripts/quality/{Assert-Policy,Invoke-MoonQuality}.ps1` - exact public interface/policy gate.

### Secondary (MEDIUM confidence)

- [PNG Third Edition](https://www.w3.org/TR/png-3/) - PNG IEND/CRC/datastream completion semantics, already cited and applied by Phase 26.
- [RFC 1950](https://www.rfc-editor.org/rfc/rfc1950.html) - zlib trailer semantics, already cited and applied by Phase 26.

### Tertiary (LOW confidence)

- No external documentation was fetched: Context7 planning selected a lookup but the local `ctx7` fallback is unavailable and no unverified package was installed. API recommendations marked `[ASSUMED]` are derived from verified repository patterns and need implementation tests to become locked behavior.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - no package change; exact package dependencies and Phase 26 private path are present.
- Architecture: HIGH - QOI public precedent and Phase 26 machine ownership are directly inspected; public sticky-wrapper details are explicitly marked as assumptions until implemented.
- Pitfalls: HIGH - consumption/terminal/policy hazards follow directly from current QOI and PNG code.

**Research date:** 2026-07-21
**Valid until:** Phase 27 implementation begins; refresh if the private machine or QOI streaming public contract changes first.
