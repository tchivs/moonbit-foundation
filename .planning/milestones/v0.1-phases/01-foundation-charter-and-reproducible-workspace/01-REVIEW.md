---
phase: 01-foundation-charter-and-reproducible-workspace
reviewed: 2026-07-16T12:13:34Z
depth: standard
files_reviewed: 39
files_reviewed_list:
  - .github/workflows/quality.yml
  - LICENSE
  - moon.work
  - docs/governance/decisions/0001-sole-owner-bootstrap.md
  - docs/governance/rfc-process.md
  - docs/policies/api-stability.md
  - docs/policies/licensing-and-fixtures.md
  - docs/policies/publication.md
  - docs/policies/targets.md
  - docs/policies/toolchain.md
  - docs/rfcs/0001-moonbit-native-foundation.md
  - docs/rfcs/README.md
  - fixtures/manifest.json
  - modules/mb-core/moon.mod.json
  - modules/mb-core/moon.pkg
  - modules/mb-core/README.mbt.md
  - modules/mb-core/CHANGELOG.md
  - modules/mb-core/scaffold.mbt
  - modules/mb-core/scaffold_wbtest.mbt
  - modules/mb-color/moon.mod.json
  - modules/mb-color/moon.pkg
  - modules/mb-color/README.mbt.md
  - modules/mb-color/CHANGELOG.md
  - modules/mb-color/scaffold.mbt
  - modules/mb-color/scaffold_wbtest.mbt
  - modules/mb-image/moon.mod.json
  - modules/mb-image/moon.pkg
  - modules/mb-image/README.mbt.md
  - modules/mb-image/CHANGELOG.md
  - modules/mb-image/scaffold.mbt
  - modules/mb-image/scaffold_wbtest.mbt
  - policy/foundation.json
  - policy/maintainers.json
  - policy/phase-01-source-audit.json
  - scripts/quality.ps1
  - scripts/quality/Assert-Policy.ps1
  - scripts/quality/Assert-Toolchain.ps1
  - scripts/quality/Invoke-MoonQuality.ps1
  - scripts/quality/Test-RfcAcceptance.ps1
findings:
  critical: 4
  warning: 4
  info: 0
  total: 8
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-07-16T12:13:34Z
**Depth:** standard
**Files Reviewed:** 39
**Status:** issues_found

## Summary

Iteration 3 verified that the Windows CRLF Required lane and all shipped adversarial matrices pass. The fixes for public-review field binding, repository approval files, external fixture policy, canonical paths, authorization markers, and real fixture dates are effective for their covered cases. The final review is still not clean: four lifecycle/evidence defects remain reproducible, including one legal lifecycle transition that the validator makes impossible.

Executed evidence:

- `pwsh -NoProfile -File .\scripts\quality.ps1 -Lane Required`: passed, including all four targets at 3/3 tests.
- RFC, fixture, LF/CRLF source-audit matrices: passed.
- An Accepted ledger whose evidence values only had the required references as prefixes passed.
- A Superseded-from-Accepted policy with `acceptance_route=forged-route` and `acceptance_evidence=forged-acceptance` passed.
- A legal Implemented-to-Superseded transition failed with `implementation_evidence must be empty for this RFC state or route.`
- The shipped Implemented positive case passes with unresolved strings `commit:implementation` and `report:qualification`.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Ledger evidence is bound by substring rather than exact reference identity

**File:** `scripts/quality/Assert-Policy.ps1:143-151`

**Severity:** BLOCKER

**Issue:** `Assert-ReferencesInLedgerRow` uses `LedgerRow.Contains(reference)`. A ledger row containing `#owner-instruction-forged` and `#edge-review-results-forged` therefore satisfies policy references ending at `#owner-instruction` and `#edge-review-results`. The adversarial case passed. The transition table can record different evidence while the gate reports the canonical references as bound.

**Fix:** Parse the Evidence cell into a normalized exact set and compare it with the expected evidence set using ordinal equality. Do not use substring containment. Add suffix, prefix, delimiter-injection, reordered-set, duplicate, and extra-reference cases.

### CR-02: Implementation and qualification evidence need not resolve to anything

**File:** `scripts/quality/Assert-Policy.ps1:408-417`

**Severity:** BLOCKER

**Issue:** Implemented-state evidence is checked only for non-empty strings and occurrence in the row. The positive test at `scripts/quality/Test-RfcAcceptance.ps1:169-170` uses `commit:implementation` and `report:qualification`; neither identifies an existing commit or report, yet the case passes. Thus the gate still permits an Implemented claim without authentic implementation or qualification evidence.

