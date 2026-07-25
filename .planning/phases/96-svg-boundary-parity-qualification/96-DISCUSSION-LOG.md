# Phase 96: SVG Boundary Parity Qualification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-26
**Phase:** 96-svg-boundary-parity-qualification
**Areas discussed:** Boundary publication, parity evidence, compatibility controls

---

## Boundary publication

| Option | Description | Selected |
|--------|-------------|----------|
| Fail only during lowering | Permit parse publication | |
| Fail at parser boundary | Preserve fail-closed error timing | ✓ |

**User's choice:** Automatic recommended compatibility default.
**Notes:** Existing parser contract remains authoritative; total lowerer recovery applies only to manually invalid public scenes.

---

## Parity evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Source-text checks | Compare duplicated implementation text | |
| Semantic controls | Assert shared numeric outcomes and observable behavior | ✓ |

**User's choice:** Automatic recommended compatibility default.
**Notes:** Controls are target-neutral and adversarial.

---

## Compatibility controls

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow native-only tests | Faster but incomplete qualification | |
| All-target semantic tests | Exercise wasm, wasm-gc, js, and native | ✓ |

**User's choice:** Automatic recommended compatibility default.
**Notes:** Preserve finite scale(0) and RFC 0008 opacity/layer behavior.

---

## the agent's Discretion

Choose the smallest deterministic additions to existing SVG tests.

## Deferred Ideas

None.
