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
| `Draft` | The author is developing the proposal; it is not yet ready to guide implementation. | `Proposed`, `Rejected` |
| `Proposed` | The proposal is reviewable and ready to guide implementation. This is the state at which an RFC authorizes the changes described in §6. | `Rejected`, `Superseded` |
| `Rejected` | The proposal was withdrawn. This is terminal for this RFC number. | None |
| `Superseded` | Another identified RFC replaces this RFC. This is terminal for this RFC number. | None |

The lifecycle is `Draft -> Proposed`. `Rejected` and `Superseded` are terminal states. A superseding transition must identify the replacement RFC.

Every transition MUST update the RFC header's status and transition ledger in the same change. Repository history records the change.

> **Historical note.** This process previously defined `Accepted` and `Implemented` states with three acceptance authority routes (maintainer, project-lead public-review, sole-project-owner-bootstrap). Those were removed on 2026-07-23 as disproportionate for a sole-owner project. The historical acceptance and edge-review records under `docs/governance/decisions/` are retained as accurate history, not as live process requirements.

## 3. Proposal and review

A Draft becomes Proposed when its scope, owned and excluded responsibilities, dependency impact, portability impact, alternatives, compatibility consequences, and verification plan are reviewable. A Proposed RFC is sufficient to proceed with the changes it describes (see §6).

An RFC should be reviewed for correctness, security, compatibility, and feasibility before implementation merges. Issues found during review are recorded against the RFC; the author resolves them by revising the RFC (which stays Proposed) or withdraws it to `Rejected`.

## 4. Required transition evidence

An RFC header and transition ledger MUST record:

- the prior and new statuses; and
- the superseding RFC for a `Superseded` transition.

Records must be accurate. Do not fabricate or infer transition evidence; repository history is the record.

## 5. Changes that require a Proposed RFC

The following changes require a Proposed RFC before their implementation may merge:

- creating a new MNF module;
- adding, removing, or reversing a public dependency direction;
- making a breaking change to an established architectural layer or module responsibility;
- breaking an established portability seam, governance rule, or other public architectural boundary.

Implementation PRs may not silently redefine an established boundary. When implementation discovers a necessary boundary change, it must pause that change, propose an RFC, and bring it to Proposed before resuming.

## 6. Terminal states

`Rejected` and `Superseded` are terminal for that RFC number. Further work requires a new RFC that links the terminal record rather than rewriting its history.

## 7. Discoverability and consistency

The [RFC index](../rfcs/README.md) lists every RFC and its current status. The index, RFC header, and transition ledger must agree. On disagreement, the records must be corrected before the RFC is relied upon.
