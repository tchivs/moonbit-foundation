---
quick_id: 260726-toy
phase: quick-260726-toy
plan: 01
description: Preserve fixture manifest ordering during color vector regeneration
type: execute
wave: 1
depends_on: []
autonomous: true
files_modified:
  - "scripts/fixtures/Generate-ColorVectors.ps1"
must_haves:
  truths:
    - "Color regeneration replaces its two owned manifest records at their existing positions instead of moving unrelated records."
    - "Every unrelated manifest record retains its relative order and serialized identity."
    - "Duplicate owned color record IDs fail closed; absent owned records are inserted deterministically."
    - "One generation is byte-identical to a second generation, and `-Artifacts all -Check` passes."
    - "The COLR deterministic generated-evidence stage no longer reports fixtures/manifest.json stale."
  artifacts:
    - path: "scripts/fixtures/Generate-ColorVectors.ps1"
      provides: "Position-preserving, idempotent color manifest regeneration"
    - path: ".planning/quick/260726-toy-preserve-fixture-manifest-ordering-durin/260726-toy-SUMMARY.md"
      provides: "Generator idempotence and COLR-stage evidence"
  key_links:
    - from: "scripts/fixtures/Generate-ColorVectors.ps1"
      to: "fixtures/manifest.json"
      via: "Render-Manifest substitutes owned records in-place and preserves foreign record order"
      pattern: "color-srgb-reference-vectors|color-derived-edge-vectors"
---

<objective>
Make Color fixture regeneration composable with other fixture generators by preserving manifest record order.

Purpose: Required qualification currently reaches COLR generation and fails only because the Color generator removes its records and appends them after the later SVG record. The record data and digests are already correct.

Output: One atomic generator commit and a complete quick summary with byte-level idempotence and focused COLR evidence.
</objective>

<execution_context>
@C:/Users/Admin/.codex/gsd-core/workflows/execute-plan.md
@C:/Users/Admin/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@AGENTS.md
@.planning/STATE.md
@scripts/fixtures/Generate-ColorVectors.ps1
@fixtures/manifest.json
@.planning/quick/260726-sss-make-the-mb-core-narrowing-prohibition-t/260726-sss-PLAN.md

A detached regeneration at commit 69d2f9c changed only fixtures/manifest.json. Its 24-line diff moved the unchanged `svg-subset-conformance-vectors` record before the two unchanged Color records because Render-Manifest filters Color records and appends replacements. No fixture bytes, record fields, or digests changed.

This quick runs only in branch worktree `codex/quick-260726-sss`. It must not edit the dirty main checkout, PNG sources, sss summary/state, Phase 97 tracking, or historical worktrees.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Replace owned Color manifest records in place</name>
  <files>scripts/fixtures/Generate-ColorVectors.ps1</files>
  <action>
Refactor Render-Manifest to construct the two canonical owned Color records once, then walk the existing record array in order. Copy every foreign record through unchanged. At each owned ID, emit its canonical replacement at that same index and record that the ID was seen.

Reject duplicate occurrences of either owned ID with an ID-specific fail-closed error. After the walk, append any missing owned records in the canonical order `color-srgb-reference-vectors`, then `color-derived-edge-vectors`; this preserves current ordering while keeping bootstrap generation deterministic. Do not globally sort records and do not alter top-level schema fields or record field order.

Extract a production `Merge-ColorManifestRecords` helper that accepts an in-memory record array plus the two canonical replacement records and returns the merged array without file I/O. Render-Manifest must call this helper.

Add a guarded `-ManifestSelfTest` script switch that may be invoked without `-Artifacts`; otherwise retain an explicit fail-closed requirement for `-Artifacts`. The self-test must call the production merge helper with in-memory fixtures and assert:

- duplicate `color-srgb-reference-vectors` and duplicate `color-derived-edge-vectors` each fail with their exact ID in the error;
- both missing owned IDs are appended in canonical Color order;
- one missing owned ID is inserted without moving the present owned or foreign records;
- foreign record object identity/order and serialized field values are unchanged;
- a complete canonical input is byte/logically idempotent.

Print `Color manifest self-test passed.` only after every assertion succeeds. Keep the change inside this script.
  </action>
  <verify>
Run the production no-write seam exactly:

`pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -ManifestSelfTest`

Require exit 0 and `Color manifest self-test passed.`.

Then run this exact fail-fast two-pass artifact check from a disposable exact checkout:

`pwsh -NoProfile -Command '$ErrorActionPreference="Stop"; $files=@("fixtures/color/srgb-reference-vectors.json","fixtures/color/derived-edge-vectors.json","fixtures/manifest.json","modules/mb-color/transfer/reference_vectors_wbtest.mbt","modules/mb-color/quantize/reference_vectors_wbtest.mbt","modules/mb-color/alpha/reference_vectors_wbtest.mbt","modules/mb-color/profile/reference_vectors_wbtest.mbt"); function Snapshot { @($files | ForEach-Object { "$_=$((Get-FileHash -Algorithm SHA256 -LiteralPath $_).Hash)" }) }; $before=Snapshot; & pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts all; if($LASTEXITCODE -ne 0){throw "first generation failed"}; $first=Snapshot; if(Compare-Object $before $first){throw "first generation changed canonical artifacts"}; & pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts all; if($LASTEXITCODE -ne 0){throw "second generation failed"}; $second=Snapshot; if(Compare-Object $first $second){throw "second generation was not idempotent"}; & pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts all -Check; if($LASTEXITCODE -ne 0){throw "generated artifact check failed"}'`

Require exit 0 and no working-tree diff in the seven listed artifacts. Run `git diff --check`.
  </verify>
  <done>Color generation is byte-idempotent on the canonical repository and cannot reorder unrelated manifest records.</done>
</task>

<task type="auto">
  <name>Task 2: Prove the focused COLR gate and record the quick</name>
  <files>.planning/quick/260726-toy-preserve-fixture-manifest-ordering-durin/260726-toy-SUMMARY.md</files>
  <action>
Run the exact COLR generator command used by Required with `-Artifacts all -Check`. Also run fixture-policy validation to prove record schema, paths, digests, and containment still pass. Confirm a clean checkout at the source commit produces no manifest diff after generation.

Commit only scripts/fixtures/Generate-ColorVectors.ps1 with `260726-toy` in the subject. Write SUMMARY.md with `status: complete`, the source commit, before/after manifest hashes, two-pass idempotence evidence, focused COLR check, and fixture-policy result. Do not commit SUMMARY or update STATE; the orchestrator owns post-execution verification and tracking.
  </action>
  <verify>
`Generate-ColorVectors.ps1 -Artifacts all -Check` exits zero; `scripts/quality/Test-FixturePolicy.ps1` exits zero; `git diff --exit-code -- fixtures/manifest.json fixtures/color modules/mb-color/*/reference_vectors_wbtest.mbt` exits zero after regeneration; SUMMARY frontmatter is complete.
  </verify>
  <done>The exact stage that blocked Required is green and the quick is ready for independent verification.</done>
</task>

</tasks>

<verification>
- Current canonical manifest bytes do not change on first or second Color regeneration.
- Foreign record order and identity are preserved.
- Duplicate owned IDs fail closed and missing owned IDs insert deterministically.
- Focused COLR generation check and fixture-policy matrix pass.
</verification>

<success_criteria>
- `fixtures/manifest.json` is no longer reported stale by Color generation.
- The generator remains deterministic from both complete and missing-owned-record inputs.
- No non-owned manifest record or unrelated source file changes.
</success_criteria>

<output>
After completion, create `.planning/quick/260726-toy-preserve-fixture-manifest-ordering-durin/260726-toy-SUMMARY.md`.
</output>
