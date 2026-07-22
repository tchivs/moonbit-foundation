# Phase 40: Portable Adaptive-Filter Evidence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-22
**Phase:** 40-portable-adaptive-filter-evidence
**Areas discussed:** evidence corpus, comparison contract, portable public proof, scope fence

---

## Evidence corpus and comparison

| Option | Description | Selected |
|--------|-------------|----------|
| Generated deterministic corpus | Small executable RGB8/RGBA8 sources committed with tests | ✓ |
| External binary fixtures | Store PNG corpus files and provenance metadata | |

**User's choice:** Autonomous recommended default, authorized by the standing instruction to select the best option.
**Notes:** Generated fixtures make the size relation reproducible without adding fixture management.

## Portable public proof

| Option | Description | Selected |
|--------|-------------|----------|
| Public eager/chunk/decode path | Validate public APIs under hostile capacities on all targets | ✓ |
| White-box-only proof | Verify internal bytes without public interoperability evidence | |

**User's choice:** Autonomous recommended default.
**Notes:** Matches Phase 40 success criteria and avoids new API surface.

## the agent's Discretion

- Select minimal stable fixture patterns and exact named target commands.

## Deferred Ideas

- Benchmark dashboards and broader performance claims remain outside this evidence-only phase.
