# Stack Research

**Domain:** Bounded SFNT/TrueType parsing and portable glyph-outline extraction
**Project:** MoonBit Native Foundation — v0.32 TrueType Font Foundation
**Researched:** 2026-07-26
**Confidence:** HIGH for repository integration and the normative format profile; MEDIUM for the proposed real-font fixture until its extracted file digest and table inventory are recorded in-repository

## Executive Recommendation

Add one independently publishable pure-MoonBit module, `tchivs/mb-font@0.1.0`, with exactly one runtime dependency: `tchivs/mb-core@0.1.0`. Implement the v0.32 parser against **OpenType Specification 1.9.1** (released May 2024 and still the current official edition), restricted to a single-font TrueType-outline SFNT with `sfntVersion = 0x00010000`. Support `cmap` formats 4 and 12, horizontal metrics, simple and bounded composite `glyf` outlines, and optional OpenType `kern` version 0 / format 0. Do not add FreeType, HarfBuzz, FontTools, C stubs, host filesystem access, WOFF, TTC, CFF, hinting, variations, GPOS, or a font registry to the runtime stack.

The parser should accept a caller-provided `tchivs/mb-core/bytes.ByteView` and `tchivs/mb-core/budget.Budget`. SFNT is random-access, so use private big-endian cursors over checked `ByteView::subview` table windows. `mb-core/io.BoundedReader` is a sequential, non-seeking logical window and is not the right primary abstraction for table-directory offsets. A future streaming convenience API may stage a size-capped font into `OwnedBytes` using `BoundedReader` and `read_exact`, but that copy is not needed for the foundational API.

Keep exact font data as integers for as long as possible. Decode signed design coordinates and metrics into `Int`/`Int64`, use `checked_add`, `checked_mul`, `CheckedRange`, and explicit narrowing at every offset/length/count boundary, and convert outline coordinates to `Double` only when constructing the existing `mb-core/math.Path2`. TrueType coordinates are integral font units and composite transforms are F2Dot14 binary fractions, so this preserves the wire model while composing directly with `mb-canvas` without a dependency on canvas.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|---|---:|---|---|
| MoonBit `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Build, test, document, and qualify the new module | This is the installed repository baseline. Pin it exactly in CI for the candidate line and record all three versions in evidence. |
| `tchivs/mb-core` | workspace `0.1.0` | Bytes, checked ranges/arithmetic, budgets, structured errors, and shared path geometry | These are already validated on `js`, `wasm`, `wasm-gc`, and `native`; adding another safety/runtime library would duplicate accepted contracts. |
| OpenType Specification | **1.9.1** (May 2024) | Normative SFNT and TrueType binary contract | This is the current official Microsoft specification. Reference exact table chapters in code comments and tests rather than an undated “TrueType” description. |
| Unicode Standard | **17.0.0** | Public `cmap` input validity | Definition D76 gives the exact scalar-value domain: `U+0000..U+D7FF` and `U+E000..U+10FFFF`. Valid-but-unmapped scalars return glyph ID 0; surrogate or out-of-range inputs are invalid input. |

### Existing `mb-core` Integration

| Contract | Use in `mb-font` | Important constraint |
|---|---|---|
| `@bytes.ByteView` | Immutable root font bytes and zero-copy table subviews | Every table is admitted with `CheckedRange::from_start_length` before a subview is created. Never cast unchecked `uint32` offsets or lengths to `Int`. |
| `@checked.CheckedRange` | Directory, table, subtable, glyph, and array windows | Use nested `subrange` checks for `cmap`, `loca`/`glyf`, and `kern`; reject overflow before reading or allocating. |
| `@checked.checked_add`, `checked_mul`, `checked_sub`, `checked_narrow_int` | Count-derived sizes and index arithmetic | Apply before `12 + numTables*16`, `numGlyphs+1`, `numberOfHMetrics*4`, contour/point arrays, format-4 array positions, format-12 group ranges, and kern-pair records. |
| `@budget.Budget` + `ResourceCharge` | Bytes/work/allocation admission | Charge work per directory record, cmap segment/group, decoded point, component, emitted path command, and kern pair. Charge allocations before arrays become visible. |
| `@budget.with_depth` | Composite glyph extraction | The font-declared `maxComponentDepth` is untrusted metadata, not a safety limit. Enforce the RFC 0004 candidate limit of one composite level plus an explicit visited-glyph set; cycles fail deterministically. |
| `@error.CoreError` | Stable malformed/resource failure | Populate `operation`, `source_offset`, `requested`, `limit`, and a stable table/glyph context. Do not return partially parsed fonts or partially built outlines. |
| `@math.Path2`, `Point2`, `PathCommand` | Public reusable outline | Emit `MoveTo`, `LineTo`, `QuadTo`, and `Close`. `mb-canvas` already consumes this type, so `mb-font` must not import `mb-canvas`. |
| `@io.BoundedReader` / `read_exact` | Optional future stream-to-owned-buffer adapter only | It has no seeking contract. Do not emulate SFNT random access by repeatedly consuming or rebuilding readers. |

### Module and Package Shape

Create `modules/mb-font/moon.mod.json` in the same publication style as the existing modules:

```json
{
  "name": "tchivs/mb-font",
  "version": "0.1.0",
  "description": "Portable bounded TrueType font parsing, Unicode mapping, metrics, kerning, and reusable glyph outlines for MoonBit Native Foundation.",
  "license": "Apache-2.0",
  "repository": "https://github.com/tchivs/moonbit-foundation",
  "readme": "README.mbt.md",
  "preferred-target": "native",
  "supported-targets": "+js+wasm+wasm-gc+native",
  "deps": {
    "tchivs/mb-core": "0.1.0"
  }
}
```

Add `./modules/mb-font` to `moon.work`. Start with one public `font` package and private files grouped by responsibility (`cursor`, `directory`, `head_maxp`, `metrics`, `cmap`, `loca_glyf`, `kern`, `outline`). Do not create separately importable “internal” packages until a real second consumer needs those boundaries; independent packages enlarge the public module surface.

The package imports only the required `mb-core` packages:

```moonbit
import {
  "tchivs/mb-core/budget",
  "tchivs/mb-core/bytes",
  "tchivs/mb-core/checked",
  "tchivs/mb-core/error",
  "tchivs/mb-core/math",
}

