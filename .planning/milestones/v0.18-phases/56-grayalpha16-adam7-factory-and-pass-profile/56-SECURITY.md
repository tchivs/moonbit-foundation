---
phase: 56
slug: grayalpha16-adam7-factory-and-pass-profile
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-23
---

# Phase 56 — Security

> Verified against the Phase 56 implementation and its native PNG evidence. This audit checks the declared threat register only; no new threat scan was performed.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller ImageView to GrayAlpha16 profile admission | Caller-controlled descriptor and metadata must remain within the locked packed little-endian U16 straight-alpha contract. | Image descriptor, metadata, and packed pixel storage |
| Adam7 pass coordinate to PNG wire byte | A pass-local logical position crosses from checked storage to endian-sensitive Type-4/16 wire lanes. | Pass coordinates and four-byte U16 pixel lanes |
| Public factory selection to PngEncodeMachine | Eager and caller-buffered selection must feed one profile-aware bounded construction path. | Profile, compression, filter, interlace, limits, and budget |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-56-01 | Tampering | GrayAlpha16 Adam7 profile gate | high | mitigate | Preflight rejects Adam7 for Gray8, Gray16, and GrayAlpha8, while GrayAlpha16 reaches the same profile-aware layout preflight. Evidence: `modules/mb-image/png/encode.mbt:1544`, `modules/mb-image/png/encode.mbt:1553`. | closed |
| T-56-02 | Tampering | Adam7 raw/candidate/winner reads | high | mitigate | Adam7 raw reads now carry `PngEncodeProfile` into `_png_wire_byte`; every filter candidate and adaptive winner uses that same path. The seven-pass 5x5 regression asserts distinct `Ghi,Glo,Ahi,Alo` lanes. Evidence: `modules/mb-image/png/encode.mbt:590`, `modules/mb-image/png/encode.mbt:606`, `modules/mb-image/png/encode.mbt:645`, `modules/mb-image/png/encode_test.mbt:1151`. | closed |
| T-56-03 | Elevation of Privilege | U16 descriptor admission | medium | mitigate | Gray+Alpha descriptor validation requires packed little-endian U8/U16 identity before PNG construction; the Phase 56 regression proves a Big-endian U16 descriptor is rejected. Evidence: `modules/mb-image/model/descriptor.mbt:489`, `modules/mb-image/png/encode_test.mbt:1182`. | closed |
| T-56-04 | Tampering | legacy GrayAlpha16 constructor routing | high | mitigate | All pre-existing eager and caller-buffered GrayAlpha16 factory shapes explicitly forward `PngInterlaceStrategy::None`; regressions assert IHDR interlace byte zero. Evidence: `modules/mb-image/png/png.mbt:250`, `modules/mb-image/png/stream_encode.mbt:208`, `modules/mb-image/png/encode_test.mbt:1208`, `modules/mb-image/png/stream_encode_test.mbt:1144`. | closed |
| T-56-05 | Denial of Service | pass traversal | medium | mitigate | The added selectors call only `PngEncodeMachine::new_with_profile`; Adam7 traversal is scalar-cursor based and derives geometry from the sole `_png_adam7_passes` authority, without Phase 56 staging state. Evidence: `modules/mb-image/png/stream_encode.mbt:244`, `modules/mb-image/png/stream_encode.mbt:628`, `modules/mb-image/png/encode.mbt:556`, `modules/mb-image/png/structural.mbt:588`. | closed |
| T-56-06 | Tampering | eager factory/profile selection | high | mitigate | Both public eager selectors produce identical Stored/None Type-4/depth-16/Adam7 output, including all seven non-symmetric pass payloads. Evidence: `modules/mb-image/png/png.mbt:265`, `modules/mb-image/png/encode_test.mbt:1151`. | closed |
| T-56-07 | Tampering | chunk factory/profile selection | high | mitigate | Both public caller-buffered selectors construct the same `GrayAlpha16` machine profile and are compared with their exact eager peers, including Type-4/depth-16/Adam7 IHDR bytes. Evidence: `modules/mb-image/png/stream_encode.mbt:229`, `modules/mb-image/png/stream_encode.mbt:244`, `modules/mb-image/png/stream_encode_test.mbt:1106`. | closed |
| T-56-08 | Elevation of Privilege | GrayAlpha16 descriptor boundary | medium | mitigate | The descriptor-level little-endian gate is unchanged and the Big-endian case remains a construction failure rather than an encoder variant. Evidence: `modules/mb-image/model/descriptor.mbt:496`, `modules/mb-image/png/encode_test.mbt:1182`. | closed |
| T-56-09 | Tampering | frozen non-interlaced factory routing | high | mitigate | Legacy eager and chunk factory contracts remain non-interlaced and retain explicit IHDR interlace-zero regression coverage. Evidence: `modules/mb-image/png/png.mbt:250`, `modules/mb-image/png/stream_encode.mbt:208`, `modules/mb-image/png/encode_test.mbt:1206`, `modules/mb-image/png/stream_encode_test.mbt:1142`. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).* 

---

## Threat Flags

No `## Threat Flags` entries were reported by either Phase 56 summary; no unregistered implementation flag was found.

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-23 | 9 | 9 | 0 | gsd-security-auditor |

### Verification Evidence

- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 eager pass profile'` — pass (1/1)
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 chunk parity'` — pass (1/1)
- `moon -C modules/mb-image test png --target native --frozen` — pass (206/206)

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-23
