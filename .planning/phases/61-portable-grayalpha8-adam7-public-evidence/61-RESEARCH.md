# Phase 61: Portable GrayAlpha8 Adam7 Public Evidence - Research

**Researched:** 2026-07-23  
**Domain:** Public MoonBit PNG conformance evidence for GrayAlpha8 Adam7  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Use a non-symmetric all-seven-pass `G,A` image and independently
  enumerate/inflate the Adam7 raster before proving decode canonicalization as
  `(G,G,G,A)`; do not rely on encoder internals as the sole oracle.
- **D-02:** For a fresh public caller-buffered Adam7 encoder, prove zero, one,
  and ragged lease schedules preserve eager bytes, accepted-only counters,
  untouched lease tails, and sticky terminal behavior.
- **D-03:** Run the ordinary frozen full PNG package command on each supported
  production target. Retain current GrayAlpha8 non-interlaced and Gray8,
  Gray16, GrayAlpha16, RGB8, and straight-RGBA8 compatibility vectors.

### the agent's Discretion

- Reuse established public fixture/drain helpers and keep scope to evidence and
  regressions; no new production encoder/decoder capability is permitted.

### Deferred Ideas (OUT OF SCOPE)

No decoder widening, Big-endian model work, staging, alternate encoders, native
FFI, release automation, registry work, target wrappers, or source copies.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| GRAYA8A7-03 | Public non-symmetric Adam7 Type-4/8 wire/decode vectors, fresh zero/one/ragged caller schedules, frozen non-interlaced/legacy vectors, and the full PNG package pass on js, wasm, wasm-gc, and native. | Reuse the existing five-by-five Type-4/8 pass enumerator and Stored-block parser for the wire oracle; mirror the GrayAlpha16 Adam7 caller-lease driver for GrayAlpha8; retain literal eager/chunk frozen-vector matrices; run the ordinary package command with `--target all`. [VERIFIED: codebase; VERIFIED: local CLI] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Prefer the codebase knowledge graph for code discovery; its MCP tools are unavailable in this runtime, so the research used targeted `rg` fallback. [VERIFIED: runtime tool inventory]
- Keep shared algorithms and data models in MoonBit; portable conformance must be deliberate, and native stubs/FFI must remain isolated. This evidence-only phase must add neither production logic nor FFI. [VERIFIED: AGENTS.md; VERIFIED: CONTEXT.md]
- Preserve acyclic public package boundaries, deterministic public operations, reproducible evidence, SemVer-compatible public behavior, and declared performance workloads. The phase therefore uses existing package tests and frozen literals rather than new APIs or generated expectations. [VERIFIED: AGENTS.md; VERIFIED: CONTEXT.md]
- Public package black-box tests are `*_test.mbt`; keep Phase 61 work in the existing PNG public test files. [VERIFIED: AGENTS.md]
- Do not add GUI state, release/registry automation, target wrappers, copied source, or a new module dependency. [VERIFIED: AGENTS.md; VERIFIED: CONTEXT.md]

## Summary

Phase 59 already supplies the correct non-symmetric 5×5 GrayAlpha8 Adam7 source (`gray = 0x20 + y*5+x`, `alpha = 0xA0 + y*5+x`) and an independent seven-pass `G,A` Stored/None raster enumerator. The existing `PNG GrayAlpha8 Adam7 eager pass profile` test asserts IHDR depth `8`, colour type `4`, interlace method `1`, and compares the extracted 61-byte inflated scanline payload to that independent oracle. Phase 61 should extend this exact evidence path with a public decoder oracle that checks all 25 pixels as `(G,G,G,A)`, rather than inventing an encoder-side or private-cursor test. [VERIFIED: codebase; VERIFIED: Phase 59 summary]

The closest caller-buffered precedent is `png_graya16_adam7_chunk_drain`. It starts with a sentinel-backed zero-length lease, constructs a fresh public encoder for every schedule, appends only `written()` bytes, validates `total_written == previously_accepted + written`, checks every unaccepted lease byte remains `Z`, compares the completed stream with a fresh eager peer, and makes a later sentinel pull prove sticky `Finished`. Copy that local shape for `PngChunkEncoder::new_graya8_with_all_strategies` across the existing six compression/filter pairs and the locked zero/one/ragged schedules. [VERIFIED: codebase; VERIFIED: Phase 52 verification]

