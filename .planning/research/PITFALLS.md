# Domain Pitfalls

**Project:** MoonBit Native Foundation v0.35 Text Shaping Foundation
**Domain:** Bounded, deterministic single-font horizontal OpenType shaping
**Researched:** 2026-07-30
**Overall confidence:** MEDIUM

The confidence seam classifies verified web research as MEDIUM. The normative behavior below was cross-checked against official OpenType 1.9.1, Unicode 17/UAX documents, HarfBuzz documentation, current MoonBit 0.10.4 documentation, and the retained `mb-font` implementation. Repository-specific prevention guidance is additionally grounded in the existing checked-read, revision-guard, caller-budget, and atomic-commit patterns.

## Executive Risk Position

The highest-risk failure is not rejecting an exotic font. It is returning `Ok(ShapedRun)` for a selected layout path that was parsed, ordered, filtered, or executed incorrectly. Such a result looks plausible, survives ordinary Latin smoke tests, and becomes an accidental compatibility contract. v0.35 should therefore be strict about the selected path, explicit about unsupported capability, and modest about what its text-shaping profile claims.

The second systemic risk is letting four concerns drift apart: parser limits, shaping work limits, caller budget authority, and publication atomicity. OpenType layout tables contain nested attacker-controlled counts and offsets, while small tables can drive repeated scans over large runs. Exact structural bounds alone do not bound execution. v0.35 needs one transaction that stages layout facts and output privately, charges every attacker-controlled dimension, performs a final font revision guard, commits once, and publishes once.

The roadmap should separate contract freezing, layout admission, GSUB, GPOS/kerning, transactional integration, and qualification. In particular, the exact RTL run order and signed-advance convention must be fixed before implementation. If that decision is deferred until oracle integration, the implementation and expected data will co-evolve and conceal errors.

## Risk Ranking

| Rank | Pitfall | Likelihood | Impact | Confidence | Primary owner |
|---:|---|---|---|---|---|
| 1 | Relative-offset and table-window confusion | High | Critical rewrite/security | MEDIUM | Phase 109 |
| 2 | Wrong feature/lookup/subtable order | High | Silent semantic corruption | MEDIUM | Phases 108–111 |
| 3 | Returning success after skipping a selected unsupported path | Medium | False capability contract | MEDIUM | Phases 108–111 |
| 4 | Cluster, direction, and glyph-order conflation | High | Public API incompatibility | MEDIUM | Phases 108, 110, 113 |
| 5 | Unbounded shaping work hidden behind bounded tables | High | Resource exhaustion | MEDIUM | Phases 109–112 |
| 6 | Mutation or budget commit before atomic publication | Medium | State/authority corruption | MEDIUM | Phase 112 |
| 7 | PairPos/class-matrix misinterpretation | High | Incorrect positioning/OOB | MEDIUM | Phase 111 |
| 8 | GPOS plus legacy `kern` double application | Medium | Common-font spacing errors | MEDIUM | Phase 111 |
| 9 | Oracle semantics silently defining product semantics | Medium | Self-confirming incompatibility | MEDIUM | Phase 113 |
| 10 | Four targets agree on tests but not on canonical behavior | Medium | Broken portability claim | MEDIUM | Phases 112–113 |

## Critical Pitfalls

### Pitfall 1: Treating every OpenType offset as relative to the same base

**What goes wrong:** Script, language-system, feature, lookup, subtable, Coverage, ClassDef, PairSet, ligature, ValueRecord device, and extension offsets are resolved against the wrong parent. Valid fonts are rejected, malformed fonts read an adjacent valid-looking region, or target-dependent narrowing permits an out-of-window access.

**Why it happens:** OpenType layout uses several nested offset bases. Most are 16-bit, extension offsets are 32-bit, and similarly named offsets are relative to different structures. Reusing a generic `base + offset` helper without encoding the base/window contract makes review difficult.

**Consequences:** Incorrect shaping, out-of-range access attempts, budget undercounting, inconsistent error context, and a parser rewrite after fixtures expose the mistake.

**Prevention:**

- Represent each retained table as a bounded view/window, never as an unqualified absolute offset.
- Name helpers by base (`from_layout`, `from_script_list`, `from_script`, `from_feature_list`, `from_lookup_list`, `from_lookup`, `from_subtable`).
- Keep offsets/counts/lengths as `UInt64`; use checked add/multiply before validating the complete range; narrow only after a semantic ceiling proves the value indexable.
- Validate the entire fixed header and offset array before following any member.
- For GSUB 7 and GPOS 9, validate the 32-bit offset relative to the extension subtable and reject extension-to-extension dispatch.
- Bind every structured error to the exact table and relation that failed.

