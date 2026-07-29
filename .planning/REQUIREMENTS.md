# Requirements: MoonBit Native Foundation v0.35

**Defined:** 2026-07-30
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.35 Requirements

Requirements for the Text Shaping Foundation milestone. Each requirement maps
to exactly one roadmap phase.

### Public Text Contract

- [ ] **TXT-01**: Library authors can shape one bounded array of Unicode scalar values with one admitted static `Font` through an explicit deterministic horizontal API that requires script, default-or-exact language choice, `LeftToRight` or `RightToLeft` direction, a closed `rlig`/`liga`/`kern` feature policy, shaping limits, and one caller-owned budget, without ambient locale, normalization, bidi analysis, fallback, host font lookup, or I/O.
- [ ] **TXT-02**: A successful immutable shaped run exposes only same-font opaque glyph identities, zero-based scalar-origin clusters, checked signed design-unit advances and x/y offsets, `units_per_em`, explicit direction, and checked total advance; LTR records are in logical pen order, RTL records are reversed only for final pen order, and a ligature carries the minimum source scalar index of its consumed components.

### Bounded Layout Selection

- [ ] **LAY-01**: `mb-font` resolves one request-scoped bounded OpenType 1.9.1 Script/LangSys/Feature/Lookup plan from the exact caller-selected script and default-or-exact language system, includes the required feature plus supported `rlig`/`liga`/`kern` choices, de-duplicates selected lookup indices, and executes them once in ascending LookupList order with stored subtable preference and no public raw table, offset, or lookup facts.
- [ ] **LAY-02**: Selected layout paths support checked Coverage formats 1/2, ClassDef formats 1/2, GDEF 1.0 `GlyphClassDef`, `IGNORE_BASE_GLYPHS`/`IGNORE_LIGATURES`/`IGNORE_MARKS`, and one-hop GSUB type 7 or GPOS type 9 extension dispatch only to an admitted inner type, while malformed dependencies, recursive wrappers, reserved flags, mark filtering, mark attachment classes, feature variations, or any other selected unsupported capability fail closed and unrelated unselected rich tables do not over-reject the font.

### Substitution and Source Provenance

- [ ] **SUB-01**: Selected GSUB type 1 formats 1/2 and type 4 format 1 execute deterministically in logical writing order over cmap-derived glyph/source-interval seeds, honor validated class filtering and LookupList/subtable/ligature preference, preserve skipped glyphs, consume only matched ligature components, validate every substitute GID, propagate scalar-origin clusters, and initialize metrics from final substituted glyph identities before final LTR/RTL publication ordering.

### Positioning and Kerning

- [ ] **POS-01**: Selected GPOS type 2 PairPos formats 1/2 apply the closed static `xPlacement`, `yPlacement`, and `xAdvance` ValueRecord subset for either glyph with checked `Int64` accumulation, strict PairSet/Coverage and second-glyph ordering, explicit class-0 matrix semantics, bounded class-product preflight, the specified next-probe rule, and deterministic rejection of `yAdvance`, device/variation offsets, reserved bits, or other selected positioning operations.
- [ ] **KRN-01**: Kerning authority is decided once for the complete selected run: a supported selected GPOS `kern` plan is authoritative, otherwise the existing legacy format-0 `kern` path is used, while `kern=false` disables both; modern and legacy adjustments are never combined, fallback never occurs per pair, and malformed or unsupported selected GPOS never degrades silently to legacy data.

### Safety and Compatibility

- [ ] **SAF-01**: Malformed, unsupported, over-limit, over-budget, numerically overflowing, or source-mutated shaping fails with frozen structured input/data/capability/resource/state precedence, no partial run, and no partial caller or ancestor charge; parser, lookup, match, skip, compaction, metric, positioning, output, byte, allocation, allocation-size, and work dimensions are bounded, the complete charge is composed immutably, the source revision is checked at frozen stages and immediately before publication, and success commits exactly once.
- [ ] **CMP-01**: v0.35 preserves the existing opaque `Font` admission, cmap, metrics, legacy-kerning query, outline, collection, static-`glyf`, CFF1, module dependency, public-interface, and four-target behavior except for the reviewed additive opaque layout seam and the new independently publishable `mb-text` module.

