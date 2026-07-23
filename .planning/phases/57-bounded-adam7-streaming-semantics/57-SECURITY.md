---
phase: 57
slug: bounded-adam7-streaming-semantics
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-23
---

# Phase 57 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller image and strategy selection to profile-aware preflight | Caller-controlled packed storage, filter, compression, interlace, limits, and budget are admitted as bounded traversal and plan facts. | Image view, strategy selectors, limits, budget |
| Encoder machine to caller-owned output lease | A previewed PNG byte becomes caller-visible only after the caller lease accepts it. | Previewed byte and lease capacity |
| Checked mutable U16 source to caller-owned lease | A post-planning source mutation must fail before an output lease receives a byte. | Image mutation revision and output lease |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-57-01 | Denial of Service | Adam7 profile-aware preflight and planner | high | mitigate | `_png_encode_preflight_with_filter_layout_idat_limit_profile` computes checked Adam7 pass totals, visits every selected planner/replay traversal, applies width/height/pixels/output/work limits, then makes the one budget charge. The four-target exact/one-less regression covers all six selectors. | closed |
| T-57-02 | Tampering | Adam7 Adaptive predictor state | high | mitigate | The profile-aware filtered cursor is constructed with `PngInterlaceStrategy::Adam7`; the GrayAlpha16 white-box regression verifies each nonempty pass begins with local history and rejects inherited Up/Average/Paeth tags across all six selectors. | closed |
| T-57-03 | Tampering | `PngChunkEncoder` accepted-byte accounting | high | mitigate | `pull` writes only after preview and increments `total_written` after successful acknowledgement. The all-selector chunk drain uses zero, one-byte, and ragged leases, checks every untouched tail byte, eager parity, and terminal totals. | closed |
| T-57-04 | Elevation of Privilege | GrayAlpha16 descriptor/factory boundary | medium | mitigate | `ImageDescriptor::new` rejects Big-endian GrayAlpha16 before PNG admission; the PNG boundary regression asserts that rejection, while explicit legacy factories remain `None`-interlaced. | closed |
| T-57-05 | Denial of Service | GrayAlpha16 Adam7 shared preflight ledger | high | mitigate | `PngEncodeMachine::new_with_profile` returns immediately on profile-aware preflight failure, before machine creation. The public matrix checks capability, geometry, output, work, and budget failures for every pair with unchanged eager writer, budget, and chunk sentinel. | closed |
| T-57-06 | Tampering | U16 Stored/Fixed/Dynamic replay revision guard | high | mitigate | `PngEncodeMachine::validate_u16_replay_revision` rejects changed U16 revisions for Stored, Fixed, and Dynamic, and `PngChunkEncoder::pull` calls it before `destination.set`. The six-pair Adam7 mutation matrix verifies each selected route. | closed |
| T-57-07 | Tampering | Caller-owned output lease | high | mitigate | Preflight failures expose no caller byte; replay drift sets a sticky failed state with zero writes before the first and later sentinel leases. The public tests inspect every sentinel byte for all supported selector pairs. | closed |
| T-57-08 | Repudiation | Eager/chunk terminal equivalence | medium | mitigate | The public admission matrix compares structured eager and chunk errors, resource ledgers, and the replay matrix compares original/sticky errors with the accepted total. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-23 | 8 | 8 | 0 | gsd-security-auditor |

### Audit Evidence

- `modules/mb-image/png/encode.mbt:1604-1808` contains the shared checked Adam7 preflight ledger and its pre-charge limit checks.
- `modules/mb-image/png/stream_encode.mbt:403-484` validates U16 replay revision before `destination.set`; `:807-821` has closed Stored, Fixed, and Dynamic drift branches.
- `modules/mb-image/png/stream_encode_test.mbt:2658-2899` exercises atomic public admission, and `:3077-3186` verifies first/later lease sentinels and sticky all-six replay failures.
- `modules/mb-image/png/encode_wbtest.mbt:378-425` provides all-selector pass-local predictor and exact/one-less-work evidence.
- Behavioral evidence is current: the focused white-box test passed on wasm, wasm-gc, js, and native; `moon -C modules/mb-image test png --target native --frozen --no-parallelize` passed 222/222 (recorded in `57-VERIFICATION.md`).

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-23
