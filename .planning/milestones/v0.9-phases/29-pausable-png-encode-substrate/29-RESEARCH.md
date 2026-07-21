# Phase 29: Pausable PNG Encode Substrate - Research

**Researched:** 2026-07-21  
**Domain:** Private portable resumable canonical PNG output  
**Confidence:** HIGH

## User Constraints

No `CONTEXT.md` exists for this phase. The approved roadmap, requirements, project state, and assignment are the controlling scope. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`]

### Locked Decisions

- Phase 29 is private substrate work: admit only compatible RGB8 and straight-RGBA8 images after eager-equivalent preflight, but publish no `PngChunkEncoder` until Phase 30. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- Preserve the existing byte-stable PNG representation: signature, IHDR, one IDAT containing zlib stored-DEFLATE filter-None scanlines, and IEND. Compression optimization is deferred. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `.planning/REQUIREMENTS.md`]
- Preflight capability, dimensions, limits, and the resource budget before any encoded byte is observable; constructor rejection uses the existing typed errors. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/encode_test.mbt`]
- Keep the implementation pure MoonBit and portable on js, wasm, wasm-gc, and native; do not add FFI, external packages, release work, or a compression-ratio feature. [VERIFIED: codebase: `AGENTS.md`, `.planning/REQUIREMENTS.md`, `modules/mb-image/png/moon.pkg`]

### the agent's Discretion

- Choose the private machine/type names, state decomposition, eager-facade adapter, and private pre-publication tests, provided both output bytes and preflight errors remain eager-equivalent. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/STATE.md`]

### Deferred Ideas (OUT OF SCOPE)

- The public `PngChunkEncoder`, caller-buffer pull result/progress API, arbitrary-capacity evidence, and public workflow belong to Phases 30-31. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- FFI/zlib bindings, host I/O adapters, APNG, metadata/colour expansion, and alternative compression strategies are excluded. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PNGE-01 | A compatible RGB8/straight-RGBA8 image creates a public encoder only after capability, dimension, limit, and budget rejection has occurred before output exposure. | Make private `PngEncodeMachine::new` the one authoritative preflight path now; it computes the exact canonical output length, constructs disposition before charging budget, and returns no machine on any failure. Phase 30 can wrap this constructor without repeating or weakening it. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/qoi/stream_encode.mbt`]

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be MoonBit; native remains primary but all four portable targets require deliberate conformance. [VERIFIED: codebase: `AGENTS.md`]
- FFI must remain narrow and replaceable; this phase must add none. Public package dependencies must remain acyclic and explicit. [VERIFIED: codebase: `AGENTS.md`]
- Public operations must be deterministic and GUI-independent; unsupported public surface and release automation are out of scope here. [VERIFIED: codebase: `AGENTS.md`]
- Code discovery should prefer the project knowledge-graph MCP; it was not exposed in this agent runtime, so code discovery fell back to targeted `rg` queries. [VERIFIED: runtime tool availability; `AGENTS.md`]
- Any implementation edit must remain inside the GSD execution workflow. [VERIFIED: codebase: `AGENTS.md`]

## Summary

The existing eager encoder already fixes the canonical representation, but it builds complete scanline, zlib, and PNG byte buffers before it invokes `Writer`. Its source checks, output-length limit order, work charge, deterministic RGB/RGBA format choice, CRC-32, and Adler-32 logic are the correct reusable semantics; only ownership and control flow need extraction. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/encode_test.mbt`, `modules/mb-image/png/encode_wbtest.mbt`]

Implement one private `PngEncodeMachine` that retains the immutable `ImageView`, scalar geometry, filtered-scanline cursor, stored-block cursor, rolling IDAT CRC, Adler value, a bounded pending fragment and offset, total length, and terminal state. It must not retain a mutable output lease or materialize the full PNG/IDAT/scanline stream. PNG permits this emission model: chunks are length/type/data/CRC, CRC covers type plus data, and one IDAT payload is a zlib datastream of filtered scanlines. [CITED: https://www.w3.org/TR/png-3/] [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/structural.mbt`]

