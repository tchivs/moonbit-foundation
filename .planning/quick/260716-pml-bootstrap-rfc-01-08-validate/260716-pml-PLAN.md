---
phase: quick-260716-pml-bootstrap-rfc-01-08-validate
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/01-foundation-charter-and-reproducible-workspace/01-CONTEXT.md
  - .planning/phases/01-foundation-charter-and-reproducible-workspace/01-RESEARCH.md
  - .planning/phases/01-foundation-charter-and-reproducible-workspace/01-08-PLAN.md
  - docs/governance/rfc-process.md
  - docs/governance/decisions/0001-sole-owner-bootstrap.md
  - docs/rfcs/0001-moonbit-native-foundation.md
  - docs/rfcs/README.md
  - policy/maintainers.json
  - policy/foundation.json
  - policy/phase-01-source-audit.json
  - scripts/quality.ps1
  - scripts/quality/Assert-Policy.ps1
  - scripts/quality/Test-RfcAcceptance.ps1
autonomous: true
requirements: [GOV-01, GOV-02]
must_haves:
  truths:
    - "The exact user instruction `现在只有我一个人开发，跳过` is preserved as the authentic sole project-owner preauthorization to pass RFC 0001's acceptance gate after both mandatory edge reviews complete without unresolved blocking objections."
    - "The sole-owner route never synthesizes a later approval and never claims a second approval or elapsed public-review time; Plan 01-08 consumes the existing conditional preauthorization."
    - "A canonical repository roster determines maintainer count from unique identities, identifies the sole project owner, and expires the route whenever the unique maintainer count is not exactly one."
    - "Owner evidence resolves only through the exact repository-relative decision artifact and required anchors; rooted, traversing, or repo-escaping paths fail closed."
    - "The normal two-maintainer route remains available, the project-lead public-review route retains its seven-day rule, and Required quality always runs the RFC acceptance test matrix."
    - "RFC prose, the RFC index, structured policy, source audit, roster, validation logic, and Plan 01-08 describe the same route and fail closed on incomplete evidence."
  artifacts:
    - path: "docs/governance/decisions/0001-sole-owner-bootstrap.md"
      provides: "Repository-tracked declaration of the owner's one-developer bootstrap decision and its limits"
      contains: "现在只有我一个人开发，跳过"
    - path: "policy/maintainers.json"
      provides: "Canonical identities and roles from which sole-owner route eligibility is derived"
      contains: '"project-owner"'
    - path: "policy/foundation.json"
      provides: "Machine-readable route inventory, owner evidence fields, roster reference, and edge-review evidence fields"
      contains: '"sole-project-owner-bootstrap"'
    - path: "scripts/quality/Assert-Policy.ps1"
      provides: "Route-specific fail-closed RFC acceptance validation"
      contains: "Assert-RfcAcceptanceState"
    - path: "scripts/quality.ps1"
      provides: "Required-lane execution of the RFC acceptance test matrix"
      contains: "Test-RfcAcceptance.ps1"
    - path: ".planning/phases/01-foundation-charter-and-reproducible-workspace/01-08-PLAN.md"
      provides: "Autonomous acceptance and qualification flow using the authorized sole-owner route"
      contains: "sole-project-owner-bootstrap"
  key_links:
    - from: "docs/governance/rfc-process.md"
      to: "policy/foundation.json"
      via: "the canonical route identifier and exact one-maintainer eligibility rule"
      pattern: "sole-project-owner-bootstrap"
    - from: "policy/maintainers.json"
      to: "scripts/quality/Assert-Policy.ps1"
      via: "unique roster identities determine maintainer count and the sole project-owner identity"
      pattern: "maintainers[.]json|project-owner"
    - from: "policy/foundation.json"
      to: "scripts/quality/Assert-Policy.ps1"
      via: "acceptance_route dispatch validates route-specific required and forbidden evidence"
      pattern: "acceptance_route|Assert-RfcAcceptanceState"
    - from: "docs/governance/decisions/0001-sole-owner-bootstrap.md"
      to: ".planning/phases/01-foundation-charter-and-reproducible-workspace/01-08-PLAN.md"
      via: "Plan 01-08 consumes the exact conditional preauthorization after recording both edge-review outcomes; it does not create a later approval"
      pattern: "现在只有我一个人开发，跳过|EDGE-GOV-01-UNCLASSIFIED|EDGE-GOV-02-UNCLASSIFIED"
    - from: "scripts/quality.ps1"
      to: "scripts/quality/Test-RfcAcceptance.ps1"
      via: "the Required lane invokes the acceptance matrix before reporting success"
      pattern: "Test-RfcAcceptance[.]ps1"
