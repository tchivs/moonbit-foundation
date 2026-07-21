# Phase 33: Fixed-or-Stored PNG Planning and Emission - Research

**Researched:** 2026-07-22  
**Domain:** Private, bounded, deterministic fixed-Huffman-or-stored DEFLATE planning and pausable PNG emission  
**Confidence:** HIGH

## User Constraints

No `CONTEXT.md` exists for Phase 33. The approved roadmap, PNGC-02/03, Phase 32 handoff, and current PNG implementation control the scope. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/32-png-compression-strategy-and-compatibility/{32-RESEARCH.md,32-01-SUMMARY.md,32-VERIFICATION.md`]

### Locked Decisions

- `PngCompressionStrategy::FixedOrStored` is already public; do not add, rename, or change its factories or either legacy constructor. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}`, `policy/foundation.json`]
- `PngEncoder::new()` and `PngChunkEncoder::new(...)` must remain explicit `Stored` routes with byte-for-byte stored-DEFLATE output. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{png.mbt,encode_test.mbt,stream_encode_test.mbt}`]
- Optimized construction must perform capability, geometry, exact selected-output, exact work, and budget admission before an eager writer or caller lease can observe any byte. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`]
- The optimized path is deterministic fixed-Huffman-or-stored only: no dynamic Huffman, adaptive filtering, FFI/host codec, or 32 KiB LZ77 dictionary. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/phases/32-png-compression-strategy-and-compatibility/32-RESEARCH.md`]
- Preserve the existing eager/chunk present → destination-set → acknowledge lifecycle, exact progress, no retained caller lease, and sticky completion/failure behavior on all four declared targets. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt,stream_encode_test.mbt,stream_encode_wbtest.mbt,moon.pkg}`, `.planning/REQUIREMENTS.md`]

### the agent's Discretion

- Use a private scalar compression plan, a deliberately small deterministic matcher, and private fixed-bit emission state under `PngEncodeMachine`; choose precise private names and test helpers. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/stream_encode.mbt`]

### Deferred Ideas (OUT OF SCOPE)

- Phase 34 owns corpus fixtures, benchmark reporting, measured compression claims, and the reproducible evidence presentation for PNGC-04. Do not add any corpus runner, benchmark, or evidence artifact in this phase. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PNGC-02 | A library user requesting the optimized strategy receives deterministic fixed-Huffman-or-stored PNG output whose construction performs exact capability, geometry, output, work, and budget admission before any byte is exposed. | Run private fixed-or-stored planning before the one resource charge; retain selected scalar lengths/work and build no output-sized buffer. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |
| PNGC-03 | A library user can drain optimized eager and caller-buffered chunk output with exact progress, canonical eager/chunk parity, and unchanged sticky completion/failure semantics on js, wasm, wasm-gc, and native. | Route configured eager and chunk construction through the same planned machine, retain present/set/acknowledge ordering, and run focused tests on each declared package target. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{encode.mbt,stream_encode.mbt,stream_encode_test.mbt,moon.pkg}`] |

## Project Constraints (from AGENTS.md)

- Implement core algorithms and shared data models in MoonBit; add no FFI or foreign compressor. [VERIFIED: `AGENTS.md`]
- Keep the portable PNG package modular, deterministic, GUI-independent, and conformant on js, wasm, wasm-gc, and native. [VERIFIED: `AGENTS.md`, `modules/mb-image/png/moon.pkg`]
- Preserve public API compatibility and acyclic package dependencies; this phase must not change the established generated PNG interface. [VERIFIED: `AGENTS.md`, `policy/foundation.json`]
- Use the codebase knowledge graph for discovery when available; no graph MCP tool or `.planning/graphs/graph.json` was present, so this research used targeted source inspection. [VERIFIED: `AGENTS.md`, local graph availability check]
- Do not make direct source edits outside the active GSD workflow. [VERIFIED: `AGENTS.md`]

## Summary

Phase 32 deliberately made `FixedOrStored` a stored-emission alias. Its configured eager and chunk factories already enter the same private `PngEncodeMachine`, while legacy constructors explicitly pass `Stored`. The existing machine has the right outward topology: an immutable source view, scalar counters, one pending byte, `present`, and `acknowledge`; the public chunk wrapper only copies an acknowledged prefix and persists `Active`, `Finished`, or the original `Failed(error)`. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt,stream_encode_test.mbt}`, `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`]

Replace only the configured `FixedOrStored` stored alias with a bounded preflight plan and a private fixed-Huffman byte emitter. The plan scans the source without retaining tokens, computes the exact fixed zlib/PNG size and deterministic logical work, compares it with the existing exact stored plan, and charges the selected plan exactly once only after all fallible work is complete. Emission recomputes the same bounded token stream from the immutable source; it retains a fixed-size bit accumulator, token cursor, and acknowledgement preview rather than a token array, compressed buffer, scanline buffer, or caller lease. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt,deflate_bits.mbt,deflate_huffman.mbt}`, `.planning/ROADMAP.md`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

