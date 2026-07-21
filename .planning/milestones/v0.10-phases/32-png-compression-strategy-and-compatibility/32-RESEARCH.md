# Phase 32: PNG Compression Strategy and Compatibility - Research

**Researched:** 2026-07-22  
**Domain:** Additive MoonBit PNG encoder API and byte-compatibility boundary  
**Confidence:** HIGH

## User Constraints

No `CONTEXT.md` exists for Phase 32. The approved roadmap, PNGC-01, current public-policy snapshot, and archived v0.9 encoder evidence define the scope. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `policy/foundation.json`, `.planning/milestones/v0.9-phases/31-portable-png-encode-evidence/31-VERIFICATION.md`]

### Locked Decisions

- Add an explicit public opt-in compression choice; do not change either legacy constructor's default. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- `PngEncoder::new()` and `PngChunkEncoder::new(...)` must keep their byte-for-byte stored-DEFLATE output. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{png.mbt,stream_encode.mbt}`]
- Dynamic Huffman, adaptive filters, a 32 KiB LZ77 dictionary, FFI codecs, host-stream adapters, APNG, colour-transform work, and metadata expansion remain outside v0.10. [VERIFIED: codebase: `.planning/ROADMAP.md`]

### the agent's Discretion

- Resolve the public strategy/type and factory names, provided they are additive, auditable in the exact generated-interface policy, and make the stored baseline distinguishable from the future optimized choice. [VERIFIED: codebase: `.planning/ROADMAP.md`, `policy/foundation.json`, `policy/compatibility.json`]

### Deferred Ideas (OUT OF SCOPE)

- Actual fixed-Huffman-or-stored planning/emission, exact optimized admission, optimized eager/chunk drain parity, and fixed-output progress behavior belong to Phase 33. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- Corpus fixtures, four-target compression measurements, and the never-larger/win assertions belong to Phase 34. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PNGC-01 | A library user can explicitly request a documented PNG compression strategy while the existing eager and chunk constructors retain their byte-for-byte stored-DEFLATE output. | Publish one enum and two named configured factories; keep both existing constructors unmodified and assert their full bytes against the stored baseline. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{png.mbt,encode_test.mbt,stream_encode_test.mbt}`] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models stay in MoonBit; native stubs, if ever required, must be small, isolated, documented, and replaceable. [VERIFIED: `AGENTS.md`]
- PNG must remain modular, portable across js/wasm/wasm-gc/native through explicit capability boundaries, deterministic, and usable without GUI/host state. [VERIFIED: `AGENTS.md`, `modules/mb-image/png/moon.pkg`]
- Public packages have acyclic documented dependencies; the PNG package's allowed imports and four supported targets are policy-controlled. [VERIFIED: `AGENTS.md`, `policy/foundation.json`]
- Candidate public changes require documented migration notes; stable APIs follow SemVer. [VERIFIED: `AGENTS.md`, `policy/foundation.json`]
- Before implementation, use the project code graph when available for code discovery; this research fell back to targeted text inspection because no graph MCP tool was exposed to this agent. [VERIFIED: `AGENTS.md`]

## Summary

The existing PNG encoder has one private, canonical stored-DEFLATE byte source. `PngEncoder::new()` is an empty value used through `ImageEncoder::encode`; `PngChunkEncoder::new(source, limits, budget, diagnostics)` constructs the same `PngEncodeMachine`, and its pull wrapper only transfers acknowledged bytes. The private machine writes zlib `78 01`, filter-None scanlines, stored blocks, Adler-32, and PNG framing. The archived v0.9 verification proved current eager/chunk equality, exact progress, sticky terminals, and four-target behavior. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt,encode_test.mbt,stream_encode_test.mbt}`, `.planning/milestones/v0.9-phases/31-portable-png-encode-evidence/31-VERIFICATION.md`]

