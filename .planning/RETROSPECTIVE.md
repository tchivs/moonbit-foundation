# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v0.1 — Foundation

**Shipped:** 2026-07-17  
**Phases:** 5 | **Plans:** 41 | **Tasks:** 93

### What Was Built

- An accepted RFC-led governance and compatibility foundation with a reproducible three-module MoonBit workspace.
- Bounded `mb-core` safety, I/O, diagnostic, budget, storage, and explicit host-capability contracts.
- Typed `mb-color` semantics and a safe `mb-image` model with deterministic operations and codec-facing contracts.
- A strict bounded PPM P6 decoder/encoder, portable and Native CLI-shaped public examples, and generated conformance evidence.
- Reproducible benchmark and release qualification with deterministic packages, isolated consumers, fail-closed negatives, and canonical same-HEAD reports.

### What Worked

- Horizontal layering kept the dependency DAG explicit and let each phase consume already verified contracts.
- Independent phase verification found real lifecycle, provenance, generated-evidence, allocation-accounting, and planar-authority gaps before closeout.
- Closed machine-readable policy owners, exact interfaces, package inventories, and negative fixtures prevented documentation or topology drift.
- Generated fixtures and public-API consumers provided stronger evidence than example-only or snapshot-only checks.
- Freezing the final static ledger before two Required runs preserved a trustworthy unchanged-HEAD release proof.

### What Was Inefficient

- Early phase state and summary metadata occasionally lagged the actual phase position and required closeout normalization.
- Full Required grew to roughly three minutes, making repeated end-to-end runs expensive even though the selector structure remained valuable.
- The milestone helper emitted every plan one-liner into `MILESTONES.md`; a concise curated milestone summary is easier to review.
- Registry-independent downstream artifact proof cannot fully close until the namespace and dependency versions are actually published.

### Patterns Established

- Use exact named dependencies plus workspace substitution; prohibit path dependencies in candidate release topology.
- Keep portable algorithms MoonBit-owned and inject narrow host/Native adapters through explicit capabilities.
- Preflight checked arithmetic and budgets before allocation, mutation, or output; charge once through an authoritative owner.
- Treat generated evidence as canonical data with provenance, byte-stable check mode, and package-local behavioral consumers.
- Separate source isolation, exact artifact consumption, and real registry resolution; never convert an external blocker into a fabricated pass.

### Key Lessons

1. Phase-level green tests do not replace adversarial verification of ownership and cross-layer wiring; independent verifier passes should remain mandatory.
2. Release evidence must be frozen before execution and stored separately from tracked planning edits when same-HEAD reproducibility matters.
3. A small reference codec is enough to validate deep infrastructure contracts when its grammar, limits, progress, and EOF semantics are strict.
4. Single-maintainer governance can be authentic when authority, eligibility, expiry, and evidence are explicit and fail closed.

### Cost Observations

- Model mix: not captured by the local GSD runtime.
- Sessions: not reliably derivable from repository history.
- Notable: 292 commits and targeted parallel agents kept 41 plans atomic; the principal cost was repeated four-target Required qualification.

---

## Milestone: v0.8 — Resumable PNG Decode

**Shipped:** 2026-07-21  
**Phases:** 3 | **Plans:** 5

### What Was Built

- A private, pause-safe MoonBit PNG framing, DEFLATE, and raster state machine retained eager API compatibility.
- A public `PngChunkDecoder` with exact caller-buffered progress, explicit strict completion, and sticky typed terminal errors.
- A 3,850-record public hostile-schedule corpus and one portable decode → resize → eager-encode workflow, proven on all four targets.

### What Worked

- Final verification and the milestone audit found and closed real public EOF-classifier gaps before shipment.
- Isolated clean-worktree testing avoided stale native build artifacts and reconfirmed 84/84 PNG tests per target.

### What Was Inefficient

