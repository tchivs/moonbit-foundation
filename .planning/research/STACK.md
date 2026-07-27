# Technology Stack

**Project:** MoonBit Native Foundation — v0.33 TrueType Collection Adapters
**Domain:** Bounded, no-copy TTC/OTC face selection over the existing pure-MoonBit TrueType implementation
**Researched:** 2026-07-28
**Overall confidence:** MEDIUM under the GSD provider classifier; all external conclusions below were cross-checked against current official specifications, and repository/toolchain facts were verified locally

## Executive Recommendation

Add **no runtime technology and no new module**. Extend the existing `tchivs/mb-font@0.1.0` module and its existing public `font` package with a bounded collection adapter written entirely in MoonBit. Preserve `tchivs/mb-core@0.1.0` as the module's only dependency and retain the existing `+js+wasm+wasm-gc+native` target set. The installed and documented v0.33 implementation baseline remains `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf`, and `moonrun 0.1.20260713`.

Implement the adapter against **OpenType Specification 1.9.1**, released May 2024 and still identified by Microsoft as the current revision. Both TTC and OTC use the same `ttcf` container structure. Support TTC header versions 1.0 and 2.0, but admit only caller-selected faces that satisfy the already-supported static TrueType-outline profile: `sfntVersion = 0x00010000`, required `glyf` and `loca`, and no CFF/CFF2 outline dependency. File extensions are guidance, not an admission authority; caller-provided bytes may not have a filename, an OTC may contain mixed outline types, and the `ttcf` tag is used for all collection outline kinds.

The essential implementation change is an **offset-aware internal admission seam**, not a decompressor or a reconstructed standalone font. In a collection, each face directory can begin at a non-zero offset, while every table record's offset is measured from byte zero of the entire collection. Keep the original collection `ByteView`, validate a selected directory offset, and resolve table windows against the root view. Do not pass `source.subview(face_directory_offset, ...)` to the current standalone parser: that would incorrectly rebase absolute table offsets and cannot preserve shared tables.

WOFF1 and WOFF2 must remain explicitly out of v0.33. WOFF1 requires zlib-compatible decompression of potentially compressed tables and is a separate web packaging format. WOFF2 does define collection packaging, but requires Brotli decompression plus optional reconstruction transforms for `glyf`, `loca`, and `hmtx`; reconstructed glyph bytes can differ from the source, and the WOFF2 specification warns that declared original lengths are not safe allocation authorities for transformed tables. Either format would replace the milestone's no-copy adapter with a decompression, materialization, and new resource-accounting project.

## Recommended Stack

### Core Framework

