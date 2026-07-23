# Phase 72: RGBA16 Encode Qualification - Research

**Researched:** 2026-07-23
**Domain:** Public, portable qualification of Type-6/16 PNG encoding
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Independent fidelity proof

- **D-01:** Retain or strengthen deterministic non-symmetric normal and Adam7
  RGBA16 source vectors that independently parse/inflate PNG wire bytes and
  explicitly decode all packed little-endian U16 source lanes. Encoder output
  must not be the sole oracle for either route.
- **D-02:** Exercise both public eager and caller-buffered RGBA16 selector
  families, including explicit Adam7 selection. Cross the legal three
  compression strategies and two filter strategies where existing public
  harnesses already express that matrix.

### Bounded and compatibility behavior

- **D-03:** Qualify hostile public admission and lifecycle behavior without
  changing production semantics: incompatible descriptors and capability,
  output, work, budget, source-revision, and released-lease failures must be
  atomic, acknowledged-only where applicable, tail-safe, and sticky.
- **D-04:** Freeze the established legacy RGB8/RGBA8 and Gray/GrayAlpha normal
  and Adam7 behavior using the smallest existing public compatibility vectors;
  do not widen generic descriptor admission or change legacy byte output.

### Portability and scope

- **D-05:** Run the ordinary full `png` package suite with `--target all` and
  `--frozen`. Keep tests in the existing source package; do not create target
  wrappers, release scripts, copied source trees, or persistent debug/recovery
  build directories.
- **D-06:** Production changes are forbidden unless a public qualification test
  exposes a real contract defect. Any such fix remains narrow, goes through the
  plan's deviation protocol, and does not add staging, FFI, a second pass
  planner, color conversion, or alternate encoder paths.

### the agent's Discretion

- Reuse the closest Phase 55, 58, and 61 public-evidence fixtures, wire parser,
  drain helpers, and frozen compatibility assertions. Prefer the smallest
  tests-only change that closes an actual evidence gap.

### Deferred Ideas (OUT OF SCOPE)

No release automation, registry publishing, target wrappers, source copies,
staging encoder, FFI, color conversion, Big-endian model support, generic
constructor widening, or another encoder/pass planner.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| RGBA16ENC-04 | Independent wire and decode vectors cover normal and Adam7 source fidelity, hostile capability/resource/lease failures, frozen legacy compatibility, and the ordinary full PNG package on wasm, wasm-gc, js, and native. | Strengthen the normal eager Type-6/16 proof with the existing independent Stored-block parser; retain the complete Adam7 parser/decode oracle, hostile public chunk harnesses, literal frozen matrices, and one unwrapped all-target package gate. [VERIFIED: codebase] |
</phase_requirements>

## Summary

Phase 69 establishes normal Type-6/16 lane mapping, Phase 70 establishes the bounded caller-buffered route, and Phase 71 establishes the explicit Adam7 selectors and seven-pass lane restoration. Their verification reports deliberately leave final independent public qualification, compatibility retention, and four-target evidence to Phase 72. [VERIFIED: Phase 69/70/71 verification]

The existing tests already contain almost all required seams. `encode_test.mbt` has non-symmetric packed little-endian normal and 5×5 all-seven-pass sources; `png_encode_gray16_public_stored_scanlines` parses public PNG/Stored-DEFLATE bytes without touching encoder internals; and `PngDecoder::decode_rgba16` verifies all storage lanes. The Adam7 test already combines those pieces; the normal RGBA16 test should be strengthened from position-specific byte checks into a complete independently expected 17-byte filtered scanline assertion. [VERIFIED: codebase]

`stream_encode_test.mbt` already supplies the complete public hostile matrix: both normal and Adam7 schedules cross Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive filters, then test empty/one/ragged caller leases, acknowledged-only totals, untouched `Z` tails, eager parity, and sticky success or typed failures. `png_test.mbt` additionally contains hand-authored normal and Adam7 Type-6/16 decoder literals that are independent of the encoder. [VERIFIED: codebase]

