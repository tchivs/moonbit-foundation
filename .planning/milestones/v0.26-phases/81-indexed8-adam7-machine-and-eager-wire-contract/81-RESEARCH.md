# Phase 81: Indexed8 Adam7 Machine and Eager Wire Contract - Research

**Researched:** 2026-07-24  
**Domain:** bounded PNG Type-3/8 Adam7 encoding in the existing MoonBit machine  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public layout selection

- **D-01:** Add opt-in Indexed8 interlace selection using the established public `PngInterlaceStrategy`; retain `encode_indexed8` and `new_indexed8` as explicit `None` compatibility wrappers. — **Reversibility:** costly — changing those frozen wrappers would alter published call sites and canonical byte vectors.
- **D-02:** Restrict this phase to Type-3/8. Indexed Type-3/1, /2, and /4 Adam7 stays deferred until packed pass traversal has a separately proven bounded contract.

### Traversal and boundedness

- **D-03:** Reuse `_png_adam7_passes(width, height, 1UL, 8)` as the only pass-geometry authority. Read source samples with scalar `PngIndexedImage::index_at` at mapped pass coordinates; share geometry only, never coerce indexed images to `ImageView`.
- **D-04:** Extend the existing profile-aware `PngEncodeMachine` and its checked preflight/facts path. Do not introduce a second encoder, pass/image/output staging, new filter/compression strategies, or generic model widening.
- **D-05:** Derive every nonempty Adam7 row's filter tag, scanline/frame/work/output facts, limit admission, and sole budget charge before any eager output. Exact limits pass; one-less failure is atomic.

### Wire and proof

- **D-06:** The Adam7 wire contract remains Stored DEFLATE plus filter None, with `IHDR → PLTE → optional shortest canonical tRNS → IDAT → IEND` and valid CRCs.
- **D-07:** Use a hand-authored non-symmetric 5×5 Indexed8 fixture whose all seven passes are nonempty. Its inflated raw pass raster is an independent test oracle, never generated through production traversal helpers.
- **D-08:** Preserve the existing opaque and transparent Indexed8 non-interlaced literal vectors and all Indexed1/2/4 literal vectors as compatibility evidence.

### the agent's Discretion

- Factor a geometry-only internal location helper only if it keeps the existing ImageView Adam7 path and indexed scalar path clear and avoids duplicated pass arithmetic.
- Choose the exact additive method spelling consistent with established selector families, after confirming the current public API patterns during research.

### Deferred Ideas (OUT OF SCOPE)

Indexed low-bit Adam7, adaptive filters, Fixed/Dynamic indexed compression, palette generation, quantization, dithering, staging buffers, FFI, wrappers, copied source trees, and release automation are outside this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research support |
|---|---|---|
| INDEXADAM7-01 | Additive eager and caller-buffered Type-3/8 Adam7 APIs while old wrappers retain signatures and bytes. | Add `*_indexed8_with_interlace_strategy` selectors which call the existing indexed machine; keep `encode_indexed8` / `new_indexed8` forwarding `None`. [VERIFIED: planning artifacts; codebase inspection] |
| INDEXADAM7-02 | Traverse checked shared Adam7 geometry and read canonical indices directly, without a second encoder or staging. | Add an indexed scalar Adam7 location/byte branch at `PngEncodeMachine::scanline_byte`; geometry comes only from `_png_adam7_passes(width, height, 1UL, 8)`. [VERIFIED: planning artifacts; codebase inspection] |
| INDEXADAM7-03 | Preserve framed Type-3/8 output and exact public RGB8/RGBA8 decode. | Extend the existing frame machine and test its independent Type-3/8 raw-raster/chunk oracle plus public decoder. [VERIFIED: planning artifacts; codebase inspection] |
| INDEXADAM7-04 | Check layout-specific facts and atomic admission; exact passes and one-less leaves state unchanged. | Thread strategy into indexed preflight before its sole `budget.charge`; test output/work exact and one-less, with zero writer progress. [VERIFIED: planning artifacts; codebase inspection] |
</phase_requirements>

## Summary

Phase 81 is a narrow extension of the existing indexed machine, not a new encoder. `PngEncodeMachine::new_with_indexed_profile` currently calls indexed preflight and then fixes `interlace_strategy` to `None`; its indexed `scanline_byte` likewise maps each byte as a non-interlaced row. The generic `ImageView` route already has the checked Adam7 pass-total pattern, and the indexed frame machine already owns `IHDR`, `PLTE`, optional shortest `tRNS`, `IDAT`, `IEND`, CRC progression, and acknowledgement. Extend those same seams for `PngIndexedWireProfile::Eight` only. [VERIFIED: codebase inspection]