**Primary recommendation:** Keep `Stored` code byte-identical; make `FixedOrStored` first build an exact scalar `PngFixedOrStoredPlan` using a deterministic distance-1..4 matcher, choose fixed only when its exact PNG length is no larger than stored, then emit through an acknowledgement-preview fixed-bit state beneath the existing `PngEncodeMachine`. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/{encode.mbt,stream_encode.mbt,deflate_huffman.mbt}`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Source/capability/geometry admission | PNG codec core | Storage model | The codec already owns `_png_encode_source`, checked dimension arithmetic, typed limits, and budget charging before any sink is touched. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`] |
| Fixed-or-stored planning | PNG codec core | Checked arithmetic | Exact choice, IDAT length, and logical work are private codec facts, not public options or host work. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |
| Fixed DEFLATE bit emission | PNG codec core | Existing Huffman helpers | DEFLATE packing and fixed code construction are portable algorithm work; the existing decoder already provides canonical-code reversal precedent. [VERIFIED: codebase: `modules/mb-image/png/{deflate_bits.mbt,deflate_huffman.mbt}`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |
| PNG framing and checksums | PNG codec core | Existing structural helpers | The machine remains the sole producer of signature/IHDR/IDAT/IEND, IDAT CRC, and Adler-32 state. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,structural.mbt,deflate_inflate.mbt}`] [CITED: https://www.w3.org/TR/png-3/] |
| Eager and caller-buffered delivery | Existing public adapters | Private machine | Both adapters already delegate to one machine; neither should implement a compressor or a second preflight. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing `tchivs/mb-image/png` package | repository source | Private plan, matcher, fixed-bit state, and established PNG adapters | It owns source admission, PNG framing, zlib checksums, and all four supported targets. [VERIFIED: codebase: `modules/mb-image/png/{moon.pkg,encode.mbt,stream_encode.mbt}`] |
| Existing checked/budget/error contracts | repository source | Checked formulas, typed rejection, and one resource charge | The stored encoder already uses these contracts and the phase must preserve its atomic failure boundary. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`] |
| RFC 1951 fixed-Huffman format | RFC 1951 | Fixed code lengths, LSB packing, EOB, and stored alignment | It defines the only optimized DEFLATE representation allowed in this phase. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |

### Supporting

| Component | Purpose | When to Use |
|---|---|---|
| `_png_reverse_bits` and fixed-tree definitions | Canonical-code reversal and fixed code-length oracle | Reuse or factor these private helpers for the fixed writer; do not make a second canonical-code implementation. [VERIFIED: codebase: `modules/mb-image/png/deflate_huffman.mbt`] |
| `_png_crc_for_type`, `_png_crc_step`, `_png_adler_step` | Existing PNG CRC and zlib Adler computation | Continue using them from acknowledgement effects. [VERIFIED: codebase: `modules/mb-image/png/{structural.mbt,deflate_inflate.mbt,stream_encode.mbt}`] |
| Existing eager/chunk/white-box PNG tests | Admission, parity, exact-progress, and terminal regressions | Extend strategy-aware helpers rather than creating a second encoded-output harness. [VERIFIED: codebase: `modules/mb-image/png/{encode_test.mbt,encode_wbtest.mbt,stream_encode_test.mbt,stream_encode_wbtest.mbt}`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Distance-1..4 bounded matcher | 32 KiB history/dictionary matcher | Rejected: the roadmap excludes a 32 KiB LZ77 dictionary; four nearby distances compress repeated RGB/RGBA pixels while keeping planning/emission storage scalar and bounded. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/phases/32-png-compression-strategy-and-compatibility/32-RESEARCH.md`] |
| Recompute deterministic tokens in emission | Retain a token array or compressed `Bytes` plan | Rejected: an input-sized plan or output-sized buffer breaks the existing bounded machine ownership model. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/milestones/v0.9-phases/29-pausable-png-encode-substrate/29-RESEARCH.md`] |
| Fixed-or-stored exact comparison | Always fixed-Huffman | Rejected: a no-match input can expand under fixed coding; exact comparison selects the stored fallback and supports the later never-larger evidence requirement without putting that evidence work in this phase. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |

**Installation:** None. This phase adds no package, FFI binding, tool, or runtime service. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `.planning/ROADMAP.md`]

## Package Legitimacy Audit

Not applicable: no external package is installed or recommended. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `.planning/ROADMAP.md`]

## Architecture Patterns

### System Architecture Diagram

```text
Configured eager or chunk factory (FixedOrStored)
                         |
                         v
             shared PngEncodeMachine::new_with_...
                         |
      source/capability -> checked geometry -> fixed scalar scan
                         |                    |
                 typed rejection               v
                 no budget charge      exact stored and fixed plans
                                               |
                                 select fixed iff fixed_total <= stored_total
                                               |
      limits(output/work) -> disposition -> one selected-work budget charge
                                               |
                                 private PngEncodeMachine (selected plan)
                                               |
    signature/IHDR -> IDAT header -> zlib header -> stored OR fixed bit emitter
                                               |
                         acknowledgement effect updates CRC/Adler/cursors
                                               |
               eager Writer driver       caller `pull` / caller-owned lease
               present -> write -> ack   present -> set -> ack
```

The plan is complete before either adapter requests a byte. It records only scalar facts and selected emission mode; the fixed token stream is deterministically regenerated in the machine. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

### Recommended Internal Shape

Use private state along these lines; names may vary but responsibilities must not:

```moonbit
priv enum PngDeflatePlan {
  Stored(PngStoredPlan)
  Fixed(PngFixedPlan)
}

priv struct PngFixedPlan {
  fixed_deflate_bits : UInt64
  fixed_deflate_bytes : UInt64
  matcher_work : UInt64
  idat_length : UInt64
  total_length : UInt64
  selected_work : UInt64
}
```

`PngEncodeMachine` keeps the selected plan, its existing PNG scalar state, and one bounded fixed-emission cursor/bit accumulator. It must not retain a token list, a compressed payload, a scanline array, an `OwnedBytes`, or a `MutByteLease`. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/milestones/v0.9-phases/30-public-png-chunk-encoder/30-01-SUMMARY.md`]

### Pattern 1: Exact Optimized Admission Before Budget Charge

**What:** Split the present stored-only `_png_encode_preflight` into shared source/geometry facts plus a strategy-aware planner. Preserve the existing stored formula and behavior when the strategy is `Stored`; only `FixedOrStored` performs the deterministic fixed scan. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

**When to use:** Every configured optimized eager/chunk constructor, through `PngEncodeMachine::new_with_compression_strategy`; never in `present`, `pull`, or the Writer loop. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

**Required ordering:**

1. Call `_png_encode_source`, compute checked pixels, row bytes, and filter-None `scanlines`; reject capability and geometry before scanning pixel data. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`]
2. Compute the stored formula exactly: `stored_blocks = ceil(scanlines / 65535)`, `stored_idat = scanlines + 6 + 5 * stored_blocks`, `stored_total = stored_idat + 57`. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`]
3. For `FixedOrStored`, perform the bounded scan, calculate exact fixed DEFLATE bits/bytes and `fixed_idat = 2 + fixed_deflate_bytes + 4`, then `fixed_total = fixed_idat + 57`; all arithmetic uses `@checked` and all source reads can still return a typed error. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] [CITED: https://www.w3.org/TR/png-3/]
4. Reject a selected IDAT length above `0xffff_ffff` before serializing its PNG 32-bit length field; do not rely on `_png_encode_machine_u32_byte` truncation. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,encode.mbt}`] [CITED: https://www.w3.org/TR/png-3/]
5. Choose `Fixed` iff `fixed_total <= stored_total`, otherwise choose `Stored`; tie-breaking toward fixed makes the decision deterministic. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
6. Calculate `selected_work` exactly as the scan's recorded logical work plus the selected emitter's recorded logical work; compare `output-bytes` and `work` against `CodecLimits`, construct the disposition, then charge exactly that selected work once. A failing check, disposition construction, or charge returns no machine and leaves no visible byte. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `.planning/REQUIREMENTS.md`]

Use one declared, testable logical-work ledger: planning counts every scanline-byte lookup and candidate comparison; stored emission counts its existing emitted-byte work; fixed emission counts the deterministic replay's lookups/comparisons plus emitted PNG bytes. The planner records the first two quantities; fixed replay must reproduce its recorded matcher work, and a mismatch is a private state error. This makes the max-work and budget value exact without pretending to count target-specific CPU instructions. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/{encode.mbt,stream_encode.mbt,moon.pkg}`]

