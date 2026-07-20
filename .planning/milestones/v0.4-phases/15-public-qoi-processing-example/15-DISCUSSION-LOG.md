# Phase 15: Public QOI Processing Example - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-20
**Phase:** 15-Public QOI Processing Example
**Areas discussed:** public example boundary, processing operation, deterministic evidence

---

## Public example boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Separate QOI portable executable | Keep the QOI consumer directly runnable and independent from the PPM example. | ✓ |
| Extend the PPM example | Mix QOI behavior into an existing PPM-focused consumer. | |

**User's choice:** Separate QOI portable executable (automatic best-fit selection).
**Notes:** Keeps code and test scope clear without new infrastructure.

---

## Processing operation

| Option | Description | Selected |
|--------|-------------|----------|
| Horizontal flip | One directly observable existing operation with minimal example complexity. | ✓ |
| Full processing pipeline | Recreate the larger PPM demonstration for QOI. | |

**User's choice:** Horizontal flip (automatic best-fit selection).
**Notes:** The phase calls for one existing operation; the small example is easier to run and verify on every target.

---

## Deterministic evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Exact bytes plus digest | Assert canonical QOI bytes, then print stable evidence after all assertions. | ✓ |
| Informal successful exit | Rely on the process exit status alone. | |

**User's choice:** Exact bytes plus digest (automatic best-fit selection).
**Notes:** The same output markers will be required on js, wasm, wasm-gc, and native.

---

## the agent's Discretion

- Choose minimal fixture bytes and status-line wording only after cross-target execution confirms them.

## Deferred Ideas

- External file inputs, CLI flags, multi-operation pipelines, streaming, registries, FFI, benchmarks, and release automation remain future work.
