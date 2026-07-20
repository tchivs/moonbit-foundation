# Phase 13: QOI Format Core and Safe Decode - Research

**Researched:** 2026-07-20
**Domain:** Pure-MoonBit QOI 1.0 eager probe and decoder
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Codec boundary and output semantics
- **D-01:** Add QOI as an independent `mb-image/qoi` package that implements the existing `ImageDecoder` trait; do not alter the shared codec contracts, add a registry, or depend on `ops`.
- **D-02:** Decode complete QOI RGB/RGBA streams without silently losing alpha or declared color-space meaning. Preserve the source semantics through existing image descriptors where representable; otherwise fail with an explicit typed capability/encoding error rather than applying an implicit conversion.
- **D-03:** Keep decoding eager and whole-image-memory in this phase. Forward-only reader behavior still follows the existing codec progress/error contracts.

### Strict input and resources
- **D-04:** Probe is prefix-only: fewer than four bytes yields `NeedMore(4)`, non-`qoif` bytes yield `NoMatch`, and no `Reader` is consumed.
- **D-05:** Validate the 14-byte header, checked dimensions, channels, color-space, codec limits, and allocation budget before creating output storage. Preflight rejection must not mutate the authoritative budget or allocate output.
- **D-06:** With `require_complete_input`, require the exact QOI end marker and reject trailing bytes. Truncated opcode payloads, run overruns, malformed markers, zero-progress reads, and host I/O failures return the existing structured error/progress shape without panics.

### Evidence scope
- **D-07:** Use repository-owned, spec-derived fixture source plus a checked generator rather than network-fetched test data. Cover all QOI opcode families, byte wraparound, index collisions, initial pixel state, run boundaries, and malformed input on all four targets.

### the agent's Discretion
- Select private helper factoring, exact fixture layout, and the smallest representable metadata mapping after checking the existing PPM patterns and model capabilities.

### Deferred Ideas (OUT OF SCOPE)
- Canonical QOI encoding and byte-round-trip proof — Phase 14.
- Public decode-process-encode consumer — Phase 15.
- Streaming APIs, external corpus ingestion, PNG/DEFLATE, FFI, and benchmark baselines — future work.
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QOI-01 | Prefix-only QOI probe with deterministic no-match/need-more outcomes. | Four-byte pure probe and existing `ImageDecoder::probe` contract. |
| QOI-02 | Decode valid QOI 1.0 RGB/RGBA into an owned portable image with exact pixels. | Header/chunk state machine, direct RGB/RGBA descriptor mapping, and `OwnedImage::new_operation`. |
| QOI-04 | Typed deterministic invalid-data, resource, and I/O failures without preflight budget mutation. | Existing exact-read error remapping, caller limits, and atomic `Budget` charge seam. |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be MoonBit-native; native is the primary target while `js`, `wasm`, `wasm-gc`, and `native` remain deliberate conformance targets. [CITED: AGENTS.md]
- Keep FFI small, isolated, replaceable, and documented; this phase must add none. [CITED: AGENTS.md]
- Public packages need acyclic, documented dependencies; QOI must not import `ops` or force ecosystem-wide imports. [CITED: AGENTS.md]
- Public operations must be deterministic and GUI-free; benchmarks require reproducible workloads, but benchmarks are not Phase 13 scope. [CITED: AGENTS.md]
- Product changes must remain within a GSD workflow; the phase planning artifact is the authorized output here. [CITED: AGENTS.md]

## Summary