---

<objective>
Add a transparent sole-project-owner bootstrap acceptance route and remove the obsolete Phase 1 governance deadlock without inventing approvals or elapsed review time.

Purpose: Honor the locked user decision that this is currently a one-developer project and that the two-maintainer and seven-day waiting prerequisites are explicitly skipped, while preserving an auditable, fail-closed acceptance record.
Output: Aligned governance sources, machine policy and tests, plus an executable autonomous Plan 01-08.
</objective>

<execution_context>
@C:/Users/Admin/.codex/gsd-core/workflows/execute-plan.md
@C:/Users/Admin/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@AGENTS.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/01-foundation-charter-and-reproducible-workspace/01-CONTEXT.md
@.planning/phases/01-foundation-charter-and-reproducible-workspace/01-RESEARCH.md
@.planning/phases/01-foundation-charter-and-reproducible-workspace/01-08-PLAN.md
@docs/governance/rfc-process.md
@docs/rfcs/0001-moonbit-native-foundation.md
@docs/rfcs/README.md
@policy/foundation.json
@policy/phase-01-source-audit.json
@scripts/quality.ps1
@scripts/quality/Assert-Policy.ps1
</context>

## Source Coverage Audit

| Source type | Item | Coverage |
|---|---|---|
| GOAL | Enable a transparent sole-owner bootstrap route and unblock 01-08 without fabricated evidence or synthesized approval | Tasks 1-3 |
| REQ | GOV-01 accepted foundation RFC | Tasks 1 and 3 establish the legitimate route that 01-08 will use to reach Accepted |
| REQ | GOV-02 documented lifecycle, authority, review expectations, and breaking-change rules | Tasks 1-2 update the normative authority model and enforce it |
| RESEARCH | Governance pitfall: prose alone or invented evidence cannot establish acceptance | Tasks 1-2 preserve fail-closed evidence while annotating the superseded waiting recommendation |
| CONTEXT | D-02 lifecycle and synchronized transitions | Tasks 1 and 3 preserve the lifecycle and synchronized ledger/index/policy update |
| CONTEXT | D-03 acceptance authority | Tasks 1-3 implement the user's explicit amendment for a one-developer repository |
| CONTEXT | D-04 accepted RFC required for architectural changes | Task 1 preserves the accepted-RFC gate; only the eligible authority route changes |

Unrelated Phase 1 requirements, research items, decisions, and deferred ideas are outside this atomic governance amendment and remain covered by the existing Phase 1 plan set.

<tasks>

