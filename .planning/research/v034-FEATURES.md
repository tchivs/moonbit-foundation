# Feature Research

**Domain:** Desktop-grade, bounded static OpenType CFF1 admission and cubic outline extraction through the existing `tchivs/mb-font/font` contract
**Milestone:** v0.34 CFF Outline Foundation
**Researched:** 2026-07-28
**Confidence:** MEDIUM

Normative format conclusions are cross-checked against the current Microsoft OpenType 1.9.1 specification and Adobe Technical Notes #5176/#5177. The GSD confidence seam classifies the Brave research route as MEDIUM even when cross-verified. Existing MNF public behavior and source boundaries are HIGH-confidence local evidence.

## Executive Position

v0.34 should make static CFF1 a second outline backend of the existing opaque `Font`; it should not create a parallel CFF-facing public object model. A caller that opens a valid standalone CFF1 OTF or selects a CFF1 face from a TTC/OTC should keep using the same:

```text
Font
├── units_per_em / global_bounds / line_metrics
├── glyph_for_scalar / glyph_id
├── horizontal_metrics / kerning
└── outline(glyph, budget) -> Path2
                              ├── MoveTo
                              ├── LineTo
                              ├── CubicTo
                              └── Close
```

The format-specific distinction belongs behind admission. The existing `Path2::CubicTo` already represents native Type 2 geometry, so converting CFF cubic curves to quadratics would be a loss of fidelity and an unnecessary feature.

“Desktop-grade minimum complete” means both ordinary name-keyed Latin fonts and CID-keyed CJK fonts, not a Latin-only sample decoder. It also means the full static CFF1 data path needed to choose the correct CharString and Private DICT, execute normal Type 2 programs and subroutines, validate non-rendered hints, and reject malformed or exhausted input atomically. It does not mean CFF2, variable instantiation, shaping, hint execution, or rasterization.

## Feature Landscape

### Table Stakes (Users Expect These)

