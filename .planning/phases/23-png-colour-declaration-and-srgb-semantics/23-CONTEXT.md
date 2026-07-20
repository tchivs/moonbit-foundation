# Phase 23 Context: PNG Colour Declaration and sRGB Semantics

## Locked Decisions

- Implement a strict eager decoder extension only; do not add a public streaming API, FFI, release automation, or an ICC transform engine.
- Recognise `sRGB`, `gAMA`, `cHRM`, and `iCCP` as singleton semantic chunks before `PLTE` and `IDAT`; malformed, duplicate, late, or unsupported-precedence declarations fail before image output.
- A valid `sRGB` chunk maps to existing built-in encoded-sRGB metadata and retains the one-byte rendering intent through bounded metadata.
- Do not label a file as sRGB merely because its raster samples are RGB/RGBA. Non-sRGB declarations remain Phase 24 work and must continue to reject with a typed capability result in Phase 23.
- Existing reference image operations must continue to require actual encoded sRGB, preserving their current semantics.

## Scope Fence

Phase 23 does not parse or preserve a usable ICC profile, implement gamma/chromaticity transforms, accept cICP/HDR, alter canonical PNG encoding, or touch QOI files currently modified in the worktree.

## Evidence

- `.planning/research/PNG-COLOUR-SPEC.md`
- W3C PNG Third Edition, colour-space precedence, chunk ordering, and `sRGB` syntax.

## Success Evidence

- Public PNG decoding returns built-in encoded-sRGB metadata and the rendering intent for valid sRGB input on every supported target.
- Tests reject wrong-length/intent, duplicate, late, and pre-`PLTE`/`IDAT` ordering violations before image visibility.
- Existing non-sRGB semantic chunks remain explicit typed capability rejections rather than being dropped or reinterpreted.
