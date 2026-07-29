# Phase 105: Bounded Type 2 Validation and Retained Metrics - Context

**Gathered:** 2026-07-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Build one private, deterministic, bounded Type 2 interpreter over the complete per-GID CFF1 execution environments admitted by Phase 104. Validate every glyph before publication, retain one truthful compact conservative bound per GID, keep OpenType `hmtx` authoritative for public metrics, and preserve one atomic admission transaction. This phase does not publish CFF-backed `Font` outlines or `Path2` values; public standalone/TTC integration belongs to Phase 106.

</domain>

<decisions>
## Implementation Decisions

### Fixed-point arithmetic and deterministic random
- **D-01:** Represent every Type 2 operand, coordinate, transient value, width, and matrix intermediate as signed Q16.16. Decode Type 2 byte `255` directly as signed 16.16; do not reuse DICT number encoding rules.
- **D-02:** Use checked `Int64` intermediates, but require every value returned to the operand stack, transient array, PRNG output, or geometry state to fit signed 32-bit Q16.16 raw range.
- **D-03:** `add`, `sub`, `mul`, `div`, `neg`, `abs`, and `sqrt` fail as deterministic Data/numeric errors on overflow, division by zero, negative square root, or `INT32_MIN` negation. Multiplication/division scale toward zero; non-negative square root returns the greatest representable Q16.16 value not exceeding the mathematical root.
- **D-04:** Implement project-owned `random` with a fixed xorshift32 transition. Reset independently at the start of each GID from the selected Private DICT `initialRandomSeed`; zero seed maps to the fixed non-zero constant `0x6D2B79F5`, non-zero seed uses the retained checked Q16.16 raw bit pattern, and subroutines share the glyph state. Emit `(high16(state) + 1)` as Q16.16 raw `1..65536`, giving `(0, 1]`. Do not mix GID, time, target, font traversal order, or ambient randomness.
- **D-05:** Retain and validate `initialRandomSeed` instead of accepting and discarding it. Adobe TN #5176 confirms it is a Private DICT `number` with default `0`; convert that checked numeric value into the locked 32-bit PRNG seed without changing the algorithm, reset boundary, or output mapping.

### VM operators, hint framing, and subroutines
- **D-06:** Implement one closed static Type 2 VM covering numbers; stem/hint operators; move, line, curve, and all flex forms; width; local/global calls; `return`/`endchar`; and escaped stack, transient, arithmetic, logical, conditional, and storage operators required by T2-01. `dotsection` is a defined no-op. Reserved/unknown operators are Data; CFF2-only operators are Capability.
- **D-07:** Use a fixed-capacity operand stack 48 and transient array 32 with a per-element initialization bitmap. Adobe TN #5177 leaves `get` before `put` undefined, so reject it deterministically as Data rather than expose an arbitrary zero. Stack underflow, bad integer/index/roll operands, transient out-of-range/uninitialized access, invalid subr index, and illegal termination are Data; stack/stem/frame/depth/call/byte/work/geometry ceiling exhaustion is Resource.
- **D-08:** Stem operators validate pairs and clear the stack. `hintmask`/`cntrmask` require at least one declared stem, first consume any stack-resident additional stems, then consume exactly `(stem_count + 7) / 8` raw mask bytes. Hints have no rendering effect and unused trailing mask bits need not be zero. Stem ceiling is 96.
- **D-09:** Resolve subroutine bias solely from each selected INDEX count using `107`, `1131`, or `32768`. Use an explicit iterative call-frame stack with global/local identity and the glyph-selected local environment; never use host recursion. Maximum nested subroutine depth is 10. Root EOF, subr EOF, root `return`, out-of-range calls, and trailing bytes after legal termination are Data. Adobe TN #5177 permits a subroutine to terminate the glyph with `endchar`; accept this only when the call occupies the tail of every suspended caller frame, otherwise reject the unexecuted trailing bytes.
- **D-10:** Do not perform static cycle pre-scans. Recursive/cyclic call behavior is bounded deterministically by depth, call, executed-byte, and work authority.

