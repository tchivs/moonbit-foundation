# Architecture Patterns

**Domain:** v0.33 bounded TrueType Collection (TTC/OTC) adapters
**Project:** MoonBit Native Foundation / `tchivs/mb-font`
**Researched:** 2026-07-28
**Confidence:** HIGH for repository integration seams; MEDIUM for the candidate pre-1.0 collection API and DSIG policy

## Executive Recommendation

Add a small public `FontCollection` facade and a private offset-aware directory
adapter inside the existing `tchivs/mb-font/font` package. Keep `Font::open`
unchanged as the standalone-SFNT compatibility facade. A collection-selected
face must enter the same admission transaction immediately after directory
construction, so the shipped metrics, cmap, kern, loca/glyf, outline, limits,
budget, and revision behavior remains one implementation.

The critical offset rule is:

- the selected face's **table directory header and records** are read at the
  `tableDirectoryOffsets[index]` supplied by the TTC header;
- every `TableRecord.offset` is already relative to byte zero of the **entire
  collection**, not relative to that selected directory;
- table-local offsets inside `cmap`, `loca`, `glyf`, `kern`, and other tables
  remain relative to their checked table `ByteView`, exactly as they are now.

Therefore, adapt only directory discovery and construction. Do not materialize
a synthetic standalone font and do not add a base to table-record offsets.
Once a selected directory has produced the existing table-local `TableWindow`
values, all downstream code should remain collection-unaware.

The public dependency graph remains unchanged:

```text
tchivs/mb-font/font ──> tchivs/mb-core/{bytes,checked,budget,error,math}
```

No new module, package, FFI, file-system capability, or target-specific path is
needed.

## Recommended Architecture