**Primary recommendation:** Make only tests-first public-test changes: normalize the normal eager wire proof to the existing independent parser pattern, retain/re-run the existing Adam7, hostile, and frozen-literal tests, then serially run `moon -C modules/mb-image test png --target all --frozen`. Do not edit production code, build configuration, scripts, FFI, or test-tree layout. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Normal Type-6/16 public wire and lane proof | API / Backend | — | Public `PngEncoder` emits bytes, while the test-local parser and explicit decoder observe the consumer-visible contract. [VERIFIED: codebase] |
| Adam7 Type-6/16 pass and lane proof | API / Backend | — | The exported eager selectors produce the stream; test-local seven-pass enumeration and explicit decode validate it independently. [VERIFIED: codebase] |
| Caller-owned lease safety and terminal behavior | API / Backend | — | `PngChunkEncoder::pull` crosses into caller-owned leases, so public tests own capacity, sentinel-tail, progress, and replay assertions. [VERIFIED: codebase] |
| Four-target package qualification | Build/Test harness | API / Backend | The existing MoonBit package declares js, wasm, wasm-gc, and native; the standard runner invokes the same package suite. [VERIFIED: modules/mb-image/moon.mod.json; VERIFIED: local CLI] |

## Project Constraints (from AGENTS.md)

- Prefer the codebase knowledge graph for code discovery. The safe worktree is not indexed by the available graph MCP, so targeted `rg`/source inspection was the permitted fallback. [VERIFIED: runtime inventory]
- Keep core algorithms and shared data models in MoonBit; portable targets are protected through conformance tests. [VERIFIED: AGENTS.md]
- Keep public operations deterministic and GUI-independent; preserve acyclic module boundaries and explicit compatibility behavior. [VERIFIED: AGENTS.md]
- Do not introduce native FFI, a new dependency, release automation, target wrappers, copied source, staging, or an alternate encoder/pass planner. [VERIFIED: AGENTS.md; VERIFIED: CONTEXT.md]
- Public black-box evidence belongs in existing `*_test.mbt` files. This task writes only the planning research artifact; implementation must remain in the established PNG package tests. [VERIFIED: AGENTS.md; VERIFIED: task scope]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` | Execute focused and all-target PNG package tests. | It is the installed project toolchain and exposes `wasm`, `wasm-gc`, `js`, `native`, and `all`. [VERIFIED: local CLI] |
| Existing `mb-image/png` public APIs | repository HEAD | Exercise eager/chunk RGBA16 construction and explicit decode. | The locked proof boundary is public-only and requires no external package. [VERIFIED: CONTEXT.md; VERIFIED: codebase] |

### Supporting

No package installation, external service, fixture download, FFI, generator, or new test framework is required. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Existing bounded Stored-block parser | A new inflater or encoder-private test hook | Rejected: `png_encode_gray16_public_stored_scanlines` already parses the public envelope and the fixed Stored block without duplicating production traversal. [VERIFIED: codebase] |
| Current public drain helpers | A generic scheduler or target-specific harness | Rejected: local helpers already prove accepted prefixes, tails, progress, eager parity, and sticky outcomes. [VERIFIED: codebase] |
| Literal frozen vectors | Expectations generated by the encoder under test | Rejected: regenerated values can silently rebaseline a regression. [VERIFIED: AGENTS.md; VERIFIED: codebase] |

**Installation:** None — the phase must not install packages. [VERIFIED: CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
non-symmetric LE RGBA16 sources
        |
        +--> public PngEncoder RGBA16 selector (normal / Adam7)
        |         |
        |         +--> Type-6/16 PNG bytes
        |                   |
        |                   +--> Stored/None: public PNG + Stored-block parser
        |                   |                  --> independent normal 17-byte or Adam7 211-byte raster
        |                   |
        |                   +--> PngDecoder::decode_rgba16
        |                                      --> all Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi lanes
        |
        +--> public PngChunkEncoder RGBA16 selector
                  |
                  +--> fresh zero / one / ragged caller leases
                             |
                             +--> accepted prefix + untouched tail + sticky terminal
                                          |
                                          +--> equality with fresh eager peer

literal legacy fixtures --> frozen eager/chunk compatibility matrices
all package tests --> moon test png --target all --> wasm | wasm-gc | js | native
```

### Recommended Project Structure

