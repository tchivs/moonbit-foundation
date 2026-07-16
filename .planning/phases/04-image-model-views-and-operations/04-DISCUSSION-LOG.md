# Phase 4: Image Model, Views, and Operations - Discussion Log

> **Audit trail only.** Decisions are captured in CONTEXT.md.

**Date:** 2026-07-17
**Phase:** 04-image-model-views-and-operations
**Areas discussed:** Descriptor scope, plane/stride validation, owned/view lifetime, deterministic operations, metadata disposition, codec seam

## Descriptor scope

Selected: expressive packed/planar descriptor with explicit component/channel/endianness/color/alpha/orientation; reference operations restricted to encoded-sRGB U8 RGB/RGBA formats.

Rejected: a single implicit Image type; limiting the descriptor itself to only packed RGBA8.

## Plane, stride, and storage validation

Selected: checked half-open plane ranges, positive images, explicit row stride/padding/subsampling, containment and non-overlap before allocation/access.

Rejected: negative stride/bottom-up convention; implicit plane offsets; permissive overlap.

## Owned images and views

Selected: retained immutable zero-copy views and callback-scoped mutable views using mb-core leases; zero-copy crop fails explicitly when layout cannot represent it.

Rejected: raw mutable backing; escaping mutable views; silently copying from a zero-copy API.

## Deterministic operations

Selected: integer nearest mapping, exact flips/orientation permutations, explicit U8 RGB/RGBA and straight/premultiplied conversions.

Rejected: floating resize coordinates, hidden color conversion, advanced filters in Phase 4.

## Metadata disposition

Selected: bounded ordered metadata with executable per-operation preserve/transform/discard rules.

Rejected: unbounded generic map; silent metadata interpretation or loss.

## Codec seam

Selected: backend-neutral Reader/Writer/options/outcomes contracts only; no registry, filesystem policy, or codec implementation.

Rejected: global codec discovery and paths/URLs in portable contracts.

## the agent's Discretion

- Exact package/type names, metadata duplicate policy, empty-view rule, and fixture encoding after research.

## Deferred Ideas

- PPM implementation to Phase 5; advanced formats/resampling/animation/GPU/native codecs to later work.
