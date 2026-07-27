---
quick_id: 260727-loc
phase: quick-260727-loc
plan: 01
description: Add deterministic mid-query revision drift tests for Phase 98 glyph and kerning post-read guards
type: tdd
wave: 1
depends_on: []
autonomous: true
gap_closure: true
requirements: [FONT-02, FONT-04]
files_modified:
  - "modules/mb-font/font/font.mbt"
  - "modules/mb-font/font/font_wbtest.mbt"
must_haves:
  truths:
    - "A deterministic white-box glyph query mutates the retained OwnedBytes after the admitted cmap lookup completes and before the post-read revision guard, then returns State/InvalidRange with operation `font-query` and context `font-source-revision-drift` instead of publishing a GlyphId, closing D-03."
    - "A deterministic white-box kerning query mutates the retained OwnedBytes after the admitted kern lookup completes and before the post-read revision guard, then returns State/InvalidRange with operation `font-query` and context `font-source-revision-drift` instead of publishing an adjustment."
    - "Each instrumentation callback executes exactly once on the successful lookup path; unchanged public calls retain their existing scalar, glyph-validation, kerning, error-taxonomy, allocation, and budget behavior."
    - "The complete font package passes on native, js, wasm, and wasm-gc with unique external target directories and `--no-parallelize`, per D-16."
    - "The generated `pkg.generated.mbti` remains byte-identical at SHA-256 `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade`; no hook, callback, raw cmap/kern fact, or other public API is added."
    - "The existing untracked Phase 98 verification report remains unmodified and untracked throughout execution."
  artifacts:
    - path: "modules/mb-font/font/font.mbt"
      provides: "Package-private deterministic after-lookup/before-post-guard query seam shared by the public glyph and kerning entry points"
    - path: "modules/mb-font/font/font_wbtest.mbt"
      provides: "Executable mid-query retained-source mutation regressions for glyph mapping and kerning"
    - path: "modules/mb-font/font/pkg.generated.mbti"
      provides: "Unchanged public semantic interface with the frozen pre-quick byte identity"
  key_links:
    - from: "modules/mb-font/font/font_wbtest.mbt"
      to: "modules/mb-font/font/font.mbt"
      via: "White-box tests call the package-private query seam with an OwnedBytes mutation callback"
      pattern: "after lookup -> mutate owner once -> require_revision -> Err"
    - from: "Font::glyph_for_scalar"
      to: "Font::require_revision"
      via: "The selected cmap lookup completes before the test seam fires, and opaque GlyphId construction occurs only after the second guard succeeds"
      pattern: "font_lookup_cmap -> after_lookup -> require_revision -> GlyphId"
    - from: "Font::kerning"
      to: "Font::require_revision"
      via: "Both opaque glyph IDs are validated and the kern lookup completes before the test seam fires; adjustment publication follows the second guard"
      pattern: "font_lookup_kern -> after_lookup -> require_revision -> adjustment"
    - from: "modules/mb-font/font/font.mbt"
      to: "modules/mb-font/font/pkg.generated.mbti"
      via: "`moon info --target all` regeneration must preserve the exact pre-quick interface bytes"
      pattern: "SHA-256 f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade"
---

<objective>
Close the Phase 98 verifier's sole 15/16 ordering-invariant gap with deterministic executable evidence for both guarded retained-source lookup paths.

Purpose: Static inspection proves the post-read guards are ordered correctly, but the current black-box tests mutate the source before synchronous query entry and therefore exercise only the pre-read guard. This plan makes the after-lookup/before-publication transition controllable in white-box tests without changing the public API.

Output: Two TDD white-box regressions and the smallest package-private query seam needed to trigger retained-source mutation between each admitted lookup and its post-read revision guard, implementing D-03 and D-16 while preserving the exact generated interface and the untracked verification report.
</objective>

<execution_context>
@C:/Users/Admin/.codex/gsd-core/workflows/execute-plan.md
@C:/Users/Admin/.codex/gsd-core/templates/summary.md
@C:/Users/Admin/.codex/gsd-core/references/tdd.md
</execution_context>

<context>
@AGENTS.md
@.planning/STATE.md
@.planning/phases/98-unicode-mapping-and-kerning/98-VERIFICATION.md
@.planning/phases/98-unicode-mapping-and-kerning/98-CONTEXT.md
@.planning/phases/98-unicode-mapping-and-kerning/98-01-SUMMARY.md
@.planning/phases/98-unicode-mapping-and-kerning/98-02-SUMMARY.md
@.planning/phases/98-unicode-mapping-and-kerning/98-03-SUMMARY.md
@modules/mb-font/font/font.mbt
@modules/mb-font/font/font_wbtest.mbt
@modules/mb-font/font/font_test.mbt

