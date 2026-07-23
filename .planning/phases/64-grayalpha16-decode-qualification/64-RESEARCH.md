# Phase 64: GrayAlpha16 Decode Qualification - Research

**Researched:** 2026-07-23  
**Domain:** Portable MoonBit PNG Type-4/16 decode qualification  
**Confidence:** LOW (the required confidence seam classifies the direct local provider as LOW; the cited repository evidence is nevertheless specific and directly inspectable.)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Use independent non-symmetric Type-4/16 vectors that exercise full
  `Ghi,Glo,Ahi,Alo` preservation after each supported filter and Adam7 pass.
- **D-02:** Exercise eager and chunk preservation through malformed metadata,
  resource limits, split input, and terminal paths; each failure remains atomic
  and generic decoding remains unchanged.
- **D-03:** Run the ordinary full PNG package on wasm, wasm-gc, js, and native;
  no wrapper, target-specific fixture, or generated expected output substitutes
  for that command.

### the agent's Discretion

- Reuse the smallest public helper/vector patterns. Keep production code frozen
  unless a qualification test exposes a genuine Phase 62/63 contract defect.

### Deferred Ideas (OUT OF SCOPE)

- Colour-managed conversion, a public conversion API, generic result widening,
  new storage, FFI, release automation, wrappers, and copied-source workflows.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GRA16DEC-03 | Public independent Type-4/16 wire/decode vectors, filters and Adam7 coverage, adversarial resource/metadata rejection, frozen legacy RGBA8 behavior, and the full PNG package pass on wasm, wasm-gc, js, and native. | [CITED: `.planning/REQUIREMENTS.md`] The public literal, chunk-parity, profile-admission, row-reconstruction, and ordinary-package command patterns below cover each required proof. |
</phase_requirements>

## Summary

[CITED: `.planning/ROADMAP.md`; `.planning/phases/62-explicit-grayalpha16-decode-contract/62-VERIFICATION.md`; `.planning/phases/63-resumable-grayalpha16-decode/63-VERIFICATION.md`] Phase 64 is an evidence-and-correction phase for the one existing bounded decoder, not a new public API or a new decode pipeline. Phase 62 established non-interlaced eager preservation and frozen generic RGBA8 behavior; Phase 63 established the same result through the caller-owned chunk lifecycle. Qualification must make byte-domain filtering, Adam7 scatter, resource accounting, hostile terminal behavior, and the existing generic façade observable through independent public fixtures.

[VERIFIED: local source inspection] The current explicit-profile gate rejects any interlaced Type-4/16 PNG at `modules/mb-image/png/stream_decode.mbt:507`, while the Phase 64 success criterion requires all seven Adam7 passes. The existing Adam7 sink calls a generic high-byte writer without passing its profile at `modules/mb-image/png/raster_decode.mbt:416-423`; that writer maps Type-4/16 to RGBA8 at `:557-560`. Therefore, a public Adam7 preservation fixture will expose a genuine Phase 62/63 contract defect, authorizing the minimal production correction: admit interlace and dispatch the existing GrayAlpha16 lane-store at Adam7 scatter time.

