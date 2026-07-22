# Phase 42: Bounded Adam7 Pass Encoding - Research

**Researched:** 2026-07-22
**Domain:** MoonBit PNG encoder: bounded Adam7 raster traversal, PNG method-0 filtering, DEFLATE planning, and acknowledgement-safe streaming replay
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Replace Phase 41's typed Adam7-pending boundary with real, bounded Adam7 RGB8/RGBA8 emission. Preserve all non-interlaced bytes and public API choices; public portability evidence remains Phase 43.

- Reuse `_png_adam7_passes` as the only checked pass-geometry authority; do not duplicate pass formulas.
- Model all nonempty passes as one deterministic logical filtered-byte source. Each pass starts a fresh PNG filter row history; Adaptive selection never reads a row from another pass.
- Let Stored, FixedOrStored, and DynamicOrFixedOrStored planning plus acknowledgement-safe replay consume that same bounded source. No pass/image-sized token buffer, selected-row cache, or staging output is allowed.
- Extend the atomic preflight ledger with exact pass scanline/filter/compression traversals and retain existing capability, dimension, output, work, and budget rejection semantics.
- Write IHDR interlace method `1` only for the real Adam7 route; legacy None remains method `0` with frozen bytes.
- Keep public factory surface from Phase 41 unchanged; Phase 42 changes pending rejection to actual emission only for compatible RGB8/RGBA8 sources.

### the agent's Discretion

No separate discretion section is present in CONTEXT.md. Implementation naming and the private representation of the bounded logical source remain discretionary, subject to the locked decisions above.

### Deferred Ideas (OUT OF SCOPE)

- Generated public four-target Adam7 fidelity corpus and final compatibility proof remain Phase 43.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PNGI-02 | An opted-in compatible image is emitted as seven deterministic Adam7 passes whose pass geometry, scanline bytes, filter selection, and compression input are bounded by existing limits and require no image-sized staging. | A seven-entry geometry list already exists; replace full-image filtered addressing with one pass-aware persistent byte cursor and feed it into all three planners/replay paths. |
| PNGI-03 | Adam7 Stored, FixedOrStored, and DynamicOrFixedOrStored preserve atomic capability, geometry, output, work, and budget admission before eager output or caller lease; replay advances only after accepted bytes. | Extend the current single preflight ledger and retain `present`/`acknowledge` successor-state discipline for the new pass-aware cursor. |
</phase_requirements>

## Summary

Phase 42 should be a private encoder-routing change, not a new public API or codec. `_png_adam7_passes` in `structural.mbt` already supplies the canonical seven `(x, y, dx, dy, width, height, row_bytes)` descriptions with checked arithmetic, and the decoder already maps a pass sample through `x + column * dx` and `y + row * dy`. Reuse those facts directly for encoding. [VERIFIED: codebase inspection — `modules/mb-image/png/structural.mbt:588`, `modules/mb-image/png/raster_decode.mbt:444`]

The existing `PngFilteredCursor` models a full-image row as `row_bytes + 1` bytes and computes `Up`/`Paeth` from `row - 1`; that cannot be used unchanged for Adam7 because each pass has its own row geometry and history. Create one persistent, pass-aware logical filtered-byte source that skips empty passes, emits the filter tag then selected samples for each pass row, and uses pass-local left/above coordinates. All Stored, Fixed, and Dynamic planning and replay must instantiate fresh cursors over this exact source, retaining only the existing 262-byte match window plus scalar cursor state. [VERIFIED: codebase inspection — `modules/mb-image/png/encode.mbt:470`, `modules/mb-image/png/encode.mbt:640`, `modules/mb-image/png/encode.mbt:744`]

