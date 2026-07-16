---
phase: 01-foundation-charter-and-reproducible-workspace
reviewed: 2026-07-16T11:22:52Z
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

**Reviewed:** 2026-07-16T11:22:52Z
**Depth:** standard
**Files Reviewed:** 39
**Status:** issues_found

## Summary

The workspace scaffolds, target declarations, dependency policy, exact toolchain checks, pinned action revisions, and package allowlists are internally coherent. The main defects are in the fail-closed governance validator: several documented acceptance and lifecycle invariants are not independently enforced and can be bypassed while the required quality lane remains green.

The acceptance matrix itself passes, but targeted adversarial cases also passed for a future-dated public review, an `Implemented` RFC with no implementation qualification evidence, a `Superseded` RFC with no replacement RFC, a maintainer route with placeholder evidence, and a sole-owner route whose mandatory review identity was replaced with `FAKE`. Those are gate failures, not documentation style concerns.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Lifecycle states are accepted without their required transition evidence

**File:** `scripts/quality/Assert-Policy.ps1:137-169`

**Severity:** BLOCKER

**Issue:** The validator checks only that the RFC header and index contain the policy status. Every state other than `Accepted` or `Implemented` is handled by the same "empty acceptance fields" branch, so `Superseded` passes without naming a replacement RFC and `Rejected` passes without a rejecting disposition. `Implemented` reuses the acceptance-route checks and never requires implementation or qualification evidence. It also never verifies that the RFC contains a transition-ledger row. This contradicts `docs/governance/rfc-process.md:24-26,74-86,101-105`. The test helper at `scripts/quality/Test-RfcAcceptance.ps1:86-101` creates only a heading and status line, which is why an `Implemented` policy with no qualification evidence and a `Superseded` policy with no replacement both passed in adversarial execution.

**Fix:** Model lifecycle evidence explicitly in `policy/foundation.json` and switch on every status. Require and validate the exact prior-to-new transition row, route-specific evidence for `Accepted`, implementation and qualification references for `Implemented`, a rejecting disposition for `Rejected`, and an existing replacement RFC plus evidence for `Superseded`. Add negative tests for missing ledger, illegal prior state, missing implementation evidence, and missing replacement RFC.

### CR-02: A future review window satisfies the seven-day public-review route

**File:** `scripts/quality/Assert-Policy.ps1:182-192`

**Severity:** BLOCKER

**Issue:** The project-lead route checks only `ended >= started + 7 days`; it never checks that the end time has elapsed. A window from `2099-01-01` to `2099-01-08` passed the current acceptance gate today. This permits immediate acceptance by recording a future interval and violates the normative requirement that seven days "has elapsed" in `docs/governance/rfc-process.md:46-51`.

**Fix:** Parse with invariant culture and require `started <= ended`, `ended <= now`, and `ended - started >= 7 days`. Inject or parameterize the clock so tests are deterministic. Add explicit future-start, future-end, reversed-window, malformed-offset, and boundary tests.

### CR-03: The sole-owner route can redefine the exact evidence it is supposed to enforce

**File:** `scripts/quality/Assert-Policy.ps1:194-223`

**Severity:** BLOCKER

**Issue:** `decision_path`, `required_anchors`, and `mandatory_edge_reviews` are read from the same mutable policy being validated but are never compared with immutable canonical values. An adversarial policy that reduced the anchor list to `owner-instruction`, replaced both mandated edge reviews with one review named `FAKE`, and made the RFC evidence match that weakened policy passed the current gate. The decision document is also checked only for headings plus the words `现在只有我一个人开发，跳过` and `preauthoriz`; the validator does not verify that the edge-review section contains each mandated ID and disposition. This defeats the exact-artifact and exact-two-review requirements in `docs/governance/rfc-process.md:55-72`.

**Fix:** Assert the canonical decision path and exact four anchors and two edge-review IDs independently of policy input. Validate that each canonical edge ID and its resolved disposition occurs in the decision artifact's edge-review section, not merely in JSON. Add negative tests that mutate each policy-owned identifier, omit an edge record from the artifact, or move the owner instruction outside its named section.

