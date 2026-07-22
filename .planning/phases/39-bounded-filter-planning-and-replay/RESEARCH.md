# Phase 39: Bounded Filter Planning and Replay - Research

**Researched:** 2026-07-22
**Domain:** Portable MoonBit PNG method-0 row filtering, bounded compression planning, and acknowledgement-safe replay
**Confidence:** HIGH

## User Constraints

- Implement PNGF-02 and PNGF-03 only: deterministic standard row-filter selection and integration before Stored, FixedOrStored, and Dynamic compression planning. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]
- Preserve every legacy/default `PngFilterStrategy::None` constructor and configured compression route byte-for-byte. Only the explicit Adaptive opt-in may change output. [VERIFIED: Phase 38 verification; `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}`]
- Add the missing eager and caller-buffered way to combine Adaptive with each compression strategy; Phase 38 deliberately exposed only independent factories and deferred this public combination to Phase 39. [VERIFIED: `.planning/phases/38-adaptive-filter-compatibility/{RESEARCH.md,38-01-PLAN.md,38-01-SUMMARY.md}`]
- Keep the established atomic admission contract: capability, geometry, output, work, and budget failure must occur before eager output or a caller lease is exposed. [VERIFIED: PNGF-03; `modules/mb-image/png/{encode.mbt,stream_encode.mbt,stream_encode_test.mbt}`]
- Do not stage a full image, filtered scanline image, compressed output, token stream, or caller lease. Use deterministic replay with fixed-size state only. [VERIFIED: PNGF-03; dynamic-plan architecture in `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]
- Prioritize implementation and tests; exclude release, registry, CI, QOI, FFI, and unrelated-worktree work. [VERIFIED: user direction]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PNGF-02 | An opted-in compatible RGB8 or straight-RGBA8 image uses deterministic, bounded None/Sub/Up/Average/Paeth candidates and a documented stable winner rule. | Use the five method-0 formulas, candidate order `None, Sub, Up, Average, Paeth`, signed-residual absolute-sum scoring, and strict-`<` replacement so the earlier candidate wins ties. [CITED: https://www.w3.org/TR/png-3/; VERIFIED: existing RGB8/RGBA8 capability boundary in `modules/mb-image/png/encode.mbt`; ASSUMED: recommended stable tie rule] |
| PNGF-03 | Filter selection happens before Stored, FixedOrStored, and Dynamic planning without image-sized staging; all admission failure remains atomic for eager and caller-buffered adapters. | Replace the filter-None byte supplier at the shared preflight/replay boundary, compute an exact deterministic work ledger before output visibility, and retain only scalar/fixed-bound replay state. [VERIFIED: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

## Summary

Phase 38 supplies the correct seam but deliberately normalizes `Adaptive` to `None` before `_png_encode_preflight`. The shared `PngEncodeMachine` is the only encoder engine: eager output acknowledges one byte after `Writer.write` reports exactly one byte, while caller-buffered output advances only after an accepted caller lease. `_png_encode_preflight` selects Stored/Fixed/Dynamic, checks every limit, and charges the budget before either adapter can expose output. [VERIFIED: Phase 38 verification; `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

Phase 39 must make that seam real for only the explicit Adaptive route. Method 0 has exactly five filter types and allows an encoder to choose one per scanline. The W3C-recommended bounded heuristic is to score all five transformed scanlines by the sum of absolute values when interpreted as signed bytes. Use that heuristic with a fixed candidate order and an earlier-wins-ties rule; this makes selection reproducible across planning and replay. [CITED: https://www.w3.org/TR/png-3/; ASSUMED: recommended tie rule]

**Primary recommendation:** Introduce a public combined-strategy factory on both adapters, retain legacy `None` routes unchanged, and refactor compression planning/replay around one forward-only filtered-byte cursor that recomputes each Adaptive row winner deterministically using only fixed-size state. Charge the exact plan-plus-replay filter work before construction succeeds. [VERIFIED: Phase 38 private combined-construction boundary; [ASSUMED] exact helper decomposition]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Adaptive public configuration | API / Backend | — | The portable `tchivs/mb-image/png` package owns the public encoder factories; no host or FFI layer participates. [VERIFIED: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`] |
| Row filter select/transform | API / Backend | — | Filtering is the byte stream immediately before DEFLATE and must use source pixels plus the prior raw scanline. [CITED: https://www.w3.org/TR/png-3/; VERIFIED: current scanline supplier in `modules/mb-image/png/stream_encode.mbt`] |
| Compression winner planning | API / Backend | — | `_png_encode_preflight` is already the sole owner of Stored/Fixed/Dynamic candidate selection, limits, and budget admission. [VERIFIED: `modules/mb-image/png/encode.mbt`] |
| Eager emission | API / Backend | — | `PngEncoder` must continue to acknowledge only a successful one-byte writer operation. [VERIFIED: `modules/mb-image/png/encode.mbt`] |
| Caller-buffered emission | API / Backend | — | `PngChunkEncoder::pull` owns caller leases, exact progress, and sticky terminal outcomes. [VERIFIED: `modules/mb-image/png/stream_encode.mbt`] |

## Project Constraints (from AGENTS.md)

- Prefer the codebase-memory graph for code discovery; its graph MCP tools were not available in this research runtime, so repository text inspection was limited to the relevant planning and PNG files. [VERIFIED: `AGENTS.md`; runtime tool inventory]
- Keep core algorithms and shared models in MoonBit; native is primary but portable targets are deliberate and require conformance evidence. [VERIFIED: `AGENTS.md`]
- Keep public package dependencies acyclic, stable API changes additive/explicit, and automation deterministic without GUI state. [VERIFIED: `AGENTS.md`]
- Do not add FFI unless a small, isolated, documented, replaceable native adapter is necessary; no FFI is in this phase. [VERIFIED: `AGENTS.md`; phase scope]
- Public packages require black-box `*_test.mbt`; `*_wbtest.mbt` covers internal arithmetic and representation invariants. Binary expectations should use deterministic bytes/digests plus semantic checks, not opaque snapshots. [VERIFIED: `AGENTS.md`]
- `workflow.nyquist_validation` is explicitly disabled, so this research does not create a Nyquist validation architecture. [VERIFIED: `.planning/config.json`]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing `tchivs/mb-image/png` MoonBit package | workspace source | Public API, source validation, preflight, DEFLATE planning, PNG framing, and replay | It already owns all required behavior and has no external dependency boundary to cross. [VERIFIED: `modules/mb-image/png/{moon.pkg,png.mbt,encode.mbt,stream_encode.mbt}`] |
| MoonBit toolchain | `moon 0.1.20260713`; `moonc v0.10.4+2cc641edf`; `moonrun 0.1.20260713` | Compile and test each portable target | Installed local toolchain and project stack baseline. [VERIFIED: local version commands; `AGENTS.md`] |
| W3C PNG Third Edition method 0 | Recommendation, 2025-06-24 | Normative row-filter formulas and permitted types | It specifies exact filter arithmetic, edge semantics, and the adaptive score heuristic used here. [CITED: https://www.w3.org/TR/png-3/] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| Existing `@checked` and `@budget` package APIs | workspace source | Checked arithmetic plus pre-output resource admission | Use for every scanline/work/output calculation; do not introduce a second accounting model. [VERIFIED: `modules/mb-image/png/{encode.mbt,moon.pkg}`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Per-row adaptive heuristic | Exhaustive combinations of row filters | The PNG specification notes exhaustive search can improve compression, but it is not bounded for this phase and cannot fit the deterministic resource contract. [CITED: https://www.w3.org/TR/png-3/] |
| Recomputed fixed-state replay | Full filtered-image or row-winner staging | Staging makes output easy to emit but violates the phase's no-image-sized-staging constraint and weakens replay ownership. [VERIFIED: PNGF-03; existing dynamic replay design] |
| Existing MoonBit implementation | External PNG/DEFLATE library or FFI | Violates the project’s MoonBit-native and small-FFI constraints while bypassing the established atomic encoder contract. [VERIFIED: `AGENTS.md`; `modules/mb-image/png/moon.pkg`] |

**Installation:** No external package, service, or FFI is needed or permitted. [VERIFIED: phase scope; `modules/mb-image/png/moon.pkg`]

## Architecture Patterns

### System Architecture Diagram

```text
legacy constructors / existing compression factories
  -> (requested compression, PngFilterStrategy::None)
  -> existing filter-None provider -> existing plan/replay -> frozen bytes

new combined eager/chunk factory
  -> (Stored|FixedOrStored|DynamicOrFixedOrStored, Adaptive)
  -> source validation
  -> forward-only row resolver
       -> score None/Sub/Up/Average/Paeth in fixed order
       -> select minimum signed-absolute-residual score; first candidate wins ties
       -> expose selected filter byte and transformed payload bytes
  -> _png_encode_preflight
       -> Stored or FixedOrStored or strict Dynamic complete-PNG winner
       -> output/work limits + one budget charge
  -> same resolver replayed through PngEncodeMachine
       -> eager Writer acknowledgement OR caller lease acknowledgement
       -> CRC/Adler, exact progress, sticky terminal behavior
```

The filter resolver must be upstream of every DEFLATE candidate because filtering changes the bytes, DEFLATE symbols, Adler-32, CRC-covered IDAT, selected output length, and work ledger. [CITED: https://www.w3.org/TR/png-3/; VERIFIED: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # additive combined eager factory and public docs
├── encode.mbt              # filter-aware preflight, exact work ledger, plan selection
├── stream_encode.mbt       # fixed-memory filtered cursor plus acknowledgement-safe replay
├── encode_test.mbt         # public eager compatibility/adaptive behavior
├── stream_encode_test.mbt  # public hostile-capacity and atomic-admission behavior
└── encode_wbtest.mbt       # filter formula, signed score, tie, and ledger invariants

policy/foundation.json      # generated semantic-interface addition for public factories
```

### Pattern 1: Additive combined configuration with frozen defaults

**What:** Publish exactly `PngEncoder::new_with_strategies(compression_strategy, filter_strategy)` and `PngChunkEncoder::new_with_strategies(source, compression_strategy, filter_strategy, limits, budget, diagnostics)`. Keep the presently private constructor private under a different implementation name if MoonBit visibility prevents promotion. [RESOLVED: public identifier; VERIFIED: the need for a combined configured route by PNGF-03 and the Phase 38 deferral]

**When to use:** Only when callers need Adaptive plus FixedOrStored or DynamicOrFixedOrStored. Existing `new()`, `new_with_compression_strategy`, and `new_with_filter_strategy` remain source-compatible and keep their Phase-38 meanings: legacy/compression routes use `None`; filter-only Adaptive keeps Stored. [VERIFIED: Phase 38 public factory behavior in `modules/mb-image/png/{png.mbt,stream_encode.mbt}`]

### Pattern 2: Exact method-0 filter resolver

**What:** For RGB8 use bytes-per-pixel `3`; for straight RGBA8 use `4`. For each raw byte `x`, read original `a` (same-row byte `bpp` positions left), `b` (previous raw row), and `c` (upper-left raw row); absent left or prior-row values are zero. Emit the type byte, then `x - predictor (mod 256)`. [CITED: https://www.w3.org/TR/png-3/; VERIFIED: current package supports only RGB8/straight RGBA8]

```moonbit
// Recommended deterministic tie rule: earlier candidate wins by using strict `<`.
let candidates = [None, Sub, Up, Average, Paeth]
let mut winner = None
let mut best = UInt64::maximum()
for candidate in candidates {
  let score = signed_absolute_residual_sum(candidate, raw_row, prior_raw_row, bpp)
  if score < best { // strict only: ties retain the earlier candidate
    winner = candidate
    best = score
  }
}
```

`Average` must add `a + b` without byte overflow before division; Paeth must use exact non-overflowing intermediate arithmetic and the prescribed `pa`, then `pb`, then `pc` comparison order. Map an emitted residual byte `0..255` to signed magnitude `0..127, -128..-1` before scoring, so `128` contributes `128`. [CITED: https://www.w3.org/TR/png-3/; [ASSUMED] exact MoonBit helper names]

### Pattern 3: Forward-only bounded plan and replay

**What:** Replace direct `_png_fixed_scanline_byte(...)` access in the Fixed/Dynamic planning and replay paths with a shared filtered-byte cursor. The cursor may retain scalar positions, a constant-size DEFLATE look-ahead/history window bounded by the current matcher’s maximum length/distance, and pending preview state; it must not retain a pixel-sized buffer or `height`-length table of selected filters. [VERIFIED: matcher bounds `length <= 258`, `distance <= 4` in `modules/mb-image/png/encode.mbt`; [ASSUMED] cursor refactor]

**When to use:** For Adaptive planning and replay. `None` should preserve the existing byte provider and exact wire behavior rather than being routed through a new transformation implementation. [VERIFIED: Phase 38 frozen compatibility contract; `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

### Pattern 4: Preflight ledger includes filter planning and replay

**What:** Compute the exact work before the successful machine is returned. For Adaptive, let `row_bytes = checked(width * channels)` and charge exactly `checked(2 * height * (5 * row_bytes))` score units: one five-candidate residual-and-signed-magnitude traversal per source byte in preflight and one identical traversal in replay. Add this to the current selected-output work and, for Fixed/Dynamic, both existing matcher walks. Keep current `None` ledger arithmetic byte-compatible and semantically unchanged. [VERIFIED: current selected-work formula and one-time charge in `modules/mb-image/png/encode.mbt`; RESOLVED: exact Adaptive ledger units]

**Required invariant:** If the exact `work` limit or budget is one unit too small, eager construction/encode writes zero bytes, chunk construction returns the same error before any lease is touched, and every resource counter is unchanged. [VERIFIED: existing public one-less Dynamic admission test in `modules/mb-image/png/stream_encode_test.mbt`]

### Anti-Patterns to Avoid

- **A filter decision `Array` indexed by image row:** it is image-proportional staging and can disagree with replay after source mutation. Recompute from source through bounded state. [VERIFIED: PNGF-03; existing dynamic plan explicitly avoids image-sized token/output state]
- **Computing a winner in preflight but reusing None during DEFLATE replay:** planned lengths/frequencies/fingerprint no longer describe emitted bytes, producing checksum or replay drift. [VERIFIED: existing Fixed/Dynamic plans are derived from `_png_fixed_scanline_byte` in `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]
- **Using `<=` when updating the score winner:** changes equal-score output based on incidental implementation order. Use fixed candidate iteration and strict `<`. [ASSUMED: stable-winner implementation rule]
- **Treating filtered residuals as unsigned for the heuristic:** W3C specifies the absolute-value heuristic over signed differences. [CITED: https://www.w3.org/TR/png-3/]
- **Changing the legacy `None` provider or compression tie rules:** this breaks Phase-38 immutable byte vectors. Fixed still wins ties against Stored; Dynamic still replaces its baseline only on a strict complete-PNG win. [VERIFIED: `modules/mb-image/png/encode.mbt`; Phase 38 verification]
- **Committing preview state before `Writer.write`/lease acknowledgement:** violates repeated-`present` observation and accepted-prefix ownership. [VERIFIED: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| PNG filter definitions | Ad-hoc gradient or pixel-based predictors | The exact W3C method-0 byte formulas | Predictor edge cases, Average width, Paeth ordering, and modulo arithmetic are format requirements. [CITED: https://www.w3.org/TR/png-3/] |
| A second adaptive encoder | Separate eager/chunk filtered-output path | The existing `PngEncodeMachine` and acknowledgement lifecycle | It already preserves CRC/Adler, writer behavior, leases, exact progress, and sticky terminals. [VERIFIED: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |
| Compression-size estimator | Approximate post-filter length estimate | Existing exact Stored/Fixed/Dynamic plan selection over filtered bytes | Output limits and budget admission must use the actual selected plan. [VERIFIED: `modules/mb-image/png/encode.mbt`] |
| Image-sized filter cache | Full transformed scanlines or a row winner vector | Recomputed bounded forward cursor | The phase requires planning/replay without image-sized staging. [VERIFIED: PNGF-03] |

**Key insight:** Adaptive filtering is not a final-output decoration. It is the logical source stream for every compressor, checksum, work calculation, and replay state transition; therefore filtering must become one shared deterministic byte source before preflight rather than a branch in eager or chunk output. [CITED: https://www.w3.org/TR/png-3/; VERIFIED: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

## Common Pitfalls

### Pitfall 1: Incorrect edge predictors

**What goes wrong:** Sub/Average/Paeth read a byte one position left rather than one pixel (`channels`) left, or Up/Paeth use the current filtered row rather than the original previous raw row. [CITED: https://www.w3.org/TR/png-3/]

**How to avoid:** Use `bpp = channels`, original source samples for `a`, `b`, and `c`, and zero for left/prior values that do not exist. Add white-box 1-row and 2-row RGB8/RGBA8 vectors that isolate left edge, first row, and upper-left behavior. [CITED: https://www.w3.org/TR/png-3/; [ASSUMED] test-vector layout]

### Pitfall 2: Stable scorer is not actually stable

**What goes wrong:** Overflow in the signed-absolute accumulation, wrong `0x80` magnitude, or non-deterministic tie replacement changes the selected filter across targets. [CITED: https://www.w3.org/TR/png-3/; [ASSUMED] target-risk analysis]

**How to avoid:** Use checked `UInt64` accumulation, map `0x80` to magnitude `128`, enumerate fixed candidates once, and replace the winner only for a strictly lower score. Verify an all-zero row chooses None and constructed ties choose the first candidate. [ASSUMED: concrete tie fixtures]

### Pitfall 3: Preflight plans different bytes than replay

**What goes wrong:** Dynamic frequencies/fingerprint or Fixed matcher work are calculated from filtered bytes, but replay still calls `_png_fixed_scanline_byte`; output may fail after partial output or silently emit the wrong checksums. [VERIFIED: planner and replay have distinct `_png_fixed_scanline_byte` call sites in `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

**How to avoid:** Replace every relevant planner and replay byte call as one atomic refactor, with a shared `None`/Adaptive resolver contract. Preserve existing Dynamic fingerprint/work replay drift checks and extend the filtered replay facts as needed. [VERIFIED: `modules/mb-image/png/stream_encode.mbt`; [ASSUMED] exact fact fields]

### Pitfall 4: Correct output but non-atomic failure

**What goes wrong:** Adaptive scoring or its work charge happens lazily after eager output or a chunk lease was issued. [VERIFIED: PNGF-03]

**How to avoid:** Finish filter-aware compression selection, output-limit checking, work-limit checking, and the one budget charge inside `_png_encode_preflight` before returning a machine. Test exact and one-less output/work/budget conditions through both public adapters. [VERIFIED: existing preflight shape and one-less Dynamic test in `modules/mb-image/png/{encode.mbt,stream_encode_test.mbt}`]

### Pitfall 5: Losing Phase-38 API semantics

**What goes wrong:** `new_with_filter_strategy(Adaptive)` unexpectedly starts using Fixed/Dynamic, or a legacy/default route becomes Adaptive. [VERIFIED: Phase 38 factories in `modules/mb-image/png/{png.mbt,stream_encode.mbt}`]

**How to avoid:** Preserve filter-only Adaptive as Stored + Adaptive; use the new combined factory for Adaptive plus configured compression. Retain and run immutable full-PNG vectors for every legacy/compression `None` route. [VERIFIED: Phase 38 verification; [ASSUMED] combined-factory semantics]

## Code Examples

### Exact residual and score helpers

```moonbit
fn png_filter_residual(original : Byte, predictor : Byte) -> Byte {
  // UInt8 subtraction implements PNG's modulo-256 filtered value.
  original - predictor
}

fn png_signed_abs(residual : Byte) -> UInt64 {
  let value = residual.to_uint64()
  if value <= 127UL { value } else { 256UL - value }
}
```

The production implementation must use checked accumulation around this helper and exact W3C Average/Paeth predictors rather than relying on language overflow behavior for intermediates. [CITED: https://www.w3.org/TR/png-3/]

### Public adapter matrix to protect

| Caller route | Compression | Filter | Required result |
|---|---|---|---|
| `PngEncoder::new()` / `PngChunkEncoder::new(...)` | Stored | None | Existing immutable bytes unchanged. [VERIFIED: Phase 38 verification] |
| Existing `new_with_compression_strategy` | caller-selected | None | Existing Stored, FixedOrStored, and Dynamic bytes/rules unchanged. [VERIFIED: Phase 38 verification] |
| Existing `new_with_filter_strategy(Adaptive)` | Stored | Adaptive | Now selects filters, but remains Stored; no implicit configured compression. [ASSUMED: recommended continuity semantics] |
| New combined eager/chunk factory | caller-selected | Adaptive | Required route for Stored, FixedOrStored, and DynamicOrFixedOrStored planning. [VERIFIED: PNGF-03; [ASSUMED] exact API name] |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Filter-None-only byte provider | Phase 38 explicit Adaptive compatibility seam, still normalized to None | Phase 38 | The public opt-in exists, but only Phase 39 can change its byte source. [VERIFIED: Phase 38 summary/verification; `modules/mb-image/png/stream_encode.mbt`] |
| Stored then bounded Fixed/Dynamic complete-PNG selection | Same compressor choices, now fed by Adaptive-selected filtered bytes for the explicit combined route | Phase 39 recommendation | Compression selection remains exact; only its logical uncompressed input changes. [VERIFIED: existing compression selection in `modules/mb-image/png/encode.mbt`; [ASSUMED] implementation recommendation] |

**Deprecated/outdated:** Treating `PngFilterStrategy::Adaptive` as a filter-None shim is Phase-38-only behavior. Phase 39 must make it actual method-0 selection while preserving the `None` compatibility route. [VERIFIED: Phase 38 plan and summary; `.planning/ROADMAP.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | **RESOLVED:** The additive public combined factories are named `new_with_strategies`. | Summary; Pattern 1; Resolved Planning Decisions | None — this phase publishes exactly that eager/chunk factory pair. |
| A2 | A forward-only cursor with a constant-size DEFLATE history/look-ahead window is the cleanest no-staging refactor. | Summary; Pattern 3 | Existing matcher interfaces may require a different fixed-memory abstraction. |
| A3 | **RESOLVED:** Adaptive score work is exactly `2 * height * (5 * row_bytes)` checked units: five candidate residual-and-signed-magnitude visits for every source byte, once in preflight and once in replay. | Pattern 4; Resolved Planning Decisions | None — checked multiplication/addition, exact/one-less white-box facts, and public atomic admission lock the ledger. |
| A4 | **RESOLVED:** Filter-only Adaptive continues to mean Stored + Adaptive while the new combined route enables other compression strategies. | User Constraints; Adapter Matrix | None — Phase 38 compatibility contract remains additive. |
| A5 | Full portable behavioral proof remains Phase 40, while Phase 39 should run focused native tests during TDD plus a final all-target regression. | Common Pitfalls; Environment | Planner could choose stronger per-task four-target runs at higher execution cost. |

## Resolved Planning Decisions

1. **Public combined factory spelling — RESOLVED**
   - Publish exactly `PngEncoder::new_with_strategies(compression_strategy, filter_strategy)` and `PngChunkEncoder::new_with_strategies(source, compression_strategy, filter_strategy, limits, budget, diagnostics)`.
   - The existing private combined chunk constructor may be renamed as needed to make this one eager/chunk naming pair public; no alternate public spelling is added. The semantic interface registers only these two additions.

2. **Exact Adaptive work unit ledger — RESOLVED**
   - Let `row_bytes = checked(width * channels)`, where channels is 3 for RGB8 or 4 for straight-RGBA8. A candidate-score visit is one source-byte operation that computes that candidate's predictor/residual and contributes its signed absolute magnitude.
   - `candidate_score_work_per_row = checked(5 * row_bytes)` because every row scores exactly None, Sub, Up, Average, and Paeth. `adaptive_filter_work = checked(checked(height * candidate_score_work_per_row) + checked(height * candidate_score_work_per_row))`, which is exactly `checked(2 * height * 5 * row_bytes)` units: one complete scoring traversal in preflight and one complete scoring traversal in replay.
   - The emitted filter-type bytes do not create a separate filter-score unit. Existing `total_length` remains the selected-output work already charged by the encoder, and Fixed/Dynamic retain their existing two matcher walks. Therefore the final checked ledger is Stored `total_length + adaptive_filter_work`; Fixed/Dynamic `total_length + matcher_work + matcher_work + adaptive_filter_work`.
   - Compute every multiplication and addition through the encoder's checked arithmetic/error path before limits and the one budget charge. White-box tests derive exact and one-less limits from these returned facts; public tests confirm rejected eager/chunk admission leaves no output or lease and no budget mutation.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Package tests on all declared targets | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` | MoonBit compilation | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local `moonc -v`] |
| `moonrun` | MoonBit test execution | ✓ | `0.1.20260713` | — [VERIFIED: local `moonrun --version`] |
| External packages/services | This phase | Not required | — | No install or service dependency. [VERIFIED: phase scope; `modules/mb-image/png/moon.pkg`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local toolchain check]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | No authentication surface. [VERIFIED: package-local encoder scope] |
| V3 Session Management | No | No session surface. [VERIFIED: package-local encoder scope] |
| V4 Access Control | No | No authority or tenant boundary. [VERIFIED: package-local encoder scope] |
| V5 Input Validation | Yes | Reuse source-profile validation plus filter-aware checked geometry/output/work/budget preflight. [VERIFIED: `modules/mb-image/png/encode.mbt`; PNGF-03] |
| V6 Cryptography | No | CRC-32 and Adler-32 are format integrity checks, not cryptographic controls. [VERIFIED: `modules/mb-image/png/stream_encode.mbt`] |

### Known Threat Patterns for the PNG Encoder

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Crafted dimensions amplify adaptive scoring work | Denial of Service | Checked deterministic work ledger, `max_work`, and one pre-output budget charge. [VERIFIED: PNGF-03; existing preflight budget structure] |
| Planner/replay byte mismatch after source mutation | Tampering | One resolver contract plus filtered replay fingerprint/work facts and existing sticky terminal handling. [VERIFIED: existing Dynamic replay drift handling; [ASSUMED] filtered fact extension] |
| Legacy byte representation changes | Tampering | Explicit `None` defaults and immutable complete-PNG vectors for Stored, FixedOrStored, and Dynamic routes. [VERIFIED: Phase 38 verification] |
| Caller observes bytes before an adaptive admission failure | Denial of Service | Finish all filter-aware planning/limits/budget checks before constructing the shared machine. [VERIFIED: PNGF-03; current construction flow] |

## Validation Architecture

Skipped: `workflow.nyquist_validation` is explicitly `false` in `.planning/config.json`. [VERIFIED: `.planning/config.json`]

## Sources

### Primary (HIGH confidence)

- Current public API, preflight, compression selection, and acknowledgement-safe replay: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}`. [VERIFIED: codebase]
- Existing public exact-byte, hostile-capacity, exact/one-less budget, and replay-drift tests: `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`. [VERIFIED: codebase]
- Phase scope and completed compatibility boundary: `.planning/{ROADMAP.md,REQUIREMENTS.md,STATE.md}` and `.planning/phases/38-adaptive-filter-compatibility/{38-01-PLAN.md,38-01-SUMMARY.md,38-VERIFICATION.md}`. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- [W3C PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — method-0 type set, byte formulas, edge arithmetic, Paeth ordering, and adaptive signed-residual score heuristic. [CITED: https://www.w3.org/TR/png-3/]

### Tertiary (LOW confidence)

- None. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no external dependency; local toolchain and current package inspected. [VERIFIED: local toolchain; codebase]
- Architecture: HIGH — current single-machine/preflight/acknowledgement flow and Phase 38 API contract were traced. [VERIFIED: codebase]
- Filter semantics: MEDIUM — current official W3C recommendation was directly checked; exact MoonBit helper shape remains implementation work. [CITED: https://www.w3.org/TR/png-3/]
- Cursor and work-ledger decomposition: LOW — prescriptive design recommendation to be validated by TDD, exact admission tests, and four-target evidence. [ASSUMED]

**Research date:** 2026-07-22
**Valid until:** Phase 39 planning completion or any change to `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`. [VERIFIED: current worktree inspection]
