# Stack Research

**Domain:** Bounded static OpenType CFF1 parsing and Type 2 CharString execution to cubic `Path2` in MoonBit
**Project:** MoonBit Native Foundation v0.34 CFF Outline Foundation
**Researched:** 2026-07-28
**Confidence:** MEDIUM

## Executive Recommendation

Extend the existing `tchivs/mb-font@0.1.0` module in pure MoonBit. Keep `tchivs/mb-core@0.1.0` as the sole runtime dependency and preserve the four-target `js`, `wasm`, `wasm-gc`, and `native` contract. Do not create a CFF-specific module, add FFI, or introduce a production dependency on FreeType, HarfBuzz, fontTools, AFDKO, OTS, or a JavaScript font runtime.

Implement CFF1 as a second private outline profile behind the existing opaque `Font`. Admission should recognize an OpenType `OTTO` SFNT with exactly one `CFF ` table, require the common OpenType tables already consumed by `mb-font`, accept `maxp` version 0.5, and reject `CFF2`, variable tables, mixed outline profiles, and WOFF containers with the existing structured capability boundary. The existing `0x00010000` plus `glyf`/`loca` path must remain behaviorally frozen.

The Type 2 interpreter should use checked signed Q16.16 values in `Int64`, fixed-capacity logical stacks, explicit call frames, and caller-owned work/allocation/path limits. Convert to `Double` only when an entirely decoded glyph is atomically published as the existing `@math.Path2`. `Path2` already supports `CubicTo`, so CFF curves and all four flex forms map directly without changing `mb-core`. Hints must be counted, ordered, mask-length validated, and then ignored for geometry; they must not execute a hinting or rasterization policy.

Use external tools only as development and qualification oracles: pin fontTools `4.63.0`, AFDKO `5.0.1`, and OTS `9.2.0` in a host-only fixture lane. Generate canonical bytes and oracle JSON before the four-target MoonBit tests run. Cross-check accepted fonts and outlines with at least two independent tools, but retain hand-derived generated vectors so no foreign implementation becomes the specification.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| MoonBit `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Workspace build, checks, tests, documentation, and qualification | Exact locally verified project baseline; no toolchain upgrade is required for CFF parsing or a bounded VM. |
| MoonBit compiler `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | Compile the same parser and interpreter on all four targets | Keeps the v0.33 compatibility baseline and avoids backend-specific numeric or allocation assumptions. |
| MoonBit runner `moonrun` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Execute portable qualification artifacts | Must remain paired with the pinned toolchain and recorded in evidence. |
| `tchivs/mb-font` | workspace `0.1.0` | Existing opaque `Font`, glyph identity, metrics, cmap, kern, collection selection, and outline API | Extend in place so static CFF1 fonts return the same public `Font` and `Path2` contract as static `glyf` fonts. |
| `tchivs/mb-core` | workspace `0.1.0` | Retained bytes, checked arithmetic, budgets, structured errors, and `Path2` | Already contains every runtime primitive required. Keep it as the sole module dependency. |
| OpenType Specification | `1.9.1` (May 2024) | Normative SFNT/CFF integration and required sibling-table rules | Current official revision; defines `OTTO`, CFF table integration, `maxp` 0.5, glyph-index identity, and the CFF/CFF2 boundary. |
| Adobe CFF Specification | Technical Note `#5176`, 4 Dec 2003 | Normative CFF1 binary structures | Canonical definition of INDEX, DICT, encodings, charsets, Private DICTs, subroutines, and CID-keyed structures. |
| Adobe Type 2 Specification | Technical Note `#5177`, 16 Mar 2000 | Normative CharString VM and path semantics | Canonical operator, number encoding, stack, subroutine, hint, flex, and implementation-limit contract. |

### Supporting Libraries

