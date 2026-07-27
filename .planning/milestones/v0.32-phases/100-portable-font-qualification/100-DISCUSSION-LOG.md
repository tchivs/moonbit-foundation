# Phase 100: Portable Font Qualification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 100-portable-font-qualification
**Areas discussed:** real-font specimen, fixture transport and oracle, complete public workflow, hostile matrix, qualification gates, scope control

---

## Real-Font Specimen

| Option | Description | Selected |
|--------|-------------|----------|
| DejaVu Sans 2.37 | v0.32 research-selected official specimen with format-4/12 cmap, simple/composite outlines, legacy kern, published archive digest, and redistributable license | ✓ |
| Go Regular v0.43.0 | Smaller BSD-3-Clause static TrueType specimen, but it lacks the legacy `kern` table and diverges from established milestone research | |
| Generated fonts only | Avoid external bytes but fail the real-font interoperability criterion | |

**User's choice:** [auto] DejaVu Sans 2.37 (recommended default)
**Notes:** Preserve the v0.32 research decision. Rechecked official single-font archive SHA-256 is `5c6e497a2f36552cb5ffb112c413a6af39c0f3c47653662b90b4fa6499822fd7`; extracted `DejaVuSans.ttf` SHA-256 is `7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954`.

---

## Fixture Transport and Oracle

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical binary plus deterministic portable embedding | Commit exact fixture bytes, generate target-consumable bytes, and bind both with length/digest plus an independent oracle | ✓ |
| Runtime filesystem loading | Smaller test source but violates portable/no-host-state requirements | |
| Snapshot only | Easy to implement but lets `mb-font` certify itself and weakens provenance | |

**User's choice:** [auto] Canonical binary plus deterministic portable embedding (recommended default)
**Notes:** Prefer a verified compile-time embedding primitive if all targets support it; otherwise use generated bounded chunks.

---

## Complete Public Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Compact complete workflow plus real-font scenario | Generated font proves minimal branches; DejaVu Sans proves representative mapping, metrics, outlines, and kern interoperability | ✓ |
| One real font only | Representative, but too large and complex to be the sole minimal branch oracle | |
| Scattered existing tests | Broad coverage but no single reproducible public workflow or canonical evidence | |

**User's choice:** [auto] Compact complete workflow plus real-font scenario (recommended default)
**Notes:** Freeze public semantic values and path commands, not runtime representation or timing.

---

## Hostile Matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Closed generated semantic matrix | Run every case on four targets and compare category/code/context/limit facts | ✓ |
| Rendered error snapshots | Brittle prose oracle that obscures semantic compatibility | |
| Target-specific expectations | Masks portability defects | |

**User's choice:** [auto] Closed generated semantic matrix (recommended default)
**Notes:** Include malformed, unsupported, mutation, arithmetic/range, semantic limit, and budget exhaustion with transactional failure checks.

---

## Qualification Gates

| Option | Description | Selected |
|--------|-------------|----------|
| Focused four-target selector plus repository policy lane | Produces canonical target evidence and separately proves workspace/dependency policy | ✓ |
| Isolated package tests only | Misses fixture drift, interface, docs, and dependency boundaries | |
| Workspace lane only | Makes font evidence vulnerable to unrelated workspace failures | |

**User's choice:** [auto] Focused four-target selector plus repository policy lane (recommended default)
**Notes:** Preserve honest reporting of the known Windows unscoped PNG driver stall without weakening focused font success.

---

## Scope Control

| Option | Description | Selected |
|--------|-------------|----------|
| Qualification-first, defect fixes only | Preserve the Phase 97-99 public boundary; change production only for a proven conformance defect | ✓ |
| Add convenience APIs | Broadens the candidate surface without a Phase 100 requirement | |
| Add host tooling to production | Violates portability and dependency constraints | |

**User's choice:** [auto] Qualification-first, defect fixes only (recommended default)
**Notes:** New formats, shaping, hinting, discovery, rasterization, and FFI remain deferred.

## the agent's Discretion

- Exact test/vector file split, evidence schema field names, and generated chunk size.
- Exact DejaVu Sans scalar/glyph choices after independent simple/composite classification.
- Exact generator language and implementation, provided it is deterministic and does not use `mb-font` as its own oracle.

## Deferred Ideas

- Broader real-font corpus and additional format/container coverage.
- Text shaping, font discovery, hinting, rasterization, authoring, and stability promotion.