**Detection / warning signs:**

- Helpers accept two bare integers named only `base` and `offset`.
- Tests cover truncation but not an in-range offset that points into the wrong sibling structure.
- Generated valid fixtures use only zero or immediately-following offsets.
- Parser code narrows to `Int` before checked range validation.

**Required tests:** For every admitted offset field: exact end, one-byte-short, additive overflow, offset to header, offset to sibling, overlapping targets, zero where forbidden, and valid non-contiguous layout. Include 32-bit extension offsets above `0xFFFF`.

### Pitfall 2: Applying features in caller order or feature-record order

**What goes wrong:** The shaper applies `rlig`, `liga`, and `kern` lookups in option order, LangSys feature-index order, or FeatureList order rather than LookupList order. Earlier substitutions then fail to feed later lookups, or a later lookup runs too early.

**Why it happens:** Feature selection and lookup execution are separate operations in OpenType. LangSys feature indices and Feature table lookup indices are not the final execution schedule.

**Consequences:** Plausible but wrong glyphs/positions; changes in caller option order change output; generated fixtures pass if their tables happen to be naturally ordered.

**Prevention:**

- Resolve exactly one Script table and one language system for each GSUB/GPOS table.
- Build the selected feature set, include the LangSys required feature, resolve all referenced lookup indices, reject out-of-range indices, then union and deduplicate.
- Execute the resulting lookups in ascending LookupList index order.
- Within one lookup, scan the glyph sequence according to the frozen direction contract; at a glyph position, try subtables in stored order and stop after the first match.
- Freeze whether duplicate lookup references execute once; the recommended v0.35 rule is one execution per LookupList index after union/deduplication.

**Detection / warning signs:**

- Reordering caller feature toggles changes output.
- A `Feature` object directly owns executable callbacks.
- Tests do not interleave lookup indices from `rlig`, `liga`, and `kern`.
- Multiple matching subtables all apply at one glyph position.

**Required tests:** Permute caller feature order and LangSys feature-index order while keeping LookupList fixed; output must remain identical. Add two features referencing the same lookup and two subtables matching the same starting glyph.

### Pitfall 3: Silently skipping a selected unsupported lookup, flag, or ValueRecord

**What goes wrong:** A selected feature references contextual GSUB, mark/cursive GPOS, device/variation positioning, a forbidden lookup flag, or an unsupported extension target; the engine skips it and returns a run as if the feature were honored.

**Why it happens:** “Best effort” is attractive for compatibility, but a partial layout engine cannot know whether the skipped operation was optional to the font’s intended result.

**Consequences:** False support claims, especially for complex scripts; consumers cannot distinguish “feature absent” from “feature present but not implemented.”

**Prevention:**

- Separate absence, not-selected, selected-and-supported, selected-but-unsupported, malformed, resource-exhausted, and mutated outcomes.
- Do not deep-execute unselected capability paths, but validate the structural envelope needed to resolve lists and indices safely.
- If any selected required/default/caller feature reaches an unsupported lookup type, flag, format, device/variation field, or extension target, fail atomically with `CapabilityUnavailable`.
- Do not let a later supported subtable hide an earlier selected unsupported subtable.
- Document the supported profile as GSUB 1/4/7-to-1-or-4 and GPOS 2/9-to-2 plus the explicit GDEF flag subset; never advertise “OpenType shaping” without that qualifier.

**Detection / warning signs:**

- Code has `default => continue` in selected lookup dispatch.
- Licensed-font qualification logs “unsupported lookup skipped” while still recording success.
- Required features can be disabled through the same path as optional features.

**Required tests:** A selected unsupported lookup must fail; the same lookup under an unselected optional feature must not run; an unsupported required feature must fail; failure must publish no run and consume no budget.

### Pitfall 4: Mixing source clusters, grapheme clusters, and visual glyph order

**What goes wrong:** `source_cluster` is documented or implemented as a grapheme boundary, byte offset, glyph-array index, or visual-order position. RTL reversal and ligature formation then produce non-monotone or unstable provenance.

**Why it happens:** “Cluster” has several meanings. HarfBuzz cluster behavior is configurable, UAX #29 grapheme segmentation is a separate algorithm, and RTL output order is not the input scalar order.

**Consequences:** Downstream selection/caret code relies on a promise v0.35 cannot keep; changing the RTL convention later becomes a breaking API change.

