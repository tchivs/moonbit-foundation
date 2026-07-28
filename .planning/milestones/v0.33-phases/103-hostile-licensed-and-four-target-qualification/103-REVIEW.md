---
phase: 103-hostile-licensed-and-four-target-qualification
reviewed: 2026-07-28T07:19:00Z
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
resolved: 2026-07-28T07:27:54Z
fix_report: 103-REVIEW-FIX.md
---

# Phase 103: Code Review Report

**Reviewed:** 2026-07-28T07:19:00Z
**Depth:** deep
**Files Reviewed:** 18
**Status:** resolved

## Summary

Final pass 3 reviewed HEAD `642a7e4caa3e8f6c961556167b06a5216543ea27`, including implementation commit `1e5ba954` and resolution-doc commit `642a7e4c`. The direct pass-2 mutation is fixed: plain, spaced, and mixed-case `continue-on-error` keys are rejected on every parsed step, and the FontQualification runner step is closed to exact `name`, `shell`, and `run` entries.

The final residual boundary is closed by `052d6fa4`. Workflow mapping keys are normalized and unquoted before fail-closed comparison, checkout and pinned-installer steps have exact schemas, and job/prerequisite/runner/upload continuation variants are rejected. Captured and recorded evidence is now compared to the exact toolchain identity derived from the separately locked project policy before any target record is written.

Pass 3 targeted validation passed:

- generator drift check;
- post-initialization target/comparison link-swap boundary suite;
- full foundation policy and permanent negative-contract suite;
- native closed collection matrix (1/1);
- native collection white-box suite (14/14);
- rejection of second-fixture schema drift, hostile-context drift, and failed-budget drift;
- rejection of the original renamed Type2, SFNT-inflation, and gvar-delta probes.

### Pass 3 Resolution

The unchanged workflow is accepted and all 16 single-quoted, double-quoted, cased, and spaced job/prerequisite/runner/upload continuation mutations are rejected. Policy substitutions for the pinned Moon, moonc, and moonrun fields are rejected. Runtime capture and evidence records require exactly `moon 0.1.20260713 (75c7e1f 2026-07-13)`, `moonc v0.10.4+2cc641edf (2026-07-15)`, and `moonrun 0.1.20260713 (75c7e1f 2026-07-13)`.

The complete four-target lane passed with 14 focused gates and 152 package tests per target, 29 evidence negatives, and semantic hash `af508a8c549bc5ebbeb4710960e2eabb7978dacbf4059e3efe0c83da4259f8d4`.

### Prior Finding Revalidation

| Finding | Final result | Evidence |
|---|---|---|
| CR-01 | Closed | Explicit runtime facts remain generated and generator drift check passed. |
| CR-02 | Closed | Every structured error field is compared; native closed matrix and white-box suites passed. |
| CR-03 | Closed | Canonical nested facts, every fixture schema, exact corpus digest, and failed-budget atomicity rejected targeted mutations. |
| CR-04 | Closed for completed swaps | Target/comparison post-init link swaps were rejected without outside writes. |
| CR-05 | Closed | Original CFF/WOFF/variable renamed aliases remain rejected and production/negative contracts remain locked. |
| CR-06 | Closed | Quoted/cased/spaced keys are normalized before comparison, prerequisite schemas are closed, and evidence is bound to the exact pinned policy identity. |
| WR-01 | Closed | Comparison evidence remains schema-closed, read back, and record/semantic hash checked. |
| WR-02 | Closed | The semantic payload retains ordered identities for all eight focused sources plus commit/tree identity. |

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-06: Quoted continuation keys bypass the prerequisite-step guard

**Classification:** BLOCKER
**Files:** `scripts/quality/Assert-Policy.ps1:1839-1868`; `scripts/quality/Invoke-FontQualification.ps1:557-558,884-899`
**Issue:** The remediation searches step text with `^continue-on-error\s*:` after trimming, so it recognizes only an unquoted YAML key. YAML treats quoted mapping keys as the same property, but the policy accepts both of these mutations directly after the pinned installer command:

```yaml
        'continue-on-error': true
```

```yaml
        "continue-on-error": true
```

The same quoted job-level spellings also bypass the four-space job check. The runner itself is protected because its exact three-line schema rejects an added entry, but the installer and other prerequisite steps are not schema-closed. Reproduction on HEAD returned:

```text
ACCEPTED prerequisite single quoted
ACCEPTED prerequisite double quoted
ACCEPTED job single quoted
ACCEPTED job double quoted
```

This is not only syntactic drift. If the pinned installer fails with continuation enabled, the lane can execute against a pre-existing `moon` on the runner. `Assert-FontQualificationEvidenceRecord` closes only the three toolchain keys, and `Get-FontQualificationToolchain` records whatever `moon version --all` returns; neither compares those values with `policy/foundation.json`'s exact pinned identity. The resulting four target records can therefore agree and upload while being produced by an unauthorized toolchain.

**Fix:** Parse the workflow with a YAML parser and inspect normalized mapping keys, then require `continue-on-error` to be absent from the job and every step. Close the checkout and pinned-installer steps to exact allowed key/value schemas just as the runner and upload steps are closed. As defense in depth, compare the captured `moon`, `moonc`, and `moonrun` values to the exact policy versions before any target record is written. Add permanent single- and double-quoted job/prerequisite mutations:

```powershell
foreach ($quotedKey in @("'continue-on-error'", '"continue-on-error"')) {
  Confirm-FontQualificationRejected "quoted prerequisite $quotedKey" {
    Assert-FontQualificationWorkflowContract -WorkflowText (
      $qualityWorkflowText.Replace(
        $installCommand,
        $installCommand + "`n        ${quotedKey}: true"
      )
    )
  } 'must not continue on error'
}
```

**Resolution:** Fixed in `052d6fa4`. The dependency-free restricted YAML parser now normalizes plain, single-quoted, and double-quoted mapping keys and rejects unsupported quoted forms fail-closed. The exact checkout, installer, runner, and upload schemas are enforced. Policy, runtime capture, each target record, and cross-target comparison reject toolchain substitution or drift.

---

_Reviewed: 2026-07-28T07:19:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