<task type="auto">
  <name>Task 1: Amend the governance contract for sole-owner bootstrap acceptance</name>
  <files>.planning/phases/01-foundation-charter-and-reproducible-workspace/01-CONTEXT.md, .planning/phases/01-foundation-charter-and-reproducible-workspace/01-RESEARCH.md, docs/governance/rfc-process.md, docs/governance/decisions/0001-sole-owner-bootstrap.md, docs/rfcs/0001-moonbit-native-foundation.md</files>
  <action>Amend D-03 in `01-CONTEXT.md` to implement the locked latest user decision: while the canonical roster contains exactly one unique maintainer identity and that identity owns the `project-owner` role, the sole owner may use `sole-project-owner-bootstrap` without a second maintainer or a seven-day public-review interval. Preserve D-02's lifecycle and synchronized transition ledger, D-04's accepted-RFC gate, the two-maintainer route, and the project-lead public-review route. Add a supersession note to the historical seven-day research recommendation instead of rewriting research as though it never existed. Update the normative RFC process and RFC 0001 lifecycle prose so the sole-owner route requires the canonical roster, the exact decision artifact and anchors, completed/dispositioned `EDGE-GOV-01-UNCLASSIFIED` and `EDGE-GOV-02-UNCLASSIFIED` reviews, and no unresolved blocking objection; state that eligibility expires whenever the roster has more than one distinct maintainer. Create `docs/governance/decisions/0001-sole-owner-bootstrap.md` with stable headings that yield the exact anchors `owner-instruction`, `conversation-context-and-interpretation`, `authorization-and-conditions`, and `edge-review-results`. Under the first heading quote the user's instruction verbatim: `现在只有我一个人开发，跳过`. Under the context heading record that it answered the assistant's request for D-03 acceptance evidence and is interpreted as the sole project owner's authentic preauthorization to proceed past RFC 0001's acceptance gate once both edge reviews complete without unresolved blockers. Establish the transparent repository identity `sole-project-owner` for this instruction without inferring a legal name or email. Under the authorization heading state that this is the approval Plan 01-08 consumes, not permission to synthesize a later approval, and that neither a second approval nor seven elapsed days is claimed. Leave the edge-review-results section pending and keep RFC 0001 Proposed until 01-08 satisfies the stated conditions.</action>
  <verify>
    <automated>pwsh -NoProfile -Command "$paths=@('.planning/phases/01-foundation-charter-and-reproducible-workspace/01-CONTEXT.md','docs/governance/rfc-process.md','docs/governance/decisions/0001-sole-owner-bootstrap.md','docs/rfcs/0001-moonbit-native-foundation.md');foreach($p in $paths){$t=Get-Content -Raw $p;if($t-notmatch'sole-project-owner-bootstrap'){throw \"missing route in $p\"}};$d=Get-Content -Raw docs/governance/decisions/0001-sole-owner-bootstrap.md;if(-not$d.Contains('现在只有我一个人开发，跳过')){throw 'exact instruction'};foreach($h in @('Owner instruction','Conversation context and interpretation','Authorization and conditions','Edge review results')){if($d-notmatch('(?m)^## '+[regex]::Escape($h)+'$')){throw \"missing anchor heading $h\"}};if($d-notmatch'preauthoriz'-or$d-notmatch'no second.*approval'-or$d-notmatch'no seven.*day'){throw 'decision interpretation'};$r=Get-Content -Raw docs/rfcs/0001-moonbit-native-foundation.md;if($r-notmatch'(?m)^- \*\*Status:\*\* Proposed$'){throw 'premature acceptance'}"</automated>
  </verify>
  <done>The amended D-03, normative process, RFC lifecycle, research supersession note, and decision artifact preserve the exact user instruction and context as conditional preauthorization, truthfully retain Proposed status, and make clear that 01-08 will consume rather than recreate the approval.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Encode and test route-specific fail-closed policy validation</name>
  <files>policy/maintainers.json, policy/foundation.json, policy/phase-01-source-audit.json, scripts/quality/Assert-Policy.ps1, scripts/quality/Test-RfcAcceptance.ps1</files>
  <behavior>
    - Proposed RFC state with empty acceptance evidence remains valid while the route is merely enabled.
    - Accepted `sole-project-owner-bootstrap` state passes only when unique canonical-roster identities total one, that sole identity is the project owner, the exact decision path/anchors are present, both mandatory edge reviews completed, and zero unresolved blockers.
    - The sole-owner route fails for duplicate roster identities, zero or multiple unique maintainers, owner mismatch, missing decision anchors, rooted/traversing/repo-escaping evidence paths, missing edge reviews, or legacy approval-count/review-window assertions.
    - The maintainer route still requires two distinct maintainers; the project-lead route still requires a real interval of at least seven elapsed days.
    - RFC header, RFC index, and structured status must agree.
  </behavior>
  <action>First create canonical `policy/maintainers.json` with a schema version and a maintainers array whose stable identity field is unique. Record exactly one entry with identity `sole-project-owner`, roles `maintainer` and `project-owner`, and evidence pointing to the decision artifact's `owner-instruction` anchor; use this transparent repository identity rather than inventing a legal name or email. Do not store an independently editable maintainer count in foundation policy: validation derives the count from unique roster identities and requires exactly one project-owner identity for the sole-owner route. Add `scripts/quality/Test-RfcAcceptance.ps1` with synthetic policy/RFC/index/roster cases covering every behavior above and make the new route fail against the current validator. Then refactor `Assert-Policy.ps1` around testable `Assert-RfcAcceptanceState` and repository-evidence resolver helpers. In `policy/foundation.json`, add the exact route inventory and branch-specific `project_owner`, decision path, exact anchor names, and two manual edge-review records while keeping current status Proposed and transition evidence empty; set `project_owner` to `sole-project-owner` and require it to equal the sole roster project owner. Require decision path exactly `docs/governance/decisions/0001-sole-owner-bootstrap.md` plus the four anchors named in Task 1. Before reading any evidence, reject `[System.IO.Path]::IsPathRooted`, reject any `..` path segment, normalize with `GetFullPath` against the repository root, and require the normalized path to start with the normalized root plus a directory separator using an ordinal case-insensitive comparison; then require a leaf file and the exact headings/content anchors. Include negative tests for drive-rooted/UNC paths, parent traversal, sibling-prefix escape, owner mismatch, duplicate identities, and multiple unique maintainers. For owner acceptance, reject non-null public-review dates, project-lead identity, or a multi-approver list; retain the original requirements for the other routes. Update the D-03 and research-pitfall source-audit descriptions without changing the exact 1/9/16/29/17/5 inventory or mappings.</action>
  <verify>
    <automated>pwsh -NoProfile -File scripts/quality/Test-RfcAcceptance.ps1; if($LASTEXITCODE){exit $LASTEXITCODE}; pwsh -NoProfile -Command ". ./scripts/quality/Assert-Policy.ps1;Assert-FoundationPolicy -PolicyPath policy/foundation.json -MaintainersPath policy/maintainers.json;Assert-PhaseSourceAudit -AuditPath policy/phase-01-source-audit.json"</automated>
  </verify>
  <done>The canonical roster is the only maintainer-count/owner source, the machine policy represents all three routes without asserting acceptance, exact decision evidence is contained safely under the repository, the full negative matrix fails as intended, and the closed-world Phase 1 audit still passes.</done>
