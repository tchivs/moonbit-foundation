# Phase 106: Cubic Path and Public/TTC Integration - Context

**Gathered:** 2026-07-29
**Status:** Ready for planning
**Mode:** Smart Discuss (`--auto`; recommended choices pre-authorized by user)

<domain>
## Phase Boundary

Publish already-admitted static CFF1 fonts through the existing opaque `Font` and `FontCollection` workflows and return complete native cubic `Path2` outlines. This phase connects the verified Phase 104/105 CFF facts and Type 2 VM to public, format-neutral APIs; it does not widen the supported CFF profile, add CFF2/variation execution, retain paths at admission, or perform Phase 107 licensed/performance/four-target qualification.

</domain>

<decisions>
## Implementation Decisions

### Existing Public Contract and Private Dispatch
- **D-01:** Keep `Font::open`, `FontCollection::open_face`, and `Font::outline(GlyphId, Budget) -> Result[Path2, CoreError]` as the sole public workflows. Do not add a CFF-specific font, glyph, metric, or outline API.
- **D-02:** Dispatch privately through the existing closed `FontOutlineSource::Glyf | Cff1(AdmittedCff1)` boundary. Public callers must not observe CFF INDEX, DICT, FDSelect, subroutine, width, or execution-environment types.
- **D-03:** A `GlyphId` remains an opaque numeric GID owned by the receiving `Font`; Unicode mapping, glyph range checks, and kerning lookup use the same public operations and ordering for glyf and CFF1.

### Cubic Path Fidelity
- **D-04:** Reuse the Phase 105 Type 2 interpreter and operator/frame semantics through a path-capable geometry sink. Do not create a second interpreter and do not retain or replay an admission-time command stream.
- **D-05:** Emit native `PathCommand::MoveTo`, `LineTo`, `CubicTo(control1, control2, end)`, and `Close` commands. Never approximate Type 2 cubics as quadratics and never flatten curves.
- **D-06:** Apply the effective exact Top/FD FontMatrix and design-unit normalization before emission, keep coordinates exact through VM/sink arithmetic, and convert to `Point2` `Double` values only at the `Path2` boundary using one deterministic checked conversion rule.
- **D-07:** Preserve Phase 105 contour semantics: a new moveto closes the prior geometric contour and legal endchar closes the final geometric contour. A glyph with no drawing segments returns an empty `Path2`; move-only contours must not create misleading public bounds.

### Atomic Query and Resource Authority
- **D-08:** A CFF outline query executes only the selected admitted glyph with fresh operand, transient, frame, PRNG, and path state. Admission still retains compact bounds and immutable execution facts, never full paths.
- **D-09:** Guard the retained source revision before execution and before return. Stage the complete path and its exact named VM/path charge, preflight caller and ancestor authority, perform the final revision guard, then commit once and publish; any failure returns no `Path2` and leaves the query transaction uncommitted.
- **D-10:** Account for real path-command storage and any sink scratch allocation, including largest single allocation and backing-store capacity. Hidden `Array` growth must not exceed charged authority; a minimal format-neutral capacity-aware `Path2` construction seam is allowed if required.
- **D-11:** Reuse the admitted glyph descriptor, global/local subroutine views, matrix, limits, and deterministic initial state. Query execution must not reparse CFF structure, change admission results, or use retained bounds as a substitute for emitting geometry.

### Standalone and TTC/OTC Admission
- **D-12:** Route a supported standalone `OTTO` + static CFF1 profile into the existing complete CFF admission transaction before any glyf-only semantic commit. Construct the public `Font` only from the complete post-ledger `AdmittedCff1`.
- **D-13:** Extend `FontCollection::open_face` to accept the already-classified static `FontFaceProfile::Cff` case and call the same selected-face CFF admission using the retained collection root, face directory start, and expected table count.
- **D-14:** Preserve root-relative TTC/OTC table-record authority and table-local CFF offsets without copying the selected face. Shared CFF bytes may coexist with face-local common tables; CFF2, variable, mixed, and other unsupported profiles remain rejected.

### Format-Neutral Metrics, Errors, and Compatibility
- **D-15:** CFF-backed `Font` retains the same common `head`, `hhea`, `OS/2`, `cmap`, `hmtx`, and `kern` facts as glyf-backed fonts. Horizontal metrics use face-local `hmtx` plus the retained CFF bounds slot; Type 2 width remains validation-only.
- **D-16:** Preserve public operation names, `CoreError` category/code behavior, mutation precedence, and glyph-range behavior. Stable CFF-specific diagnostic contexts may remain internal details, but no new public error enum or CFF inspection surface is introduced.
- **D-17:** Existing static-glyf standalone and collection admission, metrics, mappings, kerning, outline commands, error ordering, and exact resource charges stay on their current branch and must be frozen by compatibility tests.
- **D-18:** Reuse existing `FontLimits` and `Budget`; do not add public CFF or Type 2 limit types in this phase.

### the agent's Discretion
- Exact private sink/protocol type names, file boundaries, and whether path capacity is provided by a small `mb-core` constructor or a private staged-command assembler.
- Exact fixed work-unit constants for path emission, provided they are stable, independently testable, and charge real execution/allocation.
- Test fixture organization between standalone CFF, collection CFF, public integration, and frozen glyf compatibility suites.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and Phase Contracts
- `.planning/PROJECT.md` — v0.34 public CFF1/`Path2` milestone boundary and exclusions.
- `.planning/ROADMAP.md` — Phase 106 goal and four success criteria.
- `.planning/REQUIREMENTS.md` — CFF-04 and CFF-05 normative requirements.
- `.planning/STATE.md` — carried-forward v0.34 integration and compatibility decisions.
- `.planning/phases/104-cff1-profile-and-bounded-data-model/104-CONTEXT.md` — locked static profile, collection coordinate spaces, and private admission boundary.
- `.planning/phases/104-cff1-profile-and-bounded-data-model/104-VERIFICATION.md` — verified structural handoff.
- `.planning/phases/105-bounded-type-2-validation-and-retained-metrics/105-CONTEXT.md` — locked VM, matrix, contour, bounds, metrics, resource, and error semantics.
- `.planning/phases/105-bounded-type-2-validation-and-retained-metrics/105-VERIFICATION.md` — verified Type 2/all-glyph handoff.
- `.planning/phases/105-bounded-type-2-validation-and-retained-metrics/105-REVIEW-FINAL.md` — final clean resource/arithmetic review.

