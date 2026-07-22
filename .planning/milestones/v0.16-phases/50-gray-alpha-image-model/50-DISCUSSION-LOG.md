# Phase 50: Gray+Alpha Image Model - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-22
**Phase:** 50-gray-alpha-image-model
**Areas discussed:** image order, alpha semantics, compatibility boundary

---

## Image order

| Option | Description | Selected |
|---|---|---|
| Explicit `GrayAlpha` order | First-class two-component public model that cannot be confused with opaque Gray or RGBA. | ✓ |
| Reuse RGBA only | Would not represent a native two-component image profile. | |

**User's choice:** Automatic optimal-choice authorization selected the explicit order.
**Notes:** Keep this phase to the model; PNG output is deliberately deferred.

---

## Alpha semantics

| Option | Description | Selected |
|---|---|---|
| Packed U8 straight alpha | Matches the bounded Gray+Alpha8 PNG scope and existing straight-alpha contract. | ✓ |
| Broaden to U16/planar/premultiplied | Expands the model and codec surface beyond this milestone phase. | |

**User's choice:** Automatic optimal-choice authorization selected packed U8 straight alpha.
**Notes:** Gray+Alpha16 and interlacing remain explicitly deferred.

---

## Compatibility boundary

| Option | Description | Selected |
|---|---|---|
| Additive model only | Existing formats remain unchanged; unsupported operations reject the new order until separately scoped. | ✓ |
| Extend all image operations now | Would couple a PNG-model phase to unrelated processing work. | |

**User's choice:** Automatic optimal-choice authorization selected the additive boundary.
**Notes:** No release automation, staging path, or copied source tree is permitted.

## the agent's Discretion

- Use the smallest existing descriptor/storage test patterns that prove the public contract and legacy compatibility.

## Deferred Ideas

- Gray+Alpha16, Gray+Alpha Adam7, PNG encoding, and public four-target evidence belong to later planned phases.
