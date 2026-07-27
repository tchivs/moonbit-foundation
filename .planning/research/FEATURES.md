# Feature Landscape: v0.33 TrueType Collection Adapters

**Domain:** Portable, bounded TTC/OTC inspection and selected-face admission for the existing static TrueType `glyf` font contract
**Researched:** 2026-07-28
**Overall confidence:** MEDIUM — project behavior and the shipped `mb-font` contract are HIGH-confidence local authority; current OpenType 1.9.1, FreeType 2.14.3, and `ttf-parser` 0.25.1 behavior was cross-checked through a research provider classified MEDIUM by the GSD confidence seam.

## Product Boundary

v0.33 should add an explicit collection adapter beside, not inside, the existing standalone entry point:

```text
caller-owned bounded ByteView
  └─→ FontCollection::open(... collection limits/budget ...)
        ├─→ header_version / face_count / DSIG presence
        ├─→ inspect_face(index) → bounded face profile facts
        └─→ open_face(index, ... existing font limits/budget ...)
              └─→ existing opaque Font
                    ├─→ metrics
                    ├─→ cmap
                    ├─→ kern
                    └─→ glyf outline
```

Exact names may change during planning, but the semantic boundary should not:

- `Font::open` continues to mean one standalone `0x00010000` SFNT and preserves every shipped success byte/fact and error outcome. It must not silently auto-detect `ttcf`.
- A new collection value retains the original root byte view, validates a TTC header and every face-directory envelope atomically, and exposes a zero-based face count.
- Face inspection is format-neutral enough to classify a face without pretending to support it.
- Full font admission is performed only for the caller-selected face and returns the existing `Font` type only when that face is a supported, static, `glyf`-based profile.
- The adapter does not copy, extract, rewrite, or synthesize a standalone font. Collection table offsets remain relative to the collection root, as required by OpenType.

The collection layer owns container structure, face addressing, and collection-specific checksum rules. It does not own filesystem discovery, family/style matching, fallback, text shaping, hinting, rasterization, compressed web-font decoding, font authoring, or signature trust policy.

## User-Visible Behavior Contract

| Situation | Required result | Classification |
|---|---|---|
| Valid TTC header version 1.0 | Publish a collection with exact face count and no DSIG metadata | Success |
| Valid TTC header version 2.0 with all DSIG fields zero | Publish a collection and report no DSIG | Success |
| Valid TTC header version 2.0 with a structurally valid DSIG v1 / format-1 envelope at EOF | Publish a collection and report DSIG presence; do not claim cryptographic authenticity | Success |
| Unknown TTC major version or declared unknown DSIG version/format | Distinguish a recognized but unsupported capability from malformed bytes | Capability |
| Wrong collection magic, truncated header/offset array, zero face count, inconsistent DSIG tuple, overflowed range, or DSIG not at EOF | Publish no collection | Data |
| Declared face count exceeds the caller's collection limit or inspection exceeds budget/work limits | Publish no collection | Resource |
| Face index in `0 ..< face_count` | Inspect or attempt admission of exactly that face | Success path |
| Face index equals/exceeds `face_count` | Fail immediately without clamping, wrapping, defaulting to face 0, or scanning unrelated faces | Invalid input |
| Mixed collection containing supported `glyf` and unsupported CFF/CFF2/variable faces | Collection inspection succeeds; each face reports its own profile; supported sibling admission remains possible | Per-face capability |
| Selected static `glyf` face | Return an ordinary existing `Font`; its metrics, mapping, kerning, glyph IDs, and outlines obey the v0.32 contract | Success |
| Selected CFF, CFF2, variable, bitmap-only, or otherwise deferred face | Return a structured capability error and no `Font`; keep the already-open collection usable | Capability |
| Two faces reference the same table bytes | Admit either face correctly without rejecting legitimate cross-face sharing or copying the shared table | Success |
| Selected face has a malformed directory/table graph | Return the same category of structured data failure as the equivalent standalone defect; publish no `Font` | Data |
| Source mutates after collection admission, even if the original byte is restored | All later collection inspection/selection fails with revision drift; already-derived fonts also fail their existing revision guards | State |
| Collection or face admission exact-fit budget/limit | Succeed and commit one deterministic charge | Success |
| Same operation one unit short | Fail atomically with requested/limit facts and no newly published value | Resource |