### Pattern 2: Deterministic Bounded Matcher and Exact Fixed Length

**What:** Tokenize the filter-None scanline byte sequence without storing it. At cursor `p`, inspect candidate distances `1, 2, 3, 4` in that order when `distance <= p`; compare up to `min(258, remaining)` source bytes, accept matches of at least three bytes, select the longest, and resolve equal lengths to the smaller distance. Otherwise emit a literal. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/stream_encode.mbt`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

**When to use:** In the `FixedOrStored` planner and, if it wins, in the fixed emitter replay. Never invoke it for the explicit stored strategy. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`]

Use source-indexed `scanline_byte(p)` for both sides of each comparison, including a zero filter byte at each row boundary. Overlapping DEFLATE matches are valid because each compared source byte is known; the matcher still retains no history buffer. The distance ceiling of four covers repeated flat RGB (period three) and straight RGBA (period four) samples without introducing the excluded dictionary. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/ROADMAP.md`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

For one fixed block, calculate before output:

```text
fixed_bits = 3                         // BFINAL=1, BTYPE=01
           + sum(token fixed-code bits + required extra bits)
           + 7                         // fixed end-of-block symbol 256
fixed_deflate_bytes = ceil(fixed_bits / 8)
fixed_idat_length = 2 + fixed_deflate_bytes + 4
fixed_total_length = 57 + fixed_idat_length
```

The fixed block is the final block and does not need the stored-block 65,535-byte limit; `fixed_deflate_bytes` includes zero padding after EOB to the next byte boundary before Adler-32. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] [CITED: https://www.w3.org/TR/png-3/]

### Pattern 3: LSB Accumulator With Fixed Canonical Codes

**What:** Implement a private `write_bits(value, count)`/preview helper with an LSB-first `UInt64` accumulator and at most a byte-sized flush boundary. Emit the final fixed header as `BFINAL=1, BTYPE=01`, literals/lengths using fixed literal/length codes, a five-bit fixed distance code, required length extra bits, then EOB 256. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

**When to use:** Only inside the selected fixed zlib branch. Stored blocks retain their existing exact byte emitter. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]

RFC 1951 packs ordinary fields least-significant-bit first but emits each Huffman code most-significant-bit first. Therefore feed the LSB accumulator the bit-reversed canonical code. Reuse `_png_reverse_bits`/the existing fixed-length definitions or factor them into a shared private helper; do not accidentally write canonical codes directly. [VERIFIED: codebase: `modules/mb-image/png/deflate_huffman.mbt`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

```moonbit
// The writer receives the receiver-order code, not the displayed canonical code.
let code = _png_reverse_bits(canonical_code, code_length)
preview.write_bits(code.to_uint64(), code_length)
```

Distance `1..4` maps directly to fixed distance symbols `0..3`, each five bits and no distance extra bits. Length code selection must cover the RFC 1951 `257..285` bases/extras through length 258; retain a small fixed table or equivalent checked mapper, and write the extra value LSB-first. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

### Pattern 4: Preview Then Acknowledge

**What:** Generalize the single `pending : Byte?` to a bounded pending byte plus an acknowledgement effect containing the next scalar bit/token/checksum state. `present` may preview through zero-output token transitions to determine the next compressed byte, but it must not commit that preview. `acknowledge` verifies the byte, applies the stored effect exactly once, clears pending, and increments `emitted`. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`, `.planning/milestones/v0.9-phases/29-pausable-png-encode-substrate/29-RESEARCH.md`]

**When to use:** Fixed bit emission and any transition that needs to preserve the current public pause contract. Existing eager and chunk loops remain `present → sink mutation → acknowledge`. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