**Prevention:**

- Define `source_cluster` only as the zero-based index of a scalar in the exact caller input array.
- Single substitution preserves the cluster.
- Ligature substitution publishes the minimum source scalar index among consumed components.
- State explicitly that the value is not a UTF-8/UTF-16 byte offset, UAX #29 grapheme, caret stop, bidi level, or font fallback span.
- Freeze output glyph order and signed `advance_x` convention for LTR and RTL before writing the executor.
- Keep input in logical order; do not reverse text and shape it as LTR.
- Compare HarfBuzz only using an explicitly selected cluster level compatible with scalar-origin projection; do not inherit its default cluster policy.

**Detection / warning signs:**

- API examples use ASCII only.
- RTL tests compare a set of glyphs rather than exact order, clusters, advances, and offsets.
- Tests generate clusters from a UTF-8 string instead of the caller scalar array.
- Documentation claims cursor placement.

**Required tests:** Supplementary scalar, combining mark, repeated scalar, LTR ligature, RTL ligature, skipped mark under `IGNORE_MARKS`, empty input, and `.notdef`. Freeze the exact ordered run record for each.

### Pitfall 5: Implementing direction as array reversal

**What goes wrong:** The shaper reverses the scalar array for RTL, applies LTR lookup matching, and reverses the glyphs again. Logical component order, pair order, cluster propagation, and lookup filtering become wrong even for a deliberately limited RTL run.

**Why it happens:** Visual reversal looks equivalent on trivial one-glyph-per-scalar tests. HarfBuzz explicitly warns that reversing RTL input and shaping it as LTR is not equivalent to shaping logical input with RTL direction.

**Consequences:** Wrong ligatures and pair positioning; mismatch with licensed oracles; hidden coupling to future bidi behavior.

**Prevention:**

- Accept only a caller-segmented, uniform-direction run in logical scalar order.
- Encode direction in traversal helpers rather than mutating the input.
- Interpret GSUB ligature components and GPOS pairs in writing/logical direction as specified.
- Keep UAX #9 paragraph resolution, mirroring, embeddings, isolates, weak/neutral resolution, and line reordering explicitly out of scope.
- Reject mixed-direction expectations at the API/documentation boundary instead of guessing.

**Detection / warning signs:** Functions named `reverse_for_rtl`, oracle calls using guessed properties, or tests where LTR and RTL differ only by final array reversal.

### Pitfall 6: Mishandling lookup filtering and ligature components

**What goes wrong:** `IGNORE_BASE_GLYPHS`, `IGNORE_LIGATURES`, or `IGNORE_MARKS` is ignored, applied before GDEF validation, or causes skipped glyphs to be consumed by a ligature. A ligature incorrectly deletes intervening marks or assigns the wrong cluster.

**Why it happens:** Filtering changes traversal but not the underlying glyph buffer. Matching components are non-contiguous in storage when ignored glyphs intervene.

**Consequences:** Common real fonts, including Source Sans-style `IGNORE_MARKS` lookup construction, shape incorrectly. Cluster provenance and glyph preservation break together.

**Prevention:**

- Parse and validate GDEF 1.0 GlyphClassDef before applying the admitted filtering flags.
- If one of the admitted ignore flags is used but usable GlyphClassDef is absent, fail the selected path rather than invent classes.
- Treat unclassified glyphs as class 0; reject out-of-range class values.
- Build a matched-index list; consume only participating components; keep skipped glyphs in their original relative order.
- Reject reserved bits, `USE_MARK_FILTERING_SET`, and non-zero mark-attachment-class filtering in v0.35.
- Treat `RIGHT_TO_LEFT` as non-operative for admitted lookup types; never infer run direction from it.

**Detection / warning signs:** Ligature code deletes a contiguous slice from first to last component, or lookup filtering is a predicate with no GDEF dependency.

### Pitfall 7: Reusing stale metrics after GSUB

**What goes wrong:** Base `hmtx` advances are loaded during cmap mapping, then GSUB changes glyph IDs without refreshing metrics. Ligature output retains the sum or first component’s old advance, and single substitutions keep the pre-substitution advance.

**Why it happens:** Glyph buffers are initialized with both identity and metrics too early.

**Consequences:** Correct glyph IDs with incorrect positions; format-neutral parity between `glyf` and CFF1 may hide the error if fixtures share widths.

**Prevention:**

