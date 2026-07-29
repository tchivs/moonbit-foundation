# Phase 104: CFF1 Profile and Bounded Data Model - Context

**Gathered:** 2026-07-28
**Status:** Ready for planning
**Mode:** Smart Discuss (recommended choices auto-approved by user)

<domain>
## Phase Boundary

Establish the exact supported static OpenType CFF1 profile, parse its bounded structural data, and resolve every GID to one private checked CharString execution environment for both name-keyed and CID-keyed fonts. This phase does not execute Type 2 programs, calculate glyph bounds, publish CFF-backed `Font` values, or expose public CFF inspection APIs.

</domain>

<decisions>
## Implementation Decisions

### Static Profile and Admission Boundary
- Recognize only `OTTO` SFNT/collection faces with exactly one `CFF ` table, no `CFF2`, no `glyf`/`loca` mixture, no variable-outline profile, and `maxp` version 0.5.
- Preserve existing common-table, checksum, standalone, TTC/OTC root-offset, and selected-face rules; after one checked table window is created, every CFF-internal offset is table-relative.
- Require a one-font CFF FontSet, one Name INDEX entry, one Top DICT entry, Type 2 CharStrings, and `maxp.numGlyphs == CharStrings INDEX.count`; OpenType GID remains the CharStrings position.
- Classify recognized unsupported profiles before semantic CFF traversal and return stable capability outcomes; malformed supported-profile structure remains a data error.

### Shared INDEX and Typed DICT Model
- Use one reusable checked INDEX implementation for Name, Top DICT, String, Global Subrs, CharStrings, FDArray, and local Subrs; empty INDEX is exactly the count field.
- Accept `offSize` 1–4, require first offset 1, require monotonic in-range offsets, and interpret every object window as 1-based relative to INDEX object data only after terminal extent proof.
- Decode all CFF DICT integer, real, and escaped forms into checked rational/fixed structural values without using `Double`; reserved, truncated, non-finite, or out-of-range derived values fail.
- Give Top, Font, and Private DICT separate typed schemas with exact arity, defaults, named offset bases, and duplicate policy; duplicate structural singleton operators are rejected rather than silently taking first or last.

### Name-Keyed and CID-Keyed Resolution
- Name-keyed data supports predefined and custom charsets, predefined and custom Encodings with supplements, checked SID resolution through standard plus String INDEX strings, and one selected Private DICT/local Subrs environment.
- CID-keyed data requires a complete `ROS` contract, CID charset, FDArray, FDSelect format 0 or 3, checked sentinel/ranges, every referenced FD in range, and validated per-FD Private DICT/local Subrs facts; CFF Encoding is absent and predefined charsets are rejected.
- Normalize both keying models into one private per-GID descriptor containing a bounded CharString view and the selected private/local-subroutine/FontMatrix facts; the future Type 2 VM will not parse FDSelect or DICT data.
- Retain Top and per-FD FontMatrix values as checked structural facts in Phase 104; composition, font-unit normalization, rounding, and geometry effects are deliberately frozen in Phase 105.

### Limits, Errors, and Publication
- Derive structural ceilings from existing `FontLimits` and format maxima, and charge every header, INDEX offset/object, DICT token/operator, charset/Encoding entry, FD range, SID/CID lookup, and retained compact allocation against cumulative work and caller authority.
- Preflight attacker-controlled counts, offset tables, terminal extents, and allocation sizes before traversal, narrowing, or allocation; retain bounded views and compact offsets/ranges instead of copying CharStrings or strings broadly.
- Preserve parse → validate → exact preflight → final source-revision guard → one commit → publish ordering. Phase 104 tests may publish private admitted CFF facts only after the complete structural/keying transaction succeeds.
- Freeze multi-fault precedence as state/revision and invalid caller authority before resource limits, then recognized capability boundaries, then malformed supported data; exact and one-short fixtures must lock each structural stage.

### the agent's Discretion
- Exact private type names, file-local helper names, and whether compact INDEX facts retain offsets or object windows are implementation choices, provided all offset bases and retained ownership are explicit.
- The planner may split generated fixture builders by structural family when that improves independent hostile coverage without creating a second production parser.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-font/font/directory.mbt` already owns checked SFNT/TTC table windows, profile classification errors, checksum modes, and root-relative collection authority.
- `modules/mb-font/font/tables.mbt` already provides staged admission ledgers, checked work arithmetic, common table facts, and standalone-versus-collection commit modes.
- `modules/mb-font/font/font.mbt` retains caller-owned `ByteView`, source revision, private admitted facts, opaque public values, and final publication guards.
- `modules/mb-font/font/limits.mbt` provides the public non-zero semantic ceiling contract that must remain additive and compatible.
- `mb-core` supplies `ByteView`, checked arithmetic, `Budget`, `ResourceCharge`, and structured error primitives needed by the CFF layer.

### Established Patterns
- Public operations retain caller-owned bytes and guard `mutation_revision()` before returning admitted or decoded results.
- Hostile input is handled with explicit checked ranges, semantic limits, exact work ledgers, caller budget preflight, and structured data/capability/resource/state errors.
- Standalone and selected TTC/OTC faces converge after directory adaptation while keeping collection table offsets root-relative.
- Production parsing is not its own oracle; generated exact/one-short vectors and independent qualification evidence validate semantic facts.

### Integration Points
- Extend the private directory/profile model from one static `glyf` outline profile to a closed `Glyf | Cff1` classification without changing public `FontCollection` inspection shapes prematurely.
- Add dedicated `cff_index.mbt`, `cff_dict.mbt`, `cff_keying.mbt`, and `cff_admission.mbt` seams in the existing `font` package; common SFNT facts remain in current files.
- Phase 105 consumes the resolved per-GID descriptor and structural limits to build the single Type 2 VM and retained bounds transaction.
- Phase 106 connects the proven CFF state to the opaque `Font`, cubic `Path2`, and standalone/TTC public workflows.

</code_context>

<specifics>
## Specific Ideas

- Keep CFF storage completely private: downstream callers continue to see format-neutral `Font`, `GlyphId`, metrics, errors, and paths.
- Treat the INDEX parser and typed DICT schemas as security boundaries with dedicated exact/one-short tests before any VM work begins.
- Preserve the v0.33 selected-face adapter and exact shared-table semantics rather than creating a parallel CFF collection path.

</specifics>

<deferred>
## Deferred Ideas

- Phase 105: Type 2 execution, deterministic numeric/random policy, hint framing, all-glyph validation, FontMatrix application, and retained bounds.
- Phase 106: public CFF-backed `Font`, cubic `Path2`, standalone and TTC/OTC workflow integration.
- Phase 107: licensed Latin/CJK fixtures, hostile/mutation matrices, performance baselines, independent host oracles, and exact four-target evidence.
- Later milestones: CFF2/variable instantiation, WOFF1/WOFF2, shaping/bidi, hint execution, rasterization, color/bitmap glyphs, authoring, discovery, and ambient I/O.

</deferred>