**Primary recommendation:** Extract shared exact-length/preflight logic and a private byte-producing `PngEncodeMachine` in `encode.mbt` plus new `stream_encode.mbt`; route the unchanged eager `PngEncoder` through that machine with only bounded private staging, but keep all public encoder declarations for Phase 30. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Source capability and resource preflight | API / Backend | Storage | The codec owns typed admission and budget semantics while `ImageView` supplies descriptor/metadata/pixels. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/storage`]
| Canonical PNG/zlib/CRC emission | API / Backend | — | The portable PNG package already owns stored-DEFLATE, Adler-32, and PNG CRC logic. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/deflate_inflate.mbt`, `modules/mb-image/png/structural.mbt`]
| Caller destination mutation (Phase 30) | API / Backend | Browser / Client | The public codec will synchronously write a supplied `MutByteLease`; the private Phase-29 machine must retain none. [VERIFIED: codebase: `modules/mb-image/qoi/stream_encode.mbt`, `.planning/ROADMAP.md`]

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing `tchivs/mb-image/png` | repository current | Pure MoonBit canonical PNG encoder and private stream substrate | It already implements the frozen output and imports only permitted portable dependencies. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `modules/mb-image/png/encode.mbt`]
| Existing `mb-core` bytes, checked arithmetic, error, and budget contracts | repository current | Owned output leases, checked length arithmetic, typed failures, one resource charge | These are the package's declared dependencies and four-target foundation contracts. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `policy/foundation.json`]

### Supporting

| Component | Purpose | When to Use |
|---|---|---|
| Existing QOI stream encoder pattern | Constructor preflight, stable-source ownership, bounded pending state, and sticky pull precedent | Copy its ownership/test shape, not its variable-length opcode algorithm. [VERIFIED: codebase: `modules/mb-image/qoi/qoi.mbt`, `modules/mb-image/qoi/encode.mbt`, `modules/mb-image/qoi/stream_encode.mbt`]
| Existing PNG encoder tests | Canonical one-pixel RGB/RGBA bytes, CRC/Adler checks, eager no-output-on-preflight rejection | Extend as the Phase-29 oracle instead of inventing a second PNG fixture format. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt`, `modules/mb-image/png/encode_wbtest.mbt`]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Stateful generated output | Build one complete `Bytes` PNG then copy it later | Rejected: it preserves byte parity but defeats incremental output and creates full-output staging. [ASSUMED]
| One shared private machine | Preserve eager assembly and build a separate stream assembler | Rejected: two output paths can drift in lengths, checksums, error order, and canonical bytes. [ASSUMED]
| Retained immutable source view | Snapshot source pixels at construction | Rejected: it adds an allocation/ownership path not present in the QOI precedent or Phase-29 scope. [VERIFIED: codebase: `modules/mb-image/qoi/qoi.mbt`, `modules/mb-image/qoi/stream_encode.mbt`]

**Installation:** None; no external package is installed or recommended. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `.planning/REQUIREMENTS.md`]

## Architecture Patterns

### System Architecture Diagram

```text
immutable ImageView + limits + budget
                |
                v
        PngEncodeMachine::new
 source/capability -> checked geometry -> exact output length
            |              |                    |
            |              v                    v
            |        ordered limit checks -> disposition -> one budget charge
            |                                         |
            | failure                                 | success
            v                                         v
      typed Result, no machine                private output state
                                                  |
       unchanged PngEncoder Writer driver <-------+-------> Phase-30 public pull wrapper
                                                  |
                         signature -> IHDR -> IDAT header/type
                                                  |
                  zlib header -> stored block headers -> filter-None pixel bytes
                                                  |
                            Adler-32 -> IDAT CRC -> IEND -> terminal
```

### Exact Preflight and Length Formula

Run `_png_encode_source`, checked pixel count, checked `row_bytes = width * channels`, and checked `scanline_bytes = (row_bytes + 1) * height` before source pixels are read or output exists. For nonempty scanlines, calculate `blocks = ceil(scanline_bytes / 65535)`, `idat_bytes = scanline_bytes + 6 + 5 * blocks`, and `total_bytes = idat_bytes + 57`; the current 1×1 RGB oracle has `scanline_bytes=4`, `idat_bytes=15`, and `total_bytes=72`. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/encode_test.mbt`]

