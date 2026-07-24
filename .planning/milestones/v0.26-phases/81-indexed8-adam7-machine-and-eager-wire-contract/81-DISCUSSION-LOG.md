# Phase 81: Indexed8 Adam7 Machine and Eager Wire Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-24
**Phase:** 81-indexed8-adam7-machine-and-eager-wire-contract
**Areas discussed:** Public layout selection, pass traversal, bounded preflight, wire evidence

---

## Public layout selection

| Option | Description | Selected |
|--------|-------------|----------|
| Add explicit Indexed8 Adam7 selection while freezing legacy wrappers | Adds capability without changing old calls or bytes | ✓ |
| Change legacy Indexed8 behavior | Would break compatibility | |

**User's choice:** Automatic recommended selection under the standing project instruction to choose the optimal option.
**Notes:** Keep Indexed1/2/4 Adam7 out of scope until packed traversal has its own contract.

---

## Pass traversal and bounded preflight

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse the sole machine and Adam7 geometry with scalar indexed reads | Preserves boundedness and avoids staging | ✓ |
| Add an indexed-specific encoder or staged raster | Duplicates transport and expands memory risk | |

**User's choice:** Automatic recommended selection.
**Notes:** All pass facts must be admitted before output or budget mutation.

---

## Wire evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Independent seven-pass raw-raster oracle plus public decode and frozen vectors | Detects shared traversal defects and compatibility drift | ✓ |
| Eager/chunk parity only | Cannot independently validate shared traversal | |

**User's choice:** Automatic recommended selection.
**Notes:** Phase 82 will add caller-buffered hostile lease qualification.

---

## the agent's Discretion

- Internal helper factoring and exact additive method spelling, constrained by existing selector families.

## Deferred Ideas

- Indexed low-bit Adam7 and strategy expansion remain later work.
