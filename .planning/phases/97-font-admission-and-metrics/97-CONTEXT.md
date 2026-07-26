# Phase 97: Font Admission and Metrics - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the independently publishable `tchivs/mb-font` module and its trusted static TrueType-outline SFNT boundary. Library authors can open caller-provided immutable bytes under explicit semantic limits and a shared budget, then inspect named font-wide and per-glyph horizontal metrics. Unicode cmap queries, kerning, outline extraction, real-font qualification, shaping, rasterization, and additional font/container formats belong to later phases or milestones.

</domain>

<decisions>
## Implementation Decisions

### Public Contract and Dependency Boundary
- Publish one portable public `tchivs/mb-font/font` package; keep SFNT/table parsers private file-level components rather than exposing low-level table packages.
- Use an opaque `Font` and opaque/range-checked `GlyphId` so callers cannot bypass admission invariants or construct invalid glyph references.
- Plan around `Font::open(source, limits, budget)` with an explicit `FontLimits` value; generic budgets alone do not express table, glyph, expansion, and work ceilings.
- Keep the only runtime dependency `tchivs/mb-font -> tchivs/mb-core`; return core data types and do not add canvas, image, color, FFI, filesystem, or platform-font dependencies.

### Source Ownership and Atomic Admission
- Retain a caller-provided `ByteView` and capture its mutation revision; every query that reads retained source bytes must reject revision drift before consuming or publishing results.
- Accept only standalone static TrueType-outline SFNT with `sfntVersion = 0x00010000` in this milestone; reject TTC/OTC, WOFF/WOFF2, CFF/CFF2, variations, and color/bitmap profiles as unsupported.
- Publish `Font` only after one cross-table admission gate succeeds; malformed tables, inconsistent cardinalities, unsupported required profiles, or exhausted limits never produce a partial font.
- Perform checked widened offset/count/range arithmetic before narrowing, allocation, slicing, checksum work, or table-local reads.

### SFNT Integrity Profile
- Derive directory lookup facts from `numTables`; validate stored search helper fields for canonical consistency if the official profile requires them, but never trust them for navigation.
- Require sorted unique tags, checked contained table ranges, required alignment, non-overlap, table checksums, and the font-wide `head.checksumAdjustment` invariant.
- Require and structurally admit `cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, `OS/2`, `post`, `loca`, and `glyf`; unknown well-formed optional tables remain allowed.
- Normalize table records to checked table-local `ByteView` windows so downstream decoders never combine root bytes with raw attacker-controlled offsets.

### Metrics and Resource Semantics
- Expose units-per-em, global bounds, `hhea` ascent/descent/lineGap, and `OS/2` typographic ascent/descent/lineGap as separately named facts; do not invent a target-dependent “best” line metric.
- Expose per-glyph advance width, left side bearing, declared bounds, and a checked derived right side bearing, including empty glyphs and the `hmtx` repeated-final-advance tail rule.
- Treat `maxp` and table-declared counts as consistency claims, not permission to allocate or work; caller `FontLimits` intersect declarations and the shared budget remains authoritative.
- Preserve integer font-unit facts until callers request or downstream phases produce geometry; Phase 97 must avoid floating-point policy that would pre-empt later outline decisions.

### Verification and Compatibility
- Use deterministic generated micro-font bytes to cover exact-fit/one-short ranges, duplicate/overlap/checksum failures, long/short `loca`, `hmtx` tail metrics, empty glyphs, mutation drift, and budget limits.
- Test only public results and stable structured error facts across `js`, `wasm`, `wasm-gc`, and `native`; timing and host-specific representations are not compatibility oracles.
- Review generated `.mbti` output to keep the candidate surface minimal and ensure no private table parser or unsupported capability leaks publicly.
- Keep Phase 97 fixtures self-contained and provenance-ready, while licensed real-font selection and end-to-end interoperability evidence remain owned by Phase 100.

### the agent's Discretion
- Exact MoonBit type and method names may change during planning if the generated `.mbti` remains minimal, explicit, and consistent with established module conventions.
- The internal split among cursor, table-record, core-table, and metrics source files is flexible provided the public package remains singular and dependency direction stays acyclic.
- Compact bounded structural indexes may be cached after admission; persistent decoded glyph/outline caches are not part of this phase.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mb-core/bytes` provides retained immutable-style `ByteView` subviews and mutation-revision tracking suitable for zero-copy table ownership.
- `mb-core/checked` provides checked scalar/range arithmetic and explicit narrowing patterns already used by hostile image codecs.
- `mb-core/budget` and `mb-core/error` provide shared resource admission and structured error contracts.
- Existing independently publishable modules, workspace manifests, quality scripts, fixture manifest, and four-target package tests provide the repository integration template.

### Established Patterns
- Public portable modules declare `+js+wasm+wasm-gc+native`, use `moon.mod.json`, and keep host adapters out of portable packages.
- Hostile binary parsers fail before publishing partial decoded values, pair generic budgets with semantic limits, and use deterministic generated fixtures plus public black-box tests.
- Public APIs expose stable semantic facts while private white-box tests cover internal range, arithmetic, parser-state, and representation invariants.

### Integration Points
- Add `modules/mb-font` to `moon.work`, repository inventories, policy/quality selectors, and top-level/module documentation without changing existing module APIs.
- Depend only on the published `tchivs/mb-core` module and consume its bytes, checked, budget, error, and math packages as needed.
- Reserve the public `Path2` composition seam for Phase 99; Phase 97 may validate `loca`/`glyf` structure needed for metrics but does not decode outlines.

</code_context>

<specifics>
## Specific Ideas

- Normative baselines are OpenType Specification 1.9.1 and Unicode 17.0.0.
- Prefer API names that make named metric sources and explicit limits visible rather than hiding policy behind defaults.
- Generated micro-font fixtures should be easy to audit byte-for-byte and mutate deterministically without a foreign runtime oracle.

</specifics>

<deferred>
## Deferred Ideas

- Phase 98 owns cmap format 12/4 selection and legacy horizontal format-0 kerning.
- Phase 99 owns simple/composite `glyf` decoding, phantom-point/`USE_MY_METRICS`, transform, and `Path2` lowering rules.
- Phase 100 owns licensed real-font selection, provenance/digests, public end-to-end examples, and full hostile four-target qualification.
- CFF/CFF2, collections/web-font containers, variations, color/bitmap glyphs, hinting, shaping, discovery, rasterization, and authoring remain outside v0.32.

</deferred>
