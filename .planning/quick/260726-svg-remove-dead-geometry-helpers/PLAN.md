---
title: Remove unused SVG geometry helpers
status: planned
---

# Plan

Remove dead private geometry helpers left in scene.mbt and lower.mbt after v0.31 unified on geometry.mbt.

## Scope
- modules/mb-svg/svg/scene.mbt
- modules/mb-svg/svg/lower.mbt
- .planning/PROJECT.md debt note

## Non-goals
- No font / Phase 97 work
- No public API changes
- No behavior changes

## Acceptance
- Dead helpers gone
- 137/137 mb-svg tests on all four targets