The effect must include enough scalar state to resume exactly after the acknowledged output byte: fixed cursor/token remainder, bit accumulator/count, raw-scanline cursor, Adler state, and any token-completion work count. This lets a failed Writer/lease leave the committed machine unchanged and makes a repeated `present` return the same byte. It also avoids committing a token merely because it produced no complete compressed byte. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt,stream_encode_wbtest.mbt}`]

### Checksums, IDAT, and API Wiring

- Retain the one-IDAT framing: signature, IHDR, IDAT length/type, one zlib datastream, IDAT CRC, IEND. The selected plan's exact `idat_length` is written into the existing frame and must fit PNG's four-byte chunk-length field. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`] [CITED: https://www.w3.org/TR/png-3/]
- Update IDAT CRC for every acknowledged zlib byte, including the two-byte zlib header, fixed/stored DEFLATE bytes, zero padding, and Adler bytes; PNG CRC covers chunk type plus data, not the length. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,structural.mbt}`] [CITED: https://www.w3.org/TR/png-3/]
- Update Adler only for the uncompressed filtered scanline bytes represented by completed literals/matches. Do not checksum DEFLATE headers, code bits, padding, or the Adler field itself. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,deflate_inflate.mbt}`] [CITED: https://www.w3.org/TR/png-3/]
- Keep `PngEncodeMachine::new(...)` as the private explicit-`Stored` wrapper for current white-box callers. Change only `new_with_compression_strategy` to build the optimized plan for `FixedOrStored`; retain public `PngEncoder`, `PngChunkEncoder`, outcomes, results, and generated semantic interface unchanged. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt,stream_encode_wbtest.mbt}`, `policy/foundation.json`]
- Update public documentation on the existing enum/factories to say that `FixedOrStored` now deterministically chooses fixed-Huffman or stored output and still excludes dynamic Huffman/adaptive filters. This documentation-only change must remove the obsolete Phase 32 “currently emits Stored” text. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`, `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                    # revise strategy/factory documentation only
├── encode.mbt                 # strategy-aware exact preflight and eager routing
├── stream_encode.mbt          # scalar plan, matcher, fixed preview/emission, checksums
├── encode_test.mbt            # optimized eager admission, selection, deterministic output
├── encode_wbtest.mbt          # exact formulas, bit/code and frame/checksum invariants
├── stream_encode_test.mbt     # configured chunk progress, parity, sticky terminals
└── stream_encode_wbtest.mbt   # preview/acknowledgement and multi-pause fixed invariants
```

Do not modify `policy/foundation.json`: no normalized declaration changes. Do not add a benchmark/corpus runner, a new package, or an output fixture archive. [VERIFIED: codebase: `policy/foundation.json`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

### Anti-Patterns to Avoid

- **Plan a token array or compressed buffer:** it converts an exact scalar plan into unbounded staging and bypasses the existing resumable design. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]
- **Use canonical Huffman values directly in an LSB accumulator:** this reverses the code stream and produces invalid DEFLATE. [VERIFIED: codebase: `modules/mb-image/png/deflate_huffman.mbt`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]
- **Advance fixed token/Adler state in `present`:** Writer or lease failure would make a byte disappear or a retry differ. Store a preview effect and commit only in `acknowledge`. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]
- **Apply max-output/work checks to the stored estimate before selecting:** the optimized constructor needs the exact selected plan, including fixed padding and replay work. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`]
- **Route legacy constructors through a mutable optimized default:** it violates stored-byte compatibility. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt,encode_test.mbt,stream_encode_test.mbt}`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Public strategy API | New optimizer constructor/enum | Existing `PngCompressionStrategy` and two configured factories | Phase 32 already established and policy-registered the public seam. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`, `policy/foundation.json`] |
| PNG frame/CRC/Adler | A second optimized PNG formatter/checksum implementation | Existing `PngEncodeMachine` framing and `_png_*` checksum helpers | One source preserves eager/chunk parity and PNG checksum ranges. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,structural.mbt,deflate_inflate.mbt}`] |
| Canonical-code derivation | Separate hard-coded bit tables disconnected from the decoder | `_png_reverse_bits` and existing fixed-tree semantics | The decoder already encodes the RFC canonical/reversed-code relation. [VERIFIED: codebase: `modules/mb-image/png/deflate_huffman.mbt`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |
| Lease lifecycle/terminal handling | New output ownership abstraction | Existing `PngChunkEncoder::pull` state wrapper | It already enforces no lease retention and sticky `Finished`/original `Failed`. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`] |

**Key insight:** The optimized branch is an admission-and-emission refinement below a frozen public seam. Its plan must be exact enough to choose and budget the representation before output, but compact enough to regenerate token decisions during pausable emission. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/stream_encode.mbt`]

## Common Pitfalls

### Pitfall 1: Fixed output is chosen using a byte estimate

**What goes wrong:** The implementation overlooks BFINAL/BTYPE, EOB, length extras, or final padding, so `idat_length`, max-output admission, progress total, and CRC offset are wrong. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

**How to avoid:** Count exact bits during the same deterministic token walk used by emission; derive `ceil(bits/8)`, add zlib/Adler, and persist selected IDAT/PNG totals. White-box-test boundaries around 7/8/9-bit flushes and a length-258 match. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,stream_encode_wbtest.mbt}`]

### Pitfall 2: A retry sees a different fixed byte

**What goes wrong:** `present` mutates bit/token/Adler state before a Writer or lease accepts the byte, then the next call skips or changes output. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt,stream_encode_wbtest.mbt}`]

