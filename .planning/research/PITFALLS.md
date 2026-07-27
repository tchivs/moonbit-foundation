# Domain Pitfalls

**Project:** MoonBit Native Foundation — v0.33 TrueType Collection Adapters
**Domain:** Bounded TTC/OTC inspection and selected static-`glyf` face admission
**Researched:** 2026-07-28
**Overall confidence:** MEDIUM — normative claims are cross-checked against official OpenType 1.9.1 sources; project-specific risks are verified against the shipped `mb-font` implementation and v0.32 qualification artifacts

## Executive Warning

This milestone is not “read `ttcf`, slice at the chosen offset, then call
`Font::open`.” That implementation would be wrong in three independent ways:
TTC table-record offsets remain relative to collection byte zero, the
standalone whole-font checksum equation does not apply to a face in a
collection, and the current parser's directory-overlap and work calculations
assume that the SFNT directory begins at source offset zero.

The safe design is a narrow, offset-aware adapter over one retained root
`ByteView`. Collection admission validates the bounded container and face
directory envelopes. Selection passes an absolute directory offset and an
explicit collection checksum policy into the existing atomic font admission
transaction. The result is the existing `Font`; it must not expose raw offsets,
table records, or a second query model.

The suggested owners below use three roadmap-sized implementation phases:

1. **Collection Contract and Envelope** — public types, TTC v1/v2, DSIG,
   counts, structural directory facts, limits, errors, and revision identity.
2. **Offset-Aware Selected-Face Admission** — shared directory parser,
   root-relative tables, checksums, profile isolation, and unchanged `Font`
   integration.
3. **Hostile and Portable Qualification** — generated/licensed fixtures,
   mutation and resource matrices, standalone regression, and four-target
   evidence.

## Critical Pitfalls

### 1. Rebasing root-relative table offsets to the selected directory

**What goes wrong:** The adapter takes
`source.subview(tableDirectoryOffset, ...)` and feeds it to the standalone
parser, or adds the face-directory offset to each `TableRecord.offset`.
OpenType collection table offsets are measured from the beginning of the TTC,
not from the selected directory. Valid tables are read from the wrong bytes,
shared tables become unreachable, and attacker-controlled offsets can be made
to land on a different valid-looking structure.

**Why it happens:** Standalone SFNT has its directory at byte zero, so
directory-local and root-local reasoning accidentally coincide. The shipped
parser reads the SFNT header and records at fixed offsets `0`, `4`, and `12`,
which makes slicing look like a convenient reuse seam.

**Consequences:** Valid TTC/OTC files fail; malformed files can be
misinterpreted; checksums apply to the wrong windows; the collection must later
be rewritten around a root-aware model.

**Warning signs:**

- `Font::open(source.subview(face_offset, ...))` appears in the design.
- A helper computes `absolute_table_offset = face_offset + record.offset`.
- A `TableWindow` retains a view into a face-directory subview rather than the
  collection root.
- Tests use only face zero or fixtures whose table offsets happen to remain
  valid after rebasing.

**Prevention:** Refactor one private directory parser to accept
`directory_offset`, but keep table records resolved against the original root
view. Apply checked addition only to directory-local fields:
`directory_offset + 12 + index * 16`. Do not add `directory_offset` to the
recorded table offset. Retain the root `ByteView` and its opening revision in
both `FontCollection` and the returned `Font`.

**Verification:** Build a two-face micro-collection whose selected directory is
non-zero, whose table records point both before and after that directory, and
whose faces share at least one exact table range. Freeze the selected metrics,
mapping, kerning, and outline facts. Mutate the record offset so that erroneous
rebasing would still land in-bounds; the correct implementation must reject
the checksum or structure rather than admit plausible wrong data.

**Owning implementation phase:** **Phase 2 — Offset-Aware Selected-Face
Admission.**

---

### 2. Reusing standalone directory-range assumptions at a non-zero base

**What goes wrong:** The current standalone rule rejects a non-empty table when
`table_offset < 12 + 16 * numTables`. Generalized mechanically, it either
compares against a directory length without adding the base or rejects every
table numerically before a later face directory. Neither expresses the actual
TTC invariant: a table must not overlap the real TTC header, any face directory
range, or other protected structural range.

**Why it happens:** For a standalone SFNT, “before the end of the only
directory” is a correct shortcut for “overlaps the directory.” A collection
has several disjoint absolute directory ranges, so ordering and overlap are no
longer equivalent.

**Consequences:** Valid layouts can be rejected, or table bytes can overlap
another face directory and be accepted. Later face inspection then reads
attacker-controlled table payload as directory metadata.

**Warning signs:**

- A collection parser still calls a zero-base `font_directory_end`.
- The validation rule is a `< directory_end` comparison instead of checked
  range intersection.
- Only the selected face directory is known when table windows are approved.
- Fixtures always place all directories first and all tables afterward.

**Prevention:** During collection admission, derive checked absolute ranges for
the TTC header including the v2 trailer and for every face directory envelope.
During selected admission, reject intersection with any protected structural
range using `CheckedRange`, not relative ordering. Keep this structural scan
separate from semantic validation of every unselected face's tables.