## Table Stakes

Missing any item below makes the advertised collection adapter incomplete.

| Feature | Why Expected | Complexity | Required Behavior |
|---|---|---:|---|
| Additive collection API with frozen standalone behavior | Existing consumers already rely on `Font::open` accepting only standalone TrueType SFNT bytes and on its exact structured failures. | MEDIUM | Add a separate collection type/entry point. Re-run the full standalone qualification unchanged; `Font::open(ttcf...)` retains its current unsupported-profile outcome. |
| TTC/OTC header versions 1.0 and 2.0 | OpenType 1.9.1 defines exactly these two collection-header layouts. `.ttc` and `.otc` use the same `ttcf` container structure; filename extension is not available or authoritative for byte APIs. | MEDIUM | Require `ttcf`; accept major/minor 1.0 and 2.0; use checked big-endian reads; reject unknown major versions as unsupported and malformed recognized headers as data errors. |
| Exact face count with bounded zero-based indexing | OpenType stores a `numFonts` count followed by an ordered offset array. FreeType and `ttf-parser` expose faces using zero-based indices. | MEDIUM | Reject zero count as invalid data; apply `max_faces` before count-driven traversal/allocation; expose exact count; accept `count - 1`; reject `count` and larger as caller input without fallback to face 0. |
| Atomic container-envelope validation | Publishing a collection whose offset array cannot be addressed safely merely defers an already-known container failure. | HIGH | Before publishing, validate the complete header, checked `12 + 4 * numFonts` range, v2 trailer location, every directory offset, minimum directory header, checked directory-record envelope, and collection-level DSIG envelope. Do not deeply parse every face table. |
| Bounded face inspection | Callers need to know whether a face is usable without paying for complete metrics/cmap/outline admission. Mixed-outline collections are valid OpenType. | HIGH | For an in-range face, report at least index and outline/profile classification: supported static TrueType `glyf`; CFF; CFF2; variable `glyf`; or other unsupported/invalid. Inspection must check source revision before and after its work and publish no partial info on failure. |
| Per-face qualification in mixed collections | OpenType 1.9.1 explicitly allows collections to contain different outline types and to mix variable/non-variable faces. Rejecting the whole collection because one sibling is unsupported is incorrect for the stated goal. | HIGH | Structural collection admission is outline-neutral. Full capability rejection occurs for the selected face only. A valid static `glyf` face remains selectable when a sibling uses `OTTO`, `CFF `, CFF2, `fvar`/`gvar`, or another deferred profile. |
| Offset-aware, no-copy selected-face admission | In a collection, every table record offset is relative to the TTC root, not the selected table-directory position. Shared tables make extraction to a simple slice incorrect. | HIGH | Selected admission uses the root source plus face-directory base through one internal offset-aware source model. It retains the caller's bytes, creates table-local subviews, and never copies/repackages the complete face or collection. |
| Legitimate cross-face table sharing | Table sharing is the defining space-saving behavior of TTC/OTC. Identical `glyf`, `loca`, `hmtx`, `maxp`, and other tables may be referenced by multiple face directories. | HIGH | Allow two different face directories to reference identical table ranges. Preserve the existing no-overlap rule among distinct table records within one selected face, while not applying that rule globally across sibling directories. Validate a shared table for each selected face's own cross-table invariants. |
| Collection-specific checksums | OpenType states that table checksums reflect the table bytes in the collection and that `head.checksumAdjustment` is not used for collection files. Reusing standalone whole-file checksum logic unchanged would reject valid TTCs. | HIGH | Keep per-table checksum validation, including zeroing `head.checksumAdjustment` when calculating the `head` table checksum. Do not require the TTC root or a selected logical face to sum to the standalone `0xB1B0AFBA` invariant. Standalone validation remains unchanged. |
| TTC v2 DSIG structural support | A v2 header can be unsigned or can point to one DSIG table for the whole collection. The DSIG applies to the file, not individual faces. | HIGH | Require the v2 DSIG tuple to be either all zero or internally consistent with `DSIG`, a checked range, and a table ending at collection EOF. Bound signature-record count/work. Recognize DSIG table version 1 and expected format 1. Treat payload bytes as opaque; never report a signature as trusted. |
| Separate collection and selected-face resource authority | A small header can claim billions of faces or point repeatedly into expensive directories. Existing `FontLimits` do not bound the new collection loop. | HIGH | Add explicit collection limits at least for source bytes, faces, DSIG signatures/bytes, and collection work. Then apply every existing `FontLimits` dimension to the selected face. Both collection opening and face opening use caller-owned budget transactions with exact/one-short evidence. |
| Root identity and mutation propagation | The implementation deliberately retains caller-owned mutable storage instead of copying. The shipped contract treats revision change as permanent invalidation. | HIGH | Store root source identity and opening revision in the collection. Every public collection operation uses pre/post revision guards. A derived `Font` retains the same root view/revision, so any mutation invalidates the collection and every derived font, including mutation followed by byte restoration. |
| Structured, stage-specific failures | Consumers must distinguish bad caller index, bad collection bytes, unsupported face profile, resource exhaustion, and source drift. | MEDIUM | Freeze stable category/code/operation/context facts for collection open, face inspection, and face admission. Failed collection open publishes nothing; failed face open publishes no font but does not invalidate an unchanged already-open collection. |
| Portable reproducible qualification | Collection offset arithmetic and mutation semantics must not vary among MoonBit backends. | HIGH | Generated, licensed, shared-table, mixed-profile, DSIG, hostile, standalone-compatibility, and public workflow selectors pass independently on `js`, `wasm`, `wasm-gc`, and `native` with identical semantic facts. |