supported_targets = "+js+wasm+wasm-gc+native"
```

The public construction seam should be conceptually:

```moonbit
pub fn Font::parse(
  source : @bytes.ByteView,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError]
```

The parsed `Font` should retain the immutable root view plus validated table ranges and compact indexes, rather than copying every table. Outline extraction is a separate budgeted operation so a caller can parse metadata without paying for every glyph.

## Exact Normative Profile

### Container and Directory

| Item | v0.32 policy | Normative source |
|---|---|---|
| Container | Accept one SFNT at byte 0 with `sfntVersion = 0x00010000` | OpenType 1.9.1, “The OpenType Font File” |
| Directory | Validate `12 + numTables*16`, sorted ascending unique tags, valid search fields, 4-byte-aligned table starts, checked offset/length windows, and no table overlap in the single-font profile | OpenType 1.9.1, TableDirectory and TableRecord |
| Checksums | Verify every admitted table checksum using zero-padding to a 4-byte boundary and verify the whole-font `head.checksumAdjustment` equation | OpenType 1.9.1, “Calculating Checksums” and `head` |
| Required tables | Require `cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, `OS/2`, `post`, `glyf`, and `loca`; v0.32 may expose only the metric/mapping/outline fields but must validate presence and bounded ranges | OpenType 1.9.1 required-table and TrueType-outline lists; RFC 0004 |
| Excluded signatures | Reject `OTTO` (CFF/CFF2), `ttcf` (collections), WOFF/WOFF2, Apple `'true'`/`'typ1'`, and embedded bitmap-only outlines | Explicit milestone scope |

### Tables and Cross-Table Rules