Phase 32 should therefore add a selection seam only: two new factories retain an explicit `PngCompressionStrategy` in the encoder/machine state while both legacy constructors keep instantiating `Stored`. The `FixedOrStored` branch must remain a stored-emission alias in this phase; Phase 33 alone may replace that branch with exact optimized planning and fixed-Huffman-or-stored emission. This lets callers express the intended contract without silently changing an existing output representation. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}`]

**Primary recommendation:** Add `PngCompressionStrategy::{Stored, FixedOrStored}` plus `new_with_compression_strategy` factories for eager and chunk encoders; update only the PNG semantic-interface policy and lock the two legacy constructors to current full stored-DEFLATE bytes. [VERIFIED: codebase: `policy/foundation.json`, `policy/compatibility.json`, `modules/mb-image/png/{png.mbt,encode_test.mbt,stream_encode_test.mbt}`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Public strategy selection | Library API / codec package | Compatibility policy | It is a public MoonBit contract that selects encoder construction, rather than image processing or host I/O. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`, `policy/foundation.json`] |
| Legacy stored-byte preservation | PNG emitter | Black-box tests | Existing constructors reach the canonical stored emitter; full byte assertions prevent an accidental routing change. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt,encode_test.mbt,stream_encode_test.mbt}`] |
| Exact public-interface registration | Policy / quality tier | Generated MBTI | `foundation.json` records the normalized interface and the quality lane compares it exactly with generated package interfaces. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/Invoke-MoonQuality.ps1`] |
| Fixed-or-stored planning and emission | PNG emitter | Public eager/chunk adapters | It changes byte construction and must wait for Phase 33's bounded plan, not be implemented in the factory phase. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`] |

## Standard Stack

### Core

| Library / component | Version | Purpose | Why standard |
|---|---:|---|---|
| MoonBit `tchivs/mb-image/png` | repository source | Public strategy enum/factories and existing stored encoder | It already owns PNG API, source admission, frame/checksum logic, and all four declared targets. [VERIFIED: codebase: `modules/mb-image/png/{moon.pkg,png.mbt,encode.mbt,stream_encode.mbt}`] |
| `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Compile and run target-specific tests | These are the locally installed project toolchain versions. [VERIFIED: local `moon --version`, `moonc -v`, `moonrun --version`] |
| Foundation interface policy | repository policy | Exact public-surface and source-inventory gate | The PNG package has a declared candidate API, import allowlist, source list, and target set. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/Invoke-MoonQuality.ps1`] |

### Supporting

| Component | Purpose | When to use |
|---|---|---|
| `encode_test.mbt` | Frozen eager stored-DEFLATE byte oracle | Preserve `PngEncoder::new()` output exactly. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt`] |
| `stream_encode_test.mbt` | Public caller-buffered drain, parity, and terminal evidence | Add the legacy chunk full-byte assertion and configured-factory construction checks. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt`] |
| `Invoke-PngEncodeEvidence.ps1` | Existing selected four-target encoder evidence runner | Reuse unchanged in Phase 33/34 evidence work; Phase 32 does not need a new runner. [VERIFIED: codebase: `scripts/quality/Invoke-PngEncodeEvidence.ps1`, `.planning/ROADMAP.md`] |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|---|---|---|
| Explicit configured factories | Add a compression field to generic `@codec.EncodeOptions` | Rejected: codec options are shared across formats, while the requirement is PNG-specific and current `PngChunkEncoder::new` is a direct public construction path. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`, `modules/mb-image/png/{png.mbt,stream_encode.mbt}`, `.planning/REQUIREMENTS.md`] |
| `PngCompressionStrategy` with `Stored` and `FixedOrStored` | Boolean `optimized` switch | Rejected: a boolean cannot document the preserved stored baseline and leaves no safe namespace for later additive choices. This is an implementation recommendation informed by the named roadmap strategy. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`] |
| Preserve legacy constructors | Change the default of `new` | Rejected by PNGC-01 and the milestone scope boundary. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`] |

**Installation:** No external packages are required or permitted for this phase. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `.planning/ROADMAP.md`]

## Package Legitimacy Audit

Not applicable: Phase 32 installs no package and must not add FFI, host codec, or dependency. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/moon.pkg`]

## Architecture Patterns

### System Architecture Diagram

```text
Legacy eager caller                Legacy chunk caller
PngEncoder::new()                 PngChunkEncoder::new(...)
        |                                   |
        +----------- Stored ----------------+
                                            |
                                  PngEncodeMachine (existing)
                                            |
                         canonical zlib stored-DEFLATE PNG bytes

Opt-in eager/chunk caller
new_with_compression_strategy(FixedOrStored)
        |
        v
PngCompressionStrategy retained in configured encoder/machine
        |
        +--> Phase 32: stored-emission alias only
        `--> Phase 33: exact Fixed-or-Stored plan then emission
