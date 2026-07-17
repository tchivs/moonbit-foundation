# Phase 3: Reference Color Semantics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-17
**Phase:** 03-reference-color-semantics
**Areas discussed:** Component and encoding model, sRGB numeric contract, Alpha semantics, Profile boundary, Reference evidence and package boundary

---

## Component and encoding model

| Option | Description | Selected |
|--------|-------------|----------|
| Opaque explicit descriptors | Validated component types plus explicit space, transfer, and alpha state; no universal bag | ✓ |
| Public fields with conventions | Flexible records whose validity relies on caller discipline | |
| Single convenience Color type | One broad type with implicit or default metadata | |

**User's choice:** Auto-selected the recommended opaque explicit model.
**Notes:** This preserves Phase 2's invalid-state and structured-error patterns and prevents image layers from guessing color semantics.

---

## sRGB numeric contract

| Option | Description | Selected |
|--------|-------------|----------|
| Validated normalized domain and explicit quantization | Reject non-finite/out-of-range input; normative curve; explicit ties-to-even conversion | ✓ |
| Accept arbitrary floats and clamp | Broad input convenience with hidden lossy normalization | |
| Byte-only conversion | Avoid reference floats but lose a reusable semantic oracle | |

**User's choice:** Auto-selected validated normalized reference values plus explicit quantization.
**Notes:** Exact constants and tolerances remain a research task and must be tied to primary specifications.

---

## Alpha semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit states with canonical zero | Separate straight/premultiplied state, checked widened math, canonical zero alpha | ✓ |
| Implicit alpha convention | Callers infer representation from context | |
| Clamp invalid premultiplied values | Accept component greater than alpha and silently repair | |

**User's choice:** Auto-selected explicit states, canonical zero, and checked deterministic rounding.
**Notes:** Round-trip claims are limited to mathematically guaranteed cases; error bounds must be documented otherwise.

---

## Profile boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded opaque round-trip seam | Preserve tagged bytes using mb-core storage/budgets without parsing | ✓ |
| Full ICC parser | Parse and evaluate profile contents in Phase 3 | |
| Identifier string only | Preserve a name but not codec metadata bytes | |

**User's choice:** Auto-selected the bounded opaque seam.
**Notes:** A digest may identify payloads but cannot imply semantic equivalence or conformance.

---

## Reference evidence and package boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Official vectors plus focused packages | Provenance/digest fixtures, explicit tolerances, invariants, exact package DAG | ✓ |
| Ad hoc golden values | Local examples without authoritative provenance | |
| Broad all-in-one color package | One root package covering current and speculative color features | |

**User's choice:** Auto-selected official evidence and focused acyclic packages.
**Notes:** Four targets, checked README examples, exact interfaces, negative fixtures, and read-only proof stay mandatory.

## the agent's Discretion

- Exact MoonBit names and internal package decomposition.
- Exact tolerance magnitudes and fixture serialization after primary-source research.
- Additional property/adversarial tests within the fixed Phase 3 boundary.

## Deferred Ideas

- Full ICC parsing and evaluation.
- Additional spaces/transfers, chromatic adaptation, gamut mapping, interpolation, and CSS syntax.
- Image layout, codecs, and rendering.