The canonical verifier found no implementation, wiring, policy, interface, requirement, or general behavior gap. Its only unverified truth is mutation after table reads begin and before the second `require_revision` call. Existing tests named `scalar query rejects retained source mutation before publication` and `kerning rejects retained source mutation before publication` mutate before invoking the public method and must remain as pre-read controls.

The worktree currently contains `.planning/phases/98-unicode-mapping-and-kerning/98-VERIFICATION.md` as an untracked file. It is evidence supplied to this quick and is outside task ownership: do not stage, commit, rewrite, delete, or normalize it.

<interfaces>
From `modules/mb-font/font/font.mbt`:
- `pub fn Font::glyph_for_scalar(self : Font, scalar : Int) -> Result[GlyphId, @error.CoreError]`
- `pub fn Font::kerning(self : Font, left : GlyphId, right : GlyphId) -> Result[Int, @error.CoreError]`
- `fn Font::require_revision(self : Font, operation : String) -> Result[Unit, @error.CoreError]`
- `font_revision_error("font-query")` yields category `State`, code `InvalidRange`, operation `font-query`, and context `font-source-revision-drift`.

The current glyph publication order is pre-read revision guard, scalar validation, `font_lookup_cmap`, post-read revision guard, then opaque `GlyphId` construction. The current kerning publication order is pre-read revision guard, receiving-font validation of both IDs, `font_lookup_kern`, post-read revision guard, then signed adjustment publication. Preserve those orders exactly while inserting only the package-private deterministic test seam between each lookup and its second guard.

From `modules/mb-font/font/font_wbtest.mbt` and `generated_fonts_wbtest.mbt`:
- `font_wb_view`, `font_wb_build_sfnt`, `font_wb_required_tables`, `font_wb_table`, `font_wb_kern_format0`, `generated_minimal_truetype`, and `font_wb_limits` are established white-box fixture assets.
- White-box tests may inspect private `Font`, `GlyphId`, cmap/kern facts, and package-private functions; black-box `font_test.mbt` remains the public API boundary.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Prove both post-read revision guards reject publication</name>
  <files>modules/mb-font/font/font.mbt, modules/mb-font/font/font_wbtest.mbt</files>
  <behavior>
    - RED glyph case: an admitted checksum-correct font starts a successful scalar lookup; an exactly-once callback mutates its retained OwnedBytes after `font_lookup_cmap` returns; the query must not return a GlyphId and must instead expose the stable State/InvalidRange `font-source-revision-drift` error.
    - RED kerning case: an admitted checksum-correct font with one supported version-0 format-0 pair starts a successful pair lookup; an exactly-once callback mutates its retained OwnedBytes after `font_lookup_kern` returns; the query must not return the signed adjustment and must instead expose the same stable revision-drift error.
    - Control case: the public `glyph_for_scalar` and `kerning` methods pass a no-op callback through the shared private implementation and preserve all existing successful and failing outcomes.
    - Interface case: neither the callback seam nor any helper it requires is public, so all-target interface regeneration is byte-identical to the frozen baseline.
  </behavior>
  <action>
Follow RED -> GREEN -> REFACTOR as one TDD feature closing the verifier's ordering gap.

RED: In `font_wbtest.mbt`, add a local OwnedBytes fixture helper and a bounded one-byte mutation helper following the existing `font_wb_view` ownership limits and `with_mut` lease pattern. Add two separately named white-box tests containing `post-read revision drift` in their names, one for `glyph_for_scalar` and one for `kerning`. Reuse the existing checksum-correct generated SFNT builders; build the kerning font from the existing required-table inventory plus one `font_wb_kern_format0` table, and use receiving-font glyph IDs created before the instrumented call. Each callback must increment an invocation counter, mutate the retained owner once, and leave the callback-observed counter at exactly one. Each test must require the query result to be `Err`, assert category `State`, code `InvalidRange`, operation `font-query`, and context `font-source-revision-drift`, and make an `Ok` result fail so neither a GlyphId nor an adjustment can be published.

Make the RED test compile and fail for the missing interleaving behavior rather than for syntax or an unresolved symbol: add package-private query adapters in `font.mbt` with exact callback-bearing signatures chosen once for the shared pattern, initially preserving current public behavior without invoking the callback. Do not mark either adapter `pub`, do not change an existing public signature, and do not duplicate cmap or kern parsing in the test. Run only the two new tests on native with a fresh external target directory and `--no-parallelize`; require both tests to execute and the run to fail because their queries still publish successful values. Commit the RED state with a `test(quick-260727-loc): ...` commit and do not include the untracked verification report.

