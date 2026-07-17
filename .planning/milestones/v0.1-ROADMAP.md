# Roadmap: MoonBit Native Foundation

## Overview

MNF v0.1 is a contract-and-conformance milestone delivered as five horizontal layers. The sequence first establishes the ecosystem rules and reproducible workspace, then builds the safety and portability spine in `mb-core`, defines reference color semantics, stabilizes the image model and operations, and finally proves the public contracts through a bounded reference codec and independent release qualification.

## Phases

- [x] **Phase 1: Foundation Charter and Reproducible Workspace** — Accept the ecosystem contract and make the three-module workspace reproducible, target-aware, and operable from the repository root. (completed 2026-07-16)
- [x] **Phase 2: Bounded Core Primitives** — Deliver the checked byte, stream, diagnostic, budget, and host-capability contracts that every higher layer relies on. (completed 2026-07-17)
- [x] **Phase 3: Reference Color Semantics** — Define explicit color and alpha representation and verify deterministic reference conversions across declared targets. (completed 2026-07-17)
- [x] **Phase 4: Image Model, Views, and Operations** — Build safe image representation, storage/view rules, deterministic transforms, metadata behavior, and codec-facing contracts. (completed 2026-07-17)
- [x] **Phase 5: Reference Codec and Release Qualification** — Prove the public stack end to end with bounded PPM P6, conformance evidence, documentation, benchmarks, and independent module release checks. (completed 2026-07-17)

## Phase Details

### Phase 1: Foundation Charter and Reproducible Workspace

**Goal:** Contributors and consumers have an accepted architectural charter, explicit governance and compatibility rules, and a reproducible multi-module workspace with enforceable target and quality policies.

**Depends on:** Nothing (entry phase)

**Requirements:** GOV-01, GOV-02, GOV-03, GOV-04, WORK-01, WORK-02, WORK-03, WORK-04, WORK-05

**Plans:** 8/8 plans complete

Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Establish the canonical charter and auditable RFC lifecycle.
- [x] 01-02-PLAN.md — Single-source compatibility, licensing, publication, target, toolchain, and source-audit policy.
- [x] 01-03-PLAN.md — Create the three-member workspace manifests and package target contracts.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-04-PLAN.md — Add the private mb-core build, test, documentation, and release-ledger surface.
- [x] 01-05-PLAN.md — Add the private mb-color build, test, documentation, and release-ledger surface.
- [x] 01-06-PLAN.md — Add the private mb-image build, test, documentation, and release-ledger surface.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-07-PLAN.md — Implement fail-closed policy/source-audit validation and pinned required/LLVM quality lanes.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 01-08-PLAN.md — Record authentic RFC acceptance and run final exact qualification.

**Success Criteria:**

1. A contributor can follow the accepted foundation RFC from architectural principles through v0.1 boundaries and the documented RFC lifecycle, including who accepts breaking changes.
2. A consumer can identify API stability promises, project and fixture licenses, publication namespace/naming policy, and each public package's supported targets from checked-in documentation or metadata.
3. From a clean clone, a developer can reproduce the recorded MoonBit toolchain and operate `mb-core`, `mb-color`, and `mb-image` as independently publishable workspace members.
4. One root-level workflow runs formatting, checks, tests, documentation, package-content validation, and dependency-DAG validation without entering modules manually.
5. CI verifies each portable package on every declared target while treating LLVM as explicitly experimental and non-blocking.

### Phase 2: Bounded Core Primitives

**Goal:** `mb-core` provides the safe, backend-neutral primitives required to process untrusted binary data without unchecked ranges, ambient capabilities, or unbounded work.

**Depends on:** Phase 1

**Requirements:** CORE-01, CORE-02, CORE-03, CORE-04, CORE-05, CORE-06, CORE-07, CORE-08

**Success Criteria:**

1. Tests demonstrate that checked arithmetic, ranges, dimensions, offsets, alignment, casts, and allocation-size calculations reject overflow before access or allocation.
2. Callers can create owned bytes and validated immutable or mutable views, and bounded in-memory readers/writers cannot escape their declared ranges.
3. Backend-neutral I/O distinguishes exact, partial, end-of-stream, failed, and optionally seekable behavior without requiring filesystem access or universal seek support.
4. Errors and diagnostics expose stable machine-readable categories/codes and context while producing deterministic human-readable output.
5. Resource budgets and explicitly supplied host capabilities stop prohibited allocation/work and replace ambient process state across portable packages.

### Phase 3: Reference Color Semantics

**Goal:** `mb-color` makes color-space, transfer, component, and alpha behavior explicit and reproducible enough to serve as the semantic oracle for images and future graphics layers.

**Depends on:** Phase 2

**Requirements:** COLR-01, COLR-02, COLR-03, COLR-04, COLR-05

**Success Criteria:**

