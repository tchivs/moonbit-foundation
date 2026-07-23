# Phase 82: Indexed8 Adam7 Streaming and Qualification - Research

**Researched:** 2026-07-24  
**Domain:** caller-owned PNG chunk leases and four-target qualification  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Streaming lifecycle

- **D-01:** Exercise the existing `PngChunkEncoder::new_indexed8_with_interlace_strategy(..., Adam7, ...)` as a thin facade over the Phase 81 machine; no new stream or encoder is permitted.
- **D-02:** Prove zero-capacity, one-byte, and ragged leases against fresh eager bytes, including accepted-only totals and sentinel-preserved unaccepted tails.
- **D-03:** Prove released-lease failure is sticky and writes zero bytes thereafter; prove repeated finished pulls write zero bytes and preserve later destinations.

### Independent qualification

- **D-04:** Parse chunk-origin bytes independently for IHDR, PLTE, canonical tRNS, CRCs and the seven-pass inflated Type-3/8 raster; also use public decode. Do not accept eager/chunk equality as sole evidence.
- **D-05:** Retain opaque/transparent Indexed8 and Indexed1/2/4 literal compatibility vectors, and run the ordinary frozen PNG package gate on all four targets.

### the agent's Discretion

- Reuse existing hostile-drain helpers where they preserve independent assertions and avoid copying transport logic.

### Deferred Ideas (OUT OF SCOPE)

Indexed Type-3/1, /2, /4 Adam7, adaptive filters, alternative compression, staging, a second encoder, FFI, wrappers, copied trees, and release automation remain excluded.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research support |
|---|---|---|
| INDEXADAM7-05 | Caller-buffered Indexed8 Adam7 reuses the bounded eager machine, is byte-identical under zero/one/ragged leases, preserves accepted-only progress and untouched tails, and retains sticky terminals. | Reuse the established Indexed8 hostile-drain/released-lease patterns, but construct a fresh `new_indexed8_with_interlace_strategy(..., Adam7, ...)` encoder and compare its accepted bytes with a fresh eager Adam7 oracle. [VERIFIED: planning artifacts; codebase inspection] |
| INDEXADAM7-06 | Independent seven-pass wire evidence, public decode, frozen Indexed8/low-bit vectors, and the ordinary PNG package gate qualify wasm, wasm-gc, js, and native. | Independently parse the completed chunk-origin bytes and public-decode them; keep existing literal-vector tests unchanged and run the frozen all-target PNG package command. [VERIFIED: planning artifacts; codebase inspection] |
</phase_requirements>

## Summary

Phase 81 already added `PngChunkEncoder::new_indexed8_with_interlace_strategy` and proved its ordinary sufficient-lease `IHDR` wiring. Its verification records that the new selector directly constructs the one indexed `PngEncodeMachine`, uses the same checked Adam7 preflight/scalar traversal as eager encoding, and does not introduce another transport. Phase 82 must not modify that production path; its necessary implementation surface is test qualification only. [VERIFIED: Phase 81 summary and verification; codebase inspection]

`PngChunkEncoder::pull` already returns zero-write `Finished` or cached zero-write `Failed` results on terminal state, writes to the caller lease before acknowledging the machine byte, and updates `total_written` only after acknowledgement. Existing Indexed8 and selected low-bit tests exercise the required zero/one/ragged schedules, `Z` tail sentinels, release failure replay, and completed-terminal replay. The smallest safe Phase 82 extension applies those helpers and assertions to a fresh Type-3/8 Adam7 encoder and adds independent assertions over the bytes originating from that drain. [VERIFIED: codebase inspection; Phase 80 verification]