- Keep the pre-GSUB buffer to glyph identity plus source cluster.
- Validate every substitution result `< numGlyphs`.
- Initialize horizontal metrics only after all selected GSUB lookups complete.
- Keep metric queries behind the opaque `Font` seam and its revision guard.
- Use generated ligatures and single substitutions whose output widths deliberately differ from input widths.

**Detection / warning signs:** `advance_x` exists in the cmap buffer type, or a GSUB handler mutates GID without touching/reinitializing metrics.

### Pitfall 8: Misparsing PairPos and applying pair adjustments with the wrong scan rule

**What goes wrong:** PairSet count does not match Coverage cardinality, PairValue records are accepted unsorted, class 0 is ignored, class matrix size overflows, zero ValueFormat is treated as malformed, the second glyph is always skipped, or adjustments overwrite rather than accumulate.

**Why it happens:** PairPos format 2 is a dense two-dimensional matrix of variable-width records; PairPos scan advancement also depends on whether the second ValueRecord is present.

**Consequences:** Wrong kerning, out-of-window reads, quadratic fallback scans, or failure on ordinary fonts.

**Prevention:**

- Require PairPos format-1 `pairSetCount == Coverage cardinality`.
- Require PairValue records strictly ordered by second GID and use bounded binary search or an equally charged deterministic search.
- Preflight `class1Count * class2Count * recordSize` with checked arithmetic before any allocation/access; include class 0 in both counts.
- Validate every ClassDef value against its consuming declared count.
- Accept zero ValueFormat; permit only the frozen static fields (`xPlacement`, `yPlacement`, `xAdvance`) and reject `yAdvance`, device/variation, and reserved bits.
- Accumulate signed adjustments in checked `Int64` in LookupList order.
- Follow the PairPos “next glyph” rule: when the second ValueRecord is absent, it may become the next probe.

**Detection / warning signs:**

- Matrix allocation uses `Int` multiplication.
- Format 2 is expanded eagerly without an allocation-size ceiling.
- Tests use only `valueFormat2 == 0`.
- Positioning stores one adjustment per glyph instead of accumulating.

### Pitfall 9: Double-applying GPOS `kern` and legacy `kern`

**What goes wrong:** The engine applies the existing legacy `Font::kerning` result and then applies selected GPOS `kern`, or uses legacy `kern` merely because the GPOS adjustment for a particular pair is zero.

**Why it happens:** Fallback is implemented per pair rather than per resolved language-system feature plan.

**Consequences:** Common fonts with both tables become too tight/loose, while smoke tests using fonts with only one source pass.

**Prevention:**

- Decide kerning authority once from the resolved GPOS feature plan.
- If selected GPOS `kern` contributes any lookup in the resolved language system, ignore the legacy table for the whole run.
- If the resolved plan has no selected GPOS `kern` lookup, use legacy format-0 horizontal pairs.
- If `kern` is caller-disabled, disable both modern and legacy routes.
- Do not fall back per missing pair or per zero adjustment.
- Preserve the existing `Font::kerning` distinctions for absent, miss, unsupported, malformed, mutation, and exhausted resource state.

**Detection / warning signs:** Legacy kerning is called inside the GPOS pair loop, or the fallback condition checks an adjustment value rather than lookup-plan presence.

### Pitfall 10: Bounding table bytes but not shaping work

**What goes wrong:** Admission respects source bytes and table counts, but shaping repeatedly scans long runs, many lookups, Coverage ranges, ligature alternatives/components, PairSets, or class definitions. A small font table and moderate input produce excessive work.

**Why it happens:** Structural complexity and execution complexity are different. The product of individually valid limits can still be unacceptable.

**Consequences:** Denial of service in document/agent workloads and target-dependent timeouts.

**Prevention:**

- Define separate non-zero semantic ceilings for input scalars, initial/final glyphs, selected features, resolved lookups, subtables, Coverage entries/ranges, ClassDef ranges, PairSet records, class cells, ligature sets/alternatives/components, retained bytes, allocations, allocation size, match probes, lookup applications, and total work.
- Charge failed probes, filtered skips, binary-search steps, and output compaction—not only successful substitutions.
- Preflight cross-products with checked arithmetic; do not infer safety from each factor being under its own ceiling.
- Avoid repeated full parsing of the same selected subtable; retain bounded validated facts behind the opaque font seam.
- Preserve exact-fit success and one-short failure for every independently adjustable dimension.

**Detection / warning signs:** A `for glyph` loop contains a linear scan of a PairSet or all ligatures without a work charge; a limit exists but no hostile test drives it; allocation count and maximum allocation size are conflated.

