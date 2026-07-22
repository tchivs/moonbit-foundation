---
phase: 54
slug: bounded-type-4-16-encoder
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-07-23
---

# Phase 54 — Security

**Verdict:** SECURED
**Audit depth:** L2 boundary and data-flow verification (the project has no configured security-ASVS override; workflow default is L1).
**Threats closed:** 8/8

## Trust Boundaries

| Boundary | Description | Data Crossing |
|---|---|---|
| Caller `ImageView` to profile admission | A caller-supplied image descriptor and physical row layout are accepted only when they meet the packed U16 Gray+straight-alpha contract. | Descriptor, metadata, dimensions, storage shape |
| U16 storage to PNG wire | Checked component bytes are normalized from legal little-endian storage to PNG's big-endian Gray/Alpha wire order. | Raster bytes, `Ghi,Glo,Ahi,Alo` |
| Planned machine to output consumer | Eager writer output and caller-owned leases become visible only after preflight; replay drift is checked before a pull writes a lease. | PNG bytes, budget/work accounting, mutable lease |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|---|---|---|---|---|---|---|
| T-54-01 | Tampering | `_png_encode_source` GrayAlpha16 arm | high | mitigate | The legal GrayAlpha descriptor is constrained to packed/little-endian, encoded built-in sRGB, top-left U8/U16 sources before storage construction; the PNG boundary then requires `GrayAlpha`, straight alpha, U16, tight rows, no opaque metadata, and validates dimensions before any traversal. Evidence: `model/descriptor.mbt:489`, `model/descriptor.mbt:625`, `png/encode.mbt:56`, `png/encode.mbt:141`, `png/encode.mbt:153`, `png/stream_encode.mbt:601`. | closed |
| T-54-02 | Tampering | `_png_wire_byte` component mapping | high | mitigate | The U16 profile predicate includes GrayAlpha16. Each scalar position derives its component lane and byte within that component, corrects little-endian storage to PNG network order, and uses checked `get_component_byte`; non-symmetric tests assert the literal `12,34,A7,C5,BE,0F,5A,76` sequence. Evidence: `png/encode.mbt:416`, `png/encode.mbt:427`, `png/encode_test.mbt:1018`. | closed |
| T-54-03 | Denial of Service | Profile-aware preflight and compression planning | high | mitigate | Admission returns a four-byte stride. The shared preflight checked-multiplies pixels, row bytes, scanlines, block and output values, evaluates all selected plans over scalar cursors, applies width/height/pixel/output/work limits, then performs its single budget charge. Construction returns an error before eager output or a chunk encoder exists. Evidence: `png/encode.mbt:141`, `png/encode.mbt:1611`, `png/encode.mbt:1619`, `png/encode.mbt:1678`, `png/encode.mbt:1783`, `png/stream_encode.mbt:591`. | closed |
| T-54-04 | Tampering | Profile-specific filtering and replay cursors | high | mitigate | Both public factory families bind `GrayAlpha16` and `None` interlace to `PngEncodeMachine::new_with_profile`. Stored, Fixed, and Dynamic paths instantiate the same profile-aware filtered cursor; the cursor passes the profile and four-byte stride through None and Adaptive byte production. All six compression/filter pairs and a stride-sensitive Adaptive residual are tested. Evidence: `png/png.mbt:224`, `png/stream_encode.mbt:208`, `png/stream_encode.mbt:629`, `png/encode.mbt:782`, `png/encode_test.mbt:1060`. | closed |
| T-54-05 | Denial of Service | GrayAlpha16 checked limits and budget ledger | high | mitigate | For all six strategy/filter pairs, incompatible, geometry-, output-, work-, and budget-limited input returns the same eager/chunk error with zero writer bytes, unchanged budget, and untouched caller-lease sentinels. Evidence: `png/stream_encode_test.mbt:2460`, `png/stream_encode_test.mbt:2627`. | closed |
| T-54-06 | Tampering | Source revision validation before `pull` writes | high | mitigate | The machine snapshots source revision after successful preflight. Every active pull validates a U16 Fixed/Dynamic revision before `destination.set`; drift transitions to the terminal failed state with zero bytes. Fixed and Dynamic GrayAlpha16 Adaptive tests mutate alpha after framing and verify both selected DEFLATE routes. Evidence: `png/stream_encode.mbt:621`, `png/stream_encode.mbt:770`, `png/stream_encode.mbt:382`, `png/stream_encode_test.mbt:2818`. | closed |
| T-54-07 | Tampering | Caller-owned output lease | high | mitigate | Constructor-rejection tests inspect every sentinel byte. Replay-drift tests inspect the first and later leases after the terminal error; the machine's failed state returns zero bytes without calling the active write loop. Evidence: `png/stream_encode.mbt:370`, `png/stream_encode_test.mbt:2486`, `png/stream_encode_test.mbt:2841`, `png/stream_encode_test.mbt:2858`. | closed |
| T-54-08 | Repudiation | Eager/chunk error parity | medium | mitigate | The all-pair rejection helper compares structured eager/chunk `CoreError` values and resource-accounting state rather than accepting generic failure. Evidence: `png/stream_encode_test.mbt:2474`, `png/stream_encode_test.mbt:2491`. | closed |

## Compatibility and Contract Checks

- **Legal little-endian correction:** The model-level GrayAlpha identity rejects big-endian descriptors before PNG admission, while the retained U16 wire correction maps legal little-endian storage per component. The negative descriptor regression executes this exact boundary. Evidence: `model/descriptor.mbt:489`, `png/encode_test.mbt:1034`.
- **Legacy preservation:** The Phase 54 production diff is additive except for exhaustively extending existing profile matches. The current full native PNG suite passes 203/203, exercising established Gray8, Gray16, GrayAlpha8, RGB8, and RGBA8 contracts.
- **No staging route:** The Phase 54 route uses scalar `_png_wire_byte` and the fixed 262-byte matcher window; no image-sized conversion buffer or second production encoder was introduced. Evidence: `png/encode.mbt:427`, `png/encode.mbt:909`, `png/stream_encode.mbt:591`.

## Summary Threat Flags

Neither Phase 54 summary contains a `## Threat Flags` section. No unregistered flags were found.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---:|---:|---:|---|
| 2026-07-23 | 8 | 8 | 0 | Codex security auditor |

## Verification

| Command | Result |
|---|---|
| `moon -C modules/mb-image test png --target all --frozen --filter '*GrayAlpha16*'` | 7/7 passed on wasm, wasm-gc, js, and native |
| `moon -C modules/mb-image test png --target native --frozen` | 203/203 passed |

## Sign-Off

- [x] All threats have a disposition and code-level evidence.
- [x] No accepted risks require a log entry.
- [x] `threats_open: 0` confirmed (high is the configured/default blocking threshold).
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-07-23