```

The Phase 32 branch point is before construction; it must not be inserted into either legacy constructor's path. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`, `.planning/ROADMAP.md`]

### Recommended Public Contract

Use this exact additive surface in `png.mbt` and mirror its generated normalized form in `policy/foundation.json`:

```moonbit
pub(all) enum PngCompressionStrategy {
  Stored
  FixedOrStored
} derive(Eq)

pub fn PngEncoder::new_with_compression_strategy(
  strategy : PngCompressionStrategy,
) -> PngEncoder

pub fn PngChunkEncoder::new_with_compression_strategy(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError]
```

`Stored` is the named baseline; `FixedOrStored` names the only supported future optimized policy and deliberately does not promise dynamic Huffman or adaptive filtering. `new_with_compression_strategy` follows the repository's established `new_with_*` constructor convention and gives the chunk path the same explicit selector as the eager path. [VERIFIED: codebase: `policy/foundation.json`, `modules/mb-image/storage/owned_image.mbt`, `.planning/ROADMAP.md`]

Keep the existing declarations byte-for-byte and signature-for-signature unchanged:

```moonbit
pub fn PngEncoder::new() -> PngEncoder
pub fn PngChunkEncoder::new(
  @storage.ImageView, @codec.CodecLimits, @budget.Budget, @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError]
```

These constructors must hard-code `PngCompressionStrategy::Stored`; do not implement either as a default argument, an ambient setting, or a call to the configured factory. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`, `scripts/quality/Invoke-MoonQuality.ps1`, `.planning/REQUIREMENTS.md`]

### Recommended Internal Shape

- Add a private `strategy : PngCompressionStrategy` field to `PngEncoder`, `PngChunkEncoder` state or the private `PngEncodeMachine`; route configured and legacy constructors through one private strategy-aware machine constructor. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`]
- Keep `PngEncodeMachine::zlib_byte`, stored block arithmetic, CRC/Adler acknowledgement, pull lifecycle, and eager writer loop unchanged in Phase 32. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]
- In Phase 32, both enum values use the existing stored-byte path after selection. The factory must document that `FixedOrStored` is the opt-in strategy whose encoding behavior arrives in Phase 33; do not make a performance or size claim yet. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

### Policy and Compatibility Update

- Update the PNG `semantic_interface` array in `policy/foundation.json` with the enum, both cases, and both exact factory signatures; leave `production_sources`, `allowed_imports`, and `supported_targets` unchanged if implementation stays in `png.mbt`/`stream_encode.mbt`. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/Invoke-MoonQuality.ps1`]
- Do **not** edit `policy/compatibility.json`: its existing classifier already defines an addition with all baseline declarations retained as `additive`, requiring a minor release and added-surface report only when a release is prepared. [VERIFIED: codebase: `policy/compatibility.json`]
- The public diff is additive only if all existing normalized PNG declarations remain unchanged on all four targets; a changed legacy signature or removed declaration is incompatible under the existing policy. [VERIFIED: codebase: `policy/compatibility.json`]

### Anti-Patterns to Avoid

- **Changing `new` to choose an optimized default:** violates PNGC-01 even if produced images decode correctly. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`]
- **Using a generic codec option or hidden global:** obscures the PNG-specific choice and triggers the quality lane's hidden-default prohibition. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt`, `scripts/quality/Invoke-MoonQuality.ps1`]
- **Implementing fixed output in the factory phase:** moves exact admission, emission, and parity obligations from Phase 33 into Phase 32. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- **Testing legacy eager/chunk parity only against each other:** both paths could regress identically; retain a frozen stored-byte oracle for each legacy path. [VERIFIED: codebase: `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`]

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| New PNG byte emitter | A second factory-local zlib/PNG formatter | Existing `PngEncodeMachine` stored path | It already owns framing, stored block arithmetic, CRC, Adler, source admission, and byte acknowledgement. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |
| New public configuration framework | Generic registry or global option store | `PngCompressionStrategy` plus explicit factories | The strategy is PNG-local, deterministic, and visible in the API/policy snapshot. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`, `policy/foundation.json`, `.planning/ROADMAP.md`] |
| New policy classifier | Phase-specific compatibility logic | Existing `foundation.json` interface snapshot and `compatibility.json` additive rule | The existing quality tooling consumes both exact policy representations. [VERIFIED: codebase: `policy/{foundation,compatibility}.json`, `scripts/quality/Invoke-MoonQuality.ps1`] |

**Key insight:** Treat Phase 32 as a public construction contract with a frozen legacy route, not as a partial compressor. The only bytes it is allowed to defend are the existing stored bytes; all optimized bytes are Phase 33's responsibility. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

## Common Pitfalls

### Pitfall 1: Legacy constructors delegate through a mutable default

**What goes wrong:** A later change to configured-factory behavior silently changes `PngEncoder::new` or `PngChunkEncoder::new` output. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`]