- Historical verification reports and stale roadmap metadata confused GSD's current-status parser during closeout.
- The milestone archive helper misclassified historical roadmap details under `--force`; the unrelated Phase 9 and 20-25 directories were immediately restored before any commit.

### Key Lessons

1. Keep only the final current verification report under the active verifier naming convention; retain prior gap reports as explicit history.
2. Scope archive tooling from canonical milestone phase numbers, not permissive roadmap prose parsing.
3. Public streaming contracts need both arbitrary-schedule corpus evidence and a small runnable consumer flow.

## Milestone: v0.12 — PNG Filter Optimization

**Shipped:** 2026-07-22  
**Phases:** 3 | **Plans:** 9

### What Was Built

- An additive, legacy-compatible Adaptive PNG filter API for eager and caller-buffered output.
- Deterministic bounded selection across the five standard method-0 PNG row filters.
- Bounded, acknowledgement-safe replay and complete preflight accounting for Stored, FixedOrStored, and DynamicOrFixedOrStored routes.
- Four-target generated-corpus proof of strict Adaptive wins, eager/chunk identity, and public decode fidelity.

### What Worked

- Independent verifier passes caught two real planner-accounting/replay gaps before the milestone was closed.
- Selector-isolated evidence with GUID-owned temporary target roots avoided repeated source-tree copies and left no test residues.
- Preserving frozen filter-None vectors kept the new API additive instead of silently changing existing users' bytes.

### What Was Inefficient

- Intermediate red/recovery artifacts and generated planning output accumulated faster than the active milestone needed.
- Automatic milestone accomplishment extraction included superseded failed-attempt notes; the closeout summary now curates final shipped behavior instead.

### Key Lessons

1. For streaming encoders, planner work must be accounted for on candidate-decline paths as well as selected paths.
2. A focused cross-target evidence runner is more useful than repeatedly running a broad suite that can stall without producing failure evidence.
3. Planning directories should be archived at milestone close, not left beside the next active phase.

---

## Milestone: v0.15 — Gray16 PNG Interchange

**Shipped:** 2026-07-22  
**Phases:** 3 | **Plans:** 3

### What Was Built

- Explicit U16 Gray16 PNG factories for eager and caller-buffered consumers.
- One shared bounded path for Gray16 filtering, DEFLATE strategy selection, atomic admission, and acknowledgement-safe replay.
- Public wire-byte, hostile-capacity, legacy-compatibility, and independent four-target evidence.

### What Worked

- Extending the existing profile-aware scalar producer avoided a second encoder implementation and image-sized staging.
- Public tests used non-symmetric U16 data and both storage byte orders, which made wire-order mistakes observable.

### What Was Inefficient

- Historical debug metadata blocked closeout despite v0.15 passing all verification; it required an explicit historical-deferred record.

### Patterns Established

- For widened sample formats, test exact encoded wire semantics separately from any intentionally lossy public decode canonicalization.

### Key Lessons

1. Add new PNG profiles through explicit factories and the shared admission/replay machinery, never a special staging route.
2. Archive completed phase artifacts immediately at milestone close so active planning stays small.

### Cost Observations

- Model mix and session count are not reliably captured by the local GSD runtime.
- Notable: all four supported targets completed the PNG suite at 190/190 tests.

---

## Milestone: v0.17 — GrayAlpha16 PNG Interchange

**Shipped:** 2026-07-23
**Phases:** 3 | **Plans:** 4 | **Tasks:** 8

### What Was Built

- Packed U16 Gray+Alpha descriptor admission with checked per-component storage and preserved fail-closed operations.
- Explicit bounded eager and caller-buffered non-interlaced Type-4/16 PNG factories with `Ghi,Glo,Ahi,Alo` wire output.
- Public U16 wire/RGBA8 canonicalization evidence, hostile lease schedules, frozen legacy bytes, and four-target qualification.

### What Worked

- Extending the existing profile-aware bounded machine avoided staging and kept eager/chunk behavior identical.
- Non-symmetric U16 fixtures and literal raster assertions made byte-order mistakes directly observable.
- Independent code review, security audit, phase verification, and milestone integration audit found no implementation gap.