**Primary recommendation:** Add two independent public Type-4/16 literals (five-filter non-interlaced and seven-pass Adam7), generalize the existing public component assertion/schedule helper once, then fix only the currently unreachable Adam7 profile branch revealed by those tests. [VERIFIED: local source inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Type-4/16 byte reconstruction and filter fidelity | API / Backend (portable PNG library) | Public test suite | [CITED: `modules/mb-image/png/raster_decode.mbt`] The shared sink reconstructs encoded source bytes before selecting the final image-store mapping. |
| Adam7 pass traversal and coordinate scatter | API / Backend (portable PNG library) | Public test suite | [CITED: `modules/mb-image/png/raster_decode.mbt`] The sink owns pass cursors, row reset, and final coordinate writes; a public image test observes the result. |
| Input, metadata, budget, and terminal safety | API / Backend (portable PNG library) | Public chunk/eager tests | [CITED: `modules/mb-image/png/stream_decode.mbt`; `stream_decode_test.mbt`] The machine gates profile facts and owns result visibility; callers only supply views and call `finish()`. |
| Four-target qualification | Build / CI | Portable PNG package tests | [CITED: `AGENTS.md`] The package is declared portable and target behaviour is proven by the ordinary package command, not target-specific tests. |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain MoonBit; native is primary but portable targets are deliberate conformance boundaries. [CITED: `AGENTS.md`]
- Keep FFI absent from this work; public packages keep acyclic dependencies and SemVer-compatible additive behaviour. [CITED: `AGENTS.md`]
- Public operations remain deterministic and GUI-free; this phase must not add wrappers, copied workflows, or generated-output substitutes. [CITED: `AGENTS.md`; `64-CONTEXT.md`]
- Follow the repository’s public `*_test.mbt` and internal `*_wbtest.mbt` split; binary evidence uses fixed bytes/digests plus semantic assertions rather than opaque snapshots. [CITED: `AGENTS.md`]
- Code discovery used graph tools when available; no codebase-memory MCP graph tool was exposed in this research runtime, so local source inspection was the necessary fallback. [VERIFIED: research runtime tool availability]

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why standard |
|----------------|---------|---------|--------------|
| MoonBit `moon` / `moonc` / `moonrun` | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf`, `moonrun 0.1.20260713` | Compile and run the existing portable PNG package tests | [VERIFIED: local `moon --version`, `moonc -v`, and `moonrun --version`] This repository already uses the toolchain; Phase 64 adds no dependency. |
| Existing `mb-image/png` package | workspace source | Shared PNG decoder and public tests | [CITED: `modules/mb-image/png/moon.pkg`] The phase must qualify the one package and must not create a sidecar package or wrapper. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| None | — | No external dependency is needed | [VERIFIED: local source inspection] Keep the phase dependency-free. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-authored public PNG byte literals | Encoder-produced bytes, copied fixtures, or target-specific generated expectations | [CITED: `64-CONTEXT.md`] Rejected: these share an oracle with the implementation or violate D-03. |
| Direct `moon ... test png --target all --frozen` | Quality PowerShell wrappers or filtered target runs as final evidence | [CITED: `64-CONTEXT.md`] Rejected: they do not satisfy the required ordinary full-package proof. |

**Installation:** None. [VERIFIED: local source inspection]

## Architecture Patterns

### System Architecture Diagram

```text
independent Type-4/16 PNG literal
        |
        v
PngDecoder::decode_graya16 / PngChunkDecoder::new_graya16
        |
        +--> pre-IDAT profile + metadata + resource gate --reject--> typed atomic terminal
        |
        v
shared inflater -> byte-domain filter reconstruction -> normal row or Adam7 pass scatter
        |                                                    |
        |                                                    v
        +------------------------------------------> GrayAlpha16 final store
                                                               |
                                                               v
                                      public little-endian Glo,Ghi,Alo,Ahi assertions

same literal -> generic eager/chunk constructor -> frozen RGBA8(Ghi,Ghi,Ghi,Ahi) assertions
```

[CITED: `modules/mb-image/png/stream_decode.mbt`; `modules/mb-image/png/raster_decode.mbt`] The diagram is one machine with two final representation profiles; it must remain one machine.

### Required Minimal Project Changes

| File | Change | Why it is minimal |
|------|--------|-------------------|
| `modules/mb-image/png/png_test.mbt` | Add fixed independent public Type-4/16 fixtures and an eager assertion helper that compares every U16 component byte by coordinate. Add exact and one-less resource tests against the same literals. | [CITED: `png_test.mbt:16-104`] It already owns the Phase 62 public wire literal and component-byte oracle. |
| `modules/mb-image/png/stream_decode_test.mbt` | Generalize `png_graya16_chunk_result_matches`/the hard-coded lane assertion into one coordinate-byte helper; run the new literals through empty, one-byte, and ragged schedules; assert generic eager/chunk baseline and sticky no-result failures. | [CITED: `stream_decode_test.mbt:403-706`] It already owns public eager/chunk parity and terminal helpers. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | Replace the current `interlaced` rejection case with profile admission evidence for legal Type-4/16 Adam7, retaining wrong depth/type and legacy gAMA/iCCP rejection assertions. | [CITED: `stream_decode_wbtest.mbt:274-325`] The existing white-box test currently encodes the now-conflicting rejection. |
| `modules/mb-image/png/stream_decode.mbt` | Remove only the explicit-profile `ihdr[12] != 0` disqualifier. | [VERIFIED: local source inspection] This is the sole profile admission check blocking legal Adam7 before allocation. |
| `modules/mb-image/png/raster_decode.mbt` | Thread `self.profile` into the Adam7 transport-row writer and select the existing GrayAlpha16 component-byte store for Type-4/16; leave generic expansion unchanged. | [VERIFIED: local source inspection] The non-interlaced branch already makes this exact profile choice at `:438-445`; Adam7 is the missing equivalent. |

**Do not change:** `png.mbt` public selectors, generic `ImageDecoder` result type, `encode_test.mbt`, generated vector files, fixture generators, quality scripts, dependencies, or target-specific files. [CITED: `64-CONTEXT.md`; `62-VERIFICATION.md`; `63-VERIFICATION.md`]

### Pattern 1: Independent fixture plus public output oracle

**What:** Keep a complete fixed PNG literal (or a test-local fixed byte constructor that explicitly writes PNG framing, stored-DEFLATE payload, and CRC) independent from `PngEncoder`; assert raw component bytes by `(x, y, channel, byte_index)`. [CITED: `png_test.mbt:16-104`; `encode_test.mbt:1281-1430`]

**When to use:** For the five filters and Adam7 matrix, where an encoder-produced fixture could reproduce the same traversal or byte-order mistake. [CITED: `64-CONTEXT.md`]

**Example:**

```moonbit
// Source: public component-byte pattern in modules/mb-image/png/png_test.mbt
for item in expected_components {
  let (x, y, channel, byte_index, expected) = item
  inspect(result.image().view().get_component_byte(x, y, channel, byte_index).unwrap() == expected, content="true")
}
```

### Pattern 2: One public schedule helper, no decoder copy

**What:** Reuse the existing `new_graya16` schedule lifecycle and expand only its expected-coordinate input; compare a fresh eager peer, budget remainders, diagnostics, exact consumed counts, and `finish()` transfer. [CITED: `stream_decode_test.mbt:485-560`]

**When to use:** Both new legal fixtures must run with empty, one-byte, and ragged schedules; hostile split input must use the same helper rather than a bespoke parser. [CITED: `64-CONTEXT.md`]

### Pattern 3: Exact/one-less resource boundary

**What:** Construct a fresh budget for each case. The exact budget must succeed; one unit below the relevant `bytes`, `allocation_size`, `max_output_bytes`, or `max_work` ceiling must return the established resource error, expose no result, and retain atomic/sticky chunk state. [CITED: `structural.mbt:607-637`; `structural.mbt:642-674`; `stream_decode_test.mbt:613-706`]

**When to use:** At least one non-interlaced filter fixture and the 5x5 Adam7 fixture, because Adam7’s maximum source-row and total filtered-work accounting differ. [CITED: `structural.mbt:607-637`]

## Exact Qualification Matrix

| Concern | Minimal independent vector / helper | Required assertions | Existing anchor |
|---------|-------------------------------------|---------------------|-----------------|
| Filters 0–4 | One non-interlaced 2x5 Type-4/16 literal with rows tagged None, Sub, Up, Average, Paeth and non-symmetric `Ghi,Glo,Ahi,Alo` values | Every two-component, two-byte lane at all ten pixels is `Glo,Ghi,Alo,Ahi`; generic eager and chunk are `RGBA8(Ghi,Ghi,Ghi,Ahi)` | [CITED: `png_test.mbt:16-104`; `raster_decode.mbt:432-449`] |
| Adam7 passes 1–7 | One 5x5 Type-4/16 Adam7 literal; all seven passes are nonempty and its expected bytes derive from `(x,y)` directly | Every coordinate’s four stored component bytes; public eager equals chunk under one-byte and ragged schedules; generic eager/chunk remain high-byte RGBA8 | [CITED: `encode_test.mbt:248-307`; `raster_decode.mbt:343-475`] |
| Legacy metadata | Reuse the `gAMA` insertion helper and add a fixed, CRC-valid iCCP literal or use the existing authenticated white-box iCCP fact | Explicit eager/chunk error category/code/operation/context `graya16-profile`; zero lifecycle/result; split metadata input replays the same terminal | [CITED: `stream_decode_test.mbt:580-706`; `stream_decode_wbtest.mbt:66-95`] |
| Resources | Reuse public limits/budget constructors; parameterize exact and one-less values for filter and Adam7 sources | Exact success; one-less failure before public result; budgets/diagnostics match eager and chunk terminal contracts | [CITED: `png_test.mbt:385-420`; `structural.mbt:607-674`] |
| Split input / terminal | Reuse `png_graya16_chunk_schedule` and `png_graya16_chunk_assert_sticky` | Empty start, one-byte, ragged and metadata-split schedules; `NeedInput` until `finish`; error replay consumes zero later bytes | [CITED: `stream_decode_test.mbt:485-706`] |
| Frozen generic compatibility | Use the *same* independent filter and Adam7 literals with `PngDecoder::new` and `PngChunkDecoder::new` | Descriptor/result remains RGBA8; each pixel is `(Ghi,Ghi,Ghi,Ahi)`; generic accepted progress, diagnostics, and terminal replay retain their existing helper comparisons | [CITED: `62-VERIFICATION.md`; `63-VERIFICATION.md`; `stream_decode_test.mbt:371-402`] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| A second decoder for qualification | Profile-specific parser, inflater, chunk state, or staging buffer | Existing `PngDecodeMachine`, `PngRasterSink`, and public chunk schedule helpers | [CITED: `64-CONTEXT.md`; `stream_decode.mbt`] A second lifecycle would invalidate the frozen progress and terminal proof. |
| Filter residual generation in production | U16/endian-aware filtering or a separate Alpha16 filter | Existing byte-domain `PngPackedRows::reconstruct` with Type-4/16 `bpp=4` | [CITED: `raster_decode.mbt:117-130`; `raster_decode.mbt:432-445`] PNG filtering occurs before the final little-endian store. |
| Adam7 test oracle from the encoder | Decode expectations generated by `PngEncoder` | Fixed independent literal plus coordinate formula | [CITED: `64-CONTEXT.md`; `encode_test.mbt:248-307`] Encoder and decoder must not validate the same incorrect traversal. |
| Target evidence | PowerShell wrapper, filtered final run, copies, or target-only fixtures | Direct full `moon -C modules/mb-image test png --target all --frozen` | [CITED: `64-CONTEXT.md`] The required evidence is the ordinary package command. |

## Common Pitfalls

### Pitfall 1: Treating current interlace rejection as intended final behaviour

[VERIFIED: local source inspection] The current profile rejects `ihdr[12] != 0`, but the phase explicitly requires Adam7 preservation. Remove only that condition and update its white-box expectation; retain all other profile gates. **Warning sign:** an Adam7 literal fails with `graya16-profile` before an image lifecycle exists.

### Pitfall 2: Admitting Adam7 without profile-aware scatter

[VERIFIED: local source inspection] The current Adam7 writer is generic and reads only `Ghi` and `Ahi`. **Avoidance:** route `self.profile` to the existing GrayAlpha16 component writer after pass-local byte reconstruction. **Warning sign:** the decoded output is `graya16` but low bytes equal zero, high bytes, or unrelated values.

### Pitfall 3: Proving only filter None or only the high bytes

[CITED: `.planning/research/v020-PITFALLS.md`; `raster_decode.mbt`] Sub/Up/Average/Paeth can hide a wrong `bpp` or byte order that None does not expose. Assert every stored byte and use lanes whose high and low values differ.

### Pitfall 4: Letting the positive fixture replace hostile proof

[CITED: `63-VERIFICATION.md`; `stream_decode_test.mbt`] Success does not prove the pre-allocation gate, no-result lifecycle, accepted-only progress, or sticky terminal semantics. Run malformed metadata, limits, and split schedules through the public eager/chunk paths as well.

### Pitfall 5: Confusing a build-lock timeout with an OOM result

[VERIFIED: local command execution] The direct all-target command exceeded the 64-second research execution window and a later direct JS full-package attempt blocked on `_build/.moon-lock`; no OOM diagnostic was emitted in this session. [CITED: `62-VERIFICATION.md`] A prior Phase 62 full native-suite Clang out-of-memory condition is documented, so native memory pressure remains a risk to monitor separately.

## Code Examples

### Public generic compatibility assertion

```moonbit
// Source: public generic assertion shape in modules/mb-image/png/png_test.mbt
for channel = 0UL; channel < 3UL; channel = channel + 1UL {
  inspect(generic.get_byte(x, y, channel).unwrap() == ghi, content="true")
}
inspect(generic.get_byte(x, y, 3UL).unwrap() == ahi, content="true")
```

### Atomic split-terminal assertion

```moonbit
// Source: public terminal helper pattern in modules/mb-image/png/stream_decode_test.mbt
let terminal = decoder.finish().unwrap_err()
let replay = decoder.push(later.view())
inspect(replay.consumed() == 0UL, content="true")
// Compare replay and repeated finish with the first typed terminal.
```

## State of the Art

| Old approach | Current Phase 64 approach | Impact |
|--------------|---------------------------|--------|
| Explicit GrayAlpha16 accepts only non-interlaced Type-4/16 | Legal Type-4/16 Adam7 enters the same shared profile and preserves all lanes | [VERIFIED: local source inspection] This closes the current qualification-visible profile gap without widening generic decode. |
| Phase 62/63 fixed two-pixel lane oracle | Independent all-filter and all-pass coordinate oracle | [CITED: `62-VERIFICATION.md`; `63-VERIFICATION.md`] This detects errors hidden by the original non-interlaced None-filter literal. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | None. | — | [VERIFIED: local source inspection] All recommendations are derived from the locked context, adjacent verifications, local source, and direct toolchain observation. |

## Open Questions (RESOLVED)

1. **(RESOLVED 2026-07-23) Can the target machine run the direct four-target package command without inherited build contention?**
   - Resolution: [VERIFIED: local filesystem/process inspection] No `.moon-lock` exists beneath `modules/mb-image/_build`; the direct package command therefore has a lock-free precondition. A pre-existing `moon.exe` process is not terminated or otherwise modified because it is not owned by this phase. The Phase 64 executor will still run the required command serially and report any fresh contention rather than removing a lock or substituting a wrapper.

## Environment Availability

| Dependency | Required By | Available | Version / state | Fallback |
|------------|-------------|-----------|-----------------|----------|
| `moon` toolchain | Build and package test | ✓ | [VERIFIED: local `moon --version`] `0.1.20260713` | — |
| `moonc` / `moonrun` | Target compilation / execution | ✓ | [VERIFIED: local `moonc -v`; `moonrun --version`] `v0.10.4+2cc641edf` / `0.1.20260713` | — |
| Direct four-target build lock | Final qualification command | ✗ in this research session | [VERIFIED: local command execution] Existing `_build/.moon-lock` owner blocked a later direct package run | Wait for lock owner; no wrapper or copied build tree is allowed. |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment inspection]

**Execution plan (all commands are direct; run serially, never in parallel):**

```powershell
# Focused development checks; these are not final target evidence.
moon -C modules/mb-image test png --target js --frozen --filter '*graya16*'
moon -C modules/mb-image test png --target js --frozen

# Final Phase 64 gate: ordinary whole package, no wrapper/copy/filter.
moon -C modules/mb-image test png --target all --frozen
```

[CITED: `64-CONTEXT.md`; `AGENTS.md`] If native reports an actual Clang OOM, record the command and diagnostic, retry only the same direct command after normal executor resource recovery, and do not replace it with a wrapper, a reduced fixture, or target-specific expected output.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | [CITED: phase scope] No identity or login surface is involved. |
| V3 Session Management | No | [CITED: phase scope] The caller-owned chunk decoder is a parsing lifecycle, not a user session. |
| V4 Access Control | No | [CITED: phase scope] No authorization boundary is added. |
| V5 Input Validation | Yes | [CITED: `stream_decode.mbt`; `structural.mbt`] First-IDAT profile admission, CRC/framing, size/resource limits, and typed terminal errors remain the controls. |
| V6 Cryptography | No | [CITED: phase scope] No cryptographic operation is introduced; PNG CRC is framing integrity, not a cryptographic control. |

### Known Threat Patterns for portable PNG decode

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed metadata changes profile identity or allocates output | Tampering / DoS | [CITED: `stream_decode.mbt:501-548`; `stream_decode_wbtest.mbt:274-325`] Validate the complete profile before lifecycle allocation and assert no outcome. |
| Oversized image, filtered stream, or work estimate | DoS | [CITED: `structural.mbt:607-674`; `structural.mbt:1347-1372`] Checked limit and child-budget preflight plus exact/one-less tests. |
| Chunk replay exposes a partial result or consumes later attacker bytes | Tampering / DoS | [CITED: `stream_decode_test.mbt:589-706`] Existing sticky terminal and zero-consumption replay checks. |

## Sources

### Primary (local repository evidence)

- [CITED: `.planning/phases/64-grayalpha16-decode-qualification/64-CONTEXT.md`] — locked scope and non-wrapper constraints.
- [CITED: `.planning/phases/62-explicit-grayalpha16-decode-contract/62-VERIFICATION.md`] — frozen eager contract and prior native OOM note.
- [CITED: `.planning/phases/63-resumable-grayalpha16-decode/63-VERIFICATION.md`] — frozen chunk lifecycle and generic compatibility evidence.
- [CITED: `.planning/research/v020-SUMMARY.md`; `.planning/research/v020-PITFALLS.md`] — byte-order, filter, Adam7, resource, and qualification rationale.
- [CITED: `modules/mb-image/png/png_test.mbt`; `stream_decode_test.mbt`; `stream_decode_wbtest.mbt`; `raster_decode.mbt`; `structural.mbt`] — current helpers and the exact unresolved Adam7 profile seam.

### Secondary

- [VERIFIED: local `moon --version`, `moonc -v`, `moonrun --version`, and direct command execution] — installed toolchain and current test-run lock behaviour.

### Tertiary

- None. [VERIFIED: local source inspection]

## Metadata

**Confidence breakdown:**

- Standard stack: LOW — [VERIFIED: `classify-confidence --provider local --verified`] the seam classifies the local provider LOW, although versions were observed directly.
- Architecture: LOW — [VERIFIED: `classify-confidence --provider local --verified`] all seams were source-inspected; no external documentation fetch was required for this codebase-only phase.
- Pitfalls: LOW — [VERIFIED: `classify-confidence --provider local --verified`] derived from direct source and prior verification reports under the same seam classification.

**Research date:** 2026-07-23  
**Valid until:** Implementation completion or any change to the PNG decoder/test helpers, whichever comes first. [CITED: phase scope]
