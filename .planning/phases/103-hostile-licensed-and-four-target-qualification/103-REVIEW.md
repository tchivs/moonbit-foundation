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
status: issues_found
---

# Phase 103: Code Review Report

**Reviewed:** 2026-07-28T07:08:32Z
**Depth:** deep
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Pass 2 re-reviewed HEAD `84b293b3e7a9a45b186fb9177888823452357b70` and the remediation range `700687ed..84b293b3`. Seven of the eight prior findings are closed by the current implementation. CR-06 remains a blocker: the new structural CI policy rejects job-level continuation and duplicate upload steps, but still accepts `continue-on-error: true` on the FontQualification runner step. That mutation can convert a failed qualification step into a successful step conclusion and permit the subsequent `${{ success() }}` upload to publish partial or failing evidence.

Targeted validation passed:

- `Generate-FontQualification.ps1 -Check`;
- the post-initialization target/comparison link-swap boundary suite;
- the full font policy and its capability-negative probes;
- the native closed collection matrix (1/1);
- the native collection white-box suite (14/14).

The previous CFF/WOFF/variable aliases are now rejected, second-fixture schema drift is rejected, exact corpus semantics and failed-budget atomicity are locked, target/comparison evidence is closed and read back, and all focused source identities participate in the semantic payload.

### Prior Finding Revalidation

| Finding | Pass 2 result | Evidence |
|---|---|---|
| CR-01 | Closed | Generated corpus now freezes explicit runtime error facts; generator drift check passed. |
| CR-02 | Closed | Runtime dispatcher compares every error field; missing overflow, selected-limit, caller-budget, and ancestor-budget families execute; native matrix and white-box tests passed. |
| CR-03 | Closed | Target records compare nested sections to current canonical facts; corpus policy closes every fixture/case schema, exact semantic digest, and failed-budget atomicity. |
| CR-04 | Closed for completed swaps | Every record/comparison write revalidates containment, link state, and marker; completed post-init target/comparison swaps were rejected without outside writes. |
| CR-05 | Closed | The original renamed Type2, SFNT-inflation, and gvar-delta probes are rejected; production executable text and the negative contract are digest-locked. |
| CR-06 | **Open** | Step-level `continue-on-error` remains accepted; see CR-06 below. |
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

---

_Reviewed: 2026-07-28T07:08:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