**Verification:** Cover a later face directory placed near selected table
ranges; exact boundary adjacency; a table ending one byte into a directory; a
directory offset inside the header/offset array; and a zero-length table at
each boundary. Require stable `Data` errors and no collection or font
publication.

**Owning implementation phase:** **Phase 1** establishes protected ranges;
**Phase 2** consumes them for table admission.

---

### 3. TTC v1/v2 and DSIG fields are treated as one loose header

**What goes wrong:** Version 2 fields are read from a version 1 file, an
unknown minor/major version is accepted, a partially null DSIG triple is
treated as absent, or `dsigOffset + dsigLength` is not checked. A parser may
also claim that a present DSIG authenticates the file even though no
cryptographic verification exists.

**Why it happens:** The first 12 bytes and the face-offset array are common to
both versions, while the v2 trailer follows a variable-length array. It is easy
to compute the trailer from an unchecked or prematurely narrowed `numFonts`.
“DSIG present” is also easily confused with “signature verified.”

**Consequences:** Truncated headers are admitted, DSIG bytes can alias
directories or tables, signature presence becomes a false trust signal, and
v1/v2 behavior diverges by target.

**Warning signs:**

- Only the `ttcf` tag is checked; version is ignored or accepts “at least 1.”
- The v2 trailer offset is calculated with an `Int`.
- Any one zero DSIG field means “absent.”
- The public API returns `signed = true` rather than
  `present_unverified`.
- The DSIG range is in-bounds but not required to be the last table.

**Prevention:** Accept exactly TTC header 1.0 and 2.0 for v0.33. Compute
`12 + 4 * numFonts` in checked `UInt64`; for v2, require another 12 bytes. Treat
the all-zero triple as absent. For a present signature require tag `DSIG`, a
checked non-empty range at the end of the file, and the bounded DSIG
version/record envelope the milestone promises. Distinguish malformed
structure from a well-formed but unsupported signature format. Expose only
absence or structurally present/unverified status.

**Verification:** Test v1 and v2 with 0, 1, and several faces; version
0/1.1/2.1/3.0; truncation at every header, array, and trailer byte; all seven
six mixed zero/non-zero DSIG triples; wrong tag; offset/length overflow; DSIG before
another table; trailing bytes; malformed record counts; supported format 1;
and well-formed unsupported formats.

**Owning implementation phase:** **Phase 1 — Collection Contract and
Envelope.**

---

### 4. Count and offset arithmetic becomes allocation authority

**What goes wrong:** `numFonts`, a face directory offset, or `numTables`
is narrowed to `Int` before range validation; `12 + 4 * numFonts` or
`directory + 12 + 16 * numTables` wraps; an array is allocated directly from a
wire count; or `index + 1` is evaluated in a narrower domain.

**Why it happens:** Wire fields are `uint32`, but arrays and indexes are
target-dependent implementation types. The same count participates in header
length, allocation, loop, budget, and public index checks, encouraging one
early conversion.

**Consequences:** Out-of-bounds reads, panics, target divergence, or memory/work
denial of service before the caller's limits and budget can reject the input.

**Warning signs:**

- `Array::make(numFonts.to_int(), ...)` precedes `max_faces` validation.
- Arithmetic mixes `Int`, `UInt`, and `UInt64`.
- `numFonts == 0` is not explicitly handled.
- The collection has `max_source_bytes` but no face or cumulative-directory
  ceilings.
- Tests stop at small positive counts and ordinary truncation.

**Prevention:** Keep all wire and derived facts in checked `UInt64` through
limit comparison, checked range construction, resource preflight, and only
then checked-narrow for array access. Add separate collection limits for at
least source bytes, faces, total directory records, DSIG bytes, allocation
size, and work. Do not reuse `FontLimits.max_tables` as a face limit. Reject
zero faces as malformed under the project profile.

**Verification:** For every count-bearing expression test one-less, exact, and
one-more than the semantic limit; `0`, `0x7fffffff`, `0x80000000`, and
`0xffffffff`; multiplication/addition overflow; final offset equal to source
length; final offset one past; selected index `count - 1`, `count`, and
`UInt64::max_value`; and budget one-short/exact. Compare identical structured
facts on all four targets.

**Owning implementation phase:** **Phase 1 — Collection Contract and
Envelope.**

---

### 5. Duplicate, overlapping, and shared tables are collapsed into one rule

**What goes wrong:** A global overlap detector rejects legitimate tables
shared by multiple faces, or a permissive “TTC tables can be shared” exception
allows duplicate tags, partial overlap, or aliasing within one face. A second
failure mode compares only `(offset, length)` and ignores conflicting tag or
checksum facts for the same shared bytes.

**Why it happens:** The standalone parser correctly requires strictly ordered,
unique tags and non-overlapping table ranges inside one face. Collections add
cross-face sharing, but only the scope of the rule changes; the per-face
invariants do not disappear.

**Consequences:** Real collections are rejected, malformed aliases are
admitted, checksum validation becomes ambiguous, or the same bytes acquire
contradictory identities depending on which face is selected.

**Warning signs:**

