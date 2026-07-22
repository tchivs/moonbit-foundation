---
status: resolved
trigger: "Phase 46 generated 5x3 Gray8 public eager fidelity test exits native PNG black-box test with 0xc0000409 before assertions."
created: 2026-07-22
updated: 2026-07-22
---

# Debug: Phase 46 Gray8 Fidelity Work Limit

## Symptoms

- Expected: the new public Gray8 generated-source round trip passes for Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive filtering.
- Actual: `moon -C modules/mb-image test png --target native --frozen` exits `0xc0000409` after adding the test.
- Reproduction: run the exact native PNG package command with the uncommitted Phase 46 eager test addition.
- Timeline: the baseline 179-test native suite passed before this test; the failure began with the six-strategy 5x3 fidelity loop.

## Current Focus

hypothesis: "Confirmed: the public decode succeeds, but the generic RGB/RGBA fidelity helper rejects its canonical RGB8 result because it requires the decoded descriptor to equal the one-channel Gray source."
next_action: "Resolved: retain the Gray8-specific fidelity assertion and decoder canonicalization contract."

## Evidence

- timestamp: 2026-07-22
  observation: "Phase 43 resolved the identical native exit by replacing its legacy 1,024-unit eager evidence helper with test-local 1,048,576-unit limits/budget; the normal error context was `work`."
- timestamp: 2026-07-22
  observation: "The original focused native Gray8 fidelity test reproduces the `0xc0000409` process exit. A temporary Result-returning probe ran FixedOrStored and DynamicOrFixedOrStored with both None and Adaptive filters under the unmodified 1,024-unit eager limits/budget; all four results were `Some(success)`, not `Some(work)`. The temporary probe was removed."
- timestamp: 2026-07-22
  observation: "Focused public isolation: direct `PngDecoder::decode` succeeds for all six Gray8 strategy/filter pairs; dimensions match the 5x3 source. The decoded descriptor is canonical RGB8 (Rgb, 3 channels), not Gray (1 channel)."
- timestamp: 2026-07-22
  observation: "The final focused native test passes after replacing the generic descriptor-equality helper with Gray8-specific assertions: source Gray/1, IHDR bit depth 8 + colour type 0 + non-interlaced, dimensions preserved, and each decoded RGB component equals the original gray sample."

## Eliminated


## Resolution

root_cause: "The new Gray8 test used a generic helper that assumes decoder descriptor equality. PngDecoder intentionally canonicalizes grayscale input to RGB8, so the helper aborts when its one-channel expectation disagrees with the decoder's three-channel output."
fix: "Applied a Gray8-specific public fidelity assertion: retain the source/PNG one-channel contract, assert decoder RGB8 canonicalization, and compare each source gray sample with all three decoded components."
verification: "Focused native command passes: `moon -C modules/mb-image test png --target native --frozen -f \"PNG Gray8 eager strategy pairs decode generated samples faithfully\"`. Full native suite passes: `moon -C modules/mb-image test --target native --frozen` (436 passed, 0 failed)."
files_changed:
  - modules/mb-image/png/encode_test.mbt
  - .planning/debug/phase46-gray8-fidelity-work.md