1. Public values represent component behavior, color-space identity, transfer function, and straight versus premultiplied alpha without relying on implicit defaults.
2. Provenance-recorded vectors verify encoded-sRGB/linear-sRGB conversion with documented finite-value, range, rounding, and tolerance rules on every declared target.
3. Premultiply and unpremultiply tests cover zero alpha, boundary values, and documented rounding semantics consistently across targets.
4. A bounded profile identity or opaque metadata value can round-trip through the public seam without requiring an ICC parser.

### Phase 4: Image Model, Views, and Operations

**Goal:** `mb-image` exposes an explicit, memory-safe image representation and deterministic foundational operations that reuse `mb-core` and `mb-color` without embedding host or codec policy.

**Depends on:** Phase 3

**Requirements:** IMAG-01, IMAG-02, IMAG-03, IMAG-04, IMAG-05, IMAG-06, IMAG-07

**Plans:** 9/9 plans complete

Plans:

- [x] 04-01-PLAN.md — Establish bounded core-only opaque metadata and disposition values.
- [x] 04-02-PLAN.md — Define explicit validated image descriptors and image metadata.
- [x] 04-03-PLAN.md — Implement owned storage, retained views, and zero-copy crop lifetimes.
- [x] 04-04-PLAN.md — Add fresh-output copy and exact horizontal/vertical flips.
- [x] 04-05-PLAN.md — Generate image evidence and implement all eight orientation transforms.
- [x] 04-06-PLAN.md — Add integer nearest resize and closed U8 pixel conversions.
- [x] 04-07-PLAN.md — Define prefix/Reader/Writer backend-neutral codec contracts.
- [x] 04-08-PLAN.md — Remove the scaffold and close docs, policy, fixtures, and Required qualification.
- [x] 04-09-PLAN.md — Close descriptor-derived budget charging and fail-closed planar view safety gaps.

**Success Criteria:**

1. Public image descriptions make dimensions, format, component representation, channel/plane layout, stride, endianness, color space, alpha mode, and orientation inspectable.
2. Constructor and adversarial tests reject overflow, invalid dimensions or strides, insufficient storage, invalid plane ranges, and prohibited overlap before access or allocation.
3. Owned images and immutable/mutable views enforce backing-storage and lifetime rules, including zero-copy crops/subviews where representation permits.
4. Copies, flips, orientation application, nearest-neighbor resize, and required pixel conversions produce deterministic conformance results.
5. Every operation documents and tests whether metadata is preserved, transformed, or discarded, and codec authors can use the contracts through backend-neutral I/O without a global registry or filesystem policy.

### Phase 5: Reference Codec and Release Qualification

**Goal:** Demonstrate that the three modules work as independently consumable release candidates through a strict bounded reference codec, end-to-end public examples, and reproducible release evidence.

**Depends on:** Phase 4

**Requirements:** WORK-06, QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05, QUAL-06

**Plans:** 8/8 plans complete

Plans:

- [x] 05-01-PLAN.md — Define PPM options and prove the bounded incremental header parser.
- [x] 05-02-PLAN.md — Decode through one atomic allocation, exact payload fill, and strict EOF probe.
- [x] 05-03-PLAN.md — Emit canonical P6 and generate conformance, adversarial, and metamorphic evidence.
- [x] 05-04-PLAN.md — Qualify portable and Native CLI-shaped public stream-transform-stream examples.
- [x] 05-05-PLAN.md — Complete candidate docs, support matrices, changelogs, provenance, and qualification metadata.
- [x] 05-06-PLAN.md — Capture reproducible correctness-gated benchmark records and environment evidence.
- [x] 05-07-PLAN.md — Prove deterministic packages, exact core artifact consumption, and honest downstream blockers.
- [x] 05-08-PLAN.md — Close exact policy negatives and two clean deterministic Required runs.

**Success Criteria:**

1. The public codec interfaces decode and encode the documented bounded PPM P6 subset, and malformed or oversized inputs fail with structured errors before prohibited work.
2. A Native CLI-shaped example and an in-memory portable example complete stream-to-image-to-transform-to-stream flows using only public APIs.
3. Root qualification runs black-box API, internal invariant, conformance-vector, adversarial-limit, and applicable property/metamorphic suites for release-candidate behavior.
4. Each candidate module publishes runnable API documentation, examples, support matrices, changelog, fixture provenance, and reproducible benchmark evidence with complete environment and variance metadata.
5. Clean external-consumer checks verify packaged contents, registry dependency resolution, target conformance, module independence, compatibility metadata, and provenance before topological publication.

## Progress

| Phase | Name | Requirements | Status |
|------:|------|-------------:|--------|
| 1 | 8/8 | Complete    | 2026-07-16 |
| 2 | 8/8 | Complete    | 2026-07-17 |
| 3 | 8/8 | Complete    | 2026-07-17 |
| 4 | 9/9 | Complete    | 2026-07-17 |
| 5 | 8/8 | Complete    | 2026-07-17 |

**v0.1 coverage:** 36/36 requirements mapped exactly once.

---
*Roadmap created: 2026-07-16*
