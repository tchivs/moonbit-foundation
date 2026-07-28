# Phase 101: Collection Contract and Bounded Envelope - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-28
**Phase:** 101-collection-contract-and-bounded-envelope
**Areas discussed:** Public collection surface, Structural validation boundary, Collection authority and accounting, DSIG and deterministic failures

---

## Public Collection Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Separate `FontCollection` facade | Keep standalone admission explicit and add a closed semantic inspection API. | ✓ |
| Auto-detect in `Font::open` | Accept both SFNT and TTC through one entry point. | |
| Expose raw records | Return face offsets, table tags, and storage facts to callers. | |

**User's choice:** Auto-selected the research-recommended separate facade under the standing instruction to choose the optimal option.
**Notes:** Exact count, zero-based profile, and unverified DSIG status are public; storage facts remain private.

---

## Structural Validation Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded all-directory structural scan | Validate all face envelopes and protected ranges, then deeply admit only a selected face later. | ✓ |
| Selected directory only | Defer even sibling directory structure until selection. | |
| Full admission of every face | Checksum and semantically decode every face at collection open. | |

**User's choice:** Auto-selected the bounded two-stage model.
**Notes:** Exact sharing with consistent metadata is valid; partial/conflicting/protected overlap is malformed. Table offsets never rebase from the face directory.

---

## Collection Authority and Accounting

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated collection limits and one exact transaction | Bound counts, retained facts, and work separately from selected-face `FontLimits`. | ✓ |
| Reuse `FontLimits` unchanged | Treat one selected font's limits as collection-wide authority. | |
| Source-byte-only limit | Bound the input length but not face counts, records, DSIG, allocations, or work. | |

**User's choice:** Auto-selected dedicated limits and an atomic retained/work charge.
**Notes:** Caller bytes are retained rather than copied; source length is a semantic ceiling, not an allocation claim.

---

## DSIG and Deterministic Failures

| Option | Description | Selected |
|--------|-------------|----------|
| Structural DSIG validation without trust | Validate v2 placement/envelope and expose `PresentUnverified`. | ✓ |
| Opaque DSIG tuple | Check only tag/length/offset without validating the enclosed table. | |
| Cryptographic verification | Parse PKCS#7 and establish certificate trust. | |

**User's choice:** Auto-selected structural-only support.
**Notes:** Error precedence is authority-first and wire-order deterministic; malformed, unsupported, resource, invalid-input, and mutation outcomes remain distinguishable.

---

## the agent's Discretion

- Exact pre-1.0 identifiers and private helper layout.
- Stable error context strings within the locked `CoreError` categories/codes.
- Conservative target-neutral byte accounting per retained private fact.

## Deferred Ideas

None added during discussion.
