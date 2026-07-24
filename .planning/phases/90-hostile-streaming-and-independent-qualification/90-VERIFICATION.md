---
phase: 90-hostile-streaming-and-independent-qualification
verified: 2026-07-24T18:00:00+08:00
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 90 Verification Report

**Phase Goal:** Adam7 FixedOrStored output is trustworthy under hostile leases, independently parseable/decodable, compatibility-safe, and portable.

## Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Fixed Adam7 eager and chunk-origin bytes are equal under zero/one/ragged leases. | VERIFIED | `PNG indexed Adam7 FixedOrStored independent wire and decode qualification` uses `[0,1,3,2,5]` and compares collected bytes to eager output. |
| 2 | Only accepted bytes advance totals and sentinel tails remain unchanged. | VERIFIED | `png_phase90_fixed_adam7_chunk` checks written/total invariants, zero-capacity sentinel, and every unaccepted tail byte. |
| 3 | Finished pulls are sticky zero-write results and released leases are sticky zero-write failures. | VERIFIED | The hostile helper replays Finished; the dedicated released-lease test compares error identity and untouched sentinel leases. |
| 4 | Independent parsing proves chunk order/CRC, canonical PLTE/tRNS, Fixed DEFLATE, Adler-32, and pass raw lengths/tails. | VERIFIED | `png_phase90_parse_fixed_adam7` performs all checks without production planning/matching/packing/frame helpers. |
| 5 | Public decode produces RGBA8 for transparent palettes and RGB8 for opaque palettes. | VERIFIED | The qualification matrix runs both variants for depths 1/2/4/8 and checks dimensions, channels, palette values, and alpha. |
| 6 | Existing Stored/replay compatibility remains green. | VERIFIED | Full package gate includes the prior Stored Adam7, replay, and v0.28 compatibility tests. |
| 7 | All declared targets pass the ordinary package gate. | VERIFIED | Native, wasm, wasm-gc, and js each report 320/320 passed. |

**Score:** 7/7 truths verified.

## Required Checks

| Command | Result |
| --- | --- |
| `moon check modules/mb-image/png --target all` | Passed; warnings only |
| `moon test modules/mb-image/png --target all` | **320 passed / 0 failed** on native, wasm, wasm-gc, js |
| `git diff --check` | Passed |

## Scope Fence

Only test qualification code and GSD artifacts changed in Phase 90. No Dynamic/adaptive profile, staging, second encoder, source-model change, decoder production change, FFI, copied tree, or release automation was added.

## Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| ADAM7COMP-04 | SATISFIED | Hostile accepted-only progress, sentinel preservation, sticky Finished, and released-lease failure tests. |
| ADAM7COMP-05 | SATISFIED | Independent wire/DEFLATE/CRC/Adler/pass parser, RGB/RGBA decode matrix, compatibility suite, and four-target gate. |

## Gaps Summary

None. The v0.29 phase requirements are complete; milestone-level audit and archive are the remaining GSD actions.

---
_Verified: 2026-07-24_
