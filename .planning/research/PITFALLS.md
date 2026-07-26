# Pitfalls Research: v0.32 TrueType Font Foundation

**Domain:** Bounded pure-MoonBit SFNT/TrueType parsing and reusable glyph outlines  
**Researched:** 2026-07-26  
**Confidence:** HIGH for project architecture and integration risks; MEDIUM for exact format edge semantics inherited from the OpenType 1.9.1 profile documented in the companion research.

## Roadmap Phase Names

1. **Module and SFNT Admission** — package boundary, limits, immutable source, checked cursor, directory, ranges, checksums.
2. **Core Tables, Metrics, and Cmap** — `head`/`maxp`/`hhea`/`hmtx`/`loca`, Unicode mapping, optional `kern`.
3. **Simple Glyph Outlines** — simple `glyf` decoding and `Path2` normalization.
4. **Composite Glyph Outlines** — components, cycles, transforms, point attachment, metric interactions.
5. **Hostile and Portable Qualification** — generated mutations, licensed real fonts, four-target public workflow.

The mapping below assigns each risk to the earliest phase that must prevent it. Later qualification verifies the prevention but must not be the first place it exists.

## Critical Pitfalls

### 1. Unchecked offset and count arithmetic

**What goes wrong:** Attacker-controlled expressions such as `12 + numTables * 16`, `offset + length`, `numGlyphs + 1`, format-4 array positions, short-`loca` offsets multiplied by two, point counts, and pair-record lengths wrap or narrow before validation. A valid-looking backend `Int` then indexes the wrong bytes or sizes the wrong allocation.

**Warning signs:** Direct `+` or `*` involving file fields; conversion to `Int` before containment is proven; a cursor whose read methods accept absolute offsets outside its table view; tests cover truncation but not arithmetic maxima.

**Prevention and tests:** Keep wire values as `UInt64` or widened signed values until checked. Use `checked_add`, `checked_mul`, `CheckedRange::from_start_length`, nested `subrange`, and `checked_narrow_int` only after logical bounds pass. Give every table parser a checked subview, never the root plus a raw offset. Generate boundary vectors for every derived expression: exact fit, one-byte short, maximum count, multiplication overflow, addition overflow, and backend narrowing failure. Assert one stable error with table and source-offset context and no published `Font`.

**Affected seams:** Big-endian cursor, SFNT directory, every table validator, allocation preflight, `CoreError`.

**Phase to address:** **Phase 1 — Module and SFNT Admission.**

---

### 2. Treating table records as a trustworthy map

**What goes wrong:** Duplicate tags, unsorted records, a table overlapping the directory or another table, misaligned top-level offsets, out-of-file ranges, or inconsistent checksums are accepted. Different lookup orders can then select different bytes, and two logical tables can alias hostile storage.

**Warning signs:** “First table wins” or hash-map insertion silently overwrites duplicates; overlap is not checked after sorting ranges; stored search fields drive traversal; checksums are deferred until a query happens.

**Prevention and tests:** For the standalone v0.32 profile, validate directory size first, derive search facts from `numTables`, require ascending unique defined tags, four-byte-aligned top-level starts, checked containment, no overlap with the directory, and no overlap among distinct non-empty table ranges. Verify table checksums, including zero padding and the `head.checksumAdjustment` rule, before publication. Allow unknown well-formed optional tables; reject ambiguous required-table records. Mutate one otherwise valid micro-font for duplicate, unsorted, touching, partially overlapping, fully aliased, directory-overlapping, past-end, and checksum-failure cases.

**Affected seams:** SFNT admission, table registry, retained subviews, checksum work budget.

**Phase to address:** **Phase 1 — Module and SFNT Admission.**

---

### 3. Cross-table facts disagree while individual tables look valid

**What goes wrong:** `maxp.numGlyphs`, `head.indexToLocFormat`, `loca`, `hhea.numberOfHMetrics`, `hmtx`, `cmap`, and `glyf` are parsed independently. This permits too few `loca` entries, glyph offsets past `glyf`, impossible metric counts, or mappings/components that reference nonexistent glyphs.

**Warning signs:** Validators can be called without a shared admitted-font context; glyph ID range checks occur only in the public facade; table-length checks use minimum size rather than the exact profile envelope.

