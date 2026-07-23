# Project Milestones: MoonBit Native Foundation

## v0.24 Indexed PNG Encode (Shipped: 2026-07-24)

**Phases completed:** 3 phases, 3 plans, 4 tasks

**Key accomplishments:**

- Eager Indexed8 palette transparency with one owned alpha table, canonical optional tRNS chunks, and exact public RGBA8 decode-back.
- One explicit Indexed8 chunk factory now reuses the acknowledged PNG machine, with hostile lease parity and independent opaque/transparent wire and public decode qualification.

---

## v0.22 RGBA16 PNG Encode (Shipped: 2026-07-23)

**Phases completed:** 4 phases, 4 plans, 6 tasks

**Key accomplishments:**

- Eager PNG encoding now writes checked packed `rgba16` images as non-interlaced Type-6/16 streams while preserving the generic RGB8/RGBA8 encoder contract.
- Explicit non-interlaced RGBA16 chunk factories now reuse the bounded encoder machine and prove eager parity plus atomic sticky-terminal behavior.
- Explicit eager and caller-buffered RGBA16 Adam7 selectors now emit legal Type-6/16 PNGs while preserving every packed little-endian source lane.
- Independent normal Type-6/16 RGBA16 raster qualification, retained Adam7 and hostile public evidence, and a passing four-target PNG package gate.

---

## v0.21 RGBA16 PNG Decode (Shipped: 2026-07-23)

**Phases completed:** 4 phases, 4 plans, 9 tasks

**Key accomplishments:**

- Packed little-endian U16 RGBA descriptors now provide one strict straight-alpha encoded-sRGB identity and observable eight-byte storage order.
- Eager Type-6/16 PNG decode now preserves every straight-alpha RGBA source lane in packed little-endian rgba16 storage without changing generic RGBA8 decoding.
- Caller-owned PNG chunks can now select exact Type-6/16 RGBA preservation with eager-identical normal and Adam7 results, without changing the generic RGBA8 contract.
- Independent Type-6/16 all-filter and all-pass Adam7 PNG vectors prove byte-exact explicit RGBA16 decoding while generic compatibility stays RGBA8 high-byte-only.

---

## v0.20 High-Precision GrayAlpha Decode (Shipped: 2026-07-23)

**Phases completed:** 3 phases, 3 plans, 4 tasks

**Key accomplishments:**

- An opt-in PNG Type-4/16 decoder now preserves unequal gray and alpha source bytes as packed little-endian graya16 while the generic decoder remains RGBA8-compatible.
- PngChunkDecoder::new_graya16 now exposes the existing Type-4/16 preservation profile through the shared, caller-owned bounded chunk lifecycle.
- 1. [Rule 1 - Bug] Corrected the missing explicit Adam7 final-store branch

---

## v0.19 GrayAlpha8 Adam7 PNG (Shipped: 2026-07-23)

**Phases completed:** 3 phases, 5 plans, 6 tasks

**Key accomplishments:**

- Explicit eager and caller-buffered GrayAlpha8 Adam7 selectors now emit the shared Type-4/8 seven-pass G,A stream while established GrayAlpha8 factories stay byte-identical and non-interlaced.
- GrayAlpha8 Adam7 now has public six-pair framing and ordinary chunk-to-eager parity proof without broadening the shared encoder or later replay/hostile-schedule scope.
- GrayAlpha8 Adam7 replay now rejects any admitted-source mutation before the next caller lease write across all measured compression and filter selections.
- Independent seven-pass Type-4/8 GrayAlpha8 wire evidence now reaches a public U8 RGBA decoder oracle, with frozen GrayAlpha16 Stored/None bytes retained.
- Fresh public GrayAlpha8 Adam7 hostile-drain coverage now proves six selector pairs preserve caller lease ownership and eager identity, with a frozen GrayAlpha16 chunk oracle across all targets.

---

## v0.18 GrayAlpha16 Adam7 PNG (Shipped: 2026-07-23)

**Phases completed:** 3 phases, 7 plans, 3 tasks

**Key accomplishments:**

- Explicit eager and caller-buffered GrayAlpha16 Adam7 factories now emit shared-machine Type-4/16 PNG pass data in Ghi/Glo/Ahi/Alo wire order.
- Public GrayAlpha16 Adam7 selector regressions now prove eager byte identity and caller-buffered parity without expanding the encoder surface.
- 1. [Rule 1 - Test composition] Replaced aggregate selector loops with static per-selector tests
- 1. [Rule 1 - Bug] Stored replay drift bypassed the U16 pre-write guard

---