### What Was Inefficient

- Historical `quick/` and `debug/` records were left outside milestone archives, obscuring the active planning view.

### Patterns Established

- For U16 alpha profiles, retain a strict source-storage admission contract and test it separately from PNG wire order and intentionally lossy decoder canonicalization.

### Key Lessons

1. Reuse the shared bounded pipeline for a new format profile; do not add a format-specific output buffer or replay path.
2. Archive all historical planning artifacts at milestone close, not only phase directories.

### Cost Observations

- All four supported targets completed the PNG package at 204/204 tests.

---

## Milestone: v0.19 — GrayAlpha8 Adam7 PNG

**Shipped:** 2026-07-23
**Phases:** 3 | **Plans:** 5 | **Tasks:** 6

### What Was Built

- Additive eager and caller-buffered GrayAlpha8 Adam7 Type-4/8 selectors using the existing bounded machine.
- A profile-neutral pre-lease revision guard and six-pair mutation-safe replay evidence.
- Independent `G,A` wire/decode proof, fresh hostile caller leases, frozen GrayAlpha16 literals, and 227/227 PNG tests on every supported target.

### What Worked

- TDD plus independent plan, phase, and milestone checks caught the unresolved compression-corpus and frozen-vector assumptions before implementation.
- Measured all-seven-pass fixtures made Stored, Fixed, and Dynamic route coverage deterministic.

### What Was Inefficient

- Several research/execution agents required interruption to stop broad exploration and return bounded findings.

### Patterns Established

- Generalize replay integrity checks at the common pre-lease seam, while retaining plan-specific terminal diagnostics.
- Treat independently derived frozen bytes as public compatibility assets; never use current encoder output as their oracle.

### Key Lessons

1. A profile addition belongs on the existing bounded machine, not in a format-specific encoding fork.
2. Before accepting a compression-route test matrix, measure and record a deterministic corpus for every intended route.
3. Archive phase artifacts at milestone close so the active planning surface stays small.

### Cost Observations

- The ordinary PNG package completed at 227/227 on wasm, wasm-gc, js, and native.

---

## Milestone: v0.20 — High-Precision GrayAlpha Decode

**Shipped:** 2026-07-23
**Phases:** 3 | **Plans:** 3 | **Tasks:** 4

### What Was Built

- Explicit eager and caller-buffered Type-4/16 GrayAlpha decoders that preserve the existing packed little-endian U16 component lanes.
- Profile-aware Adam7 Type-4/16 scatter on the existing bounded decode machine, with generic RGBA8 high-byte behavior frozen.
- Independent filter/Adam7 wire fixtures, hostile/resource regressions, and portable full-package qualification.

### What Worked

- Red-green testing exposed the two real Adam7 seams before implementation: profile admission and final lane storage.
- Independent fixed wire data prevented the encoder and decoder from sharing an invalid oracle.

### What Was Inefficient

- Orphaned Moon build/test processes and zero-byte locks delayed the full native package run; explicit process ownership checks were needed before safe recovery.

### Patterns Established

- A high-precision representation profile may reuse all transport, filter, and Adam7 traversal state while changing only the final component-byte store.
- Full target evidence must retain the ordinary package command; stale local build state is recovered separately, never hidden behind wrappers.

### Key Lessons

1. Treat an interrupted test process as an artifact owner until its PID and parent are verified.
2. Preserve legacy lossy façades explicitly when adding opt-in fidelity contracts.
3. Archive phase artifacts immediately after verified milestone completion to keep active planning small.

### Cost Observations

- The ordinary PNG package completed at 235/235 on wasm, wasm-gc, js, and native.

---

## Milestone: v0.21 — RGBA16 PNG Decode

**Shipped:** 2026-07-23
**Phases:** 4 | **Plans:** 4 | **Tasks:** 9

### What Was Built

