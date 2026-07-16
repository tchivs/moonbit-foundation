# Target Support Policy

## Status

Portable v0.1 packages must support the complete required target set. The exact set, package declarations, and experimental targets are owned by [`policy/foundation.json`](../../policy/foundation.json).

## Required scope

| Package category | Contract |
|---|---|
| Portable public package | Declare and validate every target in the canonical required set |
| Native host adapter | Declare `native` explicitly and remain an isolated dependency leaf |
| Experimental backend | Run separately and never satisfy or mask the required target gate |

Native is the preferred development and system-integration target, but it does not weaken the portable contract. Package metadata narrows capability intentionally; support is never inferred from repository location or from an omitted declaration.

LLVM remains experimental and outside required support. An LLVM job, when present, is non-blocking and visibly separate from the required matrix.

## Out of scope

Target-specific host APIs, system codecs, devices, and foreign libraries do not belong in portable public packages. They enter through explicit capabilities or narrow native leaf adapters.

## Observable outcome

A contributor can compare every public package declaration with `policy/foundation.json`, and CI can fail when a required target is missing, an extra target is treated as required, or a native adapter contaminates a portable dependency.