- One global “seen range” set rejects the second reference to an exact range.
- Any overlap across faces is allowed because “TTC shares tables.”
- Duplicate tags are deduplicated by first/last wins.
- Two records sharing a range may declare different checksums without error.
- Cross-face validation is quadratic without an explicit work charge.

**Prevention:** Preserve strict tag order/uniqueness and non-overlap within each
face directory. Across faces, allow exact shared table references deliberately;
freeze a fail-closed policy for partial overlap and conflicting metadata.
Represent sharing as multiple immutable references to one root range, not as a
copy or public cache. If structural admission indexes shared ranges, bound and
charge that index; avoid an uncharged all-pairs scan.

**Verification:** Include same-tag exact sharing, different-face distinct
ranges, duplicate tag in one directory, equal offset with shorter/longer
length, one-byte partial overlap, same range with conflicting checksum, overlap
with a directory, zero-length records, and many faces pointing to one table.
Prove legitimate sharing causes no payload copy and has deterministic work
facts.

**Owning implementation phase:** **Phase 2 — Offset-Aware Selected-Face
Admission**, with cumulative structural ceilings established in **Phase 1**.

---

### 6. Standalone whole-font checksum logic is applied to a collection face

**What goes wrong:** Collection selection runs the existing
`font_sfnt_checksum(directory.source, false)` and requires
`0xB1B0AFBA`, or recomputes `head.checkSumAdjustment` as though selected bytes
formed a standalone file. Conversely, a rushed workaround disables every
checksum in collection mode.

**Why it happens:** The shipped `font_validate_checksums` performs both
per-table checks and one whole-source check in the same function. OpenType
1.9.1 explicitly says `head.checkSumAdjustment` is invalidated in a collection
and must be ignored, while individual table checksums remain meaningful.

**Consequences:** Valid TTC/OTC files fail admission; malformed selected tables
can pass if all checks are disabled; whole-collection rescans amplify work for
every selected face.

**Warning signs:**

- Collection mode still expects the root checksum to equal `0xB1B0AFBA`.
- `head.checkSumAdjustment == 0` is rejected for a collection face.
- A Boolean named `skip_checksums` controls the behavior.
- The selected-face work formula includes `2 * collection.length`.
- Tests only use a builder that copies standalone adjustment values unchanged.

**Prevention:** Split checksum policy explicitly. In both modes, calculate each
selected table checksum using its declared length padded to four bytes and
zero the `head.checkSumAdjustment` field for the `head` table checksum. Only
the standalone offset-zero facade performs the aggregate whole-font equation.
Collection mode ignores the stored adjustment and never scans the entire root
as a pseudo-font.

**Verification:** Use a valid TTC with `head.checkSumAdjustment` zero and
non-zero stale values; corrupt one selected shared table; corrupt one
unselected table; alter a declared table checksum; vary non-multiple-of-four
length and pad bytes; and compare standalone versus collection admission of
the same logical face. Assert measured work scales with selected directory and
table bytes, not `collection_size * selections`.

**Owning implementation phase:** **Phase 2 — Offset-Aware Selected-Face
Admission.**

---

### 7. Mixed face profiles poison the collection or leak unsupported outlines

**What goes wrong:** A collection is rejected because any sibling has `OTTO`,
`CFF `, `CFF2`, variation, color, or bitmap tables; or the container is
accepted based only on `ttcf` and a CFF/CFF2 face reaches the quadratic
`glyf` pipeline. Filename `.ttc`/`.otc` is used as the profile authority.

**Why it happens:** Modern OpenType permits mixed outline types in one
collection. The existing standalone parser intentionally rejects CFF/CFF2 and
variable/color profiles, but collection inspection and selected-face admission
are different stages.

**Consequences:** Supported faces become unusable because of unrelated
siblings, or unsupported cubic/variable data is misparsed as static TrueType.
Error categories vary with face ordering.

**Warning signs:**

- Collection open calls full `Font::open` on every face.
- A single collection-wide `is_truetype` flag is inferred from extension.
- Presence of `glyf` alone is enough to classify a face as supported.
- `OTTO` is reported as malformed rather than a well-formed unsupported
  capability.
- Selecting a supported face changes when an unsupported sibling is reordered.

**Prevention:** Structurally inspect every directory envelope, but apply the
semantic outline profile to the selected face. Classify a well-formed face from
its SFNT version and outline tables. v0.33 admits only the existing static
`0x00010000` + `glyf`/`loca` profile and rejects CFF/CFF2, variations, and
other existing out-of-profile tables as `Capability`. A malformed directory or
table remains `Data`. Unsupported siblings must not block a supported
selection merely by existing.

**Verification:** Build mixed collections in both orders: static `glyf` +
CFF, static `glyf` + CFF2, static + variable `glyf`, and supported +
malformed-selected sibling. Inspect count/profile facts, open the supported
face, require capability failure for each well-formed unsupported selection,
and require data failure only for the malformed selection/stage defined by the
contract.

**Owning implementation phase:** **Phase 1** freezes classification/error
semantics; **Phase 2** enforces them at selection.

---

### 8. Face index, directory offset, font identity, and glyph identity blur together

