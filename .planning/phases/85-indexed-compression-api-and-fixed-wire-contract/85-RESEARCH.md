# Phase 85: Indexed Compression API and Fixed Wire Contract - Research

**Researched:** 2026-07-24
**Domain:** MoonBit Type-3 PNG encoding; deterministic Stored-or-Fixed DEFLATE selection
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Add exactly four additive APIs: eager and chunk constructors for
  Indexed8 and selected low-bit indexed sources, each taking the existing
  `PngCompressionStrategy`. They are non-interlaced only; do not create a
  combined compression/filter/interlace API in this milestone. —
  **Reversibility:** costly — adding a different public selector later would
  require preserving the published API contract and test matrix.
- **D-02:** Existing/default Indexed8 and Indexed1/2/4 APIs remain literal
  forwards to `Stored` plus filter `None`; indexed Adam7 remains an explicit
  Stored/None compatibility baseline.
- **D-03:** The new selectors admit only `Stored` and `FixedOrStored`.
  `DynamicOrFixedOrStored` fails with a stable indexed-dynamic-unavailable
  capability error before planning, writer output, chunk lease exposure, or a
  budget charge. — **Reversibility:** costly — callers must be able to rely on
  truthful capability failure rather than a silent fallback.
- **D-04:** `FixedOrStored` compares exact *complete Type-3 frame* sizes,
  including IHDR, PLTE, canonical shortest tRNS, IDAT, and IEND. Fixed wins on
  a tie (`fixed_frame <= stored_frame`); otherwise use literal Stored output.
- **D-05:** Reuse one immutable, bounded, filter-None indexed raw-byte/match
  producer for Stored traversal, Fixed planning, and Fixed acknowledgement-safe
  replay. Reuse the existing 1--4-distance matcher, Fixed emitter, and sole
  acknowledged machine; do not stage pixels/tokens/output, widen the matcher,
  or create a second encoder.
- **D-06:** Phase-85 evidence focuses on API shape, literal Stored forwarding,
  Dynamic atomic rejection, and deterministic Fixed-or-Stored wire selection.
  Hostile leases, ancillary-aware admission boundaries, independent wire
  parsing, and four-target package qualification remain owned by Phases 86--87.

### the agent's Discretion
- Use existing public naming and error-construction patterns when resolving the
  concrete method and capability-error spellings; preserve the decisions above.

### Deferred Ideas (OUT OF SCOPE)
- Indexed Dynamic DEFLATE, adaptive filtering, and Adam7 compression selection
  are separate future capabilities.
- Ancillary-aware selected admission is Phase 86; hostile streaming and
  independent four-target qualification are Phase 87.
- Release automation, registry work, FFI, generic model changes, and copied
  source trees are outside this milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INDEXCOMP-01 | Explicit Stored/FixedOrStored selectors for non-interlaced indexed eager and caller-buffered encoding; legacy/new Stored bytes are identical; Dynamic fails atomically. | Four additive public forwards, an early strategy gate, existing capability-error construction, and compatibility fixtures. [VERIFIED: repository inspection] |