Apply existing limit contexts in their current order—`output-bytes`, `width`, `height`, `pixels`, then `work`—and charge the existing work-only `ResourceCharge` exactly once. Construct `_png_empty_disposition()` before that charge so a later constructor failure cannot leave a charged budget without an encoder. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/qoi/encode.mbt`, `.planning/milestones/v0.5-phases/18-resumable-qoi-buffer-encode/18-01-SUMMARY.md`]

### State Ownership and Pause Contract

| Owner | Persistent state | Must not retain |
|---|---|---|
| `PngEncodeMachine` | Immutable source view, channels, dimensions, row/scanline/block positions, exact total/emitted counts, IDAT CRC, Adler-32, state, bounded pending fragment/offset, and disposition. [ASSUMED] | `MutByteLease`, caller output buffer/view, a complete PNG, complete IDAT, or complete scanlines. [ASSUMED] |
| Pending-fragment emitter | At most a fixed protocol fragment (signature, integer field, type, CRC, zlib/stored header, or Adler) and offset; source pixels are emitted one at a time. [ASSUMED] | A 65,535-byte stored block payload. [ASSUMED] |
| Eager Writer adapter | A transient bounded owned byte fragment passed to `@io.write_all`; it maps Writer failure to existing `png-encode` requested/completed shape. [ASSUMED] | The Writer, its buffer, or a whole encoded PNG after a write returns. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`]
| Future public wrapper | Only lifecycle/progress state around the machine; Phase 30 supplies the caller lease per pull. [ASSUMED] | Any lease after `pull` returns. [VERIFIED: codebase: `modules/mb-image/qoi/stream_encode.mbt`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                    # no new public encoder declaration in Phase 29
├── encode.mbt                 # extract shared source/length/limit/budget preflight; eager driver
├── stream_encode.mbt          # NEW private canonical PngEncodeMachine and output states
├── encode_test.mbt            # eager regression and atomic preflight parity
├── encode_wbtest.mbt          # framing/checksum/length formula assertions
├── stream_encode_wbtest.mbt   # NEW private pause, ownership, and byte-generation tests
└── moon.pkg                   # unchanged imports and four-target declaration
```

`policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, and `scripts/quality/Invoke-MoonQuality.ps1` must add the private source/test inventory in the same exact-order style used for `stream_decode.mbt`; compiler-generated public interface output should be regenerated and remain unchanged because Phase 29 adds no public types. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Invoke-MoonQuality.ps1`]

### Pattern 1: Incremental Canonical Emitter

**What:** Generate each canonical protocol byte from owned scalar state; increment `emitted_total` only after that byte is successfully copied to the current transient destination. [ASSUMED]

**When to use:** Always for Phase 29's private machine and for both its eager driver and Phase 30 wrapper. [ASSUMED]

**Example:**

```moonbit
// Source pattern: modules/mb-image/qoi/stream_encode.mbt
priv fn PngEncodeMachine::next_byte(self : PngEncodeMachine) -> Result[Byte?, @error.CoreError] {
  // Advance signature/IHDR/IDAT/zlib/stored scanline/Adler/CRC/IEND state.
  // Return one canonical byte; do not advance total_copied until the sink accepts it.
}
```

### Pattern 2: Shared Preflight Before Any Sink Exists

**What:** `PngEncodeMachine::new` performs all validation, exact length calculation, limit checks, disposition creation, and budget charge, then returns the machine. [ASSUMED]

**When to use:** `PngEncoder::encode` calls it before touching `Writer`; Phase 30 calls the exact same constructor before it obtains a caller output lease. [ASSUMED]

### Anti-Patterns to Avoid

- **Whole-PNG staging:** Do not preserve `_png_encode_png` as the stream source and later slice it; it makes construction depend on an output-sized buffer. [ASSUMED]
- **Advance-on-generation:** Do not advance source/CRC/Adler/cumulative output once a pending fragment is generated; advance only the fragment offset after a byte has been copied. [ASSUMED]
- **Budget charge before all fallible construction:** Do not construct metadata disposition or machine fields after charging, because QOI streaming previously fixed that atomicity hole. [VERIFIED: codebase: `.planning/milestones/v0.5-phases/18-resumable-qoi-buffer-encode/18-01-SUMMARY.md`]
- **Public API leakage:** Do not add `PngChunkEncoder`, pull result/outcome types, or a generic cross-codec stream trait in this phase. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| PNG CRC-32 | A second CRC table or hash | `_png_crc_for_type` and `_png_crc_step` | Existing encoder and decoder already share these checked PNG semantics. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`, `modules/mb-image/png/encode.mbt`]
| Adler-32 | A separate checksum implementation | `_png_adler_step` | Existing zlib encode/decode paths use it. [VERIFIED: codebase: `modules/mb-image/png/deflate_inflate.mbt`, `modules/mb-image/png/encode.mbt`]
| Capability/limit/budget errors | New stream-specific error strings | `_png_encode_source`, `_png_encode_limit`, `_png_encode_error`, and the existing `ResourceCharge` shape | PNGE-01 requires eager-equivalent typed rejection. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `.planning/REQUIREMENTS.md`]
| Caller-lease lifecycle | An owned destination abstraction | QOI's synchronous `MutByteLease` pull pattern in Phase 30 | It already demonstrates a portable non-retained output lease contract. [VERIFIED: codebase: `modules/mb-image/qoi/qoi.mbt`, `modules/mb-image/qoi/stream_encode.mbt`]