**Prevention and tests:** Publish `Font` only after one cross-table gate proves: supported versions; `1 <= numberOfHMetrics <= numGlyphs`; the exact `hmtx` envelope; exactly `numGlyphs + 1` `loca` entries; monotone offsets with the final entry within `glyf`; all selected cmap, component, and kern glyph IDs below `numGlyphs`. Treat `maxp` maxima as consistency claims, never permission to allocate. Test every mismatch in both directions and ensure later queries cannot observe a partially valid object.

**Affected seams:** Core-table index, metrics, cmap, glyph extraction, kern.

**Phase to address:** **Phase 2 — Core Tables, Metrics, and Cmap.**

---

### 4. Incorrect `loca` semantics corrupt glyph boundaries

**What goes wrong:** Short offsets are not doubled, offsets descend, subtraction underflows, the final entry exceeds `glyf`, or equal adjacent offsets are treated as malformed. The parser can read into the next glyph or reject valid empty glyphs such as spaces.

**Warning signs:** Glyph length is computed with unchecked subtraction; `loca` is decoded lazily on every query; empty glyphs require a ten-byte `glyf` header; short and long formats do not share the same normalized invariant.

**Prevention and tests:** Eagerly normalize both formats to one validated offset array. Checked-multiply short entries by two; require monotonicity and containment before subtraction. Interpret equal adjacent entries as a successful empty outline with normal metrics. Test first, middle, and last empty glyphs; short/long equivalence; descending pairs; odd or truncated tables; and an offset exactly at versus one byte beyond `glyf.length`.

**Affected seams:** `head`, `maxp`, `loca`, glyph-window construction, metrics/outline separation.

**Phase to address:** **Phase 2 — Core Tables, Metrics, and Cmap.**

---

### 5. Cmap selection or lookup is platform-dependent

**What goes wrong:** The implementation selects the first host-recognized record, unions conflicting subtables, ignores supplementary planes, mishandles format-4 `idRangeOffset`, or returns an out-of-range glyph ID. Valid misses, invalid Unicode scalars, malformed mappings, and unsupported cmap profiles become indistinguishable.

**Warning signs:** Directory order affects results; format 4 always beats format 12; surrogate inputs return glyph zero; format-4 glyph-array addressing is relative to the table start rather than the specific `idRangeOffset` word; format-12 groups are scanned without ordering validation.

**Prevention and tests:** Freeze a project selection order with usable format 12 preferred over format 4. Validate full subtable length before indexing, format-4 segment ordering/sentinel and every relative glyph-array address, and format-12 sorted non-overlapping groups plus checked range arithmetic. Apply `idDelta` under the format-specific zero-glyph rule, then require the result below `numGlyphs`. Return glyph zero only for a valid scalar miss; reject surrogate/out-of-range queries. Test competing records with conflicting mappings, both format-4 lookup paths, supplementary scalars, unsorted/overlapping groups, malformed offsets, glyph zero, and out-of-range results on all targets.

**Affected seams:** Unicode API, cmap validator/index, `GlyphId`, text consumers.

**Phase to address:** **Phase 2 — Core Tables, Metrics, and Cmap.**

---

### 6. Horizontal metric count semantics are flattened incorrectly

**What goes wrong:** The parser assumes one four-byte `hmtx` record per glyph. When `numberOfHMetrics < numGlyphs`, it either reads past the long metrics or gives tail glyphs the wrong width/bearing. Derived right-side bearings overflow or use outline bounds from the wrong glyph.

**Warning signs:** `hmtx.length == numGlyphs * 4` is required; tail glyphs reuse both advance and bearing; metric arithmetic happens in narrow signed integers; empty outlines cannot return metrics.

**Prevention and tests:** Decode `numberOfHMetrics` `(advance, lsb)` records, then reuse only the final advance while consuming one signed lsb per remaining glyph. Validate the exact required byte count with checked arithmetic. Compute derived bearings in a widened checked signed domain using that glyph's bounds. Preserve named `hhea` and `OS/2` metric triplets instead of inventing one “best” line height. Test minimum metric count, full metric count, signed bearings, empty glyph metrics, and derived overflow.

