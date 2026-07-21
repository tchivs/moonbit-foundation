# Phase 26: Pausable PNG Decode Substrate - Research

**Researched:** 2026-07-21
**Domain:** Internal resumable PNG framing, IDAT transport, DEFLATE, and raster decode
**Confidence:** HIGH

## User Constraints

No `CONTEXT.md` exists for this phase. The following scope is therefore taken from the approved v0.8 roadmap, requirements, project state, and the parent assignment. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`]

### Locked Decisions

- Phase 26 is an **internal substrate**: retain `PngDecoder` as the only PNG public decoder and do **not** add `PngChunkDecoder` until Phase 27. [VERIFIED: codebase: `.planning/ROADMAP.md: Phase 26-27`]
- Preserve the eager decoder's complete supported profile: grayscale, indexed/PLTE, `tRNS`, 16-bit inputs, Adam7, sRGB, retained legacy declarations, and iCCP. [VERIFIED: codebase: `.planning/ROADMAP.md: Phase 26`; `modules/mb-image/png/png.mbt`; `modules/mb-image/png/structural.mbt`]
- Preserve deterministic failures, resource limits/budgets, byte accounting, diagnostics behavior, and no-partial-image visibility. [VERIFIED: codebase: `.planning/REQUIREMENTS.md: PNGS-03`; `.planning/STATE.md`]
- Keep the implementation pure MoonBit and portable across js, wasm, wasm-gc, and native; do not introduce FFI, new packages, public streaming encode, registry work, or a changed `Reader` EOF contract. [VERIFIED: codebase: `AGENTS.md`; `.planning/PROJECT.md`; `.planning/REQUIREMENTS.md`]

### the agent's Discretion

- Select private state boundaries, source-file layout, refactor order, and white-box equivalence tests that make every input byte boundary resumable while leaving the public API unchanged.

### Deferred Ideas (OUT OF SCOPE)

- Public `PngChunkDecoder`, caller-facing push/finish results, portable streaming example, and hostile public schedule evidence belong to Phases 27-28. [VERIFIED: codebase: `.planning/ROADMAP.md: Phase 27-28`]
- APNG, HDR/cICP, text/EXIF, full ICC transforms, FFI-backed PNG/zlib, and a resumable PNG encoder are out of scope. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PNGS-03 | Chunked decode preserves eager profile, semantics, accounting, diagnostics, limits, and no-partial-image guarantee. | One private `PngDecodeMachine` is driven by both the existing Reader facade and a test-only caller-byte adapter; the phase gates compare the full eager corpus at all meaningful pause points. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`; `modules/mb-image/png/*.mbt`] |

## Summary