## v0.17 GrayAlpha16 PNG Interchange (Shipped: 2026-07-23)

**Phases completed:** 3 phases, 4 plans, 8 tasks

**Key accomplishments:**

- Packed U16 GrayAlpha now has a public straight-alpha descriptor identity with byte-accurate checked storage evidence and preserved fail-closed operations.
- Packed U16 straight-alpha GrayAlpha images now encode through explicit bounded eager and caller-buffered Type-4/16 PNG APIs with Ghi/Glo/Ahi/Alo wire fidelity.
- GrayAlpha16 now has focused public regressions proving six-pair atomic admission and zero-write sticky replay drift across the bounded Type-4/16 streaming route.
- Public GrayAlpha16 compatibility evidence now freezes Type-4/16 U16 wire lanes, straight-RGBA8 high-byte decoding, caller-buffered ownership, and five PNG format baselines across all portable targets.

---

## v0.16 Grayscale Alpha PNG (Shipped: 2026-07-23)

**Phases completed:** 3 phases, 4 plans, 6 tasks

**Key accomplishments:**

- Packed U8 straight-alpha Gray+Alpha sources now encode as bounded, non-interlaced PNG type 4 through explicit eager and caller-buffered APIs.
- GrayAlpha8 now has strategy-wide atomic rejection coverage for eager and caller-buffered PNG encoding.
- Public GrayAlpha8 PNG evidence now freezes the type-4 `(13,A7)/(D2,4C)` wire contract, RGBA8 decode canonicalization, hostile chunk ownership, and four-target portability.

---

## v0.15 Gray16 PNG Interchange (Shipped: 2026-07-22)

**Phases completed:** 3 phases, 3 plans

**Key accomplishments:**

- Added explicit eager and caller-buffered U16 Gray16 PNG factories with type-0/16-bit big-endian wire output.
- Routed Gray16 through the established bounded filter, Stored/Fixed/Dynamic planning, atomic admission, and acknowledgement-safe replay path.
- Proved wire-byte fidelity, hostile caller-buffered identity, frozen legacy bytes, and 190/190 PNG tests on each supported target.

**Closeout:** Override closeout for 19 pre-v0.15 debug records and one missing historical quick-task record, documented in `STATE.md`; v0.15 itself passed its milestone audit at 100/100 with no code or verification gaps.

---

## v0.14 Gray8 PNG Interchange (Shipped: 2026-07-22)

**Phases completed:** 3 phases, 3 plans, 6 tasks

**Key accomplishments:**

- Explicit eager and caller-buffered Gray8 factories now produce standards-compliant 8-bit, type-0, non-interlaced Stored PNGs without changing legacy RGB8 or straight-RGBA8 behavior.
- Gray8 strategy factories now use the existing bounded preflight, filter, DEFLATE winner, and acknowledgement-safe replay machine.
- Public Gray8 PNG eager fidelity and caller-buffered eager-byte identity are proven across six strategy pairs and four portable targets.

---

## v0.13 PNG Adam7 Encode (Shipped: 2026-07-22)

**Phases completed:** 3 phases, 4 plans, 5 tasks

**Key accomplishments:**

- Explicit Adam7 selection now shares eager and caller-buffered PNG admission while retaining non-interlaced output and returning a typed pending capability error.
- Generated 5x5 RGB8 and straight-RGBA8 Adam7 encodings now prove exact public eager/chunk decode fidelity, frozen None compatibility, and independent four-target execution.

---

## v0.12 PNG Filter Optimization (Shipped: 2026-07-22)

**Phases completed:** 3 phases, 9 plans, 4 tasks

**Key accomplishments:**

- Additive PNG filter-selection API that preserves the existing filter-None encoder path.
- Deterministic standard PNG None/Sub/Up/Average/Paeth filtering with bounded, acknowledgement-safe planner and replay cursors.
- Stored, FixedOrStored, and DynamicOrFixedOrStored adaptive routes retain one atomic preflight ledger, including declined Dynamic candidate work.
- Generated RGB8 and straight-RGBA8 corpus evidence proves strict Adaptive output-size wins, hostile eager/chunk byte identity, and complete public decode on js, wasm, wasm-gc, and native.

**Closeout:** Audit status `tech_debt`: all 4/4 requirements, 3/3 phases, 4/4 integration links, and 3/3 end-to-end flows passed. The sole non-blocking item is duplicated R1/A1 fixture construction in two public test files; it is intentionally retained to avoid a premature test abstraction.

---

## v0.11 PNG Dynamic Huffman Compression (Shipped: 2026-07-22)