No new runtime library should be installed. Reuse the following existing `mb-core` packages:

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `tchivs/mb-core/bytes` | `0.1.0` | Retain caller-owned `ByteView`, create checked CFF/table/object views, and observe mutation revision | Every CFF structure and CharString must remain a view over the retained SFNT or collection root; do not copy the complete font. |
| `tchivs/mb-core/checked` | `0.1.0` | Checked offset, length, count, Q16.16, matrix, and work arithmetic | Before every `count + 1`, `count * width`, offset addition, range construction, coordinate update, multiply/divide, or allocation narrowing. |
| `tchivs/mb-core/budget` | `0.1.0` | Authoritative admission and per-outline resource transaction | Preflight complete CFF admission and per-glyph execution charges; commit only after the final source-revision guard. |
| `tchivs/mb-core/error` | `0.1.0` | Stable invalid-data, unsupported-capability, resource, mutation, and state outcomes | Reuse existing categories/codes and add CFF-specific contexts, not string-only exceptions or panics. |
| `tchivs/mb-core/math` | `0.1.0` | Existing `Point2`, `PathCommand::{MoveTo,LineTo,CubicTo,Close}`, and `Path2` | Publish complete unhinted cubic outlines without changing the shared geometry model. |

### Development Tools

| Tool | Verified version | Purpose | Notes |
|------|------------------|---------|-------|
| fontTools / TTX | `4.63.0` (2026-05-14) | Decompile/compile `CFF `, inspect CharStrings through `cffLib`, build deterministic subsets, and emit independent outline facts | Test and fixture tooling only. Requires Python 3.10 or later. Pin exact wheels and hashes in a host-only lock file. |
| Adobe AFDKO | `5.0.1` (2026-05-18) | `tx` CFF/outline/metric oracle, `spot` table inspection, and `makeotf` generated CFF1 construction | CFF-specialist independent oracle. Pin exact package and hashes; never import it from MoonBit code. |
| OpenType Sanitizer | `9.2.0` (2024-10-02) | Independent structural acceptance/rejection and transcode check for OTF/CFF | Use `ots-sanitize` as one validator, not as the semantic source of truth: it can normalize, rewrite, or drop data. |
| Existing PowerShell fixture generator | repository version | Construct minimal name-keyed/CID-keyed CFF1, hostile mutations, manifests, and embedded MoonBit bytes | Extend the existing `scripts/fixtures/Generate-FontQualification.ps1` pattern with exact source/generator/oracle digests. |
| MoonBit black-box tests | pinned toolchain | Verify only the public `Font`/`GlyphId`/`Path2` contract | `_test.mbt`; run identical generated/licensed cases on all four targets. |
| MoonBit white-box tests | pinned toolchain | Verify INDEX, DICT, FDSelect, Type 2 VM, limits, and atomicity | `_wbtest.mbt`; use exact boundary and one-short resource cases. |

## Normative Static CFF1 Profile

### OpenType Admission