Phase 26 should replace the eager-only chain `_png_read_stream_transport` → `PngIdatSource` → `_png_inflate_zlib_to_raster` with one private, owned `PngDecodeMachine`. The existing `PngDecoder` will construct that machine with a Reader adapter and run it to completion, so its public signature and Reader EOF behavior remain unchanged. A test-only byte adapter will stop the same machine after arbitrary supplied bytes, proving that the machine itself—not a buffered wrapper—is pausable. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`; `modules/mb-image/png/structural.mbt`; `modules/mb-image/png/deflate_inflate.mbt`]

PNG permits IDAT and DEFLATE boundaries to be unrelated; each IDAT payload contributes to one zlib datastream, and a conforming PNG ends at IEND with no following content. The machine must consequently preserve rolling chunk CRC state, zlib/bit state, Huffman and match continuations, scanline/pass cursors, and final EOF validation across a pause. [CITED: https://www.w3.org/TR/png-3/] [CITED: https://www.rfc-editor.org/rfc/rfc1950.html] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

**Primary recommendation:** Implement a private `PngDecodeMachine` plus Reader/test-byte adapters in three ordered tasks; move `PngDecoder` onto it only after structural and DEFLATE/raster continuations exist, and keep the generated interface exactly unchanged in this phase. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PNG input ownership and pause/resume | API / Backend | — | The codec is a portable library; it must copy only bounded pending parser fields and never retain a caller view. [VERIFIED: codebase: `modules/mb-image/qoi/stream_decode.mbt`] |
| Framing, CRC, ordering, and IEND/EOF checks | API / Backend | — | Current PNG structural code owns signature/chunk validation and complete-input enforcement. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`] |
| zlib/DEFLATE continuation | API / Backend | — | The project owns a pure-MoonBit inflater, bit reader, and Huffman routines. [VERIFIED: codebase: `modules/mb-image/png/deflate_*.mbt`] |
| Raster reconstruction and private image backing | API / Backend | Storage | Existing raster functions write through `OwnedImage`/mutable image views after budgeted allocation. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`; `modules/mb-image/png/raster_decode.mbt`] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Existing `tchivs/mb-image/png` package | repository current | PNG decode, bounds, metadata, DEFLATE, and raster work | The phase is a behavior-preserving internal refactor; adding a second codec or compression dependency would break the pure-MoonBit/portable boundary. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`; `AGENTS.md`] |
| Existing `mb-core` bytes/budget/error/io contracts | repository current | owned views, resource limits, typed errors, and Reader facade | These are the imports already allowed by the exact PNG package policy. [VERIFIED: codebase: `policy/foundation.json`; `modules/mb-image/png/moon.pkg`] |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Existing generated PNG decode corpus | accepted pixels plus malformed/zlib/limit outcomes | Use as the primary eager-versus-paused oracle; do not create a parallel fixture format. [VERIFIED: codebase: `fixtures/png/decode-cases.json`; `modules/mb-image/png/generated_decode_vectors_test.mbt`] |
| Existing QOI stream decoder pattern | caller-owned state, copied partial tokens, terminal state precedent | Copy the ownership and test shape only; do not reuse its simple opcode implementation for PNG. [VERIFIED: codebase: `modules/mb-image/qoi/stream_decode.mbt`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Owned continuation state | Accumulate all bytes, call current eager decoder at completion | Rejected: it cannot pause inside DEFLATE/raster work and retains the whole caller input, contrary to the v0.8 decision. [VERIFIED: codebase: `.planning/STATE.md`] |
| One shared private machine | Keep Reader framing and add a separate stream parser | Rejected: duplicated ordering/CRC/limit paths will drift and cannot establish eager equivalence. [ASSUMED] |
| Private Phase-26 substrate | Public `PngChunkDecoder` now | Rejected: the roadmap reserves caller-facing push/finish, sticky terminal behavior, and public evidence for Phases 27-28. [VERIFIED: codebase: `.planning/ROADMAP.md`] |

**Installation:** None. This phase installs no external packages. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`]

## Architecture Patterns

### System Architecture Diagram

```text
existing @io.Reader                    test-only ByteView feeder (Phase 26)
        |                                         |
        v                                         v
  PngReaderByteSource                      PngSliceByteSource
        \                                         /
         \                                       /
          v                                     v
                  private PngDecodeMachine
   signature -> chunk header -> ancillary accumulator/CRC
                         |                 |
                         | first IDAT      | non-IDAT / post-IDAT
                         v                 v
          private output preflight    IEND + CRC + explicit EOF
          (metadata, descriptor,                |
           image, row state)                    v
                         |                  Finished / Error
                         v
       IDAT payload + rolling CRC -> InflateState -> RasterSink
                         |             |              |
                         +-> zlib Adler+--------------+
                                      |
                                      v
                         private completed image/result
                                      |
                                      v
                      existing PngDecoder returns result
```

### State Ownership and Pause Contract

Use a private input result such as `ByteReady(Byte) | NeedInput | EndOfInput | Failed(CoreError)`. The machine owns its cursor and all partial fields; an adapter owns only a transient source view/Reader. `NeedInput` is a pause, while `EndOfInput` is only used by the eager Reader adapter to preserve existing EOF semantics; the public explicit `finish()` distinction is deferred to Phase 27. [ASSUMED]

| Owner | Persistent state required at a pause | Must not retain |
|-------|--------------------------------------|-----------------|
| `PngDecodeMachine` | total accepted bytes; signature index; 4-byte length/type/CRC field buffers; chunk kind/length/remaining; rolling CRC; chunk-order/colour/PLTE/tRNS facts; decode options/limits/budget; terminal result/error. [ASSUMED] | Caller `ByteView`, Reader lease, or an entire IDAT datastream. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`; `modules/mb-image/qoi/stream_decode.mbt`] |
| Ancillary accumulator | Fixed IHDR/sRGB/gAMA/cHRM payloads, bounded PLTE/tRNS/iCCP payloads only when required by existing validation; current CRC and payload index. [ASSUMED] | Unknown ancillary payloads when opaque preservation is disabled; they can be CRC-scanned then discarded. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`] |
| `PngIdatState` | current IDAT remaining byte count, rolling CRC, whether a CRC trailer is pending, and post-IDAT ordering state. [ASSUMED] | A copied IDAT payload; the current implementation is forward-only specifically to avoid owning it. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`] |
| `PngInflateState` | zlib header/trailer index; LSB bit accumulator; block phase; stored-block remaining length; active trees; Huffman-prefix cursor; dynamic-tree code-length arrays/repeat cursor; pending length/distance/match; 32 KiB history; Adler-32. [ASSUMED] | Restartable local variables from `_png_inflate_zlib_to_raster`; those lose correctness at a byte pause. [VERIFIED: codebase: `modules/mb-image/png/deflate_inflate.mbt`; `modules/mb-image/png/deflate_bits.mbt`] |
| `PngRasterSink` | expected/emitted filtered bytes; current filter; row/column; packed-row buffers; Adam7 pass/pass-row; allocated private image and metadata/descriptor/disposition ingredients. [ASSUMED] | Any externally observable image/result before terminal validation. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`; `.planning/STATE.md`] |

### Pausable Phases

1. **Signature and chunk header:** consume one byte at a time into fixed fields; validate a completed field before advancing. Charge `max_input_bytes` only when a byte is accepted, matching the existing `_png_read_one` accounting boundary. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`]
2. **Ancillary chunks:** update CRC while reading; retain only the payloads the established semantic validators require. Run the current pure payload validators after the complete payload and CRC are available. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`]
3. **First IDAT preflight:** after the IDAT type/length is valid and all pre-IDAT facts are known, build the same colour metadata, descriptor, output budget split, image, and row buffers used by the eager facade before taking compressed bytes. Keep them private. [ASSUMED]
4. **IDAT/CRC transport:** feed each payload byte directly to the inflater while rolling the IDAT CRC; after the last payload byte, pause independently while collecting/validating its four-byte CRC before parsing the next chunk. [ASSUMED]
5. **zlib/DEFLATE:** resume a single continuation after any missing compressed byte: header, block header, stored length/body, Huffman code bit, dynamic code-length repeat, length/distance extra bit, match-copy byte, and Adler trailer are all distinct states. [ASSUMED]
6. **Raster:** `emit(uncompressed_byte)` updates one filter/sample position at a time and persists packed rows and Adam7 pass transitions; it never needs the input view after the byte has been consumed. [ASSUMED]
7. **Post-zlib/IEND/EOF:** preserve eager error precedence: zlib completion while IDAT bytes remain is `zlib-trailing`; otherwise validate final IDAT CRC, prohibit later IDAT, validate IEND length/CRC, and confirm end of input before producing a result. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`; `modules/mb-image/png/deflate_inflate.mbt`]