- A checked packed little-endian U16 `rgba16` representation with explicit straight-alpha encoded-sRGB identity.
- Additive eager and caller-buffered Type-6/16 PNG selectors that preserve every source component lane while generic decoding remains RGBA8 high-byte projection.
- Independent all-filter and Adam7 wire fixtures, hostile terminal/resource qualification, and four-target package evidence.

### What Worked

- Reusing the existing bounded byte-fed decoder confined the implementation to profile admission, output accounting, and final lane storage.
- Fixed hand-authored PNG literals kept the encoder from becoming the decoder's oracle.
- Serial ordinary package runs produced clear 245/245 evidence on each supported target without introducing release wrappers or copied source trees.

### What Was Inefficient

- One hand-authored Adam7 fixture byte and one white-box feeder error path required red-green corrections before final qualification.

### Patterns Established

- A high-precision PNG decode profile can share framing, filtering, DEFLATE, and Adam7 traversal while varying only admission, result descriptor, accounting, and final component-byte store.

### Key Lessons

1. Preserve legacy lossy façades explicitly whenever an opt-in exact-fidelity decoder is added.
2. Separate authenticated-header codec limits from first-IDAT caller-owned resource leases in boundary tests.
3. Archive phase artifacts at each milestone close; do not leave active planning directories behind.

### Cost Observations

- The ordinary PNG package completed at 245/245 on wasm, wasm-gc, js, and native.

---

## Milestone: v0.28 — Indexed PNG Compression Profiles

**Shipped:** 2026-07-24  
**Phases:** 3 | **Plans:** 3 | **Tasks:** 7

### What Was Built

- Additive non-interlaced Indexed1/2/4/8 `Stored` and `FixedOrStored` selectors with literal legacy Stored forwards and fail-closed Dynamic rejection.
- Palette-aware PLTE/tRNS frame facts, exact output/work limits, and one-charge admission through the established acknowledged machine.
- Independent hostile-stream qualification covering lease schedules, sticky terminals, Type-3/DEFLATE/CRC/Adler/raster parsing, public decode, frozen vectors, and all four targets.

### What Worked

- Keeping the implementation on the existing bounded producer and acknowledged machine made the capability additive and prevented a second encoder path.
- Test-local parsers and a local corpus protected the wire contract without relying on production planning helpers as an oracle.
- Named target gates plus the aggregate `--target all` run provided a compact, reproducible portability signal.

### What Was Inefficient

- Automatic accomplishment extraction surfaced deviation notes instead of shipped outcomes; the milestone entry was curated during closeout.
- The aggregate target run initially waited on a shared Moon build lock and needed a longer retry, so parallel target invocations should remain bounded and observable.

### Patterns Established

- Indexed compression selection compares complete palette-aware frame facts, not only IDAT payload size.
- Hostile caller schedules retain sentinel owners and append only accepted prefixes; replay-work drift is tested at the private seam.
- Phase directories are archived immediately after verified milestone completion, keeping the active planning tree small.

### Key Lessons

1. Preserve compatibility by making new compression profiles explicit and keeping legacy constructors literal forwards.
2. Independent wire/decode evidence is worth the extra test code when compression and packed-row contracts interact.
3. Milestone closeout should correct generated summaries and stale project state before deleting the active requirements file.

### Cost Observations

- Model mix and session count are not captured by the local GSD runtime.
- The final ordinary PNG gate was 315/315 per declared target; the main cost was cross-target qualification and independent oracle coverage.

---

## Milestone: v0.29 — Indexed Adam7 Compression Profiles

**Shipped:** 2026-07-24  
**Phases:** 3 | **Plans:** 3 | **Tasks:** 3

### What Was Built

- Additive Adam7 Indexed1/2/4/8 `Stored` and `FixedOrStored` selectors over the existing bounded eager and acknowledged caller-buffered machines.
- Pass-aware exact preflight for palette/tRNS-aware frame facts, work limits, and one-charge atomic admission.
- Independent hostile-lease, wire, decode, and four-target qualification for Fixed winners and Stored fallbacks.