```text
modules/mb-image/png/
├── encode_test.mbt          # normal and Adam7 eager wire/decode proof; eager frozen vectors
├── stream_encode_test.mbt   # normal and Adam7 caller leases; hostile terminals; chunk frozen vectors
└── png_test.mbt             # hand-authored normal/Adam7 decoder-only Type-6/16 corpus
```

No production file, new fixture, script, wrapper, target directory, or copied tree is warranted. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

### Pattern 1: Complete normal Stored/None scanline oracle

**What:** In `PNG RGBA16 public eager wire and explicit decode fidelity`, retain the two-pixel packed-little-endian source and explicit 16-lane decode loop, but compare `png_encode_gray16_public_stored_scanlines(bytes, 17)` to a test-local expected scanline containing filter `0x00` plus `Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo` for both pixels. [VERIFIED: codebase]

**Why:** Current direct offsets prove the normal lane mapping but do not independently parse/inflate the entire normal raster; matching the Adam7 evidence shape closes that qualification gap. [VERIFIED: codebase; VERIFIED: CONTEXT.md]

```moonbit
// Source pattern: modules/mb-image/png/encode_test.mbt
let expected = b"\x00\x12\x34\xa7\xc5\xbe\x0f\x5a\x76\xde\x89\x43\x21\x87\x65\xcd\xab"
if png_encode_gray16_public_stored_scanlines(bytes, 17) != expected {
  abort("png rgba16 public normal stored raster")
}
```

### Pattern 2: Preserve the existing independent Adam7 oracle

**What:** Retain `png_encode_rgba16_adam7_image`, `png_encode_rgba16_adam7_expected_passes`, and `PNG RGBA16 Adam7 eager wire and explicit decode fidelity`. The 5×5 source makes all seven Adam7 passes nonempty; its independent tuple enumeration expects 211 filtered bytes and the explicit decoder loop checks all 25 × 4 × 2 packed storage lanes. [VERIFIED: codebase]

**When to use:** Stored × None is the literal wire oracle. For the other five legal strategy/filter pairs, assert Type-6/16/Adam7 framing and caller/eager behavior rather than snapshotting filter residuals or compression output. [VERIFIED: codebase; VERIFIED: CONTEXT.md]

### Pattern 3: Reuse normal and Adam7 hostile chunk evidence unchanged

**What:** Keep `PNG RGBA16 chunk public evidence` for non-interlaced output and `PNG RGBA16 Adam7 chunk parity and hostile schedules` for Adam7. Both create fresh encoders for every schedule and strategy pair. [VERIFIED: codebase]

**Required matrix:** `Stored`, `FixedOrStored`, and `DynamicOrFixedOrStored` × `None` and `Adaptive`, each under `[0UL, 1UL]`, `[1UL]`, and `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]`. The test must retain a direct zero-length sublease over a one-byte `Z` owner before normal draining. [VERIFIED: codebase; VERIFIED: CONTEXT.md]

### Pattern 4: Treat legacy literals and decoder corpus as independent anchors

**What:** Preserve `PNG filter strategy eager frozen compatibility vectors` and `PNG filter strategy chunk frozen compatibility vectors` as byte-literal anchors for Gray8, Gray16, GrayAlpha8, GrayAlpha16, RGB8, and straight RGBA8 normal routes. Preserve `png_test_rgba16_literal`, `png_test_rgba16_filters_literal`, and `png_test_rgba16_qualification_adam7_literal` as hand-authored decode inputs. [VERIFIED: codebase]

**When to use:** These tests must never obtain expected bytes from `PngEncoder`; they detect decoder or legacy-output regressions independently of the new encoder output. [VERIFIED: codebase; VERIFIED: CONTEXT.md]

### Anti-Patterns to Avoid

