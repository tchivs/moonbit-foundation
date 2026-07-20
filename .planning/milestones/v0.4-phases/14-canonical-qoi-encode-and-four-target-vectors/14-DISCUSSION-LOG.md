# Phase 14: Canonical QOI Encode and Four-Target Vectors - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-20
**Phase:** 14-Canonical QOI Encode and Four-Target Vectors
**Areas discussed:** encoder source boundary, canonical byte policy, conformance evidence

---

## Encoder source boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Independent QOI encoder | Add `QoiEncoder` to the existing QOI package and preserve the codec contract. | ✓ |
| Shared registry work | Add format registration alongside encoding. | |

**User's choice:** Independent QOI encoder (automatic best-fit selection).
**Notes:** The project remains code-and-test first; registry work is outside this phase.

---

## Canonical byte policy

| Option | Description | Selected |
|--------|-------------|----------|
| Standard deterministic priority | RUN, INDEX, DIFF, LUMA, RGB/RGBA and the exact end marker. | ✓ |
| Alternative valid chunk choices | Permit multiple byte encodings for the same pixels. | |

**User's choice:** Standard deterministic priority (automatic best-fit selection).
**Notes:** Canonical bytes make fixtures and four-target evidence stable.

---

## Conformance evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Extend checked QOI fixtures | Add encoder expectations to the existing JSON source and local generator. | ✓ |
| New external corpus or release tooling | Add broader tooling before encoder evidence. | |

**User's choice:** Extend checked QOI fixtures (automatic best-fit selection).
**Notes:** No network-fetched corpus, release automation, or benchmark work is included.

---

## the agent's Discretion

- Private helper factoring, write chunk size, and fixture record details stay minimal and follow the existing QOI decoder and PPM encoder patterns.

## Deferred Ideas

- Public example belongs to Phase 15; streaming, benchmarks, registry composition, FFI, and release automation remain future work.
