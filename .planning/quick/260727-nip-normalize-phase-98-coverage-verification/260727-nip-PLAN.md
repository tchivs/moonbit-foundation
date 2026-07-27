---
quick_id: 260727-nip
phase: quick-260727-nip
plan: 01
description: Normalize Phase 98 coverage verification kinds for automated UAT
type: execute
wave: 1
depends_on: []
autonomous: true
requirements: [FONT-02, FONT-04]
files_modified:
  - ".planning/phases/98-unicode-mapping-and-kerning/98-03-SUMMARY.md"
must_haves:
  truths:
    - "Phase 98 Plan 03 coverage classifies in coverage mode as three automated passes with no validation errors."
    - "Only the two invalid D1/D2 verification kinds change; all coverage descriptions, references, pass statuses, requirements, and human-judgment values remain intact."
  artifacts:
    - path: ".planning/phases/98-unicode-mapping-and-kerning/98-03-SUMMARY.md"
      provides: "Classifier-valid automated coverage metadata for all three Plan 98-03 deliverables"
  key_links:
    - from: ".planning/phases/98-unicode-mapping-and-kerning/98-03-SUMMARY.md"
      to: "uat.classify-coverage"
      via: "D1 and D2 use the valid integration kind for their cross-target verification evidence"
      pattern: "all_auto_covered.*true"
---

<objective>
Normalize the two invalid verification kinds in Phase 98 Plan 03 coverage metadata so automated UAT can classify all three deliverables.

Purpose: The recorded evidence already passes, but `uat.classify-coverage` rejects `portability` because it is not a supported verification kind.
Output: A metadata-only correction to `98-03-SUMMARY.md` and a quick SUMMARY produced by the executor.
</objective>

<execution_context>
@C:/Users/Admin/.codex/gsd-core/workflows/execute-plan.md
@C:/Users/Admin/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@AGENTS.md
@.planning/phases/98-unicode-mapping-and-kerning/98-03-SUMMARY.md

The live classifier currently reports `mode: coverage`, one automated pass (D3), D1/D2 as present with `validation_failed`, and two `invalid_kind` errors at `verification[1].kind`. Supported kinds are `unit`, `integration`, `e2e`, `automated_ui`, `manual_procedural`, and `other`.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Normalize Phase 98 cross-target verification kinds</name>
  <files>.planning/phases/98-unicode-mapping-and-kerning/98-03-SUMMARY.md</files>
  <action>
In the YAML frontmatter `coverage:` block, change only the D1 and D2 verification items whose current kind is `portability` to `kind: integration`. Cross-target execution validates the integrated public workflow and package behavior across supported runtimes, so `integration` is the closest valid classifier kind.

Preserve the D1-D3 IDs and ordering, every description, every verification `ref`, every `status: pass`, each `requirement`, each `human_judgment: false`, all other frontmatter, and the complete Markdown body. Do not modify UAT, verification reports, production code, ROADMAP.md, REQUIREMENTS.md, or any unrelated file.
  </action>
  <verify>
    <automated>pwsh -NoProfile -Command '$ErrorActionPreference="Stop"; $tool="C:/Users/Admin/.codex/gsd-core/bin/gsd-tools.cjs"; $summary=".planning/phases/98-unicode-mapping-and-kerning/98-03-SUMMARY.md"; $raw=(node $tool query uat.classify-coverage --summary $summary | Out-String); if ($LASTEXITCODE -ne 0) { throw "uat.classify-coverage exited $LASTEXITCODE" }; $coverage=$raw | ConvertFrom-Json; if ($coverage.mode -ne "coverage" -or $coverage.total -ne 3 -or -not $coverage.all_auto_covered -or @($coverage.auto_passed).Count -ne 3 -or @($coverage.present).Count -ne 0 -or @($coverage.errors).Count -ne 0) { throw "Phase 98 Plan 03 coverage did not classify as three clean automated passes" }; if ((@($coverage.auto_passed | ForEach-Object { $_.id }) -join ",") -ne "D1,D2,D3") { throw "Unexpected automated coverage IDs" }; foreach ($entry in $coverage.auto_passed) { if ($entry.human_judgment -ne $false -or @($entry.verification).Count -eq 0 -or @($entry.verification | Where-Object { $_.status -ne "pass" }).Count -ne 0) { throw "Invalid automated coverage entry $($entry.id)" } }; git diff --check -- $summary; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }'</automated>
  </verify>
  <done>`uat.classify-coverage` returns `mode: coverage`, `all_auto_covered: true`, exactly three D1-D3 auto-passed entries, an empty `present` array, and no errors; the only summary changes are the two D1/D2 verification kinds from `portability` to `integration`.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| SUMMARY frontmatter -> UAT classifier | Hand-maintained verification metadata determines whether completed evidence is recognized as automated coverage. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-NIP-01 | Tampering | Phase 98 coverage metadata | high | mitigate | Restrict the edit to two `kind` scalars and assert three clean automated classifier results. |
| T-NIP-02 | Repudiation | Existing verification evidence | medium | mitigate | Preserve descriptions, references, pass statuses, requirements, and human-judgment flags byte-for-byte. |
| T-NIP-03 | Denial of Service | Planning scope | low | mitigate | Own only `98-03-SUMMARY.md` and exclude UAT, verification, production, roadmap, and requirements files. |
</threat_model>

<source_audit>

| Source | ID | Feature / Requirement | Task | Status | Notes |
|--------|----|-----------------------|------|--------|-------|
| GOAL | NIP-01 | Normalize Phase 98 coverage verification kinds for automated UAT | 1 | COVERED | Both invalid kinds become the semantically closest valid kind |
| REQ | FONT-02 | Unicode mapping and published font contract evidence | 1 | COVERED | D1 and D3 retain FONT-02 |
| REQ | FONT-04 | Portable kerning and adversarial matrix evidence | 1 | COVERED | D2 retains FONT-04 |
| RESEARCH | — | No quick-task research artifact | — | N/A | Existing summary and live classifier output provide sufficient Level 0 evidence |
| CONTEXT | — | No D-XX context artifact | — | N/A | Supplied constraints are encoded directly in Task 1 |
</source_audit>

<verification>
Run `uat.classify-coverage` against `98-03-SUMMARY.md` and require coverage mode, `all_auto_covered: true`, three D1-D3 automated passes, no present entries, and no errors; then run `git diff --check`.
</verification>

<success_criteria>
- Both unsupported verification kinds are `integration`.
- All three coverage entries classify as automated passes with no errors.
- No descriptions, references, statuses, requirements, human-judgment values, Markdown body, or unrelated files change.
</success_criteria>

<output>
After the atomic task commit succeeds, create `.planning/quick/260727-nip-normalize-phase-98-coverage-verification/260727-nip-SUMMARY.md` with the task commit hash, classifier result, and explicit confirmation that only the two verification kinds changed.
</output>
