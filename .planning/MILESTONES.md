# Project Milestones: MoonBit Native Foundation

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
