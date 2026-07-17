---
phase: 05-reference-codec-and-release-qualification
plan: "03"
subsystem: ppm-encode-conformance
tags: [moonbit, ppm, streaming, conformance, policy]

requires:
  - phase: 05-reference-codec-and-release-qualification/05-02
    provides: Strict bounded P6 decoder and exact single-image completion
provides:
  - Canonical streaming P6 ImageEncoder with complete pre-write capability validation
  - Provenance-linked deterministic PPM corpus and formatter-clean generator check
  - Exact PPM imports, interface, source order, publication inventory, targets, and negatives
affects: [05-04-public-examples, release-qualification, conformance]

tech-stack:
  added: []
  patterns:
    - Complete capability preflight before the first Writer transition
    - Canonical header and per-logical-row write_all calls with aggregate progress remapping
    - Commutative fixture-manifest generator ordering across image, color, and PPM generators

key-files:
  created:
    - modules/mb-image/ppm/encode.mbt
    - modules/mb-image/ppm/ppm_test.mbt
    - modules/mb-image/ppm/generated_vectors.mbt
    - modules/mb-image/ppm/reference_vectors_wbtest.mbt
    - fixtures/ppm/cases.json
    - scripts/fixtures/Generate-PpmVectors.ps1
  modified:
    - fixtures/manifest.json
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1

key-decisions:
  - "Accept validated padded packed RGB views but emit only logical row bytes, making tight and padded sources byte-identical."
  - "Charge encode work once before output and use private bounded row/header owners so caller budget state is deterministic."
  - "Treat the generated six-file production source list separately from the pinned packer's broader test-inclusive package inventory."

requirements-completed: [QUAL-01, QUAL-03]
duration: 52min
completed: 2026-07-17
status: complete
---

# Phase 5 Plan 3: Canonical P6 Encode and Conformance Summary

**Canonical strict-P6 encoding now validates the complete image contract before output, streams only logical RGB rows, and is backed by deterministic four-target conformance evidence.**

## Accomplishments

- Implemented `ImageEncoder` exclusively in `encode.mbt`, emitting `P6\nW H\n255\n` plus tight logical RGB rows.
- Preserved aggregate completed counts across short progress, no-progress, and backend Writer failures.
- Added four canonical cases, six adversarial case IDs, four fixed chunk schedules, semantic round trips, decode-encode canonicalization, trailing-data relation, and padded-view evidence.
- Registered the exact six-package image order, closed eleven-import PPM DAG, 24-line semantic interface, six production sources, complete package inventory, four targets, and fail-closed synthetic mutations.

## Task Commits

1. **RED encoder contract** - `a6e818f`
2. **Canonical streaming encoder** - `903b47d`
3. **Generated conformance corpus** - `3229683`
4. **Exact policy and Required integration** - `26fa844`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made fixture-manifest generation commutative**
- **Found during:** Full Required verification
- **Issue:** Appending the PPM record after color records made the color generator's `-Check` reorder the shared manifest.
- **Fix:** Fixed canonical order to image, PPM, then color-owned records so every generator can run last with byte-identical output.
- **Files modified:** `scripts/fixtures/Generate-PpmVectors.ps1`, `fixtures/manifest.json`
- **Commit:** `26fa844`

**2. [Rule 3 - Blocking] Added encoder-induced storage interface import**
- **Found during:** Generated semantic-interface classification
- **Issue:** Completing `ImageEncoder` added the public `@storage.ImageView` semantic import, increasing the closed interface from 23 to 24 lines.
- **Fix:** Added the exact generated storage import to the policy interface allowlist.
- **Files modified:** `policy/foundation.json`
- **Commit:** `26fa844`

## Verification

- PPM generator `-Check`: passed with exact UTF-8 no-BOM LF output.
- `moon test --frozen --target all --package moonbit-foundation/mb-image/ppm`: 23/23 per target.
- `moon -C modules/mb-image check --frozen --deny-warn --target all`: passed.
- Full Required lane: passed with 197/197 workspace tests on js, wasm, wasm-gc, and native; exact interfaces/package contents; read-only tracked checkout proof.

## Self-Check: PASSED

- All planned implementation, evidence, policy, and generator files exist.
- Commits `a6e818f`, `903b47d`, `3229683`, and `26fa844` resolve in repository history.
- No TODO, FIXME, host/filesystem/registry dependency, row-padding output, or encoder trait stub remains.

## Next Phase Readiness

- Plan 05-04 can build public portable and Native CLI-shaped examples over the completed strict decoder/encoder without changing codec ownership.

---
*Phase: 05-reference-codec-and-release-qualification*
*Completed: 2026-07-17*