| Table | Supported edition/format | Required validation and behavior |
|---|---|---|
| `head` | version 1.0 | `magicNumber = 0x5F0F3CF5`; `unitsPerEm` in the specified 16..16384 range; `indexToLocFormat` exactly 0 or 1; checked global bounds. |
| `maxp` | TrueType version 1.0 | Read `numGlyphs` and declared maxima, but treat maxima only as consistency checks. Actual counts must also fit caller budget and implementation ceilings. |
| `hhea` | version 1.0 | Validate reserved fields and `metricDataFormat = 0`; require `1 <= numberOfHMetrics <= numGlyphs`. Use its ascender, descender, and lineGap as the v0.32 named font-wide horizontal metrics. |
| `hmtx` | current OpenType 1.9.1 layout | Decode `numberOfHMetrics` long records; remaining glyphs reuse the final advance width and consume individual left side bearings. Compute right side bearing with checked widened arithmetic. |
| `cmap` | header version 0; formats 4 and 12 only | Validate encoding records and complete subtable lengths before indexing. Prefer a Unicode format 12 subtable over format 4 as the specification directs when both exist. Use a fixed selection order: platform 0 full-repertoire format 12, platform 3/10 format 12, platform 0 BMP format 4, platform 3/1 format 4. Map valid misses to glyph 0 and reject any derived glyph ID outside `numGlyphs`. |
| `loca` | short (0) and long (1) | Require exactly `numGlyphs + 1` entries, monotonic offsets, short offsets multiplied by two with checked arithmetic, and every offset within `glyf.length`. Equal adjacent offsets represent an empty glyph. |
| `glyf` simple | OpenType 1.9.1 | Bound contour count, increasing end-point indices, instruction length, expanded repeat flags, point count, and accumulated coordinate deltas. Implement implied on-curve midpoints for consecutive off-curve points and contour start/end rules before emitting `Path2`. Parse and skip instruction bytes; never execute hinting. |
| `glyf` composite | OpenType 1.9.1 | Validate component glyph IDs, complete flag-dependent arguments, XY and point-matching placement, F2Dot14 scale/x-y-scale/2×2 transforms, and complete instruction ranges. Enforce an acyclic visited set, work/point/command limits, and the RFC candidate depth of one. |
| `kern` | table version 0, horizontal subtable format 0 | Validate subtable lengths, sorted pair keys, pair glyph IDs, and signed FWORD values. Use supported horizontal non-cross-stream format-0 data; safely skip well-formed unsupported subtables. Do not combine this query API with GPOS policy. |

The cmap selection order is project policy where OpenType permits a consistent application choice between same-format Unicode platform records. Freeze it in black-box tests so all four targets choose the same subtable.

## Fixture and Conformance Strategy

### Canonical Fixture Layers

| Layer | Contents | Purpose |
|---|---|---|
| Spec-derived micro-fonts | Project-generated minimal SFNTs with exact table bytes | Isolate every supported encoding branch and failure boundary without relying on a large third-party font. |
| Mutation corpus | One controlled corruption per fixture: every truncation boundary, offset/length overflow, duplicate/unsorted tags, checksum failure, invalid count, bad cmap ordering, descending `loca`, repeated-flag overflow, composite cycle/depth/work exhaustion, unsorted/out-of-range kern pair | Prove structured fail-closed behavior and atomicity. |
| Real-font specimen | **DejaVu Sans 2.37**, obtained from the official single-font archive whose published archive SHA-256 is `5c6e497a2f36552cb5ffb112c413a6af39c0f3c47653662b90b4fa6499822fd7` | Representative interoperability for real table sizes, BMP/supplementary mapping, metrics, simple/composite glyphs, and legacy kerning where present. Record the extracted `DejaVuSans.ttf` SHA-256 and inspected table inventory before accepting the fixture. |
| Public workflow vector | A tiny generated font with `.notdef`, space, `A`, `V`, an accented composite, and one supplementary-plane mapping | Stable end-to-end `parse → cmap → metrics → outline → kern` evidence on all targets. |

The source of truth belongs under `fixtures/font/`. Extend `fixtures/manifest.json` with fixture ID, path, generator or official URL, exact upstream version, retrieval date, upstream archive digest, extracted-file digest, license, redistribution status, table inventory, and intended tests. Include the full DejaVu license notice beside the vendored font.

Portable tests must not read host files. A deterministic fixture generator should convert the checked-in binary corpus into a test-only MoonBit byte-literal package (or equivalent build-time generated test data) so `js`, `wasm`, `wasm-gc`, and `native` consume identical bytes. Verify generated bytes against the manifest SHA-256 before committing them. Do not put fixture loading, a filesystem capability, or a decoder for archive formats in the runtime package.