| INDEXCOMP-02 | One bounded filter-None raw-byte/match producer selects Fixed only when the complete Type-3 frame is no larger, otherwise Stored; no staging or second encoder. | Generalize the raw producer/match cursor, keep the current bounded 262-byte window and Fixed replay, and calculate candidate totals through `PngFrameFacts`. [VERIFIED: repository inspection] [CITED: https://www.rfc-editor.org/info/rfc1951/] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain MoonBit-native; this phase must not substitute a foreign codec. [VERIFIED: AGENTS.md]
- The native target is primary, but portable support is maintained through capability boundaries and conformance tests; the PNG package declares js, wasm, wasm-gc, and native support. [VERIFIED: AGENTS.md; repository inspection]
- Public packages retain acyclic, explicit dependencies; Phase 85 needs no new module or package dependency. [VERIFIED: AGENTS.md; repository inspection]
- Public API additions must be visibly additive and SemVer-compatible; the four selectors are the only public-surface change. [VERIFIED: AGENTS.md; CONTEXT.md]
- Public behavior must be deterministic and automation-friendly; the output-selection tie rule and error context therefore require byte/error assertions. [VERIFIED: AGENTS.md; CONTEXT.md]
- `*_test.mbt` covers public API behavior and `*_wbtest.mbt` covers private invariants; binary behavior uses exact bytes/digests plus semantic assertions rather than opaque snapshots. [VERIFIED: AGENTS.md]
- Code discovery must prefer codebase-memory graph tools. The graph was queried first but returned no nodes for this workspace path, so the findings below use targeted `rg`/source reads as the documented fallback. [VERIFIED: graph query; AGENTS.md]

## Summary

Phase 85 is an internal encoder-seam change plus four additive façade methods, not a compression-library integration. The repository already exposes `PngCompressionStrategy::{Stored, FixedOrStored, DynamicOrFixedOrStored}` and a single acknowledged `PngEncodeMachine`; indexed entry points instead hard-wire `Stored`/`None` and bypass the generic `ImageView`-backed match cursor. [VERIFIED: repository inspection] The plan must make indexed bytes available to the existing bounded Fixed matcher and Fixed acknowledgement replay without allocating scanlines, token lists, output buffers, a wider dictionary, or another machine. [VERIFIED: repository inspection; CONTEXT.md]

The central correctness rule is frame-level selection. PNG Type 3 requires PLTE, permits a canonical tRNS before IDAT, and uses filter method 0 scanline bytes; therefore an IDAT-only comparison or the generic encoder's legacy `+57` frame arithmetic is insufficient for indexed output. [CITED: https://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html] [CITED: https://www.libpng.org/pub/png/spec/1.2/PNG-DataRep.html] The existing `PngFrameFacts` already owns exactly these palette/transparency offsets and total-length arithmetic. [VERIFIED: repository inspection]

**Primary recommendation:** Add the four compression-selector façades as thin non-interlaced forwards; reject Dynamic before indexed preflight; refactor the private raw-byte/match producer so Stored traversal, Fixed planning, and Fixed replay consume the same bounded filter-None indexed stream; derive both candidate totals from indexed `PngFrameFacts` and choose Fixed on `<=`. [VERIFIED: repository inspection; CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Indexed compression API selection | API / Backend | — | The public MoonBit encoder façade owns strategy validation and must reject Dynamic before any machine/budget work. [VERIFIED: repository inspection; CONTEXT.md] |
| Filter-None packed indexed raw-byte production | API / Backend | — | The immutable indexed raster, row filter byte, low-bit packing, and zero tail are pure encoder logic. [VERIFIED: repository inspection] |
| Fixed-versus-Stored candidate decision | API / Backend | — | It combines bounded DEFLATE planning with Type-3 frame facts; no client, storage, or host service owns it. [VERIFIED: repository inspection] |
| PNG framing, CRC, Adler, acknowledgement | API / Backend | — | The established `PngEncodeMachine` owns byte preview/acknowledgement and chunk CRC/Adler progression. [VERIFIED: repository inspection] |
| Palette and canonical transparency bytes | API / Backend | — | `PngIndexedImage` and `PngFrameFacts` provide the actual PLTE/tRNS data and offsets. [VERIFIED: repository inspection] |

## Standard Stack

### Core

| Library / component | Version | Purpose | Why standard |
|---------------------|---------|---------|--------------|
| MoonBit toolchain | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf` | Compile and run the existing portable PNG package. | Installed locally and already pinned by project guidance. [VERIFIED: local `moon --version`; AGENTS.md] |
| Existing `PngCompressionStrategy` | repository internal | Reuse the public Stored/Fixed/Dynamic vocabulary; do not introduce an indexed-only enum. | The current generic APIs already use it, and the phase locks its use. [VERIFIED: repository inspection; CONTEXT.md] |
| Existing `PngFrameFacts` | repository internal | Compute Type-3 PLTE/tRNS/IDAT/IEND offsets and complete length. | It is the existing owner of frame arithmetic required by the fixed-wire rule. [VERIFIED: repository inspection] |
| Existing bounded Fixed DEFLATE matcher/emitter and `PngEncodeMachine` | repository internal | Plan and acknowledgement-safe replay. | They already retain only scalar plan/replay facts and a fixed 262-byte retained window. [VERIFIED: repository inspection] |

### Supporting

| Component | Purpose | When to use |
|-----------|---------|-------------|
| `@checked` arithmetic helpers | Checked size, scanline, and frame calculations. | Preserve every existing checked-add/multiply boundary when candidate facts are added. [VERIFIED: repository inspection] |
| `@codec.capability_unavailable` via `_png_encode_capability` | Stable typed capability failure. | Use for unsupported indexed Dynamic before planning, machine construction, output, lease exposure, or budget mutation. [VERIFIED: repository inspection; CONTEXT.md] |
| Existing public and white-box PNG test files | Public API/wire compatibility versus private cursor/plan invariants. | Add Phase-85 evidence in `encode_test.mbt`, `stream_encode_test.mbt`, and `encode_wbtest.mbt` without introducing a new test harness. [VERIFIED: repository inspection; AGENTS.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared indexed raw producer | A second indexed Fixed encoder | Rejected: it would duplicate acknowledgement and DEFLATE behavior and violates D-05. [VERIFIED: CONTEXT.md] |
| Existing 1--4-distance matcher | A general 32 KiB LZ77 window | Rejected: broader matching changes the bounded contract and is explicitly out of scope. [VERIFIED: CONTEXT.md] |
| Fixed-or-Stored only | Dynamic indexed DEFLATE | Rejected in this phase: Dynamic must return a capability error, not silently fall back. [VERIFIED: CONTEXT.md] |
| Filter None | Adaptive filtering | Rejected: it adds row-candidate selection and packed-row interaction outside the phase boundary. [VERIFIED: CONTEXT.md] |

**Installation:** None. This phase adds no external packages. [VERIFIED: CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
eager Indexed8 / low-bit API       caller-buffered Indexed8 / low-bit API
              |                                  |
              +---------- strategy gate ----------+
                            |
             DynamicOrFixedOrStored? -- yes --> typed unavailable error
                            |
                            no
                            v
     indexed profile + immutable PngIndexedImage + filter None
                            |
                            v
       one bounded indexed raw-byte / match producer
                |                         |
                |                         +--> Fixed plan + fingerprint/work
                +--> Stored traversal facts
                            |
                            v
       PngFrameFacts( IHDR, PLTE, shortest tRNS, IDAT, IEND )
                            |
          fixed frame <= stored frame ?
                | yes                         | no
                v                             v
        PngDeflatePlan::Fixed          PngDeflatePlan::Stored
                \                             /
                 +--> sole PngEncodeMachine --> acknowledged writer / chunk pull
```

The diagram describes the Phase-85 decision path. Phase 86 owns the expanded ancillary-aware exact-limit/one-charge admission matrix, and Phase 87 owns hostile-lease plus independent-parser qualification. [VERIFIED: CONTEXT.md]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # existing public strategy/source vocabulary
├── encode.mbt              # eager façades, indexed preflight, raw/match planning
├── stream_encode.mbt       # chunk façades and the sole acknowledgement machine
├── encode_test.mbt         # public eager compatibility/selection tests
├── stream_encode_test.mbt  # public chunk façade parity tests
└── encode_wbtest.mbt       # private cursor, frame, plan, and atomic-rejection tests
```

These are existing ownership seams; do not add a parallel package or encoder module. [VERIFIED: repository inspection]

### Pattern 1: Literal compatibility forwards

**What:** Keep every existing non-interlaced indexed entry point as a direct call to its new compression-aware counterpart with `PngCompressionStrategy::Stored`; keep existing interlace selectors on their current Stored/None route. [VERIFIED: CONTEXT.md]

**When to use:** For legacy `encode_indexed8`, `encode_indexed`, `new_indexed8`, and `new_indexed` only. [VERIFIED: repository inspection; CONTEXT.md]

**Example (implementation sketch):**

```moonbit
pub fn PngEncoder::encode_indexed8(...) -> Result[...] {
  PngEncoder::encode_indexed8_with_compression_strategy(
    encoder, source, PngCompressionStrategy::Stored, writer, limits, budget, diagnostics,
  )
}
```

The sketch follows the repository's existing `*_with_compression_strategy` forwarding style; the exact type spelling follows the existing method signatures. [VERIFIED: repository inspection]

### Pattern 2: Early capability gate, then shared planning

**What:** Normalize the requested indexed strategy before calling indexed preflight or creating `PngEncodeMachine`. `Stored` and `FixedOrStored` proceed; Dynamic returns one stable typed capability error. [VERIFIED: CONTEXT.md]

**When to use:** At the common private constructor used by both eager and chunk selector façades. [VERIFIED: repository inspection; CONTEXT.md]

**Example (implementation sketch):**

```moonbit
match strategy {
  Stored => continue_with_indexed_profile(...)
  FixedOrStored => continue_with_indexed_profile(...)
  DynamicOrFixedOrStored =>
    Err(_png_encode_capability("indexed-dynamic-compression-unavailable"))
}
```

`_png_encode_capability` is the established construction seam; the exact new context string is a recommended spelling that must be frozen in a public error test. [VERIFIED: repository inspection] [ASSUMED]

### Pattern 3: Concrete bounded producer beneath the existing match cursor

**What:** Keep `PngFilteredMatchCursor` as the single 262-byte logical match window and change only its concrete `producer` field from `PngFilteredCursor` to a new private tagged `PngMatchProducer`. Its variants are `Filtered(PngFilteredCursor)` and `IndexedNone(PngIndexedRawCursor)`. [VERIFIED: repository inspection]

`PngIndexedRawCursor` is the smallest indexed representation: `{ source: PngIndexedImage, profile: PngEncodeProfile, row_bytes: UInt64, index: UInt64 }`. Its `next` emits the existing non-interlaced filter byte/8-bit index/packed-low-bit byte logic currently embedded in `PngEncodeMachine::scanline_byte`; it retains no row, pass, token, output, or caller lease. [VERIFIED: repository inspection; CONTEXT.md]

**When to use:** Stored traversal, Fixed planning, and Fixed replay for the selected non-interlaced indexed route. Existing Adam7 indexed construction remains on its current Stored/None path. [VERIFIED: CONTEXT.md]

**Exact implementation seam:**

1. In `modules/mb-image/png/encode.mbt`, add `PngMatchProducer`, `PngIndexedRawCursor`, `PngIndexedRawCursor::new`, `PngIndexedRawCursor::next`, `PngMatchProducer::next`, and `PngMatchProducer::facts`; update `PngFilteredMatchCursor::{new_with_interlace,facts,ensure}` and add `PngFilteredMatchCursor::new_indexed`. [VERIFIED: repository inspection]
2. In the same file, leave `_png_filtered_match_at` unchanged, because it already consumes only `PngFilteredMatchCursor::{ensure,read,consume}` and therefore keeps the 1--4-distance/258-length algorithm unchanged. Extract cursor-taking helpers from `_png_filtered_match_traverse_with_interlace` and `_png_fixed_plan_with_interlace` so generic and indexed calls share their traversal and Fixed bit-count loop. [VERIFIED: repository inspection]
3. Replace the generic Fixed plan's legacy total calculation with a cursor-taking helper that receives actual PLTE/tRNS lengths and calls `_png_frame_facts` after it computes `idat_length`; generic callers pass zero ancillary lengths, preserving their current result. The indexed caller passes `source.palette_length()` and its canonical shortest tRNS length. [VERIFIED: repository inspection]
4. In `modules/mb-image/png/stream_encode.mbt`, add a strategy-taking private sibling to `PngEncodeMachine::new_with_indexed_profile`; retain the current function as its literal Stored compatibility wrapper. For non-interlaced indexed construction, initialize `stored_cursor` with `PngFilteredMatchCursor::new_indexed` and initialize the existing `PngFixedState.filtered_cursor` with a fresh identical indexed cursor when the selected plan is Fixed. `PngEncodeMachine::{zlib_byte,fixed_preview_byte,acknowledge}` then reuse their current cursor/acknowledgement branches without a second emitter or state machine. [VERIFIED: repository inspection]

**Example (implementation sketch):**

```moonbit
priv enum PngMatchProducer {
  Filtered(PngFilteredCursor)
  IndexedNone(PngIndexedRawCursor)
}

// PngFilteredMatchCursor retains logical_position, produced_exclusive,
// retained_start, and its existing 262-byte window. It delegates next() to
// PngMatchProducer, so the unchanged matcher is used by both source kinds.
```

Do not rename the shared matcher, duplicate `_png_filtered_match_at`, widen its window, or add an indexed-specific Fixed state. [VERIFIED: repository inspection; CONTEXT.md]

### Pattern 4: Frame-level selection through `PngFrameFacts`

**What:** Calculate Stored and Fixed IDAT lengths, then form candidate `PngFrameFacts` with the actual palette byte length and shortest canonical alpha prefix. Compare `fixed_frame.total_length <= stored_frame.total_length`. [VERIFIED: repository inspection; CONTEXT.md]

**When to use:** Only for explicit non-interlaced `FixedOrStored`; legacy/default and explicit Stored do not need a Fixed walk. [VERIFIED: CONTEXT.md]

**Anti-Patterns to Avoid**

- **IDAT-only or `+57` comparison:** Generic Fixed planning still derives its total from a non-palette 57-byte base; using it for Type 3 can choose the wrong candidate when PLTE/tRNS are present. Use `PngFrameFacts` for both candidates. [VERIFIED: repository inspection]
- **Calling `scanline_byte` independently in each route:** This permits Fixed planning and acknowledgement replay to drift from Stored production. Route all selected indexed raw traversal through the one producer. [VERIFIED: CONTEXT.md]
- **A combined compression/filter/interlace façade:** It expands the public matrix and violates D-01; indexed Adam7 remains Stored/None. [VERIFIED: CONTEXT.md]
- **A silent Dynamic fallback:** It lies about support and violates the atomic capability contract. [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fixed DEFLATE encoding | A new indexed-only Huffman/token encoder | Existing Fixed planner, matcher, and `PngFixedState` replay. | They already enforce bounded matching and acknowledgement-safe preview/commit state. [VERIFIED: repository inspection] |
| Output lifecycle | A second eager/chunk state machine | Existing `PngEncodeMachine` and `PngChunkEncoder` state. | CRC/Adler and output progress advance only on acknowledgement there. [VERIFIED: repository inspection] |
| Frame arithmetic | Ad hoc palette/tRNS byte offsets or a copied `+57` base | `PngFrameFacts`. | It centralizes PLTE/tRNS/IDAT/IEND offsets with checked arithmetic. [VERIFIED: repository inspection] |
| Raw storage | Full scanline, token, pass, or output staging | Scalar producer + existing bounded 262-byte match window. | D-05 forbids staging and matcher widening. [VERIFIED: CONTEXT.md; repository inspection] |
| Compression profile vocabulary | A new indexed enum | Existing `PngCompressionStrategy`. | The phase locks the shared public vocabulary and only narrows supported variants for indexed calls. [VERIFIED: CONTEXT.md] |

**Key insight:** the indexed feature is safe only when one logical raw stream drives all three consumers—Stored traversal, Fixed planning, and Fixed replay—while the existing machine remains the sole owner of acknowledged output. [VERIFIED: CONTEXT.md]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — repository scan found fixture JSON and compatibility baselines, but no runtime database or datastore used by this PNG encoding path. [VERIFIED: repository file/dependency scan] | Code edit only; no data migration. |
| Live service config | None — the phase is a portable library encoder and the inspected repository contains no deployed PNG-service configuration for this route. [VERIFIED: repository file/dependency scan] | None. |
| OS-registered state | None — no task/service/launch registration is part of the encoder package or phase scope. [VERIFIED: repository file/dependency scan] | None. |
| Secrets/env vars | None — no strategy-dependent secret or environment-variable lookup occurs in the inspected PNG encoder sources. [VERIFIED: repository inspection] | None. |
| Build artifacts | MoonBit `_build` artifacts are regenerated by package test/build commands; no installed package or published artifact name changes in this phase. [VERIFIED: local MoonBit toolchain; CONTEXT.md] | Rebuild/test normally; do not migrate artifacts. |

## Common Pitfalls

### Pitfall 1: Selecting against the legacy non-palette frame constant

**What goes wrong:** Fixed can be accepted/rejected using a total that excludes the actual Type-3 PLTE or canonical tRNS framing. [VERIFIED: repository inspection]

**Why it happens:** generic Fixed planning currently computes `idat_length + 57`, while indexed preflight already derives variable framing through `PngFrameFacts`. [VERIFIED: repository inspection]

**How to avoid:** pass candidate IDAT lengths through `PngFrameFacts(source.palette_length(), shortest_trns_length, idat_length)` before applying the exact `<=` selection rule. [VERIFIED: repository inspection; CONTEXT.md]

**Warning signs:** an opaque and a partially transparent palette with equal raw bytes produce inconsistent winner decisions, or a white-box test observes a 57-byte base for indexed totals. [ASSUMED]

### Pitfall 2: Breaking frozen Stored bytes while adding the new API

**What goes wrong:** legacy wrappers accidentally use the request-bearing encoder's generic strategy, a Fixed producer, or a different raw traversal. [VERIFIED: repository inspection; CONTEXT.md]

**Why it happens:** current indexed no-interlace wrappers route through interlace selectors that construct a hard-wired Stored/None indexed machine. [VERIFIED: repository inspection]

**How to avoid:** make each old method a literal `Stored` forward and assert old output equals new explicit Stored output byte-for-byte for depths 1/2/4/8; retain Adam7 vectors unchanged. [VERIFIED: CONTEXT.md]

**Warning signs:** a compatibility fixture changes despite a `Stored` request, or an old method starts accepting Dynamic. [ASSUMED]

### Pitfall 3: Rejecting Dynamic after resource mutation

**What goes wrong:** a caller gets an unavailable error after preflight, a writer write, a chunk constructor, a lease, or `budget.charge`. [VERIFIED: CONTEXT.md]

**Why it happens:** the existing generic preflight supports Dynamic, so passing the enum through unchanged defers the decision too far. [VERIFIED: repository inspection]

**How to avoid:** validate supported indexed strategies in the shared public/private route before `_png_encode_indexed_preflight_with_profile` and before `PngEncodeMachine` construction. [VERIFIED: repository inspection; CONTEXT.md]

**Warning signs:** the test needs to drain output to observe the Dynamic error, or remaining budget differs after rejection. [ASSUMED]

### Pitfall 4: Copying the matcher or staging producer output

**What goes wrong:** planning and replay use different tokenization, or the implementation introduces image-sized arrays to share bytes. [VERIFIED: CONTEXT.md]

**Why it happens:** the current `PngFilteredMatchCursor` is typed directly to `PngFilteredCursor`/`ImageView`, while indexed emission currently reads `scanline_byte` from the machine. [VERIFIED: repository inspection]

**How to avoid:** make the bounded raw producer an internal variant below one shared matcher and reuse the existing Fixed emitter/replay state. [VERIFIED: repository inspection; CONTEXT.md]

**Warning signs:** a new 32 KiB window, `Array[Byte]` sized by scanlines, a second machine, or a second `_png_fixed_*` matcher appears in the diff. [ASSUMED]

## Code Examples

### Candidate selection contract

```moonbit
let stored_frame = PngFrameFacts::from_indexed(source, stored_idat_length)?
let fixed = plan_fixed_with_shared_indexed_cursor(source, profile)?
let fixed_frame = PngFrameFacts::from_indexed(source, fixed.idat_length)?

let plan = if fixed_frame.total_length <= stored_frame.total_length {
  PngDeflatePlan::Fixed({ ..fixed, total_length: fixed_frame.total_length })
} else {
  PngDeflatePlan::Stored({ ..stored, total_length: stored_frame.total_length })
}
```

This is a planning sketch, not a copied API. The implementation must call the existing frame-fact constructor and preserve its checked-error propagation rather than add a parallel `from_indexed` helper if that would duplicate ownership. [VERIFIED: repository inspection] [ASSUMED]

### Focused Phase-85 test shape

```moonbit
let legacy = encode_indexed_legacy(source, depth)
let stored = encode_indexed_with_compression(source, depth, Stored)
inspect(legacy == stored, content="true")

let result = new_indexed_with_compression(source, depth, DynamicOrFixedOrStored, ...)
inspect(result is Err(error) && error.context() == Some("indexed-dynamic-compression-unavailable"), content="true")
inspect(remaining_before == budget.remaining(), content="true")
```

The exact helper names belong to the implementation's existing test utilities; the required assertions are public Stored parity, the stable Dynamic context, and unchanged budget/output observation. [VERIFIED: CONTEXT.md; repository inspection] [ASSUMED]

## State of the Art

| Old approach | Current approach for this phase | When changed | Impact |
|--------------|--------------------------------|--------------|--------|
| Indexed Type-3 routes construct a Stored/None machine directly. | Explicit non-interlaced callers select Stored or FixedOrStored, while legacy routes remain Stored forwards. | Phase 85. [VERIFIED: repository inspection; CONTEXT.md] | Adds deterministic opt-in compression without changing default bytes. |
| Generic Fixed planner uses a legacy non-palette total. | Indexed candidate totals use palette-aware `PngFrameFacts`. | Phase 85. [VERIFIED: repository inspection; CONTEXT.md] | Corrects the decision metric for Type-3 frame size. |
| Indexed bytes are emitted only through `scanline_byte`. | One bounded indexed raw producer also feeds Stored traversal, Fixed planning, and Fixed replay. | Phase 85. [VERIFIED: repository inspection; CONTEXT.md] | Prevents divergent raw streams and avoids staging. |

**Deprecated/outdated:** applying the generic `idat_length + 57` total to indexed Fixed selection is invalid for this phase because Type-3 framing includes variable PLTE and optional tRNS spans. [VERIFIED: repository inspection] [CITED: https://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `indexed-dynamic-compression-unavailable` is the final stable error-context spelling. | Architecture Patterns; Code Examples | Public error contract would require test/API wording adjustment before release. |
| A2 | The test warning signs described above are adequate early diagnostics. | Common Pitfalls | They are guidance only; requirements remain the locked byte/error/selection contract. |

## Resolved Planning Decisions

### R1: Use `PngMatchProducer` inside `PngFilteredMatchCursor`

Use the exact cursor representation and file/function edits listed in Architecture Pattern 3. It is the smallest change because `PngFilteredMatchCursor` already owns every matcher-visible field and both `PngEncodeMachine::zlib_byte` and `PngEncodeMachine::fixed_preview_byte` already select their acknowledgement-safe cursor branches whenever their cursor fields are `Some`. [VERIFIED: repository inspection]

### R2: Use one generated-in-test two-case matrix for every Type-3 depth

Add a test-local helper named `png_indexed_compression_matrix_source(bit_depth, case)` in `modules/mb-image/png/encode_wbtest.mbt`. For `One`, `Two`, `Four`, and `Eight`, set `height = 1` and set width to `512`, `256`, `128`, and `64` respectively, so each fixture contributes exactly 64 packed raster bytes after its leading filter-None byte. [VERIFIED: repository inspection]

The helper constructs a full-capacity palette of `1 << depth` deterministic RGB entries and alpha values `{ 0x00, 0xff, ... }`; this yields a real PLTE and a canonical shortest one-byte tRNS span for every depth. It expands the named test-local packed-byte sequence into canonical unpacked `PngIndexedImage` codes—never calling production packing or matching helpers. [VERIFIED: repository inspection] [CITED: https://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html]

| Case | Packed raster bytes | Expected selected plan | Exact size rationale |
|------|---------------------|------------------------|----------------------|
| `fixed_winner` | 64 `0x00` bytes | `PngDeflatePlan::Fixed` at all depths | Filter byte plus 64 zero bytes yields a first literal then a distance-1 match; Fixed is far smaller than the one Stored block. [VERIFIED: repository matcher inspection] |
| `stored_fallback` | `0xc0, 0xc1, ..., 0xff` | `PngDeflatePlan::Stored` at all depths | The 65-byte raw stream (filter `0x00` plus 64 distinct high literals) has no 3-byte match at distances 1--4. Fixed costs 594 bits = 75 DEFLATE bytes, hence 81 IDAT bytes; Stored costs 65 raw + 5 block + 6 zlib/Adler = 76 IDAT bytes. [VERIFIED: repository matcher/Stored-length inspection] [CITED: https://www.rfc-editor.org/info/rfc1951/] |

Add these exact test locations:

1. `modules/mb-image/png/encode_wbtest.mbt`: `test "PNG indexed compression matrix selects Fixed and Stored at every depth"`. Call the new strategy-taking indexed preflight with each matrix source and assert the `PngDeflatePlan` variant, `fixed_frame <= stored_frame` for `fixed_winner`, `fixed_frame > stored_frame` for `stored_fallback`, frame facts retain the one-byte tRNS, and the selected plan keeps scalar/bounded facts. [VERIFIED: repository inspection; CONTEXT.md]
2. `modules/mb-image/png/encode_test.mbt`: `test "PNG indexed compression selectors preserve Stored and select the matrix plan"`. For every depth, compare legacy eager bytes with explicit Stored bytes; for `stored_fallback`, assert explicit FixedOrStored bytes equal explicit Stored bytes; for `fixed_winner`, assert selected eager bytes are shorter than Stored. Exercise `encode_indexed8_with_compression_strategy` for `Eight` and `encode_indexed_with_compression_strategy` for low-bit depths. [VERIFIED: repository inspection; CONTEXT.md]
3. `modules/mb-image/png/stream_encode_test.mbt`: `test "PNG indexed compression chunk selectors match eager matrix bytes"`. Pull one sufficiently large lease per matrix member and compare collected chunk bytes to fresh eager bytes for the same explicit strategy. Exercise `new_indexed8_with_compression_strategy` for `Eight` and `new_indexed_with_compression_strategy` for low-bit depths. Hostile schedules and independent parsing remain out of scope for this phase. [VERIFIED: repository inspection; CONTEXT.md]

## Open Questions

None — the cursor representation and a deterministic all-depth Fixed-winner/Stored-fallback fixture matrix are resolved for planning. [VERIFIED: repository inspection; CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| MoonBit `moon` | Formatting/build/test of the PNG package | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| MoonBit `moonc` | Compiler supplied by the pinned toolchain | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local `moon --version`] |
| MoonBit `moonrun` | Test runtime supplied by the pinned toolchain | ✓ | `0.1.20260713` | — [VERIFIED: local `moonrun --version`] |
| External compression package/service | Phase 85 | Not required | — | Use the existing MoonBit-native encoder. [VERIFIED: CONTEXT.md; AGENTS.md] |

**Missing dependencies with no fallback:** None. [VERIFIED: local toolchain probe]

**Missing dependencies with fallback:** None. [VERIFIED: local toolchain probe]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | This is an in-process library encoder with no identity boundary. [VERIFIED: repository inspection] |
| V3 Session Management | No | This phase introduces no session state. [VERIFIED: repository inspection] |
| V4 Access Control | No | This phase introduces no authorization boundary. [VERIFIED: repository inspection] |
| V5 Input Validation | Yes | Retain indexed-source validation, checked geometry/frame arithmetic, palette-cap checks, and early strategy capability validation. [VERIFIED: repository inspection; CONTEXT.md] |
| V6 Cryptography | No | CRC/Adler provide format integrity checks, not cryptographic protection; do not present them as cryptographic controls. [VERIFIED: repository inspection] [ASSUMED] |

### Known Threat Patterns for MoonBit PNG encoding

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oversized dimensions, palette, scanlines, IDAT, or frame arithmetic | Denial of service | Checked arithmetic and existing limits before machine/output creation. [VERIFIED: repository inspection] |
| Unsupported Dynamic request silently doing work or emitting bytes | Tampering / denial of service | Stable early `capability_unavailable` error before planning, lease exposure, writer progress, or budget charge. [VERIFIED: CONTEXT.md] |
| Planning/replay raw-stream mismatch | Tampering | Fingerprint and matcher-work checks at Fixed end-of-block, with the same bounded producer used in both walks. [VERIFIED: repository inspection; CONTEXT.md] |
| Image-sized staging or widened history | Denial of service | Preserve scalar plans and the existing bounded match window; prohibit a second encoder or broader matcher. [VERIFIED: repository inspection; CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- None. The configured confidence seam classifies repository discovery as LOW even when locally verified; no Context7 provider was available in this runtime. [VERIFIED: `classify-confidence`; local `ctx7` probe]

### Secondary (MEDIUM confidence)

- [RFC 1951: DEFLATE](https://www.rfc-editor.org/info/rfc1951/) — stored versus fixed block semantics, fixed code definition, stored-block bounds. [CITED: https://www.rfc-editor.org/info/rfc1951/]
- [PNG 1.2 chunk specification](https://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html) — Type-3 PLTE capacity and tRNS-before-IDAT ordering. [CITED: https://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html]
- [PNG 1.2 data representation](https://www.libpng.org/pub/png/spec/1.2/PNG-DataRep.html) — filter method 0 and None. [CITED: https://www.libpng.org/pub/png/spec/1.2/PNG-DataRep.html]
- [Moon command manual](https://moonbitlang.github.io/moon/commands.html) — `moon test --target` values. [CITED: https://moonbitlang.github.io/moon/commands.html]

### Tertiary (LOW confidence)

- Current repository inspection of `modules/mb-image/png/{png,encode,stream_encode,encode_test,encode_wbtest,stream_encode_test}.mbt`, `moon.pkg`, phase context, requirements, roadmap, state, and v0.28 research. The source is authoritative for the current implementation, but the configured codebase confidence seam reports LOW. [VERIFIED: repository inspection; `classify-confidence`]

## Metadata

**Confidence breakdown:**

- Standard stack: MEDIUM — local tool versions and official MoonBit command documentation agree; no new third-party package is proposed. [VERIFIED: local toolchain probe] [CITED: https://moonbitlang.github.io/moon/commands.html]
- Architecture: LOW — direct source inspection precisely identifies the seams, but the configured codebase confidence classifier remains LOW. [VERIFIED: repository inspection; `classify-confidence`]
- Pitfalls: MEDIUM — code evidence identifies the 57-byte/frame and cursor seams; PNG/RFC sources independently support the wire-format constraints. [VERIFIED: repository inspection] [CITED: https://www.rfc-editor.org/info/rfc1951/] [CITED: https://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html]

**Research date:** 2026-07-24
**Valid until:** 2026-08-23 (stable format specifications and a repository-specific planning snapshot). [CITED: https://www.rfc-editor.org/info/rfc1951/] [CITED: https://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html]
