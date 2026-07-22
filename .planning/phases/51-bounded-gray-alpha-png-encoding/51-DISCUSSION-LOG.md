# Phase 51: Bounded Gray+Alpha PNG Encoding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-23
**Phase:** 51-bounded-gray-alpha-png-encoding
**Areas discussed:** public factory shape, PNG wire profile, bounded strategy reuse, compatibility scope

---

## Public factory shape

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror Gray16 explicit factories | Add matched eager/chunk default, compression, filter, and combined factories. | ✓ |
| Generalize existing defaults | Change legacy constructors to infer GrayAlpha. | |

**Auto-selected choice:** Mirror Gray16 explicit factories (recommended default).

## PNG wire profile

| Option | Description | Selected |
|--------|-------------|----------|
| Type 4 / 8-bit / non-interlaced | Match the scoped Gray+Alpha8 PNG contract. | ✓ |
| Include Adam7 or 16-bit variants | Expand raster traversal and representation scope. | |

**Auto-selected choice:** Type 4 / 8-bit / non-interlaced (recommended default).

## Bounded strategy reuse

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse shared profile-aware machine | Preserve atomic preflight and acknowledgement-safe replay for all supported strategies. | ✓ |
| Add a dedicated GrayAlpha encoder | Duplicate bounded state and create a divergent path. | |

**Auto-selected choice:** Reuse shared profile-aware machine (recommended default).

## Compatibility scope

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Phase 51 focused on feature implementation | Leave hostile schedules, four-target evidence, release work, and unsupported formats to their assigned phases. | ✓ |
| Combine later evidence and delivery work now | Broaden scope and obscure regressions. | |

**Auto-selected choice:** Keep Phase 51 focused on feature implementation (recommended default).

## the agent's Discretion

- Choose the smallest focused test set that proves the Phase 51 factory and bounded-path contract.
- Follow existing Gray16 naming and typed-error conventions.

## Deferred Ideas

- Gray+Alpha16, Gray+Alpha Adam7, public hostile-schedule/four-target evidence, and delivery automation remain outside this phase.