**Affected seams:** `hhea`, `hmtx`, `maxp`, `glyf` bounds, public metrics API.

**Phase to address:** **Phase 2 — Core Tables, Metrics, and Cmap.**

---

### 7. Packed simple-glyph data expands beyond its declared shape

**What goes wrong:** A repeat byte is interpreted as the total run rather than additional copies, repeat expansion crosses the point count, coordinate byte counts do not match flags, deltas use the wrong sign/zero rule, or accumulators reset at contour boundaries. The resulting path may be plausible but wrong, or compact input may cause oversized work/allocation.

**Warning signs:** Flags are appended until input ends instead of until the exact point count; repeat, x, and y streams are decoded in one intertwined loop; coordinate additions use unchecked `Int`; leftover or missing bytes are tolerated as repair.

**Prevention and tests:** Validate increasing contour endpoints and derive the exact point count first. Bounds-check and skip instruction bytes. Expand flags to exactly that count, treating the repeat operand as additional entries and charging work per logical flag. Separately derive and bounds-check x/y byte consumption, then checked-accumulate signed deltas across the whole glyph. Reject overrun, underrun, and contradictions before allocating or publishing points. Cover every flag combination, repeat 0/maximum/exact/one-too-many, positive and negative byte/word deltas, multiple contours, truncated instruction/flag/x/y streams, and coordinate overflow.

**Affected seams:** Simple `glyf` decoder, work budget, private point model, error context.

**Phase to address:** **Phase 3 — Simple Glyph Outlines.**

---

### 8. Quadratic contour normalization loses TrueType geometry

**What goes wrong:** Consecutive off-curve points do not receive an implied midpoint; an off-curve first or last point uses the wrong synthetic start; single-point and degenerate contours panic; contour order, winding, or closure changes while lowering directly to `Path2`.

**Warning signs:** A decoder emits commands as it reads flags; point numbering is discarded before the full contour exists; tests check only bounds or command count rather than exact controls.

**Prevention and tests:** Decode all checked numbered points into a private contour model first. Apply one documented normalization algorithm for on/on lines, on/off/on quadratics, consecutive off-curve implied midpoints, first/last wraparound, and explicit close while preserving contour order and winding. Build the public path transactionally. Freeze exact command sequences and selected coordinates for all start/end combinations, multiple contours, degenerate valid cases, and malformed endpoint arrays.

**Affected seams:** Private glyph model, `Path2` conversion, downstream canvas/PDF/SVG consumers.

**Phase to address:** **Phase 3 — Simple Glyph Outlines.**

---

### 9. Composite traversal trusts depth declarations or misses cycles

**What goes wrong:** Self-reference, indirect cycles, repeated fan-out, or a false `maxComponentDepth` causes recursion overflow, exponential decoding, or unbounded accumulated points. A one-level feature restriction alone does not make a recursive parser safe.

**Warning signs:** The only guard is `maxp.maxComponentDepth`; a global “seen” set rejects harmless repeated components or, conversely, no active-stack cycle check exists; components are decoded before depth/work admission; repeated children are expanded without cumulative limits.

**Prevention and tests:** Enforce the v0.32 depth capability with `Budget::with_depth`, but also keep an active glyph-ID stack to classify direct/indirect cycles as malformed. Bound top-level components, total traversed components, accumulated points/contours/commands, and work using checked addition. A bounded request-local memo may avoid duplicate decoding, but its memory must be charged and it must not become a persistent hidden cache. Test self-cycle, two/three-node cycles, permitted repeated simple child, fan-out at limit and limit+1, false `maxp` claims, and unsupported nested composites.

**Affected seams:** Composite resolver, `loca` windows, depth/work budget, request-local scratch.

**Phase to address:** **Phase 4 — Composite Glyph Outlines.**

---

### 10. Composite flags, transforms, and point attachment are applied in the wrong domain

**What goes wrong:** Byte/word arguments use the wrong signedness, mutually exclusive transform flags are combined, F2DOT14 is rounded through `Double` too early, translation occurs before transformation, scaled/unscaled offset flags are ignored, or point attachment is attempted after child points have become path commands. Valid accents move, rotate, or scale incorrectly; hostile values overflow.