Features in this section are non-negotiable for the v0.34 milestone. Omitting one either rejects ordinary desktop CFF1 fonts or makes CFF behavior inconsistent with the already-shipped `Font` contract.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Static CFF1 SFNT profile admission | Desktop OpenType engines distinguish `CFF ` from `glyf` and CFF2 by table content, not extension | HIGH | Admit `OTTO` + exactly one supported static outline profile. Preserve current `0x00010000`/`glyf` behavior and structured rejection for mixed or variable profiles. |
| Complete CFF header and fixed-prefix parsing | Every CFF1 table begins with Header, Name INDEX, Top DICT INDEX, String INDEX, Global Subr INDEX | MEDIUM | Require CFF major version 1, a valid header size, one OpenType Name INDEX entry, and bounded, monotonic object ranges. Unknown future header bytes may be skipped only within the declared header size. |
| Reusable bounded INDEX decoder | Name, Top DICT, String, Global Subrs, CharStrings, FDArray, and local Subrs all use INDEX | HIGH | Validate count, `OffSize` 1–4, 1-based first offset, monotonic offsets, final extent, empty INDEX form, object count/bytes, and every derived range before exposing a view. Never materialize attacker-sized object arrays implicitly. |
| Top/Private/Font DICT decoding | CharStrings, charset, Encoding, Private DICT, Subrs, ROS, FDArray, FDSelect and FontMatrix are selected through DICT operands | HIGH | Support integer and real encodings, defaults, escaped operators, operand cardinality/type, duplicate/conflicting required keys, checked offset bases, and bounded operand count. Reject reserved encodings and non-finite/out-of-range derived values. |
| Name-keyed CFF1 selection | Common desktop OTF fonts use SID-based glyph names with one Private DICT | HIGH | Support standard/custom String INDEX SIDs, predefined ISOAdobe/Expert/ExpertSubset charsets, custom charset formats 0/1/2, predefined Standard/Expert encodings, custom Encoding formats 0/1 and supplements. GID 0 remains `.notdef`. |
| CID-keyed CFF1 selection | CJK desktop OTFs commonly use ROS + CID charset + per-FD private data | HIGH | Support ROS, CID charsets, FDArray, FDSelect formats 0 and 3, per-glyph FD choice, per-FD Private DICT and local Subrs. CID fonts omit CFF Encoding and cannot use predefined charsets. Validate every FD index and sentinel/range. |
| CharStrings/OpenType glyph identity agreement | Consumers already use opaque OpenType `GlyphId` values from `cmap` | MEDIUM | Enforce `maxp.numGlyphs == CharStrings INDEX count`; OpenType GID equals CharStrings GID. CFF charset maps a GID to SID/CID, but must not renumber public glyphs. |
| Preserve OpenType `cmap` authority | Unicode mapping is already deterministic and format-independent | LOW | Parse/validate CFF Encoding as CFF structure, but `Font::glyph_for_scalar` continues to use the admitted OpenType `cmap`. CFF Encoding is not a Unicode mapping and is absent for CID-keyed fonts. |
| Preserve OpenType metrics authority | Existing consumers expect identical font-wide and per-glyph metric APIs | HIGH | Continue using `head`, `hhea`, `OS/2`, `hmtx`, and `maxp`. Current OpenType guidance makes `hmtx` advance widths authoritative; this is essential because collection faces may share one CFF table but have different `hmtx` values. Type 2 width syntax still must be decoded and validated. |
| Truthful CFF glyph bounds and right side bearing | `horizontal_metrics` currently exposes optional bounds and a computed right-side bearing | HIGH | CFF has no `glyf` header to read. Planning must choose a bounded way to derive and retain canonical CFF glyph bounds before claiming parity. Do not synthesize zero extent, return a bogus right bearing, or perform unbudgeted lazy CharString execution. |
| FontMatrix/font-unit normalization | CFF coordinates can be fractional and CID Font DICTs can select local matrices | HIGH | Apply validated Top/Font DICT matrix semantics so emitted `Path2` coordinates are in the same font-unit space as existing outlines and metrics. Use checked fixed-point accumulation and convert to `Point2` only at publication to maximize four-target determinism. |
| Full static Type 2 number and stack machine | Real CharStrings are compact stack programs, not just drawing opcode streams | HIGH | Decode compact integers, `shortint`, 16.16 numbers, arithmetic, logic, conditional, transient-array and stack manipulation operators. Enforce operand types/cardinality, division/sqrt/index/roll bounds, 48-element argument stack, and deterministic behavior for `random`. Reject reserved operators. |
| All normal Type 2 path operators | Desktop fonts use specialized compact line/curve encodings | HIGH | Implement `rmoveto`/`hmoveto`/`vmoveto`, `rlineto`/`hlineto`/`vlineto`, `rrcurveto`, `rcurveline`, `rlinecurve`, `vvcurveto`, `hhcurveto`, `vhcurveto`, `hvcurveto`, `flex`, `hflex`, `hflex1`, and `flex1`. Emit native `LineTo`/`CubicTo`; close prior contours on a new moveto and close the final contour at `endchar`. |
| Local and global subroutines | Subroutinization is CFF’s normal outline de-duplication mechanism | HIGH | Implement `callsubr`, `callgsubr`, `return`, the specified count-based biases (107/1131/32768), shared operand stack behavior, per-FD local Subrs, checked indices, and a caller limit no looser than the format’s depth-10 implementation limit. |
| Width and `endchar` semantics | Width is detected through the first stack-clearing operator and valid empty glyphs may be only `endchar` | MEDIUM | Correctly distinguish optional width by operator parity, apply `defaultWidthX`/`nominalWidthX`, require legal termination, and validate the decoded width even though public advance comes from `hmtx`. Include bounded handling of the deprecated four-operand `endchar` composite form if licensed qualification fonts exercise it. |
| Hint validation without hint execution | Hint bytes affect bytecode framing even when outlines are unhinted | HIGH | Parse `hstem`, `vstem`, `hstemhm`, `vstemhm`; count at most 96 total stems; consume exactly `ceil(stems/8)` bytes after `hintmask`/`cntrmask`; validate unused bits and sequencing. Hints must not alter published geometry in v0.34. `dotsection`, if accepted for legacy compatibility, is a no-op. |
| Bounded cubic path publication | Untrusted programs can expand small bytecode into large geometry | HIGH | Add explicit limits for CharString bytes, executed operators/work, calls/depth, emitted commands/contours, numeric magnitude and allocations. Build into private scratch state and publish one `Path2` only after successful termination and final source-revision check. |
| Atomic standalone admission | `Font::open` must not publish a partially validated CFF font or charge a failed transaction | HIGH | Reuse the existing admission ledger, checked directory/checksum machinery, retained `ByteView`, mutation guards and caller-owned `Budget`. Structural CFF admission and any required precomputed metric facts must commit as one transaction. |
| TTC/OTC CFF face selection | v0.33 already classifies `FontFaceProfile::Cff` but refuses to open it | HIGH | Extend the existing root-relative, no-copy selected-face adapter. A collection may share one CFF table, while face-local `name`, `hmtx`, `cmap` and other tables remain authoritative. Unsupported sibling faces must stay isolated. |
| Existing kerning boundary unchanged | CFF outline format does not redefine legacy pair kerning | LOW | Preserve current `kern` behavior, including absence/miss/unsupported distinctions. GPOS shaping remains deferred. |
| Four-target generated and licensed qualification | “Works on one generated Latin font” is not desktop interoperability | HIGH | Require generated name-keyed/CID-keyed fixtures, hostile mutations, at least one licensed name-keyed desktop OTF and one licensed CID-keyed CJK OTF, standalone and collection routes, semantic oracles, frozen existing-`glyf` evidence, and identical results on `js`, `wasm`, `wasm-gc`, and `native`. |

