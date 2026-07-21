# Phase 38: Adaptive Filter Compatibility — Research

**Researched:** 2026-07-22
**Domain:** Portable MoonBit PNG encoder public-API compatibility
**Confidence:** HIGH

## User Constraints

- Add only an explicit adaptive PNG row-filter opt-in; preserve every existing filter-None byte route exactly. [VERIFIED: user request; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]
- Defer all five-filter selection and implementation to Phase 39. [VERIFIED: user request; `.planning/ROADMAP.md`]
- Keep this phase out of release, registry, CI/script, FFI, QOI, and user-owned-worktree scope. [VERIFIED: user request; `.planning/REQUIREMENTS.md`]
- Preserve the existing eager/caller-buffered atomic-preflight, acknowledgement, exact-progress, and sticky-terminal contracts. [VERIFIED: `.planning/STATE.md`; `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PNGF-01 | A caller can explicitly opt into adaptive filtering through eager and caller-buffered factories while legacy constructors retain filter-None bytes. | Add a public two-case filter selection and two parallel factory seams; hard-freeze legacy and configured compression output with independent complete-PNG vectors. [VERIFIED: `.planning/REQUIREMENTS.md`; `modules/mb-image/png/{png.mbt,encode_test.mbt,stream_encode_test.mbt}`] |

## Summary

The PNG package already has the correct compatibility architecture: `PngEncoder` and `PngChunkEncoder` feed one private `PngEncodeMachine`, whose `_png_encode_preflight` performs source capability, geometry, output, work, and budget admission before either writer output or a caller lease can observe bytes. `PngEncoder::new()` and `PngChunkEncoder::new(...)` explicitly select Stored compression, while their configured factories pass `PngCompressionStrategy` into the same machine. [VERIFIED: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}`]

Phase 38 should mirror the established compression-compatibility pattern, not introduce row filtering. Add an equality-comparable public `PngFilterStrategy::{None, Adaptive}` and documented `new_with_filter_strategy` factories on the eager and caller-buffered encoders. The legacy constructors and every existing compression-strategy factory must explicitly retain `None`; the new Adaptive factory must retain the selection but, for this phase only, travel through the existing Stored/filter-None path and emit the exact frozen bytes. [ASSUMED: exact public type/factory names are the minimal API recommendation, derived from the existing `PngCompressionStrategy` pattern; behavior/scope are verified by repository requirements.]