## Recommended Inspection Surface

Keep the public inspection surface deliberately small and semantic:

| Public fact | Recommendation | Rationale |
|---|---|---|
| Collection face count | Expose | Required to choose a valid zero-based index. |
| TTC header version | Expose as a small enum/value | Useful for diagnostics and DSIG expectations without exposing raw bytes. |
| DSIG presence | Expose as `Bool` or small status enum | Lets inspectors report signed/unsigned structure without claiming verification. |
| Face outline profile | Expose a closed classification that includes supported static TrueType and recognized unsupported categories | Prevents trial-and-error opening and makes mixed collections useful. |
| Raw directory offsets and table records | Keep private | They are parser implementation facts, easy to misuse as durable identity, and unnecessary for the milestone. |
| Names/family/style metadata | Defer | Requires a broader `name` decoding policy and risks turning collection inspection into font discovery. |
| Cryptographic signer/certificate details | Exclude | Requires PKCS#7/X.509 parsing, trust stores, time/revocation policy, and host integration. |

## Differentiators

These are valuable MNF qualities beyond a permissive collection decoder.

| Feature | Value Proposition | Complexity | Required Evidence |
|---|---|---:|---|
| Inspect once, admit one | Container structure is validated once, but only the selected face pays complete TrueType admission cost. | HIGH | A large-count generated collection proves opening does bounded envelope work; selecting one face does not scan/admit every sibling's tables. |
| Capability isolation across siblings | One unsupported or face-local malformed sibling does not erase access to a valid supported face. | HIGH | Mixed fixture: inspect all profiles; open static `glyf` face successfully; CFF/CFF2/variable selections fail with capability; deep corruption in an unselected face is reported only when that face is selected. Container-level invalid offsets still reject the collection. |
| No-copy sharing preserved end to end | Memory use stays proportional to small indices and selected-face state rather than duplicating file-sized tables. | HIGH | Instrumented/internal assertions prove returned table windows point into the retained root owner; a shared `glyf` table is not materialized once per face. |
| Exact collection work accounting | Attackers cannot hide work behind large face arrays, DSIG record arrays, or repeated inspection. | MEDIUM | Exact-fit and one-short cases freeze source bytes, face count, DSIG count, allocation size, and work requested/limit fields. |
| Permanent mutation fail-closed semantics | Stronger than a checksum-only design: restore-after-mutate cannot resurrect stale admitted facts. | MEDIUM | Mutate header, face offset, selected directory, and shared table at controlled pre/post points; collection/derived-font operations all return the established State error and publish no fresh value. |
| Semantic qualification rather than parser snapshots | Downstream developers care that the selected face behaves exactly like a standalone `Font`, not which internal structs were built. | MEDIUM | Public workflow compares units-per-em, mapping, metrics, kerning, outline commands/digest, and error facts for collection-selected and standalone equivalents on four targets. |