### Differentiators (Competitive Advantage)

These do not widen the supported font format; they make MNF’s implementation more reusable and trustworthy than a typical thin wrapper.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| One opaque `Font` across `glyf` and CFF1 | Downstream PDF/SVG/canvas/CLI code does not branch on outline storage | MEDIUM | Keep CFF INDEX/DICT/SID/CID facts private. Format-specific public inspection is unnecessary for the v0.34 goal. |
| Native cubic `Path2` fidelity | CFF curves survive without foreign libraries or cubic-to-quadratic approximation | LOW | Existing `PathCommand::CubicTo` is already portable and flattenable by consumers. |
| Caller-authorized resource model | Fonts from documents, uploads, or agents can be processed with explicit authority | HIGH | Separate semantic limits from the authoritative `Budget`; fail with stable resource errors rather than host OOM, recursion failure, or target-dependent timeout. |
| Mutation-atomic retained views | Caller-owned bytes remain zero-copy without silent time-of-check/time-of-use drift | HIGH | Preserve revision guards before reads and immediately before publishing `Font`, metrics, or `Path2`. Include subroutine and FD selection in mutation probes. |
| Deterministic full-program execution | The same valid CharString yields the same command sequence and coordinates on every target | HIGH | Use checked fixed-point interpreter state and a documented deterministic PRNG rule for the Type 2 `random` operator. Avoid target `Double` arithmetic until final conversion. |
| Qualification with independent semantic oracles | Maintainers can distinguish parser agreement from shared implementation bugs | HIGH | Use fontTools/FreeType only as test-time oracles; production remains pure MoonBit. Compare glyph order, selected FD, command sequence, control points, bounds, metrics and failure class. |
| Capability-preserving collection reuse | Shared CFF data is not copied or rewritten merely to open one collection face | MEDIUM | Reuse v0.33’s root-relative selected-face seam and fresh per-call limits/budgets. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Public CFF parser/DICT/charset objects | Useful for font inspection tools | Exposes offsets and format internals before the stable consumer contract is proven; creates a second public model | Keep format facts private; expose outlines, metrics, mapping and glyph identity through `Font`. Consider inspection in a later RFC. |
| Latin-only or name-keyed-only “CFF support” | Smaller initial parser | Rejects ordinary CID-keyed CJK desktop fonts and mislabels a prototype as desktop capability | Treat name-keyed and CID-keyed admission as one v0.34 table stake. |
| Only a subset of Type 2 curve operators | Generated fixtures can avoid specialized opcodes | Real fonts use compact alternating curve, flex and subroutine forms | Implement and independently qualify the complete static Type 2 execution surface. |
| Treat CFF Encoding as Unicode `cmap` | Both appear to map codes to glyphs | CFF Encoding is an 8-bit PostScript encoding, custom forms map to GID, and CID fonts omit it | Continue using the OpenType `cmap`; parse CFF Encoding only for CFF validity/legacy composite semantics. |
| Trust Type 2 width as public advance | Width is embedded in CFF1 CharStrings | Current OpenType engines use `hmtx`, and collection faces sharing CFF may have distinct `hmtx` advances | Validate CharString width syntax; report existing `hmtx` metrics. |
| Return `bounds=None` or fake zero CFF extent by default | Avoids decoding geometry for metrics | Produces false right-side bearings and breaks format-neutral `Font` behavior | Resolve bounded derived-bounds ownership during planning; either precompute atomically or add an honest budgeted contract before admission. |
| Execute CFF hints | Better small-size screen appearance | Requires device scale, raster policy, blue zones/stem darkening, and a hinting engine; output would no longer be reusable design-space geometry | Validate and skip hints; return deterministic unhinted cubic paths. |
| Rasterize glyphs in `mb-font` | Gives pixels directly | Violates the accepted `mb-font`/`mb-canvas` boundary and forces raster dependencies on metric/inspection tools | Consumers pass `Path2` to `mb-canvas`. |
| Convert cubic CFF curves to quadratics | Reuse the TrueType lowering path | Adds approximation policy, more points/work, and geometry drift | Emit `CubicTo` directly. |
| CFF2 or variable-font partial acceptance | CFF2 looks similar to CFF1 | CFF2 removes CFF1 structures and operators, raises stack rules, adds VariationStore/`vsindex`/`blend`, and changes width/termination semantics | Reject `CFF2` and variation profiles distinctly; plan a separate milestone. |
| WOFF1/WOFF2 admission | Common web delivery containers | Adds DEFLATE/Brotli/transformed-table boundaries unrelated to CFF semantics | Add reusable decompression/container adapters in a separate milestone. |
| Shaping/GSUB/GPOS/bidi | Needed for text rendering | String-level layout is owned by `mb-text`, not outline decoding | Keep scalar-to-GID `cmap`, basic legacy `kern`, metrics and outlines only. |
| Foreign production stack (FreeType/fontTools) | Fastest path to broad support | Breaks four-target portability and MoonBit-native credibility; FFI ownership becomes the product | Use mature engines as independent qualification oracles only. |
| Font authoring, subsetting, serialization | Natural follow-on for parsed data | Requires preserving/rebuilding offsets, subroutinization, SIDs/CIDs, checksums and layout tables; it is a separate product surface | Make v0.34 read-only. |
| Ambient filesystem/font discovery | Convenient desktop API | Violates deterministic automation and capability boundaries | Continue accepting caller-owned bounded `ByteView`. |
| Color/bitmap glyph fallback | Modern fonts may contain color tables | Does not belong to monochrome CFF1 outline extraction and creates image/color dependencies | Defer COLR/CPAL, SVG, CBDT/CBLC and `sbix` to separate milestones. |