| Technology | Verified version | Purpose | Why |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Workspace build, checks, tests, documentation, and qualification | This is the existing pinned project baseline. The collection adapter uses only ordinary portable language and package features. |
| MoonBit compiler `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | Compile the module on all production backends | Locally verified with `moon version --all`; no compiler upgrade is required by the format work. |
| MoonBit runner `moonrun` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Execute portable qualification artifacts | Retain the exact runner paired with the pinned toolchain. |
| `tchivs/mb-font` | workspace `0.1.0` | Existing standalone TrueType admission and metrics/cmap/kern/outline contracts | Extend in place so a selected collection face returns the same opaque `Font` and all existing query behavior remains unchanged. |
| `tchivs/mb-core` | workspace `0.1.0` | `ByteView`, checked ranges/arithmetic, budget transactions, structured errors, and `Path2` | It already supplies every primitive needed for a bounded collection adapter. Keep it as the only runtime dependency. |
| OpenType Specification | **1.9.1** (May 2024) | Normative TTC/OTC and table-directory contract | Current official revision; it defines the shared `ttcf` structure, versions 1.0/2.0, absolute collection offsets, sharing, checksums, and outline table profiles. |

### Database

No database, registry, cache service, or persistent index belongs in this milestone. A collection is admitted from one caller-provided `ByteView`; the resulting collection and selected `Font` retain only validated in-memory facts and the source revision.

### Infrastructure

| Technology | Version | Purpose | Policy |
|---|---:|---|---|
| Existing `moon.work` | current repository workspace | Resolve `tchivs/mb-core` locally for `mb-font` | No workspace member or publication unit is added. |
| Existing `moon.mod.json` for `mb-font` | module version `0.1.0` | Declare target set and sole dependency | Keep `preferred-target: native`, `supported-targets: +js+wasm+wasm-gc+native`, and only `tchivs/mb-core: 0.1.0`. |
| Existing GitHub Actions/toolchain pin | exact repository baseline | Four-target candidate evidence | No system font, native codec, zlib, Brotli, or filesystem package may enter required CI. |
| Repository fixture generation | deterministic project tooling | Build compact TTC v1/v2 and hostile test bytes | Development/test-only; generated bytes are embedded or otherwise consumed identically on all four targets. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| `tchivs/mb-core/bytes` | `0.1.0` | Retain the root collection `ByteView`, create checked shared-table views, observe mutation revision | Always; never copy the whole collection or rebase a face by slicing at its directory. |
| `tchivs/mb-core/checked` | `0.1.0` | Check `12 + 4*numFonts`, optional v2 trailer size, directory windows, table records, offsets, lengths, and index narrowing | Before every derived offset, range, count multiplication, or allocation. |
| `tchivs/mb-core/budget` | `0.1.0` | Authoritative collection discovery and selected-face admission transactions | Charge header/offset discovery and compact retained facts before publishing a collection; use the established face admission charge when selecting. |
| `tchivs/mb-core/error` | `0.1.0` | Stable malformed, unsupported, resource, mutation, and out-of-range outcomes | Reuse the existing structured error model; do not introduce string-only collection errors. |
| Existing private `mb-font` cursor/directory code | module-local | Big-endian reads and SFNT table admission | Refactor behind a directory-base plus checksum-mode parameter; do not fork a second parser. |

No compression library, cryptography library, I/O library, FFI binding, or foreign font engine is recommended.

## Exact Normative Container Profile

### TTC/OTC Header

| Field or rule | v0.33 policy |
|---|---|
| Signature | Require `0x74746366` (`ttcf`) at collection byte 0. Keep standalone `Font::open` behavior unchanged for `0x00010000`. |
| Header version | Accept exactly 1.0 or 2.0. Reject unknown major versions rather than interpreting an unknown layout. |
| Face count | Read `numFonts` as `uint32`, require a non-zero count, enforce a new explicit `max_faces` semantic ceiling, and checked-narrow before any array/index use. |
| Directory offset array | Validate `numFonts` 32-bit offsets under checked `12 + 4*numFonts` arithmetic before publishing a collection. Every offset is relative to collection byte 0. |
| Version 2 trailer | After the offset array, validate the `dsigTag`, `dsigLength`, and `dsigOffset` triple. All-null means no signature. A present DSIG uses tag `DSIG`, has a checked in-bounds range, and is structurally last. |
| Signature semantics | Structural DSIG validation only. Do not claim cryptographic authentication and do not add a crypto dependency. Signature verification is a separate capability. |
| File naming | Ignore `.ttc`/`.otc` for admission. OpenType recommends `.ttc` for TrueType-outline collections and `.otc` for CFF/CFF2 collections, but both use `ttcf` and collections may mix outline types. |

The collection adapter should expose a distinct bounded limit type, conceptually `FontCollectionLimits`, containing at least `max_source_bytes`, `max_faces`, and `max_work`. Do not overload `FontLimits.max_tables` to mean face count. Continue to apply the caller's existing `FontLimits` to the selected face.

### Selected Face Profile

| Check | Required behavior |
|---|---|
| Caller index | Reject `index >= numFonts` before reading a face directory or spending selected-face work. |
| Directory window | Validate a complete 12-byte SFNT directory header at the chosen absolute offset, then checked `numTables * 16` records within the root collection. |
| SFNT version | Require `0x00010000` for the selected face. `OTTO` is not admitted by the existing TrueType implementation. |
| Outline tables | Require the existing `glyf`/`loca` pair and all currently required TrueType tables. Reject faces containing only `CFF ` or `CFF2` as unsupported, even though their collection container is valid. |
| Table offsets | Interpret every `TableRecord.offset` from collection byte 0. Preserve table sharing naturally when multiple directories point to the same root range. |
| Table checksums | Verify each selected face table checksum using the bytes as stored in the collection. |
| `head.checksumAdjustment` | Do **not** apply the standalone whole-font `0xB1B0AFBA` equation in collection mode. OpenType 1.9.1 says this field is not used for collections and may be zero. |
| Atomicity | Do not publish `FontCollection` or `Font` until its full transaction, source-revision checks, and structural/profile validation succeed. |

The adapter does not need to deduplicate table bytes or discover which tables are shared. Sharing is already represented by equal absolute ranges in different face directories. The parser only needs to permit those equal ranges while still rejecting invalid partial overlap and out-of-bounds ranges according to the existing directory policy.

## Integration with the Existing `mb-font` Module

### Public Additions

Use additive APIs in the existing `font` package. The exact naming can be settled during phase design, but the stack boundary should be:

```moonbit
pub struct FontCollection