</task>

<task type="auto">
  <name>Task 3: Rewire the RFC index and Plan 01-08 to the authorized owner route</name>
  <files>docs/rfcs/README.md, .planning/phases/01-foundation-charter-and-reproducible-workspace/01-08-PLAN.md, scripts/quality.ps1</files>
  <action>Update the RFC index to document all three routes while keeping RFC 0001 Proposed until 01-08 runs. Rewrite 01-08 so `autonomous: true` and no human-action checkpoint remains. Its first task performs and records both mandatory edge reviews under the existing `edge-review-results` anchor, blocks on any unresolved objection, and verifies roster/owner eligibility. Its second task consumes the already-recorded owner instruction and conditional preauthorization to synchronize Accepted status across RFC 0001, index, and policy; it must not request, infer, or record a new owner approval. Its third task retains Required and exact source-audit qualification. Add the decision artifact and roster to 01-08 `files_modified`/context/must-haves/key links as appropriate. Finally, modify root `scripts/quality.ps1` so the Required lane invokes `scripts/quality/Test-RfcAcceptance.ps1` with terminating failure semantics as part of the canonical controller, while `LlvmExperimental` remains unaffected. Preserve fail-closed behavior if an edge review exposes a blocker.</action>
  <verify>
    <automated>pwsh -NoProfile -Command "$p='.planning/phases/01-foundation-charter-and-reproducible-workspace/01-08-PLAN.md';$t=Get-Content -Raw $p;if($t-notmatch'(?m)^autonomous: true$'-or$t-match'checkpoint:human-action'-or$t-notmatch'sole-project-owner-bootstrap'-or$t-notmatch'0001-sole-owner-bootstrap.md'-or$t-notmatch'maintainers[.]json'-or$t-notmatch'preauthoriz'){throw '01-08 route wiring'};$q=Get-Content -Raw scripts/quality.ps1;if($q-notmatch"Lane -ceq 'Required'"-or$q-notmatch'Test-RfcAcceptance[.]ps1'){throw 'Required test wiring'}"; node C:/Users/Admin/.codex/gsd-core/bin/gsd-tools.cjs query verify.plan-structure .planning/phases/01-foundation-charter-and-reproducible-workspace/01-08-PLAN.md; pwsh -NoProfile -File scripts/quality.ps1 -Lane Required</automated>
  </verify>
  <done>The index truthfully exposes the route, 01-08 consumes the exact preauthorization only after successful edge reviews, the Required controller always executes the acceptance matrix, and all Required checks pass before Phase 1 resumes.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|---|---|