## Anti-Features

These should be explicitly excluded from v0.33.

| Anti-Feature | Why Avoid | What to Do Instead |
|---|---|---|
| Auto-detect collections inside `Font::open` | Changes the shipped standalone API's accepted-input and error contract and makes an implicit face-0 policy unavoidable. | Keep an explicit collection entry point and explicit zero-based selection. |
| Clamp invalid indices or default to face 0 | Hides caller bugs and can select a legally or semantically different font. | Reject `index >= face_count` as invalid input. |
| Admit every face eagerly | Makes one unsupported/malformed sibling block supported faces and multiplies attacker-controlled table work. | Validate all directory envelopes, then deeply admit only the selected face. |
| Reject a collection because any sibling profile is unsupported | OpenType collections may legally mix outline formats. | Classify per face; capability-gate only selection. |
| Copy or rebuild a selected face into temporary standalone SFNT bytes | Destroys shared-table benefits, adds file-sized allocation, creates new checksum/offset canonicalization, and weakens mutation identity. | Use a root-relative offset adapter feeding the existing admission transaction. |
| Treat a TTC face directory as a simple subview | Table offsets are collection-root-relative, so slicing at the directory base misaddresses tables. | Carry root view and face-directory base separately. |
| Enforce standalone whole-file `checksumAdjustment` on TTC data | The OpenType specification says this field is not used for collections. | Validate collection table checksums with collection rules; retain standalone rules only for standalone input. |
| Global deduplication/cache for shared tables | Adds lifetime, synchronization, eviction, and budget-ownership policy that the milestone does not need. | Retain root subviews; repeated face opens may create small independent validated indices. |
| DSIG cryptographic verification or trust decisions | Requires PKCS#7/X.509, algorithms, trust stores, certificate time/revocation, and platform policy. Structural presence is not authenticity. | Validate bounded DSIG structure only and report `present-unverified`. |
| Silently ignore malformed declared DSIG | A v2 header makes the DSIG range part of collection structure; ignoring an invalid range weakens fail-closed admission. | Reject malformed tuple/envelope as Data; reject recognized unsupported version/format as Capability. |
| CFF/CFF2 outline decoding | Adds a charstring VM and cubic-outline path independent of the collection adapter. | Inspect/classify, then return Capability on selection. |
| Variable font instances | Changes metrics, outlines, phantom points, and identity based on axis coordinates. | Classify `fvar`/`gvar` or CFF2 variation faces as unsupported for this milestone. |
| WOFF/WOFF2 | Compression/transformation is a separate container problem and WOFF2 requires reconstruction. | Continue requiring uncompressed TTC/OTC bytes. |
| Shaping, GSUB/GPOS, fallback, or family matching | These are string/font-selection policies, not collection addressing. | Return the existing single-font queries; defer to `mb-text`/consumers. |
| Font discovery or ambient file I/O | Breaks target portability and explicit capability ownership. | Caller supplies a bounded `ByteView`; host adapters remain outside the portable package. |
| Hinting or rasterization | Adds execution/device/pixel state and violates the existing unhinted geometry boundary. | Return unchanged `Path2` outlines from the selected `Font`. |
| Collection authoring, extraction, merging, subsetting, or rewriting | Requires glyph closure, table serialization, checksum reconstruction, and license-policy decisions. | Keep v0.33 read-only. |
| Mandatory network/system-font fixtures | Makes qualification non-reproducible and host-dependent. | Vendor compact immutable fixtures with license, provenance, source hashes, and digests. |

## Errors and Publication Semantics