pub fn FontCollection::open(
  source : @bytes.ByteView,
  limits : FontCollectionLimits,
  budget : @budget.Budget,
) -> Result[FontCollection, @error.CoreError]

pub fn FontCollection::face_count(
  self : FontCollection,
) -> Result[UInt64, @error.CoreError]

pub fn FontCollection::open_face(
  self : FontCollection,
  index : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError]
```

The selected result must be the existing `Font`, not a parallel collection-face type. That preserves `units_per_em`, line metrics, `glyph_for_scalar`, `glyph_id`, horizontal metrics, legacy kerning, and outline calls without adapters at every query.

### Private Refactor

Factor current `Font::open` admission into a private function conceptually shaped as:

```moonbit
fn font_open_at(
  source : @bytes.ByteView,
  directory_offset : UInt64,
  checksum_mode : FontChecksumMode,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError]
```

- Standalone `Font::open` calls it with directory offset `0` and standalone checksum mode.
- `FontCollection::open_face` calls it with the validated absolute directory offset and collection checksum mode.
- Directory parsing reads directory fields at `directory_offset + local_field_offset`.
- Table record offsets remain root-relative and are never incremented by `directory_offset`.
- Collection mode verifies table checksums but skips the standalone whole-source checksum-adjustment equation.
- Both modes retain the root `ByteView` and its mutation revision, preserving existing pre-query and post-query drift checks.

Do not duplicate `font_parse_directory`, `font_validate_profile`, required-table admission, cmap, kern, metrics, or outline code. The v0.33 implementation should make the existing standalone path one parameterization of the same admission transaction, with black-box byte compatibility tests proving that the old API remains unchanged.

### Resource Accounting

The stack already supports the required authority model. Extend it, rather than importing a collection parser:

1. Collection discovery preflights the bounded header, face count, directory offset array, optional v2 DSIG trailer, retained offset facts, and associated work.
2. Collection publication charges once and records the opening source revision.
3. Face selection checks the collection revision and index before selected-face work.
4. Existing `Font` admission performs its own authoritative budget transaction over the selected directory and referenced tables.
5. A second collection revision guard runs immediately before publishing the selected `Font`.

Do not charge the complete collection byte length again as if it were a copied face allocation. Bytes remain caller-owned. Resource facts must distinguish referenced source bytes from newly allocated bookkeeping and from parsing work.

## Why WOFF1 and WOFF2 Are Excluded

### WOFF1

WOFF File Format 1.0 is a W3C Recommendation dated 13 December 2012. It is a webfont package with signature `wOFF`, a 44-byte header, a replacement table directory, optional metadata/private blocks, and potentially compressed font tables. A conforming decoder must support zlib-compatible decompression for compressed tables; metadata, when present, is also zlib-compressed.

WOFF1 should not be added because:

- It does not expose raw TTC table-directory offsets that can be adapted in place.
- Compressed tables must be materialized or exposed through a new decompressed-table storage abstraction.
- Admission needs decompression ratio, output-byte, allocation, and work ceilings that do not exist in the TTC header adapter.
- A pure-MoonBit zlib/DEFLATE decoder might be reusable from other MNF work, but wiring it into `mb-font` would create a new public dependency edge and broaden this milestone from collection selection into webfont decoding.

Policy: reject `wOFF` at the collection and standalone font boundaries with the existing structured unsupported-container outcome. If WOFF1 is later implemented, place decompression in a separate adapter that yields bounded owned SFNT bytes and then calls `mb-font`.

### WOFF2

WOFF File Format 2.0 is a W3C Recommendation dated 8 August 2024. Unlike WOFF1, it explicitly supports collections when `flavor = ttcf`; it has a collection directory mapping each nested font to unique table-directory entries.

WOFF2 still should not be added because:

- All table data is carried in a combined Brotli-compressed stream.
- `glyf`, `loca`, and `hmtx` may have format-specific transforms requiring reconstruction after decompression.
- Transformed `glyf` reconstruction can produce semantically equivalent bytes that differ from the original.
- The specification says transformed-table original lengths are reference values and must not be trusted as allocation authority.
- Collection decoding must restore nested font directories, shared-table relationships, and `glyf`/`loca` pairing before the existing SFNT parser can run.
- Brotli, UIntBase128 parsing, transform reconstruction, output storage, and hostile compression accounting are independently substantial portable infrastructure.

Policy: reject `wOF2` in v0.33. A future WOFF2 milestone should first establish a bounded pure-MoonBit Brotli and WOFF2 reconstruction layer, then hand reconstructed owned TTC/SFNT bytes to the unchanged `mb-font` contract. Do not make `mb-font` depend directly on WOFF2.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|---|---|---|---|
| Module placement | Extend existing `tchivs/mb-font` | Add `mb-font-collection` module | Splits one format admission boundary, forces a second publication unit, and complicates returning the existing private `Font`. |
| Face admission | Root `ByteView` plus absolute directory offset | Slice the collection at the selected face directory | TTC table offsets are measured from collection byte 0; slicing rebases them incorrectly and breaks shared tables. |
| Parser structure | Parameterize the existing atomic admission | Copy the standalone parser into collection-specific files | Creates two validation/checksum/profile implementations that will drift. |
| Selected result | Existing `Font` | New `CollectionFace` query surface | Duplicates metrics, cmap, kern, outline, limits, and error contracts. |
| Checksum policy | Table checksums plus collection-mode `head` handling | Reuse standalone whole-source checksum verification | OpenType does not use `head.checksumAdjustment` for collections; the standalone whole-font equation is inapplicable. |
| Outline support | `glyf`/`loca` only | Add `CFF ` or `CFF2` | Those are different cubic CharString systems and exceed the existing quadratic outline foundation. |
| Compression | Raw TTC/OTC only | Add WOFF1 | Requires zlib-compatible decompression and table materialization, contrary to the no-copy milestone. |
| Compression | Raw TTC/OTC only | Add WOFF2 collections | Requires Brotli plus font-table transforms and reconstructed collection storage; it is a separate project. |
| Native integration | Pure MoonBit on four targets | FreeType/fontconfig/CoreText/DirectWrite FFI | Adds ambient discovery and platform-specific ownership/behavior while bypassing the portable contract. |
| I/O | Caller-provided `ByteView` | Filesystem path or installed-font lookup | Breaks deterministic portable use and introduces ambient authority. |
| DSIG | Structural fields only | Cryptographic signature verification | Needs trust-store and cryptographic policy not required to select and parse a face. |

## What NOT to Add

| Avoid | Reason | Use Instead |
|---|---|---|
| New runtime dependencies | All required primitives already exist in `mb-core` | Existing bytes/checked/budget/error contracts |
| `mb-image`, `mb-canvas`, `mb-color`, or `mb-svg` dependency | A collection selects a font; it does not render pixels or scenes | Return the existing `Font` and `Path2` behavior |
| C/C++/Rust stubs | Violates four-target equality and no-FFI scope | Pure MoonBit parsing |
| `@fs`, URLs, streams, or system font discovery | Introduces ambient I/O and target-specific behavior | Explicit caller-owned bounded bytes |
| Copied standalone SFNT reconstruction | Defeats no-copy sharing and changes budget semantics | Root-relative directory adapter |
| CFF/CFF2 CharString interpreter | Separate outline model and variable-font surface | Structured unsupported-face outcome |
| WOFF1 zlib/DEFLATE dependency | New decompression and allocation boundary | Defer to a future outer adapter |
| WOFF2 Brotli and transforms | New compression and reconstruction subsystem | Defer to a dedicated future milestone |
| DSIG trust or crypto stack | Not needed for structural collection admission | Validate header fields/range only |
| Shaping, GPOS/GSUB, variation, hinting, rasterization | Not collection-container responsibilities | Preserve explicit future boundaries |
| Version bump during implementation | Project milestone `v0.33` is not automatically a module release | Keep workspace `0.1.0`; change only through release governance |

## Installation and Qualification

No package installation is required.

```powershell
# Verify the pinned toolchain.
moon version --all