Implement QOI as one portable `modules/mb-image/qoi` package with a small public decoder value and private byte/state helpers. QOI 1.0 is a fixed 14-byte header, a sequence of byte-aligned chunks, and an eight-byte end marker; its reference state is only the prior RGBA pixel and a 64-entry RGBA index. This makes a pure eager decoder suitable for the established MoonBit contract without FFI, a registry, streaming state, or image operations. [CITED: https://qoiformat.org/qoi-specification.pdf] [CITED: modules/mb-image/codec/contracts.mbt]

The existing model can represent both QOI declarations exactly: channel value 3 maps to packed `rgb8` with no alpha mode; value 4 maps to packed `rgba8` with `AlphaMode::Straight`. QOI colorspace 0 maps to sRGB plus encoded-sRGB transfer and colorspace 1 maps to sRGB primaries plus linear-sRGB transfer; both retain QOI's un-premultiplied/straight alpha rule. No metadata conversion is required. [CITED: https://qoiformat.org/qoi-specification.pdf] [CITED: modules/mb-color/model/identities.mbt] [CITED: modules/mb-image/model/descriptor.mbt]

The decoder must complete all header-derived checked arithmetic and all output/shape/work/budget preflight before `OwnedImage::new_operation`. Compressed input length is not known from a header, so enforce `max_input_bytes` both for the fixed header and monotonically before each subsequent read; do not reject a valid short compressed stream solely because its theoretical worst-case encoding exceeds that ceiling. This follows the existing PPM distinction between derived preflight values and forward-only I/O progress. [CITED: modules/mb-image/ppm/decode.mbt] [CITED: modules/mb-core/io/exact.mbt]

**Primary recommendation:** Plan a single independent QOI decoder package around one header preflight, one private pixel/chunk state machine, and spec-derived generated fixtures; preserve the public codec contract unchanged.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Caller-owned prefix classification | API / Backend | — | `ImageDecoder::probe` receives only a `ByteView`; it has no `Reader`. [CITED: modules/mb-image/codec/contracts.mbt] |
| Forward-only QOI parsing | API / Backend | — | The decoder owns sequential reads, chunk interpretation, and typed failures. [CITED: modules/mb-image/codec/contracts.mbt] |
| Output image allocation and mutation | Database / Storage | API / Backend | `OwnedImage` owns checked allocation; decoder fills it through a bounded mutable view. [CITED: modules/mb-image/storage/owned_image.mbt] |
| Resource accounting | API / Backend | Database / Storage | Codec checks declared limits; the authoritative `Budget` preflights and commits output charge atomically. [CITED: modules/mb-core/budget/budget.mbt] |
| Format metadata interpretation | API / Backend | — | Header values map to the existing descriptor/color identities without pixel conversion. [CITED: modules/mb-image/model/descriptor.mbt] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit `moon` toolchain | `0.1.20260713` | Compile and test the portable QOI package. | Installed project baseline exposes `moon test --target all`; module already declares all four targets. [VERIFIED: local `moon --version` and `moon test --help`] |
| `tchivs/mb-image/codec` | workspace `0.1.0` | Existing `ImageDecoder`, limits, options, result, and error seam. | D-01 locks this boundary unchanged. [CITED: modules/mb-image/codec/contracts.mbt] |
| `tchivs/mb-image/storage` | workspace `0.1.0` | Checked owned output allocation and bounded fill. | Existing PPM decoder uses `OwnedImage::new_operation` for a single atomic output charge. [CITED: modules/mb-image/ppm/decode.mbt] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|-------------|-------------|
| `tchivs/mb-core/io` | workspace `0.1.0` | `read_exact` and forward-only progress/error semantics. | Every fixed-size QOI field/chunk payload and the complete-input marker check. [CITED: modules/mb-core/io/exact.mbt] |
| `tchivs/mb-core/checked` | workspace `0.1.0` | Checked dimension, byte-count, and work arithmetic. | Header preflight before descriptor/output allocation. [CITED: modules/mb-image/ppm/decode.mbt] |
| `tchivs/mb-image/model`, `metadata`, `mb-color/model`, `profile` | workspace `0.1.0` | Direct QOI descriptor and disposition construction. | Header channels/colorspace mapping and empty opaque metadata. [CITED: modules/mb-image/ppm/decode.mbt] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Independent pure QOI package | Extend PPM or a shared codec registry | Contradicts D-01 and couples independent codecs. [CITED: .planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md] |
| Eager `ImageDecoder` implementation | Streaming decoder API | Contradicts D-03; partial-state API is explicitly deferred. [CITED: .planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md] |
| Direct descriptor metadata mapping | Pixel colorspace conversion | Conversion would lose declared semantics or add scope; mapping is representable. [CITED: https://qoiformat.org/qoi-specification.pdf] [CITED: modules/mb-color/model/identities.mbt] |

**Installation:** None. This phase installs no external package, registry dependency, FFI library, or tool. [CITED: .planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
caller prefix ──> QoiDecoder.probe ──> NeedMore(4) | NoMatch | Match

forward-only Reader
  └─> exact 14-byte header read
       └─> validate magic/dimensions/channels/colorspace/derived limits
            ├─> typed failure; no output allocation or budget charge
            └─> descriptor + `OwnedImage::new_operation`
                 └─> chunk state machine (prev RGBA + index[64])
                      ├─> fill exact pixels
                      ├─> malformed/truncated/run-overrun/I-O failure
                      └─> if require_complete_input: exact marker then EOF check
                           └─> DecodeResult(image, disposition, bytes_read)
```

### Recommended Project Structure

```text
modules/mb-image/qoi/
├── moon.pkg                 # portable lower-layer imports; four target declaration
├── qoi.mbt                  # public QoiDecoder value and pure prefix helper
├── decode.mbt               # private header, descriptor, chunk/state-machine helpers and trait impl
├── decode_test.mbt          # public decode/hostile-reader/limit behavior tests
├── decode_wbtest.mbt        # private opcode and arithmetic invariant tests
└── generated_vectors.mbt    # generated, checked, repository-owned fixture table
fixtures/qoi/cases.json      # human-reviewable spec-derived fixture source
scripts/fixtures/Generate-QoiVectors.ps1  # deterministic generator with -Check mode
```

Update `modules/mb-image/moon.mod.json` is not needed because QOI is a package inside the existing module; update any package/interface policy allowlists only where existing quality rules require a new package. [CITED: modules/mb-image/moon.mod.json] [CITED: modules/mb-image/ppm/moon.pkg]

### Pattern 1: Pure prefix probe

**What:** Reject a prefix over `max_probe_bytes`; otherwise return `NeedMore(4)` for lengths 0–3 and compare the first four caller-owned bytes to `qoif`.

**When to use:** Only `ImageDecoder::probe`; never read, seek, allocate output, or charge a caller budget.

```moonbit
// Mirrors PPM's private prefix helper shape; source: codec contracts + QOI 1.0 spec.
fn probe_qoi_prefix(prefix : @bytes.ByteView) -> @codec.ProbeOutcome {
  if prefix.length() < 4UL { @codec.ProbeOutcome::NeedMore(4UL) }
  else if /* bytes are q,o,i,f */ { @codec.ProbeOutcome::Match }
  else { @codec.ProbeOutcome::NoMatch }
}
```

[CITED: modules/mb-image/ppm/ppm.mbt] [CITED: https://qoiformat.org/qoi-specification.pdf]

### Pattern 2: Header-only preflight, then one authoritative allocation

**What:** Read the 14-byte header with existing exact-read semantics; parse 32-bit big-endian width/height; validate nonzero dimensions, `channels in {3,4}`, `colorspace in {0,1}`, checked pixel/storage/work values, and every derivable `CodecLimits` ceiling before descriptor/allocation.

**When to use:** Once per decode, before decoding the first QOI chunk. Allocate scratch/index data privately, never from the caller's output budget; use `OwnedImage::new_operation` exactly once for successful output allocation.

**Important input-limit rule:** Enforce the known header count preflight, then increment/check actual consumed bytes before each later read. The compressed chunk length cannot be known from the header. This preserves a true maximum on consumed input without treating `14 + 5*pixels + 8` as the required size of every valid stream. [CITED: https://qoiformat.org/qoi-specification.pdf]

### Pattern 3: Pixel-count-bounded chunk machine

**What:** Store `previous = (0,0,0,255)` and a zero-initialized 64-entry RGBA index. Read one tag; test `0xFE` and `0xFF` first, then dispatch top two bits to INDEX, DIFF, LUMA, or RUN. Write only up to `width * height` pixels; reject a run whose decoded count exceeds remaining pixels.

**When to use:** For all QOI payload processing. Update the hash index after each decoded pixel, including expanded run pixels only according to the same observed-pixel state rule used by the decoder.

**QOI field facts:** RGB preserves prior alpha; RGBA replaces all channels; DIFF and LUMA use byte wraparound; RUN encodes 1–62 repeated prior pixels; the index is `(r*3 + g*5 + b*7 + a*11) % 64`. Eight-bit RGB/RGBA tags have precedence over two-bit tags. [CITED: https://qoiformat.org/qoi-specification.pdf]

### Pattern 4: Preserve exact forward-I/O diagnostics

**What:** Use a single-byte or fixed-payload helper based on `@io.read_exact`, remapping its `requested`/`completed` to the operation's total payload progress just as PPM does. Read one byte past the required marker only when complete input is required; successful byte means deterministic trailing-data error, `UnexpectedEndOfStream` means exact completion, and other I/O errors propagate.

**When to use:** Header fields, all opcode payloads, end marker, and trailing check. No direct `Reader.read` loop should duplicate the exact-read zero-progress or over-progress logic.

[CITED: modules/mb-core/io/exact.mbt] [CITED: modules/mb-image/ppm/decode.mbt]

### Metadata Mapping

| QOI header declaration | Output descriptor | Metadata | Disposition |
|------------------------|-------------------|----------|-------------|
| `channels = 3` | `ImageFormat::rgb8()` | alpha `None` | Empty, non-lossy. [CITED: modules/mb-image/model/descriptor.mbt] |
| `channels = 4` | `ImageFormat::rgba8()` | `AlphaMode::Straight` | Empty, non-lossy; QOI specifies un-premultiplied alpha. [CITED: https://qoiformat.org/qoi-specification.pdf] |
| `colorspace = 0` | unchanged pixels | `Srgb` + `EncodedSrgb` + builtin sRGB profile | Empty, non-lossy. [CITED: https://qoiformat.org/qoi-specification.pdf] [CITED: modules/mb-color/model/identities.mbt] |
| `colorspace = 1` | unchanged pixels | `Srgb` + `LinearSrgb` + builtin sRGB profile | Empty, non-lossy. [CITED: https://qoiformat.org/qoi-specification.pdf] [CITED: modules/mb-color/model/identities.mbt] |

`preserve_opaque_metadata` has no QOI source payload to retain, so use the same empty opaque metadata/disposition construction as PPM; never invent an opaque metadata entry. [CITED: modules/mb-image/ppm/decode.mbt]

### Anti-Patterns to Avoid

- **Changing `codec/contracts.mbt`:** D-01 makes contracts, registry, and operations dependencies out of scope. [CITED: .planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md]
- **Checking two-bit tags before `0xFE`/`0xFF`:** RGB/RGBA would be misread as RUN; the specification expressly grants eight-bit tag precedence. [CITED: https://qoiformat.org/qoi-specification.pdf]
- **Treating channel or colorspace declarations as conversion instructions:** They are informative and do not alter chunk encoding; map them to descriptor semantics without conversion. [CITED: https://qoiformat.org/qoi-specification.pdf]
- **Allocating before all header-derived checks:** Violates D-05 and loses PPM's atomic budget behavior. [CITED: modules/mb-image/ppm/decode.mbt]
- **Accepting a complete-pixel stream without validating marker/trailing bytes when the option requires completion:** Violates D-06. [CITED: .planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exact partial-read handling | Ad-hoc reader loops | `@io.read_exact` plus a QOI progress remapper | It already detects zero/invalid progress, EOF, and host failure with structured counts. [CITED: modules/mb-core/io/exact.mbt] |
| Authoritative resource mutation | Separate per-dimension budget charges | `OwnedImage::new_operation` | It uses one allocation charge which preflights every budget window before commit. [CITED: modules/mb-image/storage/owned_image.mbt] [CITED: modules/mb-core/budget/budget.mbt] |
| Descriptor validation | Open-coded plane layout/alpha checks | `ImageDescriptor::new` and `PlaneDescriptor::new` | Existing model validates dimensions, packing, storage ranges, and alpha identity. [CITED: modules/mb-image/model/descriptor.mbt] |
| Fixture corpus | Downloaded QOI corpus or handwritten generated bytes | Checked repository fixture JSON plus generator | D-07 requires auditable, network-independent vectors and deterministic regeneration. [CITED: .planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md] |

**Key insight:** QOI's codec algorithm is intentionally small enough to implement, but the existing infrastructure already solves unsafe allocation, forward-progress, and descriptor invariants; use those seams rather than recreating them.

## Common Pitfalls

### Pitfall 1: Misclassifying `0xFE` / `0xFF`
**What goes wrong:** The RGB/RGBA opcodes share the `11` high bits with RUN.
**Why it happens:** A decoder dispatches only on top-two bits.
**How to avoid:** Check the full-byte RGB and RGBA tags before the two-bit dispatch.
**Warning signs:** A valid RGB opcode becomes an impossible 63/64-length run.
[CITED: https://qoiformat.org/qoi-specification.pdf]

### Pitfall 2: Incorrect run count or run overrun
**What goes wrong:** Decoder emits `tag & 0x3f` pixels instead of that quantity plus one, or writes beyond image capacity.
**Why it happens:** QOI stores run length with a -1 bias.
**How to avoid:** Decode `run = low6 + 1`, compare with remaining output pixels before writing, and reject overflow deterministically.
**Warning signs:** One-pixel runs vanish, or a malformed final run mutates out-of-range output.
[CITED: https://qoiformat.org/qoi-specification.pdf]

### Pitfall 3: Losing alpha or colorspace semantics
**What goes wrong:** RGBA is decoded into RGB, alpha becomes premultiplied, or linear input is labelled encoded sRGB.
**Why it happens:** Treating QOI header declarations as disposable hints.
**How to avoid:** Use `rgba8` + straight alpha for channel 4 and direct transfer mapping for both colorspace values.
**Warning signs:** Descriptor tests cannot distinguish RGB/RGBA or colorspace 0/1.
[CITED: https://qoiformat.org/qoi-specification.pdf] [CITED: modules/mb-color/model/identities.mbt]

### Pitfall 4: Non-atomic preflight
**What goes wrong:** A limit or budget failure occurs after output allocation or a partial budget charge.
**Why it happens:** Header checks, descriptor construction, and allocation are interleaved.
**How to avoid:** Compute all header-derived quantities, validate codec ceilings, build descriptor, then call the single owned-image allocation seam.
**Warning signs:** Budget `remaining()` differs after a rejected header/limit test.
[CITED: modules/mb-image/ppm/decode.mbt] [CITED: modules/mb-core/budget/budget.mbt]

### Pitfall 5: Hiding stream progress errors
**What goes wrong:** A zero-progress reader spins or a host error loses the total completed count.
**Why it happens:** Implementing direct reader loops rather than `read_exact`.
**How to avoid:** Reuse exact-read and PPM-style remapping for QOI header/chunk context.
**Warning signs:** `NoProgress` has no stable operation/requested/completed fields.
[CITED: modules/mb-core/io/exact.mbt] [CITED: modules/mb-image/ppm/decode_test.mbt]

## Code Examples

### Header preflight order

```moonbit
// Pattern only: keep all derived checks before the caller-budget allocation.
let header = read_qoi_header(reader, limits)?
let pixels = @checked.checked_mul(header.width, header.height)?
let channels = if header.channels == 3 { 3UL } else { 4UL }
let output_bytes = @checked.checked_mul(pixels, channels)?
let work = /* documented checked decode work */
validate_qoi_limits(header, pixels, output_bytes, work, limits)?
let descriptor = qoi_descriptor(header, output_bytes)?
let image = @storage.OwnedImage::new_operation(descriptor, budget, allocator, work)?
```

This is the PPM allocation ordering adapted to QOI's header-derived shape; actual QOI code must check channels/colorspace before choosing channel count. [CITED: modules/mb-image/ppm/decode.mbt]

### Strict complete-input finish

```moonbit
// Only for options.require_complete_input().
read_exact_end_marker(reader, consumed, limits)?
match read_one_checked(reader, consumed + 8UL, limits) {
  Ok(_) => Err(qoi_data_error("qoi-trailing-data"))
  Err(error) if error.code() == @error.ErrorCode::UnexpectedEndOfStream => Ok(())
  Err(error) => Err(error)
}
```

The marker is seven `0x00` bytes then `0x01`; the EOF probe follows the existing strict PPM trailing-data pattern. [CITED: https://qoiformat.org/qoi-specification.pdf] [CITED: modules/mb-image/ppm/decode.mbt]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| PPM P6 is the sole concrete decoder | Add independent QOI 1.0 decoder over the same contracts | Phase 13 plan | Users gain lossless RGB/RGBA interchange without FFI or a contract change. [CITED: .planning/PROJECT.md] |

**Deprecated/outdated:** None for this scoped phase. The QOI authority is Specification Version 1.0 dated 2022-01-05. [CITED: https://qoiformat.org/qoi-specification.pdf]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. All implementation-relevant claims above are cited to the QOI specification or current codebase. | — | — |

## Open Questions (RESOLVED)

1. **QOI decode work charge** — `decode_work = checked_add(pixel_count, output_bytes)`. Both operands are derived from the validated 14-byte header before allocation; this checked value is compared with `CodecLimits.max_work` and passed unchanged to `OwnedImage::new_operation`, allowing the existing `Budget` preflight to charge or reject the complete operation atomically. Compressed-byte and per-opcode work are deliberately excluded because they are not fully header-derivable. This is the locked strategy in `13-01-PLAN.md`.

2. **Relaxed completion progress** — when `require_complete_input = false`, the decoder returns at the declared pixel boundary with exact consumed progress and does not consume the QOI end marker or trailing input. Exact marker and EOF/trailing validation occur only in strict mode. This is the locked strategy in `13-01-PLAN.md` and preserves forward-only caller control of unread bytes.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| MoonBit toolchain | Compile/check/test QOI across portable targets | ✓ | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf` | — [VERIFIED: local `moon --version`] |
| Four-target test selector | Conformance evidence | ✓ | `moon test --target all` supports `wasm`, `wasm-gc`, `js`, `native`, `all` | Individual `--target` runs only for diagnosis. [VERIFIED: local `moon test --help`] |
| PowerShell | Checked fixture generator | ✓ | PowerShell host used by existing fixture generators | — [CITED: scripts/fixtures/Generate-PpmVectors.ps1] |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No user/session boundary in this local codec. [CITED: .planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md] |
| V3 Session Management | no | No session state. [CITED: .planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md] |
| V4 Access Control | no | No authorization boundary. [CITED: .planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md] |
| V5 Input Validation | yes | Validate magic/header enums/dimensions, checked arithmetic, codec limits, pixel count, run bounds, marker, and trailing policy. [CITED: https://qoiformat.org/qoi-specification.pdf] |
| V6 Cryptography | no | QOI decoding has no cryptographic function. [CITED: https://qoiformat.org/qoi-specification.pdf] |

### Known Threat Patterns for QOI decoder

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dimension or multiplication overflow | Denial of Service | Checked arithmetic and all shape/output ceilings before allocation. [CITED: modules/mb-image/ppm/decode.mbt] |
| Allocation/budget exhaustion | Denial of Service | `OwnedImage::new_operation` atomic preflight with caller `Budget`. [CITED: modules/mb-image/storage/owned_image.mbt] |
| Truncated opcode or zero-progress reader | Denial of Service | `read_exact` structured EOF/NoProgress behavior and context remapping. [CITED: modules/mb-core/io/exact.mbt] |
| Run exceeds declared pixel count | Tampering | Compare decoded run length to remaining pixels before output write. [CITED: https://qoiformat.org/qoi-specification.pdf] |
| Invalid marker or trailing input in strict mode | Tampering | Exact marker read then EOF check when `require_complete_input` is true. [CITED: https://qoiformat.org/qoi-specification.pdf] |

## Sources

### Primary (HIGH confidence)

- [QOI 1.0 specification](https://qoiformat.org/qoi-specification.pdf) — header, colorspace/channels, chunk dispatch, hash, pixel state, byte wrap, and marker.
- `modules/mb-image/codec/contracts.mbt` — immutable codec API and option/result contracts.
- `modules/mb-image/ppm/decode.mbt`, `decode_test.mbt` — current decoder allocation, limit, trailing, and I/O diagnostic patterns.
- `modules/mb-core/io/exact.mbt`, `modules/mb-core/budget/budget.mbt`, `modules/mb-image/storage/owned_image.mbt` — exact progress and atomic resource mechanisms.

### Secondary (MEDIUM confidence)

- Local MoonBit CLI `moon test --help` — installed selector surface for four-target test execution.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locked workspace contracts and local installed toolchain.
- Architecture: HIGH — QOI 1.0 specification and existing PPM implementation agree on the required seam.
- Pitfalls: HIGH — direct QOI opcode/marker rules and existing hostile-reader tests.

**Research date:** 2026-07-20
**Valid until:** 2026-08-19 (QOI 1.0 and local contract patterns are stable; revisit after shared codec contract changes).