The recommended additive public spellings are `PngEncoder::encode_indexed8_with_interlace_strategy(...)` and `PngChunkEncoder::new_indexed8_with_interlace_strategy(...)`. This matches existing `*_with_interlace_strategy` selector families and makes the old entry points literal `None` wrappers. Phase 81 owns a normal sufficient-capacity lease smoke for the thin caller-buffered selector, asserting the selector reaches the shared machine and emits `IHDR` Adam7 byte `01`; Phase 82 owns zero/one/ragged/released-lease hostile schedules, tails, accepted-only progress, sticky terminal behavior, and final portable qualification. [VERIFIED: planning artifacts; codebase inspection]

**Primary recommendation:** Add the explicit strategy parameter only to the Indexed8 profile path; for `Adam7`, derive all facts from the shared pass list before the one budget charge and emit `00 + source.index_at(mapped_x, mapped_y)` for each nonempty pass row. [VERIFIED: planning artifacts; codebase inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Indexed8 API layout selection | API / Backend | — | Public MoonBit constructors select an existing wire layout; no browser or FFI responsibility exists. [VERIFIED: codebase inspection] |
| Adam7 pass geometry and scanline facts | API / Backend | — | Checked encoder preflight owns dimensions, limits, frame lengths, and budget admission. [VERIFIED: codebase inspection] |
| Scalar palette-index traversal | API / Backend | Database / Storage | The immutable `PngIndexedImage` is the source storage; the machine maps pass coordinates and reads `index_at`. [VERIFIED: planning artifacts; codebase inspection] |
| PNG chunk framing and CRC acknowledgement | API / Backend | — | The one `PngEncodeMachine` emits and acknowledges the wire bytes. [VERIFIED: codebase inspection] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain MoonBit-native; do not replace this route with a foreign implementation. [VERIFIED: AGENTS.md]
- Keep native stubs small and isolated; this phase adds no FFI. [VERIFIED: AGENTS.md]
- Keep public packages modular with acyclic dependencies; the work remains inside `mb-image/png`. [VERIFIED: AGENTS.md]
- Preserve deterministic GUI-free public operations and substantiate performance claims with reproducible work; this work adds deterministic byte-level tests rather than claims. [VERIFIED: AGENTS.md]
- Use the codebase graph for discovery when useful; its current `moonbit-foundation` index did not contain PNG symbols, so source inspection was the necessary fallback. [VERIFIED: codebase graph query; codebase inspection]

## Existing Entrypoints and Minimal Change Set

| File | Existing seam | Phase 81 change | Must not change |
|---|---|---|---|
| `modules/mb-image/png/encode.mbt` | `_png_encode_indexed_preflight_with_profile` computes normal rows; `encode_indexed8` builds the indexed machine. | Add an `interlace_strategy` parameter to the indexed preflight/profile constructor call chain; compute Adam7 pass-row sum for Eight; add `encode_indexed8_with_interlace_strategy`; retain existing `encode_indexed8` as a `None` wrapper. [VERIFIED: codebase inspection] | Do not route low-bit `encode_indexed` through Adam7 or alter its literal vectors. [VERIFIED: planning artifacts] |
| `modules/mb-image/png/stream_encode.mbt` | `new_indexed8` calls `new_with_indexed`; `new_with_indexed_profile` fixes interlace to `None`; `scanline_byte` only knows normal indexed row indexing. | Thread strategy into `new_with_indexed_profile`; add the thin `new_indexed8_with_interlace_strategy`; add direct scalar indexed Adam7 scanline emission. [VERIFIED: codebase inspection] | Do not add a second encoder, staging buffer, filters, compression modes, or lifecycle logic. [VERIFIED: planning artifacts] |
| `modules/mb-image/png/encode_test.mbt` | Has independent CRC/chunk helpers, public Indexed8 RGB/RGBA decode tests, literal non-interlaced vectors, and eager atomic-admission tests. | Add the hand-authored 5×5 Adam7 oracle, eager framing/decode, compatibility freeze re-runs, and writer/budget atomic tests. [VERIFIED: codebase inspection] | Do not replace legacy literal vector assertions. [VERIFIED: planning artifacts] |
| `modules/mb-image/png/encode_wbtest.mbt` | Already invokes indexed preflight and checks exact/one-less atomic work. | Add Type-3/8 Adam7 fact assertions: pass total, frame offsets, total, exact/one-less. [VERIFIED: codebase inspection] | Do not test low-bit Adam7. [VERIFIED: planning artifacts] |

`png.mbt` already exposes `PngInterlaceStrategy::{None, Adam7}` and several public `*_with_interlace_strategy` families, so no type addition is required. Phase 81 adds a minimal `stream_encode_test.mbt` selector-to-machine smoke using one ordinary sufficient-capacity lease and asserting Type-3/8 Adam7 `IHDR` interlace byte `01`; Phase 82 owns hostile lease schedules, tails, accepted-only progress, sticky terminal behavior, and four-target qualification. [VERIFIED: codebase inspection; planning artifacts]

## Architecture Pattern

```text
PngEncoder::encode_indexed8_with_interlace_strategy(source, strategy)
PngChunkEncoder::new_indexed8_with_interlace_strategy(source, strategy)
                         |
                         v
PngEncodeMachine::new_with_indexed_profile(source, Eight, strategy)
                         |
                         v
_png_encode_indexed_preflight_with_profile(..., strategy)
  None  -> (row_bytes + 1) * height
  Adam7 -> _png_adam7_passes(width, height, 1, 8)
             -> sum((pass.row_bytes + 1) * pass.height) for nonempty passes
                         |
                         v
limits + frame facts + Stored IDAT facts + one successful budget charge
                         |
                         v
existing PngEncodeMachine present/acknowledge
  IHDR(interlace=1) -> PLTE -> optional shortest tRNS -> IDAT -> IEND
                         |
                         v
indexed scanline byte: `00` tag, then `source.index_at(pass.x + col*dx, pass.y + row*dy)`
```

The diagram describes one machine and one preflight. The caller-buffered facade may construct that machine, but it must not duplicate preflight, traversal, or chunk state. [VERIFIED: planning artifacts; codebase inspection]

## Arithmetic and Traversal Seams

### Preflight arithmetic

1. Validate dimensions/pixels/palette constraints exactly as current indexed preflight does. [VERIFIED: codebase inspection]
2. Keep `row_bytes` as the normal wire-row width for profile Eight (`width`); for `None`, retain `(row_bytes + 1) * height` exactly. [VERIFIED: codebase inspection]
3. For `Adam7`, call `_png_adam7_passes(width, height, 1UL, 8)`, skip zero-width or zero-height passes, and checked-sum `(pass.row_bytes + 1) * pass.height`. This is the sole raw scanline count supplied to Stored-IDAT length, frame facts, output limit, work, and budget. [VERIFIED: planning artifacts; codebase inspection]
4. Derive the shortest canonical `tRNS` as today, derive frame facts, check every limit, obtain the empty disposition, then call `budget.charge` once. Any earlier failure returns without charging or emitting. [VERIFIED: codebase inspection]

For the proposed transparent 5×5 oracle (four PLTE entries and all seven nonempty passes), alpha is exactly `00 80 7F FF`; therefore the canonical `tRNS` is its first three bytes, `00 80 7F`. The expected raw pass raster length is 36 bytes. Stored zlib has one block, so `IDAT=36+6+5=47` and total PNG size is `33 + 24 + 15 + (12+47) + 12 = 143` bytes. Treat these as red-test constants only after the independent test fixture spells out its pass raster; do not generate the expected raster with `_png_adam7_passes` or production cursor helpers. [VERIFIED: planning artifacts; arithmetic derived from existing stored/frame formulas]

### Scalar traversal

The current indexed `scanline_byte` returns `00` at each normal row start and calls `source.index_at(in_row - 1, index / row_width)` for Eight. Add a strategy branch before that normal mapping: convert the global filtered byte index into `(pass, pass_row, in_pass_row)` using shared geometry, return `00` for `in_pass_row == 0`, and otherwise read the scalar source index at `pass.x + (in_pass_row - 1) * pass.x_step` and `pass.y + pass_row * pass.y_step` (using the actual existing `PngAdam7Pass` coordinate-field names). A geometry-only helper is worthwhile only if both the existing ImageView cursor and this indexed branch can use it without creating a generic source abstraction. [VERIFIED: codebase inspection; planning artifacts]

This branch is admitted only when `profile == PngIndexedWireProfile::Eight` and strategy is `Adam7`; normal Indexed8 and every Indexed1/2/4 caller continue through the existing row/packing path. [VERIFIED: planning artifacts; codebase inspection]

## Atomic Preflight Contract

| Checkpoint | Required outcome |
|---|---|
| Invalid dimensions, multiplication, palette cap, or pass arithmetic | Return before frame work and before the charge. [VERIFIED: codebase inspection] |
| Any width/height/pixel/output/work limit failure | Return before the charge and before eager writer output. [VERIFIED: codebase inspection] |
| Exact output/work budget | Construct machine and consume exactly the admitted work. [VERIFIED: existing indexed preflight tests; codebase inspection] |
| One-less output or work budget | Return error, writer remains at position zero, and every budget resource limit is unchanged. [VERIFIED: existing eager/indexed atomic tests; planning artifacts] |

The new thin chunk constructor must call the same constructor/preflight. Phase 81 proves selector-to-machine wiring by draining one ordinary sufficient-capacity lease and asserting `IHDR` Adam7 byte `01`; Phase 82 proves zero/one/ragged lease schedules, tails, accepted-only progress, sticky terminal semantics, and final portable qualification. [VERIFIED: planning artifacts]

## Minimal Red/Green Test Sequence

1. **Red — API and independent wire oracle:** add a non-symmetric 5×5 Indexed8 source with explicit indices, four PLTE entries, alpha `00 80 7F FF`, and an explicit 36-byte inflated raw Adam7 raster containing 11 literal `00` filter tags (one per nonempty pass row). Call the intended eager selector; parse chunks with the existing test-local CRC helpers, assert `IHDR` bit depth 8/colour type 3/interlace 1, 12-byte `PLTE`, canonical three-byte `tRNS` `00 80 7F`, one `IDAT` of 47 bytes, total length 143, valid CRCs, chunk order, and the independently inflated raw raster. This initially fails to compile because the selector does not exist. [VERIFIED: planning artifacts; codebase inspection]
2. **Green — API/machine threading:** introduce the two additive selectors, make both legacy wrappers literally select `None`, and thread strategy into indexed machine construction. Confirm the old 89-byte opaque and 112-byte transparent literal vectors still pass unchanged. [VERIFIED: codebase inspection]
3. **Red/green — traversal:** assert every decoded pixel equals the original 5×5 RGB/RGBA palette result, then implement the scalar Adam7 `scanline_byte` branch. The test oracle must remain test-local rather than sharing production traversal. [VERIFIED: planning artifacts; codebase inspection]
4. **Red/green — facts and atomicity:** add white-box Eight/Adam7 exact facts (`scanlines=36`, `idat_length=47`, total `143` for the fixture), exact work succeeds and reaches zero remaining work, and one-less work/output fails without changing budget or writer position. Then change indexed preflight to calculate the pass sum before its sole charge. [VERIFIED: planning artifacts; codebase inspection]
5. **Green — caller-buffered selector smoke:** construct `PngChunkEncoder::new_indexed8_with_interlace_strategy(..., Adam7, ...)`, drain it through one ordinary sufficient-capacity lease, and parse the `IHDR` Type-3/8 fields with interlace byte `01`. Do not add hostile schedules, tail sentinels, released leases, accepted-only progress, or sticky-terminal coverage here. [VERIFIED: planning artifacts]
6. **Regression gate:** retain the existing Indexed1/2/4 packing/vector tests and both Indexed8 normal vectors in the ordinary package suite. Do not add low-bit Adam7 cases. [VERIFIED: planning artifacts; codebase inspection]

## Don't Hand-Roll

| Problem | Do not build | Use instead | Why |
|---|---|---|---|
| Adam7 geometry | A second pass table or independent coordinate arithmetic | `_png_adam7_passes(width, height, 1UL, 8)` plus, if needed, a geometry-only location helper | Separate geometry definitions would let preflight and emission disagree. [VERIFIED: planning artifacts; codebase inspection] |
| Indexed encoder | A parallel eager/chunk implementation | `PngEncodeMachine` and existing `present`/`acknowledge` flow | CRC, framing, Stored DEFLATE, and acceptance semantics already live there. [VERIFIED: codebase inspection] |
| Raw raster materialisation | A pass/image/output staging buffer | Byte-at-a-time scalar `index_at` emission | The boundary explicitly prohibits staging and the existing machine is pull-based. [VERIFIED: planning artifacts; codebase inspection] |
| New compression/filter policy | Adaptive, Fixed, or Dynamic indexed path | Existing Stored + filter None contract | This phase's proof and preflight arithmetic cover one deterministic contract only. [VERIFIED: planning artifacts] |

## Risks and Planner Guardrails

| Risk | Guardrail |
|---|---|
| Normal `row_bytes * height` accidentally used for Adam7 | Route all raw-byte facts through the same checked pass sum before Stored-IDAT/frame/limit/work calculations. [VERIFIED: planning artifacts] |
| Filter tag absent per pass row | The independent oracle includes 11 literal `00` tags, one for each of the seven passes' 11 nonempty rows. [VERIFIED: planning artifacts] |
| Source coordinate order wrong | Use the scalar `index_at` mapped coordinates; assert public decode of all 25 non-symmetric pixels. [VERIFIED: planning artifacts] |
| Low-bit path accidentally gains Adam7 | Limit the strategy branch to Eight and preserve all existing Indexed1/2/4 vectors. [VERIFIED: planning artifacts; codebase inspection] |
| Eager and chunk APIs diverge | Both selectors call one indexed profile constructor; Phase 81 smoke-tests selector-to-machine `IHDR` wiring, and Phase 82 owns lifecycle stress proof. [VERIFIED: planning artifacts; codebase inspection] |
| Contradictory phase wording on caller selector ownership | Treat `INDEXADAM7-01` and locked D-01 as authoritative: add the thin selector in Phase 81; reserve the Phase 82 hostile-lifecycle test suite for Phase 82. [VERIFIED: planning artifacts] |

## Validation Architecture

`workflow.nyquist_validation` is explicitly disabled in `.planning/config.json`; this phase therefore does not require a Nyquist validation plan. The repository's ordinary PNG package gate remains the release-quality verification for the implementation. [VERIFIED: .planning/config.json; planning artifacts]

**Focused development checks** (use exact finalized test names if a filter is supported; the full gate is authoritative):

```powershell
moon -C modules/mb-image test png --target native --frozen
moon -C modules/mb-image test png --target all --frozen
```

The first command gives Phase 81 a quicker native compile/test loop. The target-all command is the Phase 82 final independent portability qualification for `INDEXADAM7-06`, not Phase 81's acceptance scope. [VERIFIED: planning artifacts]

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | The exact `PngAdam7Pass` field spelling for horizontal/vertical step is represented here as `x_step`/`y_step`; implementation must use the actual declared field names. | Scalar traversal | Compilation failure only; inspect the pass struct before editing. [ASSUMED] |

## Open Questions

1. **How is the caller-buffered selector test split?**
   - What we know: Phase 81 owns one ordinary sufficient-capacity lease smoke that asserts the new selector reaches Type-3/8 Adam7 `IHDR` byte `01`; Phase 82 owns hostile schedules, tails, accepted-only progress, sticky terminal behavior, and final portable qualification. [VERIFIED: planning artifacts]
   - What's unclear: Only the exact existing ordinary-drain helper spelling needs confirmation while writing the test. [VERIFIED: codebase inspection]
   - Recommendation: reuse that ordinary drain shape for the Phase 81 smoke and leave all adversarial lifecycle assertions to Phase 82. [VERIFIED: planning artifacts]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/81-indexed8-adam7-machine-and-eager-wire-contract/81-CONTEXT.md` — locked boundary, traversal, atomicity, wire and freeze decisions. [VERIFIED: planning artifacts]
- `.planning/REQUIREMENTS.md` — `INDEXADAM7-01` through `INDEXADAM7-04` ownership and Phase 82 exclusions. [VERIFIED: planning artifacts]
- `.planning/research/v026-ADAM7-SUMMARY.md` — accepted API, pass-oracle, test, and sequencing recommendations. [VERIFIED: planning artifacts]
- `modules/mb-image/png/encode.mbt` — indexed preflight, eager entry points, generic Adam7 fact calculation. [VERIFIED: codebase inspection]
- `modules/mb-image/png/stream_encode.mbt` — indexed machine constructor, scalar scanline seam, thin chunk facade, and IHDR interlace emission. [VERIFIED: codebase inspection]
- `modules/mb-image/png/encode_test.mbt`, `encode_wbtest.mbt` — independent CRC helper, normal Indexed8 vectors, decode, and atomic-preflight evidence. [VERIFIED: codebase inspection]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no package, FFI, or toolchain addition; all work is inside the existing MoonBit PNG package. [VERIFIED: codebase inspection]
- Architecture: HIGH — the existing machine, preflight, framing, and scanline seams directly identify the minimum extension. [VERIFIED: codebase inspection]
- Pitfalls: HIGH — locked phase decisions and current normal-row hardcoding expose the relevant failure modes. [VERIFIED: planning artifacts; codebase inspection]

**Research date:** 2026-07-24  
**Valid until:** implementation begins or the Phase 81 context/contracts change.
