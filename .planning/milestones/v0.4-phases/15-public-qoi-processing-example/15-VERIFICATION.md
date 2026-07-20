---
phase: 15-public-qoi-processing-example
verified: 2026-07-20T11:56:58Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/3
  gaps_closed:
    - "The public status line and README now identify the checked canonical bytes with the correct, computed SHA-256."
  gaps_remaining: []
  regressions: []
---

# Phase 15: Public QOI Processing Example Verification Report

**Phase Goal:** Library users can independently follow an end-to-end portable QOI workflow that demonstrates interoperability with the existing image operations.
**Verified:** 2026-07-20T11:56:58Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can run one public documented example that decodes QOI, applies an existing image operation, encodes QOI, and produces deterministic output evidence. | ✓ VERIFIED | All four exact frozen runs execute the public decode → `flip_horizontal` → encode pipeline and emit the same checked evidence line, including `sha256=5dc3abfe81e722b211af255f6f96805225f98435f1f9525c46df48217f858df2`. |
| 2 | The example uses only the public portable image, codec, I/O, and budget contracts, so it runs without GUI state, FFI, or a platform-specific codec dependency. | ✓ VERIFIED | The standalone module declares `+js+wasm+wasm-gc+native`; its executable package imports only public `mb-core/{budget,bytes,error,io}` and `mb-image/{codec,ops,qoi}` packages. |
| 3 | The consumer proves dimensions, flipped pixel positions, decode/encode byte progress, empty diagnostics, exact output bytes, deterministic digest, and output identity before its only status line. | ✓ VERIFIED | `main.mbt` asserts dimensions, the six transformed RGB bytes, read/write progress, writer position, diagnostics, canonical bytes, rolling digest, and a computed SHA-256 over the actual writer bytes before `println`. A native rerun produced exactly one normal-output line. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/qoi-portable/moon.mod.json` | Independent portable QOI example module | ✓ VERIFIED | Exists, substantive, and declares a separate portable module with public `mb-core` and `mb-image` dependencies. |
| `examples/qoi-portable/main/moon.pkg` | Public executable imports | ✓ VERIFIED | Exists, substantive, and imports only the public packages needed by the consumer. |
| `examples/qoi-portable/main/main.mbt` | Deterministic in-memory QOI decode, flip, and encode proof | ✓ VERIFIED | Exists, substantive, and wired through public decoder, operation, encoder, memory I/O, limits, budgets, diagnostics, byte/digest checks, and computed SHA-256 comparison. |
| `modules/mb-image/README.mbt.md` | Public QOI instructions and frozen four-target commands | ✓ VERIFIED | Links the standalone example, describes its in-memory proof, documents correct deterministic evidence, and provides all four exact commands. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `main.mbt` | `modules/mb-image/qoi/qoi.mbt` | public `QoiDecoder::new` / `QoiEncoder::new` through codec traits | ✓ WIRED | Both public constructor values feed `ImageDecoder::decode` and `ImageEncoder::encode` with actual input/output state. |
| `main.mbt` | `modules/mb-image/ops/copy_flip.mbt` | public `ops.flip_horizontal` | ✓ WIRED | The returned flipped image is encoded and its pixel positions are asserted before output. |
| `README.mbt.md` | `examples/qoi-portable/main/main.mbt` | frozen four-target commands | ✓ WIRED | README links the executable and its four commands were reproduced verbatim. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `examples/qoi-portable/main/main.mbt` | `source` → `decoded` → `flipped` → `encoded` / `writer` | The repository-owned 27-byte `diff-byte-wrap` QOI stream enters `OwnedBytes`/`MemoryReader`, then public QOI decode, flip, and QOI encode write the 24-byte canonical result to `MemoryWriter`. | Yes — direct four-target runs reached the real checked writer output. `sha256_matches(writer.view(), writer.position())` hashes and compares those bytes to `5dc3…58df`. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| JS portable public workflow | `moon -C examples/qoi-portable run main --target js --frozen` | One checked line with correct SHA-256; exit 0. | ✓ PASS |
| Wasm portable public workflow | `moon -C examples/qoi-portable run main --target wasm --frozen` | One checked line with correct SHA-256; exit 0. | ✓ PASS |
| Wasm-GC portable public workflow | `moon -C examples/qoi-portable run main --target wasm-gc --frozen` | One checked line with correct SHA-256; exit 0. | ✓ PASS |
| Native portable public workflow | `moon -C examples/qoi-portable run main --target native --frozen` | One checked line with correct SHA-256; exit 0. A second native run confirmed exactly one output line. | ✓ PASS |
| Public image regression coverage | `moon -C modules/mb-image test --target all --frozen` | 235/235 passed on wasm, wasm-gc, js, and native. | ✓ PASS |
| Printed SHA-256 identity | PowerShell SHA-256 over `716f696600000002000000010300655a0000000000000001` | Independently produced `5dc3abfe81e722b211af255f6f96805225f98435f1f9525c46df48217f858df2`, matching the program's computed expected words, printed line, and README. | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 15 declares no probe and the repository contains no conventional `probe-*.sh` script for this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| QOI-06 | `15-01-PLAN.md` | A user can run one public portable example that decodes QOI, applies an existing image operation, and encodes QOI with deterministic output evidence. | ✓ SATISFIED | The independently runnable, public, all-target consumer checks the complete pipeline and correct deterministic evidence before output. |

### Anti-Patterns Found

No Phase 15 stub, placeholder, debt-marker, stale SHA-256, FFI, host-file, registry, or platform-specific dependency pattern was found in the example or its README entry.

## Gaps Summary

No gaps remain. The earlier SHA-256 integrity gap is closed by a real SHA-256 implementation that hashes the encoded `MemoryWriter` output and compares it to the externally confirmed canonical digest before the only status line. The README and all four runtime outputs use that same value.

---

_Verified: 2026-07-20T11:56:58Z_
_Verifier: the agent (gsd-verifier)_
