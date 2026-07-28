# Phase 106: Cubic Path and Public/TTC Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-29
**Phase:** 106-cubic-path-and-public-ttc-integration
**Mode:** `--auto`; the user explicitly authorized optimal default selections
**Areas discussed:** Public API and format dispatch, Cubic path fidelity, Atomic query authority, Standalone and TTC admission, Format-neutral compatibility

---

## Public API and Format Dispatch

| Option | Description | Selected |
|--------|-------------|----------|
| Private dispatch through existing `Font` API | Keep public `Font`, `GlyphId`, metrics, and outline workflows unchanged; branch on the private outline source. | ✓ |
| Add a CFF-specific public API | Expose CFF-specific font or outline types beside the existing API. | |
| Translate CFF into synthetic glyf data | Convert CFF geometry into another font format before public use. | |

**Selection:** Private dispatch through the existing `Font` API.
**Rationale:** `FontOutlineSource::Cff1` and the existing `Font::outline` return type already provide the correct closed seam.

---

## Cubic Path Fidelity

| Option | Description | Selected |
|--------|-------------|----------|
| Native cubic commands from the shared VM | Preserve exact transformed controls and emit `MoveTo`/`LineTo`/`CubicTo`/`Close`. | ✓ |
| Approximate cubics as quadratics | Convert CFF cubics to one or more `QuadTo` commands. | |
| Retain an admission-time command stream | Store complete commands for every glyph during font admission. | |

**Selection:** Native cubic commands from the shared Type 2 VM.
**Rationale:** `Path2` already supports cubics, and a second interpreter or retained path cache would violate the Phase 105 handoff.

---

## Atomic Query Authority

| Option | Description | Selected |
|--------|-------------|----------|
| Stage, final-guard, commit once, publish | Re-execute one glyph, preflight exact VM/path authority, guard revision, commit, then return the complete path. | ✓ |
| Charge incrementally while appending | Mutate caller budget during path construction. | |
| Cache all paths during font admission | Pay the memory cost for every path before any query. | |

**Selection:** Stage the complete query transaction and commit once.
**Rationale:** This preserves no-partial geometry, mutation precedence, and explicit resource authority without retaining all paths.

---

## Standalone and TTC Admission

| Option | Description | Selected |
|--------|-------------|----------|
| One shared CFF admission with coordinate-space adapters | Reuse standalone/collection CFF entry points and retain root/table authority. | ✓ |
| Separate collection CFF parser | Add a second collection-specific implementation. | |
| Copy selected face into standalone bytes | Materialize a standalone font before admission. | |

**Selection:** One shared CFF admission implementation.
**Rationale:** Existing CFF admission already accepts directory start, expected table count, checksum mode, and collection charging.

---

## Format-Neutral Compatibility

| Option | Description | Selected |
|--------|-------------|----------|
| Common-table facts with closed outline dispatch | Reuse mapping/metrics/kerning facts and keep glyf behavior on its existing branch. | ✓ |
| CFF-specific metrics and glyph identities | Add separate CFF public query behavior. | |
| Refactor both formats into a new public model | Replace the established opaque `Font` contract. | |

**Selection:** Reuse common-table facts and closed private dispatch.
**Rationale:** CFF-04 requires format-neutral public behavior and CFF-05 requires zero glyf drift.

---

## the agent's Discretion

- Private sink and helper names.
- Capacity-aware `Path2` construction mechanism.
- Exact stable path-emission work constants.
- Fixture file/task boundaries.

## Deferred Ideas

- Phase 107 licensed/hostile/performance/four-target qualification.
- CFF2, seac composition, WOFF, shaping, hint rendering, rasterization, color/bitmap glyphs, authoring, and ambient I/O.