**How to avoid:** Use pending preview effects, acknowledge exactly the presented byte, and test duplicate `present` before acknowledgment at header, literal, match, EOB/padding, and Adler transitions. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]

### Pitfall 3: The stored fallback changes legacy compatibility

**What goes wrong:** Refactoring preflight/emission accidentally alters `Stored` output or legacy admission/work behavior. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`]

**How to avoid:** Keep `PngEncodeMachine::new` and both legacy public constructors explicit `Stored`; retain their complete frozen RGB8/RGBA8 byte assertions and current stored work formula. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt,encode_test.mbt,stream_encode_test.mbt}`]

### Pitfall 4: Fixed checksum boundaries mirror stored offsets

**What goes wrong:** Current stored Adler logic identifies raw bytes from stored-block byte offsets; that condition is invalid for Huffman-packed output. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]

**How to avoid:** Move checksum responsibility into selected-emission acknowledgement effects: IDAT CRC observes every zlib byte; fixed Adler observes completed uncompressed tokens. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,deflate_inflate.mbt}`] [CITED: https://www.w3.org/TR/png-3/]

### Pitfall 5: Large IDAT length is silently truncated

**What goes wrong:** A `UInt64` selected IDAT length is serialized through a four-byte helper without an explicit PNG chunk-field bound. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]

**How to avoid:** Reject `idat_length > 0xffff_ffff` during exact preflight before disposition/budget charge/output. [CITED: https://www.w3.org/TR/png-3/]

## Code Examples

### Deterministic candidate selection

```moonbit
// Private planner/emitter helper: scalar state only.
fn fixed_match_at(machine, pos, remaining) -> Result[(UInt64, UInt64, UInt64), @error.CoreError] {
  let mut best_length = 0UL
  let mut best_distance = 0UL
  let mut work = 0UL
  for distance = 1UL; distance <= 4UL && distance <= pos; distance = distance + 1UL {
    let mut length = 0UL
    while length < 258UL && length < remaining {
      work = work + 1UL
      if machine.scanline_byte(pos + length)? != machine.scanline_byte(pos + length - distance)? { break }
      length = length + 1UL
    }
    if length >= 3UL && length > best_length {
      best_length = length
      best_distance = distance
    }
  }
  Ok((best_length, best_distance, work))
}
```

The ascending distance loop implements the required smallest-distance tie break because `best_length` changes only on a strict improvement. The final implementation must use checked increments for its work ledger. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

### Fixed plan versus stored plan

```moonbit
let fixed_deflate_bytes = (fixed_bits + 7UL) / 8UL
let fixed_idat = @checked.checked_add(6UL, fixed_deflate_bytes)?
let fixed_total = @checked.checked_add(57UL, fixed_idat)?
let selected = if fixed_total <= stored_total {
  PngDeflatePlan::Fixed(...)
} else {
  PngDeflatePlan::Stored(...)
}
```

Here six fixed-IDAT bytes are zlib's two-byte header plus its four-byte check value; 57 is the existing PNG framing constant. The actual code must additionally reject a selected IDAT value above the PNG four-byte chunk-length range and calculate/charge the selected logical work before returning a machine. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`] [CITED: https://www.w3.org/TR/png-3/]

### Acknowledged fixed byte preview

```moonbit
// present(): derive `byte` and scalar `next` without mutating committed state.
self.pending = Some({ byte, next_fixed_state, next_adler, next_work })

// acknowledge(byte): verify equality, then atomically apply the pending effect.
self.fixed_state = pending.next_fixed_state
self.adler = pending.next_adler
self.emitted = self.emitted + 1UL
self.pending = None
```

The real effect must also preserve the existing IHDR/IDAT CRC treatment and terminal transition. The important invariant is that no effect is committed merely by presenting a byte. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| `FixedOrStored` is a stored-emission alias | It becomes an exact private fixed-or-stored plan and emitter | Phase 33 | Public callers keep the same factory/enum while configured bytes may improve deterministically. [VERIFIED: codebase: `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`, `.planning/ROADMAP.md`] |
| Stored block bytes identify Adler payload offsets | Selected-emission acknowledgement effects identify raw token completion | Phase 33 | Fixed compressed bytes can pause safely without applying stored-offset assumptions. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`] |

**Deprecated/outdated:** The Phase 32 documentation statement that `FixedOrStored` “currently emits the Stored baseline” must be removed once this phase implements the private optimized branch. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`, `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | **Adopted contract:** The fixed matcher caps distance at four and uses distance-ascending longest-match selection: inspect distances `1..4` in order, accept only lengths `3..258`, and retain the smaller distance on equal lengths. | Architecture Patterns | This locks deterministic optimized bytes and exact work; white-box tests must prove the distance bound, longest-match choice, and tie break. [RESOLVED] |
| A2 | **Adopted contract:** Exact logical work is the scalar count of planning lookups/comparisons plus selected emission work, rather than platform CPU time. | Pattern 1 | This locks limit/budget units; white-box tests must prove exact boundaries and fixed replay must reject a mismatched recorded matcher-work total. [RESOLVED] |

## Open Questions (RESOLVED)

1. **Private optimized-work ledger spelling and exact units**
   - What we know: PNGC-02 requires exact work/budget admission before bytes, while current stored work equals total output and the fixed branch must additionally scan/match. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/encode.mbt`]
   - Resolution: Adopt A2. The private scalar ledger counts every planning source lookup and candidate comparison, then adds the chosen emitter's deterministic work. Stored retains its established emitted-byte work; fixed replay includes its lookup/comparison work plus emitted PNG bytes and fails a private state check if its matcher-work total differs from the plan. This is the exact max-work and budget-admission unit. [RESOLVED]