Expected facts should be semantic and compact: selected cmap record, codepoint→glyph pairs, font metrics, glyph bounds, ordered path commands/control points, kern pairs, and canonical rendered `CoreError` values. Do not snapshot opaque binary output. For the real font, independently record a one-time table inventory and oracle values using a pinned external inspector during fixture curation; portable CI compares against the committed facts and does not install or execute that foreign tool.

### Required Test Placement

| Test kind | File form | Coverage |
|---|---|---|
| Public contract | `*_test.mbt` | Parse API, metrics, cmap, outline, kern, error stability, public workflow |
| Internal invariants | `*_wbtest.mbt` and inline tests | Big-endian cursor, checked ranges, format-4 `idRangeOffset`, flag expansion, implied points, composite transforms/cycles, checksum arithmetic |
| Documentation | `README.mbt.md` and `mbt check` examples | Black-box parse/query workflow with generated tiny bytes |
| Four-target qualification | Isolated package selector plus workspace lane | Same fixture IDs, results, command counts, and error renderings on all four targets |

## Development Tools

| Tool | Purpose | Policy |
|---|---|---|
| `moon check` / `moon test` | Compilation and semantic conformance | Run with `--target all --frozen`; this expands to `wasm`, `wasm-gc`, `js`, and `native`, not LLVM. |
| `moon info` | Regenerate/check public interfaces | Review generated `.mbti` diffs as the candidate API contract. |
| Repository fixture generator | Emit minimal SFNT bytes, correct checksums, mutations, and test literals | Keep it deterministic and versioned; it is test tooling, never a runtime dependency. |
| Optional pinned FontTools `ttx` | One-time independent oracle during fixture curation | Do not add to `moon.mod.json`, runtime packages, or mandatory four-target CI. Record its exact version and output facts if used. |
| SHA-256 tooling | Fixture identity | Use existing repository fixture/manifest conventions; fail generation if bytes differ from the recorded digest. |

## Installation and Qualification

No external package installation is required for the implementation.

```powershell
# After creating the module, register it in the existing workspace.
moon work use modules/mb-font

# Check and run the isolated module on all production targets.
moon -C modules/mb-font check --target all --frozen
moon -C modules/mb-font test --target all --frozen

# Confirm workspace-wide dependency and target compatibility.
moon check --target all --frozen
moon test --target all --frozen

# Record the exact toolchain with qualification evidence.
moon version --all --json
```

Use an isolated `mb-font` selector for fast iteration and a workspace-wide lane before milestone acceptance. Native-only performance benchmarks may be added after semantics stabilize, but portable-target execution is a correctness gate, not a cross-runtime timing comparison.

## Alternatives Considered

| Recommended | Alternative | Why the alternative is not the v0.32 stack |
|---|---|---|
| Pure MoonBit parser over `ByteView` | FreeType, HarfBuzz, stb_truetype, Rust/fontations, or a C FFI wrapper | Violates the milestone’s no-foreign-font-stack goal, becomes native-specific, and bypasses the contracts this milestone exists to establish. |
| Private random-access SFNT cursor | `BoundedReader` as the primary parser | SFNT table offsets require random access; `BoundedReader` deliberately has no seeking contract. |
| Existing `mb-core/math.Path2` output | A new font-only path or a dependency on `mb-canvas` | Duplicates geometry or reverses the RFC dependency direction. |
| Checked integer wire model, late `Double` conversion | Decode all values immediately as `Double` | Loses the exact signed/unsigned table semantics and makes bounds/index arithmetic harder to audit. |
| Project-generated micro-fonts plus one pinned real font | Only system-installed fonts or a large third-party test corpus | System fonts are non-reproducible; a large borrowed corpus obscures licenses, provenance, and feature intent. |
| Committed semantic oracle facts | Run FontTools/FreeType in portable CI | Adds a foreign test-runtime dependency and can turn differential agreement into the acceptance criterion instead of the normative spec. |

## What NOT to Add

