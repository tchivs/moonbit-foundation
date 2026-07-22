---
phase: 51
slug: bounded-gray-alpha-png-encoding
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-23
---

# Phase 51 — Security

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Image view to GrayAlpha8 profile admission | Caller-controlled image descriptor, metadata, geometry, and packed backing must meet the locked PNG profile before pixels are read. | Channel order, U8 type, alpha mode, layout, color identity, orientation, and row geometry. |
| Bounded preflight to eager writer or caller lease | The encoder may make PNG bytes observable only after shared profile-aware planning, limit checks, and budget charging succeed. | Planned bytes, resource limits, budget state, and caller-owned mutable lease. |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-51-01 | Tampering | `_png_encode_source` GrayAlpha8 profile arm | high | mitigate | Closed descriptor admission validates packed layout, encoded builtin sRGB, top-left orientation, `GrayAlpha`, straight alpha, U8 components, and tight rows before source reads or budget charge; incompatible channel order returns `graya8-required`. Evidence: `modules/mb-image/png/encode.mbt:54-149`; rejection regression: `encode_test.mbt:918-928`. | closed |
| T-51-02 | Tampering | `_png_wire_byte` and IHDR emission | high | mitigate | Generic U8 scalar mapping reads component 0 then 1 with `channels=2`; GrayAlpha8 emits bit depth 8, color type 4, and non-interlaced IHDR. Non-symmetric pair regressions assert exact stored raster bytes and decoder fidelity. Evidence: `encode.mbt:405-424`; `stream_encode.mbt:1048-1068`; `encode_test.mbt:903-916`; `stream_encode_test.mbt:766-787`. | closed |
| T-51-03 | Denial of Service | profile-aware preflight and compression planning | high | mitigate | GrayAlpha8 enters the existing checked profile-aware preflight, with checked dimensions/scanlines/planning, configured width/height/pixel/output/work limits, and the single final budget charge. Evidence: `encode.mbt:1520-1541`, `encode.mbt:1588-1787`; strategy-wide resource-limit regression: `stream_encode_test.mbt:2148-2189`, `2291-2309`. | closed |
| T-51-04 | Tampering | caller-buffered construction | medium | mitigate | The combined graya8 factory invokes `PngEncodeMachine::new_with_profile` and returns `Err` before constructing `PngChunkEncoder`; the shared machine performs preflight before state creation. Evidence: `stream_encode.mbt:144-159`, `stream_encode.mbt:527-571`; all six strategy pairs are exercised in `stream_encode_test.mbt:801-821`. | closed |
| T-51-05 | Tampering | graya8 eager and chunk strategy factories | high | mitigate | All eager and caller-buffered public shapes delegate to the explicit GrayAlpha8 combined profile route, and all six compression/filter pairs are asserted byte-identical with type-4/8-bit/non-interlaced framing. Evidence: `png.mbt:181-219`; `stream_encode.mbt:98-159`; `encode_test.mbt:931-956`; `stream_encode_test.mbt:789-821`. | closed |
| T-51-06 | Denial of Service | checked geometry/output/work/budget preflight | high | mitigate | The same shared preflight applies checked geometry, output/work envelopes, and final budget charge before construction; the regression runs incompatible, width, output, work, and budget failures for every strategy/filter pair with unchanged accounting. Evidence: `encode.mbt:1592-1642`, `1760-1787`; `stream_encode_test.mbt:2148-2189`, `2293-2308`. | closed |
| T-51-07 | Tampering | callback-scoped mutable output lease | high | mitigate | Rejected chunk construction cannot return an encoder; tests create a sentinel owner before each attempted constructor and assert every byte stays `Z` across all six strategy/filter pairs and all declared failure envelopes. Evidence: `stream_encode.mbt:152-159`, `527-542`; `stream_encode_test.mbt:2172-2187`, `2291-2309`. | closed |
| T-51-08 | Repudiation | typed eager/chunk failure comparison | medium | mitigate | The atomicity helper compares structured error category, code, operation, context, requested, completed, and limit fields between eager and chunk failures for every strategy/filter pair. Evidence: `stream_encode_test.mbt:1670-1681`, `2175-2181`, `2291-2309`. | closed |

## Unregistered Threat Flags

None. Neither Phase 51 execution summary contains a `## Threat Flags` section or reports a new attack surface outside T-51-01 through T-51-08.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-23 | 8 | 8 | 0 | Phase 51 mitigation audit, ASVS L1 |

## Verification

- `moon -C modules/mb-image test png --target native --frozen` — passed: 195/195.

## Sign-Off

- [x] All declared threats have a disposition and code-backed mitigation evidence.
- [x] No unregistered executor threat flags were reported.
- [x] `threats_open: 0` confirmed using `block_on: high` (default; no explicit project override).
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-07-23