**Warning signs:** Composite decoding has only an `(x,y)` translation path; internal state is `Path2`; raw F2DOT14 values are immediately divided into floating point; both scaled-offset flags are accepted; the first point-attached component has no parent point.

**Prevention and tests:** Retain numbered points/contours until all components are resolved. Decode argument width and signedness from flags; require scale/x-y-scale/2×2 flags to be mutually exclusive; reject contradictory scaled/unscaled offset flags and freeze the specified default. Compose F2DOT14 transforms with exact integer/fixed-point intermediates and widened checked multiply/add, then perform XY placement or validated parent/child point alignment in the specified order. Check every referenced point and transformed coordinate before append. Test byte/word XY arguments, later-component point attachment, every transform form, negative/fractional coefficients, scaled/unscaled/default offsets, contradictory flags, invalid point IDs, and exact overflow boundaries.

**Affected seams:** Composite parser, private point model, signed checked arithmetic, `Path2` conversion.

**Phase to address:** **Phase 4 — Composite Glyph Outlines.**

---

### 11. Phantom points and composite metrics are silently approximated

**What goes wrong:** Point-number attachment ignores the four phantom points, or `USE_MY_METRICS` is ignored even though it affects unhinted composite metrics. Alternatively, implementation invents vertical phantom-point values despite vertical metrics being outside v0.32, producing undocumented compatibility behavior.

**Warning signs:** Point validation stops at the last outline point; composite metrics always come from the parent's raw `hmtx`; multiple `USE_MY_METRICS` components are accepted without policy; no test distinguishes outline points from phantom references.

**Prevention and tests:** Resolve the unhinted phantom-point policy before composite implementation. Derive supported horizontal phantom points from the admitted bounds and `hmtx` metrics with checked arithmetic, implement the specified `USE_MY_METRICS` behavior, and explicitly reject any phantom/vertical-metric case the milestone cannot represent rather than approximate it. Define deterministic handling of contradictory/multiple metric flags. Test parent and child phantom attachment, composite versus component metrics, empty children, metric overflow, and unsupported vertical references.

**Affected seams:** Metrics, composite point numbering, feature boundary, future `mb-text`.

**Phase to address:** **Phase 2 contract decision; implementation in Phase 4.**

---

### 12. Budgets measure input bytes but not expansion and repeated work

**What goes wrong:** A small font triggers large flag expansion, many cmap groups, checksum rescans, repeated composite decoding, path-command growth, or large temporary arrays. Parsing is memory-safe but still vulnerable to denial of service.

**Warning signs:** Only `max_input_bytes` exists; arrays are allocated before `Budget::charge`; `maxp` values become allocation sizes; every glyph query rescans directory/checksums/cmap; failure leaves a half-built result or query-order-dependent cache.

**Prevention and tests:** Add semantic `FontLimits` for tables, glyphs, cmap records/segments/groups, instruction bytes, points, contours, components, depth, kern pairs, and output commands. Use shared `Budget` for bytes, allocations, allocation size, work, and depth. Preflight exact known costs atomically; incrementally checked-charge data-dependent traversal. Charge logical expansion, not merely bytes consumed. Validate/checksum/index once at open; decode glyphs on demand under a query budget. Publish no partial font/path. For every dimension test `limit-1`, exact limit, and `limit+1`, plus high fan-out and repeated-query cases.

**Affected seams:** Public limits, admission, every parser loop, allocation, caching, atomic result publication.

**Phase to address:** **Phase 1 establishes the contract; every phase enforces its dimensions.**

---

### 13. Retained bytes mutate after admission

**What goes wrong:** `Font` stores zero-copy table views, but the backing `OwnedBytes` is changed through a later mutable lease. Validated ranges and indexes then refer to different content, creating time-of-check/time-of-use behavior.

**Warning signs:** `Font` retains `ByteView` but not its opening mutation revision; queries trust cached offsets without checking the source; mutation tests exist for images but not fonts.

**Prevention and tests:** Retain the root `ByteView` and its admission `mutation_revision`. Check the current revision before every public operation that reads source bytes; return a stable state error on change and never silently revalidate. Keep owned compact indexes independent of mutable source state. Test mutation in required, optional, glyph, and unrelated byte ranges after open, including mutation back to the original value; all must reject consistently.

