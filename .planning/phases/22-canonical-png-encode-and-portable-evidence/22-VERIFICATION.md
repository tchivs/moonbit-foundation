---
phase: 22-canonical-png-encode-and-portable-evidence
verified: 2026-07-20T18:12:44Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 22: Canonical PNG Encode and Portable Evidence Verification Report

**Phase Goal:** Library users can create deterministic PNG output and independently verify supported PNG interoperability through portable public evidence.
**Verified:** 2026-07-20T18:12:44Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A compatible RGB8 or straight-RGBA8 view encodes to one documented deterministic PNG sequence after eager-equivalent preflight. | ✓ VERIFIED | `PngEncoder` is public in `png.mbt` and implements `@codec.ImageEncoder` in `encode.mbt:254`. Its source checks strict format/metadata/layout, constructs filter-None scanlines, stored-DEFLATE, and canonical IHDR/IDAT/IEND before the only Writer call at `encode.mbt:305`. Four-target PNG tests passed exact RGB/RGBA bytes, structural checksums, repeat stability, and round trips. |
| 2 | Incompatible source, limit, budget, and setup failures cannot write output. | ✓ VERIFIED | All source, checked arithmetic, framing, limit, and budget error paths return before `encode.mbt:305`; `_png_encode_write` first creates its owned byte view before it invokes `@io.write_all`. The all-target test `PNG encoder rejects output and budget limits before Writer output` asserts zero writer position for output-limit, work-budget, and semantic failures; the Writer-progress test asserts requested/completed accounting after partial progress. |
| 3 | A public portable PNG decode → existing operation → encode workflow produces deterministic evidence. | ✓ VERIFIED | `examples/png-portable/main/main.mbt:57-82` uses only public `@codec`, `@png`, and `@ops` contracts, decodes a fixed PNG, runs `flip_horizontal`, encodes it, then checks dimensions, read/write lengths, all 75 expected output bytes, and digest `548592766`. Each of js, wasm, wasm-gc, and native printed the identical evidence line. |
| 4 | Supported fixtures and hostile PNG cases have identical expected behavior on js, wasm, wasm-gc, and native. | ✓ VERIFIED | `png_test.mbt:292-332` executes generated fixed/dynamic decode vectors and asserts accepted pixels or typed limit/data errors; `generated_decode_vectors_test.mbt` includes hostile zlib-header, truncated-deflate, Adler, filter, incomplete-tree, distance, and expansion cases. `moon -C modules/mb-image test png --target all --frozen` passed all 18 tests on each required target. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | Pure-MoonBit stored-DEFLATE `PngEncoder` implementation | ✓ VERIFIED | Exists (314 lines), has no stub/debt markers, builds canonical scanlines/zlib/chunks with CRC-32 and Adler-32, performs limit/budget checks, and is wired by the public `ImageEncoder` implementation. |
| `examples/png-portable/main/main.mbt` | Public decode-operation-encode PNG evidence executable | ✓ VERIFIED | Exists (83 lines), has no stub/debt markers, is registered in `moon.work`, imports only portable public packages, and runs against non-empty fixed PNG input with whole-output evidence assertions. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | `modules/mb-image/png/encode.mbt` | `PngEncoder` implements `ImageEncoder` | ✓ WIRED | Public `PngEncoder`/`new()` are declared in `png.mbt:14-18`; implementation is `pub impl @codec.ImageEncoder for PngEncoder` at `encode.mbt:254`; generated public interface exposes both at `pkg.generated.mbti:23-26`. |
| `examples/png-portable/main/main.mbt` | `modules/mb-image/png/png.mbt` | public decoder → operation → encoder calls | ✓ WIRED | The example imports `tchivs/mb-image/png`, invokes `@png.PngDecoder::new()` at line 58, `@ops.flip_horizontal` at line 63, and `@png.PngEncoder::new()` at line 70 through `@codec` seams. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `examples/png-portable/main/main.mbt` | `decoded` → `flipped` → `encoded`/writer bytes | Fixed valid 2×1 PNG literal → public decoder → `flip_horizontal` → public encoder | Yes — output is compared byte-for-byte with a distinct 75-byte expected PNG and digest. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Encoder bytes, zero-write preflight, Writer progress, and hostile decode fixtures on all portable targets | `moon -C modules/mb-image test png --target all --frozen` | 18/18 passed on wasm, wasm-gc, js, and native | ✓ PASS |
| Public decode → flip → encode evidence on every portable target | `moon -C examples/png-portable run main --target {js,wasm,wasm-gc,native} --frozen` | Every target printed `example=png-portable bytes_read=75 bytes_written=75 width=2 height=1 flip_horizontal digest=548592766` | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 22 declares no probe, PASS-marker, stage-marker, or `probe-*.sh` contract; no conventional probe was present.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNG-06 | `22-01-PLAN.md` | Deterministic RGB8/straight-RGBA8 encode after eager-equivalent zero-write preflight | ✓ SATISFIED | Public encoder contract, exact-byte/RGB-RGBA/round-trip tests, zero-position Writer assertions, and four-target package test. |
| PNG-07 | `22-01-PLAN.md` | Portable decode → image operation → encode workflow plus four-target fixture/hostile evidence | ✓ SATISFIED | Public example with exact output/digest and four identical target outputs; package test includes generated hostile vectors on all targets. |

No Phase 22 requirements are orphaned: both roadmap IDs are declared in the plan and have implementation evidence.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, empty-render, or hardcoded-empty-output stub pattern found in Phase 22 product/test/example files. | ℹ️ Info | No blocker or warning. |

### Disconfirmation Pass

- **Partial-requirement check:** The encoder defers `CodecLimits` comparisons until after it constructs the complete canonical byte representation, but all failures still occur before its only Writer call. This satisfies the phase's zero-write/eager-equivalent contract; it is not an unwired or output-visible partial implementation.
- **Misleading-test check:** Exact output is not accepted on decode success alone: the public test compares all expected bytes and the white-box test independently verifies chunk framing, stored-block fields, CRC-32, and Adler-32.
- **Uncovered-error-path check:** The scripted Writer test covers partial progress then failure, while `@io.write_all` independently covers no-progress and bounded-writer completion propagation. No Phase 22 error path was found that reaches the Writer before the encoder's preflight/charge gates.

### Gaps Summary

No blocking gaps found. The phase goal is achieved by substantive public API wiring, deterministic byte evidence, hostile-fixture coverage, and actual four-target execution.

---

_Verified: 2026-07-20T18:12:44Z_
_Verifier: the agent (gsd-verifier)_
