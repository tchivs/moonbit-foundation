---
phase: 108
slug: public-contract-and-transaction-skeleton
status: approved
shadcn_initialized: false
preset: none
created: 2026-07-30
---

# Phase 108 — UI Design Contract

> Applicability record for the visual and interaction contract. Phase 108 has no UI surface.

---

## Applicability Determination

**Result: No UI surface / Not applicable.**

Phase 108 creates a pure MoonBit library/API module and supporting contracts across
`js`, `wasm`, `wasm-gc`, and `native`. It creates no GUI, DOM, terminal UI, visual
component, styling layer, typography, color palette, user-facing copy surface,
pointer/keyboard interaction, responsive layout, or screenshot target.

The frontend detector is a false positive caused by vocabulary such as `text`,
`public contract`, `empty input`, `error`, `direction`, and `positioned run`.
In this phase:

- `text` means format-neutral scalar-to-glyph library processing, not displayed UI text.
- `empty input` is an API transaction and resource-charging case, not an empty screen state.
- `error` means structured `CoreError` values with stable technical operation/context
  strings, not user-facing error copy.
- `LeftToRight` and `RightToLeft` define shaped-run record order and signed design-unit
  pen deltas, not page direction, RTL layout, or responsive presentation.
- Documentation and generated `.mbti` interfaces are technical contract outputs, not UI
  copywriting surfaces.

**Planner constraint:** Do not add UI, frontend, styling, visual-regression, responsive,
accessibility-widget, interaction, or screenshot tasks to Phase 108. Plan only the
MoonBit API, transaction authority, immutable values, resource accounting, contract
fixtures, module policy, documentation, and four-target verification described by the
phase requirements and research.

**Sources:** `.planning/ROADMAP.md` Phase 108; `.planning/REQUIREMENTS.md` TXT-01/TXT-02;
`108-CONTEXT.md` D-01 through D-16; `108-RESEARCH.md` Standard Stack, Architecture
Patterns, and Verification Strategy.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — not applicable |
| Preset | not applicable |
| Component library | none |
| Icon library | none |
| Font | none |

No React, Next.js, Vite, frontend component configuration, or existing design-system
surface was detected. The shadcn initialization gate does not apply to this MoonBit
library phase.

---

## Spacing Scale

No spacing tokens are declared. There are no visual elements, containers, controls, or
page layouts in scope.

| Token | Value | Usage |
|-------|-------|-------|
| Not applicable | Not applicable | No UI surface |

Exceptions: none; there is no baseline spacing contract to vary.

---

## Typography

No typography roles, font sizes, weights, or line heights are declared because Phase 108
does not render text.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Not applicable | Not applicable | Not applicable | Not applicable |

MoonBit identifiers, API documentation, stable error operation/context strings, and test
fixture text follow technical repository conventions. They are not visual typography.

---

## Color

No dominant, secondary, accent, semantic, or destructive colors are declared because
Phase 108 has no rendered surface.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Not applicable | No background or surface |
| Secondary (30%) | Not applicable | No cards, sidebar, or navigation |
| Accent (10%) | Not applicable | No interactive or emphasized UI elements |
| Destructive | Not applicable | No destructive UI action |

Accent reserved for: none; no accent color exists in this phase.

---

## Copywriting Contract

Phase 108 defines no end-user copy. API names, MoonBit documentation, generated interface
text, and `CoreError` category/code/operation/context values are technical compatibility
contracts governed by TXT-01/TXT-02 and D-16, not UI copywriting.

| Element | Copy |
|---------|------|
| Primary CTA | Not applicable — no action control |
| Empty state heading | Not applicable — empty scalar input is API behavior, not a UI state |
| Empty state body | Not applicable |
| Error state | Not applicable — callers receive structured `CoreError` values |
| Destructive confirmation | Not applicable — no destructive UI action |

---

## UI Considerations

**Applicable state considerations resolved: none applicable.**

There are no UI elements to classify as a form, list/collection, navigation, media,
interactive control, or static content. Therefore the UI-consideration probe categories
do not arise in this phase.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| Empty / no data | none | dismissed | No UI element exists; empty scalar input is covered by the API contract and tests. |
| Loading / in-flight | none | dismissed | The deterministic library call defines no loading presentation. |
| Error / failure | none | dismissed | `CoreError` is a technical result value, not rendered UI. |
| Populated / happy path | none | dismissed | Successful `ShapedRun` values are library data, not a displayed collection. |
| Partial / incomplete | none | dismissed | Publication is atomic; there is no partial UI state. |
| Overflow / truncation | none | dismissed | Numeric overflow is checked API failure; no visual container exists. |
| Zero / one / many | none | dismissed | Input/run cardinality is tested library behavior, not layout or pluralized copy. |
| Long text | none | dismissed | Input is a bounded scalar array and is never rendered by this phase. |

Accessibility, focus, keyboard/pointer input, responsive behavior, reduced motion,
internationalization/RTL presentation, offline/optimistic UI, and visual regression are
also not applicable because no UI surface exists.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable — shadcn is not initialized or required |
| third-party | none | not applicable — no UI registry dependencies |

No registry code may be introduced as part of Phase 108.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: NOT APPLICABLE — no user-facing copy surface
- [x] Dimension 2 Visuals: NOT APPLICABLE — no visual or screenshot surface
- [x] Dimension 3 Color: NOT APPLICABLE — no rendered surface
- [x] Dimension 4 Typography: NOT APPLICABLE — no rendered text
- [x] Dimension 5 Spacing: NOT APPLICABLE — no layout or components
- [x] Dimension 6 Registry Safety: NOT APPLICABLE — no UI registry or blocks

**Approval:** verified 2026-07-30 — no UI surface; all six dimensions passed
