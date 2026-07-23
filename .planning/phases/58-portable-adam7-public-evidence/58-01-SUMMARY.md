---
phase: 58
plan: "01"
subsystem: png-eager-public-evidence
tags: [png, adam7, graya16, public-api, regression]
requires: [Phase-56-public-Adam7-factories, Phase-57-bounded-Adam7-semantics]
provides: [public-Type-4-16-Adam7-wire-evidence, public-RGBA8-high-byte-decode-evidence]
affects: [modules/mb-image/png/encode_test.mbt]
tech-stack:
  added: []
  patterns: [bounded-Stored-IDAT-parser, public-PngDecoder-canonicalization, frozen-method-0-literals]
key-files:
  created: []
  modified: [modules/mb-image/png/encode_test.mbt]
decisions:
  - "The Stored/None parser remains bounded and requires its caller to declare the known filtered-payload length."
  - "U16 Adam7 decode evidence observes only the public straight-RGBA8 high-byte contract."
metrics:
  duration: "~20 minutes"
  completed: "2026-07-23"
status: complete
---

# Phase 58 Plan 01: Public GrayAlpha16 Adam7 Eager Evidence Summary

Public PNG output now proves the full non-symmetric 5×5 GrayAlpha16 Adam7 pass wire and every decoded straight-RGBA8 high-byte pixel.

## Completed Tasks

1. Added a public Stored/None Adam7 regression that checks Type-4/16/interlace-1 framing, parses the complete independently derived 111-byte seven-pass raster, and validates all 25 public decoder pixels.
2. Extended every legal eager compression/filter pair with the 5×5 public decoder oracle and made the five frozen legacy eager vectors explicitly assert method 0.

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 public wire and decode'` — passed (1/1).
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 public eager evidence'` — passed (1/1).
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG filter strategy eager frozen compatibility vectors'` — passed (1/1).

## Commits

- `86cca84` — RED public wire/decode regression.
- `65bb767` — bounded public Stored payload parser and 111-byte pass proof.
- `ad529c4` — six-selector public decode evidence and explicit frozen method-0 assertions.

## Deviations from Plan

None — no production encoder, decoder, API, fixture, staging path, Big-endian route, or target-specific behavior was added.

## Self-Check: PASSED

- `modules/mb-image/png/encode_test.mbt` contains only public eager evidence additions for this plan.
- All three task commits exist in the current history.