### Width, matrices, contour termination, and retained bounds
- **D-11:** Validate Type 2 optional-width placement and checked arithmetic using `defaultWidthX`/`nominalWidthX`, but never compare the result with OpenType metrics or use it as public advance/LSB authority. `hmtx` remains authoritative even when a TTC/OTC face shares CFF bytes with a face-local metrics table.
- **D-12:** Preserve whether an FD FontMatrix was omitted. For name-keyed glyphs apply Top FontMatrix exactly once. For CID glyphs apply the selected FD-local matrix first and then Top FontMatrix; omitted FD matrix is relative identity/inheritance, not another default `0.001` transform.
- **D-13:** Compose exact rational matrix facts with checked arithmetic and normalize to OpenType design units using `head.unitsPerEm × Top × FD × charstring-coordinate`. Official CFF/OpenType research must verify concat order and default/inheritance wording before planning, but must not reintroduce duplicate name-keyed application or floating-point VM arithmetic.
- **D-14:** Starting a new moveto implicitly closes the prior contour; legal `endchar` closes the final contour. The root CharString must terminate exactly once through its own clean `endchar` or a tail-called subroutine `endchar`; ordinary subroutines terminate with `return`. Type 1 `closepath` is not accepted as a no-op.
- **D-15:** Reject the deprecated four-argument seac-compatible `endchar` form with stable Capability in Phase 105. Component lookup/composition is not silently added to this phase.
- **D-16:** Accumulate bounds in checked fixed-point over move/line endpoints and cubic endpoints/control points. Use the cubic control hull as the conservative contract, not target-dependent exact extrema. Apply the effective matrix before bounds; round minima toward negative infinity and maxima toward positive infinity into checked `GlyphBoundsFacts`. A glyph with no drawing segments retains `None`.

### All-glyph atomic admission, resource ledger, and errors
- **D-17:** Execute every GID in ascending order with the same VM. Each glyph gets fresh operand/transient/frame/PRNG/geometry state; only its selected immutable CFF environment is shared. The smallest failing GID is the deterministic failure site.
- **D-18:** Stage the Phase 104 structural facts, all-glyph VM results, compact bounds array, and named resource facts without committing. Preflight the combined structural + VM + retained-metrics charge, perform a final source-revision guard, then commit exactly once and construct the complete private `AdmittedCff1`.
- **D-19:** Any failure discards all staged bounds and publishes no `Font`, no CFF outline source, and no committed caller/ancestor charge. The existing Phase 104 admission path must be split or extended before its current structural commit; rollback of an already committed budget is not an acceptable design.
- **D-20:** Stable ledger units: each actually fetched glyph/subr/mask byte counts as one executed byte; decoded number, operator dispatch, call, return, matrix primitive, and bounds primitive carry fixed named work units; Move/Line/Curve/Close count as commands; geometry points count `1/1/3/0`; flex lowers to two curves/six points; each moveto counts one contour. Repeated subr execution is recharged as executed bytes/work.
- **D-21:** Reuse existing public limits rather than add a public Type 2 limits surface. Per-glyph executed bytes use `max_outline_instruction_bytes`; points/contours use existing outline limits; derive a checked command ceiling from `points + 2 × contours`; cumulative work uses `max_work`. Fixed stack/transient/frame scratch has deterministic allocation facts.
- **D-22:** `ResourceCharge.bytes` counts retained/source authority without double-counting the same source view on subr replay. `allocations` counts real retained/scratch array objects; `allocation_size` is the largest single allocation, never a sum.
- **D-23:** Preserve the Phase 104 precedence: State/revision → caller/resource authority → recognized Capability → encountered Data. Check authority before consuming the governed byte/operation; within a glyph use actual execution order; across glyphs use ascending GID. Before returning any non-State VM error, recheck revision so concurrent mutation deterministically wins.

### the agent's Discretion
- Exact private type/file names and task boundaries may follow existing package conventions.
- Fixed numeric error context suffixes and individual work-unit constants may be chosen during planning, provided they are stable, independently testable, and consistent with D-20/D-23.
- The bounds sink may be an interpreter mode or a private interface, provided Phase 105 retains compact bounds only and Phase 106 can reuse the identical VM semantics for path emission.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project contracts and prior phase
- `.planning/ROADMAP.md` — Phase 105 goal, requirements, and four success criteria.
- `.planning/REQUIREMENTS.md` — T2-01, T2-02, and CFF-03 normative project requirements.
- `.planning/STATE.md` — carried-forward decisions and Phase 105/107 concerns.
- `.planning/phases/104-cff1-profile-and-bounded-data-model/104-CONTEXT.md` — locked Phase 104 keying, limits, admission, and error-precedence decisions.
- `.planning/phases/104-cff1-profile-and-bounded-data-model/104-VERIFICATION.md` — verified structural handoff and supported CFF1 profile.

### Milestone research
- `.planning/research/SUMMARY.md` — recommended Q16.16 VM, all-glyph admission, bounds, and metric authority.
- `.planning/research/FEATURES.md` — operator/compatibility/resource feature matrix and rejected shortcuts.
- `.planning/research/ARCHITECTURE.md` — VM/sink architecture, explicit frames, hint framing, limits, and integration seams.
- `.planning/research/PITFALLS.md` — milestone failure modes and prevention guidance.