## Feature Dependencies

```text
[Existing SFNT directory/checksum + Font admission ledger]
    └──requires──> [CFF1 profile gate]
                       └──requires──> [bounded INDEX decoder]
                                          └──requires──> [Top/Private DICT decoder]
                                                               ├──requires──> [name-keyed charset + Encoding]
                                                               └──requires──> [CID ROS + FDArray + FDSelect]

[CharStrings INDEX + selected Private DICT/local Subrs]
    └──requires──> [bounded Type 2 machine]
                       ├──requires──> [numbers + operand/transient stacks]
                       ├──requires──> [hint parsing/mask skipping]
                       ├──requires──> [local/global subroutine calls]
                       └──requires──> [line/cubic/flex lowering]
                                          └──publishes──> [existing cubic Path2]

[OpenType GID == CharStrings GID] ──preserves──> [existing cmap/GlyphId]
[OpenType hmtx authority] ──preserves──> [existing horizontal metrics]
[CFF geometry bounds] ──required-by──> [truthful bounds + right-side-bearing]

[Standalone CFF Font admission]
    └──enables──> [TTC/OTC CFF open_face]
                       └──enables──> [licensed collection qualification]

[CFF2/variable] ──conflicts-with──> [static CFF1-only interpreter]
[hint execution/rasterization] ──conflicts-with──> [design-space Path2 boundary]
```

### Dependency Notes