**Affected seams:** `ByteView` ownership, `Font` lifetime, cached structural indexes, public queries.

**Phase to address:** **Phase 1 design; Phase 5 public-workflow verification.**

---

### 14. Legacy kern parsing confuses absence, unsupported data, and malformed data

**What goes wrong:** Binary search runs over unsorted or truncated pairs, search helper fields are trusted, glyph IDs exceed `numGlyphs`, signed values become unsigned, or a present unsupported subtable is reported as adjustment zero.

**Warning signs:** Pair order is never validated; the query returns only `Int` with no capability error; unsupported coverage/version/format is skipped until the table appears absent; pair lookup accepts Unicode code points rather than glyph IDs.

**Prevention and tests:** Validate the table/subtable envelope, supported version-0 horizontal format-0 coverage, exact `nPairs * 6` range, strictly sorted pair keys, in-range glyph IDs, and signed FWORD values. Derive search behavior independently. Return zero for absent table or supported-table miss; return structured unsupported/malformed results for present out-of-profile or invalid data. Test positive/negative hit, miss, absence, unsorted/duplicate/truncated pairs, invalid glyph IDs, unsupported coverage/format, and boundary pair keys.

**Affected seams:** Optional-table admission, `GlyphId`, metrics/layout consumer boundary.

**Phase to address:** **Phase 2 — Core Tables, Metrics, and Cmap.**

---

### 15. Floating-point conversion creates cross-target outline drift

**What goes wrong:** JS, Wasm, Wasm-GC, and native take different paths through signed narrowing, F2DOT14 conversion, fused arithmetic, negative zero, or rounding. Path coordinates or error boundaries differ even though the wire font is integral/fixed point.

**Warning signs:** All coordinates become `Double` while parsing; platform math or native FFI participates; tests compare only rendered appearance; semantic digests serialize target-specific decimal strings.

**Prevention and tests:** Keep offsets, counts, design coordinates, deltas, metrics, and composite transform intermediates exact and widened for as long as possible. Define the transform evaluation order and rounding/conversion rule once; convert to finite `Double` only at the `Path2` seam after checking a target-neutral geometry envelope. Canonical evidence should hash command kinds and exact normalized numeric facts, not locale-formatted prose. Run the same boundary fixtures independently on all four targets and require identical mappings, metrics, command sequences, selected coordinate bit patterns or canonical fixed-point facts, and structured errors.

**Affected seams:** Signed arithmetic helpers, composite transforms, `Path2`, qualification evidence.

**Phase to address:** **Phase 3 establishes conversion; Phase 4 extends it; Phase 5 proves it.**

---

### 16. Real-font fixtures are non-reproducible or legally unusable

**What goes wrong:** Tests read installed system fonts, download a moving URL, vendor a font without its license, record an archive hash but not the extracted file, or rely on an external tool as the sole oracle. CI differs by machine and release artifacts may not be redistributable.

**Warning signs:** Fixture path points outside the repository; no manifest entry or SHA-256; “free font” is the only license statement; version/table inventory is unknown; expected values are regenerated by production parser code.

**Prevention and tests:** Combine project-generated micro-fonts with a small number of explicitly redistributable real fonts. For every binary record exact source URL/version, retrieval date, extracted-file digest, upstream/archive digest when relevant, license identifier and full notice, redistribution status, table inventory, and intended coverage in `fixtures/manifest.json`. Generate portable byte literals deterministically and verify their digest. Keep external inspectors pinned and curation-only; commit semantic oracle facts. Add a qualification check that every font fixture has a matching manifest/license record and that no test accesses host fonts or network.

**Affected seams:** Fixture manifest, generated tests, release/legal review, four-target CI.

**Phase to address:** **Phase 5 — Hostile and Portable Qualification** (fixture policy should be chosen in Phase 1).

## Technical Debt Patterns