**Primary recommendation:** Introduce a private raster-layout/pass-aware cursor abstraction in `encode.mbt`, dispatch the existing preflight/planner machinery through it for Adam7, and make `stream_encode.mbt` use that cursor whenever the selected layout is Adam7 while preserving the direct legacy `None` route byte-for-byte. [VERIFIED: codebase inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Checked Adam7 geometry | API / Backend | — | Private PNG structural helpers own checked pass dimensions and are already shared by decode. [VERIFIED: codebase inspection — `structural.mbt:588`] |
| Pass-local filtered byte production | API / Backend | — | The encoder reads `ImageView` samples and must impose PNG filtering/predictor history without allocating a pass raster. [VERIFIED: codebase inspection — `encode.mbt:470`] |
| Compression selection and resource admission | API / Backend | — | The private preflight performs Stored/Fixed/Dynamic traversal, output/work checks, and the single budget charge before construction. [VERIFIED: codebase inspection — `encode.mbt:1183`] |
| Caller-buffered retry and acknowledgement | API / Backend | — | `PngChunkEncoder::pull` commits a preview only after the destination accepts the byte, delegated to the private machine. [VERIFIED: codebase inspection — `stream_encode.mbt:112`, `stream_encode.mbt:856`] |
| PNG framing/IHDR interlace declaration | API / Backend | — | `PngEncodeMachine::byte_at` emits the IHDR payload and its acknowledgement path computes the CRC. [VERIFIED: codebase inspection — `stream_encode.mbt:804`, `stream_encode.mbt:856`] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be MoonBit-native; do not replace this encoder with a foreign codec wrapper. [CITED: AGENTS.md]
- Native is primary, but portable targets require explicit capability boundaries and conformance tests. [CITED: AGENTS.md]
- Public package dependencies must remain acyclic and explicitly documented. [CITED: AGENTS.md]
- Public operations must be deterministic and usable without GUI state. [CITED: AGENTS.md]
- Benchmark claims require declared workloads and reproducible baselines; Phase 42 must not introduce performance claims without that evidence. [CITED: AGENTS.md]
- Public package black-box tests use `*_test.mbt`; internal invariant and checked-arithmetic tests use `*_wbtest.mbt`. [CITED: AGENTS.md]
- The workspace supports `js`, `wasm`, `wasm-gc`, and `native`; Phase 43 owns generated four-target Adam7 proof, so do not expand Phase 42 into that corpus. [CITED: AGENTS.md, `42-CONTEXT.md`]
- No direct implementation edits outside an active GSD workflow; this research artifact is the only allowed write in this task. [CITED: AGENTS.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit standard/workspace toolchain | `moon 0.1.20260713` | Compile and test the existing pure-MoonBit PNG implementation. | The workspace package declares all four production targets and contains the existing encoder, decoder, checked arithmetic, budget, and byte I/O primitives. [VERIFIED: local `moon version`; `modules/mb-image/png/moon.pkg`] |
| Existing `tchivs/mb-image/png` private encoder | workspace source | Adam7 pass emission, PNG filtering, DEFLATE selection, framing, and replay. | Phase scope explicitly requires extension of this bounded MoonBit-owned implementation rather than a dependency. [VERIFIED: codebase inspection; CITED: AGENTS.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|
| `tchivs/mb-core/checked` | workspace source | Checked `UInt64` addition/multiplication in geometry, logical-byte totals, output, and work ledgers. | Use for every new pass-total or cursor-bound arithmetic operation. [VERIFIED: codebase inspection — `structural.mbt:588`, `encode.mbt:1183`] |
| `tchivs/mb-core/budget` | workspace source | Atomic resource charge after all admission facts are known. | Reuse the existing one-charge preflight path; do not charge per emitted pass. [VERIFIED: codebase inspection — `encode.mbt:1355`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| A persistent pass-aware logical byte cursor | Materialize seven pass buffers or a selected-filter cache | Rejected: it violates the locked no pass/image-sized staging rule and makes replay consume stored state rather than regenerate bounded bytes. [CITED: `42-CONTEXT.md`] |
| Shared `_png_adam7_passes` | Duplicate inline Adam7 width/height formulas in encoder | Rejected: it would create geometry drift from structural validation and decoder scatter logic. [CITED: `42-CONTEXT.md`] |
| Existing Stored/Fixed/Dynamic planners over the common cursor | An Adam7-specific compressor | Rejected: it forks established selection/tie/replay and ledger semantics without satisfying a requirement. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode.mbt:1237`] |

**Installation:** No external packages are installed in this phase. [VERIFIED: codebase inspection]

## Architecture Patterns

### System Architecture Diagram

```text
ImageView + public strategy selections
                |
                v
_png_encode_preflight_with_interlace
  | None --------------------> legacy full-image route (unchanged bytes)
  |
  ` Adam7 --> _png_adam7_passes(width, height, channels, 8)
                    |
                    v
             bounded raster layout (7 small geometry records)
                    |
                    v
      fresh pass-aware PngFilteredCursor per traversal
      - skip empty passes
      - filter tag + samples in pass order
      - reset row history at each pass boundary
                    |
       +------------+-------------+
       |            |             |
       v            v             v
     Stored      Fixed plan     Dynamic plan
       |            |             |
       +------------+-------------+
                    |
              exact output/work ledger
                    |
          limits + one atomic budget charge
                    |
                    v
        PngEncodeMachine preview -> acknowledge -> output
                    |
      IHDR interlace 1 for Adam7 / 0 for legacy None
```

### Recommended Project Structure

```text
modules/mb-image/png/
├── structural.mbt           # retain the sole checked `_png_adam7_passes` authority
├── encode.mbt               # private raster-layout, filtered cursor, plans, and preflight ledger
├── stream_encode.mbt        # machine construction, IHDR byte, preview/acknowledge cursor ownership
├── encode_wbtest.mbt        # private geometry/scanline/ledger invariants
├── encode_test.mbt          # minimal eager public Adam7 route assertions
└── stream_encode_test.mbt   # hostile-capacity and atomic caller-buffered assertions
```

### Pattern 1: Represent raster traversal separately from DEFLATE

**What:** Add a small private layout/value (for example `PngEncodeRaster`) that distinguishes the frozen non-interlaced row geometry from an Adam7 layout holding the seven records returned by `_png_adam7_passes`, its exact `scanlines` total, and a maximum pass row width if needed for invariants. Pass the layout to filtered and match cursors rather than passing only `row_bytes` and `source.height()`. [VERIFIED: codebase inspection — current scalar assumptions at `encode.mbt:470`, `encode.mbt:504`]

**When to use:** Construct it once inside interlace preflight after `_png_encode_source` confirms RGB8 or straight-RGBA8 and before compression planning. The `None` layout must retain the current direct provider path. [VERIFIED: codebase inspection — `encode.mbt:1166`, `stream_encode.mbt:403`]

**Example:**

```moonbit
// Derived from codebase cursor/preflight patterns; names are private implementation discretion.
priv enum PngEncodeRaster {
  None(row_bytes : UInt64, height : UInt64)
  Adam7(passes : Array[PngAdam7Pass], scanlines : UInt64)
}

// A cursor's persistent state includes pass_index, pass_row, in_row, and winner.
// `next()` advances only the preview successor; it skips empty passes and emits
// the next pass tag/sample coordinate without allocating a row.
```

Source: [VERIFIED: codebase inspection — `encode.mbt:470`, `structural.mbt:588`]

### Pattern 2: Pass-local filtering through coordinates, not reconstructed rows

**What:** Generalize the adaptive candidate/residual helpers so a pass supplies its own coordinate transform. At local pass `(column, row)`, source sample is `(pass.x + column * pass.dx, pass.y + row * pass.dy)`; left exists only when `column > 0`, above only when `row > 0`, and upper-left only when both exist. The previous row must never come from a different Adam7 pass. [VERIFIED: codebase inspection — decoder transform at `raster_decode.mbt:444`; current full-image predictor at `encode.mbt:401`]

**When to use:** Use this helper for both Adaptive scoring and selected residual bytes. Filter None still produces tag `0` followed by pass samples through the same logical source. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode.mbt:504`]

**Example:**

```moonbit
// Conceptual private helper; all arithmetic is checked where totals/cursors change.
fn adam7_sample(pass, pass_row, column, channel) {
  source.get_byte(pass.x + column * pass.dx, pass.y + pass_row * pass.dy, channel)
}
// `above` calls adam7_sample(pass, pass_row - 1, ...) only if pass_row > 0.
```

Source: [VERIFIED: codebase inspection — `raster_decode.mbt:444`, `encode.mbt:401`]

### Pattern 3: One deterministic source, fresh traversal for every plan/replay pass

**What:** Leave `_png_filtered_match_traverse`, `_png_fixed_plan`, `_png_dynamic_plan_with_idat_limit`, and machine replay structurally intact, but make their cursor constructors consume the same raster layout. Every traversal receives a fresh persistent cursor; `PngFilteredMatchCursor` retains its existing fixed 262-byte window and advances logical consumption only for an emitted DEFLATE token. [VERIFIED: codebase inspection — `encode.mbt:640`, `encode.mbt:777`, `encode.mbt:1063`, `encode.mbt:1313`]

**When to use:** Stored has planning traversal plus replay; Fixed adds its matcher traversal; Dynamic adds frequency and exact-bit traversals. The selected replay walk remains included before the atomic charge exactly as it is now. [VERIFIED: codebase inspection — `encode.mbt:1237`, `encode.mbt:1313`]

### Pattern 4: Keep preview state private until acknowledgement

**What:** For Adam7, initialize `stored_cursor`, `fixed_state.filtered_cursor`, and `dynamic_state.filtered_cursor` with the pass-aware cursor even when `PngFilterStrategy::None`; this is necessary because direct `scanline_byte(index)` only understands full-image rows. Preserve current direct `None` initialization for non-interlaced output. [VERIFIED: codebase inspection — `stream_encode.mbt:331`, `stream_encode.mbt:403`, `stream_encode.mbt:856`]

**When to use:** `present` may calculate a byte repeatedly, but `acknowledge` is the only place that swaps in `pending_stored`, `pending_fixed`, or `pending_dynamic`. Do not advance pass, row, match window, Adler, or CRC state in preview. [VERIFIED: codebase inspection — `stream_encode.mbt:836`, `stream_encode.mbt:856`]

### Anti-Patterns to Avoid

- **Duplicate Adam7 geometry arithmetic:** Do not recalculate pass dimensions or start/stride values in `encode.mbt`; receive the checked records from `_png_adam7_passes`. [CITED: `42-CONTEXT.md`]
- **Full-image `row - 1` for a pass predictor:** It leaks filter history across passes and creates invalid adaptive tags/residuals. Use pass-local row coordinates. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode.mbt:401`]
- **A staged pass or output buffer:** Do not retain pass rows, selected filters, token streams, or compressed IDAT bytes; the allowed bounded retained bytes are the existing fixed 262-byte matcher window and scalar state. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode.mbt:640`]
- **A second admission path for Adam7:** Do not charge a budget or expose eager/caller-buffered state before all chosen-plan facts are known. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode.mbt:1136`]
- **Writing IHDR method 1 for non-interlaced encoders:** The frozen routes must keep method 0 and byte-identical output. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `stream_encode.mbt:804`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Adam7 pass sizing | A new encoder-local pass formula | `_png_adam7_passes` | It centralizes checked geometry already shared with structural validation and raster decode. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `structural.mbt:588`] |
| Compression plan selection | A pass-specific stored/fixed/dynamic chooser | Existing `PngDeflatePlan` plus `_png_fixed_plan` / `_png_dynamic_plan_with_idat_limit` | It already records scalar replay facts, strict dynamic tie behavior, IDAT checks, and selected work. [VERIFIED: codebase inspection — `encode.mbt:959`, `encode.mbt:1063`, `encode.mbt:1237`] |
| Resumable output state | A separate Adam7 stream writer | `PngEncodeMachine::present` / `acknowledge` state transition model | It already guarantees a preview is committed only after accepted output. [VERIFIED: codebase inspection — `stream_encode.mbt:836`, `stream_encode.mbt:856`] |
| Resource accounting | Approximate fixed multipliers for pass work | Actual fresh cursor traversals and the existing `PngFilteredTraversalFacts` aggregation | Adaptive work depends on real rows/candidates and compression strategy traversal count. [VERIFIED: codebase inspection — `encode.mbt:129`, `encode.mbt:1313`] |

**Key insight:** Adam7 changes the producer of the filtered logical byte stream, not the ownership model of compression or output. Keep the existing compression/replay machinery and replace only its input abstraction. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection]