**Fix:** Define structured evidence kinds. Resolve repository files and anchors with the contained-path helper, validate `commit:<sha>` through `git cat-file`, and reject unknown schemes. Require distinct, existing implementation and qualification artifacts and add nonexistent/unknown-scheme tests.

### CR-03: Superseded Accepted history bypasses acceptance-route authentication

**File:** `scripts/quality/Assert-Policy.ps1:388-400`

**Severity:** BLOCKER

**Issue:** The Superseded branch returns before the acceptance-route switch. `Assert-RfcLifecycleLedger` only checks that the current `acceptance_evidence` strings occur in the historical row; it does not validate the authority route or its artifacts. A Superseded-from-Accepted policy with `acceptance_route=forged-route` and `acceptance_evidence=forged-acceptance` passed when those strings were placed in the historical row. Advancing to Superseded can therefore erase the authenticity of the Accepted state.

**Fix:** Separate historical-state validation from current-transition validation. Whenever the ledger contains Accepted history, run the complete route-specific authority/evidence validator against that historical evidence before processing Superseded. Add Superseded-from-Accepted cases for each valid route and forged/missing historical route data.

### CR-04: The legal Implemented-to-Superseded transition is impossible

**File:** `scripts/quality/Assert-Policy.ps1:117-139,388-400`

**Severity:** BLOCKER

**Issue:** For Superseded from Implemented, `Assert-RfcLifecycleLedger` requires non-empty historical implementation and qualification evidence. The Superseded branch then requires both fields to be empty at lines 397-398. A policy preserving valid Implemented evidence therefore fails, while clearing it fails the historical check. This contradicts the explicitly allowed `Implemented -> Superseded` transition.

**Fix:** Preserve and validate historical implementation/qualification evidence for Superseded-from-Implemented; require emptiness only when no Implemented history exists. Add positive and negative cases for Superseded from Proposed, Accepted, and Implemented.

## Warnings

### WR-01: Commit approval evidence does not prove an approved disposition

**File:** `scripts/quality/Assert-Policy.ps1:198-202`

**Severity:** WARNING

**Issue:** Markdown approval artifacts require `Disposition: approved`, but commit references check only `Approval-Identity` and `Approval-Role`. A commit explicitly recording rejection can still qualify if it has those two trailers.

**Fix:** Require an exact `Approval-Disposition: approved` trailer and reject duplicate/conflicting approval trailers. Add rejected, missing-disposition, and duplicate-trailer cases.

### WR-02: Reserved non-resolving HTTPS evidence is treated as authentic

**File:** `scripts/quality/Assert-Policy.ps1:181-189`

**Severity:** WARNING

**Issue:** Every syntactically valid HTTPS string returns immediately. The positive project-lead case uses the reserved `.invalid` TLD for the review location, opening, closing, and approval references and passes. At minimum, the validator cannot distinguish deliberately non-resolving test evidence from a stable public location.

**Fix:** Reject reserved documentation/test hosts and require an explicit manual-verification record or immutable fetched digest for external evidence. Keep offline unit fixtures behind an explicit test-only resolver rather than weakening production validation.

### WR-03: A filename-only placeholder qualifies as a replacement RFC

**File:** `scripts/quality/Assert-Policy.ps1:388-396`

**Severity:** WARNING

**Issue:** Supersession verifies only that one filename starts with the replacement ID. The positive test creates a one-line file containing only `# RFC 0002`, which passes as the replacement RFC. It does not need lifecycle metadata, status, a transition ledger, or a link back to RFC 0001.

**Fix:** Validate replacement RFC identity, non-terminal reviewable status, header metadata, and a supersession/back-reference to RFC 0001. Resolve the replacement through the no-reparse helper and add placeholder/symlink/wrong-ID tests.

### WR-04: Lifecycle parsing is not scoped to the Transition history section

**File:** `scripts/quality/Assert-Policy.ps1:96-105`

**Severity:** WARNING

**Issue:** `Get-RfcTransitionLedgerRows` scans every three-column Markdown table in the RFC. Adding an unrelated legitimate three-column table elsewhere changes the row count and makes lifecycle validation fail, while a transition-like row outside the ledger can be consumed as governance history.

**Fix:** Extract the `Transition history` section first and parse exactly its single table. Reject multiple transition tables and ignore unrelated tables outside that section. Add an unrelated three-column table case.

---

_Reviewed: 2026-07-16T12:13:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
