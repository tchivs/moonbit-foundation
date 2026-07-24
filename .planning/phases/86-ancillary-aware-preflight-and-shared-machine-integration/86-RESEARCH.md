# Phase 86: Ancillary-Aware Preflight and Shared-Machine Integration - Research

**Researched:** 2026-07-24  
**Domain:** MoonBit Type-3 PNG preflight, bounded DEFLATE selection, and acknowledged output  
**Confidence:** LOW (the configured codebase confidence classifier returns LOW; the local source locations below were directly inspected, and PNG wire semantics were cross-checked against the W3C specification.)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Selected candidate admission
- **D-01:** `PngFrameFacts` remains the sole owner of IHDR, PLTE, canonical
  tRNS, IDAT, and IEND offsets. Build both exact candidate facts before choosing
  Fixed-on-tie or Stored fallback, then retain only the selected frame/output/
  work facts for admission.
- **D-02:** Charge the supplied budget exactly once, only after every selected
  output and work limit check succeeds. All rejection paths leave writer bytes,
  chunk state/lease exposure, and budget unchanged.

### Shared machine integration
- **D-03:** Pass the admitted selected plan/facts through the existing
  `PngEncodeMachine` lifecycle for both eager and caller-buffered APIs. No new
  stream encoder, output buffer, staging container, or separate accounting path
  is permitted.

### Boundary evidence
- **D-04:** Direct tests must prove exact selected output/work limits pass;
  one-less output/work rejects atomically; palette-capacity overflow and
  checked-arithmetic failure also perform no budget charge or observable output.
- **D-05:** Exercise both a Fixed winner and Stored fallback with actual
  palette/transparency facts at each selected non-interlaced Type-3 depth.
  Hostile lease schedules and independent chunk-origin parsing remain Phase 87.

### the agent's Discretion
- Reuse the repository's existing exact-limit, budget-observation, writer-spy,
  and chunk-constructor test helpers rather than inventing a second oracle.

### Deferred Ideas (OUT OF SCOPE)

Dynamic indexed compression, adaptive filters, indexed Adam7 compression,
hostile lease schedules, independent chunk-origin wire parsing, four-target
qualification, release automation, FFI, copied trees, and new public wrappers
remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INDEXCOMP-03 | Before writer progress, caller lease exposure, or budget mutation, selected non-interlaced indexed output computes selected-depth geometry, actual PLTE and shortest canonical tRNS, plus exact Stored/Fixed frame/output/work facts; exact limits charge once, while one-less limits, palette overflow, and checked arithmetic are atomic. | The selected preflight, frame-facts owner, sole machine constructor, and pre-existing atomic test helpers are mapped below. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Use MoonBit for core algorithms and shared models; keep this portable PNG package free of FFI, staging, and foreign-core implementations.
- Preserve the existing `+js+wasm+wasm-gc+native` package boundary; Phase 86 does not add a target-specific dependency. [VERIFIED: modules/mb-image/png/moon.pkg]
- Public behavior belongs in `*_test.mbt`; internal arithmetic and representation assertions belong in `*_wbtest.mbt`. [VERIFIED: AGENTS.md]
- Prefer codebase-memory graph tools for code discovery; its project index returned no matching symbols, so this research used the permitted source-text fallback for MoonBit definitions and string/test discovery. [VERIFIED: codebase-memory-mcp search_graph; VERIFIED: AGENTS.md]
- No direct implementation work, release automation, copied trees, or new public wrappers belongs in this phase.

## Summary

The authoritative admission seam already exists in `_png_encode_indexed_preflight_with_profile_and_strategy` in `encode.mbt`. It derives selected-depth geometry, computes actual palette and canonical shortest transparency facts, evaluates Stored and (for non-interlaced `FixedOrStored`) Fixed frames through `_png_frame_facts`, selects Fixed on a complete-frame tie, checks selected output/work limits, then calls `budget.charge` once. The returned `PngEncodePreflight` contains only the selected plan, frame, total length, and work. [VERIFIED: modules/mb-image/png/encode.mbt:2226-2390]