### What Worked

- Reusing the established producer and acknowledgement lifecycle kept the change additive and avoided a second encoder or staging tree.
- A small independent parser plus public decode checks proved seven-pass framing, packed tails, Adler/CRC, PLTE/tRNS canonicalisation, and RGB8/RGBA8 results without trusting production planning helpers.
- Closing the milestone immediately archived all phase artifacts and left the active planning tree ready for the next code-first cycle.

### What Was Inefficient

- Earlier work had accumulated temporary phase/debug directories; keeping qualification on one shared machine and archiving at closeout avoids repeating that residue.

### Key Lessons

1. Adam7 compression selection must remain pass-aware while sharing one bounded replay owner across eager and chunked APIs.
2. Hostile lease schedules and independent wire/decode checks are the shortest reliable proof for a streaming codec contract.
3. Closeout should archive phase artifacts and remove the active requirements file so the next milestone starts with a small, unambiguous planning surface.

### Cost Observations

- The ordinary PNG package completed at 320/320 on wasm, wasm-gc, js, and native; no release automation or source-tree copies were added.

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|---|---:|---:|---|
| v0.1 | 5 | 41 | Established RFC-led horizontal delivery, independent verification, and closed release evidence. |
| v0.8 | 3 | 5 | Added byte-resumable public PNG decode with corpus-wide four-target streaming evidence. |
| v0.15 | 3 | 3 | Extended the bounded PNG profile path to U16 grayscale with wire-level portability evidence. |
| v0.17 | 3 | 4 | Extended the same bounded profile path to U16 Gray+Alpha with explicit type-4 wire and lease ownership evidence. |
| v0.19 | 3 | 5 | Extended that bounded profile path to GrayAlpha8 Adam7 with shared replay integrity and independent portable evidence. |
| v0.20 | 3 | 3 | Added opt-in high-precision GrayAlpha16 decode while retaining generic RGBA8 and one bounded machine. |
| v0.21 | 4 | 4 | Added opt-in Type-6/16 RGBA decode with exact U16 lanes, chunk parity, and portable qualification. |
| v0.28 | 3 | 3 | Added bounded indexed Fixed-or-Stored compression with independent hostile-stream and four-target qualification. |
| v0.29 | 3 | 3 | Extended the bounded indexed profile contract to Adam7 with pass-aware admission and independent hostile-stream qualification. |

### Cumulative Quality

| Milestone | Required tests | Requirements | Integration |
|---|---:|---:|---:|
| v0.1 | 197/197 per required target at the locked baseline | 36/36 | 15/15 contract families, 6/6 flows |
| v0.8 | 84/84 PNG tests per target | 4/4 | 6/6 phase handoffs, 2/2 public flows |
| v0.15 | 190/190 PNG tests per target | 3/3 | 3/3 phase verifications, 100/100 milestone audit |
| v0.17 | 204/204 PNG tests per target | 4/4 | 3/3 phase verifications, 5/5 handoffs, 3/3 flows |
| v0.19 | 227/227 PNG tests per target | 3/3 | 3/3 phase verifications, 100/100 integration, 4/4 flows |
| v0.20 | 235/235 PNG tests per target | 3/3 | 3/3 phase verifications, 100/100 integration, 4/4 flows |
| v0.21 | 245/245 PNG tests per target | 4/4 | 4/4 phase verifications, 5/5 integration links, 2/2 public flows |
| v0.28 | 315/315 PNG tests per target | 5/5 | 3/3 phase verifications, no open artifact records |
| v0.29 | 320/320 PNG tests per target | 5/5 | 3/3 phase verifications, no open artifact records |

### Top Lessons

1. Preserve exact policy ownership and fail-closed negatives as the ecosystem grows.
2. Re-check these lessons after the next milestone before treating them as cross-milestone invariants.