- **INDEX precedes every higher CFF feature:** one reusable checked decoder prevents inconsistent offset/count behavior across seven structures.
- **DICT precedes name/CID selection:** the selected CharStrings, charset, Encoding, Private DICT, FDArray and FDSelect are all offset-reached through Top/Font/Private DICT keys.
- **CID selection precedes Type 2 execution:** the glyph’s FD determines FontMatrix, Private DICT, width defaults and local Subrs.
- **Hint parsing is required even without hint execution:** mask bytes are inline bytecode; skipping the wrong length desynchronizes all later operators.
- **Metrics depend on geometry policy:** advance/LSB are available from `hmtx`, but truthful bounds and RSB need a CFF geometry extent under an explicit resource model.
- **Standalone admission should precede collection opening:** collection selection should adapt root-relative ranges into the same admission path, not fork a second CFF parser.
- **Qualification depends on both keying models:** a name-keyed generated font cannot validate FDSelect/per-FD local Subrs; a CID font alone cannot validate Encoding and SID behavior.

## MVP Definition

For this foundation milestone, “MVP” is the smallest honest desktop-capable vertical slice, not a reduced format prototype.

### Launch With (v0.34)

- [ ] Static `OTTO` + `CFF ` standalone admission through the existing `Font::open`.
- [ ] One bounded shared INDEX decoder and strict Top/Private/Font DICT decoding.
- [ ] Both name-keyed and CID-keyed glyph/Private-DICT selection.
- [ ] Full normal Type 2 path, arithmetic/stack, hint-framing and local/global subroutine execution.
- [ ] Native cubic `Path2` publication with atomic budget, work, mutation and limit failure.
- [ ] Existing `cmap`, `GlyphId`, font metrics, per-glyph metrics, `kern`, checksum and error contracts preserved.
- [ ] CFF1 `FontCollection::open_face` through the retained collection root.
- [ ] Generated, hostile, licensed name-keyed, licensed CID-keyed, existing-`glyf`, collection and four-target qualification evidence.

### Add After Validation (v0.34.x)

- [ ] Performance tuning that does not change commands, coordinates, errors or public API — trigger only after declared licensed Latin/CJK workloads establish a reproducible baseline.
- [ ] Additional licensed corpus coverage and compatibility forms — add when a real font exposes a valid CFF1 construct not represented in launch fixtures.
- [ ] Optional CFF metadata inspection — only after a concrete consumer need and RFC review; do not leak raw offsets.

### Future Consideration (v0.35+)

- [ ] CFF2 and variable-font instantiation — separate parser/interpreter semantics and variation-store authority.
- [ ] WOFF1/WOFF2 — separate reusable compression/container boundary.
- [ ] Shaping, GSUB/GPOS and bidi — belongs to `mb-text`.
- [ ] Hint execution and rasterization — separate device-aware `mb-canvas` integration.
- [ ] Color/bitmap glyphs — separate color/image/scene architecture.
- [ ] Subsetting, authoring and serialization — separate mutable font-data model.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| CFF1 profile + INDEX/DICT admission | HIGH | HIGH | P1 |
| Name-keyed selection | HIGH | HIGH | P1 |
| CID-keyed FDArray/FDSelect selection | HIGH | HIGH | P1 |
| Full Type 2 path/flex machine | HIGH | HIGH | P1 |
| Local/global subroutines | HIGH | HIGH | P1 |
| Hint validation/mask framing | HIGH | HIGH | P1 |
| Cubic `Path2` publication | HIGH | MEDIUM | P1 |
| OpenType GID/`cmap`/`hmtx` integration | HIGH | MEDIUM | P1 |
| Truthful bounded glyph bounds/RSB | HIGH | HIGH | P1 |
| TTC/OTC CFF face opening | HIGH | HIGH | P1 |
| Atomic limits/budget/mutation behavior | HIGH | HIGH | P1 |
| Four-target generated/licensed/hostile qualification | HIGH | HIGH | P1 |
| Deterministic `random` and legacy compatibility forms | MEDIUM | MEDIUM | P1 if exercised by valid qualification; otherwise P2 with explicit unsupported result |
| Performance tuning/caching | MEDIUM | MEDIUM | P2 |
| Public CFF metadata inspection | LOW | HIGH | P3 |
| CFF2/variable, WOFF, shaping, hinting, rasterization | Future | HIGH | Deferred |

**Priority key:**

- P1: Must have for an honest v0.34 launch.
- P2: Add after semantic correctness and interoperability are frozen.
- P3: Requires concrete consumer demand and likely RFC/API work.