GREEN: Move the existing glyph and kerning query bodies behind the package-private callback-bearing adapters, have the public methods delegate with a no-op callback, and invoke the callback exactly once only after the corresponding successful `font_lookup_cmap` or `font_lookup_kern` has returned and immediately before the existing second `require_revision("font-query")`. Keep scalar validation and receiving-font glyph validation before lookup; preserve early lookup errors; construct `GlyphId` and return the signed adjustment only after the post-read guard succeeds. This exact order implements D-03. Run the focused native tests again in a second fresh external target directory and require both to pass, then commit the GREEN state with a `feat(quick-260727-loc): ...` commit.

REFACTOR only if it removes duplication without widening visibility or weakening order. Retain one shared structural pattern for the two adapters, clear names that identify the after-lookup callback, existing public documentation semantics, and no new mutable global or target-specific code. Run the focused native tests after any refactor and commit only if source changes remain.

Qualification per D-16: after the focused native GREEN gate, run the entire `font` package independently on native, js, wasm, and wasm-gc, giving every invocation its own external target directory and `--no-parallelize`. Then hash `pkg.generated.mbti`, run `moon -C modules/mb-font info --target all --frozen` in another unique external target directory, hash the file again, and require both hashes to equal the frozen SHA-256 in `must_haves`. Require `git diff --exit-code` for that interface file, `git diff --check` for the two task-owned source files, and exact `??` status for the Phase 98 verification report. Do not stage the verification report or generated interface.
  </action>
  <verify>
    <automated>pwsh -NoProfile -Command '$ErrorActionPreference="Stop"; $root=Join-Path ([IO.Path]::GetTempPath()) ("mnf-phase98-post-read-"+[Guid]::NewGuid().ToString("N")); New-Item -ItemType Directory -Path $root | Out-Null; $focused=Join-Path $root "native-focused-final"; moon -C modules/mb-font test font --target native --frozen --target-dir $focused --no-parallelize -f "*post-read revision drift*"; if ($LASTEXITCODE -ne 0) { throw "Focused native post-read revision tests failed" }; foreach ($target in @("native","js","wasm","wasm-gc")) { $targetDir=Join-Path $root ("full-"+$target); moon -C modules/mb-font test font --target $target --frozen --target-dir $targetDir --no-parallelize; if ($LASTEXITCODE -ne 0) { throw "Full font package failed on $target" } }; $interface="modules/mb-font/font/pkg.generated.mbti"; $expected="f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade"; $before=(Get-FileHash -Algorithm SHA256 $interface).Hash.ToLowerInvariant(); if ($before -ne $expected) { throw "Interface baseline drifted before regeneration: $before" }; moon -C modules/mb-font info --target all --frozen --target-dir (Join-Path $root "info-all"); if ($LASTEXITCODE -ne 0) { throw "All-target interface generation failed" }; $after=(Get-FileHash -Algorithm SHA256 $interface).Hash.ToLowerInvariant(); if ($after -ne $before -or $after -ne $expected) { throw "Generated interface bytes changed: $before -> $after" }; git diff --exit-code -- $interface; if ($LASTEXITCODE -ne 0) { throw "Generated interface has a worktree diff" }; git diff --check -- modules/mb-font/font/font.mbt modules/mb-font/font/font_wbtest.mbt; if ($LASTEXITCODE -ne 0) { throw "Owned source diff check failed" }; $verification=".planning/phases/98-unicode-mapping-and-kerning/98-VERIFICATION.md"; $status=(git status --short -- $verification | Out-String).TrimEnd(); if ($status -ne "?? $verification") { throw "Phase 98 verification report was modified, staged, committed, or removed: $status" }'</automated>
  </verify>
  <done>Both deterministic white-box callbacks execute exactly once after their admitted lookup and before the post-read guard; each instrumented query returns the exact State/InvalidRange revision-drift error and publishes no value; public controls and the complete font package pass on all four targets; the generated interface retains SHA-256 `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade`; and the Phase 98 verification report remains untouched and untracked.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Retained caller-owned bytes -> admitted query | Caller-controlled OwnedBytes may change while a query reads table-local facts retained from admission. |
