# Project Milestones: MoonBit Native Foundation

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