# Isolated module checks on every production target.
moon -C modules/mb-font check --target all --frozen
moon -C modules/mb-font test --target all --frozen

# Workspace integration gate.
moon check --target all --frozen
moon test --target all --frozen

# Review the additive public API contract.
moon -C modules/mb-font info
```

Required fixtures should include generated TTC v1.0 and v2.0 containers, shared-table faces, independent-table faces, mixed `glyf`/CFF face directories, invalid selected indices, hostile counts/offsets/ranges, structurally invalid DSIG triples, collection-mode checksum cases, and the shipped standalone SFNT corpus. Any licensed real collection belongs in repository fixture metadata with an exact digest and license; portable tests must not discover or read system fonts.

## Version Compatibility

| Component | Compatible With | Notes |
|---|---|---|
| `tchivs/mb-font@0.1.0` | `tchivs/mb-core@0.1.0` | Preserve as the only public runtime dependency. |
| TTC/OTC adapter | OpenType 1.9.1 TTCHeader 1.0 and 2.0 | Supports raw `ttcf` containers and selected static `glyf` faces only. |
| Existing standalone API | Standalone SFNT `0x00010000` | Must remain source- and behavior-compatible; old checksums and admission semantics stay frozen. |
| MoonBit targets | `js`, `wasm`, `wasm-gc`, `native` | Same source, fixtures, structured outcomes, and public facts on all four. |
| WOFF1 | Not supported | W3C 2012 packaging requires zlib-compatible decompression. |
| WOFF2 | Not supported | W3C 2024 packaging requires Brotli and optional table transforms, despite having collection support. |

## Sources

- [OpenType Specification 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/) and [OpenType version archive](https://learn.microsoft.com/en-us/typography/opentype/opentypeversions) — current revision and May 2024 release date. **Confidence: MEDIUM** under the GSD verified-provider classifier; official Microsoft primary source.
- [OpenType font file — Font Collections, TTC Header, checksums, and outline-table profiles](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — TTC/OTC shared structure, header 1.0/2.0 fields, root-relative offsets, table sharing, DSIG placement, and collection checksum rules. **Confidence: MEDIUM**; official normative source.
- [OpenType comparison of `glyf`, `CFF `, and `CFF2`](https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison) — alternate outline systems and quadratic-versus-cubic distinction. **Confidence: MEDIUM**; official primary source.
- [WOFF File Format 1.0](https://www.w3.org/TR/WOFF/) — W3C Recommendation, 13 December 2012; WOFF header/directory and mandatory zlib-compatible decoder behavior. **Confidence: MEDIUM**; official W3C standard.
- [WOFF File Format 2.0](https://www.w3.org/TR/WOFF2/) — W3C Recommendation, 8 August 2024; Brotli stream, explicit collection directory, and `glyf`/`loca`/`hmtx` transforms. **Confidence: MEDIUM**; official W3C standard.
- [MoonBit v0.10.4 release](https://www.moonbitlang.com/updates/2026/07/13/moonbit-0-10-4-release) and [official module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html) — current toolchain line, dependency metadata, and supported-target declarations. **Confidence: MEDIUM** under the provider classifier; official MoonBit sources, cross-checked locally.
- Repository evidence: `.planning/PROJECT.md`, `modules/mb-font/moon.mod.json`, `modules/mb-font/font/moon.pkg`, `modules/mb-font/font/{font,directory,cursor,limits}.mbt`, and `moon.work`. **Confidence: HIGH**; direct local inspection on 2026-07-28.

## Research Gaps and Phase Flags

- OpenType defines collection structure and sharing, but the project must freeze its own structured error taxonomy for malformed collection headers, unsupported selected faces, and index failures during phase planning.
- DSIG cryptographic verification is intentionally not researched because it is out of scope; structural v2 header validation is sufficient for v0.33.
- A licensed collection fixture and its exact digest/license should be selected during fixture planning. This does not affect the runtime stack.
- Any future WOFF2 phase needs separate feasibility research for a bounded pure-MoonBit Brotli implementation and the WOFF2 transform reconstruction rules; it must not be treated as a small extension of this adapter.

---
*Stack research for MoonBit Native Foundation v0.33 TrueType Collection Adapters*
