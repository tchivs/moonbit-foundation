# MoonBit Native Foundation

Native Infrastructure for MoonBit.

MNF is an RFC-led initiative for building composable, native-first infrastructure libraries in MoonBit. The project begins by defining shared contracts, module boundaries, portability rules, and quality gates before implementing the first foundation packages.

The canonical project proposal is [RFC 0001](docs/rfcs/0001-moonbit-native-foundation.md). Delivery planning lives in [`.planning/`](.planning/PROJECT.md).

## Status

Pre-implementation / RFC stage. No API is stable yet.

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

## Next step

Discuss and plan Phase 1 from [the roadmap](.planning/ROADMAP.md).
