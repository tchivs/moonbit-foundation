---
phase: 103-hostile-licensed-and-four-target-qualification
reviewed: 2026-07-28T07:08:32Z
depth: deep
files_reviewed: 18
files_reviewed_list:
  - .github/workflows/quality.yml
  - docs/policies/licensing-and-fixtures.md
  - fixtures/font/collection-qualification-cases.json
  - fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face-v1.ttc
  - fixtures/font/dejavu-sans-2.37/collection-oracle.json
  - fixtures/manifest.json
  - modules/mb-font/CHANGELOG.md
  - modules/mb-font/README.mbt.md
  - modules/mb-font/font/collection_wbtest.mbt
  - modules/mb-font/font/font_qualification_hostile_test.mbt
  - modules/mb-font/font/font_qualification_test.mbt
  - modules/mb-font/font/generated_font_qualification_test.mbt
  - modules/mb-font/moon.mod.json
  - policy/foundation.json
  - scripts/fixtures/Generate-FontQualification.ps1
  - scripts/quality/Assert-Policy.ps1
  - scripts/quality/Invoke-FontQualification.ps1
  - scripts/quality/Test-FontQualificationEvidenceBoundary.ps1
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: resolved
resolved: 2026-07-28T07:14:19Z
fix_report: 103-REVIEW-FIX.md
---

# Phase 103: Code Review Report

**Reviewed:** 2026-07-28T07:08:32Z
**Depth:** deep
**Files Reviewed:** 18
**Status:** resolved

## Summary

Pass 2 re-reviewed HEAD `84b293b3e7a9a45b186fb9177888823452357b70` and the remediation range `700687ed..84b293b3`. The sole residual blocker is now closed by commit `1e5ba954`: the structural policy rejects `continue-on-error` on every FontQualification step, closes the runner step to its exact three-key schema, and permanently probes runner, prerequisite, and upload mutations with YAML-compatible spacing and casing variants.

Targeted validation passed:

- `Generate-FontQualification.ps1 -Check`;
- the post-initialization target/comparison link-swap boundary suite;
- the full font policy and its capability-negative probes;
- the native closed collection matrix (1/1);
- the native collection white-box suite (14/14).

The previous CFF/WOFF/variable aliases are now rejected, second-fixture schema drift is rejected, exact corpus semantics and failed-budget atomicity are locked, target/comparison evidence is closed and read back, and all focused source identities participate in the semantic payload.

### Pass 2 Resolution

The unchanged workflow passes. Twelve direct step-continuation mutations are rejected across the runner, prerequisite, and upload steps, including `continue-on-error : TRUE`, `Continue-On-Error: True`, and `CONTINUE-ON-ERROR : false`. The full policy contract and complete four-target FontQualification lane passed with 14 focused gates and 152 package tests per target, 25 negative probes, and semantic hash `960351f39e08294b59188278b518c2ed4266c1dfbce923dc08afb84a5c1b6ca5`.

### Prior Finding Revalidation

| Finding | Pass 2 result | Evidence |
|---|---|---|
| CR-01 | Closed | Generated corpus now freezes explicit runtime error facts; generator drift check passed. |
| CR-02 | Closed | Runtime dispatcher compares every error field; missing overflow, selected-limit, caller-budget, and ancestor-budget families execute; native matrix and white-box tests passed. |
| CR-03 | Closed | Target records compare nested sections to current canonical facts; corpus policy closes every fixture/case schema, exact semantic digest, and failed-budget atomicity. |
| CR-04 | Closed for completed swaps | Every record/comparison write revalidates containment, link state, and marker; completed post-init target/comparison swaps were rejected without outside writes. |
| CR-05 | Closed | The original renamed Type2, SFNT-inflation, and gvar-delta probes are rejected; production executable text and the negative contract are digest-locked. |
| CR-06 | Closed | Every step is checked structurally for continuation; the unique runner is closed to exact `name`, `shell`, and `run` keys; runner/prerequisite/upload variants are permanent negatives. |
| WR-01 | Closed | `comparison.json` has a closed schema, durable write, read-back, per-record hash verification, and semantic-hash verification. |
| WR-02 | Closed | Evidence binds the ordered eight-file focused source set plus exact repository commit and tree identities. |

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-06: Step-level continuation still permits failing evidence upload

**Classification:** BLOCKER
**File:** `scripts/quality/Assert-Policy.ps1:1839-1843`
**Issue:** The workflow policy rejects only a job-level key matching `^    continue-on-error:`. It parses individual steps at lines 1849-1857 but never closes or validates the FontQualification runner step itself. Adding the following line directly after the lane command is therefore accepted:

```yaml
        continue-on-error: true
```

The adversarial in-memory mutation returned `STEP_CONTINUE_ON_ERROR_ACCEPTED`. In GitHub Actions, a failed step with `continue-on-error: true` can have a successful conclusion for subsequent job control, so the exact `${{ success() }}` upload step is no longer sufficient to prove that the qualification command passed. Because the runner clears the managed directory before emitting target records, a mid-lane failure can leave a marker and a partial record set that this bypass uploads.

**Fix:** Close the runner step to the exact allowed `name` and `run` keys and reject `continue-on-error` at every indentation within the `font-qualification` job. At minimum, structurally identify the unique lane step and require that it has no `continue-on-error` property. Add the reproduced mutation as a permanent negative probe:

```powershell
Confirm-FontQualificationRejected 'runner step continue-on-error' {
  Assert-FontQualificationWorkflowContract -WorkflowText (
    $qualityWorkflowText.Replace(
      $expectedLaneCommand,
      $expectedLaneCommand + "`n        continue-on-error: true"
    )
  )
} 'must not continue on error'
```

**Resolution:** Fixed in `1e5ba954`. The policy now rejects the key on any parsed FontQualification step before upload topology validation and requires one exact runner step containing only `name`, `shell`, and `run`. Permanent probes cover runner, prerequisite, and upload steps plus mixed-case and spaced spellings.

---

_Reviewed: 2026-07-28T07:08:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