**Key insight:** PNG's canonical stored-DEFLATE format is simple enough to generate byte-by-byte from source coordinates, but its exact output length must be known first so the streaming constructor can preserve the eager resource boundary. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`] [ASSUMED]

## Common Pitfalls

### Pitfall 1: Preflight that scans or allocates output first

**What goes wrong:** A rejected output/work limit occurs after creating scanlines, zlib data, or a PNG buffer, so the public constructor cannot be honestly atomic. [ASSUMED]

**How to avoid:** Use the arithmetic formula above before source pixel iteration; compare error context, diagnostics, and every `Budget::remaining` field with the eager oracle. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `.planning/milestones/v0.8-phases/27-public-png-chunk-decoder/27-02-PLAN.md`]

### Pitfall 2: Losing the final stored-block bit across a pause

**What goes wrong:** The `BFINAL` byte is computed from a changing cursor after partial block emission, producing a noncanonical or invalid zlib stream. [ASSUMED]

**How to avoid:** Persist `block_index`, `block_payload_remaining`, and the precomputed `block_count`; emit `0x01` only for `block_index + 1 == block_count`. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`] [ASSUMED]

### Pitfall 3: CRC/Adler range confusion

**What goes wrong:** Adler is updated for zlib framing or IDAT CRC excludes the `IDAT` type/Adler bytes, changing canonical output. [ASSUMED]

**How to avoid:** Start IDAT CRC from `_png_crc_for_type(IDAT)`, update it for every zlib byte including header/block/Adler, and update Adler only for emitted filter bytes and sample bytes. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/structural.mbt`]

### Pitfall 4: Retaining an output lease

**What goes wrong:** A caller reuses or mutates a previous output owner and a later pull writes through the stale lease. [ASSUMED]

**How to avoid:** Make a lease a parameter of the private copy step only; state contains bytes/scalars and never `MutByteLease`. Use QOI's mutation/fresh-lease tests as the Phase-30 shape. [VERIFIED: codebase: `modules/mb-image/qoi/stream_encode.mbt`, `modules/mb-image/qoi/stream_encode_test.mbt`]

## Code Examples

### Exact stored-DEFLATE length preflight

```moonbit
// Derived from modules/mb-image/png/encode.mbt.
let scanlines = checked_mul(checked_add(row_bytes, 1UL), height)
let blocks = checked_add((scanlines - 1UL) / 65535UL, 1UL)
let idat = checked_add(checked_add(scanlines, 6UL), checked_mul(blocks, 5UL))
let total = checked_add(idat, 57UL)
```

The existing eager encoder emits zlib header + stored blocks + Adler as `scanlines + 6 + blocks * 5`, then adds 57 bytes for PNG signature, IHDR, IDAT framing, and IEND. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`]

### Bounded pending copy boundary

```moonbit
// Source pattern: modules/mb-image/qoi/stream_encode.mbt.
while written < destination.length() {
  let byte = machine.next_byte()
  destination.set(written, byte)
  // Only here update copied count / pending offset.
}
```

The QOI implementation establishes that state survives arbitrary output capacities through a private pending value/offset and synchronous destination mutation. [VERIFIED: codebase: `modules/mb-image/qoi/stream_encode.mbt`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Eager PNG builds whole scanlines, zlib, and PNG bytes before one writer call | Private resumable output machine is the approved v0.9 direction | v0.9 planning | Enables caller-buffered output later without changing the canonical format. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `.planning/ROADMAP.md`]
| QOI stream encoder has shared token state and caller-lease output | PNG uses the same ownership/preflight concept with PNG-specific framing/checksum state | v0.5 shipped; v0.9 planned | Reuse the proven state/lease contract without conflating QOI tokens with PNG stored-DEFLATE. [VERIFIED: codebase: `modules/mb-image/qoi/stream_encode.mbt`, `.planning/ROADMAP.md`]

**Deprecated/outdated:** Treating a buffered eager encoder as a resumable substrate is incompatible with this milestone's private incremental-output goal. [ASSUMED]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The private type can be named `PngEncodeMachine` and can expose a private one-byte/bounded-fragment emitter. | Summary; Architecture Patterns | Naming or MoonBit visibility constraints may require a different private layout, but not a different contract. |
| A2 | The eager `PngEncoder` should be routed through the same private machine in this phase using bounded staging. | Summary; State Ownership | If existing Writer behavior needs a distinct adapter, byte/error parity must still be proven before Phase 30. |
| A3 | The machine should retain the immutable source view under the same stable-backing expectation documented for QOI. | State Ownership | Phase 30 must document/verify the exact source-lifetime contract before exposing a public constructor. |

## Open Questions (RESOLVED)

1. **Eager Writer adapter granularity**
   - Decision: Phase 29 uses a fixed one-byte, machine-owned Writer staging adapter. It calls the existing complete-write operation for each byte, advances the machine's completed-byte count only after that call succeeds, and returns the original Writer `CoreError` unchanged on failure. [DECIDED: plan review 2026-07-21]
   - Rationale: the contract preserves canonical byte order, avoids retaining caller output or allocating output-sized staging, and makes the failed byte unambiguously absent from completed progress. [DECIDED: plan review 2026-07-21]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Compile/test all portable targets | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` | Compiler/interface generation | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local `moonc --version`] |