### Pitfall 11: Charging or publishing before the final revision guard

**What goes wrong:** The engine mutates a public run incrementally, commits caller/ancestor budget during parsing, or performs its last source-revision check before final positioning. A later malformed lookup or mutation leaves partial output or consumed authority.

**Why it happens:** Parser and executor layers each believe their local success is independently committable.

**Consequences:** Violates the established MNF transaction model; retries observe reduced budgets; stale source bytes can influence published results.

**Prevention:**

- Capture the authoritative font/source revision at operation start through a narrow opaque `mb-font` layout seam.
- Stage validated layout facts, glyph identities, clusters, metrics, positions, totals, and the combined `ResourceCharge` privately.
- Use caller and ancestor budget preflight without mutation.
- Run deterministic mutation probes during attacker-controlled stages and one final guard immediately before the sole commit.
- Commit the complete charge once, then publish one immutable `ShapedRun`.
- No error path may expose a partial glyph array or decrement any budget dimension.

**Detection / warning signs:** More than one `charge`/`commit` call in the public operation, output arrays passed to callbacks during shaping, or the final revision guard precedes final GPOS accumulation.

**Required tests:** Mutation at opening, after selection, during Coverage/ClassDef traversal, between GSUB and metrics, during GPOS, and immediately before commit. Combine mutation with malformed data and one-short budget to freeze precedence.

### Pitfall 12: Letting error precedence depend on traversal accidents

**What goes wrong:** The same multi-fault input reports unsupported, malformed, resource-exhausted, or mutation depending on target, map iteration, feature option order, or which parser helper happens to run first.

**Why it happens:** Fail-fast code has no declared admission/selection/execution precedence.

**Consequences:** Four-target evidence diverges; callers cannot rely on structured outcomes; tests overfit current implementation order.

**Prevention:**

- Define a canonical stage order: validate caller input/options/limits → opening revision → bounded structural envelope → script/language/feature selection → selected capability/profile validation → complete work/charge preflight → GSUB → metrics → GPOS/legacy choice → final revision guard → commit/publication.
- Within each stage, use deterministic table/list order.
- Freeze a multi-fault precedence matrix in public hostile tests.
- Keep error operation/context names stable and table-specific.

**Detection / warning signs:** Tests accept one of several errors, or error context embeds host exception text.

### Pitfall 13: Assuming `Int64` alone guarantees cross-target equality

**What goes wrong:** Intermediate work narrows to 32-bit `Int`, signed conversion differs, map iteration order leaks into records, or canonical JSON/text formatting differs across JS, Wasm, Wasm-GC, and native.

**Why it happens:** The public numeric model is 64-bit, but array indices, loop counters, serialization, and helper APIs may not be.

**Consequences:** Target-specific glyph positions, failures, or evidence digests despite common high-level tests.

**Prevention:**

- Keep lengths/offsets/counts/work in `UInt64` until checked narrowing after limits.
- Keep design-unit advances/offsets/totals in checked `Int64`; reject overflow rather than wrap.
- Use arrays and explicit sorting for semantic order; never rely on hash-map iteration.
- Define one closed canonical semantic carrier with decimal integer syntax, exact field order, explicit direction, explicit zero values, and no target-formatted floats.
- Run isolated `moon test` lanes for all four production targets; do not treat one `--target all` summary as equality proof.
- Compare canonical records byte-for-byte; allow target identity only outside the compared semantic payload.

**Detection / warning signs:** `.to_int()` appears before a limit check, a position uses `Double`, or equality is inferred from equal test counts.

### Pitfall 14: Treating HarfBuzz output as the specification

**What goes wrong:** Expected facts are copied directly from HarfBuzz without pinning all properties, or implementation behavior is changed to match HarfBuzz functionality outside the admitted profile.

**Why it happens:** HarfBuzz is mature and convenient, but includes normalization, script shapers, reordering, fallback/compatibility behavior, and cluster policies beyond v0.35.

**Consequences:** The foreign oracle silently defines product semantics; upgrades rewrite baselines; two tools can agree for reasons unrelated to the project contract.

**Prevention:**