## Common Pitfalls

### Pitfall 1: Cross-pass adaptive predictor history

**What goes wrong:** `Up`, `Average`, or `Paeth` reads the full image's preceding source row rather than the preceding row in the same pass. [VERIFIED: codebase inspection — current full-image row lookup at `encode.mbt:401`]

**Why it happens:** The current adaptive helpers encode a non-interlaced row number, and an Adam7 local row may map to a non-adjacent image `y`. [VERIFIED: codebase inspection — `encode.mbt:401`; `raster_decode.mbt:444`]

**How to avoid:** Keep pass index/local row/local column in the cursor and make all predictor lookups through `pass.x/y/dx/dy`; reset winner/history when moving to a new nonempty pass. [CITED: `42-CONTEXT.md`]

**Warning signs:** A targeted image that makes pass 1 and pass 2 use different first-row tags exposes a nonzero `Up`/`Paeth` dependency for the first row of a pass. [ASSUMED]

### Pitfall 2: Updating only Stored emission

**What goes wrong:** Stored emits pass bytes but Fixed/Dynamic still call `_png_fixed_scanline_byte` or construct a noninterlaced cursor, causing plan/replay drift or invalid DEFLATE input. [VERIFIED: codebase inspection — `stream_encode.mbt:403`, `stream_encode.mbt:478`, `stream_encode.mbt:654`]