| Check | v0.34 policy |
|-------|--------------|
| SFNT version | Accept `0x4F54544F` (`OTTO`) only for the new CFF1 profile. Preserve existing `0x00010000` static-`glyf` behavior. |
| Outline tables | Require exactly `CFF ` for the CFF1 profile. Reject `CFF2`, `glyf`/`loca` mixed with `CFF `, and variation-dependent outline profiles as unsupported. |
| Common tables | Continue requiring `cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, `OS/2`, and `post`. `VORG` is optional and not needed for the horizontal outline slice. |
| `maxp` | Require version `0x00005000` and require `numGlyphs == CharStrings INDEX.count`. Existing TrueType version 1.0 parsing remains private to the `glyf` profile. |
| Glyph identity | OpenType GID is the CharStrings INDEX position. Continue to use OpenType `cmap` for Unicode-to-GID mapping; CFF encoding data is validated metadata, not a replacement cmap. |
| Metrics | Continue to publish `hmtx`/`hhea`/`OS/2` facts through existing APIs. Validate CFF width syntax and Private DICT width defaults, but do not silently replace public `hmtx` metrics. |
| Standalone/collection | Support the existing standalone and TTC/OTC selected-face paths through the same profile discriminator. CFF table offsets remain relative to the appropriate retained SFNT/collection root. |
| Atomicity | No `Font`, admitted CFF facts, budget charge, or `Path2` becomes observable until all ranges, cross-table invariants, execution limits, and source revisions succeed. |

### CFF1 Structures

| Structure | Required handling |
|-----------|-------------------|
| Header | Admit CFF major version 1, honor `hdrSize`, validate header `offSize`, and reject future major versions gracefully. |
| INDEX | Parse `count`, `offSize` 1–4, exactly `count + 1` offsets, mandatory first offset 1, monotonic offsets, terminal offset, and object-data range before object access or allocation. Empty INDEX is exactly its count field. |
| Name INDEX | Require exactly one entry inside an OpenType `CFF ` table, as OpenType 1.9.1 requires one-font CFF FontSet data. |
| Top DICT INDEX | Require one DICT corresponding to the sole Name entry. Decode operands before operators, cap at the specified 48 DICT operands, reject reserved/malformed encodings, and apply documented defaults. |
| String INDEX | Validate every custom SID reference against the standard-string plus String INDEX namespace; never allocate or publish unbounded strings merely to select outlines. |
| Global Subr INDEX | Retain bounded object windows and compute the Type 2 bias from count. Do not eagerly concatenate or desubroutinize the font. |
| Charset | Support predefined name-keyed charsets and custom formats 0, 1, and 2. Require coverage of exactly `CharStrings.count - 1` entries because GID 0 is `.notdef`. CID-keyed fonts must not use predefined charsets. |
| Encoding | Support predefined encodings and custom formats 0/1 plus supplements for name-keyed validation. CID-keyed CFF omits encoding. OpenType `cmap` remains authoritative for public scalar lookup. |
| CharStrings INDEX | Require GID 0 `.notdef`, retain one bounded view per glyph, validate count against `maxp`, and reject non-Type-2 `CharstringType`. |
| Private DICT | Require the Top DICT or selected FD to identify a Private DICT, permitting specified length zero. Parse `Subrs`, `defaultWidthX`, `nominalWidthX`, `initialRandomSeed`, and hint data under explicit operand/range limits. |
| Local Subrs INDEX | Resolve `Subrs` relative to the beginning of its Private DICT. Select the Top Private DICT for name-keyed fonts and the FD-selected Private DICT for CID-keyed glyphs. |
| CID `ROS` | Treat presence of `ROS` as the CID-keyed discriminator. Require `FDArray`, `FDSelect`, CID charset semantics, and no encoding. |
| `FDArray` | Validate every Font DICT and its Private DICT before publication. Cap FD count and total DICT bytes independently from glyph count. |
| `FDSelect` | Support CFF1 formats 0 and 3. Format 3 ranges must begin at GID 0, increase strictly, terminate with sentinel `numGlyphs`, and select an existing FD. |
| Embedded PostScript | Validate the referenced SID if present but never execute it. Adobe states a CFF consumer without a PostScript interpreter can ignore this feature. |
| Synthetic fonts | Reject `SyntheticBase` as unsupported for this vertical slice; it introduces cross-font transformation and selection beyond one admitted OpenType CFF font. |

## Type 2 Execution Stack

### Numeric and VM Representation

Use a project-owned private Q16.16 numeric type represented by checked `Int64`. Type 2 byte `255` is a signed 16.16 number; integer encodings enter the same representation by a checked left shift. Keep coordinates, operands, transient-array values, and deterministic arithmetic in this representation and convert to `Double` only when constructing the final `Point2`.

This is preferred over a `Double` operand stack because exact integer/fixed inputs, subroutine effects, operator arity, and cross-target output stay reproducible. It also avoids JS/native differences becoming part of malformed-input or limit behavior. `div`, `mul`, and `sqrt` need specified checked fixed-point algorithms and exact rounding rules. The Type 2 `random` operator must use a documented deterministic project-owned PRNG initialized from `initialRandomSeed`; ambient host randomness is forbidden.

### Required Type 2 Coverage

| Group | Required behavior |
|-------|-------------------|
| Number decoding | Support one-byte integers, two-byte positive/negative integers, `shortint`, and signed 16.16 five-byte values with truncation checks. |
| Width | Detect the optional first width operand according to the first stack-clearing operator; validate against `defaultWidthX`/`nominalWidthX` while preserving `hmtx` as the public metric source. |
| Moves and lines | Implement `rmoveto`, `hmoveto`, `vmoveto`, `rlineto`, `hlineto`, and `vlineto`; close an open contour when required by Type 2 path sequencing. |
| Cubic curves | Implement `rrcurveto`, `rcurveline`, `rlinecurve`, `vvcurveto`, `hhcurveto`, `vhcurveto`, and `hvcurveto` directly as checked `CubicTo` endpoints/control points. |
| Flex | Implement `flex`, `hflex`, `hflex1`, and `flex1` as two cubic segments. Because v0.34 returns unhinted design-space geometry, never flatten flex to a device-size-dependent line. |
| Hints | Validate ordering, even stem-argument counts, maximum 96 total stems, negative edge-hint rules, and exact `ceil(stemCount / 8)` mask bytes. Count their work, then discard hint effects. |
| Subroutines | Implement `callsubr`, `callgsubr`, and `return`; use biases 107, 1131, and 32768 at the specified count thresholds. Validate the biased index before entry and cap call depth. |
| Arithmetic/logical/storage | Implement the defined non-reserved operators needed by valid Type 2 programs with checked Q16.16 behavior, a 32-element transient array, initialized-slot tracking, and deterministic `random`. |
| Termination | Require legal `endchar` termination, allow a subroutine to terminate the glyph as specified, and reject trailing executable bytes or illegal `return`/`endchar` context. |
| Deprecated compatibility | Treat `dotsection` as a validated no-op. Support deprecated four-operand `endchar` composition only if its StandardEncoding glyph-name resolution and non-nesting rules are implemented with the same resource/recursion authority; otherwise expose a deliberate unsupported-program outcome rather than partial geometry. |

### Mandatory Limits

The Adobe limits are protocol ceilings, not substitutes for caller authority:

| Resource | Adobe ceiling | Project policy |
|----------|---------------|----------------|
| Argument stack | 48 | Fixed logical maximum 48 and caller work accounting for every push/operator. |
| Total horizontal + vertical stems | 96 | Validate even pairs and mask bytes; also charge scanned hint bytes. |
| Subroutine nesting | 10 | Hard maximum 10, plus cycle-safe explicit frames and a caller `max_cff_subr_calls`/work ceiling. |
| CharString length | 65,535 bytes | Enforce per object and also cap cumulative executed bytes across subroutine re-entry. |
| Local/global subroutine count | 65,536 | Intersect with CFF INDEX representation, caller limits, allocation limits, and checked index narrowing. |
| Transient array | 32 elements | Fixed 32 Q16.16 slots plus initialized flags; no dynamic map. |
| DICT operands | 48 | Fixed logical maximum 48; clear according to operator semantics. |
| Path output | Project-defined | Add explicit maximum commands/contours/cubic segments and allocation bytes; do not overload TrueType point limits ambiguously. |
| Work | Project-defined | Count bytes decoded, operators, stack actions, hint bytes, subroutine entries, FD/INDEX ranges, and emitted commands. |

Extend `FontLimits` additively with CFF-specific ceilings rather than interpreting TrueType fields such as `max_outline_instruction_bytes` as CharString policy. Candidate limits should cover at least CFF INDEX objects/bytes, DICT operands/bytes, FDs, subroutines, subroutine calls/depth, executed CharString bytes, stems, path commands/contours, and total work.

## Installation

### Runtime

No new runtime package is installed:

```bash
moon sync
moon check --target native modules/mb-font
```

The module manifest remains:

```text
tchivs/mb-font@0.1.0 -> tchivs/mb-core@0.1.0
supported_targets = "+js+wasm+wasm-gc+native"
```

### Host-Only Qualification Tools

Pin tools in a dedicated lock/manifest with verified hashes. Do not run floating `latest` installs in required CI.

```bash
python -m venv .venv-font-oracle
python -m pip install --require-hashes -r qualification/font-oracles.requirements.txt