- Keep hand-derived generated facts normative for the admitted micro-profile.
- Use direct pinned `hb-shape` only as an independent semantic comparison for the exact projection: GID, scalar-origin cluster, design-unit advances, and x/y offsets.
- Pass explicit font, face, text encoding, direction, script, language, feature list, cluster level, output format, and shaper selection; prohibit property guessing and ambient font lookup.
- Record archive hash, extracted executable hash, version output, command-line arguments, adapter hash, input hash, and raw/canonical output hash.
- Keep fontTools structural, HarfBuzz semantic, and OpenType Sanitizer structural; do not let one tool serve as generator, parser, and oracle.
- A mismatch is an investigation, not an automatic baseline update.

**Detection / warning signs:** Oracle scripts call `hb_buffer_guess_segment_properties`, omit cluster level, or regenerate expected files in place without a reviewed diff.

### Pitfall 15: Losing fixture provenance or redistribution obligations

**What goes wrong:** A licensed font is replaced by a distro/repacked variant, generated fixture bytes are committed without generator identity, or the license/copyright notice is separated from the redistributed font.

**Why it happens:** Font filenames and upstream version labels do not uniquely identify bytes. Reproducibility needs the entire artifact/tool/adaptor chain.

**Consequences:** Non-reproducible evidence, accidental license violation, and oracle drift caused by unrelated font bytes.

**Prevention:**

- Reuse retained DejaVu Sans 2.37 and Source Sans 3.052R bytes only after verifying repository hashes.
- Preserve the upstream copyright and license beside each redistributed font; do not infer license from repository metadata alone.
- Prefer official archives/releases and record upstream URL, version/tag, archive size/hash, member path/hash, repository path/hash, acquisition date, and license path/hash.
- For generated fonts, bind source description, generator/adaptor commits, pinned tool identities, deterministic environment inputs, output hash, and hand-derived expected facts.
- Refuse partial publication when any manifest member, tool, adapter, source font, or output digest is unbound.

**Detection / warning signs:** A fixture manifest contains only filename/version, the generator depends on PATH discovery, or CI downloads “latest.”

### Pitfall 16: Claiming complex-script shaping from simple lookup support

**What goes wrong:** Because a font’s selected Arabic/Indic feature happens to contain a supported single or ligature lookup, v0.35 returns success without the required script-specific stages, reordering, contextual substitutions, mark/cursive attachment, or bidi preparation.

**Why it happens:** OpenType defines low-level lookups, while complete script shaping requires client-side algorithms outside the tables.

**Consequences:** Incorrect text for languages where shaping correctness is essential; misleading product positioning.

**Prevention:**

- Define and enforce a horizontal, caller-segmented, implementation-honest profile rather than a broad script-name allowlist.
- If a selected required path needs contextual/chained/reverse, mark/cursive, reordering, variable/device, or other deferred semantics, return capability failure.
- Use Source Han only as admission/compatibility evidence, never as a Japanese/complex-script shaping claim.
- Documentation must say “Latin-style GSUB/GPOS subset,” not “multilingual shaping.”

**Detection / warning signs:** Release notes list supported scripts based on cmap coverage or successful glyph output alone.

## Moderate Pitfalls

### Pitfall 17: Ambiguous script, language, and feature fallback

**What goes wrong:** Missing exact script selects the first script, missing language combines default and exact LangSys, `DFLT` and default LangSys are conflated, or duplicate/conflicting caller feature entries resolve differently by input order.

**Prevention:** Exact script → documented `DFLT` fallback only; exact LangSys → that Script table’s default LangSys only; use one language system, not both; include the required feature; define `rlig`/`liga`/`kern` defaults; reject malformed/duplicate/conflicting caller entries; validate sorted unique tags and all indices.

**Detection:** Changing record order changes selection, or tests never distinguish `DFLT` Script from default LangSys.

### Pitfall 18: Overflowing signed placement and total advance

**What goes wrong:** Individually valid FWORD adjustments overflow after many lookups/glyphs, or unsigned base advances are mixed with signed deltas through unchecked casts.

**Prevention:** Convert admitted base advances to checked `Int64`, checked-add every ValueRecord and legacy kern delta, checked-sum total advance, and fail before publication. Add exact-boundary and alternating-sign sequences, not only one pair.

### Pitfall 19: Over-validating unsupported, unselected font capabilities

**What goes wrong:** The presence of any contextual, mark, vertical, device, or variable structure rejects a font even when no selected v0.35 feature reaches it.

**Prevention:** Validate enough of the global envelope to resolve selected structures safely, but apply capability rejection to selected/reachable execution paths. Keep “present but unselected” distinct from “selected and unsupported.” Preserve the ability to shape a simple supported feature in a font that also contains richer layout.

**Detection:** A Source Han compatibility fixture cannot shape a deliberately simple supported path because unrelated complex tables exist.