**Why it happens:** Existing nonadaptive Fixed/Dynamic bypass cursor state while Stored only gets a match cursor for Adaptive. [VERIFIED: codebase inspection — `stream_encode.mbt:331`]

**How to avoid:** For Adam7, force all strategies through the common pass-aware match cursor and retain the legacy direct fast path only for `None` interlace. [CITED: `42-CONTEXT.md`]

**Warning signs:** Fixed/Dynamic end-of-replay errors such as `png-encode-fixed-replay-drift` or `png-encode-dynamic-replay-drift`, or eager/chunk mismatch under one-byte leases. [VERIFIED: codebase inspection — `stream_encode.mbt:559`, `stream_encode.mbt:756`]

### Pitfall 3: Inexact preflight work/budget accounting

**What goes wrong:** Admission uses one pass count or one filter sweep, but the selected strategy actually performs Stored, Fixed, Dynamic frequency/bit, and replay traversals. [VERIFIED: codebase inspection — `encode.mbt:1237`, `encode.mbt:1313`]

**Why it happens:** Adam7's logical byte total is a sum of only nonempty pass rows, not `(full_row_bytes + 1) * image_height`. [VERIFIED: codebase inspection — `structural.mbt:621`]

**How to avoid:** Sum `(pass.row_bytes + 1) * pass.height` with checked operations, execute the same fresh cursor traversals as the final selected plan, then use the existing one final charge. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode.mbt:1355`]

**Warning signs:** A budget of exactly `selected_work` is rejected, or one less is accepted/charged; eager output appears before a resource failure. [VERIFIED: codebase inspection — existing exact-one-less testing pattern at `encode_wbtest.mbt:175`]

### Pitfall 4: Incorrect IHDR method/CRC boundary

**What goes wrong:** The Adam7 byte stream has pass data but IHDR remains method 0, or a legacy route flips to method 1. [CITED: `42-CONTEXT.md`]

**Why it happens:** `byte_at` currently hardcodes the final IHDR method byte to zero while CRC is computed as acknowledged bytes pass through. [VERIFIED: codebase inspection — `stream_encode.mbt:804`, `stream_encode.mbt:856`]

**How to avoid:** Choose byte 12 of IHDR from `interlace_strategy` at emission; do not special-case CRC because the existing acknowledgement loop will cover the new payload byte. [VERIFIED: codebase inspection — `stream_encode.mbt:856`]

**Warning signs:** IHDR byte at absolute offset 28 is not `1` for Adam7, or `moon test` shows legacy byte baselines changing. [VERIFIED: codebase inspection — IHDR layout at `stream_encode.mbt:804`; `encode_test.mbt:526`]

## Code Examples

Verified patterns from the current codebase:

### Adam7 sample coordinate mapping

```moonbit
// The decoder's existing pass-local mapping is the encoder's required source order.
for column = 0UL; column < pass.width; column = column + 1UL {
  let x = pass.x + column * pass.dx
  let y = pass.y + row * pass.dy
  // Encode channels at (x, y) in channel order.
}
```

Source: [VERIFIED: codebase inspection — `modules/mb-image/png/raster_decode.mbt:444`]

### Acknowledgement-safe successor commit

```moonbit
// Preserve this contract when the successor contains Adam7 cursor state.
let byte = machine.present().unwrap().unwrap()
destination.set(written, byte).unwrap()
machine.acknowledge(byte).unwrap()
```

Source: [VERIFIED: codebase inspection — `modules/mb-image/png/stream_encode.mbt:112`]

### Exact nonempty-pass total

```moonbit
let mut scanlines = 0UL
for pass in passes {
  if pass.width > 0UL && pass.height > 0UL {
    let per_row = @checked.checked_add(pass.row_bytes, 1UL)?
    scanlines = @checked.checked_add(scanlines, @checked.checked_mul(per_row, pass.height)?)?
  }
}
```

Source: [VERIFIED: codebase inspection — `modules/mb-image/png/structural.mbt:621`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 41 typed `png-adam7-pending` rejection | Phase 42 real pass traversal through the existing bounded planner/replay model | This phase | Replace only the compatible Adam7 boundary; non-interlaced bytes and factories remain frozen. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode.mbt:1174`] |
| Full-image row filter cursor | Pass-local logical filtered byte source | This phase | Ensures each pass starts with fresh filter history while still requiring no pass buffer. [CITED: `42-CONTEXT.md`] |