**How to avoid:** Make each legacy constructor directly choose `PngCompressionStrategy::Stored`, and test both outputs against fixed stored-byte expectations. [VERIFIED: codebase: `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`]

### Pitfall 2: Factory API is added but omitted from the semantic policy snapshot

**What goes wrong:** Generated MBTI and `foundation.json` diverge, causing the policy quality stage to fail closed. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/Invoke-MoonQuality.ps1`]

**How to avoid:** Update the enum and both factories in the same task as the declarations, then generate interfaces for all declared targets before running the policy/compatibility checks. [VERIFIED: codebase: `scripts/quality/Invoke-MoonQuality.ps1`, `policy/foundation.json`]

### Pitfall 3: Phase 32 equality test blocks Phase 33

**What goes wrong:** A test asserts `FixedOrStored == Stored`, then becomes invalid as soon as Phase 33 optimizes repetitive data. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

**How to avoid:** In Phase 32 test only successful construction/valid encoding for the configured factory and exact bytes for legacy constructors; Phase 33 replaces the provisional factory-behavior check with optimized-output admission and selection evidence. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`]

### Pitfall 4: New enum promises unsupported compression modes

**What goes wrong:** Names such as `Optimized` invite dynamic Huffman, adaptive filters, or host-codec assumptions that the milestone excludes. [VERIFIED: codebase: `.planning/ROADMAP.md`]

**How to avoid:** Publish only `FixedOrStored` and document its exclusions alongside the factory. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

## Code Examples

### Opt-in caller shape

```moonbit
let eager = PngEncoder::new_with_compression_strategy(
  PngCompressionStrategy::FixedOrStored,
)
let chunked = PngChunkEncoder::new_with_compression_strategy(
  image.view(), PngCompressionStrategy::FixedOrStored,
  limits, budget, diagnostics,
)
```

This is the intended public Phase 32 call shape. Until Phase 33, both configured values use the already-canonical stored emission; the selection is retained so the later implementation does not need another public API change. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/{png.mbt,stream_encode.mbt}`]

### Legacy compatibility assertion

```moonbit
let eager_bytes = png_encode_with(PngEncoder::new(), image)
let chunk_bytes = png_chunk_drain_with(PngChunkEncoder::new(...))
inspect(eager_bytes == expected_stored_png, content="true")
inspect(chunk_bytes == expected_stored_png, content="true")
```

Use the existing eager exact-byte vectors as the oracle and extend the chunk helper to compare the complete drained aggregate, not only a prefix or eager parity. [VERIFIED: codebase: `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`]

## Phase Boundaries

| Deliver in Phase 32 | Explicitly reserve for Phase 33 | Explicitly reserve for Phase 34 |
|---|---|---|
| `PngCompressionStrategy`, the two configured factories, documentation, exact policy registration, and frozen legacy eager/chunk stored-byte regression tests. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`] | Exact capability/geometry/output/work/budget preflight for optimized output; fixed-Huffman literal/match planning; choose fixed vs stored; optimized eager/chunk byte emission, progress, and sticky terminal proof. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`] | Reproducible corpus/fixtures, target-neutral decoded-image evidence, four-target optimized eager/chunk evidence, never-larger assertion, and declared flat RGB8/RGBA8 wins. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`] |
| No edit to `zlib_byte`'s stored block representation, no optimized-size guarantee, and no factory-output equality assertion that would freeze Phase 33 out. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/ROADMAP.md`] | No dynamic Huffman, adaptive filters, 32 KiB LZ77 dictionary, FFI, or host streaming. [VERIFIED: codebase: `.planning/ROADMAP.md`] | No new public compression API; corpus work validates the Phase 32/33 API rather than expanding it. [VERIFIED: codebase: `.planning/ROADMAP.md`] |

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| One unconfigured eager/chunk stored encoder | Stored defaults plus explicit `FixedOrStored` factory selection | Callers can opt in without a default change; Phase 33 can implement the selected behavior without another public-surface addition. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/{png.mbt,stream_encode.mbt}`] |

**Deprecated/outdated:** Do not treat a single canonical stored stream as the only public compression policy after Phase 32; it remains the mandatory default/baseline, not the only selectable strategy. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

## Assumptions Log

All implementation guidance is derived from the current PNG API, policy, roadmap, and archived encoder evidence; no training-only claim is required. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}`, `policy/{foundation,compatibility}.json`, `.planning/ROADMAP.md`]

