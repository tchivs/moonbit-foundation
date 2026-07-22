---
phase: 55
slug: portable-public-evidence
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-07-23
---

# Phase 55 — Security

**Verdict:** SECURED

Phase 55 changes public PNG regression evidence only. The audit verified every declared mitigation against the submitted test code; no production or test code was changed during this audit.

## Threat Verification

| Threat ID | Category | Severity | Disposition | Status | Evidence |
|---|---|---:|---|---|---|
| T-55-01 | Tampering | high | mitigate | closed | `encode_test.mbt:180-211` constructs only the legal little-endian non-symmetric U16 corpus. `encode_test.mbt:1067-1084` invokes the public Stored/None factory and asserts the PNG signature, Type-4/depth-16/non-interlaced framing, and literal `00 12 34 A7 C5 BE 0F 5A 76` scanline. `encode_test.mbt:480-508` decodes through `ImageDecoder::decode(PngDecoder::new(), ...)` and asserts straight RGBA8 high-byte results. `encode_test.mbt:1126-1137` repeats framing and decode proof for all six strategy/filter pairs. |
| T-55-02 | Tampering | high | mitigate | closed | `stream_encode_test.mbt:710-760` creates a fresh public chunk encoder per drain; it appends only accepted bytes, requires cumulative accepted-only progress, checks every unwritten `Z` tail byte, compares to a fresh eager oracle, and probes an unchanged successful terminal lease. `stream_encode_test.mbt:1294-1328` crosses all three compression strategies with both filters, performs a direct zero-capacity pull, and independently drives zero/one and ragged schedules. |
| T-55-03 | Tampering | high | mitigate | closed | Literal complete PNG baselines are asserted, without another current encoder as oracle, for Gray8, Gray16, GrayAlpha8, RGB8, and straight RGBA8 in `encode_test.mbt:874-977` and `stream_encode_test.mbt:1374-1470`. Phase 55 adds the missing GrayAlpha8 literal to both eager and chunk sets while retaining the other four frozen vectors. |
| T-55-04 | Denial of Service | medium | mitigate | closed | The qualifying code is portable MoonBit in the two PNG package tests: no native branch, FFI, or target-specific conditional appears in the submitted Phase 55 diff. The exact package command is `moon -C modules/mb-image test png --target all --frozen`; the executor recorded 204/204 tests on wasm, wasm-gc, js, and native in `55-01-SUMMARY.md:71-76`. This audit independently reran native: 204/204 passed. A new all-target foreground run was unable to complete before the local command window elapsed because another shared `moon` process owns `_build/.moon-lock`; the lock was left untouched. |
| T-55-05 | Tampering | high | mitigate | closed | `encode_test.mbt:1087-1110` constructs a packed Big-endian U16 GrayAlpha descriptor and requires descriptor construction to fail before PNG admission. The added evidence fixtures use `ImageFormat::graya16()` and set low/high component bytes in the legal little-endian order in `encode_test.mbt:182-211` and `stream_encode_test.mbt:176-205`; the Phase 55 diff introduces no Big-endian source fixture. |

## Threat Flags

None. `55-01-SUMMARY.md` contains no `## Threat Flags` section, so execution reported no unmapped attack surface.

## Verification

| Command | Result |
|---|---|
| `git diff --check af47151^..c8267c9` | passed |
| `moon -C modules/mb-image test png --target native --frozen` | passed: 204/204 |
| `moon -C modules/mb-image test png --target all --frozen` | executor evidence: passed 204/204 on wasm, wasm-gc, js, and native; audit rerun contended on the shared `_build/.moon-lock` and was not allowed to modify it |

## Verdict

**SECURED** — all five declared `mitigate` controls are present in the correct public evidence seams. No accepted or transferred risks are declared, no unregistered threat flag is present, and no blocking or non-blocking threat remains open.

**threats_open:** 0