**Deprecated/outdated:**

- `PngInterlaceStrategy::Adam7 => Err(..."png-adam7-pending")`: remove the pending branch in favor of the pass-aware preflight route; retain unsupported-image capability rejection from `_png_encode_source`. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode.mbt:1174`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A deliberately constructed multi-pass adaptive test can expose cross-pass first-row predictor leakage through differing filter tags. | Common Pitfalls | The test may be weak; retain direct logical-byte assertions in `encode_wbtest.mbt` instead of relying only on tag differences. |

## Open Questions (RESOLVED)

1. **Which private layout type yields the smallest safe MoonBit refactor?**
   - **Resolution:** use one private pass-aware raster source/layout passed to filtered and match-cursor constructors. It carries only checked geometry references plus scalar traversal state, making the shared Stored/Fixed/Dynamic producer explicit without a staging buffer.

2. **What is the smallest public-evidence boundary for Phase 42?**
   - **Resolution:** retain targeted native regression coverage for pass order, atomic preflight, IHDR interlace, and eager/chunk replay parity. Generated fidelity cases and independent js/wasm/wasm-gc/native public evidence remain exclusively Phase 43.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| MoonBit `moon` CLI | Compile and run targeted PNG tests | ✓ | `0.1.20260713 (75c7e1f 2026-07-13)` | — [VERIFIED: local `moon version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment probe]

