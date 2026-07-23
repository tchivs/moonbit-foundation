# Domain Pitfalls: GrayAlpha8 Adam7 PNG

**Milestone:** v0.19 GrayAlpha8 Adam7 PNG
**Researched:** 2026-07-23
**Confidence:** MEDIUM for PNG-format claims (official PNG specification surfaced through a verified web search); HIGH for repository-specific risks (current source inspection).

## Critical Pitfalls

### 1. Treating Adam7 as a reordered complete raster

**What goes wrong:** An implementation emits Type-4/8 source rows in conventional order, or omits the filter byte at Adam7 pass boundaries. The resulting IHDR may advertise interlace method `1`, yet IDAT does not describe the seven legal subimages.

**Why it happens:** A non-interlaced Type-4/8 image is exactly two bytes per pixel (`G,A`) and ordinary row math is tempting to reuse. Adam7 is not merely a different row stride: each non-empty pass has its own `(x, y, dx, dy, width, height, row_bytes)` and scanlines are ordered pass-by-pass.

**Consequences:** Valid-looking bytes decode to misplaced gray/alpha samples, fail independent decoders, or work only for symmetric/constant test images. Tiny and ragged dimensions can hide missing passes.

**Prevention:** Derive every preflight total, logical cursor lookup, filter tag, and raw `G,A` lookup from the existing single `_png_adam7_passes(..., channels=2, bit_depth=8)` authority. Add a public asymmetric 5x5-or-larger vector that visits all seven passes and assert exact `IHDR = 8/4/0/0/1`, exact filtered pass stream, and decoded `(gray, alpha)` pairs.

**Detection:** Fail the phase if a pass has no filter tag, if a scalar logical position resolves outside the seven-pass total, or if a test only uses 1x1/constant fixtures. Cross-check emitted output with the existing public PNG decoder rather than only comparing eager with chunk output.

### 2. Carrying Adaptive predictor history across an Adam7 pass

**What goes wrong:** `Up`, `Average`, or `Paeth` treats the preceding row of a different pass as its upper neighbor, or a selected filter survives into the next pass.

**Why it happens:** The streaming cursor has one monotonic byte index, while filtering needs local row context. In ordinary PNG, an `Up` predecessor is simply the prior source row; Adam7 changes that predecessor to the prior row *within the same pass*.

**Consequences:** Adaptive output can be deterministic but non-conforming; a decoder will reconstruct different samples. It may affect only pass transitions and evade full-sized RGB/RGBA regressions.

**Prevention:** Make pass-local row number the only source of `up`/`upper_left` eligibility; reset the filter winner at each pass's first row. Score all five PNG filter candidates against the pass-local wire row, then retain the winner only until that row's payload is acknowledged. Preserve the existing deterministic tie-break (`None` on equal scores).

**Detection:** Exercise `None` and `Adaptive` for Stored, FixedOrStored, and DynamicOrFixedOrStored with a deliberately irregular GrayAlpha8 image. Assert pass-transition filter tags and exact eager/chunk identity, then decode to original samples.

### 3. Giving Adam7 a second admission path

**What goes wrong:** New GrayAlpha8 Adam7 factories calculate a partial pass total or choose a compression plan after construction, bypassing the existing resource ledger. A failing request can then reserve budget, read source pixels, construct an encoder, or expose bytes before rejection.

**Why it happens:** It is easy to add an interlace-special encoder constructor next to the established non-interlaced GrayAlpha8 factory, then let its planner evolve independently.

**Consequences:** Capability/limit/budget errors are no longer atomic and caller-buffered semantics differ by strategy. This is a correctness and hostile-input regression even if successful PNG files decode.

**Prevention:** Admit the explicit GrayAlpha8 Adam7 selector only by relaxing the profile gate in the shared profile-aware preflight. Keep one scalar scanline count consisting of each nonempty pass's `(row_bytes + 1) * pass_height`; run all Stored/Fixed/Dynamic candidates and final replay through it before any `PngChunkEncoder` state or lease write exists.