| Stage | Example | Category | Publication Rule |
|---|---|---|---|
| Collection open | Non-`ttcf` bytes supplied to collection API | Capability or InvalidInput per final API boundary | No collection |
| Collection open | Unknown TTC major version | Capability | No collection |
| Collection open | Truncated offset array, zero faces, offset arithmetic overflow, directory envelope out of range, inconsistent DSIG tuple | Data | No collection |
| Collection open | `numFonts > max_faces`, source/work/budget one short | Resource | No collection; atomic budget failure |
| Collection query | Source revision changed | State | Existing collection handle only; no new result |
| Face inspection/open | `index >= face_count` | InvalidInput | Existing collection remains usable |
| Face inspection | Recognized CFF/CFF2/variable face | Success with unsupported classification | Face info only |
| Face open | Recognized CFF/CFF2/variable face | Capability | No font; existing collection remains usable |
| Face open | Required selected table missing/malformed or selected table range invalid | Data | No font; existing collection remains usable if source unchanged |
| Face open | Existing `FontLimits`/budget exhausted | Resource | No font and no partial selected-face state |
| Font query | Root source mutates after face admission | Existing State/revision-drift result | Existing font handle only; no fresh metric/glyph/path |

Do not make directory offsets, selected profile, or index determine a new public equality contract. Internally, a face is identified by the retained root owner, opening revision, and zero-based face index. Selecting the same face twice yields deterministic equivalent font behavior but may produce distinct opaque handles; no public reference equality or cache identity is required.

## Limits and Budget Dimensions

### New collection limits

| Limit | Prevents | Boundary Evidence |
|---|---|---|
| `max_source_bytes` | Oversized retained collection | Exact bytes succeed; one extra fails before header traversal |
| `max_faces` | Huge `numFonts` arrays and count-driven work | `count == max` succeeds; `max + 1` fails before offsets allocation/scan |
| `max_dsig_signatures` | Huge DSIG record arrays | Exact count and one-short resource failure |
| `max_dsig_bytes` | Oversized opaque signature payload | Checked declared length before any scan/copy |
| `max_work` | Repeated directory-envelope/profile checks | Deterministic preflight for known counts; checked cumulative work |

### Existing selected-face limits

Every existing `FontLimits` field remains authoritative for the selected face: table count/bytes, glyphs, name/cmap/kern counts, outline points/contours/components/instructions, post-name bytes, source ceiling, and work. Unselected faces do not consume selected-face limits. Shared tables do not bypass any validation or charge required for the selected face.

Collection opening and selected-face opening are separate explicit operations and therefore separate atomic charges. A caller may use one cumulative `Budget` or distinct budgets, but the implementation must not retain or secretly reuse either after the operation. The exact meaning of the selected-face `max_source_bytes`/byte charge must be documented and frozen during planning; the conservative recommendation is to count the retained root collection bytes because the returned `Font` keeps that root storage alive. Optimizing shared-lifetime accounting would require a new resource-ownership contract and is not part of v0.33.

## Feature Dependencies

```text
existing mb-core ByteView identity/revision + checked arithmetic + Budget + CoreError
  └─→ TTC header parser
        ├─→ version 1.0 header
        └─→ version 2.0 header
              └─→ optional bounded DSIG v1/format-1 envelope

TTC header + max_faces/max_work
  └─→ complete face-directory offset array
        └─→ atomic directory-envelope validation
              └─→ published FontCollection
                    ├─→ zero-based face_count/index validation
                    ├─→ bounded per-face profile inspection
                    └─→ selected root-relative face adapter
                          ├─→ collection-aware table checksums
                          ├─→ shared-table-safe table windows
                          └─→ existing atomic TrueType admission
                                └─→ existing Font API unchanged

root ByteView identity + opening revision
  ├─→ every collection query pre/post guard
  └─→ every derived Font retains existing revision guards

all paths
  └─→ generated/licensed/hostile/four-target qualification
```

### Dependency Notes

- Header/count limits precede every face-offset loop.
- Container-envelope validation precedes collection publication; face-local semantic parsing waits until inspection/selection.
- Per-face profile classification precedes selected admission so unsupported CFF/CFF2/variation profiles fail intentionally rather than through accidental missing-table errors.
- The offset-aware adapter precedes reuse of the existing directory parser. Do not fork a second metrics/cmap/kern/outline implementation.
- Collection checksum mode must be explicit before calling the existing admission logic; the standalone whole-file checksum rule cannot be inferred from a subview.
- Mutation identity is rooted in the original byte owner, not in a face slice or copied buffer.

## Qualification Landscape

