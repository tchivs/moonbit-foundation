# MoonBit Native Foundation

Native Infrastructure for MoonBit.

MNF is an RFC-led initiative for building composable, native-first infrastructure libraries in MoonBit. Shared contracts, module boundaries, portability rules, and quality gates govern three independently publishable foundation modules.

The canonical project proposal is [RFC 0001](docs/rfcs/0001-moonbit-native-foundation.md). Delivery planning lives in [`.planning/`](.planning/PROJECT.md).

## Status

The `0.1.0` module family is an unpublished candidate. No API is stable yet, and public publication remains blocked until the exact Mooncakes authority and registry state are verified.

The initial registry owner is the sole maintainer's personal namespace. The canonical module identities are `tchivs/mb-core`, `tchivs/mb-color`, and `tchivs/mb-image`; this operational owner does not rename the **MoonBit Native Foundation** project. The repository URL `https://github.com/tchivs/moonbit-foundation` is intended metadata only and is not yet verified live.

## Initial scope

- `mb-core`: byte buffers, streams, I/O abstractions, errors, and diagnostics
- `mb-color`: color types, conversions, and profile boundaries
- `mb-image`: image storage, pixel formats, transforms, and codec interfaces

Graphics, fonts, SVG, PDF, GPU, AI, and MCP layers remain part of the broader architecture, but are staged after the foundation contracts are validated.

## Design commitments

- Pure MoonBit for core algorithms wherever practical
- Native-first delivery with explicit portability across supported MoonBit targets
- Independently consumable modules with versioned public contracts
- No dependency on a particular GUI, web, game, or application runtime
- Deterministic, automation-friendly APIs suitable for CLI, agents, and MCP tools

## Namespace evolution

No previous module version was published under the superseded bootstrap owner, so the personal-namespace correction keeps version `0.1.0` and requires no migration note. If an organization namespace becomes available later, MNF will publish new identities through an explicit forward migration; it does not assume registry rename, transfer, overwrite, delete, unpublish, or yank support.

Current delivery and publication work is tracked in [the roadmap](.planning/ROADMAP.md).