| Project-owner instruction -> normative governance | The exact contextual instruction is preauthorization and must not be replaced by an agent-authored approval. |
| Maintainer roster -> route eligibility | Unique identities and the sole owner role determine whether the bootstrap authority exists. |
| Policy record -> Accepted RFC state | Structured evidence controls whether a governance transition is permitted. |
| Evidence path -> repository filesystem | Untrusted structured paths must remain relative and contained under the normalized repository root. |
| Executor edge review -> preauthorized transition | Agent-produced review findings must not unlock the existing owner authorization while a blocker remains. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|---|---|---|---|---|---|
| T-PML-01 | Spoofing/Repudiation | sole-owner authority | high | mitigate | Preserve the exact instruction and context as preauthorization; prohibit a later synthesized approval. |
| T-PML-02 | Tampering | route-specific fields | high | mitigate | Test branch-specific required and forbidden fields in `Assert-RfcAcceptanceState`. |
| T-PML-03 | Repudiation | skipped legacy prerequisites | medium | mitigate | State explicitly that neither a second approval nor seven elapsed days occurred. |
| T-PML-04 | Elevation of Privilege | route lifetime | high | mitigate | Derive eligibility from unique roster identities and invalidate the route unless exactly one maintainer is the project owner. |
| T-PML-05 | Tampering | decision evidence path | high | mitigate | Reject rooted/traversing paths, normalize under repo root with separator-safe containment, and require the exact artifact and anchors. |
</threat_model>

<verification>
Run the RFC acceptance matrix including roster and path-containment attacks, direct foundation/source-audit validators, 01-08 plan-structure validation, and the full Required quality lane. Confirm the Required controller itself invokes the matrix. Inspect the final quick-task diff to confirm RFC 0001 remains Proposed until the rewritten 01-08 plan completes both edge reviews and consumes the existing preauthorization.
</verification>

<success_criteria>
- A repository-tracked sole-owner route preserves `现在只有我一个人开发，跳过` and its conversation context as conditional preauthorization without claiming missing approvals or time.
- A canonical roster supplies unique maintainer identities and the sole owner; no independently editable count can keep an expired route alive.
- Governance prose, decision sources, roster, policy, validator tests, RFC index, Required controller, and Plan 01-08 use one canonical route and evidence contract.
- Rooted, traversing, repo-escaping, wrong-artifact, missing-anchor, owner-mismatch, duplicate-identity, and multi-maintainer evidence fails automatically; existing routes retain their requirements.
- Plan 01-08 can autonomously complete the edge reviews, consume the preauthorization without creating a later approval, and run final qualification.
</success_criteria>

<output>
Create `.planning/quick/260716-pml-bootstrap-rfc-01-08-validate/260716-pml-SUMMARY.md` when done.
</output>
