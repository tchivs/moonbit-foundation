# Phase 2: Bounded Core Primitives - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-16
**Phase:** 2-bounded-core-primitives
**Areas discussed:** Checked numeric and range semantics, Owned bytes and view aliasing, Stream outcomes and optional seeking, Diagnostics, budgets, and host capabilities

---

## Checked numeric and range semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Structured checked results | Fail before access/allocation with portable structured failures | ✓ |
| Panics for programmer errors | Treat invalid caller-controlled values as unrecoverable | |
| Saturating arithmetic | Clamp values and continue | |

**User's choice:** Auto-selected the recommended structured checked-result model.
**Notes:** Half-open ranges, valid empty operations, non-zero power-of-two alignment, and explicit-width logical quantities were selected to make behavior reproducible across backends.

---

## Owned bytes and view aliasing

| Option | Description | Selected |
|--------|-------------|----------|
| Opaque backing-retaining views | Validated zero-copy windows retain owned backing storage | ✓ |
| Copy every slice | Avoid aliasing by allocating for all subranges | |
| Expose raw arrays and offsets | Leave range validation to callers | |

**User's choice:** Auto-selected opaque backing-retaining views with exclusive or validated-disjoint mutation.
**Notes:** Immutable aliases may coexist; simultaneous overlapping mutable aliases are not part of the public v0.1 API.

---

## Stream outcomes and optional seeking

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit progress/EOS/failure outcomes | Preserve partial progress and make EOF distinct | ✓ |
| Zero bytes always means EOF | Collapse no-progress and EOF | |
| Exception-only APIs | Report stream state only through thrown failures | |

**User's choice:** Auto-selected explicit outcomes and a separate seek capability.
**Notes:** Exact helpers loop safely, detect no-progress, preserve completed counts, and bounded wrappers enforce independent logical windows.

---

## Diagnostics, budgets, and host capabilities

| Option | Description | Selected |
|--------|-------------|----------|
| Structured errors, precharged shared budgets, fine-grained capabilities | Stable tools-facing failures and no ambient-state or child-budget bypass | ✓ |
| Free-form strings and post-accounting | Simpler surface with weaker enforcement | |
| Global host singleton | Central ambient access to all host functions | |

**User's choice:** Auto-selected the recommended structured and explicitly injected model.
**Notes:** Rendering is deterministic; budget rejection occurs before work; child scopes share parent allowance; portable in-memory implementations are in scope while concrete native adapters are deferred.

## the agent's Discretion

- Exact MoonBit names, internal representations, package split, and plan waves.
- Additional property, invariant, and adversarial tests that strengthen the locked behavior.

## Deferred Ideas

- Concrete native host adapters beyond the contract surface.
- Image- and codec-specific limits and policies owned by Phases 4 and 5.