### Qualification

- [ ] **QUA-01**: Maintainers can reproduce hand-derived generated `glyf` and CFF1 shaping facts, pinned licensed DejaVu Sans and Source Sans cases, hostile and resource/mutation outcomes, frozen v0.34 compatibility, pinned host-only fontTools and HarfBuzz comparison identities, and canonical semantic records whose normalized payloads are byte-identical across isolated `js`, `wasm`, `wasm-gc`, and `native` runs without any foreign production dependency.

## Future Requirements

Deferred to later RFC-led milestones.

### Complex Script Shaping

- **TEXT-COMPLEX-01**: Library authors can shape script runs that require joining, reordering, contextual substitution, cursive attachment, mark attachment, or other script-specific stages through an explicitly versioned capability profile.

### Unicode Text Processing

- **TEXT-UNICODE-01**: Library authors can normalize, segment, infer scripts, resolve paragraph bidi levels and mirroring, and form explicit shaping runs through reusable Unicode data and algorithm boundaries.

### Multi-Font Layout

- **TEXT-FALLBACK-01**: Library authors can select fallback fonts and merge stable multi-font runs without ambient discovery or platform-dependent shaping.
- **TEXT-LAYOUT-01**: Library authors can perform line breaking, vertical layout, justification, rich-text segmentation, and paragraph layout over positioned glyph runs.

### Extended Font Layout

- **TEXT-LAYOUT-02**: Library authors can opt into broader OpenType layout capabilities including contextual/chained lookups, mark filtering sets, mark attachment classes, device positioning, and variation-aware layout through bounded versioned profiles.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full Arabic, Syriac, Indic, Khmer, Tibetan, cursive, contextual, or mark-attachment shaping | These require script-specific preprocessing, reordering, joining, attachment, and lookup profiles beyond the closed Latin-style v0.35 contract. |
| Normalization, bidi paragraph analysis, mirroring, script/language inference, or grapheme segmentation | v0.35 accepts caller-segmented scalar runs and explicit choices; Unicode text processing belongs in separate reusable boundaries. |
| Font fallback, discovery, host lookup, multi-font merging, rich text, line breaking, justification, or vertical layout | The milestone shapes exactly one explicit horizontal run with one admitted font. |
| Arbitrary feature tags or broader GSUB/GPOS/GDEF operations | A closed feature and lookup profile is required for deterministic fail-closed capability and evidence claims. |
| Device positioning, variable fonts, FeatureVariations, CFF2, WOFF/WOFF2, AAT, or Graphite | These add independent binary, numeric, capability, and resource contracts. |
| Rasterization, hint execution, color/bitmap glyphs, authoring, subsetting, or serialization | v0.35 produces reusable design-space positioned glyph facts rather than pixels or modified fonts. |
| HarfBuzz, ICU, FreeType, platform shapers, or other FFI/runtime dependencies | Core shaping remains pure MoonBit and portable; foreign tools are qualification-only independent comparisons. |
| Persistent implicit caches or ambient host state | Request-scoped normalized facts preserve mutation, budget, and deterministic four-target authority. |
| Publication or stable API promotion | The new module remains an implementation candidate until a later explicit release/governance action. |

## Traceability

Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TXT-01 | Phase 108 | Pending |
| TXT-02 | Phase 108 | Pending |
| LAY-01 | Phase 109 | Pending |
| LAY-02 | Phase 109 | Pending |
| SUB-01 | Phase 110 | Pending |
| POS-01 | Phase 111 | Pending |
| KRN-01 | Phase 111 | Pending |
| SAF-01 | Phase 112 | Pending |
| CMP-01 | Phase 112 | Pending |
| QUA-01 | Phase 113 | Pending |

**Coverage:**

- v0.35 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-07-30*
*Last updated: 2026-07-30 after v0.35 research synthesis*