`PngFrameFacts` is the correct single framing owner: it starts after the signature/IHDR region, adds PLTE and optional tRNS chunk envelopes with checked addition, then locates IDAT, IEND, and total length. The current indexed preflight passes the actual palette byte length and a trailing non-opaque alpha prefix length to this owner for both candidates. This matches PNG indexed-color rules: PLTE is required, while tRNS may omit trailing opaque palette entries. [VERIFIED: modules/mb-image/png/encode.mbt:344-394,2301-2336] [CITED: https://www.w3.org/TR/png-3/]

Both public façades already converge on `PngEncodeMachine::new_with_indexed_profile_and_strategy`; this constructor invokes the same preflight before returning an observable machine. Eager encoding only writes bytes presented by that machine and acknowledges each accepted byte; chunk construction only exposes an active encoder after the same constructor succeeds. [VERIFIED: modules/mb-image/png/encode.mbt:2477-2493,2570-2585; modules/mb-image/png/stream_encode.mbt:36-47,84-96,1024-1077]

**Primary recommendation:** Keep production ownership centered on the existing selected-preflight → `PngEncodePreflight` → `PngEncodeMachine` path; make Phase 86 a focused ancillary-aware exact-limit/atomicity test matrix, with a narrow production correction only if that matrix exposes a fact not retained as selected.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Selected-depth geometry, palette cap, canonical tRNS length, candidate accounting, and limits | API / Backend | — | This is deterministic library admission before any output state exists. [VERIFIED: modules/mb-image/png/encode.mbt:2237-2374] |
| PNG frame offsets and total length | API / Backend | — | `PngFrameFacts` owns PLTE/tRNS/IDAT/IEND offsets and uses checked arithmetic. [VERIFIED: modules/mb-image/png/encode.mbt:344-394] |
| Eager byte presentation and acknowledgement | API / Backend | — | The existing machine presents bytes; the eager facade writes one and then acknowledges it. [VERIFIED: modules/mb-image/png/encode.mbt:2477-2493] |
| Caller-buffered construction and lease-safe progress | API / Backend | — | `PngChunkEncoder` only wraps the same admitted machine. Hostile lease scheduling is deliberately Phase 87. [VERIFIED: modules/mb-image/png/stream_encode.mbt:36-47,84-96] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Existing MoonBit `mb-image/png` package | repository workspace | PNG preflight, encoder machine, and package-local tests | Phase 86 is a code/test integration slice and installs no package. [VERIFIED: modules/mb-image/png/moon.pkg] |
| Existing `mb-core/checked`, `budget`, `codec`, `io`, and `bytes` imports | repository workspace | Checked arithmetic, admission charge, limits, writer, and owned-byte contracts | They are already the package dependencies used at the selected preflight and test seams. [VERIFIED: modules/mb-image/png/moon.pkg; modules/mb-image/png/encode.mbt:344-394,2237-2380] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|
| No new external library | — | Preserve the established implementation and test surface | Always for this phase. [VERIFIED: CONTEXT.md D-03/D-05] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `PngEncodeMachine` | A new indexed streaming/output path | Rejected: it would create a second acknowledgement/accounting path and violate D-03. |
| `PngFrameFacts` candidate totals | Ad-hoc palette offset arithmetic near the Fixed planner | Rejected: it duplicates ancillary-frame ownership and risks comparing IDAT instead of complete-frame sizes. [VERIFIED: modules/mb-image/png/encode.mbt:2309-2343] |

**Installation:** None — no external packages are installed.

## Architecture Patterns

### System Architecture Diagram

```text
PngIndexedImage + selected depth + FixedOrStored
                    |
                    v
  checked geometry / palette cap / shortest tRNS
                    |
                    v
 Stored facts ----> PngFrameFacts <---- Fixed facts
                    |                         |
                    +---- complete-frame <= ---+
                              select plan/frame/work
                                         |
                        selected output/work limits pass?
                          | no                    | yes
                          v                       v
                error; no budget/output     exactly one budget.charge
                                                  |
                                                  v
                             PngEncodeMachine (sole acknowledged state machine)
                                      /                         \
                                   eager writer              chunk constructor
```

The diagram describes the required data-flow boundary, not a proposal for a second encoder. [VERIFIED: modules/mb-image/png/encode.mbt:2226-2390; modules/mb-image/png/stream_encode.mbt:1024-1077]

### Recommended Project Structure

```text
modules/mb-image/png/
├── encode.mbt                 # selected indexed preflight and eager facade
├── stream_encode.mbt          # sole acknowledged machine and chunk facade
├── encode_wbtest.mbt          # exact selected fact/budget tests
├── encode_test.mbt            # eager writer-visible atomicity tests
└── stream_encode_test.mbt     # chunk-constructor atomicity/parity tests
```

### Pattern 1: Select candidates before admission

**What:** Build Stored frame facts first, build Fixed facts from a fresh bounded indexed cursor only for supported non-interlaced `FixedOrStored`, compare complete `PngFrameFacts.total_length`, retain the selected tuple, then limit-check and charge. [VERIFIED: modules/mb-image/png/encode.mbt:2297-2389]

**When to use:** Every explicit non-interlaced indexed `FixedOrStored` request; do not apply it to indexed Adam7 or Dynamic in this phase. [VERIFIED: modules/mb-image/png/encode.mbt:2234-2236,2320-2323]

**Example:**

```moonbit
// Source: modules/mb-image/png/encode.mbt:2309-2389
let (plan, frame, selected_work) = select_complete_frame_candidate(...)
for item in [
  ("output-bytes", frame.total_length, limits.max_output_bytes()),
  ("work", selected_work, limits.max_work()),
] { _png_encode_limit(item) ? }
budget.charge(@budget.ResourceCharge::new(..., work=selected_work)) ?
Ok({ plan, frame, total_length: frame.total_length, selected_work, ... })
```

### Pattern 2: Construct one admitted machine for both façades

**What:** Both eager and chunk selectors call `new_with_indexed_profile_and_strategy`; the constructor preflights once and stores `facts.plan` and `facts.frame`. [VERIFIED: modules/mb-image/png/encode.mbt:2477-2480,2570-2573; modules/mb-image/png/stream_encode.mbt:43-46,92-95,1036-1077]

**When to use:** Keep all Phase 86 integration on this constructor. Do not preflight in a façade and rebuild separate accounting or output state afterward.

### Pattern 3: Test facts privately and observation publicly

**What:** Assert exact selected totals, selected plan, and unchanged `Budget.remaining()` in `encode_wbtest.mbt`; assert zero eager writer bytes and failure to obtain a chunk encoder in public tests. [VERIFIED: modules/mb-image/png/encode_wbtest.mbt:994-1055,1235-1280,1386-1420; modules/mb-image/png/encode_test.mbt:954-966; modules/mb-image/png/stream_encode_test.mbt:5999-6035,6198-6230]

**When to use:** Phase 86 atomic admission only. Retain hostile `pull` schedules, sentinel-tail behavior after actual pulls, and independent wire parsing for Phase 87.

### Anti-Patterns to Avoid

- **Comparing only DEFLATE/IDAT lengths:** selection must compare complete palette-aware frame totals; PLTE and optional tRNS are frame data, not a generic `+57` constant. [VERIFIED: modules/mb-image/png/encode.mbt:2309-2343]
- **Charging candidate work before choosing:** the charged work must belong only to the retained selected candidate. [VERIFIED: modules/mb-image/png/encode.mbt:2316-2389]
- **Facade-specific admission:** eager and chunk constructors must not each create a plan or charge independently. [VERIFIED: modules/mb-image/png/stream_encode.mbt:36-47,84-96,1024-1041]
- **Promoting Phase 87 tests into this phase:** do not add hostile schedules or independent chunk-origin parsing here. [VERIFIED: CONTEXT.md D-05]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ancillary chunk offsets/whole-file totals | A Fixed-only arithmetic formula or frame-size constant | `_png_frame_facts` / `PngFrameFacts` | It centralizes optional PLTE/tRNS envelopes and checked offset additions. [VERIFIED: modules/mb-image/png/encode.mbt:344-394] |
| Budget snapshot comparison | A new selective charge counter | `png_wb_same_remaining`, `png_adam7_same_remaining`, and `Budget.remaining()` | Existing helpers compare every resource dimension, not work alone. [VERIFIED: modules/mb-image/png/encode_wbtest.mbt:994-1006; modules/mb-image/png/stream_encode_test.mbt:6005-6034] |
| Eager output spy | A custom writer | `@io.MemoryWriter` plus `png_encode_prefix` | Existing tests already observe a zero-byte writer after preflight rejection. [VERIFIED: modules/mb-image/png/encode_test.mbt:827-846,954-966] |
| Caller-buffered path | A staging or test-only stream encoder | `PngChunkEncoder::new_indexed*_with_compression_strategy` | It exercises the actual constructor that owns the acknowledged machine. [VERIFIED: modules/mb-image/png/stream_encode.mbt:36-47,84-96] |

**Key insight:** Atomicity is an admission property, not an output replay property. Once selected facts pass and the single charge succeeds, existing acknowledgement logic owns byte/CRC/Adler progression; before then, no machine should exist. [VERIFIED: modules/mb-image/png/encode.mbt:2371-2390; modules/mb-image/png/stream_encode.mbt:1036-1077]

## Exact Source and Test Seams

### Production seam: selected facts and single charge

1. Keep `_png_encode_indexed_preflight_with_profile_and_strategy` as the only place that derives `width`, `height`, `pixels`, `row_bytes`, `scanlines`, palette capacity, canonical `trns_length`, Stored/Fixed candidates, selected work, limits, and charge. [VERIFIED: modules/mb-image/png/encode.mbt:2226-2390]
2. Do not move PLTE/tRNS offsets into the planner or machine: call `_png_frame_facts(source.palette_length(), trns_length, candidate.idat_length)` for both Stored and Fixed, and carry the selected `frame` forward. [VERIFIED: modules/mb-image/png/encode.mbt:2301-2343]
3. Preserve the current order: all `output-bytes` and `work` checks finish before `_png_empty_disposition` and the sole `budget.charge`. [VERIFIED: modules/mb-image/png/encode.mbt:2358-2381]
4. Preserve `PngEncodeMachine::new_with_indexed_profile_and_strategy` as the sole state-construction seam. It must consume the selected `facts.plan`, `facts.frame`, `facts.idat_length`, and `facts.total_length`; actual zlib emission dispatches on `self.plan`, not the requested enum. [VERIFIED: modules/mb-image/png/stream_encode.mbt:1036-1077,1241-1245,1782-1803]

### White-box test seam: selected candidate matrix

Extend the existing `png_indexed_compression_matrix_source`, `png_indexed_compression_matrix_budget`, and `png_indexed_compression_matrix_limits` matrix in `encode_wbtest.mbt`, rather than add a second oracle. It already creates actual palette bytes and a shortest one-byte tRNS, covers profiles One/Two/Four/Eight, and deliberately yields both an all-zero Fixed winner and a literal Stored fallback. [VERIFIED: modules/mb-image/png/encode_wbtest.mbt:1333-1420]

For every `(profile, stored_fallback)` case, use a generous preflight once to obtain the selected public facts, then independently rerun the real preflight with:

- exact `max_output_bytes = facts.total_length`, `max_work = facts.selected_work`, and a budget with exactly `facts.selected_work`; assert success and zero remaining work;
- one-less output (`facts.total_length - 1`) with unchanged budget snapshot; assert `output-bytes` rejection before charge;
- one-less work (`facts.selected_work - 1`) with unchanged budget snapshot; assert `work` rejection before charge;
- selected plan is Fixed for the winner and Stored for the fallback, while `frame.plte_length` is actual palette length and `frame.trns_length` is one. [VERIFIED: modules/mb-image/png/encode_wbtest.mbt:994-1055,1235-1280,1386-1420]

Retain the existing selected-depth palette-capacity loop and route it through the strategy-aware preflight for the Phase 86 matrix. It already constructs a cap+1 palette and proves the `indexed-palette-cap` error without a budget change. [VERIFIED: modules/mb-image/png/encode_wbtest.mbt:1265-1280]

### Public eager test seam: writer-visible atomicity

Use `@io.MemoryWriter`, `png_encode_prefix`, `png_encode_budget`, and `png_adam7_same_remaining` in `encode_test.mbt`. The existing Dynamic rejection test establishes the required observation pattern: take the budget snapshot, call the eager selector, assert error, compare the complete budget, and assert writer-prefix length zero. [VERIFIED: modules/mb-image/png/encode_test.mbt:827-846,954-966]

Add a compact helper parameterized by `(PngIndexedWireProfile/PngIndexedBitDepth, stored_fallback, limit_kind)` only if it calls the production selector and the existing observation helpers. Run it for both actual-ancillary matrix outcomes at all four depths. This proves `FixedOrStored` rejection is invisible to an eager writer, without duplicating frame or compression calculations. [ASSUMED]

### Public chunk test seam: no observable encoder/lease path

Use `PngChunkEncoder::new_indexed8_with_compression_strategy` and `new_indexed_with_compression_strategy` together with `png_stream_test_budget`, `png_stream_test_limits`, and the complete remaining-resource helper. Existing tests already use exactly these constructors for eager-byte parity and reject-at-construction assertions. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt:2-20,4975-5030,5999-6035,6198-6230]

