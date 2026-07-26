# Requirements: MoonBit Native Foundation v0.32

**Defined:** 2026-07-26
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.32 Requirements

### Font Admission and Metrics

- [x] **FONT-01**: Library authors can admit one static TrueType-outline SFNT from caller-provided immutable bytes under explicit limits and inspect named font-wide and per-glyph horizontal metrics through a portable `tchivs/mb-font` API.

### Unicode Mapping

- [ ] **FONT-02**: Library authors can map any valid Unicode scalar through deterministic cmap format 12/4 selection, receiving glyph zero for a valid miss and a structured error for an invalid scalar or malformed mapping.

### Glyph Outlines

- [ ] **FONT-03**: Library authors can extract complete unhinted `Path2`-compatible outlines for valid simple glyphs and bounded one-level composite glyphs, with checked arithmetic and no partial geometry on failure.

### Kerning

- [ ] **FONT-04**: Library authors can query basic legacy horizontal format-0 kerning and distinguish neutral table absence or pair miss from present-but-unsupported or malformed kerning data.

### Qualification

- [ ] **FONT-05**: Maintainers can reproduce the complete public font workflow and hostile-input qualification with licensed immutable fixtures on `js`, `wasm`, `wasm-gc`, and `native`, without GUI state, host font discovery, FFI, or target-specific behavior.

## Future Requirements

### Font Containers and Outlines

- **FONT-06**: Library authors can open TrueType Collections, WOFF/WOFF2 containers, and CFF/CFF2 outline fonts through explicit format adapters.
- **FONT-07**: Library authors can inspect and instantiate OpenType variable-font axes and variations under bounded deterministic semantics.

### Text and Rendering

- **FONT-08**: Text-layout consumers can apply GSUB/GPOS shaping features through the separately chartered `mb-text` boundary.
- **FONT-09**: Consumers can select and fall back across installed or registered font families through a separate discovery/registry contract.
- **FONT-10**: Rendering consumers can opt into a bounded hinting or outline-adjustment capability without moving rasterization into `mb-font`.

## Out of Scope

| Feature | Reason |
|---------|--------|
| CFF/CFF2, TTC/OTC, WOFF/WOFF2, variable fonts, and color/bitmap glyphs | Each adds a distinct container, outline, or variation state machine; the first milestone must prove the static TrueType contract independently. |
| TrueType hinting bytecode execution | A VM materially expands the hostile-input and portability surface and is not required for reusable unhinted outlines. |
| GSUB/GPOS shaping, bidi, line breaking, fallback, and font selection | These are owned by `mb-text` or a future registry boundary, not single-font parsing. |
| Rasterization and colored text | Outline-to-pixel production remains owned by consumers such as `mb-canvas`; `mb-font` returns geometry only. |
| Font writing, editing, and subsetting | v0.32 is a bounded read/query contract; mutation and serialization require separate compatibility rules. |
| Ambient filesystem or operating-system font discovery | Portable library operations must consume caller-provided bytes and remain deterministic on all supported targets. |

## Traceability

Roadmap phases populate this table. Every v0.32 requirement must map to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FONT-01 | Phase 97 | Complete |
| FONT-02 | Phase 98 | Pending |
| FONT-03 | Phase 99 | Pending |
| FONT-04 | Phase 98 | Pending |
| FONT-05 | Phase 100 | Pending |

**Coverage:**

- v0.32 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0

---
*Requirements defined: 2026-07-26*
*Last updated: 2026-07-26 after v0.32 research*