**Phases completed:** 3 phases, 4 plans, 0 tasks

**Key accomplishments:**

- Bounded RFC Dynamic-Huffman PNG planning with strict fixed-or-stored fallback and acknowledgement-safe scalar replay.
- Focused four-target tests close the Dynamic selected-work admission and public replay-drift lease-isolation evidence gaps.
- Public periodic RGB8 and straight-RGBA8 PNG corpus proves strict Dynamic compression wins, eager/chunk determinism, and complete four-target decode fidelity.

**Closeout:** Verified v0.11 product closeout; the archive retains 17 pre-existing historical artifact records (16 legacy debug entries and one missing old quick-task record) already documented as deferred in `STATE.md`. They do not affect the v0.11 audit, which passed 4/4 requirements, 3/3 phase verifications, 5/5 integration handoffs, and 4/4 end-to-end flows.

---

## v0.10 PNG Compression Optimization (Shipped: 2026-07-22)

**Phases completed:** 3 phases, 4 plans, 5 tasks

**Key accomplishments:**

- Additive PNG Stored/FixedOrStored selection factories with independently frozen legacy stored-DEFLATE eager and chunk output.
- 1. [Rule 1 - Bug] Added the fixed DEFLATE block header to replay emission
- Public PNG corpus evidence proves deterministic, strictly smaller FixedOrStored output for flat 32x1 RGB8 and straight-RGBA8 sources on all portable targets.

---

## v0.9 Resumable PNG Encode (Shipped: 2026-07-21)

**Phases completed:** 3 phases, 5 plans, 12 tasks

**Key accomplishments:**

- A private MoonBit PNG byte emitter now preserves canonical stored-DEFLATE output while atomically admitting compatible RGB8 and straight-RGBA8 sources.
- PngEncoder now drains the single private canonical PNG machine through fixed one-byte complete writes with acknowledgement only after success.
- PngEncoder now returns host Writer failures field-for-field and proves its private canonical byte ownership on all four portable targets.
- Public caller-buffered PNG encoding now drains the private canonical byte machine with exact progress, eager-byte parity, lease isolation, and sticky terminal outcomes.
- Public PNG output now proves hostile caller-buffer behavior and drives the sole portable decode-resize-encode workflow to the frozen 78-byte, digest-626208771 result on all four targets.

---

## v0.8 Resumable PNG Decode (Shipped: 2026-07-21)

**Delivered:** A portable, caller-buffered PNG decode API with strict completion, exact progress, sticky terminal failures, and four-target evidence.

**Phases completed:** 3 phases, 5 plans

**Key accomplishments:**

- Preserved eager PNG behavior while replacing its internal transport with one private byte-resumable MoonBit state machine.
- Added public `PngChunkDecoder` with caller-owned input, explicit `finish()`, exact accepted-byte accounting, private-until-success output, and sticky typed errors.
- Proved 3,850 accepted and rejected vectors through public empty, one-byte, and adversarial ragged schedules on all four supported targets.
- Shipped a public chunk-decode → bilinear-resize → eager-encode workflow with identical frozen output evidence on all targets.

**Closeout:** Override closeout for 17 pre-existing historical artifact records: 16 v0.2 release/debug records and one missing historical quick-task record. These do not affect v0.8 verification; the v0.8 audit passed requirements 4/4, phases 3/3, integration 6/6, and flows 2/2.

**What's next:** Define the next code-first milestone; resumable PNG encoding is the leading candidate, while registry and release automation remain deferred.

---

## v0.5 QOI Streaming I/O (Shipped: 2026-07-20)

**Phases completed:** 3 phases, 3 plans, 7 tasks

**Key accomplishments:**

- A private, bounded QOI state machine now accepts arbitrary caller-owned chunks and returns one eager-equivalent image only after explicit strict completion.
- A zero-copy QOI stream encoder now drains eager-identical canonical bytes through arbitrary caller-owned mutable leases with constructor-only resource preflight.
- Generated hostile QOI schedules now prove four-target stream progress, and the single public QOI example performs streaming decode → horizontal flip → streaming canonical encode.

---

## v0.4 Portable Image Interchange (Shipped: 2026-07-20)

**Phases completed:** 8 phases, 12 plans, 27 tasks

**Key accomplishments:**