For the same selected candidate cases and one-less output/work limits, assert constructor failure and unchanged budget; do not call `pull`, because a rejected constructor must not return a lease-consuming encoder. A sentinel lease schedule is Phase 87, not Phase 86. [VERIFIED: CONTEXT.md D-02/D-05]

### Checked-arithmetic boundary

`PngIndexedImage::new` checks `width * height` before accepting/copying the source raster, so an overflow cannot become a valid `PngIndexedImage` that reaches preflight. The suitable direct test is therefore constructor-level: pass overflowing geometry, snapshot its construction budget, assert failure and no budget mutation; there can be no eager writer byte or chunk encoder because no valid source was created. Do not weaken source validation or introduce a test-only invalid `PngIndexedImage` merely to drive an unreachable encoder branch. [VERIFIED: modules/mb-image/png/png.mbt:246-333] [ASSUMED]

## Common Pitfalls

### Pitfall 1: Testing a generic frame constant instead of selected ancillary facts

**What goes wrong:** A test may show that Fixed beats Stored using IDAT size or an old constant while failing to prove real PLTE/tRNS accounting.

**Why it happens:** Compression tests tend to focus on zlib bytes; indexed PNG adds palette and optional transparency chunks outside IDAT.

**How to avoid:** Derive both candidate frames with the real source palette length and shortest tRNS prefix, assert selected `frame` fields in every winner/fallback depth case, and use `frame.total_length` for exact output limits. [VERIFIED: modules/mb-image/png/encode.mbt:2301-2343; modules/mb-image/png/encode_wbtest.mbt:1396-1418]