# The lock should resolve exactly:
# fonttools==4.63.0
# afdko==5.0.1

# Build or consume an integrity-pinned ots-sanitize 9.2.0 separately.
```

Qualification order:

```bash
# 1. Regenerate bytes, provenance, hostile cases, and canonical oracle JSON.
pwsh -File scripts/fixtures/Generate-FontQualification.ps1

# 2. Validate external structural/oracle agreement in the host lane.
fonttools ttx -t "CFF " fixture.otf
afdko tx -mtx fixture.otf
ots-sanitize fixture.otf

# 3. Run the same committed/generated MoonBit facts on every runtime target.
moon test --target js modules/mb-font
moon test --target wasm modules/mb-font
moon test --target wasm-gc modules/mb-font
moon test --target native modules/mb-font
```

## Qualification Fixture Stack

| Fixture class | Recommended source | Purpose |
|---------------|-------------------|---------|
| Minimal generated name-keyed CFF1 | Repository PowerShell generator plus hand-authored expected facts | Every INDEX/DICT/encoding/charset format, width detection, all path operators, hints, subr bias thresholds, arithmetic/storage, and exact cubic commands. |
| Minimal generated CID-keyed CFF1 | Repository generator, with multiple FDs and both FDSelect formats | `ROS`, CID charset, FDArray, per-FD Private DICT/local Subrs, invalid FD/range/sentinel cases. |
| Licensed compact Latin OTF | Exact static OTF asset from Adobe Source Sans or Source Serif, pinned by release URL and SHA-256 | Ordinary name-keyed interoperability, real subroutinization, metrics/cmap/path fingerprints, license-preserving intake. |
| Licensed CID CJK OTF/OTC derivative | Exact static Source Han Serif OTF/OTC parent under OFL-1.1, deterministically subset and pinned | CID-keyed/FDSelect/local-subr stress without committing an unnecessarily huge corpus. Preserve parent, derivative, generator, notice, and digest lineage. |
| Existing `glyf`/TTC corpus | Current generated and DejaVu fixtures | Prove all old standalone and collection facts remain byte/behavior compatible. |
| Negative/hostile matrix | Deterministic mutations of generated structures | Truncated operands/masks, bad OffSize/offsets, overlapping/out-of-range objects, DICT overflow, malformed FDSelect, invalid subr bias/index, recursion, stack overflow/underflow, work/path/allocation exhaustion, and source mutation. |

Do not use a fontTools-generated CFF file and fontTools-derived JSON as the only success proof. At least the minimal fixtures need hand-derived expected bytes and exact `PathCommand` sequences. For licensed fixtures, compare table/profile facts, metrics, glyph mapping, cubic command fingerprints, bounds, and independent tool outputs rather than opaque whole-file snapshots.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Extend `tchivs/mb-font` | New `mb-cff` module | Only if a future RFC deliberately makes standalone CFF/PDF font programs a separate public product. It is wrong for the current opaque OpenType `Font` contract. |
| Pure MoonBit CFF/Type 2 implementation | FreeType or Adobe C library wrapper | Only as a future optional native validation/acceleration leaf after the portable implementation is authoritative. |
| Checked Q16.16 `Int64` VM | `Double` operand/coordinate VM | Only if later profiling proves fixed arithmetic infeasible and a cross-target numeric contract is separately specified and qualified. |
| Lazy bounded INDEX/object views | Eagerly materialize/desubroutinize the full CFF table | Only in an offline authoring/subsetting tool where memory use and rewritten bytes are the product. |
| Existing `Path2::CubicTo` | Convert cubic curves to quadratics or flattened lines | Only for a downstream consumer that explicitly requests approximation. The font layer should preserve native CFF cubics. |
| Validate and ignore hints | Execute CFF hinting | Only in a separate rasterization/hinting milestone with device scale, grid, and rendering policy. |
| Three independent host oracles | One foreign library as golden truth | Never for conformance. One tool can share bugs or normalize malformed data. |
| Static raw OTF/OTC | WOFF1/WOFF2 | Only after a separate bounded decompression/reconstruction foundation is designed and qualified. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| FreeType, HarfBuzz, CoreText, DirectWrite, or fontconfig as runtime dependencies | Violates the pure-MoonBit/four-target goal, adds FFI ownership and platform behavior, and conflates parsing with shaping/discovery/rasterization | Existing `mb-core` primitives and a MoonBit CFF1/Type 2 implementation |
| fontTools, AFDKO, or OTS in production | Python/C++ host tools are not portable runtime contracts and may rewrite input | Host-only pinned oracle lane producing committed/generated evidence |
| `opentype.js`, `fontkit`, or browser APIs | Adds a JS-only implementation and destroys identical four-target behavior | One MoonBit source implementation |
| CFF2 parser reuse by tag switch | CFF2 removes CFF1 structures, changes stack/operator semantics, and adds `blend`/variation-store behavior | Explicit unsupported `CFF2` outcome and a future separate milestone |
| Variable tables or instance selection | Static CFF1 has no OpenType outline variations; variable CFF outlines are CFF2 | Reject/defer `fvar`, CFF2 `VariationStore`, `vsindex`, and `blend` |
| WOFF1 zlib or WOFF2 Brotli/transform code | Container reconstruction is a separate bounded codec/allocation problem | Raw SFNT/TTC/OTC caller-provided bytes |
| GSUB/GPOS shaping or bidi | String-level glyph selection/positioning is outside single-font outline extraction | Preserve existing scalar-to-GID and per-glyph APIs; defer shaping to `mb-text` |
| Hint execution and rasterization | Requires device/grid policy and would make outline results resolution-dependent | Validate hint syntax, publish unhinted cubic geometry |
| Executing embedded PostScript | Introduces an unbounded language runtime and ambient behavior; Adobe permits non-PostScript consumers to ignore it | Validate its SID/range only |
| Ambient RNG for Type 2 `random` | Breaks determinism and four-target equality | Fixed documented PRNG seeded from Private DICT state |
| Using CFF encoding for `glyph_for_scalar` | OpenType Unicode mapping is defined by `cmap`; CFF encoding is a different legacy/name-keyed structure | Continue the existing canonical cmap selection |
| Replacing `hmtx` widths with CharString width values | Would silently change the existing public metric contract | Validate both representations and define mismatches as malformed or a documented compatibility rule |
| Partial path publication | A late malformed operator, mutation, or budget failure would leak inconsistent geometry | Build private bounded geometry, final revision guard, then publish one `Path2` |

## Stack Patterns by Variant

**If the CFF is name-keyed:**

- Parse one Top DICT, one Top Private DICT, its optional local Subrs, charset, and encoding.
- Resolve every GID directly through CharStrings; use charset only for name/SID validation and deprecated StandardEncoding composition.
- Continue to use the OpenType `cmap` and `hmtx` tables for public mapping and metrics.

**If the CFF is CID-keyed:**

- Require `ROS`, `FDArray`, `FDSelect`, and a CID charset; reject an Encoding operator.
- Select the FD before CharString execution, then use that FD's Private DICT, local Subrs, widths, random seed, and matrix facts.
- Apply explicit FD-count, FDSelect-range, DICT-byte, local-subr, and work ceilings before publication.

**If the font is selected from TTC/OTC:**

- Reuse the retained collection root and selected-face directory adapter.
- Admit `OTTO` plus `CFF ` through the new profile without copying the whole collection or rebasing shared table offsets.
- Preserve collection-mode checksum rules and source revision guards.

**If hints or flex operators occur:**

- Parse and validate all hint arguments and mask bytes, but do not alter coordinates.
- Emit flex as the two specified cubic curves regardless of device size.

**If CFF2, WOFF, variable data, shaping requests, or rasterization requests occur:**

- Return the established structured unsupported-capability outcome at the appropriate boundary.
- Do not partially parse the foreign profile or silently ignore variation-dependent geometry.

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| `tchivs/mb-font@0.1.0` | `tchivs/mb-core@0.1.0` | Preserve as the only public runtime dependency and existing opaque `Font` API owner. |
| MoonBit `0.1.20260713` / `moonc 0.10.4` | `js`, `wasm`, `wasm-gc`, `native` | Exact locally verified baseline. A toolchain upgrade is not part of v0.34. |
| Static CFF1 admission | OpenType `1.9.1`, Adobe TN `#5176`, Adobe TN `#5177` | Raw OTF and selected OTC faces; one CFF FontSet entry; Type 2 CharStrings; `maxp` 0.5. |
| Existing TrueType admission | OpenType `0x00010000`, `glyf`/`loca`, `maxp` 1.0 | Must remain unchanged and pass the existing full corpus on every target. |
| fontTools `4.63.0` | Python `>=3.10` | Host-only oracle/subsetter; exact lock and hashes required. |
| AFDKO `5.0.1` | Host qualification environment | Host-only CFF specialist oracle/builder; exact lock and hashes required. |
| OTS `9.2.0` | OTF/TTF/WOFF/WOFF2 validation | Host-only independent sanitizer; no runtime linkage. |
| CFF2/variable fonts | Not supported | Different CFF structures and VM (`VariationStore`, `vsindex`, `blend`); separate milestone. |
| WOFF1/WOFF2 | Not supported | Requires zlib or Brotli plus reconstruction; separate outer adapter. |
| GSUB/GPOS shaping, hint execution, rasterization | Not supported | Preserve module boundary and deterministic unhinted outlines. |