## Open Questions (RESOLVED)

1. **May Phase 32 expose `FixedOrStored` before Phase 33 implements fixed-or-stored emission?**
   - Resolution: Yes, but the public documentation on the enum and both configured factories must state that `FixedOrStored` currently emits the Stored baseline, provides no optimization or size guarantee, and receives fixed-or-stored behavior in Phase 33. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
   - Release consequence: The additive API must not advertise a compression-ratio result until Phase 34 supplies its required corpus evidence. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Package tests/interface generation | Yes | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` | Compilation | Yes | `v0.10.4+2cc641edf` | — [VERIFIED: local `moonc -v`] |
| `moonrun` | Target runtime | Yes | `0.1.20260713` | — [VERIFIED: local `moonrun --version`] |
| PowerShell | Existing quality scripts | Yes | `7.6.3` | — [VERIFIED: local `$PSVersionTable.PSVersion`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local version checks]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V5 Input Validation | Yes | Keep legacy source/capability/limit/budget admission unchanged; add no factory-time bypass or new input type. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `.planning/ROADMAP.md`] |
| V8 Data Protection / Integrity | Yes | Assert complete legacy stored bytes for eager and caller-buffered output; preserve existing CRC/Adler and caller-lease terminal behavior. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,stream_encode_test.mbt}`] |
| V2/V3/V4/V6 | No | PNG compression selection has no authentication, session, authorization, or secret-cryptography role. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`] |

| Threat pattern | STRIDE | Standard mitigation |
|---|---|---|
| Silent legacy representation drift | Tampering | Freeze full eager and chunk stored-DEFLATE bytes rather than only decoded pixels. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/encode_test.mbt`] |
| Factory bypass of existing admission | Denial of service | Route both configured factories through the same authoritative source/preflight path; Phase 33 extends optimized admission only. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `.planning/ROADMAP.md`] |
| Ambiguous compression claim | Spoofing | Use `FixedOrStored`, document exclusions, and defer performance claims to corpus evidence. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}` — current constructors, canonical stored emission, preflight, and state ownership. [VERIFIED: codebase]
- `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt,encode_wbtest.mbt,stream_encode_wbtest.mbt}` — existing frozen bytes, eager/chunk parity, exact progress, and sticky terminal test patterns. [VERIFIED: codebase]
- `policy/{foundation,compatibility}.json` and `scripts/quality/Invoke-MoonQuality.ps1` — exact policy surface, additive classification, and interface enforcement. [VERIFIED: codebase]
- Archived v0.9 Phase 29–31 research, plans, summaries, and verification — established encoder and evidence boundaries. [VERIFIED: codebase: `.planning/milestones/v0.9-phases/`] 
- Local baseline: `moon -C modules/mb-image test png --target native --frozen -f '*PNG chunk encoder*'` passed 5/5. [VERIFIED: local execution]

### Secondary (MEDIUM confidence)

- None required: the phase adds no external library and is constrained by the repository's current public contract. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/moon.pkg`]

### Tertiary (LOW confidence)

- None. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}`, `policy/{foundation,compatibility}.json`, `.planning/ROADMAP.md`]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — existing internal package, policy, tests, and installed toolchain were inspected directly. [VERIFIED: codebase; local version checks]
- Architecture: HIGH — the exact constructor/machine routing and archived v0.9 evidence are present in source and verification records. [VERIFIED: codebase]
- Pitfalls: HIGH — each follows from current legacy byte creation, policy enforcement, or explicitly fenced later requirements. [VERIFIED: codebase]

**Research date:** 2026-07-22  
**Valid until:** Phase 32 planning begins or the PNG public interface changes.
