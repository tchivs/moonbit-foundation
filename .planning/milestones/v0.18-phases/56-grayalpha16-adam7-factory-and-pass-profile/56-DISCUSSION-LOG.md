# Phase 56: GrayAlpha16 Adam7 Factory and Pass Profile - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-23
**Phase:** 56-grayalpha16-adam7-factory-and-pass-profile
**Areas discussed:** Adam7 factory shape, U16 pass lanes, descriptor and compatibility boundary

---

## Adam7 factory shape

| Option | Description | Selected |
|---|---|---|
| Explicit GrayAlpha16 Adam7 eager and chunk factories | Mirrors established public opt-in factory families. | ✓ |
| Implicitly interlace existing GrayAlpha16 factories | Would change frozen non-interlaced output. | |

**User's choice:** Automatic best option: explicit opt-in factories.
**Notes:** Existing bytes and APIs remain stable.

---

## U16 pass lanes

| Option | Description | Selected |
|---|---|---|
| Reuse GrayAlpha16 profile plus Adam7 pass traversal | One bounded encoder route emits `Ghi,Glo,Ahi,Alo`. | ✓ |
| New Adam7-specific encoder/buffer | Duplicates output and replay machinery. | |

**User's choice:** Automatic best option: profile composition on the existing route.
**Notes:** No staging or alternate pipeline.

---

## Descriptor and compatibility boundary

| Option | Description | Selected |
|---|---|---|
| Keep legal little-endian admission and reject Big-endian descriptors | Preserves the v0.17 public model contract. | ✓ |
| Add a Big-endian source variant | Widens the model contract and scope. | |

**User's choice:** Automatic best option: preserve strict admission and frozen non-interlaced output.
**Notes:** Big-endian support remains a separate future design decision.

---

## the agent's Discretion

- Use the smallest existing Adam7 and GrayAlpha16 test analogues.

## Deferred Ideas

- Resource/replay matrices and public portable evidence belong to Phases 57–58.
