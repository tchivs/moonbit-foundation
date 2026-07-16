# MoonBit Native Foundation RFC Process

- **Status:** Normative for RFC review and transitions
- **Scope:** Architectural proposals and accepted public boundaries
- **Canonical charter:** [RFC 0001](../rfcs/0001-moonbit-native-foundation.md)
- **RFC index:** [docs/rfcs/README.md](../rfcs/README.md)
- **Evidence policy:** Fail closed; unevidenced transition claims are invalid

## 1. Purpose

This document defines how an MNF RFC moves through review, who may accept it, how blocking objections are resolved, what evidence must be recorded, and which changes require an accepted RFC. It governs transition mechanics; [RFC 0001](../rfcs/0001-moonbit-native-foundation.md) remains the single architectural charter.

## 2. Lifecycle

| Status | Meaning | Permitted next states |
|---|---|---|
| `Draft` | The author is developing the proposal; it is not ready for an acceptance decision. | `Proposed`, `Rejected` |
| `Proposed` | The proposal is public and ready for review; implementation may experiment but cannot claim an accepted boundary. | `Accepted`, `Rejected`, `Superseded` |
| `Accepted` | An authorized acceptance route is satisfied, objections are resolved, and authentic evidence is recorded. | `Implemented`, `Superseded` |
| `Implemented` | The accepted proposal's required implementation and qualification are complete. | `Superseded` |
| `Rejected` | Review concluded without acceptance. This is terminal for this RFC number. | None |
| `Superseded` | Another identified RFC replaces this RFC. This is terminal for this RFC number. | None |

The normal lifecycle is `Draft -> Proposed -> Accepted -> Implemented`. `Rejected` and `Superseded` are terminal states. A superseding transition must identify the replacement RFC.

Every transition MUST update the RFC header's status and transition ledger in the same change. Repository history records the change; the ledger points to the review and authority evidence that justifies it.

## 3. Proposal and review

A Draft becomes Proposed when its scope, owned and excluded responsibilities, dependency impact, portability impact, alternatives, compatibility consequences, and verification plan are reviewable. The transition does not imply approval.

Review stays open while a blocking objection is unresolved. A blocking objection must identify the violated project constraint or material correctness, security, compatibility, governance, or feasibility risk. The proposer and reviewers must record whether it was resolved, withdrawn, or made the reason for rejection. Silence is not evidence that no objection exists.

## 4. Acceptance authority

An RFC may move from Proposed to Accepted through exactly one of these routes:

### 4.1 Maintainer route

- at least two distinct maintainer approvals are recorded;
- no blocking objection remains unresolved; and
- the RFC ledger links the approvals and objection disposition.

### 4.2 Project-lead public-review route

Only while the project has fewer than two maintainers, the project lead may accept an RFC when:

- a minimum seven-day public review window has elapsed;
- the public review location and its opening and closing evidence are recorded;
- the project lead's approval is recorded; and
- no blocking objection remains unresolved.

The bootstrap exception expires immediately when two maintainers are available. It does not reduce the evidence or objection requirements.

### 4.3 Sole project-owner bootstrap route

The `sole-project-owner-bootstrap` route is available only while the canonical
[`policy/maintainers.json`](../../policy/maintainers.json) roster contains exactly one distinct
maintainer identity and that same identity has the `project-owner` role. It requires:

- the exact decision artifact
  [`docs/governance/decisions/0001-sole-owner-bootstrap.md`](decisions/0001-sole-owner-bootstrap.md),
  including the anchors `owner-instruction`, `conversation-context-and-interpretation`,
  `authorization-and-conditions`, and `edge-review-results`;
- completed, dispositioned records for `EDGE-GOV-01-UNCLASSIFIED` and
  `EDGE-GOV-02-UNCLASSIFIED` under `edge-review-results`; and
- no unresolved blocking objection.

The recorded owner instruction is conditional preauthorization that Plan 01-08 consumes after
the edge reviews pass. It is not permission to synthesize a later approval. This route claims
neither a second maintainer approval nor a seven-day public-review interval. Eligibility expires
immediately when the canonical roster contains more than one distinct maintainer.

## 5. Required transition evidence

An RFC header and transition ledger MUST record, as applicable:

- the prior and new statuses;
- links or repository references for each approval;
- the identities and roles of approving maintainers or the project lead;
- the public review location and evidenced interval for the bootstrap route;
- the canonical roster identity, exact decision artifact, and mandatory edge-review results for
  the `sole-project-owner-bootstrap` route;
- every blocking objection and its resolution, withdrawal, or rejecting disposition;
- the superseding RFC for a `Superseded` transition; and
- implementation and qualification evidence for an `Implemented` transition.

**PROH-GOV-02-EVIDENCE:** An RFC MUST NOT record acceptance, approvals, review duration, or absence of blocking objections without authentic evidence. Empty, placeholder, inferred, or fabricated evidence fails closed: the RFC remains Proposed.

## 6. Changes that require an accepted RFC

The following changes require an Accepted RFC before their implementation may merge:

- creating a new MNF module;
- adding, removing, or reversing a public dependency direction;
- making a breaking change to an accepted architectural layer or module responsibility;
- breaking an accepted portability seam, governance rule, or other public architectural boundary.

Implementation PRs may not silently redefine an accepted boundary. When implementation discovers a necessary boundary change, it must pause that change, propose an RFC, complete the review process, and link the resulting acceptance evidence before resuming.

## 7. Implementation and terminal states

Accepted becomes Implemented only when the RFC's stated implementation and qualification criteria are complete and linked. An accepted but unfinished RFC remains Accepted.

Rejected and Superseded are terminal for that RFC number. Further work requires a new RFC that links the terminal record rather than rewriting its history.

## 8. Required manual edge review

Every RFC that selects the sole-project-owner bootstrap route must explicitly complete and record
these checks before acceptance:

- **EDGE-GOV-01-UNCLASSIFIED:** Manually review the accepted charter for an omitted architectural boundary case.
- **EDGE-GOV-02-UNCLASSIFIED:** Manually review lifecycle and acceptance authority for an omitted transition or authority case.

The checks remain permanent route requirements; listing them here is not itself completion evidence.
RFC 0001 completed and dispositioned both checks in the canonical
[edge-review results](decisions/0001-sole-owner-bootstrap.md#edge-review-results). Any case found by
a future application of this route must be resolved in the governing RFC or process before acceptance.

## 9. Discoverability and consistency

The [RFC index](../rfcs/README.md) lists every RFC and its current status. The index, RFC header, and transition ledger must agree. On disagreement or missing evidence, tooling and reviewers must use the less advanced truthful state and block the disputed transition until the records are corrected.
