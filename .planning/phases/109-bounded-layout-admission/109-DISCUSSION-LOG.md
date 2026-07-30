# Phase 109: Bounded Layout Admission - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-30
**Phase:** 109-bounded-layout-admission
**Mode:** `--auto` single pass
**Areas discussed:** Binary windows and offsets; selection and ordering; normalized layout facts; limits and mutation; phase ownership

---

## Binary Windows, Offset Bases, and Validation Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Deep-validate every table body | Reject any rich unselected construct | |
| Ignore every unselected record | Validate only the exact selected body | |
| Envelope all globals, deep-decode selected bodies | Field-specific bases; global structural reachability; selected capability checks | ✓ |

**User's choice:** Auto-selected the recommended envelope-plus-selected-depth policy.
**Notes:** Null FeatureVariations in 1.1 is admitted; checked non-null is capability failure.

## Script, LangSys, Feature, Lookup, and Subtable Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Add `DFLT`/default fallback | Infer alternate script/language records | |
| Treat missing selection as empty | Admit a no-op plan | |
| Exact selection with deterministic lookup union | Required feature, closed tags, ascending lookup indices, stored subtable order | ✓ |

**User's choice:** Auto-selected exact request semantics and one execution per lookup index.
**Notes:** Required `kern` conflicts with `kern=false` rather than silently overriding the toggle.

## Coverage, ClassDef, GDEF, Flags, and Extensions

| Option | Description | Selected |
|--------|-------------|----------|
| Retain checked raw views | Re-parse selected bytes during execution | |
| Flatten everything by glyph | Allocate glyph-sized arrays | |
| Compact owned normalized facts | Close selected offsets/cardinalities/classes/GIDs and one-hop wrappers | ✓ |

**User's choice:** Auto-selected compact private facts and on-demand GDEF dependency.
**Notes:** Mark filtering/attachment and recursive/deferred wrappers remain capability-closed.

## Limits, Charges, Mutation, Lifetime, and Diagnostics

| Option | Description | Selected |
|--------|-------------|----------|
| Implementation constants | No caller-visible layout limits | |
| Extend `FontLimits` | Put shaping admission limits on Font construction | |
| Additive layout-limit bundle on ShapeLimits | Preserve old constructor with documented nonzero defaults | ✓ |

**User's choice:** Auto-selected additive layout limits, exact retained charge, stage guards, and callback-scoped lifetime.
**Notes:** Diagnostics use stable tokens and expose no raw offsets/indices.

## Phase Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Root-envelope admission only | Defer selected subtable normalization | |
| Execute layout immediately | Merge admission and GSUB/GPOS execution | |
| Fully normalize selected bodies without execution | Preserve the six-phase roadmap ownership | ✓ |

**User's choice:** Auto-selected admission-only Phase 109 with public nonempty shaping still capability-closed.
**Notes:** Phase 110/111/112/113 retain execution, integration, and qualification authority.

## the agent's Discretion

- Private file organization and record naming.
- Conservative nonzero default layout-limit values.
- Internal search/storage implementation that preserves locked ordering and charge facts.

## Deferred Ideas

Execution, integrated atomicity, licensed qualification, contextual/mark/variable layout, caches, UI, FFI, and public raw inspection remain assigned to later phases or milestones.