| White-box callback -> production query ordering | Test instrumentation executes inside a package-private seam and must prove the real lookup-to-publication boundary without becoming public runtime policy. |
| Private MoonBit source -> generated public interface | Internal refactoring must not leak callback types, raw table facts, or test controls through `pkg.generated.mbti`. |
| Dirty worktree -> task commits | The existing untracked Phase 98 verification report is evidence, not an implementation artifact owned by this quick. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-LOC-01 | Tampering | `Font::glyph_for_scalar` retained cmap read | high | mitigate | Invoke the deterministic callback only after successful cmap lookup and before the second revision guard; require the exact State/InvalidRange drift error and no GlyphId publication. |
| T-LOC-02 | Tampering | `Font::kerning` retained pair read | high | mitigate | Invoke the deterministic callback only after successful kern lookup and before the second revision guard; require the exact drift error and no adjustment publication. |
| T-LOC-03 | Repudiation | Test ordering evidence | medium | mitigate | Assert callback count equals one, use successful lookup fixtures, run focused native evidence first, and preserve the existing pre-call mutation tests as separate controls. |
| T-LOC-04 | Elevation of Privilege | Package-private instrumentation visibility | high | mitigate | Keep adapters and callback types non-public and require exact all-target generated-interface SHA-256 stability plus an empty interface diff. |
| T-LOC-05 | Denial of Service | Four-target qualification | medium | mitigate | Use package-scoped serial commands, `--no-parallelize`, and a distinct external target directory for every focused, full-target, and interface run. |
| T-LOC-06 | Information Disclosure | Test fixtures and diagnostics | low | accept | Fixtures are generated repository-local font bytes and stable structured errors; no secret or external user data crosses the seam. |
</threat_model>

<source_audit>

| Source | ID | Feature / Requirement | Task | Status | Notes |
|--------|----|-----------------------|------|--------|-------|
| GOAL | Phase 98 | Deterministic Unicode and kerning queries over the admitted font | 1 | COVERED | Adds the missing executable ordering proof while retaining all already verified query behavior |
| GOAL | Verifier 15/16 | Mutation after table reads begin and before result publication is rejected | 1 | COVERED | Both successful lookup paths receive deterministic after-lookup callbacks and exact no-publication assertions |
| REQ | FONT-02 | Deterministic scalar mapping with structured failure behavior | 1 | COVERED | Glyph post-read mutation becomes an executable State/InvalidRange regression |
| REQ | FONT-04 | Deterministic legacy kerning with distinguishable outcomes | 1 | COVERED | Kerning post-read mutation becomes an executable State/InvalidRange regression |
| RESEARCH | — | No quick-task RESEARCH.md was provided | — | N/A | Level 0 discovery is sufficient because the exact production guards, fixture builders, test framework, and target commands already exist |
| CONTEXT | D-03 | Pre-read and post-read retained-source revision guards prevent glyph publication on drift | 1 | COVERED | The glyph callback is placed after cmap lookup and before the second guard |
| CONTEXT | D-16 | White-box offset/ordering evidence, four targets, and minimal generated interface | 1 | COVERED | Native-first TDD, four full target runs, and exact interface byte stability are mandatory |
| CONTEXT | D-01-D-02, D-04-D-15 | Existing locked Phase 98 scalar, cmap, kern, admission, resource, and compatibility behavior | 1 | COVERED | No contract is reimplemented or reduced; the complete four-target font package is the regression gate |
| CONTEXT | Deferred Ideas | Phase 99 outlines, Phase 100 real-font qualification, shaping/GPOS/host behavior | — | EXCLUDED | Explicitly deferred and absent from task actions |
</source_audit>

<verification>
1. RED: run only the two new `post-read revision drift` white-box tests on native in a fresh external target directory; require an executable behavioral failure showing the callback interleaving is not yet honored.
2. GREEN: rerun those two tests on native in another fresh external target directory; require both exact drift/no-publication cases to pass.
3. Run the complete `font` package serially on native, js, wasm, and wasm-gc, with a unique external target directory for each target.
4. Require `pkg.generated.mbti` to hash to `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade` before and after all-target interface regeneration and to have no git diff.
5. Run `git diff --check` for `font.mbt` and `font_wbtest.mbt`.
6. Require the Phase 98 verification report to remain exactly untracked (`??`) and absent from all task commits.
</verification>

<success_criteria>
- The verifier's sole behavior-unverified ordering invariant has deterministic executable coverage for both `Font::glyph_for_scalar` and `Font::kerning`.
- Mutation occurs after the admitted lookup and before the post-read guard, each callback runs exactly once, both queries return the stable State/InvalidRange revision-drift error, and no successful value escapes.
- Existing public and white-box font behavior passes on all four supported targets with serial, externally isolated build roots.
- No public API or generated interface byte changes; the frozen SHA-256 remains exact.
- Only `font.mbt` and `font_wbtest.mbt` are implementation-task-owned, and the existing untracked Phase 98 verification report remains untouched.
</success_criteria>

<output>
After the RED and GREEN commits and all qualification gates succeed, create `.planning/quick/260727-loc-add-deterministic-mid-query-revision-dri/260727-loc-SUMMARY.md` with `status: complete`, RED/GREEN/refactor commit hashes, focused native and full four-target results, both callback-count/no-publication outcomes, the before/after interface SHA-256 values, and explicit confirmation that `.planning/phases/98-unicode-mapping-and-kerning/98-VERIFICATION.md` remained unmodified, untracked, and absent from commits.
</output>