### Milestone Research
- `.planning/research/SUMMARY.md` — recommended CFF architecture and phase sequencing.
- `.planning/research/ARCHITECTURE.md` — VM/sink, public font, and collection integration seams.
- `.planning/research/FEATURES.md` — public behavior and compatibility matrix.
- `.planning/research/PITFALLS.md` — integration, resource, mutation, and compatibility failure modes.

### Normative External Specifications
- [Adobe Technical Note #5177 — Type 2 Charstring Format](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf) — cubic operators and contour termination semantics already locked in Phase 105.
- [OpenType CFF table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff) — CFF1 glyph identity and OpenType integration.
- [OpenType `hmtx`](https://learn.microsoft.com/en-us/typography/opentype/spec/hmtx) — authoritative horizontal metrics.
- [OpenType Collections](https://learn.microsoft.com/en-us/typography/opentype/spec/otff#ttc-header) — TTC/OTC root-relative face/table authority.

### Existing Implementation
- `modules/mb-core/math/path.mbt` — public `Path2`, native cubic command model, and current append-only storage.
- `modules/mb-font/font/font.mbt` — opaque `Font`, closed outline-source enum, standalone open path, common queries, and atomic outline return seam.
- `modules/mb-font/font/collection.mbt` — public collection profile and selected-face admission routing.
- `modules/mb-font/font/collection_parser.mbt` — retained face profiles and root-relative directory authority.
- `modules/mb-font/font/cff_admission.mbt` — complete standalone/collection CFF admission and retained `AdmittedCff1`.
- `modules/mb-font/font/cff_type2.mbt` — sole deterministic Type 2 VM and all-glyph staging.
- `modules/mb-font/font/cff_type2_bounds.mbt` — geometry/matrix/contour sink semantics to generalize without divergence.
- `modules/mb-font/font/outline.mbt` — existing glyf `Path2` lowering and resource patterns that must remain unchanged.
- `modules/mb-font/font/metrics.mbt` — common/glyf metric index plus CFF `hmtx` and retained-bounds helpers.
- `modules/mb-font/font/tables.mbt` — shared common-table facts and atomic admission ledger.
- `modules/mb-core/budget/budget.mbt` — caller/ancestor preflight and commit authority.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FontOutlineSource::Cff1(AdmittedCff1)` already forms the closed private promotion boundary; only construction and query dispatch are missing.
- `Font::outline_after_decode` already provides pre/post revision guards and a no-partial-return public seam.
- `Path2` already exposes `CubicTo` and is consumed format-neutrally by canvas, SVG, and font clients.
- `Type2BoundsSink` already computes the exact relative line/cubic coordinates, effective transform, contour lifecycle, and resource counters needed by a shared path sink.
- `admit_cff1_structure*` already converges standalone and selected-collection authority into one complete transaction.

### Established Patterns
- Caller-owned bytes are retained without copying and guarded by mutation revisions before publication.
- Parsing/admission stages exact authority and commits once; public values are opaque and format-specific facts stay private.
- Common tables own mapping, line metrics, `hmtx`, and legacy kerning; outline format is a closed private branch.
- Public `Path2` geometry is append-only, and glyf lowering emits explicit Move/Quad/Close commands after bounded preflight.
- Hostile failures use stable State → Resource → Capability → Data precedence and publish no partial value.

### Integration Points
- Generalize the Type 2 geometry seam so bounds admission and path emission share one VM/operator implementation.
- Add a CFF-backed `Font` constructor that retains canonical common-table/query facts plus complete `AdmittedCff1`.
- Branch `Font::open` and `FontCollection::open_face` at the supported outline profile without disturbing the glyf branch.
- Branch `Font::outline` and horizontal-metric bounds lookup on `FontOutlineSource`.
- Add exact capacity/charge authority for `Path2` construction before any public CFF geometry is returned.

</code_context>

<specifics>
## Specific Ideas

- A cubic CharString should produce visibly native `CubicTo(c1, c2, end)` commands with the transformed control points preserved exactly until the final `Point2` conversion.
- Standalone and TTC/OTC copies of the same CFF face should have equal mappings, metrics, kerning, and path commands while retaining different correct root/table coordinate spaces internally.
- Deliberately mismatched Type 2 width and `hmtx` fixtures should continue proving that public advances and side bearings never come from CharString width.
- Frozen glyf fingerprints should cover standalone and collection open, mapping, metrics, kerning, paths, errors, and budget counters before and after the new dispatch.

</specifics>

<deferred>
## Deferred Ideas

- Phase 107 owns licensed Latin/CJK assets, generated/hostile matrix completion, performance baselines, independent oracles, and exact four-target qualification.
- CFF2/variation execution, deprecated seac composition, WOFF, shaping/bidi, hint rendering, rasterization, color/bitmap glyphs, authoring, discovery, and ambient I/O remain outside v0.34.

</deferred>

---

*Phase: 106-cubic-path-and-public-ttc-integration*
*Context gathered: 2026-07-29*
