# Phase 108: Public Contract and Transaction Skeleton - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-30
**Phase:** 108-public-contract-and-transaction-skeleton
**Areas discussed:** Public call and immutable run, Direction clusters and
numeric projection, Tags features and empty input, Transaction authority and
error precedence

---

## Public Call and Immutable Run

| Option | Description | Selected |
|--------|-------------|----------|
| Closed scalar-array operation returning an opaque immutable run | One explicit call, request-owned input snapshot, indexed value access, no raw layout facts | ✓ |
| String convenience API returning a public mutable glyph array | Couples v0.35 to string encoding and exposes mutable result storage | |
| Builder/session API with incremental mutation | Adds public lifecycle and partial-state semantics outside the phase boundary | |

**User's choice:** Auto-selected the recommended closed operation under the
user's standing instruction to choose the optimal option.
**Notes:** The exact MoonBit receiver syntax remains implementation discretion;
the observable call and immutable value contract are locked.

---

## Direction, Clusters, and Numeric Projection

| Option | Description | Selected |
|--------|-------------|----------|
| Logical shaping plus final pen-order projection with signed advances | LTR publishes logical order; RTL reverses final records only; clusters remain scalar origins | ✓ |
| Always return logical order and require callers to reverse RTL | Pushes a critical drawing contract into every consumer | |
| Reverse RTL input before shaping | Breaks lookup matching and source provenance | |

**User's choice:** Auto-selected the recommended logical-shaping/final-projection
contract.
**Notes:** Placement offsets remain signed OpenType design-space coordinates;
the phase must freeze exact hand-derived RTL fixtures before API completion.

---

## Tags, Features, and Empty Input

| Option | Description | Selected |
|--------|-------------|----------|
| Typed exact tags and a closed feature policy | Explicit script/language/direction; `liga` and `kern` toggles; required/`rlig` behavior fixed | ✓ |
| Arbitrary feature-tag/value map | Allows deferred behavior to enter through caller-selected tags | |
| Automatic script/language/direction inference | Adds Unicode inference and ambient policy excluded from v0.35 | |

| Empty-input option | Description | Selected |
|--------------------|-------------|----------|
| Validated and charged empty-run success without layout selection | Validates options/limits and font authority, commits fixed text cost once, returns empty run | ✓ |
| Immediate free success | Bypasses invalid options, source guards, and budget semantics | |
| Reject empty input | Makes composition harder without improving safety | |

**User's choice:** Auto-selected typed closed choices and validated empty-run
success.
**Notes:** Empty input does not justify opening GSUB/GPOS tables, but it is not
an authority or validation bypass.

---

## Transaction Authority and Error Precedence

| Option | Description | Selected |
|--------|-------------|----------|
| Opaque request-scoped font transaction with one combined commit | Font owns bytes/revision/layout facts; text owns public staging; one final guard, charge, and publication | ✓ |
| Independent mb-font and mb-text charges | Can leave partial ancestor consumption when the later layer fails | |
| Persistent public layout cache shared across calls | Creates stale-source, hidden-authority, and public raw-layout problems | |

| Precedence option | Description | Selected |
|-------------------|-------------|----------|
| Frozen stage precedence with final State before commit | InvalidInput → entry State → Data → Capability → Resource, with named mutation guards returning State immediately | ✓ |
| Backend traversal order | Produces unstable target/representation-dependent errors | |
| Resource before selected-data validation | Lets budget size hide malformed or unsupported selected semantics | |

**User's choice:** Auto-selected the one-commit opaque transaction and frozen
stage precedence.
**Notes:** Phase-specific table diagnostics are deferred to the phases that
introduce those tables; Phase 108 freezes the shared categories and stages.

## the agent's Discretion

- Exact MoonBit API/receiver spelling and private continuation encoding.
- Internal immutable run storage and accessor naming.
- Concise error context strings consistent with existing module conventions.

## Deferred Ideas

- Binary layout admission, GSUB, GPOS/kerning, integrated hardening, and
  qualification remain assigned to Phases 109-113.
- Broader Unicode, complex script, fallback, paragraph, rendering, and cache
  capabilities remain outside v0.35.
