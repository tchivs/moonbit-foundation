---
quick_id: 260726-uhq
phase: quick-260726-uhq
plan: 01
description: Scope the image floating prohibition to geometry mapping while allowing typed color math
type: execute
wave: 1
depends_on: []
autonomous: true
files_modified:
  - "scripts/quality/Invoke-MoonQuality.ps1"
must_haves:
  truths:
    - "Image geometry and source-index mapping remain checked UInt64 operations with no floating conversion or backend rounding."
    - "Only the audited Phase 10 box-blur color average and i66 bilinear blend fractions may use Double/to_double in production ops."
    - "Any new Double, to_double, inferred decimal/exponent literal, round, floor, or ceil token outside the exact audited inventory fails closed."
    - "Public image operation signatures cannot introduce Double geometry parameters."
    - "The existing image negative matrix and a dedicated no-write floating-policy self-test pass."
    - "Current processing and bilinear implementations remain unchanged and pass on all four targets."
  artifacts:
    - path: "scripts/quality/Invoke-MoonQuality.ps1"
      provides: "Exact audited image-ops floating policy plus production self-test"
    - path: ".planning/quick/260726-uhq-scope-the-image-floating-prohibition-to-/260726-uhq-SUMMARY.md"
      provides: "Policy inventory, negative matrix, and ops target evidence"
  key_links:
    - from: "scripts/quality/Invoke-MoonQuality.ps1"
      to: "modules/mb-image/ops/processing.mbt"
      via: "Exactly four typed linear-premultiplied box-window normalizations are admitted"
      pattern: "window[.]to_double"
    - from: "scripts/quality/Invoke-MoonQuality.ps1"
      to: "modules/mb-image/ops/resize.mbt"
      via: "Only checked remainder/extent fractions and private blend parameters are admitted"
      pattern: "remainder_[xy][.]to_double"
---

<objective>
Repair the stale file-wide image floating prohibition so it enforces the actual geometry contract without rejecting later, verified typed color math.

Purpose: Required now passes CORE, COLR, and IMAG generation, but the Phase 4 raw regex rejects Phase 10 box blur before reaching the likewise intentional i66 bilinear blend. Historical locked decisions require integer geometry/indexing while explicitly allowing bounded remainder fractions and linear-premultiplied color arithmetic.

Output: One atomic quality-policy commit and a verified quick summary; no image algorithm change.
</objective>

<execution_context>
@C:/Users/Admin/.codex/gsd-core/workflows/execute-plan.md
@C:/Users/Admin/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@AGENTS.md
@.planning/STATE.md
@scripts/quality/Invoke-MoonQuality.ps1
@modules/mb-image/ops/processing.mbt
@modules/mb-image/ops/resize.mbt
@.planning/milestones/v0.4-phases/10-alpha-correct-pixel-processing/10-01-PLAN.md
@.planning/milestones/legacy-quick/260721-i66-add-deterministic-alpha-correct-bilinear/260721-i66-PLAN.md

The legacy rule rejects any Double/to_double/round/floor/ceil token in every ops production file. Current audited production inventory is:

- processing.mbt: four `window.to_double()` divisors that average premultiplied linear RGB and alpha in box_blur;
- processing.mbt: exactly nine inferred Double literals, all scoped to typed color/alpha math: `1.0` in `load_linear_premultiplied`, `1.0` in `composite_source_over`, Rec.709 `0.2126`/`0.7152`/`0.0722` in `grayscale`, and four `0.0` accumulators in `box_blur`;
- resize.mbt: private `x_fraction : Double` and `y_fraction : Double`, plus exact `remainder_y / height` and `remainder_x / width` conversions used only after `bilinear_source_coordinate` returns checked integer low/high/remainder facts;
- resize.mbt and every coordinate/index helper: zero decimal/exponent literals;
- every other ops production file: zero floating tokens or decimal/exponent literals.

i66 explicitly locks: checked integer products/quotient/remainder for geometry, convert only bounded remainder/destination extent to Double for blending, and never use floating point for geometry/indexing.

Run only in the isolated codex/quick-260726-sss worktree. Do not modify image sources, dirty main, sss summary/state, PNG work, Phase 97, or historical worktrees.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Enforce an exact audited image floating-policy inventory</name>
  <files>scripts/quality/Invoke-MoonQuality.ps1</files>
  <action>
Extract `Assert-ImageOpsFloatingPolicy(RelativePath, Text)` and call it from `Assert-ImageSourceTextProhibitions` for ops production sources.

The helper must first reject every `round`, `floor`, or `ceil` call in every ops file. It must then admit only these anchored semantic forms, with exact cardinality:

- processing.mbt: one each of `rr / window.to_double()`, `gg / window.to_double()`, `bb / window.to_double()`, and `aa / window.to_double()` as arguments to the established typed LinearSrgbComponent/NormalizedAlpha constructors; no explicit `Double` token and no other `to_double`;
- processing.mbt: exactly the nine decimal literals in the audited typed color/alpha expressions: `NormalizedAlpha::new(1.0)` in `load_linear_premultiplied`, `let factor = 1.0 - sa` in `composite_source_over`, the single Rec.709 luminance expression with coefficients `0.2126`, `0.7152`, and `0.0722` in `grayscale`, and the four named `rr`/`gg`/`bb`/`aa` `= 0.0` accumulators in `box_blur`;
- resize.mbt: exactly one private `x_fraction : Double`, one private `y_fraction : Double`, one `let y_fraction = remainder_y.to_double() / height.to_double()`, and one `let x_fraction = remainder_x.to_double() / width.to_double()`; no other Double/to_double;
- resize.mbt and any other ops path: zero decimal or exponent literals, and any other ops path also has zero Double/to_double.

Implement this conservatively by matching/removing the full anchored allowed forms from a copy of the text, verifying each expected form occurs exactly once in its canonical file, then rejecting any residual `Double`, `.to_double(`, or inferred floating literal. The literal detector must cover decimal and exponent spellings, including `0.5`, `1.`, `.5`, `1e3`, and `1.0e-3`, with token boundaries that do not misclassify identifiers. Missing, duplicate, moved-to-another-file/function, renamed, wrong-axis paired, or extra forms all fail with path-specific messages. The exact inventory inherently keeps public signatures free of Double; add an explicit public-declaration Double rejection as defense in depth.

Replace the old file-wide regex, but retain the existing `floating resize` negative fixture through the production helper.

Add an `-ImageFloatingPolicySelfTest` top-level switch usable without `-Lane`. The self-test must exercise the production helper with:

- positive canonical processing and resize snippets;
- a non-floating identifier-boundary control such as `value1e3` that must pass without being misclassified as an exponent literal;
- floating nearest/coordinate mapping using floor;
- public Double geometry;
- unauthorized to_double in another ops file;
- one extra processing normalization;
- missing required processing or resize form;
- Double/to_double form moved to the wrong canonical file;
- both explicit wrong-axis failures: `remainder_x.to_double() / height.to_double()` and `remainder_y.to_double() / width.to_double()`;
- parameterized geometry-mapping literals covering every required lexical spelling: `0.5`, `1.`, `.5`, `1e3`, and `1.0e-3`;
- an extra, missing, or moved typed-color decimal literal.

Each negative must match its expected policy-specific error, not merely any exception. Print `Image floating policy self-test passed.` only after all cases pass. Preserve the existing CoreNarrowingSelfTest dispatch and normal required-Lane behavior.
  </action>
  <verify>
Run:

`pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -ImageFloatingPolicySelfTest`

Require exit 0 and the exact success marker. Invoke the production image portable prohibition and image negative matrix through the smallest guarded production seam; if necessary, extend the same self-test switch to call those two existing functions after the focused fixtures, but do not run the full Required lane in this task.

Run the ops suite:

`pwsh -NoProfile -Command '$ErrorActionPreference="Stop"; foreach($target in @("js","wasm","wasm-gc","native")) { & moon -C modules/mb-image test ops --target $target --frozen; if($LASTEXITCODE -ne 0){throw "mb-image ops $target failed"} }'`

Require all targets green. Run `git diff --check`.
  </verify>
  <done>The production policy accepts only the audited color-blending inventory and rejects every floating geometry/indexing escape.</done>
</task>

<task type="auto">
  <name>Task 2: Record focused policy and target evidence</name>
  <files>.planning/quick/260726-uhq-scope-the-image-floating-prohibition-to-/260726-uhq-SUMMARY.md</files>
  <action>
Commit only scripts/quality/Invoke-MoonQuality.ps1 with `260726-uhq` in the subject. Write SUMMARY.md with `status: complete`, the exact admitted inventory, locked Phase10/i66 rationale, self-test/negative matrix results, four-target ops counts, and source commit. Do not commit SUMMARY or edit STATE.
  </action>
  <verify>The source commit changes one file, no image source changes, all focused evidence is recorded, and the isolated worktree contains only untracked SUMMARY.</verify>
  <done>The stale quality rule is repaired without weakening integer geometry or changing image behavior.</done>
</task>

</tasks>

<verification>
- Exact processing and resize blend forms pass; any inventory drift fails.
- Floating geometry, public Double, inferred decimal/exponent geometry literals, round/floor/ceil, and unauthorized conversions fail.
- Existing image portable and negative policy matrices pass.
- ops tests pass on js, wasm, wasm-gc, and native.
</verification>

<success_criteria>
- processing.mbt and resize.mbt no longer false-positive.
- No new floating geometry/indexing route can pass the production gate.
- Only the quality script is committed.
</success_criteria>

<output>
After completion, create `.planning/quick/260726-uhq-scope-the-image-floating-prohibition-to-/260726-uhq-SUMMARY.md`.
</output>