### Pitfall 20: Breaking the existing opaque `Font` and legacy behavior

**What goes wrong:** `mb-text` gains raw-table access, `Font` exposes mutable layout records, font admission starts rejecting previously accepted static fonts, or the existing `Font::kerning` public semantics change.

**Prevention:** Add a narrow private/opaque layout capability seam to `mb-font`; keep string sequencing in the independently publishable `mb-text`; expose no raw offsets/views; run the frozen 1,287-test v0.34 four-target baseline plus public interface diffs; require an RFC for dependency or public-boundary changes.

## Minor Pitfalls

### Pitfall 21: Treating empty input or `.notdef` as failure

**What goes wrong:** Empty input attempts table selection or requires GSUB/GPOS presence; a valid unmapped scalar is treated as malformed instead of glyph zero.

**Prevention:** Empty valid input returns an empty immutable run with direction/units-per-em and zero total advance under the frozen charging rule. Valid unmapped scalars preserve their source cluster and use the admitted `.notdef` glyph/metrics. Invalid scalars still fail before shaping.

### Pitfall 22: Benchmarking before semantics stabilize

**What goes wrong:** Native timing thresholds drive premature caches or target-specific fast paths, obscuring correctness and resource accounting.

**Prevention:** Keep performance observation-only, native-only, workload-declared, and bound to the same semantic digest after all four correctness lanes pass. No cross-runtime timing comparison is an acceptance criterion.

## Phase-Specific Warnings

| Phase | Scope | Likely pitfall | Required mitigation / exit evidence |
|---:|---|---|---|
| 108 | Public contract and opaque seam | RTL order/advance and cluster meaning remain ambiguous; raw OpenType details leak from `mb-font` | Freeze the exact run/options/error model, scalar-origin clusters, direction convention, feature defaults, fallback rules, selected-unsupported policy, and opaque `mb-font` capability interface before parser implementation |
| 109 | Bounded layout admission | Wrong offset base, unchecked cardinality, oversized class matrices, missing GDEF dependency, or eager rejection of unrelated complex tables | Offset-base ledger; checked window helpers; semantic limits for every count/range/matrix; exact/one-short hostile suite; selected-vs-unselected validation rules; no public raw tables |
| 110 | GSUB execution | Feature order, ligature preference, filtered component deletion, stale metrics, or wrong clusters | LookupList-order scheduler; stored subtable and ligature preference; matched-index consumption; GID range checks; metrics deliberately deferred; LTR/RTL exact generated facts |
| 111 | GPOS and kerning | Pair scan rule, class 0, ValueRecord width, accumulation, or legacy double-kern | PairPos 1/2 hostile fixtures; checked dense extent; allowed-bit mask; signed accumulation; run-level GPOS/legacy authority decision; licensed DejaVu/Source Sans comparisons |
| 112 | Transactional shaping integration | Structural limits mistaken for execution limits; mutation/commit occurs too early; error precedence drifts | Combined parser/executor charge; caller+ancestor exact/one-short tests; mutation at frozen probes; one final revision guard; one commit and one publication; multi-fault precedence matrix |
| 113 | Qualification and release evidence | Oracle defaults, self-oracle, repacked font, unbound toolchain, or equal test counts mistaken for equal behavior | Hand-derived facts plus pinned `hb-shape`; explicit oracle args/cluster level; full artifact/license manifest; generated `glyf`/CFF1 equivalence; four byte-equal canonical semantic records; frozen v0.34 regression |

## Roadmap Research Flags

- **Phase 108 requires deeper research before implementation:** exact RTL output order and signed-advance convention. This is the only major public-semantic watch item that cannot be safely deferred.
- **Phase 109 requires phase research:** enumerate every admitted field’s offset base, required cardinality relation, sortedness rule, class-zero behavior, selected/unselected validation depth, and error context.
- **Phase 111 requires phase research:** freeze the full allowed `ValueFormat` bit matrix and the PairPos next-probe rule for both directions with hand-derived examples.
- **Phase 112 requires phase research:** derive a complete work equation and charge ledger from actual executor loops; do not copy CFF limits mechanically.
- **Phase 113 requires phase research:** provision HarfBuzz 14.2.1, record the extracted executable digest, choose/freeze cluster level and shaper options, and prove retained font licensing/manifests before baselining.
- Complex scripts, mark/cursive attachment, contextual/chained lookups, bidi, normalization, fallback, vertical layout, variable/device positioning, and font discovery are future milestone research topics—not spillover tasks.