- **Only checking IHDR:** Depth/type/interlace cannot detect channel, endian, or Adam7 placement errors; compare the complete parsed Stored/None raster. [VERIFIED: CONTEXT.md]
- **Using eager/chunk parity as the sole fidelity oracle:** Two paths share the encoder machine; require the independently derived normal and Adam7 scanline expectations and explicit decoder-lane checks. [VERIFIED: CONTEXT.md; VERIFIED: codebase]
- **Reusing a chunk encoder across schedules:** This conceals first-pull and capacity behavior; each schedule needs a fresh public encoder. [VERIFIED: codebase]
- **Appending a whole caller lease:** Only `written()` bytes are owned by the encoder; verify every remaining `Z` byte. [VERIFIED: codebase]
- **Rebaselining a frozen literal:** Any byte drift is a defect to diagnose, not a replacement expectation. [VERIFIED: CONTEXT.md]
- **Running competing all-target suites in parallel:** MoonBit builds share workspace state; serialize the final package command after test changes land. [VERIFIED: Phase 58 research]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| PNG/Stored-DEFLATE test decoding | A new general inflater or private encoder hook | `png_encode_gray16_public_stored_scanlines` | It is a bounded public-byte parser already used by the Adam7 conformance test. [VERIFIED: codebase] |
| Adam7 traversal oracle | A second pass planner | `png_encode_rgba16_adam7_expected_passes` | Its literal seven-tuple loop is independent, compact, and directly targets pass placement. [VERIFIED: codebase] |
| Hostile caller harness | A new cross-file scheduler | `png_stream_rgba16_public_drain` and `png_rgba16_adam7_chunk_drain` | They already encode required progress, tail, parity, and terminal invariants. [VERIFIED: codebase] |
| Portable runner | A wrapper, copied tree, or target-specific script | `moon -C modules/mb-image test png --target all --frozen` | The ordinary package command is the locked evidence boundary. [VERIFIED: CONTEXT.md; VERIFIED: local CLI] |

