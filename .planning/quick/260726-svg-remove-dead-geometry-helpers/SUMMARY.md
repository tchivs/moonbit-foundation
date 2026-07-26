---
title: Remove unused SVG geometry helpers
status: complete
---

# Summary

Removed post-v0.31 dead private geometry helpers from scene.mbt and lower.mbt. Active path remains geometry.mbt for both parser preflight and total lowering.

## Verification
- moon -C modules/mb-svg test svg --target all --frozen → 137/137 on js, native, wasm, wasm-gc