### Eager Facade Bridge

`PngDecoder::decode` should become a small driver: create `PngDecodeMachine` with `PngReaderByteSource`, repeatedly advance until a private completed result or terminal error, then return exactly that result. The Reader adapter must translate its existing empty/no-progress/host-failure behavior through the same helper/error contexts rather than interpreting an empty read as a successful stream finish. [ASSUMED]

The refactor must remove the eager-only ownership seam rather than wrap it: `_png_read_stream_transport`, `PngIdatSource`, and `_png_inflate_zlib_to_raster` currently hand off through a synchronous Reader-owned source and large local DEFLATE/raster variables. Their validation helpers, metadata constructors, preflight calculations, row reconstruction methods, Adam7 geometry, Huffman construction, CRC, and error strings should be retained/reused where possible. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`; `modules/mb-image/png/structural.mbt`; `modules/mb-image/png/deflate_*.mbt`; `modules/mb-image/png/raster_decode.mbt`]

### Exact Resource and Image Visibility Semantics

- Allocate image and row storage exactly once after successful first-IDAT preflight, using the existing child-budget split and row-allocation envelopes; do not allocate a second staging image. [ASSUMED]
- An allocation/preflight error occurs before any compressed raster byte is accepted and leaves caller budget state unchanged where existing tests establish that behavior. [VERIFIED: codebase: `modules/mb-image/png/structural_wbtest.mbt`; `modules/mb-image/png/png_test.mbt`]
- A later CRC/zlib/filter/IEND/EOF error keeps the allocated image private and returns no `DecodeResult`. [VERIFIED: codebase: `.planning/STATE.md`; `modules/mb-image/png/png.mbt`]
- On success, construct the same empty metadata disposition and return `bytes_read` equal to the complete physical PNG byte count, including final CRC/IEND and no trailing byte. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`; `modules/mb-image/png/structural.mbt`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # existing public PngDecoder facade; delegate only
├── structural.mbt          # shared PNG grammar/preflight helpers, reduced synchronous transport
├── stream_decode.mbt       # NEW private decode machine, adapters, framing/IDAT state
├── deflate_bits.mbt        # refactor bit operations to machine-compatible continuation helpers
├── deflate_huffman.mbt     # refactor symbol/dynamic-tree cursor support
├── deflate_inflate.mbt     # refactor to private explicit InflateState
├── raster_decode.mbt       # extract private resumable raster sink from current emit closure
├── stream_decode_test.mbt  # NEW black-box eager facade equivalence tests
└── stream_decode_wbtest.mbt # NEW white-box pause-state/ownership tests
```

### Implementation Sketch

```moonbit
// Private only; do not declare a public PNG streaming API in Phase 26.
priv enum PngAdvance {
  NeedInput
  Complete(@codec.DecodeResult)
  Failed(@error.CoreError)
}