**What goes wrong:** A directory offset is exposed as the public face ID,
face indices become one-based in documentation but zero-based in code, a
selected index is stored in global state, or a glyph numeric value from one
face is assumed to name the same outline in another face.

**Why it happens:** TTC has several integer namespaces: zero-based face-array
index, absolute directory offset, per-face glyph index, Unicode scalar, and
table offsets. Shared tables make two faces look more identical than they are;
`cmap`, `name`, and OS/2 are commonly face-specific even when glyph data is
shared.

**Consequences:** The wrong face is opened, cached glyphs cross faces,
out-of-range errors report misleading limits, and concurrent callers influence
one another.

**Warning signs:**

- Public API accepts a raw directory offset rather than a face index.
- `open_face(1)` is described as “the first face.”
- Collection caches one “current face.”
- Public profile/name facts are used as unique identity.
- Tests use faces with identical cmap and metrics, so swaps are invisible.

**Prevention:** Make the public selection key an explicit zero-based index and
keep directory offsets private. `open_face(index, ...)` returns an independent
existing `Font`; no mutable current-face state. Do not promise that `GlyphId`
is collection-global or face-bound beyond the existing receiving-font numeric
validation contract. Keep face-index range errors distinct from glyph-index
errors, and document that names are metadata rather than identity.

**Verification:** Use two faces with deliberately different cmap, metrics,
name facts, and glyph ordering, including shared `glyf` where practical.
Select first/last/out-of-range indices, interleave operations on both returned
fonts, pass equal numeric glyph values intentionally, and prove deterministic
receiving-font semantics without global state.

**Owning implementation phase:** **Phase 1** freezes public identity semantics;
**Phase 2** proves independent returned fonts.

---

### 9. Revision checks leave a collection-to-font mutation window

**What goes wrong:** `FontCollection::open` records a root revision, but
`open_face` trusts copied offsets without rechecking. Or it checks only before
selected admission, allowing mutation after table reads and before `Font`
publication. A returned `Font` retains a subview with a new revision identity
instead of the original collection root.

**Why it happens:** Collection objects may contain immutable copied metadata,
which creates the impression that no further source read needs guarding.
Selected admission actually reads root table bytes and can span many checksums
and allocations.

**Consequences:** Time-of-check/time-of-use admission publishes facts from
multiple byte revisions. Mutation back to the original bytes can evade value
comparison. Collection and Font disagree about which revision they represent.

**Warning signs:**

- `face_count` checks revision but `inspect_face` or `open_face` does not.
- Only an entry guard exists around long selected admission.
- A selected `Font` records `subview.mutation_revision()` after parsing.
- Mutation of unrelated or unselected bytes is ignored even though the root
  collection identity changed.
- Tests mutate only before calling an operation.

**Prevention:** Capture the root revision before collection discovery and
recheck immediately before collection publication. Every public collection
operation checks it. `open_face` checks before reading and immediately before
publishing the `Font`; the returned `Font` retains the same root and opening
revision so its existing pre/post-query guards continue to work. Revision
change is permanently a `State` failure for that admitted object; do not
silently revalidate.

**Verification:** Add deterministic hooks for mutation after index validation,
after directory reads, during a shared-table checksum, after selected semantic
admission, and just before publication. Mutate header, selected table,
unselected table, padding, and DSIG; mutate back to original value. Require no
partial collection, face facts, glyph, metric, kerning, or path publication.

**Owning implementation phase:** **Phase 1** for collection lifetime;
**Phase 2** for handoff into `Font`; **Phase 3** for mid-operation evidence.

---

### 10. Collection and selected-face work amplify each other

**What goes wrong:** Opening one face rescans/checksums the complete collection,
opening the collection semantically admits every face, an all-pairs overlap
scan grows quadratically, or exact shared tables are revalidated repeatedly
without accounting. Small metadata can authorize huge arrays or repeated
work.

**Why it happens:** The current standalone work model includes whole-source
checksum work and pairwise table-overlap work. Reusing it with the collection
root means every face pays for every byte, while eager all-face validation
turns `numFonts` into a work multiplier.

**Consequences:** A bounded file still causes disproportionate CPU and
allocation, repeated selection drains caller budgets unpredictably, and
“no-copy” is advertised while large hidden indexes/caches are retained.

**Warning signs:**

- Collection open loops over `Font::open` for every face.
- Selected-face work contains `collection.length * 2`.
- `max_faces` exists but `max_total_directory_records` does not.
- Arrays/maps are filled before `Budget::preflight`.
- Shared-table checksum results are cached persistently without charged
  allocation or deterministic eviction.
- Benchmarks report only one tiny two-face fixture.

**Prevention:** Separate collection structural work from selected semantic
work. Preflight face-offset storage and cumulative directory records before
allocation. Charge exact checked header/directory scans, retained bookkeeping,
checksum bytes actually visited, and any range index. Do not interpret
referenced root bytes as copied allocation. Avoid hidden persistent face or
table caches in v0.33; if a request-local memo is needed, bound and charge it.
Keep `FontLimits` authoritative for the selected face.

**Verification:** Create many-face collections with tiny directories, few
faces with maximum allowed records, all faces sharing one large table, no
sharing, and repeated selection schedules. Test every budget/limit at
one-short/exact/one-over; assert failed admissions publish nothing; record
work/allocation facts and demonstrate selected work is independent of
unselected payload size except for declared collection structural scanning.