2. **Fixed matcher distance ceiling**
   - What we know: Dynamic Huffman and a 32 KiB dictionary are excluded, while future evidence needs flat RGB8/RGBA8 wins. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
   - Resolution: Adopt A1. The private matcher considers only distances `1..4` in ascending order, compares no more than 258 remaining filter-None scanline bytes, accepts matches of length at least three, selects the longest, and preserves the first equal-length distance. It retains no history or token array; white-box tests freeze this contract. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Build/test across declared targets | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` / `moonrun` | Compile and execute MoonBit tests | ✓ | `v0.10.4+2cc641edf` / `0.1.20260713` | — [VERIFIED: local `moonc -v`, `moonrun --version`] |
| PowerShell | Existing quality lane | ✓ | `7.6.3` | — [VERIFIED: local `pwsh --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local command probes]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | The portable PNG codec has no identity boundary. [VERIFIED: codebase: `modules/mb-image/png`] |
| V3 Session Management | no | No session state exists. [VERIFIED: codebase: `modules/mb-image/png`] |
| V4 Access Control | no | No authorization surface exists. [VERIFIED: codebase: `modules/mb-image/png`] |
| V5 Input Validation | yes | Preserve source/capability validation, checked arithmetic, selected output/work limits, IDAT bound, and one budget charge before output. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`] |
| V6 Cryptography | no | CRC-32 and Adler-32 are format integrity checks, not cryptographic controls. [CITED: https://www.w3.org/TR/png-3/] |

### Known Threat Patterns for Optimized PNG Output

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Oversized source, output, work, or IDAT field | Denial of Service | Checked strategy-aware preflight and one charge after all fallible planning. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt`, `.planning/REQUIREMENTS.md`] |
| Unbounded history/tokens/compressed staging | Denial of Service | Distance-1..4 scanner plus scalar plan, replay, and bounded pending effect. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/stream_encode.mbt`] |
| Dropped/duplicated bytes across output pause | Tampering | Preview → sink mutation → acknowledge; commit state/checksum only in the acknowledgement effect. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |
| Invalid CRC/Adler after fixed emission | Tampering | Existing CRC helpers cover acknowledged IDAT bytes; token completion updates Adler over raw scanline bytes. [VERIFIED: codebase: `modules/mb-image/png/{structural.mbt,deflate_inflate.mbt,stream_encode.mbt}`] |
| Retained stale caller lease | Information Disclosure / Tampering | Keep all optimized state under the private machine and pass each lease only to synchronous `pull`. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`] |

## Validation Architecture

Skipped: `workflow.nyquist_validation` is explicitly `false` in `.planning/config.json`. [VERIFIED: codebase: `.planning/config.json`]

## Test Plan

Use existing `*_test.mbt` black-box contracts and `*_wbtest.mbt` private invariants. The phase needs no corpus or benchmark artifact; focused test fixtures are only correctness oracles. [VERIFIED: codebase: `AGENTS.md`, `.planning/config.json`, `.planning/ROADMAP.md`]