| Shortcut | Long-term cost | Acceptable? |
|---|---|---|
| Give table parsers root bytes plus raw offsets | Recreates unchecked arithmetic at every table | Never |
| Decode every glyph during `Font::open` | Font-sized latency/allocation and weak caller control | Never for v0.32 |
| Persistently cache every requested outline | Memory depends on query history and budgets become nondeterministic | Defer to explicit caller-owned cache |
| Lower composite children directly to `Path2` | Loses point numbering and prevents correct attachment | Never |
| Use `maxp` maxima as resource permission | Hostile font chooses its own budget | Never |
| Silently clamp or repair malformed structures | Hides corruption and creates target/order differences | Never |
| Treat unsupported present cmap/kern/composite semantics as absence | False capability claims | Never |
| Test only large real fonts | Poor fault isolation and hard-to-audit licenses | Never; pair with generated micro-fonts |

## “Looks Done But Isn’t” Checklist

- [ ] Every derived offset/count uses checked arithmetic before narrowing.
- [ ] Directory records are unique, ordered, aligned, contained, non-overlapping, and checksum-valid.
- [ ] `head`/`maxp`/`hhea`/`hmtx`/`loca`/`glyf` cardinalities are cross-validated.
- [ ] Format 4 and 12 selection is frozen and supplementary-plane lookup is tested.
- [ ] Simple flags expand to exactly the point count; x/y streams and cumulative deltas are exact.
- [ ] All quadratic start/end and consecutive off-curve cases produce exact commands.
- [ ] Composite cycles, depth, fan-out, transforms, point attachment, phantom points, and metrics are covered.
- [ ] `kern` distinguishes absent/miss from unsupported/malformed.
- [ ] Every expansion dimension has exact and limit+1 budget tests with no partial result.
- [ ] Source mutation after open is rejected by every query.
- [ ] The same semantic facts and errors pass on `js`, `wasm`, `wasm-gc`, and `native`.
- [ ] Every real font has immutable bytes, digest, provenance, license notice, and declared test purpose.

## Pitfall-to-Phase Mapping

| Pitfall | Earliest prevention phase | Required verification |
|---|---|---|
| Offset/count overflow and premature narrowing | Phase 1 | Generated arithmetic-boundary and every-truncation tests |
| Duplicate/overlapping/out-of-range tables | Phase 1 | Mutated directory matrix; no `Font` publication |
| Cross-table inconsistency | Phase 2 | Pairwise count/range mismatch corpus |
| Incorrect `loca` normalization | Phase 2 | Short/long, empty, descending, final-bound vectors |
| Nondeterministic/malformed cmap | Phase 2 | Competing 4/12 records and hostile segment/group vectors |
| Wrong `hmtx` tail semantics | Phase 2 | Minimum/full count and signed-bearing vectors |
| Simple flag/repeat/delta expansion | Phase 3 | Exact logical flags, coordinates, and truncation matrix |
| Wrong quadratic contour normalization | Phase 3 | Exact command/control-point fixtures |
| Composite cycles/depth/fan-out | Phase 4 | Active-stack cycle and cumulative-limit tests |
| Composite transform/attachment errors | Phase 4 | All argument/transform/offset/point modes |
| Phantom points and `USE_MY_METRICS` | Phase 2 contract, Phase 4 code | Phantom attachment and component-metric fixtures |
| Incomplete denial-of-service budgets | Phase 1 contract, all phases | One-less/exact/one-more per semantic dimension |
| Source mutation after admission | Phase 1 | Post-open mutation black-box tests |
| Malformed/unsupported kern ambiguity | Phase 2 | Hit/miss/absent/unsupported/malformed matrix |
| Cross-target numeric drift | Phases 3–5 | Identical canonical public facts on four targets |
| Fixture provenance/license gaps | Phase 5 | Manifest/digest/license validation lane |

## Sources

- `.planning/research/STACK.md` — exact v0.32 technology profile, checked-arithmetic/budget strategy, normative table profile, and fixture policy.
- `.planning/research/FEATURES.md` — public behavior, error/limit expectations, anti-features, feature dependencies, and qualification requirements.
- `.planning/research/ARCHITECTURE.md` — validated-index architecture, component boundaries, ownership/mutation design, decode flows, and build order.
- `docs/rfcs/0004-mb-font.md` — authoritative module boundary, portable targets, unhinted determinism, hostile-input posture, and font-versus-text/canvas ownership.

---
*Pitfalls research for: MoonBit Native Foundation v0.32 TrueType Font Foundation*  
*Researched: 2026-07-26*