**Owning implementation phase:** **Phase 1** defines collection limits and
charges; **Phase 2** separates selected-face charging; **Phase 3** qualifies
amplification boundaries.

---

### 11. Error taxonomy and validation order drift across entry points

**What goes wrong:** The same malformed offset is `InvalidInput` through
collection inspection and `Data` through selection; CFF is sometimes
malformed and sometimes unsupported; an out-of-range caller index reads a
directory before failing; budget exhaustion masks an earlier structural error;
or errors become collection-specific strings that consumers cannot classify.

**Why it happens:** v0.33 adds container, inspection, and selection stages in
front of an existing parser with established `Data`, `Capability`, `Resource`,
`State`, and invalid-input outcomes. Without an explicit precedence contract,
each helper returns whichever error it encounters first.

**Consequences:** Automated callers cannot distinguish retry, caller repair,
unsupported capability, hostile bytes, or mutation. Tests become coupled to
incidental loop order and future refactors become breaking changes.

**Warning signs:**

- Public collection errors are plain text or a new unrelated enum.
- Invalid index and malformed indexed directory share one context.
- “Unsupported” is used for truncated CFF/DSIG data.
- Resource charges occur before the bounded header needed to compute them is
  structurally readable.
- A failed `open_face` mutates collection state or publishes cached partials.

**Prevention:** Reuse `CoreError` and freeze stage-specific operation/context
names. Recommended distinction: malformed wire/header/directory/checksum is
`Data`; well-formed unsupported outline/signature capability is `Capability`;
caller index or invalid limits is `InvalidInput`; semantic ceiling or Budget
failure is `Resource`; revision drift is `State`. Check collection revision and
caller index before selected-face reads. Define which minimal structural facts
must be read before resource preflight and preserve that order on every target.

**Verification:** Maintain a closed error matrix recording operation,
category, code, context, source offset, requested, limit, and publication
outcome for each malformed/unsupported/resource/mutation case. Include inputs
with two simultaneous faults to freeze precedence deliberately. Verify the
unchanged standalone API retains its existing contexts.

**Owning implementation phase:** **Phase 1** freezes the taxonomy;
**Phases 2–3** enforce and qualify it.

---

### 12. The adapter leaks container internals or forks the Font API

**What goes wrong:** Public inspection exposes mutable `ByteView`s, raw table
offsets, directory records, or DSIG bytes; selected faces return a
`CollectionFace` with duplicate metrics/cmap/kern/outline methods; or collection
support silently changes `Font::open` to accept `ttcf`.

**Why it happens:** Raw facts are convenient for debugging, and a parallel
face type avoids refactoring the private zero-base parser. Both choices create
permanent compatibility and security surface.

**Consequences:** Callers depend on storage layout, bypass checked table
windows, or face two drifting APIs. Standalone consumers see changed
acceptance, checksums, errors, documentation, or budgets.

**Warning signs:**

- `FontCollection::table_offset` or public `TableRecord` appears.
- Metrics and outline methods are copied onto a new face type.
- `Font::open(ttcf_bytes, ...)` automatically selects face zero.
- Standalone tests are updated to new outputs instead of kept as frozen
  baselines.
- Two implementations validate table tags/checksums.

**Prevention:** Keep the additive public surface narrow: bounded collection
open, face count/inspection facts, and explicit zero-based face selection.
Return the existing `Font`. Refactor one private `font_open_at`/directory seam
parameterized by absolute directory offset and checksum mode. Keep
`Font::open` as the standalone offset-zero facade and preserve its `ttcf`
capability rejection. Raw offsets and source views remain private.

**Verification:** Run the complete v0.32 standalone suite and qualification
unchanged. Add API-surface checks proving no duplicate query type or raw
storage accessor. For the same logical generated face, compare standalone and
collection-returned `Font` metrics, mapping, kerning, outlines, glyph-ID
validation, revision errors, and resource behavior.

**Owning implementation phase:** **Phase 1** freezes the additive API;
**Phase 2** performs the shared-parser refactor; **Phase 3** proves standalone
compatibility.

## Moderate Pitfalls

### 13. Malformed unselected faces are either trusted or eagerly overvalidated

**What goes wrong:** Collection open validates only the selected offset array
and retains arbitrary unvalidated directory offsets, or it performs full
checksums/cmap/metrics/outline admission for every sibling.

**Prevention:** Freeze a two-stage boundary. Collection admission validates the
header, every face directory envelope, protected-range relationships, and
bounded profile facts needed for safe inspection. Deep table semantics and
checksums are selected-face work. A structurally malformed directory prevents
collection publication; a structurally bounded but semantically malformed
face fails when selected without poisoning unrelated supported selections.

**Warning signs:** `open_face` can encounter an out-of-bounds directory first
discovered long after collection publication, or collection admission cost is
proportional to all table payload bytes.

**Verification:** Distinguish malformed header, malformed directory envelope,
malformed selected table, and malformed unselected table in the error matrix.
Prove the collection remains immutable and reusable after an atomic selected
face failure when the frozen stage contract permits it.

