# Requirements: MoonBit Native Foundation v0.34

**Defined:** 2026-07-28
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.34 Requirements

Requirements for the CFF Outline Foundation milestone. Each requirement maps to exactly one roadmap phase.

### CFF1 Structure and Keying

- [x] **CFF-01**: Library authors can admit the exact supported static OpenType CFF1 profile from bounded caller-owned `OTTO` bytes through the existing font boundary, with checked CFF-local Header, INDEX, DICT, String, CharStrings, Private DICT, and global/local subroutine facts and stable explicit rejection of mixed, CFF2, variable, or otherwise unsupported profiles.
- [x] **CFF-02**: Every admitted GID resolves to exactly one bounded CharString and execution environment for both name-keyed fonts and CID-keyed fonts, including predefined/custom charset and Encoding data, `ROS`, FDArray, FDSelect formats 0/3, per-FD Private DICT/local Subrs, FontMatrix facts, and checked SID/CID/cardinality rules.

### Type 2 Execution and Retained Metrics

- [x] **T2-01**: Maintainers have one deterministic pure-MoonBit Type 2 interpreter covering the supported static number, stack, transient, arithmetic, logical, storage, width, line, curve, flex, local/global subroutine, termination, and project-owned `random` semantics with target-identical fixed-point results.
- [x] **T2-02**: Type 2 hint and stem operators are validated as non-rendering framing data, including exact `hintmask`/`cntrmask` byte consumption, while explicit stack, stem, frame, depth, byte, call, work, contour, command, point, allocation, mutation, and caller-budget limits prevent partial state, host recursion, or unbounded execution.
- [x] **CFF-03**: CFF admission executes every glyph through the same interpreter before publication, retains truthful compact conservative integer bounds per GID, keeps `hmtx` authoritative for public advance and side-bearing metrics, and publishes no `Font`, bounds, or committed charge when any structural, program, numeric, resource, or mutation check fails.

### Public Font and Collection Integration

- [x] **CFF-04**: A successfully admitted standalone static CFF1 font is returned as the existing opaque `Font`; Unicode mapping, glyph identity, metrics, kerning, and errors remain format-neutral, and outline queries atomically return complete native cubic `Path2` geometry without exposing CFF internals or approximating cubics as quadratics.
- [x] **CFF-05**: A supported CFF1 face selected from TTC/OTC uses the same admission and outline implementation as standalone CFF1, preserves root-relative collection and table-local CFF offset authority plus face-local common tables, and leaves all previously qualified static-`glyf` standalone and collection behavior unchanged.

### Qualification

- [x] **CFF-06**: Maintainers can reproduce generated name-keyed and multi-FD CID vectors, hostile/resource/mutation cases, immutable licensed Latin and CJK evidence with complete provenance, frozen `glyf` compatibility, standalone and collection public workflows, independent host-oracle comparisons, declared performance baselines, and exactly four equal semantic records from isolated `js`, `wasm`, `wasm-gc`, and `native` runs.

## Future Requirements

Deferred to later RFC-led milestones.

### Variable and CFF2 Outlines

- **CFF2-01**: Library authors can select bounded variable-font axes and instantiate CFF2 outlines with checked `VariationStore`, `vsindex`, and `blend` semantics.

### Compressed Web Containers

- **WOFF-01**: Library authors can admit bounded WOFF1 data through a reusable pure-MoonBit zlib/DEFLATE and table-reconstruction boundary.
- **WOFF-02**: Library authors can admit bounded WOFF2 data through a pure-MoonBit Brotli and transformed-table reconstruction boundary.

### Text and Rendering

- **TEXT-01**: Library authors can shape Unicode text into positioned glyph runs through explicit script, language, direction, and feature inputs.
- **FONT-RASTER-01**: Library authors can rasterize reusable outlines under an explicit hinting and sampling policy.

## Out of Scope

| Feature | Reason |
|---------|--------|
| CFF2 and variable-font instantiation | `VariationStore`, `vsindex`, `blend`, axis normalization, and instance selection require a separate semantic and resource contract. |
| WOFF1/WOFF2 decode | Compression and transformed-table reconstruction require reusable DEFLATE/Brotli boundaries independent from CFF semantics. |
| Shaping, bidi, GSUB, or GPOS | Text layout is a higher layer over stable glyph identity, metrics, and outlines. |
| Hint execution or rasterization | v0.34 validates hint framing but returns reusable unhinted design-space paths; device execution belongs to the rendering layer. |
| Color/bitmap glyphs | COLR/CPAL, SVG glyph, CBDT/CBLC, and sbix profiles have independent data and rendering contracts. |
| Font subsetting, authoring, serialization, discovery, fallback, or host lookup | The milestone is deterministic, read-only, caller-buffered font admission rather than an authoring or platform-discovery system. |
| Foreign runtime font stacks or ambient I/O | Core parsing and execution remain pure MoonBit over caller-owned bytes on all four targets. |
| Public raw CFF offsets, INDEXes, DICTs, or CharStrings | CFF storage remains a private implementation detail behind the opaque format-neutral `Font`. |

## Traceability

Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CFF-01 | Phase 104 | Complete |
| CFF-02 | Phase 104 | Complete |
| T2-01 | Phase 105 | Complete |
| T2-02 | Phase 105 | Complete |
| CFF-03 | Phase 105 | Complete |
| CFF-04 | Phase 106 | Complete |
| CFF-05 | Phase 106 | Complete |
| CFF-06 | Phase 107 | Complete |

**Coverage:**

- v0.34 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0

---
*Requirements defined: 2026-07-28*
*Last updated: 2026-07-28 after v0.34 roadmap creation*
