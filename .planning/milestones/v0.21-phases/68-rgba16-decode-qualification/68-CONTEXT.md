# Phase 68: RGBA16 Decode Qualification - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Qualify the completed explicit eager and chunk RGBA16 decoding contract with independent Type-6/16 filter and Adam7 wire evidence, exact resource boundaries, hostile terminal behavior, frozen generic compatibility, and portable four-target execution. This phase may make only narrow profile-store repairs found by qualification; it does not introduce APIs or a second decoder.

</domain>

<decisions>
## Implementation Decisions

### Evidence quality
- **D-01:** Use fixed, hand-authored Type-6/16 PNG literals: all five filter tags and an all-seven-pass Adam7 fixture, with distinct lane bytes at every asserted coordinate. Do not derive expected bytes from PngEncoder.
- **D-02:** Qualify both eager `decode_rgba16` and chunk `new_rgba16`; chunk tests include empty, one-byte, ragged, malformed and terminal replay schedules, while generic eager/chunk stays frozen on RGBA8 high bytes.

### Resource and compatibility safety
- **D-03:** Demonstrate exact and one-less normal/Adam7 output, image and work limits; the eight-byte result allocation must be charged before decompression advances and no failure may expose a result.
- **D-04:** Preserve strict default/sRGB Type-6/16 admission, typed preallocation failure, accepted-only progress, private lifecycle and sticky terminals under hostile metadata/data.
- **D-05:** Run the ordinary PNG package serially on wasm, wasm-gc, js and native. No copied source trees, generated decoder oracle, FFI, release automation, or target-specific expectations.

### the agent's Discretion
- Extend Phase 66/67 test helpers and wire constants as narrowly as possible; if a real qualification gap exposes a shared-store bug, fix it in place with a targeted regression.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — `RGBA16DEC-04` qualification requirement.
- `.planning/ROADMAP.md` — Phase 68 success criteria and scope guard.
- `.planning/phases/66-explicit-rgba16-png-preservation/66-VERIFICATION.md` — eager profile admission, exact store and resource contract.
- `.planning/phases/67-resumable-rgba16-png-preservation/67-VERIFICATION.md` — chunk lifecycle and terminal contract.
- `modules/mb-image/png/png_test.mbt` — public explicit eager and generic compatibility fixtures.
- `modules/mb-image/png/stream_decode_test.mbt` — public chunk schedule/parity fixtures.
- `modules/mb-image/png/stream_decode_wbtest.mbt` — internal resource/admission/terminal fixtures.

</canonical_refs>

<code_context>
## Existing Code Insights

- Phase 66 Rgba16 profile already owns normal and Adam7 final stores plus eight-byte layout charging.
- Phase 67 `new_rgba16` reuses the same private machine; qualification must compare observed results rather than add another path.
- Existing public/white-box PNG tests provide the wire builders, chunk schedules, budget fixtures and serial four-target package command.

</code_context>

<specifics>
## Specific Ideas

Any low-byte loss, endianness reversal, filter-stride defect, Adam7 coordinate error, undercharged eight-byte allocation, or widened generic behavior is a release-blocking failure.

</specifics>

<deferred>
## Deferred Ideas

None — this is the final v0.21 qualification phase. Non-sRGB conversion and high-precision conversion APIs remain future scope.

</deferred>

---

*Phase: 68-RGBA16 Decode Qualification*
*Context gathered: 2026-07-23*