**Owning implementation phase:** **Phase 1** defines structural admission;
**Phase 2** defines selected semantics.

---

### 14. Four-target equality is inferred from one backend

**What goes wrong:** Native passes while JS/Wasm narrow large offsets or counts
differently, array conversion traps on one target, error offsets are formatted
differently, or unordered map iteration changes the first reported overlap.

**Prevention:** Keep all parse arithmetic in checked `UInt64`, use deterministic
arrays/sorts with frozen tie-breaking, avoid FFI and host font APIs, and
canonicalize semantic facts rather than locale-formatted diagnostics. Execute
the same tests independently on `js`, `wasm`, `wasm-gc`, and `native`.

**Warning signs:** A native-only fixture loader or font tool participates in
runtime assertions; large arithmetic vectors are omitted; canonical evidence
contains platform paths or prose; one umbrella command is assumed to cover all
targets.

**Verification:** Require identical face count/profile, selected metrics/cmap/
kern/outlines, error category/code/context/offsets, mutation outcomes, and
budget facts on all four targets. Include values above signed 31-bit and at
32-bit boundaries even when the source itself is compact.

**Owning implementation phase:** **Phase 3 — Hostile and Portable
Qualification.**

---

### 15. Fixtures are non-reproducible, legally incomplete, or self-confirming

**What goes wrong:** Tests use installed system TTCs, download a moving font,
vendor a collection without its license, transform a font without recording
the derivative, or generate both input and expected values with production
code.

**Prevention:** Combine small repository-generated collections with a
redistributable licensed specimen. For every external or derived binary record
upstream release/URL, retrieval date, input and output SHA-256, license
expression and full notice, redistribution status, generator/tool version and
exact command, whether table bytes are original/shared/transformed, and
intended coverage. DejaVu's official license requires the relevant notices to
accompany redistribution; the repository's existing DejaVu Sans 2.37 manifest
is the minimum baseline, not sufficient metadata for an unrecorded TTC
derivative.

**Warning signs:** Fixture paths escape the repository; CI reads host fonts or
network; only a filename identifies provenance; expected checksums/metrics are
computed by `mb-font`; a “real TTC” is committed without a notice or derivative
manifest.

**Verification:** Add a qualification selector that verifies fixture and
notice digests, manifest coverage, generator drift, no network/host-font
access, and independent oracle facts. Generated hostile fixtures should be
Apache-2.0 repository artifacts and explain each byte-level mutation.

**Owning implementation phase:** **Phase 3 — Hostile and Portable
Qualification**; fixture policy is frozen in **Phase 1**.

---

### 16. Qualification produces false confidence from happy-path collections

**What goes wrong:** Evidence proves `face_count == 2` and one metrics call but
misses non-zero-base offsets, sharing, v2 DSIG, mixed profiles, mutation,
budgets, standalone compatibility, or the full existing Font workflow.

**Prevention:** Use three independent evidence layers:

1. generated minimal fixtures that isolate every boundary and hostile mutation;
2. a licensed real collection/derivative with committed independent semantic
   facts; and
3. unchanged standalone v0.32 qualification.

The public workflow must select at least two distinct indices and exercise the
same metrics, BMP/supplementary cmap, kern, simple/composite outline, and
revision behavior as standalone. Evidence must record exact commands, target,
exit status, full-session termination, fixture/toolchain digests, and canonical
facts.

**Warning signs:** All tables are unique; only face zero is selected; a CFF
sibling is absent; DSIG is always null; mutation occurs only before open; the
oracle shares production parsing code; or CI labels a lane “four-target”
without separate target runs.

**Verification:** Maintain a requirement-to-case matrix covering TTC-01 through
TTC-05, including one-less/exact/one-more resource cases and faults with
plausible in-bounds rebased offsets. Independently review the canonical output
schema and fail on missing selectors, duplicate labels, skipped targets, or
stale fixture digests.

**Owning implementation phase:** **Phase 3 — Hostile and Portable
Qualification.**

## Minor Pitfalls

### 17. DSIG presence is surfaced as security assurance

**What goes wrong:** Documentation or a Boolean property implies that a
structurally present DSIG has been cryptographically authenticated.

**Prevention:** Name the fact `present_unverified` or equivalent, document that
trust-store and cryptographic verification are out of scope, and never use
DSIG presence to relax structural/checksum validation.

**Verification:** Documentation/API review and a fixture with structurally
valid but cryptographically meaningless signature bytes.

**Owning implementation phase:** **Phase 1**, with public-doc verification in
**Phase 3**.

---

### 18. File extension or face names become admission authority

**What goes wrong:** `.ttc` is assumed to mean TrueType outlines, `.otc` to
mean CFF, or duplicate/localized `name` records are used as stable selectors.

**Prevention:** Admit from bytes, classify each face from its directory and
tables, select only by explicit zero-based index in v0.33, and treat names as
optional metadata outside the identity contract.

**Verification:** Feed the same bytes under no filename and misleading
extensions; include duplicate face names and a mixed-profile collection.

**Owning implementation phase:** **Phase 1 — Collection Contract and
Envelope.**