**Warning signs:** Any new test derives expected output from Fixed `idat_length` alone or invokes a generic `+57` framing value. [VERIFIED: modules/mb-image/png/encode.mbt:2309-2343]

### Pitfall 2: Measuring the requested profile instead of the retained profile

**What goes wrong:** A Stored fallback can accidentally be tested with Fixed matcher work or Fixed output limit.

**Why it happens:** The request is `FixedOrStored`, but the accepted plan is one of two candidates.

**How to avoid:** Capture the `PngEncodePreflight` selected tuple and feed its `total_length` and `selected_work` into exact/one-less checks; branch assertions on `facts.plan`. [VERIFIED: modules/mb-image/png/encode.mbt:2316-2389]

**Warning signs:** Work expectations are hard-coded per strategy rather than read from selected facts. [ASSUMED]

### Pitfall 3: Proving only budget atomicity

**What goes wrong:** A rejection could leave the budget unchanged while an eager writer had already accepted data, or a chunk facade had returned state.

**Why it happens:** Preflight correctness and façade observability are separate contracts.

**How to avoid:** Pair white-box snapshot checks with a public zero-byte `MemoryWriter` rejection and a chunk constructor `Err` for the same case. [VERIFIED: modules/mb-image/png/encode_test.mbt:954-966; modules/mb-image/png/stream_encode_test.mbt:5999-6035]

