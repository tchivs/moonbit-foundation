---
phase: 24-bounded-non-srgb-and-icc-preservation
verified: 2026-07-21T02:50:56Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/3
  gaps_closed:
    - "Invalid ICC envelope, compression, profile-space, and resource-expansion paths fail before image visibility."
  gaps_remaining: []
  regressions: []
---

# Phase 24: Bounded Non-sRGB and ICC Preservation Verification Report

**Phase Goal:** A library user can retain legal legacy and ICC PNG colour declarations without treating samples as sRGB or performing an implicit transform.
**Verified:** 2026-07-21T02:50:56Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Legal `gAMA`/`cHRM` declarations and bounded legal `iCCP` profiles decode as explicit, bounded non-sRGB metadata without transforming or relabelling pixels. | ✓ VERIFIED | CRC-authenticated facts flow through `PngStreamTransport` into `_png_legacy_metadata` / `_png_iccp_metadata`. Both use `LinearSrgb` plus an opaque profile (`structural.mbt:1416-1496`, `png.mbt:21-83`). Public generated vectors assert the retained key/value/profile length and exact pixels. |
| 2 | Invalid ICC envelope, compression, profile-space, and resource-expansion paths fail before image visibility. | ✓ VERIFIED | Before collecting the first compressed profile byte, `_png_read_colour_chunk` derives a temporary envelope from the caller budget (`structural.mbt:1005-1024`). It preflights compressed input, a 32 KiB history, bounded output, three allocations, and `max_work`; `_png_inflate_iccp` then charges the isolated lease before history/output allocation (`structural.mbt:141-270`). Because `PngDecoder::decode` only constructs metadata/image after `_png_read_stream_transport` returns, all rejection paths precede image visibility (`png.mbt:120-163`). |
| 3 | Reference operations and canonical PNG encoding return a typed capability error instead of losing retained non-sRGB semantics. | ✓ VERIFIED | Retained metadata has `LinearSrgb`, so `supports_reference_operations` returns false (`model/descriptor.mbt:684-697`). The PNG encoder rejects it before writer access (`encode.mbt:60-78`); `encode_test.mbt:138-156` asserts `CapabilityUnavailable` and writer position zero. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | Checked iCCP temporary resource budget and DEFLATE work enforcement. | ✓ VERIFIED | L1 exists (69,725 bytes). L2 has explicit checked-add/mul limits, caller-child preflight, lease charges, deterministic error contexts, and profile validation. L3 is called by `_png_read_stream_transport` with the original decoder budget before stream transport can reach `PngDecoder`. |
| `scripts/fixtures/Generate-PngDecodeVectors.ps1` | Independent iCCP hostile resource/header vectors. | ✓ VERIFIED | The generator independently constructs minimal ICC profiles and validates required case IDs. It emits header, declared-size, signature, incompatible-space, compressed, inflated, allocation, and work cases into the generated public decoder corpus. Freshness check passed for 3,780 executable cases. |
| `modules/mb-image/png/png.mbt` | Bounded explicit non-sRGB metadata construction. | ✓ VERIFIED | The decoder consumes the structural declaration and metadata budget before image construction; it produces opaque profile/metadata identity without assigning encoded sRGB. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Caller `Budget` / `CodecLimits` | iCCP collector and inflater | `_png_read_stream_transport` → `_png_read_colour_chunk` → `_png_iccp_temporary_budget` / `_png_inflate_iccp` | ✓ WIRED | The same caller budget is passed into the colour reader at `structural.mbt:1460`; its non-expanding child preflights every temporary dimension before any iCCP compressed-buffer push. |
| `fixtures/png/decode-cases.json` | `generated_decode_vectors_test.mbt` | Manifest-backed PowerShell generator emits `PngDecodeVector` records | ✓ WIRED | Required hostile IDs are present in both corpus and generated source; the public test calls `PngDecoder` for every record (`png_test.mbt:405-516`). |
| `structural.mbt` | `png.mbt` | Colour declaration enters `PngStreamTransport`, then bounded metadata creation | ✓ WIRED | The decoder only chooses metadata after structural parsing is successful, so malformed/resource-rejected iCCP cannot produce an `OwnedImage`. |
| Retained non-sRGB metadata | reference / canonical encoder guards | descriptor eligibility and encoder semantic preflight | ✓ WIRED | Model test passes on every target; encoder test proves the typed no-output boundary. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| iCCP resource path | `iccp_compressed`, temporary budget, profile | PNG iCCP chunk length and bytes → caller-budget preflight → private DEFLATE → ICC validator | Yes. The declaration's actual remaining length drives compressed-byte, allocation, output, and work reservation; only validated profile bytes flow into opaque metadata. | ✓ FLOWING |
| hostile decoder corpus | generated `PngDecodeVector` fields | Declarative JSON → independent generator → public `PngDecoder` test | Yes. Context/category/code and resource limits are emitted and checked, not hardcoded in the decoder. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generator grammar, hostile ICC completeness, manifest, and generated-source freshness | `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | 3,780 executable cases | ✓ PASS |
| Valid retained metadata plus malformed header/signature/size/space and compressed/inflated/allocation/work rejection through `PngDecoder` | `moon -C modules/mb-image test png --target all --frozen` | 40/40 passed on wasm, wasm-gc, js, and native | ✓ PASS |
| Reference-operation guard remains portable | `moon -C modules/mb-image test model --target all --frozen` | 13/13 passed on wasm, wasm-gc, js, and native | ✓ PASS |
| PNG policy, generator, isolation, and four-target lane | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Passed; 29 existing warnings, 0 errors | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no Phase 24 probe declaration and no `scripts/**/tests/probe-*.sh` files exist.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGCM-03 | `24-01-PLAN.md`, `24-02-PLAN.md` | Valid `gAMA`, `cHRM`, and iCCP declarations are retained as bounded explicit non-sRGB metadata; hostile ICC input is rejected safely. | ✓ SATISFIED | Legal legacy/ICC metadata and exact samples pass the generated public vectors; all ICC syntax/resource limits are enforced before image construction and pass all-target tests. |
| PNGCM-04 | `24-01-PLAN.md` | Operations that would require an unavailable transform or lose non-sRGB semantics return typed capability results. | ✓ SATISFIED | The descriptor reference guard and canonical encoder preflight remain live; all-target model/PNG tests pass, including typed no-output encoder evidence. |

No Phase 24 requirement is orphaned from its plans.

### Anti-Patterns Found

No `TBD`, `FIXME`, `XXX`, placeholder implementation, hardcoded empty decoder result, or empty handler was found in the Phase 24 implementation, generator, fixtures, or generated corpus. The quality lane's 29 warnings are pre-existing unused-field/reserved-keyword warnings; it reported zero errors.

### Re-verification Assessment

The earlier blocker was not waived: it is closed in the live code. The previous parser collected/inflated iCCP data outside the caller envelope. The current path derives a non-expanding child from the caller at the first compressed byte, verifies the complete temporary allocation/work envelope before collecting that byte, then charges an isolated lease for the three actual buffer classes and conservative DEFLATE work. This preserves the caller ceiling while allowing transient ICC storage to be released before the later metadata/raster reservations.

The disconfirmation pass found no remaining partial link: the hostile vector generator is wired to the public decoder rather than a private parser, and the all-target test exercises the generated profile header, signature, declared-size, profile-space, compressed, inflated, allocation, and work cases. Existing non-sRGB retention and typed capability boundaries also remain intact.

---

_Verified: 2026-07-21T02:50:56Z_
_Verifier: the agent (gsd-verifier)_