**Detection:** For all six compression/filter pairs, use incompatible descriptors plus width, height, byte, IDAT, and budget limits that fail at distinct ledger stages. Assert constructor failure, unchanged budget, no accepted output, and no live encoder/lease exposure.

### 4. Mutating the admitted source before a caller lease is written

**What goes wrong:** A GrayAlpha8 source view changes after preflight and before/during `pull()`. The chunk encoder writes one or more bytes from an unadmitted replay before recognizing that the source no longer matches the plan.

**Why it happens:** Fixed and Dynamic DEFLATE replays repeatedly inspect source-derived logical bytes. Acknowledgement-safe presentation protects internal cursor commits, but it does not by itself validate mutable source state before `destination.set`.

**Consequences:** A supposedly atomic stream leaks unplanned output, later retries can differ, and error results are not sticky. The defect is schedule-dependent and particularly easy to miss with an eager-only test.

**Prevention:** Reuse the pre-lease source-revision guard for every Type-4/8 replay plan, including Stored. On detected drift, transition to one sticky terminal error before inspecting or modifying the current lease; maintain accepted-only `total_written`. Do not introduce an Adam7-only staging buffer or a copied source tree.

**Detection:** For every legal `None/Adaptive × Stored/FixedOrStored/DynamicOrFixedOrStored` Adam7 selector, admit an encoder, acknowledge framing into a sentinel lease, mutate the view, then pull a second sentinel lease. Assert zero writes, unchanged sentinel tail and total, and the identical terminal error on a later pull.

### 5. Confusing IDAT, DEFLATE, pass, and caller-lease boundaries

**What goes wrong:** Streaming code assumes a pass row fits a caller lease, aligns an IDAT chunk with a deflate block, or commits a filter/decompression cursor when a preview is merely presented.

**Why it happens:** PNG defines a single zlib stream over concatenated IDAT payloads; its format has no semantic alignment between IDAT chunks, deflate blocks, or scanlines. Adam7 further introduces small and empty passes.

**Consequences:** Zero-capacity pulls may mutate state; one-byte/ragged leases can lose/duplicate filter bytes; the same encoder produces a different stream from its eager peer.

**Prevention:** Keep the current preview/acknowledge contract: a preview is private until the byte is successfully placed in the caller's lease. Do not add pass buffers. The logical byte cursor must be the sole replay source for all lease sizes.

**Detection:** Drain newly constructed eager and chunk encoders with zero, one-byte, and ragged schedules for each strategy pair. Assert the first zero-capacity pull is a no-op, output is byte-for-byte eager-identical, totals advance only by accepted bytes, and a final pull is stably finished.

### 6. Accidentally broadening compatibility while enabling the opt-in

**What goes wrong:** Existing GrayAlpha8 non-interlaced factories begin selecting Adam7, old `None` bytes change, or unrelated Gray8/Gray16/RGB8/RGBA8 routes are changed while opening the Type-4/8 opt-in.

**Why it happens:** The generic profile/machine and public factory overloads have shared switch points. A broad default change appears to reduce duplicate code but silently redefines stable contracts.

**Consequences:** Downstream checksum, snapshot, and interoperability baselines break despite no source-level API error.

**Prevention:** Add only explicit eager and caller-buffered GrayAlpha8 interlace selectors; keep existing factories wired to `PngInterlaceStrategy::None`. Retain existing descriptor admission and straight-alpha metadata. Do not legalize unrelated Gray8/Gray16 Adam7 routes in this milestone.

**Detection:** Freeze existing non-interlaced GrayAlpha8 bytes and at least one Gray8, Gray16, RGB8, and RGBA8 vector. Check both legacy constructors and their explicit `None` selector peers against their historical bytes.

### 7. Treating native success as portability evidence

**What goes wrong:** The implementation or test suite passes only under native because integer conversion, mutable lease behavior, compile-time visibility, or test filtering differs on `js`, `wasm`, and `wasm-gc`.

**Why it happens:** Adam7 pass totals and one-byte replay paths exercise checked arithmetic and state transitions more densely than normal row encoding. Native's toolchain and optimizer can conceal a portability issue.