## Sources

- [OpenType Specification 1.9.1](https://learn.microsoft.com/typography/opentype/spec) and [version archive](https://learn.microsoft.com/en-us/typography/opentype/opentypeversions) — current revision and May 2024 release date. **Confidence: MEDIUM**; official primary source, cross-checked through the research seam.
- [OpenType font file](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — `OTTO`, required common tables, CFF/CFF2 table roles, and separation from optional layout/variation/raster data. **Confidence: MEDIUM**; official primary source.
- [OpenType CFF table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff) — one Name/Top DICT entry, Type 2 requirement, CharStrings/GID identity, and `maxp.numGlyphs` equality. **Confidence: MEDIUM**; official primary source.
- [OpenType `maxp` table](https://learn.microsoft.com/en-us/typography/opentype/spec/maxp) — version 0.5 for CFF/CFF2 and version 1.0 for TrueType outlines. **Confidence: MEDIUM**; official primary source.
- [OpenType outline-format comparison](https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison) — CFF1 cubic/Q16.16 characteristics and CFF2 structural/operator/variation differences. **Confidence: MEDIUM**; official primary source.
- [Adobe Technical Note #5176: The Compact Font Format Specification](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5176.CFF.pdf) — CFF1 layout, INDEX/DICT, encoding/charset, Private DICT, subroutines, CID `ROS`/FDArray/FDSelect, and defaults. **Confidence: MEDIUM**; canonical Adobe specification, cross-checked with OpenType.
- [Adobe Technical Note #5177: The Type 2 CharString Format](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf) — number/operator encoding, path/flex/hint/subroutine semantics, deprecated forms, and interpreter limits. **Confidence: MEDIUM**; canonical Adobe specification, cross-checked with OpenType and tool implementations.
- [fontTools TTX documentation](https://fonttools.readthedocs.io/en/latest/ttx.html), [CFF table documentation](https://fonttools.readthedocs.io/en/latest/ttLib/tables/C_F_F_.html), and [cffLib](https://fonttools.readthedocs.io/en/latest/cffLib/index.html) — CFF XML round-trip, CFF/Type 2 inspection, and test-oracle capabilities. [fontTools 4.63.0 release](https://github.com/fonttools/fonttools/releases/tag/4.63.0) verifies the pinned version. **Confidence: MEDIUM**; official project docs/releases.
- [AFDKO command-line guide](https://adobe-type-tools.github.io/afdko/CommandLineHowTo.html) — `tx`, `spot`, and `makeotf` CFF workflows. [AFDKO 5.0.1 release](https://github.com/adobe-type-tools/afdko/releases/tag/5.0.1) verifies the pinned version. **Confidence: MEDIUM**; official Adobe project docs/releases.
- [OpenType Sanitizer 9.2.0](https://chromium.googlesource.com/external/ots/+/refs/tags/v9.2.0) and [OTS design](https://chromium.googlesource.com/external/ots/+/refs/tags/v6.1.0/docs/DesignDoc.md) — CFF-aware validation/transcoding role and version. **Confidence: MEDIUM**; official upstream repository.
- [MoonBit v0.10.4 release](https://www.moonbitlang.com/updates/2026/07/13/moonbit-0-10-4-release), [module configuration](https://docs.moonbitlang.com/en/stable/toolchain/moon/module.html), and [testing documentation](https://docs.moonbitlang.com/en/stable/language/tests.html) — toolchain line, supported targets, and black-/white-box tests. **Confidence: MEDIUM**; official sources, cross-checked locally.
- [WOFF 1.0](https://www.w3.org/TR/WOFF/) and [WOFF 2.0](https://www.w3.org/TR/WOFF2/) — zlib/Brotli wrapper and reconstruction boundaries supporting the explicit deferral. **Confidence: MEDIUM**; W3C Recommendations.
- [Adobe Source Sans](https://github.com/adobe-fonts/source-sans), [Adobe Source Serif](https://github.com/adobe-fonts/source-serif), and [Adobe Source Han Serif](https://github.com/adobe-fonts/source-han-serif) — official static OTF/CID fixture candidates and OFL-1.1 provenance. **Confidence: MEDIUM**; official upstream repositories.
- Repository evidence: `.planning/PROJECT.md`, `moon.work`, `modules/mb-font/moon.mod.json`, `modules/mb-font/font/moon.pkg`, `modules/mb-font/font/{font,directory,cursor,limits,outline}.mbt`, `modules/mb-core/math/path.mbt`, `scripts/fixtures/Generate-FontQualification.ps1`, and fixture policy documents. **Confidence: MEDIUM**; direct local inspection, with the seam offering no higher local-provider tier.

## Confidence and Research Flags

| Area | Confidence | Reason |
|------|------------|--------|
| Runtime dependency and target stack | MEDIUM | Exact local manifests/tool identities and official MoonBit docs agree; provider classifier caps verified web findings at MEDIUM. |
| CFF1/OpenType profile | MEDIUM | OpenType 1.9.1 and Adobe TN #5176 agree on integration and structures. |
| Type 2 operator/limit stack | MEDIUM | Adobe TN #5177 is canonical and was cross-checked against OpenType/fontTools/AFDKO behavior. |
| Qualification tools | MEDIUM | Current official releases and capability docs are verified; final hashes/environment lock remain implementation work. |
| Licensed fixture selection | MEDIUM | Suitable OFL-1.1 upstreams exist, but exact assets, derivatives, and SHA-256 values must be frozen during fixture intake. |

Phase-specific research/decision flags:

- Freeze the exact checked Q16.16 rounding contract for `div`, `mul`, `sqrt`, matrix application, and final `Double` conversion before implementing the VM.
- Freeze the deterministic Type 2 `random` PRNG algorithm and glyph/reset semantics; the Adobe specification constrains the result range but does not prescribe one algorithm.
- Decide whether deprecated four-operand `endchar` composition is admitted in v0.34 or returns a structured unsupported-program result. Do not implement it partially.
- Define the precise cross-check policy when CharString width and `hmtx` disagree. Public metrics must not silently change.
- Select and hash one compact static name-keyed OTF and one CID-keyed Source Han derivative, including parent/generator/license/notice lineage.
- A future CFF2/variable or WOFF milestone requires separate research; neither is an incremental tag switch.

---
*Stack research for MoonBit Native Foundation v0.34 CFF Outline Foundation*
*Researched: 2026-07-28*