**Missing dependencies with fallback:** None. [VERIFIED: local environment probe]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Offline pure-library encoding has no authentication boundary. [VERIFIED: codebase inspection] |
| V3 Session Management | no | Offline pure-library encoding has no session state. [VERIFIED: codebase inspection] |
| V4 Access Control | no | No user/resource authorization operation is introduced. [VERIFIED: codebase inspection] |
| V5 Input Validation | yes | Retain `_png_encode_source`, checked dimensions, checked pass totals, output/work limits, and atomic `Budget` charge before output. [VERIFIED: codebase inspection — `encode.mbt:42`, `encode.mbt:1183`, `structural.mbt:588`] |
| V6 Cryptography | no | PNG framing/checksums are integrity format operations, not cryptographic controls. [VERIFIED: codebase inspection — `stream_encode.mbt:856`] |

### Known Threat Patterns for MoonBit PNG encoding

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Arithmetic overflow in pass total, stored block count, or output/work ledger | Denial of service | Use `@checked` for all new aggregate calculations and reject before budget charge/output. [VERIFIED: codebase inspection — `structural.mbt:588`, `encode.mbt:1183`] |
| Resource exhaustion from malformed/incompatible oversized source geometry | Denial of service | Preserve width, height, pixel, output, work, and budget admission before eager writer output or chunk encoder construction. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode.mbt:1341`] |
| State desynchronization under tiny caller leases | Tampering / Denial of service | Keep preview successor private and commit it only from `acknowledge` after a destination write. [VERIFIED: codebase inspection — `stream_encode.mbt:112`, `stream_encode.mbt:856`] |

## Validation Strategy

`workflow.nyquist_validation` is explicitly `false` in `.planning/config.json`; the required Nyquist Validation Architecture section is therefore omitted. The following focused checks are still required for this phase. [VERIFIED: `.planning/config.json`]

### Minimum targeted tests

1. **Private geometry/byte-source tests — `encode_wbtest.mbt`:** Build a small nontrivial RGB8 and RGBA8 image (for example 5×5, so every Adam7 pass has meaningful geometry), construct the Adam7 layout from `_png_adam7_passes`, and assert exact pass-order source/filter bytes. Include empty-pass images such as 1×1 to prove they emit no extra tag. [VERIFIED: codebase inspection — canonical 5×5 pass facts at `structural_wbtest.mbt:403`]
2. **Private filter reset/ledger tests — `encode_wbtest.mbt`:** Assert Adaptive first rows use no `Up`/`Paeth` predecessor from the prior pass, then parameterize exact-work and one-less-work rejection across `Stored`, `FixedOrStored`, and `DynamicOrFixedOrStored`. Reuse `PngFilteredTraversalFacts` rather than duplicating traversal-count formulas. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode_wbtest.mbt:152`]
3. **Eager boundary test — `encode_test.mbt`:** Replace the Phase 41 pending-rejection expectations for compatible RGB8/RGBA8 with successful Adam7 output checks: IHDR byte 28 is `1`, basic framing completes, and all legacy/explicit-None baseline assertions remain unchanged. Do not add the generated four-target corpus here. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `encode_test.mbt:526`, `stream_encode.mbt:804`]
4. **Caller-buffered parity and atomicity — `stream_encode_test.mbt`:** Replace the pending-rejection portion with Adam7 `new_with_interlace_strategy` and `new_with_all_strategies` drains over `[0, 1, 3, 2, 5]` (and a one-byte schedule). Assert exact eager/chunk identity, precise `written`/`total_written`, terminal idempotence, and no state advance before acceptance. Reuse `png_chunk_test_drain_hostile...` after extending it to accept an interlace strategy. [VERIFIED: codebase inspection — `stream_encode_test.mbt:957`, `stream_encode.mbt:112`]
5. **Admission parity — `encode_wbtest.mbt` and/or `stream_encode_test.mbt`:** For Adam7, set each capability/geometry/output/work/budget limit just below/at the observed need. Both eager and caller-buffered creation must fail before writer position or lease acceptance, with unchanged remaining budget on failure. Exercise every compression strategy. [CITED: `42-CONTEXT.md`; VERIFIED: codebase inspection — `stream_encode_test.mbt:1108`]