### Normative external specifications
- [Adobe Technical Note #5177 — Type 2 Charstring Format](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf) — number/operator semantics, widths, hints/masks, subroutines, random, termination, and implementation limits.
- [Adobe Technical Note #5176 — Compact Font Format](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5176.CFF.pdf) — Private DICT seed/widths, subr bias, FontMatrix, and CID semantics.
- [OpenType CFF table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff) — OpenType glyph identity, CFF1 integration, and profile restrictions.
- [OpenType `hmtx`](https://learn.microsoft.com/en-us/typography/opentype/spec/hmtx) — authoritative advance/side-bearing metrics.

### Existing implementation
- `modules/mb-font/font/cff_admission.mbt` — staged CFF structural authority and current final commit seam.
- `modules/mb-font/font/cff_keying.mbt` — normalized per-GID CharString/private/local-subr/matrix environments.
- `modules/mb-font/font/cff_dict.mbt` — exact DICT facts, Private widths/seed seam, and incremental parser pattern.
- `modules/mb-font/font/cff_index.mbt` — bounded CharString/subroutine views and bias counts.
- `modules/mb-font/font/outline.mbt` — checked signed arithmetic, explicit composite frames, and geometry accounting analogs.
- `modules/mb-font/font/metrics.mbt` — compact `GlyphBoundsFacts`, `hmtx` reads, and right-side-bearing calculation.
- `modules/mb-font/font/tables.mbt` — `FontAdmissionLedger` atomic preflight/commit.
- `modules/mb-font/font/limits.mbt` — existing public limits and private derived CFF ceilings.
- `modules/mb-core/checked/checked.mbt` — checked UInt64 arithmetic and allocation-size helpers.
- `modules/mb-core/budget/budget.mbt` — caller/ancestor preflight and charge semantics.
- `modules/mb-core/bytes/views.mbt` — mutation revision authority.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `cff_parse_dict_incremental` in `cff_dict.mbt`: reuse its single-cursor, fixed operand-stack, entry-consumer, and encounter-order pattern for VM decoding.
- `CompositeFrame` and composite graph classification in `outline.mbt`: closest explicit-stack/depth/cycle analog; Type 2 needs separate global/local call identities and shared VM state.
- Checked signed outline arithmetic in `outline.mbt`: pattern for deterministic `Int64` intermediates and structured numeric errors; Phase 105 adds Q16.16 mul/div/sqrt rules.
- `FontAdmissionLedger::preflight_atomic` / `commit_atomic` in `tables.mbt`: preserve one final combined transaction.
- `CffAuthorityLedger` and final guard/commit sequence in `cff_admission.mbt`: extend with VM and retained-bounds dimensions rather than create a parallel budget.
- `GlyphBoundsFacts` and `font_right_side_bearing` in `metrics.mbt`: retain compact CFF bounds and keep `hmtx` authoritative.
- `FontOutlineSource::Cff1(AdmittedCff1)` in `font.mbt`: only complete all-glyph facts may cross this closed private boundary.

### Established Patterns
- Untrusted data is preflighted before traversal/allocation and published only after a final revision check.
- Resource errors are separate from malformed Data and unsupported Capability; multi-fault precedence is deterministic.
- Private white-box tests assert parser/ledger internals; public tests freeze format-neutral glyf behavior.
- No production deterministic PRNG exists; fixture schedule names are not reusable algorithms.

### Integration Points
- Extend `CffPrivateDict` to retain `initialRandomSeed` and distinguish omitted FD FontMatrix inheritance.
- Replace the current single tracer `AdmittedCff1.glyph` shape with complete ordered glyph environments and retained bounds.
- Insert all-glyph VM validation before the existing CFF structural ledger commit.
- Preserve common SFNT `head`/`hmtx` facts needed for matrix normalization and future metric lookup without publishing CFF-backed `Font` until Phase 106.
- Phase 106 should reuse the identical interpreter with a path sink; Phase 105 must not retain full per-glyph command streams or `Path2` values.

</code_context>

<specifics>
## Specific Ideas

- Model Type 2 as an iterative frame machine over zero-copy CharString/subr views and one shared operand/transient/hint/geometry state.
- Keep bounds conservative through transformed endpoints/control points and explicit outward integer rounding.
- Include deliberate CFF-width versus `hmtx` mismatch tests to prove syntax validation and public metric authority remain separate.
- Qualification should include subr-bias thresholds, depth 10/11, stem 96/97, mask truncation, PRNG reset/order independence, matrix inheritance/composition, and exact/one-short resource facts.

</specifics>

<deferred>
## Deferred Ideas

- Public CFF-backed `Font`, cubic `Path2`, standalone/TTC outline queries, and format-neutral metric routing — Phase 106.
- CFF2 blend/variation execution, WOFF, shaping, hint rendering, rasterization, and color/bitmap glyphs — outside v0.34.
- Deprecated seac component composition — explicit Capability in Phase 105; reconsider only through a future scoped requirement.

</deferred>

---

*Phase: 105-bounded-type-2-validation-and-retained-metrics*
*Context gathered: 2026-07-28*