| Behavior | Test location | Required assertion |
|---|---|---|
| Deterministic fixed selection | `encode_test.mbt`, `stream_encode_test.mbt` | A repetitive RGB8 and RGBA8 fixture selects fixed (`BTYPE=01`), decodes, and has identical eager/chunk bytes under irregular capacities. [VERIFIED: codebase: `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |
| Deterministic stored fallback | `encode_test.mbt` | A no-useful-match fixture selects stored and configured output equals explicitly configured `Stored`; this is a unit fallback check, not Phase 34 corpus evidence. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt`, `.planning/ROADMAP.md`] |
| Exact optimized admission | `encode_test.mbt`, `stream_encode_test.mbt` | Capability, width/height/pixels, selected output, selected work, and budget failures expose zero eager bytes / no chunk encoder and leave the failing budget unchanged; exact-boundary values admit. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`] |
| Plan/bit formulas | `encode_wbtest.mbt` | Fixed bands, reversed code emission, match length/extras, EOB/padding, `ceil(bits/8)`, zlib/IDAT/PNG totals, and 32-bit IDAT rejection. [VERIFIED: codebase: `modules/mb-image/png/{deflate_huffman.mbt,encode_wbtest.mbt}`] [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |
| Pause/ack/checksum safety | `stream_encode_wbtest.mbt` | Repeated `present` returns the same byte; acknowledge commits once; fixed IDAT CRC and Adler recompute correctly; byte pauses cover header/token/EOB/padding/Adler. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,stream_encode_wbtest.mbt}`] |
| Public chunk lifecycle | `stream_encode_test.mbt` | Empty, one-byte, and irregular leases report accepted-prefix totals; `Finished` and first lease `Failed(error)` replay unchanged; no previous lease is retained. Run with `FixedOrStored`. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,stream_encode_test.mbt}`] |
| Four-target requirement coverage | existing PNG package suite | Run the optimized focused selectors and complete PNG package suite on js, wasm, wasm-gc, and native; do not create a Phase 34 corpus/benchmark runner here. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`] |

Suggested commands after implementation:

```powershell
moon -C modules/mb-image test png --target native --frozen -f '*fixed*'
moon -C modules/mb-image test png --target native --frozen
moon -C modules/mb-image test png --target js --frozen
moon -C modules/mb-image test png --target wasm --frozen
moon -C modules/mb-image test png --target wasm-gc --frozen
moon -C modules/mb-image test png --target native --frozen
```

These use the package's declared four targets; the planner should replace the focused selector with the final test names introduced by the implementation. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`]

## Sources

### Primary (HIGH confidence)

- Codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt,png.mbt}` — current strategy seam, exact stored preflight, machine state, frame emission, acknowledgement, eager/chunk wiring.
- Codebase: `modules/mb-image/png/{deflate_bits.mbt,deflate_huffman.mbt}` — existing LSB bit-reader and canonical/reversed Huffman code precedent.
- Codebase: `modules/mb-image/png/{encode_test.mbt,encode_wbtest.mbt,stream_encode_test.mbt,stream_encode_wbtest.mbt}` — current byte, admission, progress, terminal, and private-machine regression shapes.
- Codebase: `.planning/phases/32-png-compression-strategy-and-compatibility/{32-RESEARCH.md,32-01-SUMMARY.md,32-VERIFICATION.md}` — frozen public seam and Phase 33 handoff.
- Codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `AGENTS.md` — phase scope, exclusions, requirements, and project constraints.

### Secondary (MEDIUM confidence)

- [RFC 1951](https://www.rfc-editor.org/rfc/rfc1951.html) — DEFLATE packing, block types, fixed code lengths, EOB, length/distance coding, and stored alignment.
- [PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — zlib IDAT structure, chunk ordering/length framing, CRC range, and Adler relationship.

### Tertiary (LOW confidence)

- A1-A2 in the Assumptions Log. They require plan-review confirmation before exact deterministic bytes and work limits are frozen.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — existing MoonBit PNG package and no new dependency. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`]
- Architecture: HIGH — Phase 32 configuration seam and Phase 29/30 machine/acknowledgement ownership contract are implemented and verified. [VERIFIED: codebase: `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`, `modules/mb-image/png/stream_encode.mbt`]
- Bit/format semantics: MEDIUM — cross-checked official RFC 1951 and PNG Specification through the research seam after Context7 CLI was unavailable. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] [CITED: https://www.w3.org/TR/png-3/]
- Matcher/work policy: HIGH — review adopted A1/A2 as the private deterministic matcher and logical-work contract; Phase 33 tests must preserve both. [RESOLVED]

**Research date:** 2026-07-22  
**Valid until:** 2026-08-21 (repository-local phase; revisit if a Phase 33 `CONTEXT.md` is added).
