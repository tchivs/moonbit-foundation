---
phase: 50
slug: gray-alpha-image-model
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-23
---

# Phase 50 — Security

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller metadata → descriptor | Caller-controlled format and metadata select the permitted image representation. | Format, alpha, color, profile, and orientation identities. |
| Descriptor → storage/view | The validated descriptor determines allocation size, component bounds, and byte offsets. | Dimensions, plane shape, and packed component bytes. |
| Image view → operations | A storable image is not automatically eligible for existing processing operations. | Validated image view and operation budget. |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-50-01 | Tampering | GrayAlpha descriptor admission | high | mitigate | `validate_alpha_identity` requires straight alpha; `validate_gray_alpha_identity` fixes U8/packed/little-endian/encoded-sRGB/builtin-sRGB/top-left and returns the typed descriptor error. | closed |
| T-50-02 | Tampering | Checked packed views | medium | mitigate | `channel_count()` is the sole two-component layout source; public storage tests verify distinct gray/alpha bytes and reject component two. | closed |
| T-50-03 | Elevation of Privilege | Reference and copy/flip gates | high | mitigate | Both `supports_reference_operations` and `supports_copy_flip` explicitly return false for `GrayAlpha`; copy rejection is tested before budget consumption. | closed |
| T-50-04 | Denial of Service | Plane shape and owned allocation | medium | mitigate | Existing checked descriptor plane validation and budgeted `OwnedImage::new` remain on the only allocation path. | closed |
| T-50-05 | Repudiation | Regression evidence | low | accept | Deterministic four-target public package tests and the phase verification report are retained as evidence. | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-23 | 5 | 5 | 0 | GSD secure-phase L1 artifact verification |

## Sign-Off

- [x] All threats have a disposition.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-07-23
