# Phase 98: Unicode Mapping and Kerning - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 98-unicode-mapping-and-kerning
**Areas discussed:** Unicode query contract, deterministic cmap selection, legacy kern profile, admission and resource semantics

---

## Unicode Query Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Result with glyph-zero miss | Invalid scalar is a structured error; valid unmapped scalar returns opaque glyph zero. | ✓ |
| Optional glyph | Return `None` for a valid miss. | |
| Coerce invalid input | Treat invalid scalar input as glyph zero. | |

**User's choice:** Auto-selected the recommended result-with-glyph-zero contract under the instruction to choose the optimal option.
**Notes:** This preserves RFC 0004's notdef sentinel while keeping caller input errors observable.

---

## Deterministic Cmap Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical ranked mapping | Prefer format 12, then format 4; use a fixed Unicode-record rank and reject conflicts. | ✓ |
| File-order winner | Use the first eligible encoding record. | |
| Per-scalar merging | Try multiple subtables or fall back after a miss. | |

**User's choice:** Auto-selected one canonical ranked mapping.
**Notes:** OpenType 1.9.1 says a 32-bit Unicode subtable should supersede the 16-bit compatibility subtable. The existing stack research freezes the exact candidate order as `0/4/12`, `3/10/12`, `0/3/4`, then `3/1/4`; one selected mapping prevents record-order and target-dependent behavior.

---

## Legacy Kern Profile

| Option | Description | Selected |
|--------|-------------|----------|
| Single horizontal format 0 | Support one canonical OpenType v0 format-0 value subtable. | ✓ |
| Multiple format-0 subtables | Accumulate or override across coverage flags. | |
| Broader legacy support | Include format 2 and Apple extensions. | |

**User's choice:** Auto-selected the interoperable single-subtable profile.
**Notes:** This matches the milestone's “basic legacy horizontal format-0” boundary. Well-formed unsupported data remains usable for metrics/cmap and returns capability only from the kerning query; malformed kern bytes fail opening as data.

---

## Admission and Resource Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Eager atomic admission | Select/validate once at `Font::open`, retain compact facts, and make queries bounded/allocation-free. | ✓ |
| Lazy first-query validation | Defer table validation until the capability is queried. | |
| Reparse every query | Re-read and validate the table on every call. | |

**User's choice:** Auto-selected eager atomic admission.
**Notes:** This extends Phase 97's one-publication invariant and lets all attacker-driven work be preflighted and charged once.

## the agent's Discretion

- Exact public method names, private file split, error context strings, and canonical Unicode platform/encoding rank within the locked policy.

## Deferred Ideas

- GPOS/GSUB shaping, non-horizontal or multi-subtable kerning, format 2, Apple extensions, outlines, and portable real-font qualification remain assigned to later work.