- Portable checked crop produces independent tightly packed images, while named clockwise rotations preserve every packed RGB/RGBA pixel and normalize output orientation.
- Portable geometry now has adversarial atomic-budget proof, while the existing integer-floor nearest-neighbor mapping is documented and regression-tested across all four targets.
- Straight encoded-sRGB RGBA8 compositing and filters now calculate in linear premultiplied space with deterministic quantization and checked resource semantics.
- Independent linear-premultiplied RGBA8 oracle and public exact-byte vectors now prove alpha-correct processing and atomic rejection behavior across all supported targets.
- One portable public consumer now proves strict PPM decode, nearest resize, RGB/RGBA conversion, alpha-correct source-over, and PPM encode with an exact 17-byte vector on every supported target.
- The public resize-to-opaque-source-over pipeline and its atomic composite budget failure are directly exercised on all four portable targets.
- A native public PPM resize-and-composite workload now has correctness-gated execution and an isolated seven-capture local reproducibility record.
- Portable strict-P6 geometry and alpha-aware filter pipeline with exact 29-byte output and atomic radius-one blur budget coverage.
- Portable, eager QOI 1.0 RGB/RGBA decoding with atomic resource preflight, strict stream validation, and checked spec-derived vectors.
- Pure-MoonBit canonical QOI 1.0 encoding with atomic resource preflight, exact forward-writer progress, and checked all-target byte vectors.
- Independent portable QOI consumer proving fixed in-memory decode, horizontal pixel flip, and canonical re-encode on all four supported targets.
- Exact QOI package policy, fail-closed scoped drift checks, and an isolated four-target qoi-portable quality lane.

---

## v0.3 Image Processing Core (Shipped: 2026-07-20)

**Phases completed:** 4 phases, 8 plans, 17 tasks

**Key accomplishments:**

- Portable checked crop produces independent tightly packed images, while named clockwise rotations preserve every packed RGB/RGBA pixel and normalize output orientation.
- Portable geometry now has adversarial atomic-budget proof, while the existing integer-floor nearest-neighbor mapping is documented and regression-tested across all four targets.
- Straight encoded-sRGB RGBA8 compositing and filters now calculate in linear premultiplied space with deterministic quantization and checked resource semantics.
- Independent linear-premultiplied RGBA8 oracle and public exact-byte vectors now prove alpha-correct processing and atomic rejection behavior across all supported targets.
- One portable public consumer now proves strict PPM decode, nearest resize, RGB/RGBA conversion, alpha-correct source-over, and PPM encode with an exact 17-byte vector on every supported target.
- The public resize-to-opaque-source-over pipeline and its atomic composite budget failure are directly exercised on all four portable targets.
- A native public PPM resize-and-composite workload now has correctness-gated execution and an isolated seven-capture local reproducibility record.
- Portable strict-P6 geometry and alpha-aware filter pipeline with exact 29-byte output and atomic radius-one blur budget coverage.

---

## v0.1 Foundation (Shipped: 2026-07-17)

**Delivered:** An RFC-led, independently publishable MoonBit foundation spanning bounded core primitives, explicit color semantics, safe image contracts, a strict reference codec, and reproducible release-candidate evidence.

**Phases completed:** 1-5 (41 plans, 93 tasks)

**Key accomplishments:**

- Accepted RFC 0001 and established fail-closed governance, compatibility, target, toolchain, licensing, and publication policy.
- Built independently publishable `mb-core`, `mb-color`, and `mb-image` modules with exact acyclic dependencies and four-target conformance.
- Implemented checked budgets/storage/I/O, typed color and alpha semantics, safe image views, and deterministic foundational operations.
- Proved the public stack with a strict bounded PPM P6 codec plus portable and injected Native stream-transform-stream examples.
- Captured correctness-gated benchmarks and deterministic clean-copy packages; the exact mb-core artifact consumer passes outside `moon.work`.
- Closed release qualification with 19/19 selectors twice at one unchanged HEAD and identical canonical evidence.

**Stats:**

- 295 tracked files changed across the milestone
- 44,481 insertions and 165 deletions from the initial repository commit
- 5 phases, 41 plans, 93 tasks, 36/36 requirements
- 292 commits from 2026-07-16 to 2026-07-17

**Git range:** `a6517dc` → `a902de7`

**Closeout:** Verified closeout; 5/5 phase verifications passed, milestone audit passed, 0 blockers, 0 broken flows.

**What's next:** Verify the mooncakes.io namespace and choose between publishing the v0.1 candidates or opening a new RFC-led milestone.

---

## v0.2 Publication & Compatibility (Deferred: 2026-07-20)

**Status:** Deferred without a registry mutation. Its release qualification and compatibility work remains preserved for a later manual publication effort.

**Reason:** Further retry/recovery automation was no longer the highest-value work. The project is resuming code-first delivery in `mb-image`.

---
