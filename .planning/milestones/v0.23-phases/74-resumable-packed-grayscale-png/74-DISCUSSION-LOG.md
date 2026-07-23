# Phase 74 Discussion Log

## 2026-07-23 — Autonomous scope resolution

- **Chosen path:** Extend the established `PngChunkEncoder` explicit grayscale
  factory family with fixed Stored/None/non-interlaced Gray1, Gray2, and Gray4
  routes.
- **Why:** Phase 73 already supplies the private profiles, exact admission,
  packed row layout, and shared machine. This phase can therefore deliver the
  caller-buffered capability with minimal new surface and maximum reuse.
- **Rejected expansion:** Strategy families and Adam7 would multiply the
  lifecycle/qualification matrix without advancing the required v0.23
  resumable contract.
- **Evidence required:** Eager/chunk byte identity, fragmented leases,
  pre-lease atomic rejection, and sticky terminals for all depths.
