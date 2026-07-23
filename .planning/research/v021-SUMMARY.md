# v0.21 Research Summary — RGBA16 PNG Decode

**Decision:** Deliver explicit Type-6/16 PNG preservation as a narrow extension of the existing portable model and shared bounded PNG decoder. Do not widen generic decode or introduce a conversion layer.

## Locked Architecture

- Add `ImageFormat::rgba16()` as one packed eight-byte-per-pixel, little-endian plane with storage order `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi`.
- Add a dedicated identity validator that requires straight alpha, encoded builtin sRGB, top-left orientation, packed layout, and little-endian U16 lanes; existing U8-only operations remain fail-closed.
- Add `PngDecodeProfile::Rgba16`, `PngDecoder::decode_rgba16`, and `PngChunkDecoder::new_rgba16`; both selectors use the existing byte-fed bounded machine.
- Permit only Type-6/16 input with no declaration or sRGB declaration; reject transparency, legacy-colour, and ICC declarations before allocation.
- Keep generic Type-6/16 eager and chunk decode exactly `RGBA8(Rhi,Ghi,Bhi,Ahi)`.
- Add profile-aware normal and Adam7 final stores only; reuse framing, DEFLATE, byte-domain filtering, pass traversal, budget ownership, progress, and sticky-terminal machinery.

## Delivery Order

1. Establish checked `rgba16` model/storage identity and fail-closed U8 compatibility.
2. Add explicit eager Type-6/16 decoding with exact normal-row byte preservation and frozen generic output.
3. Add caller-buffered selection and parity/terminal semantics through the same profile machine.
4. Qualify independent five-filter and seven-pass Adam7 literals, profile/resource hostility, generic compatibility, and the direct four-target package command.

## Qualification Facts

- Independent 2×5 all-filter and 5×5 all-pass Adam7 Type-6/16 literals are required; existing generated RGBA16 vectors remain generic regression evidence only.
- Explicit lanes assert `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi`; generic lanes assert `Rhi,Ghi,Bhi,Ahi`.
- Resource boundary fixtures need exact/one-less image/output/work gates: filter `80/85/165`, Adam7 `200/211/411`.
- The final proof remains `moon -C modules/mb-image test png --target all --frozen` without wrappers, copies, or target-specific expectations.

## Scope Fences

No implicit conversion, premultiplication, non-sRGB/ICC transformation, generic result widening, image-sized staging, alternate decoder, FFI, release automation, or copied-source workflow.