| Evidence Class | Minimum Fixture/Case | Frozen Assertions |
|---|---|---|
| Generated TTC v1 positive | Two static `glyf` faces, distinct `cmap`/name facts, at least one shared `glyf`/`loca`/`hmtx` region | Header version, count 2, indices 0/1, shared ranges accepted, both selected fonts expose expected existing facts |
| Generated TTC v2 unsigned | Two faces with all-zero DSIG tuple | Version 2, DSIG absent, face selection unchanged |
| Generated TTC v2 DSIG structural | DSIG v1, format 1, bounded opaque payload, table at EOF | Presence reported but not trusted; malformed tuple/version/format/range/EOF cases classify correctly |
| Mixed-profile collection | Static `glyf` plus CFF, CFF2, and/or variable `glyf` directory profiles | Collection opens; inspection classifies each; static face opens; other selections return Capability |
| Shared versus distinct tables | Some identical ranges shared, identity tables distinct | No global overlap rejection; each face receives its own cmap/metrics and common outlines where intended |
| Face index boundaries | Empty/zero count, count 1, count N, `N-1`, `N`, very large caller index | Exact successes and stable Data/InvalidInput outcomes without wrap/clamp |
| Offset hostility | Truncated offset array, offset into header, out-of-range directory, unaligned table, record-count multiplication overflow, table end overflow | No collection/font publication and stable checked error facts |
| Selected/unselected corruption | Valid container with deep malformed supported face and a valid sibling | Envelope-level corruption blocks collection; deep face-local corruption blocks only selection of that face |
| Mutation matrix | Header, offset entry, selected directory, shared table mutated before/after inspection/admission | Permanent State invalidation of collection and all derived fonts, even after restoration |
| Limit/budget matrix | Source, face count, DSIG count/bytes, collection work, and every existing font limit exact/one-short | Exact requested/limit facts and atomic publication/charge behavior |
| Standalone compatibility | Entire v0.32 standalone suite and frozen public interface baseline | No new accepted input, changed result, changed error, or public signature for existing routes |
| Licensed positive | Deterministic compact TTC derived offline from redistributable static DejaVu inputs already used by the project, with transformation recipe, tool version, source hashes, license, and final digest | Real table complexity, shared-table interoperability, selected public metrics/cmap/kern/outline facts |
| Licensed negative/optional | A provenance-locked OFL collection such as a Noto CJK OTC or TTF-TTC only if repository size permits | Recognized CFF/variable profile rejection; never required for the ordinary fast lane if too large |
| Four-target public workflow | Open collection → inspect faces → select glyf face → metrics → cmap → kern → outline | Identical semantic output and structured failures on `js`, `wasm`, `wasm-gc`, and `native` |

Do not claim fixture legitimacy from a filename or download page alone. Commit the exact license text, upstream URL/revision or release, original and transformed SHA-256 digests, transformation command/tool version, and a note identifying whether bytes are original or derivative. Generated hostile fixtures should carry the repository's own license and a human-readable construction manifest.

## MVP Recommendation

Prioritize:

1. **Frozen standalone compatibility plus bounded TTC v1/v2 container admission**
   - Add the separate collection API, collection limits, zero-based count/index semantics, root revision identity, and atomic directory-envelope validation.
2. **Offset-aware selected static-`glyf` face admission**
   - Reuse the existing `Font` transaction with root-relative table windows, collection checksum mode, legitimate shared tables, and unchanged downstream metrics/cmap/kern/outline behavior.
3. **Per-face capability inspection and mixed-profile isolation**
   - Classify static `glyf`, CFF, CFF2, and variable faces; ensure unsupported siblings do not block a supported selection.
4. **TTC v2 DSIG structural handling**
   - Support absent and bounded version-1/format-1 envelopes, distinguish malformed from unsupported, and explicitly report unverified presence.
5. **Qualification**
   - Freeze generated v1/v2/shared/mixed/hostile cases, one compact licensed positive derivative, mutation and exact/one-short matrices, standalone regression, and independent four-target public evidence.

Defer:

- Broad localized face names: collection addressing does not require a public `name` table API.
- DSIG cryptographic verification: it is a separate security/trust-store capability.
- Whole-collection eager face admission or shared-table caching: neither is necessary for one selected face.
- CFF/CFF2, variable-font instances, WOFF/WOFF2, shaping, discovery, hinting, rasterization, or collection authoring: each widens the product boundary beyond an adapter.