## Phase-Specific Warnings

| Phase topic | Likely pitfall | Required mitigation |
|---|---|---|
| Phase 1: public contract | Face offset/name leaks as identity | Zero-based index only; private offsets; existing `Font` result |
| Phase 1: TTC header | `numFonts` overflow or premature allocation | Checked `UInt64`, explicit `max_faces`, budget preflight before allocation |
| Phase 1: TTC v2 | Partial DSIG triple or false trust claim | All-zero absence, bounded last-table envelope, `present_unverified` semantics |
| Phase 1: structural scan | Eager semantic admission of every face | Validate bounded envelopes/protected ranges only; defer selected semantics |
| Phase 1: errors | Data/Capability/Resource/State collapse | Freeze operation, category, code, context, offset, requested/limit precedence |
| Phase 2: parser refactor | Directory slice rebases table offsets | Root view + absolute directory base; record offsets stay root-relative |
| Phase 2: overlap | Shared range rejected or partial overlap accepted | Per-face strictness; deliberate exact cross-face sharing policy |
| Phase 2: checksum | Standalone aggregate checksum used in TTC | Per-table checks always; aggregate equation standalone-only |
| Phase 2: profile | CFF sibling poisons supported face | Per-face classification and selected capability failure |
| Phase 2: resource model | Whole collection scanned per selection | Charge selected directory/table bytes and explicit structural work only |
| Phase 2: mutation | Drift between selection and Font publication | Root revision checks before and after; returned Font retains same root/revision |
| Phase 3: fixtures | Builder and oracle share the same bug | Independent generator/oracle; adversarial non-zero-base/shared layouts |
| Phase 3: licensing | TTC derivative lacks provenance/notice | Source and derivative digests, exact tool/command, complete license record |
| Phase 3: portability | Native-only evidence hides narrowing | Separate canonical js/wasm/wasm-gc/native runs with large boundary facts |
| Phase 3: compatibility | New adapter weakens standalone behavior | Run unchanged v0.32 suite and exact public qualification baselines |

## Technical Debt Patterns

| Shortcut | Long-term cost | Acceptable? |
|---|---|---|
| Slice at selected directory and call `Font::open` | Fundamentally wrong offset model | Never |
| Copy/reconstruct a standalone SFNT | Violates no-copy goal and creates new checksum/resource semantics | Never for v0.33 |
| Duplicate the standalone parser | Validation and error behavior drift | Never |
| Expose raw directory/table offsets | Permanent storage-layout API and bypass risk | Never |
| Open face zero implicitly | Identity ambiguity and silent behavior | Never |
| Validate all faces semantically at collection open | Work amplification and sibling poisoning | Never |
| Disable all checksums for TTC | Corrupted selected tables are admitted | Never |
| Cache all opened faces/shared tables | Query-history-dependent memory and budgets | Defer to explicit caller-owned caching |
| Use filename/extension for profile | Mixed collections are misclassified | Never |
| Use system fonts in tests | Non-reproducible and licensing-sensitive | Never |
| Generate expected facts with production parser | Shared-bug false confidence | Never |

## “Looks Done But Isn’t” Checklist

- [ ] TTC 1.0 and 2.0 are distinguished exactly; unknown versions fail.
- [ ] `12 + 4*numFonts` and the v2 trailer are checked before narrowing or
      allocation.
- [ ] Every face directory envelope is structurally bounded against the root.
- [ ] Selected table records remain root-relative and never add the face base.
- [ ] Protected structural ranges use intersection, not zero-base ordering.
- [ ] Per-face duplicate tags and overlaps fail; exact cross-face sharing works.
- [ ] Partial/conflicting shared ranges have one frozen fail-closed policy.
- [ ] Per-table checksums remain active; `head.checkSumAdjustment` is ignored
      only for collection aggregate semantics.
- [ ] Supported static-`glyf` selection succeeds beside CFF/CFF2/variable
      siblings; unsupported selection is `Capability`.
- [ ] Face index, directory offset, glyph index, and Unicode scalar remain
      separate namespaces.
- [ ] Collection and returned Font retain one root revision identity with
      pre/post-operation guards.
- [ ] Collection limits cover faces, cumulative records, DSIG, allocations,
      and work; selected `FontLimits` remain authoritative.
- [ ] Work evidence rules out whole-collection rescans per selected face.
- [ ] Every failure publishes neither a partial collection nor a partial Font.
- [ ] Public errors preserve stable category/code/context/offset facts.
- [ ] `Font::open` standalone behavior and v0.32 qualification remain unchanged.
- [ ] Generated fixtures isolate v1/v2, base offsets, sharing, mixed profiles,
      checksums, limits, budgets, mutation, and error precedence.
- [ ] Licensed derivatives include exact source/output digests, tool/command,
      provenance, redistribution status, and complete notices.
- [ ] Canonical public facts and hostile errors match independently on `js`,
      `wasm`, `wasm-gc`, and `native`.

## Pitfall-to-Phase Mapping

