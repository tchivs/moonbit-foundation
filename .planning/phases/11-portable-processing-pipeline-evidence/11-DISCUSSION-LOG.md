# Phase 11: Portable Processing Pipeline Evidence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-20
**Phase:** 11-Portable Processing Pipeline Evidence
**Areas discussed:** pipeline scope, cross-target evidence, benchmark boundary

---

## Pipeline scope

| Option | Description | Selected |
|--------|-------------|----------|
| Synthetic internal test | Does not prove public codec and API composition | |
| Public PPM pipeline | Uses real decode, processing, and encode APIs | ✓ |

**User's choice:** Auto-selected the public PPM pipeline.

## Cross-target evidence

| Option | Description | Selected |
|--------|-------------|----------|
| One host target | Leaves portable behavior unproven | |
| All supported targets | js, wasm, wasm-gc, and native are required | ✓ |

**User's choice:** Auto-selected four-target evidence.

## Benchmark boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Generic speed claim | Not reproducible or useful for maintainers | |
| Declared local baseline | Fixed workload and recorded reproducible evidence | ✓ |

**User's choice:** Auto-selected a declared local baseline without release tooling.

## the agent's Discretion

- Reuse the smallest existing example and benchmark patterns compatible with the requirements.

## Deferred Ideas

- Registry and release work remain deferred.