### CR-04: Maintainer approvals are not bound to authentic evidence

**File:** `scripts/quality/Assert-Policy.ps1:166-180`

**Severity:** BLOCKER

**Issue:** The common check requires only that `acceptance_evidence` have at least one element. The maintainer branch validates two roster identities but never requires one stable approval reference per approver and never checks the RFC transition ledger. A two-maintainer policy with both roster evidence fields and `acceptance_evidence` set to the literal `placeholder` passed. Therefore the gate can claim two approvals without links or repository references, contrary to `docs/governance/rfc-process.md:38-42,74-88`.

**Fix:** Represent approvals as structured records containing canonical identity, role, and a non-placeholder repository reference or HTTPS review URL. Require a one-to-one exact set between approvers and approval records, validate the references against the RFC ledger, and reject generic strings, duplicate evidence, and evidence that is not bound to an approver. Add those adversarial cases to the matrix.

## Warnings

### WR-01: Fixture validation checks digest syntax but not fixture identity or path containment

**File:** `scripts/quality/Assert-Policy.ps1:305-322`

**Severity:** WARNING

**Issue:** A future fixture record passes when its `sha256` merely has 64 lowercase hex characters; the digest is never compared with the file. The record path may also contain `..` or traverse a reparse point because only `Test-Path` is used. That allows stale or substituted fixture bytes and files outside the repository to satisfy the provenance gate, despite the policy describing SHA-256 as fixture identity.

**Fix:** Resolve every fixture path through a repository-contained, no-reparse-point helper, reject rooted and parent-traversal paths, require a regular leaf file, and compare `Get-FileHash -Algorithm SHA256` with the manifest digest using ordinal lowercase equality. Add mismatch, traversal, symlink, missing-file, and valid-file tests.

### WR-02: The normative RFC process still says the completed edge reviews are open

**File:** `docs/governance/rfc-process.md:107-114`

**Severity:** WARNING

**Issue:** The normative process calls the two checks "still-unclassified" and says they "are open review obligations," while the accepted RFC, decision artifact, RFC index, and machine policy all state they are completed and dispositioned. Readers therefore receive contradictory current governance state from a normative document.

**Fix:** Keep the section as a permanent description of the required checks, but state that RFC 0001 completed them and link to `docs/governance/decisions/0001-sole-owner-bootstrap.md#edge-review-results`. Avoid wording that hard-codes them as currently open.

### WR-03: Negative acceptance tests can pass for the wrong failure reason

**File:** `scripts/quality/Test-RfcAcceptance.ps1:93-105`

**Severity:** WARNING

**Issue:** `Invoke-AcceptanceCase` converts every exception into the same Boolean failure. A malformed test fixture, path/setup error, or unrelated regression therefore makes a negative case pass even when the intended invariant was never exercised. The platform-shaped-path cases already risk this because their rejection can come from a later canonical-path mismatch rather than the rooted-path check named by the test.

**Fix:** Give validation failures stable codes or exception types and let every negative case assert the expected code. At minimum, accept an expected message pattern and fail when a different exception occurs. Add a harness self-test proving an arrange/setup exception is not counted as a successful rejection.

### WR-04: The source-audit gate validates claims, not their referenced coverage

**File:** `scripts/quality/Assert-Policy.ps1:327-370`

**Severity:** WARNING

**Issue:** The "exact source inventory" gate fixes IDs and counts, but for each entry it accepts any non-empty `source`, `description`, and `covering_plan` plus the self-asserted string `covered`. It does not check that a source document or anchor exists, that a covering plan is one of the Phase 01 plans, or that the plan actually references the item. A fully fabricated coverage map with the same IDs passes.

**Fix:** Validate source paths and anchors against repository-contained files, parse covering-plan IDs as an exact allowed set, and verify reciprocal references from each plan or from a generated immutable coverage manifest. Add tests for missing anchors, unknown plans, duplicate plan IDs, and a known ID mapped to the wrong plan.

---

_Reviewed: 2026-07-16T11:22:52Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