| Avoid | Why | Use Instead |
|---|---|---|
| C/C++/Rust/native stubs in core parsing | Breaks four-target identity and obscures ownership/error behavior | MoonBit plus `mb-core` checked/budget contracts |
| `mb-color`, `mb-image`, or `mb-canvas` dependencies | Fonts produce geometry and metrics, not pixels or color | Return `mb-core/math.Path2`; let consumers import canvas |
| WOFF/WOFF2, TTC/OTC, CFF/CFF2 | Separate containers/outline systems outside this milestone | Reject signatures explicitly and reserve later RFC phases |
| TrueType hinting VM | Large hostile bytecode interpreter with target-sensitive rendering behavior | Parse/skip bounded instruction bytes and return unhinted outlines |
| GPOS/GSUB, shaping, bidi, fallback | String-level text policy owned by `mb-text` | Expose only cmap, metrics, outlines, and legacy kern query |
| Variable/color/bitmap fonts | Introduces `fvar/gvar/HVAR`, COLR/CPAL/SVG, or bitmap stacks | Static monochrome TrueType `glyf` only |
| Ambient filesystem or installed-font discovery | Not portable or deterministic | Caller-provided bytes and explicit host capability outside `mb-font` |
| Permissive recovery from malformed offsets/counts | Can publish partial or ambiguous font state | Atomic structured rejection with source offsets and limits |

## Version Compatibility

| Component | Compatible With | Notes |
|---|---|---|
| `tchivs/mb-font@0.1.0` | `tchivs/mb-core@0.1.0` | Exact candidate dependency; only allowed public runtime edge. |
| MoonBit `0.1.20260713` / `moonc 0.10.4` | Existing `moon.mod.json`, `moon.pkg`, and `moon.work` files | Keep current JSON module manifest style for this milestone; use existing `moon.pkg` DSL for packages. |
| OpenType 1.9.1 TrueType subset | Static single-font SFNT `0x00010000` | The implementation is intentionally not a claim of all OpenType 1.9.1 features. |
| Unicode 17.0.0 scalar contract | cmap formats 4 and 12 | No Unicode database dependency is needed; only scalar validation and numeric mapping are required. |
| `@math.Path2` | Existing `mb-canvas` fill/stroke consumers | Quadratic `QuadTo` directly represents TrueType outlines; no canvas import in `mb-font`. |

## Sources

- [OpenType Specification 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/) and [version archive](https://learn.microsoft.com/en-us/typography/opentype/opentypeversions) — current edition and May 2024 release. **Confidence: HIGH** (official Microsoft specification).
- [The OpenType Font File](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — SFNT directory, table records, required tables, alignment, and checksum rules. **Confidence: HIGH**.
- Official OpenType 1.9.1 table chapters: [`head`](https://learn.microsoft.com/en-us/typography/opentype/spec/head), [`maxp`](https://learn.microsoft.com/en-us/typography/opentype/spec/maxp), [`hhea`](https://learn.microsoft.com/en-us/typography/opentype/spec/hhea), [`hmtx`](https://learn.microsoft.com/en-us/typography/opentype/spec/hmtx), [`cmap`](https://learn.microsoft.com/en-us/typography/opentype/spec/cmap), [`loca`](https://learn.microsoft.com/en-us/typography/opentype/spec/loca), [`glyf`](https://learn.microsoft.com/en-us/typography/opentype/spec/glyf), and [`kern`](https://learn.microsoft.com/en-us/typography/opentype/spec/kern). **Confidence: HIGH**.
- [Unicode Standard 17.0.0, Chapter 3](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/) — definition D76 for Unicode scalar values. **Confidence: HIGH** (official Unicode Consortium standard).
- Official MoonBit v0.10.4 documentation: [workspaces](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html), [module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html), [package/target configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html), [tests](https://docs.moonbitlang.com/en/latest/language/tests.html), and [documentation tests](https://docs.moonbitlang.com/en/latest/language/docs.html). **Confidence: HIGH**, cross-checked against the installed toolchain and repository manifests.
- [DejaVu Fonts official download](https://dejavu-fonts.github.io/Download.html) and [license](https://dejavu-fonts.github.io/License.html) — version 2.37 archive identity and redistribution terms. **Confidence: MEDIUM** until the extracted TTF digest/table inventory are captured in `fixtures/manifest.json`.
- Repository evidence: `docs/rfcs/0004-mb-font.md`, `modules/mb-core/{bytes,checked,budget,error,io,math}`, `moon.work`, current module manifests, and `fixtures/manifest.json`. **Confidence: HIGH** (direct local inspection).

---
*Stack research for: MoonBit Native Foundation v0.32 TrueType Font Foundation*
*Researched: 2026-07-26*