**Warning signs:** A test calls only `_png_encode_indexed_preflight_with_profile_and_strategy` and calls it complete atomicity coverage. [ASSUMED]

## Code Examples

Verified pattern from the existing selected indexed preflight:

```moonbit
// Source: modules/mb-image/png/encode.mbt:2301-2389
let stored_frame = _png_frame_facts(source.palette_length(), trns_length, idat_length) ?
let (plan, frame, selected_work) = match strategy {
  PngCompressionStrategy::FixedOrStored => {
    let fixed = _png_fixed_plan_with_cursor(cursor, scanlines) ?
    let fixed_frame = _png_frame_facts(source.palette_length(), trns_length, fixed.idat_length) ?
    if fixed_frame.total_length <= stored_frame.total_length {
      (PngDeflatePlan::Fixed({ ..fixed, total_length: fixed_frame.total_length }), fixed_frame, ...)
    } else {
      (PngDeflatePlan::Stored(stored), stored_frame, stored_frame.total_length)
    }
  }
  PngCompressionStrategy::Stored => (...)
  PngCompressionStrategy::DynamicOrFixedOrStored => return Err(...)
}
// Check frame.total_length and selected_work, then charge exactly once.
```

Verified public atomic-observation pattern:

```moonbit
// Source: modules/mb-image/png/encode_test.mbt:954-966
let before = budget.remaining()
let error = PngEncoder::encode_indexed*_with_compression_strategy(...).unwrap_err()
inspect(error.context() == Some(expected_context), content="true")
inspect(png_adam7_same_remaining(before, budget.remaining()), content="true")
inspect(png_encode_prefix(writer).length(), content="0")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Indexed encoding always uses Stored/filter-None frame facts | Explicit non-interlaced `FixedOrStored` builds actual Stored and Fixed `PngFrameFacts` and selects the complete-frame winner | Phase 85 | Phase 86 must qualify selected ancillary-aware admission, not introduce a new planner. [VERIFIED: modules/mb-image/png/encode.mbt:2297-2347; .planning/phases/85-indexed-compression-api-and-fixed-wire-contract/85-VERIFICATION.md] |

**Deprecated/outdated:**

- Treating non-indexed frame accounting as applicable to Type-3 selection is invalid for this phase because PLTE and optional tRNS alter complete-frame length. [VERIFIED: modules/mb-image/png/encode.mbt:344-394,2309-2343]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A small parameterized public helper can reuse existing selectors/observers without creating a second oracle. | Exact Source and Test Seams | Test structure may need to remain explicit per façade if MoonBit inference or ownership makes a generic helper awkward. |
| A2 | Constructor-level checked-overflow testing is the correct reachable evidence because a valid immutable `PngIndexedImage` cannot carry overflowing pixel geometry into encoder preflight. | Checked-arithmetic boundary | The planner may need to locate an existing package-private fixture seam if product policy requires encoder-facade evidence beyond the valid-source invariant. |
| A3 | Hard-coded per-strategy work assertions are unsafe relative to selected-facts assertions. | Common Pitfalls | Low; it affects test maintenance rather than the public contract. |

## Open Questions (RESOLVED)

1. **Canonical public exact-limit corpus:** Use the existing 512-pixel `png_indexed_compression_matrix_source` Fixed-winner/Stored-fallback matrix as the canonical public exact-limit corpus. It covers every selected Type-3 depth with actual PLTE and shortest one-byte tRNS facts; do not introduce a smaller competing oracle. [VERIFIED: modules/mb-image/png/encode_wbtest.mbt:1333-1420]

2. **Both work guards are required:** Tests must assert exact and one-less behavior for both `CodecLimits.max_work` and budget work. The limit guard proves rejection before `budget.charge`; the budget guard proves exact single-charge admission and atomic budget failure. [VERIFIED: modules/mb-image/png/encode.mbt:2358-2381; modules/mb-image/png/encode_wbtest.mbt:1009-1055]

## Environment Availability

Step 2.6: SKIPPED (no external runtime, service, package, or CLI dependency is introduced; this phase changes only the existing portable MoonBit PNG code/tests). [VERIFIED: CONTEXT.md scope guard]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identity boundary exists in this library slice. |
| V3 Session Management | no | No session state exists. |
| V4 Access Control | no | No authorization decision exists. |
| V5 Input Validation | yes | Validate indexed geometry, palette capacity, and arithmetic before charge/output; retain checked arithmetic. [VERIFIED: modules/mb-image/png/encode.mbt:2237-2308] |
| V6 Cryptography | no | PNG CRC/Adler are integrity framing checks, not cryptographic controls. [ASSUMED] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Arithmetic overflow in image geometry/frame accounting | Denial of Service | Use `@checked` arithmetic and test rejection before resource charge or observable output. [VERIFIED: modules/mb-image/png/encode.mbt:2255-2294; modules/mb-image/png/encode.mbt:364-384] |
| Oversized palette for selected bit depth | Denial of Service | Reject `indexed-palette-cap` before candidate planning/charge. [VERIFIED: modules/mb-image/png/encode.mbt:2251-2254] |
| Resource exhaustion through planning/replay work | Denial of Service | Check selected output/work limits, then charge exactly the selected work once. [VERIFIED: modules/mb-image/png/encode.mbt:2358-2381] |

## Sources

### Primary (HIGH confidence)

- No provider was classified HIGH in this session.

### Secondary (MEDIUM confidence)

- [W3C PNG Third Edition](https://www.w3.org/TR/png-3/) — indexed PLTE/tRNS semantics and generic chunk envelope rules.

### Tertiary (LOW confidence)

- Local source inspection: `modules/mb-image/png/{png,encode,stream_encode,encode_test,encode_wbtest,stream_encode_test}.mbt` — exact project seams; the configured `classify-confidence` seam classifies provider `codebase` as LOW even when verified.
- Phase artifacts: `86-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `85-VERIFICATION.md`, and `research/v028-INDEXED-PNG-COMPRESSION.md` — locked scope and prior-phase baseline.

## Metadata

**Confidence breakdown:**

- Standard stack: LOW — no package/API verification was needed; the codebase provider is classified LOW.
- Architecture: LOW — directly inspected current construction/preflight source, but the configured codebase classifier is LOW.
- Pitfalls: MEDIUM — source behavior was inspected and indexed PNG framing was cross-checked with the W3C specification.

**Research date:** 2026-07-24  
**Valid until:** 2026-08-23 (stable file-format semantics; re-check local source immediately before planning if the worktree changes).