## Reference Implementation Feature Analysis

These projects are compatibility references, not production dependencies.

| Feature | OpenType/Adobe specifications | fontTools | FreeType | MNF v0.34 approach |
|---------|-------------------------------|-----------|----------|--------------------|
| CFF1 container | Normative Header/INDEX/DICT/charset/Encoding/FD structures | Reads/writes CFF1 and CFF2 | Dedicated CFF driver | Read-only, bounded CFF1 only |
| Name-keyed fonts | SID charset + predefined/custom Encoding | `cffLib` exposes charset/Encoding/CharStrings | Supported | Required P1 |
| CID-keyed fonts | ROS + CID charset + FDArray/FDSelect | `cffLib` models FDArray/FDSelect | Supported | Required P1, including per-FD Subrs |
| Type 2 execution | #5177 defines complete operators and limits | Decompile/compile/interpreter tooling | Production outline loading | Pure MoonBit bounded interpreter |
| Cubic output | CFF uses third-order Béziers | Pens expose cubic commands | Outline decomposition exposes cubic curves | Direct `Path2::CubicTo` |
| Hints | Defined for rasterizer guidance | Preserved/edited | Device-aware CFF hinting engine | Validate and skip; no device effects |
| Resource contract | Fixed format implementation limits, not a caller authority model | General-purpose Python exceptions/limits | Library-level error handling | Explicit `FontLimits` + authoritative `Budget` + atomic publication |
| Portability | Format standard | Python runtime | Native C library | Same MoonBit behavior on four targets |
| Collections | CFF table can be shared across collection faces | `TTCollection`/`TTFont` tooling | Face selection | Reuse existing root-relative no-copy `FontCollection` adapter |

## Desktop-Level Acceptance Matrix

| Evidence class | Minimum proof |
|----------------|---------------|
| Generated name-keyed | Predefined and custom charset/Encoding, String INDEX, private widths, all path operator families, local/global Subrs, hints/masks, empty glyph, fractional operands |
| Generated CID-keyed | ROS, CID charset formats, FDArray, FDSelect formats 0 and 3, at least two FDs with distinct Private DICT/local Subrs and matrix/width defaults |
| Licensed name-keyed desktop OTF | Unicode mapping, metrics, representative straight/cubic/flex/subr glyphs, oracle command/control-point comparison |
| Licensed CID-keyed CJK OTF | Large charset, high GIDs, multiple FD ranges, CJK glyph outlines, bounded work and exact oracle facts |
| Collection | At least two selected CFF faces, shared-table case, face-local `hmtx`/`cmap` facts, unsupported sibling isolation, TTC v1/v2 compatibility |
| Hostile structural | Truncated Header/INDEX/DICT, invalid OffSize/offset monotonicity, range overflow, bad SID/CID/FD, malformed supplements/sentinels, CharStrings/maxp mismatch |
| Hostile program | Stack under/overflow, bad operands, reserved opcodes, bad subr bias/index/return/depth, recursion/work exhaustion, mask truncation, numeric overflow/non-finite conversion, excessive path growth |
| Atomicity | No `Font`, metric fact, `Path2`, committed budget charge or leaked intermediate survives failure or source mutation |
| Compatibility | Existing standalone `glyf` and TTC/OTC bytes, metrics, mappings, kerning, outlines, errors and interface remain frozen |
| Portability | Identical semantic records and complete package tests on `js`, `wasm`, `wasm-gc`, and `native` under the pinned toolchain |

## Roadmap Impact

Recommended phase structure:

1. **CFF1 structural admission and keying**
   - Build the shared INDEX/DICT layer, static profile gate, name-keyed and CID-keyed selection, semantic limits, and generated structural fixtures.
   - End with private/internal proof that every GID selects exactly one bounded CharString + Private DICT/local-Subr environment.
   - Do not publish CFF `Font` yet if truthful per-glyph bounds/RSB ownership is unresolved.

2. **Bounded Type 2 to cubic `Path2`**
   - Implement fixed-point program state, all normal drawing/flex operators, width rules, hint framing, local/global Subrs, arithmetic/stack/transient behavior, deterministic random policy, legacy forms selected for compatibility, and atomic scratch geometry.
   - Close the glyph-bounds/right-side-bearing decision here because the same geometry semantics must feed both outline and metrics.

