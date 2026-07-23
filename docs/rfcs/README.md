# MoonBit Native Foundation RFCs

Architectural proposals and governance records for MoonBit Native Foundation.

The [RFC process](../governance/rfc-process.md) defines lifecycle, review authority, evidence, and the changes that require an accepted RFC. Repository history and each RFC's transition ledger are the authoritative transition record.

## Status

All RFCs are at **Proposed** status. The lifecycle is `Draft -> Proposed`; a Proposed RFC is reviewable and sufficient to guide implementation. The acceptance machinery this index previously described (authority routes, seven-day public-review windows, mandatory edge reviews) was removed on 2026-07-23 as disproportionate for a sole-owner project. The [historical acceptance records](../governance/decisions/) are retained as accurate history.

## Scope

RFCs govern architectural layers, module responsibilities, public dependency direction, portability seams, and other breaking public boundaries. Implementation may refine internals inside established boundaries, but it may not silently redefine them.

## RFC list

| RFC | Title | Status | Scope |
|---|---|---|---|
| [RFC 0001](0001-moonbit-native-foundation.md) | MoonBit Native Foundation | Proposed | Canonical foundation charter and v0.1 architecture |
| [RFC 0002](0002-mb-svg.md) | mb-svg Charter | Proposed | Document and Scene Layer SVG module charter, bounded v0.x subset, and rasterization-seam resolution |
| [RFC 0003](0003-mb-canvas.md) | mb-canvas Charter | Proposed | Graphics Layer drawing-list and portable rasterization charter, compositing-delegation boundary, and v0.x scope |
| [RFC 0004](0004-mb-font.md) | mb-font Charter | Proposed | Document and Scene Layer font-binary parsing and glyph outline/metrics charter, font-versus-rasterization boundary, and v0.x scope |
| [RFC 0005](0005-mb-text.md) | mb-text Charter | Proposed | Document and Scene Layer Unicode text layout, bidi, shaping, and line-breaking charter, text-versus-font/rasterization boundaries, and v0.x scope |
| [RFC 0006](0006-mb-pdf.md) | mb-pdf Charter | Proposed | Document and Scene Layer PDF container parsing and serialization charter, container-versus-renderer boundary, and v0.x scope |
| [RFC 0007](0007-mb-layout.md) | mb-layout Charter | Proposed | Document and Scene Layer document-flow pagination, columns, and float layout charter, paragraph-versus-document-flow boundary, and v0.x scope |

## Lifecycle

The lifecycle is `Draft -> Proposed`. A Proposed RFC is reviewable and sufficient to proceed with the changes it describes. `Rejected` and `Superseded` are terminal states.

## Next step

Implement and qualify [RFC 0001](0001-moonbit-native-foundation.md) and the proposed module charters under the [normative RFC process](../governance/rfc-process.md). New modules, public dependency-direction changes, and breaking boundary changes require a Proposed RFC before implementation may merge.