**Key insight:** Qualification must compose the shipped public encoder/decoder and one existing package command; introducing another transport, parser architecture, or runner weakens the evidence rather than improving it. [VERIFIED: CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Normal evidence is less independent than Adam7 evidence

**What goes wrong:** The normal RGBA16 test validates fixed positions in the encoded PNG, whereas Adam7 validates a complete parsed, independently enumerated scanline payload. [VERIFIED: codebase]

**How to avoid:** Promote normal Stored/None to the same parser-plus-full-raster assertion, then retain the all-16 explicit decoder-lane checks. [VERIFIED: codebase]

### Pitfall 2: Confusing explicit U16 decode with generic RGBA8 decode

**What goes wrong:** Generic decode exposes high-byte compatibility output, not all packed low/high U16 lanes. [VERIFIED: codebase]

**How to avoid:** Use `PngDecoder::decode_rgba16` for every source storage lane; use generic decode only for its established compatibility assertions. [VERIFIED: codebase; VERIFIED: CONTEXT.md]

### Pitfall 3: Missing atomic hostile paths

**What goes wrong:** A success-only schedule test misses rejected descriptor/capability, output/work/budget admission, revision drift, and released-lease terminals. [VERIFIED: CONTEXT.md]

**How to avoid:** Retain the existing `PNG RGBA16 strategy admission is atomic`, `PNG RGBA16 Fixed and Dynamic replay mutations are sticky`, released-lease replay, and Adam7 admission/mutation lifecycle tests. [VERIFIED: codebase]

### Pitfall 4: Treating successful target discovery as target qualification

**What goes wrong:** `moon test --help` confirms accepted target names but does not execute the PNG corpus. [VERIFIED: local CLI]

**How to avoid:** A successful four-target result from the ordinary frozen package command is the final phase gate; do not report portability before that command completes. [VERIFIED: CONTEXT.md]

## Code Examples

### Caller-lease invariant to preserve

```moonbit
let before = output.length().to_uint64()
let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png rgba16 accepted-only progress")
}
for index = pulled.written(); index < capacity; index = index + 1UL {
  if owner.view().get(index).unwrap() != b'Z' { abort("png rgba16 lease tail") }
}
```

The existing normal and Adam7 drains use this shape, append only the returned prefix, compare the completed bytes with a fresh eager peer, and probe a later sentinel lease for a sticky terminal. [VERIFIED: codebase]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Phase 69–71 delivery tests | Phase 72 public qualification | Keep production delivery separate from independent wire, compatibility, and portability proof. [VERIFIED: Phase 69/70/71 verification; VERIFIED: CONTEXT.md] |
| Target-specific or wrapper-based evidence | One frozen public PNG package command with `--target all` | No wrapper lifecycle or copied source tree belongs in this phase. [VERIFIED: CONTEXT.md; VERIFIED: local CLI] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | No implementation assumption is required; the final all-target result must be captured during execution rather than inferred from research. [VERIFIED: CONTEXT.md] | — | — |

## Open Questions

None. The remaining normal-wire proof gap, hostile seams, frozen vectors, target command, and exclusions are explicitly determined by the phase context and current tests. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| `moon` | Focused and full PNG evidence | ✓ | `0.1.20260713` | — [VERIFIED: local CLI] |
| `moon test --target all` | wasm, wasm-gc, js, native package gate | ✓ | help lists all four production targets and `all` | None; run the command to completion. [VERIFIED: local CLI] |
| `modules/mb-image` target declaration | Portable package qualification | ✓ | `+js+wasm+wasm-gc+native` | — [VERIFIED: modules/mb-image/moon.mod.json] |

**Missing dependencies with no fallback:** None. [VERIFIED: local CLI]

## Security Domain

`security_enforcement` is not explicitly disabled, so this section applies. The phase adds no production trust boundary; its relevant controls are public input/admission validation and caller-owned lease integrity. [VERIFIED: .planning/config.json; VERIFIED: CONTEXT.md]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity behavior changes. [VERIFIED: CONTEXT.md] |
| V3 Session Management | no | No session state changes. [VERIFIED: CONTEXT.md] |
| V4 Access Control | no | No authorization surface changes. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Public tests retain descriptor/capability/resource rejection, caller capacity, source revision, and released-lease checks. [VERIFIED: CONTEXT.md; VERIFIED: codebase] |
| V6 Cryptography | no | No cryptographic primitive changes. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for the Evidence

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| U16 lane or Adam7 scatter regression hidden by symmetric source data | Tampering | Use non-symmetric normal and 5×5 all-pass sources with independent full-raster expectations. [VERIFIED: codebase] |
| Caller-tail overwrite or inflated total | Tampering | Assert accepted-prefix arithmetic, every unaccepted `Z` tail, and later sticky terminal leases. [VERIFIED: codebase] |
| Frozen compatibility baseline replaced from current output | Tampering | Preserve literal eager/chunk byte anchors and hand-authored decoder corpora. [VERIFIED: codebase; VERIFIED: CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `72-CONTEXT.md`, `ROADMAP.md`, and `REQUIREMENTS.md` — locked Phase 72 scope, exclusions, success criteria, and `RGBA16ENC-04`. [VERIFIED: phase artifacts]
- `69-VERIFICATION.md`, `70-VERIFICATION.md`, and `71-VERIFICATION.md` — completed normal, caller-buffered, and Adam7 RGBA16 delivery boundaries. [VERIFIED: phase artifacts]
- `55-*`, `58-*`, and `61-*` historical context/research/verification artifacts — public wire/parser, hostile-drain, frozen-vector, and all-target qualification precedents. [VERIFIED: phase artifacts]
- `modules/mb-image/png/encode_test.mbt` — normal/Adam7 fixtures, independent parser, explicit decode checks, and eager frozen vectors. [VERIFIED: codebase]
- `modules/mb-image/png/stream_encode_test.mbt` — normal/Adam7 hostile drains, admission, replay, released-lease, and chunk frozen vectors. [VERIFIED: codebase]
- `modules/mb-image/png/png_test.mbt` — independent hand-authored normal/Adam7 Type-6/16 decoder corpus. [VERIFIED: codebase]
- `modules/mb-image/moon.mod.json` and local `moon test --help` — declared portable targets and ordinary command interface. [VERIFIED: codebase; VERIFIED: local CLI]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — installed toolchain and module target declaration agree. [VERIFIED: local CLI; VERIFIED: modules/mb-image/moon.mod.json]
- Architecture: HIGH — locked context, predecessor verification, and current public test seams agree. [VERIFIED: CONTEXT.md; VERIFIED: Phase 69/70/71 verification; VERIFIED: codebase]
- Pitfalls: HIGH — each is directly represented by an existing test seam or the identified normal parser gap. [VERIFIED: codebase]

**Research date:** 2026-07-23
**Valid until:** 2026-08-22, unless the public PNG API, test seam, or MoonBit runner changes. [ASSUMED]
