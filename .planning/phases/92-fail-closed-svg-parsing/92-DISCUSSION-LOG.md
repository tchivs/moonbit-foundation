# Phase 92: Fail-Closed SVG Parsing - Discussion Log

> **Audit trail only.** Decisions are captured in `92-CONTEXT.md`.

**Date:** 2026-07-26
**Phase:** 92-fail-closed-svg-parsing
**Areas discussed:** numeric admission ownership, explicit-versus-absent behavior, compatibility boundaries

---

## Numeric admission ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Central parser admission | One Phase 91 envelope enforced at ingress and checked derivations | ✓ |
| Lowering-time checks | Defer safety until a drawing list is formed | |

**User's choice:** Auto-selected central parser admission (consistent with Phase 91 locked decisions).

---

## Explicit-versus-absent behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit invalid is an error | No fallback or partial result; absent remains defaultable | ✓ |
| Fallback/coercion | Treat invalid present data as missing or clamp it | |

**User's choice:** Auto-selected fail-closed structured errors (consistent with SVGPR-02).

---

## Compatibility boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve valid finite controls | Keep defaults, finite singular transforms, and canvas layer behavior | ✓ |
| Reject singular transforms | Treat all non-invertibility as invalid | |

**User's choice:** Auto-selected preserved finite controls and unchanged RFC 0008 semantics.

---

## the agent's Discretion

Helper placement, error variant naming, and test organization follow established `mb-svg` patterns.

## Deferred Ideas

None.