| `moonrun` | MoonBit test execution | ✓ | `0.1.20260713` | — [VERIFIED: local `moonrun --version`] |
| PowerShell 7 | Existing quality/fixture checks | ✓ | installed at `C:\Program Files\PowerShell\7\pwsh.exe` | — [VERIFIED: local command probe] |

**Missing dependencies with no fallback:** None. [VERIFIED: local command probes]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity boundary exists in a portable image codec. [VERIFIED: codebase: `modules/mb-image/png`] |
| V3 Session Management | no | No session state exists. [VERIFIED: codebase: `modules/mb-image/png`] |
| V4 Access Control | no | The codec has no authorization surface. [VERIFIED: codebase: `modules/mb-image/png`] |
| V5 Input Validation | yes | Existing capability checks, checked arithmetic, deterministic `CodecLimits`, and `Budget` preflight must remain authoritative. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`] |
| V6 Cryptography | no | PNG CRC and Adler are integrity/checksum algorithms, not security controls; do not represent them as cryptography. [CITED: https://www.w3.org/TR/png-3/] |

### Known Threat Patterns for portable PNG encode

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Huge dimensions / length overflow | Denial of Service | Checked source/row/scanline/block/total arithmetic plus existing width, height, pixel, output, work, and budget checks before machine creation. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`] |
| Output mutation before rejected construction | Tampering | Complete source/length/limit/disposition/budget preflight before the machine or any destination exists. [ASSUMED] |
| Stale caller output destination | Information Disclosure / Tampering | Retain no `MutByteLease`; accept it only during synchronous copying. [VERIFIED: codebase: `modules/mb-image/qoi/stream_encode.mbt`] |
| Checksum/state drift at output-capacity boundaries | Tampering | Persist CRC, Adler, stored-block, scanline, pending-offset, and total-count state; compare every generated byte to eager output. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- Codebase: `modules/mb-image/png/encode.mbt` — current compatibility checks, stored-DEFLATE construction, exact limit order, budget charge, writer-error mapping, and canonical framing.
- Codebase: `modules/mb-image/qoi/encode.mbt`, `qoi.mbt`, and `stream_encode.mbt` — authoritative in-repository resumable-output ownership, preflight, pending-state, and terminal precedent.
- Codebase: `.planning/milestones/v0.8-phases/26-pausable-png-decode-substrate/` and `27-public-png-chunk-decoder/` — private-machine, policy, and strict parity practices.

### Secondary (MEDIUM confidence)

- [PNG Third Edition](https://www.w3.org/TR/png-3/) — chunk layout/ordering, IDAT/zlib relationship, CRC scope, filtered scanlines, and compression requirements.

### Tertiary (LOW confidence)

- None; implementation recommendations are separately recorded in the Assumptions Log.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — the phase uses existing repository code only. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`]
- Architecture: HIGH — current eager PNG and shipped QOI streaming encode provide direct local seams; private machine naming/adapter granularity is logged as assumptions. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/qoi/stream_encode.mbt`]
- Pitfalls: HIGH — each derives from current checksum/layout code or shipped QOI stream-ownership behavior. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `modules/mb-image/qoi/stream_encode.mbt`]

**Research date:** 2026-07-21  
**Valid until:** 2026-08-20 (repository-local encoder design; revisit if the public Phase-30 contract changes).