### Verification commands

```powershell
Set-Location D:\source\moonbit-foundation-phase42
moon test modules/mb-image/png --target native
moon test modules/mb-image/png --target js
moon test modules/mb-image/png --target wasm
moon test modules/mb-image/png --target wasm-gc
git diff --check
git status --short
```

Run the native command while implementing each plan slice; the portable target matrix is a safe regression check, but Phase 43 owns independent generated public Adam7 evidence. [CITED: `42-CONTEXT.md`; VERIFIED: `modules/mb-image/png/moon.pkg`]

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/structural.mbt:565-603` — checked seven-pass representation and `_png_adam7_passes`. [VERIFIED: codebase inspection]
- `modules/mb-image/png/raster_decode.mbt:303-390, 444-446` — existing empty-pass handling, exact nonempty-pass byte total, and pass-local coordinate mapping. [VERIFIED: codebase inspection]
- `modules/mb-image/png/encode.mbt:470-841, 959-1369` — filtered cursor/match window, Stored/Fixed/Dynamic planner traversals, and atomic ledger. [VERIFIED: codebase inspection]
- `modules/mb-image/png/stream_encode.mbt:197-396, 403-907` — construction, direct/cursor replay, IHDR framing, and acknowledgement commit semantics. [VERIFIED: codebase inspection]
- `modules/mb-image/png/*encode*_test.mbt` — Phase 41 pending tests and existing hostile/admission test helpers. [VERIFIED: codebase inspection]

### Secondary (MEDIUM confidence)

- `.planning/phases/42-bounded-adam7-pass-encoding/42-CONTEXT.md` — locked implementation boundary and exclusions. [CITED: `42-CONTEXT.md`]
- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` — PNGI-02/PNGI-03 and Phase 42 success criteria. [CITED: `REQUIREMENTS.md`; `ROADMAP.md`]
- `AGENTS.md` — MoonBit-native, bounded, deterministic, modular, and test placement constraints. [CITED: AGENTS.md]

### Tertiary (LOW confidence)

- No external web/package findings were used. [VERIFIED: research scope]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — this phase installs no packages and uses the locally verified MoonBit workspace/toolchain. [VERIFIED: local `moon version`]
- Architecture: HIGH — all recommended seams are directly traced in the current encoder, decoder, and streaming machine. [VERIFIED: codebase inspection]
- Pitfalls: HIGH — the relevant assumptions (full-image predecessor, direct nonadaptive replay, exact ledger) are observable in current source; the test-vector sensitivity note A1 is explicitly low-confidence. [VERIFIED: codebase inspection; ASSUMED: A1]

**Research date:** 2026-07-22
**Valid until:** 2026-08-21 (stable, codebase-scoped research)