```text
caller-owned TTC/OTC ByteView
              |
              v
 FontCollection::open
  - ttcf/version/count/offset array
  - v2 DSIG envelope (not signature trust)
  - bounded scan of every face-directory envelope
  - retain compact face facts + source revision
              |
       face_count/profile
              |
              v
 FontCollection::open_face(index, FontLimits, Budget)
  - range/profile/revision gate
  - parse selected TableDirectory at directory_offset
  - resolve TableRecord.offset against collection root
  - validate selected table checksums
  - skip standalone whole-file checksumAdjustment check
              |
              v
 shared private Font admission transaction
  - required tables/profile/cross-table cardinalities
  - cmap/kern/metric/loca/glyf admission
              |
              v
 existing opaque Font
  - metrics / glyph_for_scalar / kerning / outline
  - unchanged table-local readers and revision guards
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|---|---|---|
| `FontCollection` public facade | Retain one bounded collection, expose face count/profile, select one face | Collection parser; shared font admission |
| Collection parser | Validate TTCHeader v1/v2, face offsets, DSIG envelope, and all face-directory envelopes under collection limits | Big-endian cursor; checked arithmetic; budget |
| Offset-aware SFNT directory parser | Read one directory at an absolute directory offset while resolving its table records against the collection root | Existing `DirectoryFacts` and `TableWindow` |
| Shared font admission | Perform the shipped profile, checksum, required-table, cross-table, cmap/kern/metrics/outline admission | Existing `tables.mbt`, `metrics.mbt`, `cmap.mbt`, `kern.mbt`, `outline.mbt` |
| Revision authority | Keep collection and selected font tied to the same backing mutation revision | `ByteView::mutation_revision()` shared by root and subviews |
| Qualification fixture builder | Produce independent generated TTCs and hostile mutations | Tests only; never production parsing |

## New Versus Modified Components

| Action | Path | Exact change |
|---|---|---|
| New | `modules/mb-font/font/collection.mbt` | Private TTC header/face facts plus public `FontCollection`, face inspection, and selected-face admission |
| New | `modules/mb-font/font/collection_limits.mbt` or additive section in `limits.mbt` | `FontCollectionLimits` with non-zero `max_source_bytes`, `max_faces`, `max_directory_records`, and `max_work` |
| Modify | `modules/mb-font/font/directory.mbt` | Parameterize directory reads by absolute `directory_offset`; keep table-record offsets collection-root-relative; split standalone and collection checksum policy |
| Modify | `modules/mb-font/font/font.mbt` | Extract the body of `Font::open` after directory construction into one private shared admission function; preserve the existing public signature and behavior |
| Modify | `modules/mb-font/font/tables.mbt` | Make admission byte/work accounting use an explicit selected-source extent rather than assuming every `DirectoryFacts.source` is a standalone font |
| Modify | `modules/mb-font/font/font_wbtest.mbt` and new collection white-box tests | Prove absolute-offset math, checksum policy, budget boundaries, and mutation checkpoints |
| Modify | `modules/mb-font/font/font_test.mbt` and qualification tests | Add public collection workflows while retaining every standalone assertion |
| Modify | `fixtures/font/**`, fixture generator, and manifest | Add generated collections, licensed TTC/OTC input, provenance, hostile derivatives, and expected facts |
| Modify | focused font qualification scripts/workflows | Run standalone and collection selectors on `js`, `wasm`, `wasm-gc`, and `native` |
| Unchanged | `cursor.mbt` | Reads remain relative to the `ByteView` passed by the caller; callers compute checked absolute directory positions |
| Unchanged | `cmap.mbt`, `kern.mbt`, `metrics.mbt`, `outline.mbt` | They already operate on table-local retained views and require no collection branches |
| Unchanged | `mb-core` and public dependency policy | `ByteView` subviews share backing and revision; checked ranges, budgets, errors, and `Path2` are sufficient |

## Public API Boundary

Prefer one additive opaque type and one additive limits type. Do not overload
`Font::open` to guess whether input is standalone or a collection: format
guessing makes error context and resource policy ambiguous and risks changing a
shipped API.

Candidate surface:

```moonbit
pub fn FontCollection::open(
  source : @bytes.ByteView,
  limits : FontCollectionLimits,
  budget : @budget.Budget,
) -> Result[FontCollection, @error.CoreError]

pub fn FontCollection::face_count(
  self : FontCollection,
) -> Result[UInt64, @error.CoreError]

pub fn FontCollection::face_profile(
  self : FontCollection,
  index : UInt64,
) -> Result[FontFaceProfile, @error.CoreError]

pub fn FontCollection::open_face(
  self : FontCollection,
  index : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError]
```

`FontFaceProfile` should expose only stable capability information useful
before selection, for example `TrueTypeGlyf`, `Cff`, `Cff2`, and
`Unsupported`. If that enum would prematurely freeze policy, omit
`face_profile` from v0.33 and expose only `face_count` plus structured
capability failure from `open_face`. Do not expose raw table-directory offsets,
table lists, `ByteView`s, checksums, or mutable collection cursors.

An out-of-range face index is `InvalidInput/InvalidRange`. A structurally bad
container or face is `Data/InvalidEncoding`. A CFF/CFF2 or otherwise unsupported
selected face is `Capability/CapabilityUnavailable`. Limit and authoritative
budget exhaustion remain `Resource/BudgetExceeded`. Revision drift remains a
state error. Use collection-specific operation/context tokens so callers can
distinguish container failure from the existing standalone `font-open`
contract without parsing messages.

## Data Flow and Exact Integration Seams

### 1. Collection Admission

`FontCollection::open` should:

1. Capture `opening_revision` before reading.
2. Enforce `max_source_bytes`, then require the 12-byte TTC prefix.
3. Require tag `ttcf`; accept only version 1.0 or 2.0.
4. Read `numFonts`, reject zero, enforce `max_faces`, and checked-compute
   `12 + numFonts * 4` plus the v2 12-byte DSIG tuple.
5. Preflight a bounded discovery charge before walking attacker-declared
   offsets.
6. Scan every face directory at its absolute offset. Validate its 12-byte
   header, non-zero table count, complete `16 * numTables` record envelope,
   sorted/unique tags, four-byte top-level table alignment, and checked
   collection containment. Accumulate and enforce `max_directory_records` and
   `max_work`.
7. Classify outline profile from `sfntVersion` and outline tags, but do not
   reject an otherwise structural collection merely because an unselected face
   is CFF/CFF2. OpenType collections may mix outline formats.
8. For TTCHeader v2, accept an all-zero DSIG tuple. For a non-zero tuple,
   validate tag/range/end placement as an envelope but make no authenticity
   claim; cryptographic signature validation is outside v0.33.
9. Atomically retain only compact face facts (directory offset, table count,
   profile) after the exact budget decision.
10. Recheck the root revision immediately before publishing the collection.

The all-face envelope scan is important: a published collection then means its
header and directory topology are bounded and structurally inspectable. It does
not mean every unselected face has passed semantic table admission or checksum
validation. That stronger and more expensive contract belongs to
`open_face`.

### 2. Selected Face Directory

Generalize the current standalone functions conceptually as:

```moonbit
font_directory_discovery_charge_at(
  source,
  directory_offset,
  limits,
  checksum_policy,
)

font_parse_directory_at(
  source,
  directory_offset,
  limits,
) -> DirectoryFacts
```

All reads of `sfntVersion`, `numTables`, search fields, and table records add
`directory_offset` using checked arithmetic. The directory range is:

```text
[directory_offset, directory_offset + 12 + numTables * 16)
```

By contrast, a record's `offset` is consumed unchanged:

```text
table_start = record.offset
table_end   = checked_add(record.offset, record.length)
table_view  = collection_root.subview(table_start, record.length)
```

Do **not** compute `directory_offset + record.offset`; that double-bases a
collection-relative field. Do **not** parse a subview beginning at the face
directory and feed it to the standalone parser; table offsets would then point
at the wrong bytes.

Replace the current standalone check `table_offset < directory_end` with an
actual checked range-overlap test against the selected directory range. In a
collection, valid table data may occur before or after a selected face
directory. Continue rejecting overlap among distinct tables referenced by the
same selected face. Do not compare table ranges globally across faces: equal
absolute ranges are the mechanism by which TTC shares tables.

### 3. Shared Font Admission

Refactor `Font::open` into:

```text
standalone facade
  -> construct directory at offset 0 with Standalone checksum policy
  -> shared admit_font_from_directory(...)

collection open_face
  -> construct directory at selected absolute offset with Collection policy
  -> shared admit_font_from_directory(...)
```

The shared function owns the existing ordering:

- declared work and budget planning;
- TrueType/glyf profile gate;
- required-table presence;
- checksums;
- `head`/`maxp`/`hhea`/`OS/2`/`cmap`/`name`/`post`/optional `kern`;
- `hmtx`/`loca`/`glyf` cardinalities and glyph-header validation;
- final revision check and one opaque `Font` publication.

Keep the existing `0x00010000` TrueType requirement for a selected supported
face. Reject `OTTO` early as unsupported; the presence of `CFF ` or `CFF2`
confirms the capability class. Continue requiring `glyf` and `loca` and
rejecting the already unsupported variable/color/bitmap profiles. The file
extension (`.ttc` or `.otc`) is not available and must never drive capability
selection.

### 4. Checksum Policy

Split current checksum validation into two explicit operations:

```text
validate_selected_table_checksums(directory)       # standalone and collection
validate_standalone_whole_font_checksum(source)    # standalone only
```

For every selected table, retain the existing padded uint32 checksum behavior,
including treating bytes 8–11 of the `head` table as zero. For a collection,
do not calculate or require the complete collection sum to equal
`0xB1B0AFBA`, and ignore `head.checksumAdjustment`; OpenType explicitly says
that field is not used in collections. This is a semantic difference, not a
relaxation of per-table integrity.

## Ownership and Revision Strategy

`ByteView::subview` retains the same backing allocation and the same
`MutationRevision` object as the root view. Use that existing property rather
than adding a collection lease or copying bytes.

- `FontCollection` retains the root source and its opening revision.
- Every public collection inspection checks that revision.
- `open_face` checks the collection revision before reading, uses that same
  revision throughout admission, and checks it again before publishing `Font`.
- The resulting `Font` retains the collection root as its source, not only the
  selected directory subview. Its shipped before/after query guards therefore
  detect mutation anywhere in the backing, including shared tables and the TTC
  header.
- Table-local subviews retained by cmap, kern, metrics, and outline facts share
  the same mutation revision automatically.

Do not silently refresh collection facts after mutation. The deterministic
recovery path is to call `FontCollection::open` again on a fresh/stable view.
Tests should inject revision drift during collection inspection, between
collection open and face selection, during selected admission, and during a
font query.

## Limits and Budget Architecture

Do not add collection fields to the existing `FontLimits::new` constructor;
that would break the shipped source API. Add `FontCollectionLimits`:

| Limit | Purpose |
|---|---|
| `max_source_bytes` | Bound the retained TTC/OTC view before header reads |
| `max_faces` | Bound the offset array and public face index space |
| `max_directory_records` | Bound the sum of table records scanned across all face directories |
| `max_work` | Bound header, record, range, profile, and revision work |

Selected semantic limits remain exactly `FontLimits`: table bytes/count,
glyphs, name/cmap/kern records, outline points/contours/components/instructions,
post names, and work.

Follow the existing two-stage budget pattern:

1. preflight the safe discovery envelope before attacker-controlled repeated
   work or allocation;
2. derive the exact aggregate collection or selected-face charge with checked
   arithmetic;
3. commit one authoritative charge for that operation;
4. publish no partial `FontCollection` or `Font`.

Collection accounting should include its compact face-fact allocation and both
passes if the implementation scans once to size and once to populate. Selected
face accounting should use selected directory records and selected table bytes,
not multiply the entire collection length by face count. Shared table bytes are
charged when a selected face actually validates them; sharing is not permission
to perform unaccounted checksum work. Preserve the current rule that a budget
is caller-owned and not a synchronization primitive.

## Offset-Aware Parser Versus Standalone Materialization

| Criterion | Offset-aware directory adapter | Materialize standalone selected face |
|---|---|---|
| Full-font copy | None; table `ByteView`s alias caller bytes | Required for directory plus referenced tables, or requires a new virtual scatter view |
| TTC table offsets | Consumed correctly as collection-root-relative | Must rewrite every table record |
| Shared tables | Naturally supported by equal root-relative views | Duplicated into each synthetic font |
| Checksums | Per-table validation reused; collection adjustment explicitly skipped | Must recompute directory and `head.checksumAdjustment` |
| Mutation contract | Preserved through shared `MutationRevision` | Snapshot hides later caller mutation and changes public semantics |
| Budget model | Charges bounded metadata and selected work | Adds large allocations/copy work and a second resource model |
| Downstream changes | None after `TableWindow` creation | Synthetic source identity leaks into all retained facts |
| Failure surface | Concentrated in directory-base arithmetic | Offset rewriting, layout, padding, checksums, copying, and ownership |

**Recommendation:** use the offset-aware adapter. Materialization conflicts
with the explicit no-copy requirement and creates more security-critical code
than it removes. If a future export API needs a standalone face, make that a
separate explicit serialization feature with its own output buffer, budget,
and checksum contract.

## Patterns to Follow

### Pattern 1: Container-Aware, Table-Local Core

**What:** Normalize a selected container face into existing checked
`TableWindow`s at one boundary.
**When:** Any container changes only where top-level tables are located, while
table internals are unchanged.
**Why:** It keeps container math out of cmap, metrics, kern, and glyph decode
and prevents divergent standalone/collection implementations.

### Pattern 2: Structural Collection, Semantic Selection

**What:** Collection open validates bounded topology for all faces; selection
performs complete semantic admission for exactly one face.
**When:** Collections can contain many faces and mixed supported/unsupported
profiles.
**Why:** Inspection stays bounded and useful without forcing callers to pay
full checksum and glyph-index admission for every unselected face.

### Pattern 3: Explicit Container Checksum Policy

**What:** Make standalone versus collection checksum behavior an enum or
separate private function, not an incidental `if directory_offset == 0`.
**When:** The same face directory format has different whole-container
checksum semantics.
**Why:** A directory can theoretically occur at zero only in standalone input,
but encoding the semantic mode explicitly is auditable and testable.

## Anti-Patterns to Avoid

### Add the Face Base to Every Table Offset

**What goes wrong:** Reads land after the real table, and crafted files can make
the wrong range appear valid.
**Instead:** Add the directory offset only when reading directory fields; use
table-record offsets unchanged against the collection root.

### Feed a Directory Subview to `Font::open`

**What goes wrong:** The first four bytes look like a valid SFNT, but
collection-relative table offsets are interpreted relative to the subview and
the whole-font checksum rule is incorrectly applied.
**Instead:** call the private offset-aware directory constructor and shared
admission function.

### Reject Cross-Face Shared Table Ranges as Overlap

**What goes wrong:** Valid TTC space sharing is rejected.
**Instead:** enforce distinct-table non-overlap within one selected face only;
allow separate face directories to reference identical absolute ranges.

### Validate the Entire Collection as One Standalone Font

**What goes wrong:** `head.checksumAdjustment` and the magic whole-font sum are
misapplied, while selected table integrity may still be inadequately isolated.
**Instead:** validate every selected table checksum and skip only the
standalone aggregate checksum rule.

### Cache Fully Admitted `Font`s Inside the Collection

**What goes wrong:** memory and budget behavior becomes selection-order
dependent, and one failed/mutated face complicates cache invalidation.
**Instead:** retain compact directory/profile facts only; each `open_face`
performs an explicit bounded admission and returns an independent opaque
`Font`.

## Qualification Architecture

Use independent generated fixtures plus at least one provenance-tracked,
redistributable real TTC/OTC. Production parsing must not generate its own
expected results.

| Layer | Required evidence |
|---|---|
| TTC header | v1 and v2-null-DSIG success; every truncation boundary; bad tag/version/minor/count; count/array arithmetic and limits |
| DSIG envelope | all-zero tuple; inconsistent tuple; bad tag; overflow/out-of-range; non-terminal DSIG |
| Face directory topology | out-of-range face offsets; truncated headers/records; zero tables; unsorted/duplicate tags; record total/work limit |
| Offset origin | tables before and after selected directory; a fixture that succeeds only with collection-root-relative offsets; explicit double-base rejection case |
| Sharing | two faces sharing `glyf`/`loca`/`hmtx` successfully; same-face table overlap rejected; cross-face identical ranges accepted |
| Profiles | supported `0x00010000` glyf face; `OTTO` CFF and CFF2 selected-face capability errors; mixed-profile collection inspection |
| Checksums | selected table mismatch rejected; non-zero collection `head.checksumAdjustment` ignored; unchanged standalone whole-font checksum rejection |
| Atomicity/resources | exact and one-less source/face/record/work/budget boundaries; no partial collection/font publication |
| Revision | drift during collection open, before selection, during selection, and mid-query produces stable state failure |
| Compatibility | every v0.32 standalone public vector and diagnostic remains unchanged |
| Interoperability | selected real face agrees with independent expected metrics, cmap, kern behavior, and outline digest |
| Portability | identical public facts, errors, counts, and outline assertions on `js`, `wasm`, `wasm-gc`, and `native` |

Keep collection fixture helpers test-local. A minimal deterministic TTC builder
should be able to place directories and tables in deliberately unusual legal
orders; a builder that always emits directories first will not detect the
critical base-offset bug. Licensed corpus facts should be recorded as explicit
expected values/digests, not produced at test time by fontTools or another
foreign runtime.

## Recommended Build Order

1. **Freeze the additive public contract and errors** — `FontCollection`,
   `FontCollectionLimits`, face-index semantics, profile policy, and stable
   container contexts; preserve `Font::open`.
2. **Implement bounded TTCHeader admission** — v1/v2, count/offset array,
   collection limits, budget preflight, revision guards, and DSIG envelope.
3. **Generalize the SFNT directory seam** — absolute `directory_offset`,
   root-relative table records, directory-range overlap, all-face structural
   scan, and table sharing rules.
4. **Split checksum policy and refactor shared font admission** — per-table
   checksums for both modes, standalone aggregate checksum only at offset-zero
   facade, early CFF/CFF2 capability rejection.
5. **Wire selected faces into the existing `Font`** — unchanged metrics, cmap,
   kern, glyf, outline, limits, and query revision behavior.
6. **Add hostile and mutation qualification** — base-offset traps, shared
   tables, mixed profiles, exact/one-less limits and budgets, and no partial
   publication.
7. **Add generated and licensed public workflows** — prove selection then the
   same `Font` methods, retain all standalone compatibility vectors.
8. **Run isolated four-target evidence and focused CI** — compare canonical
   facts/errors/digests and archive the exact command/evidence contract.

This order keeps the one new security boundary—the container-to-directory
adapter—ahead of public feature work and lets every later phase reuse already
qualified standalone behavior.

## Scalability and Boundedness

| Concern | Small collection | Large allowed collection | Hostile collection |
|---|---|---|---|
| Header memory | Compact face facts | O(`max_faces`) | Rejected before allocation at face limit |
| Directory inspection | Linear in total records | O(`max_directory_records`) | Stops at cumulative record/work limit |
| Face admission | One selected directory and its tables | Independent of unselected table payload semantics | Selected table/range/profile/checksum failure is atomic |
| Shared tables | Same zero-copy subview | No duplicate retained payload | Repeated references still incur explicitly accounted validation work |
| Queries | Existing per-font behavior | Existing `FontLimits` and per-outline budget | Revision/resource errors remain unchanged |

## Sources

- [OpenType 1.9.1 — OpenType font file and Font Collections](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — TTCHeader v1/v2, collection-root-relative table offsets, table sharing, four-byte alignment, and collection checksum rules (MEDIUM via verified Brave research seam; authoritative Microsoft specification).
- [OpenType 1.9.1 — `head` table](https://learn.microsoft.com/en-us/typography/opentype/spec/head) — `checksumAdjustment` must be ignored for collection components (MEDIUM via verified Brave research seam; authoritative Microsoft specification).
- [OpenType 1.9.1 — glyph format comparison](https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison) — `glyf`, `CFF `, and `CFF2` are distinct outline profiles (MEDIUM via verified Brave research seam; authoritative Microsoft specification).
- [Apple TrueType Reference Manual — Font Tables](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6.html) — independent confirmation of SFNT table-directory structure, root-relative standalone offsets, and TrueType-required `glyf`/`loca` tables (MEDIUM).
- Repository evidence (HIGH, direct source): `modules/mb-font/font/font.mbt`,
  `directory.mbt`, `tables.mbt`, `metrics.mbt`, `cmap.mbt`, `kern.mbt`,
  `outline.mbt`, `limits.mbt`, and
  `modules/mb-core/bytes/views.mbt`.

## Confidence Notes and Open Questions

- **HIGH:** downstream font logic is table-local and does not need collection
  branches; this is directly verified in the shipped source.
- **HIGH:** TTC table offsets are collection-root-relative and collection
  `head.checksumAdjustment` is not used; both are explicit in OpenType 1.9.1.
- **MEDIUM:** whether `face_profile` should be public in v0.33. Omitting it
  gives a smaller compatibility surface while still satisfying selected-face
  admission.
- **MEDIUM:** whether v0.33 should accept a structurally bounded non-null DSIG
  envelope or return capability-unavailable. Do not claim signature validity
  without a dedicated cryptographic verification contract.
- **Phase research flag:** exact budget byte accounting should be frozen during
  implementation planning because the existing standalone admission charges
  the whole source, while collection selection should not multiply unrelated
  payload bytes by the number of faces.

---
*Architecture research for: MoonBit Native Foundation v0.33 TrueType Collection Adapters*