## Pre-Submission / “What Might We Have Missed?” Review

The following areas remain intentionally unresolved and must not be inferred from this research:

- Exact MoonBit allocation-size accounting for the final retained layout representation; it depends on the Phase 109 data model.
- Exact RTL public order/advance projection; official standards and HarfBuzz document behavior, but MNF must choose and freeze its own bounded-run contract.
- Whether Source Sans 3.052R exercises every desired GDEF/filter/extension combination after the final selected script/language/features are fixed; the fixture must be inspected by the pinned host lane.
- The complete set of feature parameters and layout 1.1 FeatureVariations rejection cases; v0.35 should accept only the explicitly documented null/absent profile.
- Performance of the eventual MoonBit lookup representation; correctness and charged complexity must land before observation-only tuning.

## Sources

### Primary standards and official documentation

- [OpenType 1.9.1 specification index](https://learn.microsoft.com/en-us/typography/opentype/spec) — current official OpenType specification and change history. **Confidence: MEDIUM**
- [OpenType Layout Common Table Formats](https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2) — Script/LangSys/Feature/Lookup relationships, lookup order, lookup flags, Coverage, ClassDef, and offset bases. **Confidence: MEDIUM**
- [GSUB — Glyph Substitution Table](https://learn.microsoft.com/en-us/typography/opentype/spec/gsub) — SingleSubst, LigatureSubst preference/logical order, and extension dispatch. **Confidence: MEDIUM**
- [GPOS — Glyph Positioning Table](https://learn.microsoft.com/en-us/typography/opentype/spec/gpos) — PairPos formats, ValueRecords, pair traversal, class matrices, and extension dispatch. **Confidence: MEDIUM**
- [GDEF — Glyph Definition Table](https://learn.microsoft.com/en-us/typography/opentype/spec/gdef) — glyph classes used by lookup filtering. **Confidence: MEDIUM**
- [Recommendations for OpenType Fonts](https://learn.microsoft.com/en-us/typography/opentype/spec/recom) — GPOS `kern` versus legacy `kern` precedence. **Confidence: MEDIUM**
- [Unicode 17, Chapter 3](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/) — Unicode scalar-value definition. **Confidence: MEDIUM**
- [UAX #9: Unicode Bidirectional Algorithm](https://www.unicode.org/reports/tr9/) — bidi resolution and reordering boundary. **Confidence: MEDIUM**
- [UAX #24: Unicode Script Property](https://www.unicode.org/reports/tr24/) — Script and Script_Extensions ambiguity. **Confidence: MEDIUM**
- [UAX #29: Unicode Text Segmentation](https://www.unicode.org/reports/tr29/) — grapheme clusters and their distinction from ligatures. **Confidence: MEDIUM**
- [HarfBuzz buffer direction](https://harfbuzz.github.io/harfbuzz-hb-buffer.html) and [cluster behavior](https://harfbuzz.github.io/working-with-harfbuzz-clusters.html) — explicit direction, RTL output, cluster levels, and monotonicity. **Confidence: MEDIUM**
- [HarfBuzz shaping API](https://harfbuzz.github.io/harfbuzz-hb-shape.html) and [utilities](https://harfbuzz.github.io/utilities.html) — explicit font/properties/features and `hb-shape` projection. **Confidence: MEDIUM**
- [MoonBit fundamentals](https://docs.moonbitlang.com/en/latest/language/fundamentals.html) and [`moon` command reference](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — 64-bit integer types and target commands. **Confidence: MEDIUM**

### Fixture and license authorities

- [DejaVu official downloads](https://dejavu-fonts.github.io/Download.html) — official 2.37 artifact identities and checksums versus third-party packages. **Confidence: MEDIUM**
- [Source Sans official repository](https://github.com/adobe-fonts/source-sans) — 3.052 release and SIL Open Font License identity. **Confidence: MEDIUM**

### Repository evidence

- `.planning/PROJECT.md`, `.planning/MILESTONE-CONTEXT.md`, `.planning/research/FEATURES.md`, and `.planning/research/STACK.md`.
- `modules/mb-font/font/cursor.mbt`, `limits.mbt`, `font.mbt`, `kern.mbt`, and `cff_admission.mbt`.
- Retained DejaVu Sans 2.37, Source Sans 3.052R, and Source Han Serif JP 2.003R fixtures and manifests under `fixtures/font/`.
- v0.34 Phase 107 qualification, review, security, and verification artifacts.