3. **Opaque `Font` and collection integration**
   - Admit standalone CFF1 through `Font::open`, enable `FontFaceProfile::Cff` in `FontCollection::open_face`, retain `cmap`/`hmtx`/`kern` authority, and freeze existing `glyf` behavior.
   - Prove shared-CFF collection faces can retain distinct face-local mapping/metrics.

4. **Desktop interoperability and four-target qualification**
   - Add licensed name-keyed and CID-keyed corpora, independent command/metric oracle records, closed hostile matrices, mutation/resource evidence, existing-`glyf` regression, exact API/dependency checks, and four-target semantic equality.
   - Performance claims require named Latin and CJK workloads with reproducible baselines; correctness gates precede optimization.

**Ordering rationale:** CFF structure chooses the execution environment; the Type 2 machine consumes that environment; public `Font` admission must not occur until geometry and metrics are truthful; collection enablement should reuse the proven standalone path; licensed/four-target qualification must exercise the final public route.

**Research flags for planning:**

- Phase 1: Deep research required for duplicate DICT keys, exact OpenType restrictions on FontMatrix/CID Font DICT matrices, predefined charset/Encoding tables, and admission-time versus lazy validation.
- Phase 2: Deep research required for Type 2 `random` determinism, Appendix C deprecated `endchar` composition, exact fixed-point overflow policy, contour closure, and canonical geometric bounds/rounding.
- Phase 3: Deep research required for per-glyph bounds/RSB without an unbudgeted query, and for collection-shared CFF with face-local `hmtx`.
- Phase 4: Corpus/license selection and independent-oracle tooling need explicit provenance review; implementation patterns are otherwise standard.

## Sources

### Official format authorities

- [Microsoft OpenType 1.9.1 — CFF table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff) — CFF/OpenType integration, one Name INDEX entry, CharstringType 2, GID/count identity. **Confidence: MEDIUM (cross-verified provider tier).**
- [Microsoft OpenType 1.9.1 — OpenType font file](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — required shared tables, outline-table distinction, collection sharing. **Confidence: MEDIUM.**
- [Microsoft OpenType 1.9.1 — Recommendations](https://learn.microsoft.com/en-us/typography/opentype/spec/recom) — `OTTO`, CFF `hmtx` cardinality, table/profile guidance. **Confidence: MEDIUM.**
- [Microsoft OpenType 1.9.1 — `glyf` / `CFF ` / CFF2 comparison](https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison) — cubic geometry and binding CFF1/CFF2 differences. **Confidence: MEDIUM.**
- [Adobe Technical Note #5176 — Compact Font Format Specification](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5176.CFF.pdf) — INDEX, DICT, strings, charset, Encoding, Private DICT, Subrs, CID and FDSelect. **Confidence: MEDIUM.**
- [Adobe Technical Note #5177 — Type 2 Charstring Format](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf) — operators, width/hints, Subrs, biases, termination and implementation limits. **Confidence: MEDIUM.**

### Compatibility references

- [fontTools `cffLib`](https://fonttools.readthedocs.io/en/latest/cffLib/index.html) — mature CFF1/CFF2 read/write model and name/CID structures. **Confidence: MEDIUM.**
- [FreeType CFF driver](https://freetype.org/freetype2/docs/reference/ft2-cff_driver.html) — mature desktop CFF engine boundary and device-aware hinting contrast. **Confidence: MEDIUM.**

### Local project authorities

- `.planning/PROJECT.md` — binding v0.34 goal, scope exclusions, active requirements, four-target and atomicity baseline. **Confidence: HIGH.**
- `docs/rfcs/0004-mb-font.md` — accepted module boundary: binary-to-outline in `mb-font`, outline-to-pixel in `mb-canvas`, shaping in `mb-text`. **Confidence: HIGH.**
- `modules/mb-font/font/*.mbt` and the Phase 100 interface baseline — existing opaque `Font`, metrics/mapping/kerning/outline, limits/budget, mutation guards and `FontCollection` profile/selection behavior. **Confidence: HIGH.**
- `modules/mb-core/math/path.mbt` — existing portable `Path2` with native `CubicTo`. **Confidence: HIGH.**

---
*Feature research for: MoonBit Native Foundation v0.34 CFF Outline Foundation*
*Researched: 2026-07-28*