PNG filtering is a byte-preserving preprocessing step: it emits a filter-type byte followed by equal-length transformed scanline bytes, and the standard permits choosing a filter per scanline. Filter method 0 defines exactly None, Sub, Up, Average, and Paeth; implementing or scoring those filters is explicitly Phase 39 work, not a Phase 38 shortcut. [CITED: https://www.w3.org/TR/png-3/]

**Primary recommendation:** Publish `PngFilterStrategy::{None, Adaptive}` plus eager/chunk `new_with_filter_strategy` factories; retain both selections in the private machine, but make both emit the unchanged filter-None representation until Phase 39. [ASSUMED: public naming recommendation; implementation boundary verified by existing strategy architecture.]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Public filter opt-in selection | API / Backend | — | The MoonBit PNG package owns its public constructor contract; no browser, host, or FFI tier participates. [VERIFIED: `modules/mb-image/png/png.mbt`] |
| Atomic plan admission | API / Backend | — | `_png_encode_preflight` owns capability, dimension, output, work, and budget checks before adapters expose output. [VERIFIED: `modules/mb-image/png/encode.mbt`] |
| Eager PNG emission | API / Backend | — | `PngEncoder` drives the shared machine and commits one byte only after `Writer.write` succeeds. [VERIFIED: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |
| Caller-buffered PNG emission | API / Backend | — | `PngChunkEncoder::pull` writes only within the supplied lease and advances shared state only after acknowledgement. [VERIFIED: `modules/mb-image/png/stream_encode.mbt`] |
| Row-filter algorithm and scoring | API / Backend | — | It belongs inside the shared preflight/replay path in Phase 39, after the public seam is frozen. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`] |

## Project Constraints (from AGENTS.md)

- Prefer the codebase-memory graph for code discovery; it is unavailable in this runtime, so this research used the permitted `rg` fallback. [VERIFIED: `AGENTS.md`; tool availability]
- Keep shared algorithms and models in MoonBit; maintain portable `js`, `wasm`, `wasm-gc`, and `native` conformance. [VERIFIED: `AGENTS.md`; `modules/mb-image/png/moon.pkg`]
- Treat Native as the primary performance/system-integration target while preserving deliberate portability through capability boundaries and conformance tests. [VERIFIED: `AGENTS.md`]
- Keep FFI isolated and minimal; this phase adds no FFI. [VERIFIED: `AGENTS.md`; `.planning/REQUIREMENTS.md`]
- Preserve modular, acyclic public package boundaries and semantic-versioning compatibility. [VERIFIED: `AGENTS.md`]
- Keep public operations deterministic and GUI-independent; retain reproducible compatibility vectors. [VERIFIED: `AGENTS.md`; `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`]
- Do not make unevidenced performance claims; any benchmark requires declared workloads and reproducible baselines. [VERIFIED: `AGENTS.md`]
- Do not silently redefine ecosystem boundaries; new modules or breaking architecture changes require an RFC. [VERIFIED: `AGENTS.md`]
- Do not bypass the active GSD workflow for repository edits. [VERIFIED: `AGENTS.md`]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing `tchivs/mb-image/png` MoonBit package | workspace source | Public PNG encoder and shared encode machine | It already owns the portable eager/chunk API, preflight, checksums, and all existing compression routes. [VERIFIED: `modules/mb-image/png/{moon.pkg,png.mbt,encode.mbt,stream_encode.mbt}`] |
| MoonBit toolchain | `moon 0.1.20260713`; `moonc v0.10.4`; `moonrun 0.1.20260713` | Compile/test the package on declared targets | Installed local baseline and repository stack policy. [VERIFIED: local `moon --version`; `AGENTS.md`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| Existing PNG semantic-interface policy registration | workspace source | Locks the additive public API exactly across declared targets | Update only the PNG interface entries when the enum/factories are added. [VERIFIED: `policy/foundation.json`] |

**Installation:** No external packages are needed or permitted for this phase. [VERIFIED: `.planning/REQUIREMENTS.md`; `modules/mb-image/png/moon.pkg`]

## Architecture Patterns

### System Architecture Diagram

```text
PngEncoder::new() / existing compression factory ─┐
PngChunkEncoder::new() / existing compression factory ─┼─> explicit PngFilterStrategy::None
new_with_filter_strategy(Adaptive) ────────────────────┘
                                                        │
                                                        v
                                      one private PngEncodeMachine constructor
                                                        │
                    Phase 38: both selections use existing filter-None scanline provider
                                                        │
                                                        v
                  _png_encode_preflight -> Stored / FixedOrStored / Dynamic plan
                                                        │
                       eager Writer acknowledgement / caller-lease acknowledgement
                                                        v
                                         deterministic PNG bytes and sticky terminals

Phase 39 only: Adaptive -> bounded row candidate selection -> same preflight/replay paths
```

The diagram describes the required Phase 38 data-flow invariant: the new selection must be retained through the shared construction boundary, while the emitted bytes still come from the proven None provider. [VERIFIED: existing flow in `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}`; Phase 39 boundary in `.planning/ROADMAP.md`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # public PngFilterStrategy and eager factory docs
├── encode.mbt              # shared eager adapter and atomic preflight call
├── stream_encode.mbt       # chunk factory and private selected-filter machine state
├── encode_test.mbt         # complete eager frozen-vector regression tests
└── stream_encode_test.mbt  # hostile-capacity chunk frozen-vector regression tests

policy/foundation.json      # exact generated PNG public interface registration
```

### Pattern 1: Additive selection with explicit legacy defaults

**What:** Keep legacy constructors as direct `Stored + None` calls. Existing `new_with_compression_strategy` calls must set `None` explicitly; only the new filter factory takes an `Adaptive` selection. [VERIFIED: direct Stored legacy pattern in `modules/mb-image/png/{png.mbt,stream_encode.mbt}`; [ASSUMED] filter-field adaptation]

**When to use:** Every public compatibility seam where a future capability must be nameable before its implementation changes bytes. [VERIFIED: Phase 32/35 precedent in `.planning/milestones/v0.10-phases/32-png-compression-strategy-and-compatibility/32-01-SUMMARY.md`; git `HEAD:.planning/phases/35-png-dynamic-strategy-compatibility/35-01-PLAN.md`]

**Recommended API shape:**

```moonbit
pub(all) enum PngFilterStrategy {
  None
  Adaptive
} derive(Eq)

pub fn PngEncoder::new_with_filter_strategy(
  strategy : PngFilterStrategy,
) -> PngEncoder

pub fn PngChunkEncoder::new_with_filter_strategy(
  source : @storage.ImageView,
  strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError]
```

[ASSUMED: exact type and factory identifiers; this follows the established public compression-factory signature and is intentionally a recommendation rather than a locked user choice.]

### Pattern 2: Private combined construction, public parallel factories

**What:** Add a private constructor accepting both compression and filter selections. Have legacy/default wrappers pass `(Stored, None)`, existing compression factories pass `(requestedCompression, None)`, and new filter factories pass `(Stored, requestedFilter)`. Preserve both fields in `PngEncoder`/`PngEncodeMachine`; Phase 38's `Adaptive` match delegates to the current None scanline byte provider. [ASSUMED: minimal implementation design; existing one-strategy wrapper pattern verified in `modules/mb-image/png/stream_encode.mbt`]

**When to use:** When two independent future controls must reach one atomic preflight/replay engine without breaking existing factory signatures. [VERIFIED: the shared strategy constructor and one-machine architecture in `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

### Anti-Patterns to Avoid

- **Changing `PngEncoder::new()` or `PngChunkEncoder::new(...)` to delegate to an Adaptive default:** this would violate the frozen filter-None compatibility boundary. [VERIFIED: `.planning/REQUIREMENTS.md`; `modules/mb-image/png/{png.mbt,encode_test.mbt,stream_encode_test.mbt}`]
- **Implementing Sub/Up/Average/Paeth or a winner rule in the compatibility phase:** that is Phase 39 scope and changes compression inputs, preflight lengths, work accounting, Adler-32, and replay. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]
- **Creating a second encoder/emitter for Adaptive:** this bypasses the sole atomic admission and acknowledgement-safe machine. [VERIFIED: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]
- **Adding a public combined compression/filter factory now:** Phase 38 exposes only independent filter-strategy configured factories; defer any combined compression/filter factory to Phase 39 after actual combination behavior exists. [VERIFIED: user decision]

## Compatibility Contract and Test Vectors

| Route | Required Phase 38 result | Test oracle |
|---|---|---|
| `PngEncoder::new()` | Exact pre-Phase-38 Stored/filter-None complete PNG bytes remain unchanged for RGB8 and straight-RGBA8 fixtures. [VERIFIED: `modules/mb-image/png/{png.mbt,encode_test.mbt}`] | Independent immutable complete `Bytes` literals, not output computed by another route. [VERIFIED: Phase 35 vector practice in `modules/mb-image/png/encode_test.mbt`] |
| `PngChunkEncoder::new(...)` | Same exact Stored/filter-None bytes under hostile schedules. [VERIFIED: `modules/mb-image/png/{stream_encode.mbt,stream_encode_test.mbt}`] | Drain only accepted `[0, written)` lease bytes under `[0, 1, 3, 2, 5]`, then compare to immutable literal. [VERIFIED: `modules/mb-image/png/stream_encode_test.mbt`] |
| `new_with_compression_strategy(Stored)` | Exact pre-Phase-38 Stored/filter-None bytes remain unchanged. [VERIFIED: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`] | Reuse the route's own captured complete literal, not `new()` as its oracle. [ASSUMED: stronger independent-vector rule for the configured Stored route.] |
| `new_with_compression_strategy(FixedOrStored)` | Exact pre-Phase-38 fixed-or-stored filter-None bytes remain unchanged. [VERIFIED: `modules/mb-image/png/encode.mbt`] | Complete repetitive RGB8/RGBA8 vectors with fixed-block bits retained. [VERIFIED: `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`] |
| `new_with_compression_strategy(DynamicOrFixedOrStored)` | Exact pre-Phase-38 Dynamic (including a strict Dynamic winner) filter-None bytes remain unchanged. [VERIFIED: existing opt-in route in `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}`] | Freeze the existing `128×1` periodic RGB8 strict-Dynamic winner as complete bytes, then require eager/chunk identity and a public complete-input decode; do not rely only on a BTYPE assertion. [VERIFIED: user decision; `modules/mb-image/png/stream_encode_test.mbt`] |
| `new_with_filter_strategy(Adaptive)` | In Phase 38 it is selectable but returns the frozen Stored/filter-None vector for compatible RGB8/RGBA8 inputs, eager and chunked. [ASSUMED: compatibility-shim behavior needed to defer filtering to Phase 39.] | Compare against the independent Stored literal, decode through `PngDecoder` with complete input, and preserve hostile-capacity eager/chunk identity. [VERIFIED: existing public decoder and drain patterns in `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`] |

The dynamic strict-winner vector is essential: a non-winning Dynamic test that happens to equal FixedOrStored does not prove that the established Dynamic filter-None emission remains byte-compatible. [VERIFIED: user decision; Phase 37 Dynamic route in `modules/mb-image/png/stream_encode_test.mbt`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Alternate eager/chunk output pipeline | New Adaptive encoder/emitter | The existing `PngEncodeMachine` with one retained filter-selection field | Preserves preflight, exact progress, CRC/Adler handling, acknowledgement semantics, and terminal behavior. [VERIFIED: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |
| Phase 38 adaptive transforms | Partial Sub/Up/Average/Paeth implementation | A Phase 38 `Adaptive -> None` compatibility shim | A filter transform changes every downstream DEFLATE-plan fact; all five filters and bounded scoring belong together in Phase 39. [VERIFIED: `.planning/ROADMAP.md`; [CITED: https://www.w3.org/TR/png-3/]] |
| Ad-hoc byte comparisons | Derived output versus another current route | Immutable complete PNG literals captured before implementation | A second dynamic/compression path can regress in lockstep; frozen vectors make the old wire representation the oracle. [VERIFIED: current legacy/fixed vector practice in `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`] |

**Key insight:** Filter selection is upstream input to every existing compression plan, so the only safe compatibility implementation is to carry the selection through the single machine while mapping it to the current filter-None provider until the complete bounded planner/replay change is delivered. [VERIFIED: compression plans consume `_png_fixed_scanline_byte`/`scanline_byte` in `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`; [ASSUMED] Phase 38 shim mapping.]

## Common Pitfalls

### Pitfall 1: A new factory silently changes a legacy default

**What goes wrong:** `new()` or the existing compression factory gains an implicit Adaptive default, causing different IDAT/CRC/Adler and complete PNG bytes. [VERIFIED: existing scanline bytes feed DEFLATE and checksums in `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

**How to avoid:** Every existing construction route must pass `PngFilterStrategy::None` explicitly and tests must compare complete pre-change byte literals. [ASSUMED: implementation action; test approach verified by existing vectors.]

### Pitfall 2: Treating Adaptive as implemented because the enum exists

**What goes wrong:** A premature Sub/Up/etc. branch makes Phase 38's new factory produce new compressed bytes without the required bounded candidate/work/replay contract. [VERIFIED: Phase 39 owns selection and atomic integration in `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]

**How to avoid:** Make the Phase 38 public docs explicit: Adaptive is an opt-in compatibility reservation that currently emits the None representation; Phase 39 changes only that new route. [ASSUMED: documentation wording recommendation.]

### Pitfall 3: Omitting a real Dynamic winner from legacy vectors

**What goes wrong:** Tests freeze only Stored and Fixed fallback cases, allowing a regression in `DynamicOrFixedOrStored` output to go undetected. [VERIFIED: the Dynamic strategy has its own plan branch in `modules/mb-image/png/encode.mbt`]

**How to avoid:** Freeze the existing `128×1` periodic RGB8 strict-Dynamic winner as complete bytes and require eager/chunk equality plus complete public decode. [VERIFIED: user decision; `modules/mb-image/png/stream_encode_test.mbt`]

### Pitfall 4: Bypassing atomic admission with a filter-specific branch

**What goes wrong:** Capability, output/work limit, or budget failures occur after an eager byte or caller lease is exposed. [VERIFIED: atomic preflight contract in `modules/mb-image/png/{encode.mbt,stream_encode_test.mbt}`]

**How to avoid:** Route the selected filter through the existing private combined constructor and leave `_png_encode_preflight` as the only pre-output admission point. [ASSUMED: implementation recommendation.]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Fixed filter-None Stored output only | Explicit Stored, FixedOrStored, and DynamicOrFixedOrStored compression selection with frozen filter-None routes | Phases 32–37 | Filter selection is the next independent compatibility axis; do not conflate it with compression strategy. [VERIFIED: `.planning/STATE.md`; `modules/mb-image/png/png.mbt`] |
| No filter opt-in | Phase 38 additive Adaptive reservation, with actual selection deferred | v0.12 Phase 38 plan | Public callers can name the future capability without changing established bytes. [VERIFIED: `.planning/ROADMAP.md`; [ASSUMED] factory implementation.] |

**Deprecated/outdated:** An Adaptive factory that immediately implements only one or a subset of standard filter types is not acceptable; the PNG standard defines method-0's exact five types and the project scopes their deterministic selection to Phase 39. [CITED: https://www.w3.org/TR/png-3/; VERIFIED: `.planning/ROADMAP.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The public type should be named `PngFilterStrategy` with `None` and `Adaptive` cases. | Summary; Architecture Patterns | Public naming is an API decision and may need renaming before implementation. |
| A2 | **RESOLVED:** Phase 38 exposes only independent filter-strategy configured factories; any combined compression/filter factory is deferred to Phase 39 after combination behavior exists. | Architecture Patterns; Open Questions | None — locked by user decision. |
| A3 | The Phase 38 Adaptive factory should default to Stored and emit current filter-None bytes until Phase 39. | Summary; Compatibility Contract | If product intent requires immediately pairing Adaptive with all compression routes, Phase 38 must expose a combined selector instead. |
| A4 | **RESOLVED:** Use the existing `128×1` periodic RGB8 strict-Dynamic winner as the frozen complete-byte Dynamic compatibility vector. | Compatibility Contract; Pitfalls; Open Questions | None — locked by user decision. |

## Open Questions (RESOLVED)

1. **Combined compression/filter factory boundary**
   - **Decision:** Phase 38 exposes only independent filter-strategy configured factories. Defer any combined compression/filter factory to Phase 39, after actual compression/filter combination behavior exists. [VERIFIED: user decision]
   - **Planning impact:** Retain a private combined construction seam only; do not publish a combined factory or claim combined behavior in Phase 38. [VERIFIED: user decision]

2. **Frozen strict-Dynamic compatibility vector**
   - **Decision:** Use the existing `128×1` periodic RGB8 strict-Dynamic winner as the immutable complete-byte Dynamic compatibility vector. [VERIFIED: user decision; `modules/mb-image/png/stream_encode_test.mbt`]
   - **Planning impact:** Assert its complete eager bytes, hostile-capacity chunk identity, and public complete-input decode; this locks the legacy Dynamic filter-None route without adding a new corpus or script. [VERIFIED: user decision; existing public test patterns in `modules/mb-image/png/stream_encode_test.mbt`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| MoonBit `moon` | Focused and four-target PNG tests | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` / `moonrun` | Target compilation/execution | ✓ | `v0.10.4` / `0.1.20260713` | — [VERIFIED: local toolchain output] |
| External packages/services | Phase 38 implementation | Not required | — | No install, service, FFI, host adapter, or download. [VERIFIED: `.planning/REQUIREMENTS.md`; `modules/mb-image/png/moon.pkg`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local toolchain; scope]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | No authentication surface. [VERIFIED: package-local encoder scope] |
| V3 Session Management | No | No session surface. [VERIFIED: package-local encoder scope] |
| V4 Access Control | No | No authority boundary is introduced. [VERIFIED: package-local encoder scope] |
| V5 Input Validation | Yes | Reuse `_png_encode_source` plus `_png_encode_preflight` capability, geometry, output, work, and budget checks. [VERIFIED: `modules/mb-image/png/encode.mbt`] |
| V6 Cryptography | No | CRC-32 and Adler-32 are integrity-format checks, not cryptographic controls; no cryptography is added. [VERIFIED: `modules/mb-image/png/stream_encode.mbt`] |

### Known Threat Patterns for the PNG Encoder

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Compatibility tampering through a changed legacy filter byte | Tampering | Explicit `None` on old routes; complete immutable eager/chunk vectors for Stored, FixedOrStored, and Dynamic. [ASSUMED: Phase 38 test addition; current constructor/vector pattern verified.] |
| Resource-check bypass in a filter-specific path | Denial of Service | One shared preflight and one budget charge before output visibility. [VERIFIED: `modules/mb-image/png/encode.mbt`] |
| Source mutation between preflight and replay | Tampering | Continue the acknowledgement-safe scalar replay model and existing sticky failure behavior; do not add staging or a second emitter. [VERIFIED: `modules/mb-image/png/{stream_encode.mbt,stream_encode_test.mbt}`] |

## Validation Architecture

Skipped: `workflow.nyquist_validation` is explicitly `false` in `.planning/config.json`. [VERIFIED: `.planning/config.json`]

## Sources

### Primary

- Repository PNG API, preflight, shared machine, and public tests: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt,encode_test.mbt,stream_encode_test.mbt}`. [VERIFIED: codebase]
- Roadmap, requirement, and state scope: `.planning/{ROADMAP.md,REQUIREMENTS.md,STATE.md,PROJECT.md}`. [VERIFIED: codebase]
- Prior additive compatibility precedent: Phase 32 summary and Phase 35 plan/verification from git history. [VERIFIED: codebase/git history]

### Secondary

- [PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — filter-byte framing, the exact method-0 filter set, per-scanline selection allowance, and adaptive-filter guidance. [CITED: https://www.w3.org/TR/png-3/]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new dependency; local toolchain and existing portable package were inspected. [VERIFIED: local toolchain; `modules/mb-image/png/moon.pkg`]
- Architecture: HIGH — the current single-machine/preflight/acknowledgement flow and prior additive strategy pattern were inspected. [VERIFIED: codebase]
- Public naming/factory shape: LOW — it is a minimal recommendation, not a locked user naming decision. [ASSUMED]
- Pitfalls and compatibility vectors: HIGH for existing routes; MEDIUM for the strengthened Dynamic-vector recommendation. [VERIFIED: codebase; ASSUMED]

**Research date:** 2026-07-22
**Valid until:** Phase 38 planning completion; this is codebase-specific and should be refreshed if the PNG public API changes first. [VERIFIED: current worktree inspection]