## Requirement Candidates

| ID | Requirement | Acceptance Evidence |
|---|---|---|
| **TTC-01** | Library authors can atomically inspect bounded TTC/OTC v1/v2 bytes, obtain an exact face count, and address faces by zero-based in-range index without copying the collection. | Generated v1/v2, count/index boundary, overflow/truncation, limit/budget, DSIG, and mutation cases produce frozen outcomes on four targets. |
| **TTC-02** | Selecting one supported static `glyf` face returns the existing `Font` behavior through root-relative table windows, including legitimate cross-face table sharing and collection checksum semantics. | Shared-table generated/licensed fixtures prove equal metrics, mapping, kerning, and outlines; selected admission performs no file-sized copy; standalone baselines remain unchanged. |
| **TTC-03** | Mixed collections remain inspectable and capability failures are isolated to the selected unsupported CFF/CFF2/variable face. | Mixed fixture exposes per-face classifications; supported face opens; unsupported selections return Capability; face-local malformed selection publishes no font while unchanged collection remains usable. |
| **TTC-04** | Collection/face operations preserve structured Data, Capability, InvalidInput, Resource, and State distinctions with atomic publication and exact budget/limit evidence. | Closed hostile matrix freezes stage, category, code, context, requested/limit, and publication outcome, including permanent root revision drift. |
| **TTC-05** | Maintainers can reproduce standalone and collection behavior from generated and licensed immutable fixtures on all four supported targets without ambient I/O or network state. | Manifested fixture provenance/license/digests, complete public workflow, standalone regression, and identical `js`/`wasm`/`wasm-gc`/`native` evidence. |

## Sources

### Project authority — HIGH

- [Project definition and active v0.33 requirements](../PROJECT.md)
- [RFC 0004: `mb-font` Charter](../../docs/rfcs/0004-mb-font.md)
- [`mb-font` shipped candidate contract](../../modules/mb-font/README.mbt.md)
- [`Font::open`, retained-source identity, and query semantics](../../modules/mb-font/font/font.mbt)
- [Existing semantic limits](../../modules/mb-font/font/limits.mbt)
- [Existing qualification case schema](../../fixtures/font/qualification-cases.json)

### Primary standards and established library behavior — MEDIUM by research seam

- [OpenType 1.9.1: The OpenType Font File](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — collection structure, root-relative offsets, table sharing, mixed outline profiles, header versions 1.0/2.0, DSIG tuple, required tables, and collection checksum rules.
- [OpenType: Comparison of `glyf`, `CFF `, and CFF2](https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison) — mutually distinct outline models and variation support.
- [OpenType: DSIG Digital Signature Table](https://learn.microsoft.com/en-us/typography/opentype/otspec181/dsig) — DSIG table version 1, format-1 expectation for TTC, whole-collection scope, and EOF placement. The DSIG chapter is from OpenType 1.8.1 but remains the current linked DSIG definition from the 1.9.1 font-file chapter.
- [FreeType 2.14.3 Face Creation](https://freetype.org/freetype2/docs/reference/ft2-face_creation.html) — `num_faces`, zero-based face indices, and count-probe behavior.
- [`ttf-parser` 0.25.1 `RawFace`](https://docs.rs/ttf-parser/latest/ttf_parser/struct.RawFace.html) and [`FaceParsingError`](https://docs.rs/ttf-parser/latest/ttf_parser/enum.FaceParsingError.html) — explicit collection index, face-count helper, and distinct out-of-range/malformed/unknown-magic errors.
- [fontTools `TTCollection`](https://fonttools.readthedocs.io/en/latest/ttLib/ttCollection.html) — established collection object exposing member fonts and optional table sharing.
- [Noto CJK repository](https://github.com/notofonts/noto-cjk) and [OFL 1.1 license](https://github.com/notofonts/noto-cjk/blob/main/Sans/LICENSE) — authoritative examples of licensed OTC and TTF-TTC distributions; suitable primarily as optional negative-profile evidence for this static-`glyf` milestone.

---
*Feature research for v0.33 TrueType Collection Adapters.*
