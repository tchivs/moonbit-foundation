# MoonBit Native Foundation RFCs

Architectural proposals and governance records for MoonBit Native Foundation.

The [RFC process](../governance/rfc-process.md) defines lifecycle, review authority, evidence, and the changes that require an accepted RFC. Repository history and each RFC's transition ledger are the authoritative transition record.

## Status

RFC 0001 is **Accepted** through `sole-project-owner-bootstrap`. The transition consumes the
existing conditional preauthorization in the [sole-owner decision](../governance/decisions/0001-sole-owner-bootstrap.md#owner-instruction)
after both mandatory reviews were completed with no unresolved blocking objection; it claims
neither a second approval nor a seven-day public-review interval.

## Scope

RFCs govern architectural layers, module responsibilities, public dependency direction, portability seams, and other breaking public boundaries. Implementation may refine internals inside accepted boundaries, but it may not silently redefine them.

## RFC list

| RFC | Title | Status | Scope |
|---|---|---|---|
| [RFC 0001](0001-moonbit-native-foundation.md) | MoonBit Native Foundation | Accepted | Canonical foundation charter and v0.1 architecture |

## Lifecycle

The normal path is `Draft -> Proposed -> Accepted -> Implemented`. `Rejected` and `Superseded` are terminal states. Acceptance requires an evidenced authority route and no unresolved blocking objection; missing evidence leaves a proposal at Proposed.

The available acceptance routes are:

- `maintainer`: two distinct canonical-maintainer approvals;
- `project-lead-public-review`: an eligible project lead plus at least seven elapsed days of evidenced public review while fewer than two maintainers exist; and
- `sole-project-owner-bootstrap`: exactly one canonical maintainer who is also the project owner, the exact [sole-owner decision](../governance/decisions/0001-sole-owner-bootstrap.md), both mandatory edge reviews completed and dispositioned, and no unresolved blocker.

The sole-owner route consumes the recorded conditional preauthorization; it never synthesizes a later approval and expires when another distinct maintainer is added. RFC 0001 satisfied those conditions through the completed [edge-review results](../governance/decisions/0001-sole-owner-bootstrap.md#edge-review-results), and its Accepted state is synchronized with machine policy.

## Next step

Implement and qualify [RFC 0001](0001-moonbit-native-foundation.md) under the [normative RFC process](../governance/rfc-process.md). Future transitions must retain authentic route-specific evidence and update the RFC ledger, this index, and machine policy together.