// The eager facade repeatedly supplies bytes from @io.Reader.
// Phase-26 tests supply bounded ByteView slices and stop on NeedInput.
priv fn PngDecodeMachine::advance(self : PngDecodeMachine) -> PngAdvance {
  // dispatch one persisted framing / IDAT / DEFLATE / raster continuation
  // until it needs the next input byte or reaches a terminal state
}
```

The shape follows the state-owned QOI stream decoder, while the internal states must be richer because current PNG decode crosses independent structural, DEFLATE, and raster modules. [VERIFIED: codebase: `modules/mb-image/qoi/stream_decode.mbt`; `modules/mb-image/png/*.mbt`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PNG grammar, chunk classification, limits, CRC, and error contexts | A new parallel parser | Existing `_png_*` validators and CRC/type helpers, refactored around completed fields | The current corpus asserts their exact accepted/rejected profile. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`; `modules/mb-image/png/generated_decode_vectors_test.mbt`] |
| PNG metadata/profile semantics | Stream-only metadata rules | Existing colour declaration, profile, descriptor, and metadata constructors | Full-profile parity includes the v0.7 colour behavior. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`; `modules/mb-image/png/structural.mbt`] |
| DEFLATE implementation | External zlib/FFI or a new inflater | Existing pure-MoonBit stored/fixed/dynamic DEFLATE algorithm, converted to owned state | FFI is explicitly out of scope and the current package is portable. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`; `modules/mb-image/png/deflate_*.mbt`] |
| Raster semantics | A second pixel/filter implementation | Existing reconstruction/writer helpers, extracted behind `PngRasterSink` | Grayscale, palette, transparency, 16-bit, and Adam7 behavior is already established. [VERIFIED: codebase: `modules/mb-image/png/raster_decode.mbt`] |

**Key insight:** retain tested pure functions and representation helpers, but replace only the synchronous ownership/control flow; a second decoder is more likely to drift than a stateful extraction. [ASSUMED]

## Common Pitfalls

### Pitfall 1: Buffered faux-resumability

**What goes wrong:** Input is accumulated and the old eager decoder runs only at the end. [VERIFIED: codebase: `.planning/STATE.md`]

**How to avoid:** Require a white-box pause assertion inside each DEFLATE and raster continuation, not merely at chunk boundaries. [ASSUMED]

### Pitfall 2: Restarting a partially decoded DEFLATE token

**What goes wrong:** Retrying `Huffman::symbol`, dynamic tree expansion, or a match after `NeedInput` consumes already-read bits twice or loses repeat/match progress. [VERIFIED: codebase: `modules/mb-image/png/deflate_inflate.mbt`; `modules/mb-image/png/deflate_huffman.mbt`]

**How to avoid:** Store the symbol prefix, dynamic-tree cursor/repeat state, length/distance extra-bit state, and remaining match bytes in `PngInflateState`. [ASSUMED]

### Pitfall 3: Treating IDAT as its own zlib stream

**What goes wrong:** Validation incorrectly resets zlib or Adler state between legal IDAT splits. [CITED: https://www.w3.org/TR/png-3/]

**How to avoid:** Keep one inflater/adler/history state across consecutive IDAT payloads; only CRC and payload remaining reset per chunk. [ASSUMED]

### Pitfall 4: Publishing the image after raster completion

**What goes wrong:** Later IDAT CRC, Adler, IEND CRC, or trailing-input rejection invalidates pixels that were already observable. [VERIFIED: codebase: `.planning/STATE.md`; `modules/mb-image/png/structural.mbt`]

**How to avoid:** Make the image an implementation detail until the post-IEND EOF state creates the result. [ASSUMED]

### Pitfall 5: Resource-accounting drift

**What goes wrong:** Refactor changes when parent/child budgets are charged or adds a second image/row allocation. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`; `modules/mb-image/png/png.mbt`]

**How to avoid:** Preserve existing preflight/budget helpers and assert before/after resource limits at every current boundary vector. [ASSUMED]

## Minimal Executable Task Breakdown

### Task 1 — Establish private input/framing and resource-ready machine

**Files:** `png.mbt`, `structural.mbt`, new `stream_decode.mbt`, new `stream_decode_wbtest.mbt`. [ASSUMED]

- Introduce the private byte-source result, Reader adapter, test-only slice adapter, terminal state, fixed-field/chunk/CRC states, and copied bounded ancillary accumulator. [ASSUMED]
- Move shared structural grammar/preflight transitions into the machine; leave existing public `PngDecoder` behavior temporarily covered by its present path until Task 3 switches the facade. [ASSUMED]
- On first valid IDAT header, reserve/build metadata, descriptor, image, and row state privately with the existing helpers; prove no caller-view retention and no image result at this boundary. [ASSUMED]
- White-box test pauses at all signature/header/type/length/payload/CRC boundaries, including IHDR, PLTE, tRNS, colour chunks, iCCP, empty IDAT, and IEND. [ASSUMED]

### Task 2 — Convert DEFLATE and raster locals into resumable continuations

**Files:** `deflate_bits.mbt`, `deflate_huffman.mbt`, `deflate_inflate.mbt`, `raster_decode.mbt`, `stream_decode.mbt`, new `stream_decode_wbtest.mbt`. [ASSUMED]

- Convert bit reads, Huffman-symbol reads, dynamic-tree construction, stored body copying, length/distance parsing, and back-reference copying into explicit `PngInflateState` substates. [ASSUMED]
- Extract the current inflater `emit` closure to `PngRasterSink::emit`, retaining filter, packed row, palette/transparency, 16-bit, and Adam7 pass state between emitted bytes. [ASSUMED]
- Wire `PngIdatState` to feed one compressed payload byte at a time, authenticate each CRC, validate zlib Adler, and transition into post-IDAT framing with current error precedence. [ASSUMED]
- Add white-box pause tests at zlib header/adler, stored/fixed/dynamic blocks, dynamic repeat symbols, match copies, every filter position, each Adam7 pass transition, IDAT CRC, IEND CRC, and EOF. [ASSUMED]

### Task 3 — Switch eager facade and lock full-profile equivalence

**Files:** `png.mbt`, new `stream_decode_test.mbt`, existing PNG generated/public/white-box test files as needed, `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Invoke-MoonQuality.ps1`. [ASSUMED]

- Make `PngDecoder::decode` drive the shared machine through `PngReaderByteSource`; remove or retire the old synchronous transport hand-off only after all tests use the new path. [ASSUMED]
- For every accepted generated vector, compare eager result dimensions, channels, every output byte, descriptor metadata/profile/transfer, disposition, and `bytes_read` against the same machine driven through adversarial internal split schedules. [ASSUMED]
- For every rejected vector and boundary mutation, compare category/code/context and resource-budget deltas; verify no result after any late failure. [ASSUMED]
- Update exact package file/source inventories to admit private `stream_decode.mbt` and its test files, while keeping the generated public interface and its two public types (`PngDecoder`, `PngEncoder`) unchanged. [VERIFIED: codebase: `policy/foundation.json`; `scripts/quality/Assert-Policy.ps1`]
- Keep the PNG quality lane command structure and four targets; Phase 26 adds internal equivalence evidence only, not the public streaming workflow reserved for Phase 28. [VERIFIED: codebase: `scripts/quality/Invoke-MoonQuality.ps1`; `.planning/ROADMAP.md`]

## Source and Policy Impacts

| Area | Phase-26 change | Must remain unchanged |
|------|-----------------|-----------------------|
| `modules/mb-image/png/stream_decode.mbt` | Add a private production source after `generated_vectors.mbt` in policy ordering. [ASSUMED] | No public `PngChunkDecoder`, push result, or finish API. [VERIFIED: codebase: `.planning/ROADMAP.md`] |
| PNG test inventory | Add `stream_decode_test.mbt` and `stream_decode_wbtest.mbt` to exact directory/package inventories. [ASSUMED] | Existing PNG generated-vector and eager tests remain authoritative. [VERIFIED: codebase: `scripts/quality/Assert-Policy.ps1`; `modules/mb-image/png/*_test.mbt`] |
| `policy/foundation.json` semantic interface | Do not change it in Phase 26. [ASSUMED] | `PngDecoder`, `PngEncoder`, allowed imports, and four targets remain exact. [VERIFIED: codebase: `policy/foundation.json`] |
| `Assert-PngFoundationPolicy` and negative fixtures | Update exact source/file lists only; keep rejecting extra public stream types, explicitly including future names until Phase 27 deliberately changes the contract. [ASSUMED] | Fail-closed exact policy checks. [VERIFIED: codebase: `scripts/quality/Assert-Policy.ps1`] |
| Fixtures and generators | Reuse existing generated corpus; add no QOI changes or fixture-policy changes in this phase. [VERIFIED: codebase: `fixtures/png/decode-cases.json`; `docs/policies/licensing-and-fixtures.md`] |

## State of the Art

| Old Approach | Current Phase-26 Target | Impact |
|--------------|-------------------------|--------|
| Reader-backed structural parser returns a `PngStreamTransport`, then synchronous locals inflate/rasterize. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`; `modules/mb-image/png/structural.mbt`] | Private, explicit, input-pausing decode machine driven by a Reader adapter. [ASSUMED] | Existing API remains compatible while Phase 27 gains a safe insertion point for caller chunks. [ASSUMED] |
| IDAT source and bit reader return terminal `Result` errors when Reader data is absent. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`; `modules/mb-image/png/deflate_bits.mbt`] | Private `NeedInput` is a nonterminal machine outcome; the eager adapter maps actual Reader EOF/failure to existing terminal behavior. [ASSUMED] | Reader EOF semantics stay unchanged while arbitrary byte pauses become representable. [ASSUMED] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The private input result can cleanly distinguish `NeedInput` from Reader EOF without altering observed eager errors. | State Ownership / Eager Facade Bridge | Eager truncation/no-progress behavior could drift. |
| A2 | A single `PngDecodeMachine` can reuse current metadata/preflight and raster helpers without changing allocation counts. | Exact Resource Semantics | Budget conformance or full-profile parity could regress. |
| A3 | Adding private stream source/test files in Phase 26 is the smallest policy change; the semantic interface can wait until Phase 27. | Source and Policy Impacts | Policy inventory/order may need a different internal source placement. |

## Open Questions

1. **Should Phase 26 retain a test-only slice adapter in production source or construct it inside white-box tests?**
   - What we know: a caller-byte adapter is necessary to prove the private machine pauses; no public API is allowed. [VERIFIED: codebase: `.planning/ROADMAP.md`; `.planning/STATE.md`]
   - Recommendation: keep the generic source protocol and a private slice adapter in `stream_decode.mbt` so Phase 27 can bind it to public input without duplicating core control flow. [ASSUMED]

2. **Can iCCP's already-bounded, fully accumulated decompression remain synchronous after its payload is complete?**
   - What we know: iCCP is a bounded pre-IDAT metadata path rather than IDAT image transport. [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`]
   - Recommendation: yes for Phase 26, provided input pauses occur before every iCCP payload byte and all existing iCCP limit/budget/error tests remain equal; do not expand scope to CPU-yield scheduling. [ASSUMED]

## Environment Availability

No new external runtime, service, CLI, or package dependency is introduced; the phase uses the existing MoonBit package and quality lane. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`; `scripts/quality/Invoke-MoonQuality.ps1`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | This portable binary codec has no authentication flow. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`] |
| V3 Session Management | no | The internal decoder state is not an authenticated user session. [VERIFIED: codebase: `modules/mb-image/png/*.mbt`] |
| V4 Access Control | no | The package has no authorization boundary. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`] |
| V5 Input Validation | yes | Preserve checked lengths, chunk grammar/order, CRC, zlib/DEFLATE validation, limits, and typed failure at every resumed boundary. [CITED: https://owasp.org/www-project-application-security-verification-standard/] [VERIFIED: codebase: `modules/mb-image/png/structural.mbt`] |
| V6 Cryptography | no | PNG CRC and Adler are integrity/error-detection mechanics, not cryptographic protection; do not label them as security cryptography. [CITED: https://www.w3.org/TR/png-3/] [CITED: https://www.rfc-editor.org/rfc/rfc1950.html] |
| V8 Data Protection | yes | Keep allocated pixels private until final integrity/framing completion. [CITED: https://devguide.owasp.org/en/11-security-gap-analysis/01-guides/02-asvs/] [VERIFIED: codebase: `.planning/STATE.md`] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Decompression expansion or unbounded work | Denial of service | Keep current input/output/work limits, checked arithmetic, child budgets, 32 KiB history, and generated hostile limit vectors. [VERIFIED: codebase: `modules/mb-image/png/deflate_inflate.mbt`; `modules/mb-image/png/generated_decode_vectors_test.mbt`] |
| Chunk/order/CRC confusion across pauses | Tampering | Store one chunk state and rolling CRC; validate before state transition or result visibility. [CITED: https://www.w3.org/TR/png-3/] [ASSUMED] |
| Partial image exposed before integrity is known | Information disclosure / tampering | Keep `OwnedImage` and result ingredients private until IDAT CRC, Adler, IEND CRC, and EOF succeed. [VERIFIED: codebase: `.planning/STATE.md`] |
| Borrowed caller bytes modified after a pause | Tampering | Copy only bounded pending fields and consume a byte before returning `NeedInput`; never retain `ByteView`. [VERIFIED: codebase: `modules/mb-image/qoi/stream_decode_test.mbt`] |

## Sources

### Primary (HIGH confidence)

- [PNG Third Edition](https://www.w3.org/TR/png-3/) - datastream order, CRC, IDAT/zlib independence, IEND/trailing-content requirements.
- [RFC 1950](https://www.rfc-editor.org/rfc/rfc1950.html) and [RFC 1951](https://www.rfc-editor.org/rfc/rfc1951.html) - zlib trailer and DEFLATE block/bit-stream rules.
- `modules/mb-image/png/{png,structural,deflate_bits,deflate_huffman,deflate_inflate,raster_decode}.mbt` - current implementation ownership and exact behavior.
- `modules/mb-image/qoi/stream_decode*.mbt` - repository streaming ownership/terminal precedent.

### Secondary (MEDIUM confidence)

- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/) - validation and data-protection control framing.

### Tertiary (LOW confidence)

- None; implementation recommendations requiring confirmation are enumerated in the Assumptions Log.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - no new packages; exact existing package imports and targets are policy-verified.
- Architecture: MEDIUM - current ownership seams are verified; the proposed state decomposition is an implementation recommendation.
- Pitfalls: HIGH - synchronous local-state and final-validation risks are directly visible in current PNG code and locked project decisions.

**Research date:** 2026-07-21
**Valid until:** Phase planning begins; this is codebase-specific refactor research and should be refreshed after any PNG pipeline change.