**Primary recommendation:** make two test-only edits—one eager wire/public-decode test and one GrayAlpha8 Adam7 hostile-schedule helper/test—then retain the existing literal compatibility matrices and run `moon -C modules/mb-image test png --target all --frozen`. [VERIFIED: codebase; VERIFIED: local CLI]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Type-4/8 Adam7 serialized raster evidence | API / Backend | — | Public `PngEncoder` produces the bytes; the test independently enumerates expected PNG pass rows instead of inspecting the encoder cursor. [VERIFIED: codebase; CITED: https://www.w3.org/TR/png-3/] |
| GrayAlpha8 decode canonicalization | API / Backend | — | Public `PngDecoder` owns the observable decoded image; test evidence must check `R=G=B` and source alpha through that façade. [VERIFIED: codebase] |
| Caller-owned lease safety and progress | API / Backend | — | Public `PngChunkEncoder::pull` returns accepted progress while each test-owned mutable lease exposes tail ownership. [VERIFIED: codebase] |
| Portable qualification | Build/Test harness | API / Backend | The MoonBit package declares js, wasm, wasm-gc, and native support, and `moon test --target all` names those targets. [VERIFIED: codebase; VERIFIED: local CLI; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` | Execute the existing PNG package test suite. | The local project toolchain exposes `wasm`, `wasm-gc`, `js`, `native`, and `all` through `moon test --help`. [VERIFIED: local CLI] |
| Existing `mb-image/png` public API | repository HEAD | Create eager/chunk GrayAlpha8 Adam7 output and decode it. | Locked decisions require public selectors only; the selectors already route to the shared profile-aware machine. [VERIFIED: CONTEXT.md; VERIFIED: codebase] |

### Supporting

No external packages are required, installed, or recommended. [VERIFIED: codebase]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Existing test-local Stored-block parser | New generic inflater/test framework | Rejected: the current bounded parser is sufficient for the 61-byte Stored/None oracle and avoids a broader test utility. [VERIFIED: codebase] |
| Existing GrayAlpha16 Adam7 drain pattern | New generic streaming abstraction | Rejected: it would duplicate accepted-byte/lease ownership logic and expand a test-only evidence phase. [VERIFIED: codebase; VERIFIED: CONTEXT.md] |
| Literal frozen vectors | Expectations emitted by the current encoder | Rejected: regenerated expectations can normalize a regression. [VERIFIED: AGENTS.md; VERIFIED: codebase] |

**Installation:** None — this phase installs no package. [VERIFIED: codebase]

## Architecture Patterns

### System Architecture Diagram

```text
5x5 non-symmetric GrayAlpha8 source
        |
        +--> public PngEncoder::new_graya8_with_all_strategies(Stored, None, Adam7)
        |         |
        |         +--> PNG bytes --> existing Stored-block parser --> independent 7-pass G,A oracle
        |         |                                                |
        |         |                                                +--> exact 61-byte raster equality
        |         |
        |         +--> public PngDecoder --> 5x5 RGBA8 --> (G,G,G,A) per-pixel oracle
        |
        +--> fresh public PngChunkEncoder::new_graya8_with_all_strategies
                  |
                  +--> zero / one / ragged sentinel leases
                            |
                            +--> accepted prefix + untouched tail + sticky Finished
                                      |
                                      +--> byte equality with fresh eager peer

same package tests --> moon test png --target all --> js | wasm | wasm-gc | native
```

The data flow intentionally stays at exported encoder/decoder APIs; only the expected raster is test-local and independent. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

### Recommended Project Structure

```text
modules/mb-image/png/
├── encode_test.mbt          # add GrayAlpha8 Adam7 Stored/None wire + public decode evidence
└── stream_encode_test.mbt   # add GrayAlpha8 Adam7 fresh hostile schedule evidence
```

Do not create fixtures, scripts, wrappers, production files, or new test modules. [VERIFIED: CONTEXT.md; VERIFIED: Phase 49 verification]

### Pattern 1: Independent Stored/None wire oracle plus public decode

**What:** Reuse `png_encode_graya8_adam7_image`, `png_encode_graya8_adam7_expected_passes`, and `png_encode_gray16_public_stored_scanlines`. Add a 5×5 GrayAlpha8 Adam7 public-decode helper patterned on `png_encode_graya16_adam7_public_decode_is_canonical`; it must compute expected components from `(x,y)`, not from encoder state. [VERIFIED: codebase]

**When to use:** Exactly once for `Stored × None × Adam7`. Stored/None makes the raster deterministic and the existing parser extracts the 61 bytes without an encoder-internal oracle. All six pairs are appropriate for framing and schedule identity, not a full raw-payload snapshot. [VERIFIED: codebase]

```moonbit
// Source pattern: modules/mb-image/png/encode_test.mbt
let expected = Bytes::from_array(png_encode_graya8_adam7_expected_passes())
let bytes = png_encode_prefix(writer)
if bytes[24] != b'\x08' || bytes[25] != b'\x04' || bytes[28] != b'\x01' {
  abort("png graya8 Adam7 public framing")
}
if png_encode_gray16_public_stored_scanlines(bytes, 61) != expected {
  abort("png graya8 Adam7 public pass raster")
}
png_encode_graya8_adam7_public_decode_is_canonical(bytes)
```

The PNG specification defines colour type 4 as greyscale-with-alpha, with 8-bit depth allowed; samples are grey then alpha, and Adam7 is interlace method 1 with seven passes. [CITED: https://www.w3.org/TR/png-3/]

### Pattern 2: Fresh encoder per hostile schedule

**What:** Mirror `png_graya16_adam7_chunk_drain`, substituting only GrayAlpha8 eager/chunk public factories and the existing all-seven-pass source. The helper owns its fresh encoder, output array, lease sentinels, accepted-only arithmetic, tail check, eager comparison, and later sticky-terminal check. [VERIFIED: codebase]

**When to use:** For every `Stored`, `FixedOrStored`, and `DynamicOrFixedOrStored` × `None` and `Adaptive` selection, run `[0UL, 1UL]`, `[1UL]`, and `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]`; before each schedule matrix, use a fresh encoder with an empty sublease of a one-byte `Z` owner. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

```moonbit
// Source pattern: modules/mb-image/png/stream_encode_test.mbt
let before = output.length().to_uint64()
let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png graya8 adam7 accepted-only progress")
}
for index = pulled.written(); index < capacity; index = index + 1UL {
  if owner.view().get(index).unwrap() != b'Z' { abort("png graya8 adam7 lease tail") }
}
```

### Pattern 3: Retain frozen compatibility literals in place

**What:** Keep the literal eager and chunk vector matrices in `PNG filter strategy eager frozen compatibility vectors` and `PNG filter strategy chunk frozen compatibility vectors`. They already cover non-interlaced Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8; add GrayAlpha16 literal assertions only if the existing matrix lacks the required frozen route, without rewriting unrelated vector construction. [VERIFIED: codebase; VERIFIED: CONTEXT.md]

**When to use:** Run these existing named tests as focused regression checks and as part of the full package gate. [VERIFIED: codebase]

### Anti-Patterns to Avoid

- **Using the encoder cursor as the Adam7 oracle:** It cannot independently detect traversal or component-order regressions; enumerate the seven geometry tuples in test code. [VERIFIED: CONTEXT.md; VERIFIED: codebase]
- **Reusing a completed chunk encoder:** It omits the fresh zero-capacity/progress contract for later schedules. [VERIFIED: Phase 52 verification]
- **Appending entire caller leases:** It hides accepted-only accounting and tail mutation; append exactly `written()` bytes and inspect the rest. [VERIFIED: codebase]
- **Snapshotting Fixed/Dynamic/Adaptive payloads:** Filter residuals and compression plans may legitimately change; keep literal raw-wire proof to Stored/None and use eager/chunk equality for the six-pair matrix. [VERIFIED: Phase 49 research]
- **Adding a wrapper, staging path, copied implementation, or target branch:** All are outside the locked boundary and are not needed for the ordinary package command. [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| PNG raster inflater | A general DEFLATE utility or production decoder hook | `png_encode_gray16_public_stored_scanlines` | It already validates the fixture-sized zlib Stored block and returns just the independent scanline payload. [VERIFIED: codebase] |
| Hostile caller scheduler | A generic cross-file driver | Local GrayAlpha16 Adam7 drain shape | It already embodies fresh encoders, counters, sentinel tails, and sticky terminal checks. [VERIFIED: codebase] |
| Four-target runner | PowerShell wrapper or copied target suites | `moon -C modules/mb-image test png --target all --frozen` | The project package declares all four production targets and MoonBit accepts `all`. [VERIFIED: codebase; VERIFIED: local CLI] |

**Key insight:** the phase proves consumer-visible behavior; it should compose existing public APIs and test helpers, not create another encoding, inflation, or execution path. [VERIFIED: CONTEXT.md]

## Common Pitfalls

### Pitfall 1: A seven-pass source does not by itself prove consumer decode

**What goes wrong:** The existing `eager pass profile` checks a correct independent wire raster but does not assert the 5×5 public decoder result for GrayAlpha8 Adam7. [VERIFIED: codebase]

**How to avoid:** Add a per-pixel public decoder helper parallel to GrayAlpha16: descriptor must be 5×5 `Rgba` U8, `R/G/B = 0x20 + y*5+x`, and `A = 0xA0 + y*5+x`. [VERIFIED: codebase]

### Pitfall 2: Empty lease checks can be masked by a zero-capacity owner

**What goes wrong:** A zero-length owner cannot prove the owner buffer remained untouched. [VERIFIED: Phase 52 verification]

**How to avoid:** Allocate one byte filled with `Z` and pass only its `0UL, 0UL` sublease; assert `NeedOutput`, zero counters, and retained `Z`. [VERIFIED: codebase]

### Pitfall 3: Tail ownership is missed on exact-capacity turns

**What goes wrong:** One-byte-only drains provide no lease tail to inspect. [VERIFIED: codebase]

**How to avoid:** Run the locked ragged capacities and inspect every byte from `written()` to `capacity`; retain the later 7-byte sentinel check after `Finished`. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

### Pitfall 4: Frozen compatibility is weakened by deriving expected bytes

**What goes wrong:** Current output used as expected data turns a byte regression into an accepted baseline. [VERIFIED: AGENTS.md]

**How to avoid:** Keep literal byte constants in both existing eager/chunk matrices; include the required GrayAlpha16 literal in the same local matrices if it is absent. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

### Pitfall 5: Misreporting portability from an incomplete command

**What goes wrong:** A local all-target run started during this research exceeded the first 120-second command allowance and the longer run was interrupted before it produced a pass/fail result. It is not evidence that the current Phase 61 baseline passes. [VERIFIED: local execution]

**How to avoid:** Treat the ordinary all-target command as the mandatory implementation/phase gate and record all four target outcomes from its completed invocation. [VERIFIED: CONTEXT.md; VERIFIED: local CLI]

## Code Examples

### Required public decoder oracle shape

```moonbit
// Source pattern: png_encode_graya16_adam7_public_decode_is_canonical
for y = 0UL; y < 5UL; y = y + 1UL {
  for x = 0UL; x < 5UL; x = x + 1UL {
    let sample = y * 5UL + x
    let gray = (b'\x20'.to_uint64() + sample).to_byte()
    let alpha = (b'\xa0'.to_uint64() + sample).to_byte()
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      if restored.get_byte(x, y, channel).unwrap() != gray { abort("decoded grayscale") }
    }
    if restored.get_byte(x, y, 3UL).unwrap() != alpha { abort("decoded alpha") }
  }
}
```

This derives expected output from the source coordinate formula and checks only the public decode route. [VERIFIED: codebase]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Early Adam7 evidence used target-specific wrapper execution. | The locked Phase 61 decision is one ordinary frozen PNG package command with `--target all`. | No release automation, wrapper lifecycle, or target-specific source belongs in this phase. [VERIFIED: CONTEXT.md; VERIFIED: local CLI] |
| Narrow GrayAlpha8 Adam7 checks proved framing/raster or ordinary parity separately. | Combine existing independent raster evidence with public decode and hostile caller schedules. | The result directly covers the remaining GRAYA8A7-03 observable contract. [VERIFIED: Phase 59 summary; VERIFIED: Phase 60 verification] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The full all-target command will complete within the implementation environment once given sufficient CI/runner time. The local research run was interrupted before completion. [ASSUMED] | Environment Availability | The planner must treat a completed all-target run as a hard gate, not assume a pass. |

## Open Questions

1. **Does the frozen matrix already contain a literal GrayAlpha16 non-interlaced vector?**
   - What we know: the current eager/chunk frozen matrices have literal Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 vectors; direct search found no GrayAlpha16 literal in those matrices. [VERIFIED: codebase]
   - What's unclear: whether another existing public frozen test is the approved GrayAlpha16 baseline. [VERIFIED: codebase]
   - Recommendation: planner should make a narrow literal GrayAlpha16 addition beside the existing eager/chunk matrices if the focused inspection confirms no approved literal exists; do not generate it at runtime. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| `moon` | Compile/run PNG evidence | ✓ | `moon 0.1.20260713` | — [VERIFIED: local CLI] |
| `moon test --target all` | js, wasm, wasm-gc, native gate | ✓ | Help lists `wasm`, `wasm-gc`, `js`, `native`, `all` | None; complete the ordinary command. [VERIFIED: local CLI] |
| `modules/mb-image/png` target declaration | Portable package qualification | ✓ | `+js+wasm+wasm-gc+native` | — [VERIFIED: codebase] |

**Missing dependencies with no fallback:** None. [VERIFIED: local CLI]

**Execution note:** The ordinary full-suite command was started twice during research; the first exceeded a 120-second tool timeout and the second was interrupted before output. The phase plan must re-run it to completion and capture its result. [VERIFIED: local execution]

## Security Domain

The configuration does not explicitly disable security enforcement, so this section applies. Phase 61 adds no production trust boundary; its security-relevant value is regression evidence for caller-owned lease integrity and deterministic public data handling. [VERIFIED: .planning/config.json; VERIFIED: CONTEXT.md]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity behavior is added. [VERIFIED: CONTEXT.md] |
| V3 Session Management | no | No session state is added. [VERIFIED: CONTEXT.md] |
| V4 Access Control | no | No authorization behavior is added. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Validate zero/one/ragged caller capacities, accepted-only totals, untouched tails, and sticky outcomes through public APIs. [VERIFIED: CONTEXT.md; VERIFIED: codebase] |
| V6 Cryptography | no | No cryptographic primitive is added or changed. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for the Evidence

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Grey/alpha order or Adam7 pass regression hidden by symmetric data | Tampering | Use the existing non-symmetric 5×5 source and independently enumerated `G,A` seven-pass raster. [VERIFIED: codebase; CITED: https://www.w3.org/TR/png-3/] |
| Caller lease tail write or inflated completion count | Tampering | Assert only accepted prefixes, all unaccepted `Z` tails, exact counter arithmetic, and later sticky terminal leases. [VERIFIED: codebase] |
| Frozen compatibility baseline rewritten from current output | Tampering | Keep literal vectors in eager/chunk tests; never emit expected data with the encoder under test. [VERIFIED: AGENTS.md; VERIFIED: codebase] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/encode_test.mbt` — current 5×5 GrayAlpha8 Adam7 fixture, independent pass enumeration, Stored-block parser, public decoder helpers, and frozen eager vectors. [VERIFIED: codebase]
- `modules/mb-image/png/stream_encode_test.mbt` — current GrayAlpha16 Adam7 hostile drain, GrayAlpha8 public drain, caller lease owners, and frozen chunk vectors. [VERIFIED: codebase]
- `.planning/phases/59-grayalpha8-adam7-factory-and-pass-profile/59-01-SUMMARY.md`, `59-02-SUMMARY.md` — established GrayAlpha8 selectors, independent raster proof, and six-pair ordinary parity handoff. [VERIFIED: phase artifacts]
- `.planning/phases/60-bounded-adam7-streaming-semantics/60-VERIFICATION.md` and `60-01-SUMMARY.md` — shared six-pair replay/admission handoff and pre-lease revision guarantee. [VERIFIED: phase artifacts]
- `modules/mb-image/png/moon.pkg` and local `moon test --help` — portable target declaration and ordinary command interface. [VERIFIED: codebase; VERIFIED: local CLI]

### Secondary (MEDIUM confidence)

- [PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — colour type 4 sample ordering, 8-bit legality, Adam7 seven-pass interlace, and filtering model. [CITED: https://www.w3.org/TR/png-3/]
- [MoonBit command-line help](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — supported `moon test --target` names, including `all`. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]

### Tertiary (LOW confidence)

- The all-target completion time is unverified in this research session because the command was interrupted; this is recorded as A1. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — local toolchain help and package target declaration agree. [VERIFIED: local CLI; VERIFIED: codebase]
- Architecture: HIGH — locked context, Phase 59/60 handoffs, and current public test seams agree. [VERIFIED: CONTEXT.md; VERIFIED: phase artifacts; VERIFIED: codebase]
- Pitfalls: HIGH — each is demonstrated by the existing GrayAlpha16 or prior GrayAlpha8 public-evidence patterns. [VERIFIED: codebase; VERIFIED: Phase 52 verification]

**Research date:** 2026-07-23  
**Valid until:** 2026-08-22 for the stable internal test shape; re-check on a MoonBit or PNG API change. [ASSUMED]