**Primary recommendation:** Change only `modules/mb-image/png/stream_encode_test.mbt`; parameterize or add a narrow sibling around the existing Indexed8 hostile-drain/released-lease pattern for `PngInterlaceStrategy::Adam7`, then parse and decode the collected chunk bytes independently before the ordinary all-target gate. [VERIFIED: planning artifacts; codebase inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Caller-owned lease progression | API / Backend | — | `PngChunkEncoder::pull` owns the active/finished/failed state and accepts bytes into a `MutByteLease`. [VERIFIED: codebase inspection] |
| Adam7 byte production | API / Backend | — | The already-admitted Phase 81 `PngEncodeMachine` produces the byte stream; Phase 82 only drives it through leases. [VERIFIED: Phase 81 verification; codebase inspection] |
| Independent transport evidence | API / Backend | — | Test code parses chunk-origin bytes and invokes the public decoder without using production traversal to manufacture expectations. [VERIFIED: planning artifacts; codebase inspection] |
| Target portability | Build / CI | — | `mb-image` declares js, wasm, wasm-gc, and native, and the MoonBit package gate runs the same PNG tests on each. [VERIFIED: modules/mb-image/moon.mod.json; local toolchain] |

## Project Constraints (from AGENTS.md)

- Keep the capability MoonBit-native and deterministic; Phase 82 adds no FFI, external service, GUI state, or dependency. [VERIFIED: AGENTS.md; planning artifacts]
- Preserve modularity and the existing acknowledged machine rather than adding a new transport or encoder. [VERIFIED: AGENTS.md; Phase 82 context]
- Preserve public compatibility and all frozen Type-3 vectors. [VERIFIED: AGENTS.md; planning artifacts]
- The codebase graph did not index PNG symbols for this workspace, so direct source inspection was required after the graph query returned no matching nodes. [VERIFIED: codebase graph query; codebase inspection]

## Current Seams and Required File Changes

| File | Current evidence | Phase 82 action |
|---|---|---|
| `modules/mb-image/png/stream_encode.mbt` | `new_indexed8_with_interlace_strategy` already delegates to `new_with_indexed_profile(... Eight, interlace_strategy, ...)`; `pull` already implements active, sticky-failed, and sticky-finished paths. [VERIFIED: codebase inspection] | **No production change.** Do not add an adapter, state, buffer, selector, or alternate stream. [VERIFIED: Phase 82 context; codebase inspection] |
| `modules/mb-image/png/stream_encode_test.mbt` | Existing `png_stream_indexed_hostile_drain` covers legacy Indexed8; selected low-bit helpers show the exact zero/one/ragged, sentinel, and released-lease pattern; Phase 81 has only an Adam7 sufficient-lease IHDR smoke. [VERIFIED: codebase inspection; Phase 80 artifacts] | Extend this file with Adam7-specific hostile lifecycle and chunk-origin evidence. [VERIFIED: planning artifacts] |
| `modules/mb-image/png/encode_test.mbt` | Holds test-only literal Indexed8 Adam7 source, raw 36-byte raster, CRC/u32/slice helpers, Stored-IDAT extraction, public decode oracle, and frozen opaque/transparent/low-bit vectors. [VERIFIED: codebase inspection] | **No behavioral rewrite.** Reuse its test-only package helpers where visible; retain its literal vectors unchanged under the package gate. [VERIFIED: planning artifacts; codebase inspection] |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | No Indexed8 Adam7 lifecycle seam was found. [VERIFIED: codebase inspection] | No change required. [VERIFIED: planning artifacts] |

## Recommended Test Architecture

```text
literal 5x5 Indexed8 Adam7 source
          |
          +--> fresh eager selector --> eager bytes (parity oracle only)
          |
          +--> fresh chunk selector --> zero / one / ragged MutByteLease schedule
                                      |
                                      +--> accepted bytes collected
                                      +--> each unaccepted tail remains 'Z'
                                      +--> total_written == prior accepted + written
                                      +--> Finished / Failed replay writes 0
                                                   |
                                                   v
                         chunk-origin bytes --> test-only PNG parser / CRC checks
                                                   |
                                                   +--> literal 36-byte Stored/None raster
                                                   +--> public PngDecoder palette-pixel checks
```

Eager equality is necessary to prove that the chunk facade exposes the same machine; the separate parser/raw-raster/public-decode path is necessary because parity alone cannot reveal a shared framing or traversal defect. [VERIFIED: Phase 82 context; Phase 80 verification]

### Lifecycle helper

Use the closest Phase 80 shape rather than create a new test harness. The preferred minimal refactor is to give `png_stream_indexed_hostile_drain` an explicit interlace/factory parameter (or introduce one Adam7 sibling if that keeps the non-interlaced call sites clearer). It must create a fresh encoder for every schedule and use a fresh eager oracle generated with the matching explicit strategy. [VERIFIED: codebase inspection; Phase 80 artifacts]

For the transparent literal 5×5 fixture, invoke all three schedules independently:

```moonbit
[0UL, 1UL]                 // zero-capacity then one-byte leases
[1UL]                      // only one-byte leases
[0UL, 1UL, 3UL, 2UL, 5UL]  // ragged schedule
```

At each pull, assert `written <= capacity`, `total_written == accepted_before + written`, collect exactly the accepted prefix, and assert each remaining lease byte is `b'Z'`. A zero-capacity lease must be `NeedOutput`, write zero, retain total zero, and preserve its sentinel. On `Finished`, compare collected bytes with the eager Adam7 bytes, then pull into a fresh seven-byte `Z` lease and assert zero-write `Finished`, unchanged total, and unchanged destination. [VERIFIED: Phase 82 context; codebase inspection; Phase 80 verification]

### Released-lease sticky failure

Create a new Adam7 encoder, release a one-byte lease before `pull`, and capture the first `Failed(error)`. A second fresh one-byte `Z` lease must return `Failed` with the same error, `written == 0`, unchanged zero total, and no mutation in either destination. Do not test split-parent behavior unless the existing helper can be reused without broadening the phase: the locked Phase 82 acceptance set requires released leases, not a new ownership feature. [VERIFIED: Phase 82 context; codebase inspection]

### Chunk-origin independent parser and decode

After a successful hostile drain, inspect the *drained chunk bytes*, not eager bytes:

- assert total length 143; `IHDR` data is `00 00 00 05 00 00 00 05 08 03 00 00 01`; verify IHDR CRC. [VERIFIED: Phase 81 verification; codebase inspection]
- assert 12-byte literal `PLTE`, three-byte canonical `tRNS` `00 80 7F`, 47-byte `IDAT`, `IEND`, expected chunk order, and every CRC with the existing test-only `png_indexed_crc32`/`png_indexed_u32`/`png_indexed_slice` helpers. [VERIFIED: Phase 81 verification; codebase inspection]
- obtain the Stored/None payload from those chunk-origin bytes with the existing test-only `png_encode_public_stored_scanlines(bytes, 36)` helper and compare it with the literal `png_indexed8_adam7_expected_raw()` 36-byte oracle. Neither helper invokes production encoding, decoding, packing, or Adam7 geometry. [VERIFIED: codebase inspection]
- feed the drained bytes to public `PngDecoder` and assert all 25 RGBA palette pixels using the literal index/palette/alpha fixture. This is independent of eager/chunk byte equality. [VERIFIED: Phase 81 verification; codebase inspection]

The opaque Adam7 RGB8 decode and the 89-byte opaque / 112-byte transparent non-interlaced Indexed8 vectors, together with Indexed1/2/4 vectors, are already exact tests in `encode_test.mbt`; do not duplicate or alter them. Their retention is demonstrated by the same ordinary package command. [VERIFIED: Phase 81 verification; codebase inspection]

## Minimal Red/Green Test Sequence

1. **Red — lifecycle parity:** add an Adam7 hostile-drain invocation against the transparent 5×5 literal source for `[0,1]`, `[1]`, and `[0,1,3,2,5]`; the current Phase 81 smoke cannot satisfy these assertions. [VERIFIED: Phase 81 summary; codebase inspection]
2. **Green — lifecycle:** reuse/refactor the existing Indexed8 drain helper so it selects Adam7, creates a fresh matching eager oracle, and passes all accepted-only/tail/completed-terminal assertions without production changes. [VERIFIED: codebase inspection]
3. **Red/green — sticky failure:** apply the existing released-lease failure sequence to a fresh Adam7 selector and verify zero-write same-error replay with both sentinels intact. [VERIFIED: Phase 82 context; codebase inspection]
4. **Red/green — independent transport proof:** parse the successfully drained chunk output, compare the literal seven-pass raw raster after test-only Stored extraction, CRC-check framing, and public-decode every transparent pixel. This must remain a chunk-origin assertion after eager parity has passed. [VERIFIED: Phase 82 context; Phase 81 verification]
5. **Regression / portability gate:** retain every existing literal Indexed8 and low-bit vector test and execute the frozen full PNG package on all targets. [VERIFIED: planning artifacts]

## Don't Hand-Roll

| Problem | Do not build | Use instead | Why |
|---|---|---|---|
| Chunk transport | A second Adam7 stream/encoder | Existing `PngChunkEncoder` over the admitted Phase 81 machine | Its `present → set → acknowledge` ordering and terminal cache are the behavior being qualified. [VERIFIED: codebase inspection] |
| Hostile schedule harness | A separate caller-buffer simulation framework | Existing Indexed8 / low-bit hostile-drain and released-lease test patterns | They already inspect progress, tails, and terminals through real leases. [VERIFIED: codebase inspection; Phase 80 verification] |
| Wire oracle | Production traversal or eager equality alone | Literal source/raw bytes plus test-only parser, CRC, Stored extractor, and public decoder | Equality only proves shared behavior, not external correctness. [VERIFIED: Phase 82 context; codebase inspection] |
| Portability wrapper | Target-specific code or script | `moon -C modules/mb-image test png --target all --frozen` | The module declares all four supported targets and the ordinary package suite exercises the same tests. [VERIFIED: modules/mb-image/moon.mod.json; local toolchain] |

## Risks and Guardrails

| Risk | Guardrail |
|---|---|
| Test accidentally invokes legacy non-interlaced factory | Construct every Phase 82 lifecycle encoder with `new_indexed8_with_interlace_strategy(..., Adam7, ...)` and parser-assert IHDR interlace byte `01`. [VERIFIED: Phase 82 context; codebase inspection] |
| Parity hides shared wire defect | Parser/raw/decode assertions consume only chunk-origin bytes and literal test data. [VERIFIED: Phase 82 context] |
| Progress includes unaccepted bytes | Record accepted prefix length before every pull and require `total_written == before + written`. [VERIFIED: codebase inspection; Phase 80 verification] |
| Caller tail mutated | Allocate every lease with `b'Z'` and inspect indices from `written` to capacity after each pull, including terminal replay. [VERIFIED: codebase inspection; Phase 80 verification] |
| Failure/finish not sticky | Use a released first lease and a fresh later lease for `Failed`; use a fresh later lease after `Finished`; both must be zero-write with untouched sentinels. [VERIFIED: Phase 82 context; codebase inspection] |
| Scope expands into a new implementation | No production files change; do not add low-bit Adam7, filters, compression choices, buffers, wrappers, FFI, or release automation. [VERIFIED: Phase 82 context; requirements] |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| MoonBit `moon` | Native and four-target package tests | ✓ | `0.1.20260713` | — [VERIFIED: local toolchain] |
| `mb-image` target declaration | INDEXADAM7-06 | ✓ | `+js+wasm+wasm-gc+native` | — [VERIFIED: modules/mb-image/moon.mod.json] |

**Missing dependencies with no fallback:** None. [VERIFIED: local toolchain; module configuration]

## Validation Architecture

`workflow.nyquist_validation` is explicitly disabled in `.planning/config.json`, so no Nyquist test-map section is required. The phase acceptance gate remains the ordinary frozen PNG test command. [VERIFIED: .planning/config.json; planning artifacts]

Run after the test-only change:

```powershell
# Fast development feedback
moon -C modules/mb-image test png/stream_encode_test.mbt --target native --frozen

# Required Phase 82 qualification: wasm, wasm-gc, js, and native
moon -C modules/mb-image test png --target all --frozen
```

Use an exact named filter only after confirming the final test name; previous Phase 80 evidence found broad filter text can compile but run zero tests. The all-target ordinary package command is authoritative and must be recorded as passing for all four targets. [VERIFIED: Phase 80 summary and verification]

## Security Domain

| ASVS Category | Applies | Standard control |
|---|---|---|
| V5 Input Validation | yes | Reuse existing checked indexed preflight before an encoder/lease exists; test only valid admitted source data and preserve rejection coverage already delivered in Phase 81. [VERIFIED: Phase 81 verification; codebase inspection] |
| V3 Session Management | no | Sticky encoder state is not an authentication session. [VERIFIED: codebase inspection] |
| V6 Cryptography | no | PNG CRC and Adler checks are file-integrity mechanisms, not cryptographic controls. [VERIFIED: codebase inspection] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Test-only helpers defined in `encode_test.mbt` are package-visible to `stream_encode_test.mbt`; if a compiler visibility boundary prevents reuse, copy only the small test-only parser/oracle helpers into `stream_encode_test.mbt`. | Chunk-origin parser | A small test-local duplication would be required; production design remains unchanged. [ASSUMED] |

## Open Questions

1. **No blocking implementation question remains.**
   - What we know: The public Adam7 chunk selector, one-machine construction, complete lifecycle behavior, literal raster oracle, public decoder, frozen vectors, local toolchain, and four-target module declaration already exist. [VERIFIED: Phase 81 verification; codebase inspection; local toolchain]
   - What's unclear: Only whether the planner prefers parameterizing the existing Indexed8 hostile helper or adding an Adam7-specific sibling for readability. [VERIFIED: codebase inspection]
   - Recommendation: Prefer a small strategy/factory parameter if it keeps legacy `None` coverage explicit; otherwise add one sibling while reusing the same assertions. [VERIFIED: Phase 82 context; codebase inspection]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/82-indexed8-adam7-streaming-and-qualification/82-CONTEXT.md` — locked lifecycle, independent evidence, and scope decisions. [VERIFIED: planning artifacts]
- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` — `INDEXADAM7-05`/`-06`, goal, success criteria, and exclusions. [VERIFIED: planning artifacts]
- `.planning/phases/81-indexed8-adam7-machine-and-eager-wire-contract/81-01-SUMMARY.md` and `81-VERIFICATION.md` — completed machine, 5×5 wire facts, selector smoke, and Phase 82 handoff. [VERIFIED: planning artifacts]
- `.planning/milestones/v0.25-phases/80-resumable-indexed-low-bit-qualification/{80-01-PLAN.md,80-01-SUMMARY.md,80-VERIFICATION.md}` — established hostile lease and four-target qualification pattern. [VERIFIED: planning artifacts]
- `modules/mb-image/png/stream_encode.mbt` and `stream_encode_test.mbt` — selector, terminal/acknowledgement semantics, and reusable lease tests. [VERIFIED: codebase inspection]
- `modules/mb-image/png/encode_test.mbt` — literal Type-3/8 Adam7 source/raw/frame/decode and frozen compatibility evidence. [VERIFIED: codebase inspection]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no dependency or runtime addition is necessary. [VERIFIED: codebase inspection; local toolchain]
- Architecture: HIGH — production selector and `pull` paths already provide the sole machine and terminal behavior. [VERIFIED: codebase inspection]
- Pitfalls: HIGH — the exact Phase 80 test patterns and locked Phase 82 assertions identify the relevant lifecycle failures. [VERIFIED: Phase 80 verification; Phase 82 context]

**Research date:** 2026-07-24  
**Valid until:** Phase 82 implementation begins or its locked context changes.