| Pitfall | Earliest prevention phase | Required verification |
|---|---|---|
| Root-relative offsets rebased | Phase 2 | Non-zero directory with plausible in-bounds wrong-base trap |
| Zero-base directory overlap shortcut | Phase 1/2 | Actual protected-range intersection matrix |
| TTC v1/v2 and DSIG confusion | Phase 1 | Every header/trailer truncation and DSIG state |
| Count/offset overflow | Phase 1 | 32-bit boundary and one-short/exact/one-over matrix |
| Shared versus overlapping tables | Phase 2 | Exact sharing, partial overlap, conflicting metadata |
| Collection checksum misuse | Phase 2 | Zero/stale adjustment plus selected table corruption |
| Mixed-profile poisoning | Phase 1/2 | Static + CFF/CFF2/variable in both orders |
| Face/font/glyph identity confusion | Phase 1/2 | Distinct faces and interleaved query workflows |
| Mutation window | Phase 1/2 | Deterministic mid-admission drift without publication |
| Work/allocation amplification | Phase 1/2 | Many faces/shared large table/repeated selection budgets |
| Error taxonomy drift | Phase 1 | Closed multi-fault precedence matrix |
| API leakage/standalone regression | Phase 1/2 | API surface check plus unchanged v0.32 qualification |
| Unselected malformed semantics | Phase 1/2 | Structural versus selected-semantic stage cases |
| Four-target divergence | Phase 3 | Identical canonical facts/errors on four targets |
| Fixture provenance/license gaps | Phase 3 | Manifest, notice, source/derivative digest selector |
| Qualification false confidence | Phase 3 | Requirement-to-case coverage and independent oracle |

## Sources

### Primary specifications — MEDIUM via verified `websearch`

- [OpenType font file, OpenType 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) —
  TTC/OTC structure, v1/v2 headers, root-relative directory/table offsets,
  table sharing, mixed outline profiles, and required TrueType tables.
- [`head` table, OpenType 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/head) —
  `checkSumAdjustment` must be ignored when the font is a component of a
  collection.
- [DSIG table, OpenType 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/dsig) —
  ordered unique table records, alignment/non-overlap/checksum conditions,
  collection-wide signature placement, and collection checksum-adjustment
  differences.
- [Recommendations for OpenType Fonts, OpenType 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/recom) —
  extension is not outline authority, outline mixing guidance, and table
  alignment/checksum recommendations.
- [Comparison of `glyf`, `CFF `, and CFF2](https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison) —
  distinct quadratic versus cubic outline systems and capability boundary.
- [CFF table, OpenType 1.9](https://learn.microsoft.com/en-us/typography/opentype/otspec190/cff) —
  CFF collection sharing and face-specific naming behavior.

### Fixture authority — MEDIUM via verified `websearch`

- [DejaVu Fonts license](https://dejavu-fonts.github.io/License.html) —
  redistribution, notice, modification, and naming conditions.

### Project authority — directly verified local sources

- `.planning/PROJECT.md` — v0.33 goal, constraints, active requirements, and
  shipped v0.32 guarantees.
- `.planning/research/STACK.md` — collection checksum/profile policy, no-copy
  root-view adapter, and WOFF/CFF exclusions.
- `.planning/research/FEATURES.md` — inspection, selection, error, resource,
  and qualification contract.
- `.planning/research/ARCHITECTURE.md` — component boundaries, protected range
  strategy, root revision ownership, and build order.
- `modules/mb-font/font/directory.mbt` — shipped zero-base parsing,
  overlap/checksum work, checked arithmetic, and structured outcomes.
- `modules/mb-font/font/font.mbt` — atomic standalone admission, retained root
  revision, and existing public query guards.
- `modules/mb-font/font/limits.mbt` — current selected-face semantic limits.
- `fixtures/manifest.json` and
  `fixtures/font/dejavu-sans-2.37/LICENSE` — current provenance, digests,
  redistribution status, and notice baseline.

## Confidence and Open Questions

| Area | Confidence | Notes |
|---|---|---|
| TTC v1/v2, offsets, sharing | MEDIUM | Direct official OpenType 1.9.1 rules, cross-checked across `otff` and DSIG |
| Collection checksum policy | MEDIUM | Explicit official `head` and DSIG language |
| CFF/CFF2 boundary | MEDIUM | Official outline-format and collection rules |
| Current parser regression risks | HIGH as local observation | Directly verified in shipped MoonBit source; confidence tier is not supplied by the web provider seam |
| Mutation and budget risks | HIGH as local observation, MEDIUM as proposed policy | Existing revision/budget implementation is direct evidence; exact collection charge model must be frozen in Phase 1 |
| Cross-face partial-overlap policy | MEDIUM | Exact sharing is normative; project should explicitly freeze fail-closed handling for ambiguous partial aliasing |
| Licensed TTC derivative choice | MEDIUM | Existing DejaVu provenance is solid; exact v0.33 derivative/tooling has not yet been chosen |

**Phase research flags:**

- Phase 1 must settle the exact structural-versus-selected validation boundary,
  cumulative directory limit, DSIG envelope depth, and error precedence.
- Phase 2 must settle the exact permitted cross-face range-sharing relation and
  collection-mode resource charge before implementation.
- Phase 3 should independently audit fixture derivative licensing metadata and
  the evidence selector's actual four-target coverage.
