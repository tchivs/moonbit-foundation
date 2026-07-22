---
phase: 20-png-structural-safety-gate
plan: "05"
subsystem: png-structural-safety
tags: [png, audit, structural-validation, generated-fixtures, portable-targets]
requires:
  - phase: 20-png-structural-safety-gate
    provides: Existing generated structural matrix and isolated Png policy lane
provides:
  - Reproducible current all-target evidence for PNG-01 through PNG-03
  - Audit boundary between Phase 20 structural validation and Phases 21-25 decode, encode, and colour features
affects: [png, phase-21-deflate-and-raster, phase-22-png-encode, phase-23-png-colour]
tech-stack:
  added: []
  patterns: [read-only regression audit, generated vector freshness, isolated package-policy evidence]
key-files:
  created:
    - .planning/phases/20-png-structural-safety-gate/20-05-SUMMARY.md
  modified: []
decisions:
  - "Treat the current image-returning decoder, PngEncoder, legal DEFLATE/raster behavior, and colour-profile paths as later Phase 21-25 scope after structural validation succeeds."
  - "Do not reopen completed Phase 20 production work when the generated structural corpus and isolated lane pass unchanged."
metrics:
  duration: 4min
  completed: 2026-07-21
status: complete
---

# Phase 20 Plan 05: PNG Structural Safety Audit Summary

**The existing PNG structural safety gate remains current: its 89 generated hostile cases, public and white-box routes, all four portable targets, and isolated policy lane all passed without a production repair.**

## Performance

- **Tasks:** 2/2 read-only audit tasks
- **Production files modified:** 0
- **Audit result:** no Phase-20 structural regression found

## Audit Evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Structural-vector freshness | PASS | `pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` reported `89 P+W cases`. |
| Portable PNG package tests | PASS | `moon -C modules/mb-image test png --target all --frozen` passed 40/40 on wasm, wasm-gc, js, and native. |
| Isolated Png quality lane | PASS | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` passed actual policy/interface/target/source-order/inventory checks, scoped fail-closed negatives, allowlist, structural and decode vector freshness, colour evidence, four-target tests, and lane isolation. |

## Retained Structural Coverage

- The generator validates every source case has public and white-box routes, then confirms both generated tables match the `cases.json` source and manifest identity/digest.
- `png_test.mbt` executes every public generated record through `ImageDecoder::decode(PngDecoder)` and checks typed category, code, context, and immutable caller-Budget/diagnostics outcomes.
- `structural_wbtest.mbt` executes the matching private table and separately retains the five CRC-precedence cases.
- The public probe test still covers caller-owned prefix `NeedMore(8)`, `NoMatch`, `Match`, and the probe-byte ceiling.
- The current `PngDecoder::decode` begins with `_png_read_stream_transport`; every structural error returns before later metadata, allocation, DEFLATE, raster, or `DecodeResult` work. This is the evolved structural handoff corresponding to the earlier `_png_read_transport` seam.

## Audit Boundary

This audit found no evidence that legal DEFLATE, raster reconstruction, decoded images, `PngEncoder`, expanded colour declarations, or non-sRGB profile preservation bypass structural validation. Those successful capabilities are intentional later Phase 21-25 work, not reopened Phase-20 production debt.

The quality lane emitted 29 existing MoonBit warnings but no errors; they include generated-table unused fields, later PNG profile naming, and later transport/colour fields. The lane passed and this plan intentionally makes no warning, policy, QOI, release, registry, CI, or source repair.

## Task Commits

No per-task commit was created: both tasks were explicitly read-only evidence reproduction and produced no task-owned source or policy changes. The completion metadata commit records this summary and GSD state updates.

## Deviations from Plan

The two audit tasks executed exactly as written: no structural case failed, no case was unrouted from `PngDecoder`, and no production repair was required.

### Close-out Note

`state.advance-plan` could not parse the pre-existing `Plan: Not started` field in `STATE.md`, so it did not advance that legacy position. The other state metadata operations recorded this audit's metric, decision, progress, and session. Per this plan's no-roadmap-change boundary, the automatic roadmap update was reverted and is not included in the completion commit.

## Known Stubs

None. The audit scan found no placeholder behavior in the audited PNG implementation; the sole textual `placeholder` match is a policy assertion that rejects placeholder evidence.

## Self-Check: PASSED

- The audit summary exists at the declared phase path.
- Generator freshness, all-target PNG tests, and the isolated Png quality lane all exited successfully.
- No task commit is expected because the plan performed evidence-only, read-only tasks; the completion metadata commit records this summary and the scoped state updates.