**Consequences:** The public portable contract is unproven and a release can regress non-native consumers.

**Prevention:** Keep all traversal/filter/preflight/replay logic in portable MoonBit packages and run the complete public PNG package under all four targets from one unchanged commit.

**Detection:** Require the named GrayAlpha8 Adam7 public vectors to pass on `wasm`, `wasm-gc`, `js`, and `native`; preserve a separate all-target frozen-compatibility selector so new tests cannot mask an old-route regression.

## Moderate Pitfalls

### 8. Testing only image fidelity, not wire contract

**What goes wrong:** A decoder round trip passes after both encoder and decoder make the same mapping error.

**Prevention:** Assert IHDR fields, pass-order filtered bytes (or a compact verified wire digest), `G,A` sample ordering, and independent decoder reconstruction. Use nonsymmetric gray/alpha values so channel swaps cannot pass.

### 9. Treating empty Adam7 passes as malformed or materializing them

**What goes wrong:** Small dimensions trigger invalid zero-row filters or produce phantom filter bytes; alternatively arrays are allocated for every pass regardless of geometry.

**Prevention:** Skip only zero-width or zero-height passes in the shared authority, with no scanline/filter contribution and no pass-buffer allocation. Test zero/tiny/ragged legal dimensions separately from the all-seven-pass reference image.

### 10. Replacing bounded traversal with a convenience buffer

**What goes wrong:** A new `Array`/byte buffer gathers all GrayAlpha8 Adam7 rows before filtering or compression.

**Prevention:** Preserve the scalar cursor and per-byte lookup path already used by RGB/RGBA and GrayAlpha16 Adam7. Benchmarks are optional; bounded allocation and atomic behavior are non-negotiable.

## Phase-Specific Warnings

| Phase topic | Likely pitfall | Mitigation |
|-------------|---------------|------------|
| Factory/profile enablement | Relaxing all grayscale gates instead of only GrayAlpha8 | Explicit Type-4/8 Adam7 selectors, existing constructors remain `None` |
| Pass traversal | Wrong `channels=2`/pass-row math or phantom empty-pass rows | One `_png_adam7_passes` source and asymmetric all-seven-pass wire test |
| Adaptive filtering | Cross-pass predictor history | Pass-local row coordinates and filter-winner reset |
| Compression preflight | Strategy-specific or late admission | One profile-aware ledger before source work/output for all six pairs |
| Chunk replay | Lease writes before mutation rejection | Pre-lease revision guard and sticky failure checks for Stored, Fixed, Dynamic |
| Compatibility | Non-interlaced byte drift | Frozen legacy fixtures plus explicit-`None` parity |
| Portability | Native-only evidence | Full package tests on js, wasm, wasm-gc, native at unchanged HEAD |

## Sources

- [PNG Specification, Second Edition — interlacing, filtering, and IDAT structure](https://www.libpng.org/pub/png/spec/iso/index-object.html) — MEDIUM via verified search; format requirements independently corroborated by the implementation's existing Adam7 paths.
- [PNG Specification 1.2 — Data Representation and Adam7 pass order](https://libpng.org/pub/png/spec/1.2/PNG-DataRep.html) — MEDIUM via verified search.
- [PNG Specification 1.2 — Filter Algorithms](https://www.libpng.org/pub/png/spec/1.2/PNG-Filters.html) — MEDIUM via verified search; explicitly states that an interlaced pass is an independent image for filtering.
- [W3C PNG Third Edition — IDAT/zlib stream relationship](https://www.w3.org/TR/png-3/) — MEDIUM via verified search.
- [libpng manual — Adam7 pass-wise handling](https://www.libpng.org/pub/png/libpng-1.0.3-manual.html) — MEDIUM via verified search; used only as implementation corroboration.
- Current repository inspection: `modules/mb-image/png/encode.mbt` and `modules/mb-image/png/stream_encode.mbt` — HIGH for existing shared traversal, preflight, and replay seams.
