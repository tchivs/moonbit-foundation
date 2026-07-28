# Phase 102: Root-Relative Selected-Face Admission - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-28
**Phase:** 102-root-relative-selected-face-admission
**Mode:** `--auto`; the user authorized selecting the optimal recommended option
**Areas discussed:** Public selected-face contract, root-relative admission seam, cached facts and mixed siblings, limits and budget ownership, failure precedence and lifetime, collection checksum policy, deferred boundaries

---

## Public selected-face contract

| Option | Description | Selected |
|--------|-------------|----------|
| `open_face` returning existing `Font` | One fallible resource-bearing operation; all shipped queries remain unchanged | ✓ |
| `select_face` wrapper | Adds a new public wrapper/provenance type | |
| Public `CollectionFace` | Duplicates or forwards the complete font query surface | |

**Choice:** One `FontCollection::open_face` operation returning existing `Font`.

## Root-relative admission seam

| Option | Description | Selected |
|--------|-------------|----------|
| Offset-aware root seam | Absolute directory start; table offsets remain collection-root-relative | ✓ |
| Directory subview/rebase | Reuses zero-based parser but misinterprets TTC table offsets | |
| Reconstruct standalone bytes | Copies/materializes a synthetic SFNT | |

**Choice:** Private offset-aware seam with explicit checksum mode.

## Cached facts and mixed siblings

| Option | Description | Selected |
|--------|-------------|----------|
| Selected-only reparse | Reuse compact Phase 101 authority facts; semantically admit only selected face | ✓ |
| Eager all-face admission | Retains large semantic state and makes unsupported siblings blocking | |
| Full rescan per selection | Makes selection cost depend on unrelated siblings | |

**Choice:** Selected-only reparse; exact sharing uses local root subviews and unsupported siblings do not poison a supported selection.

## Limits and budget ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Split root ceiling / selected charge | Root extent is bounded; selected directory and distinct referenced tables determine work/charge | ✓ |
| Charge whole collection root | Repeated small selections pay for unrelated payloads | |
| Inherit collection transaction | Selection outcome depends on collection-opening budget history | |

**Choice:** Independent selected-face transaction with staged authority and one final aggregate commit; preserve standalone helper charging through a private collection-mode ledger.

## Failure precedence and lifetime

| Option | Description | Selected |
|--------|-------------|----------|
| Revision-first staged order | Revision, index, profile, authority stages, semantics, final revision, charge, publish | ✓ |
| Index-first | Leaks index/profile outcomes from a stale collection | |
| Resource-first | Reverses established structural and state precedence | |

**Choice:** Revision-first staged order; returned `Font` retains the collection root and opening revision.

## Collection checksum policy

| Option | Description | Selected |
|--------|-------------|----------|
| Per-table checks only in collection mode | Keep table integrity/head zeroing; skip standalone aggregate adjustment | ✓ |
| All standalone checks | Rejects valid TTCs whose whole collection is not a standalone SFNT | |
| Disable checksums | Admits corrupted selected tables | |

**Choice:** Explicit collection checksum mode, with standalone mode unchanged.

## Deferred boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Adapter-only static `glyf` slice | Delivers TTC-02/TTC-03 without expanding the font engine | ✓ |
| Add CFF/variable execution | New outline/variation capabilities | |
| Add extraction/materialization | New authoring/serialization capability | |

**Choice:** Adapter-only slice. Phase 103 owns broad qualification and licensed evidence.

## the agent's Discretion

- Private helper/type names, file splits, internal ledger shape, and focused builder refactors.

## Deferred Ideas

- None.
