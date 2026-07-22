---
phase: 53
slug: grayalpha16-model-and-checked-storage
status: open_nonblocking
# Blocking count only: severity >= workflow.security_block_on (high).
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-07-23
---

# Phase 53 — Security

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Status | Evidence |
|---|---|---|---|---|---|---|
| T-53-01 | Tampering | `validate_gray_alpha_identity` | high | mitigate | closed | `descriptor.mbt:465-515` admits only U8/U16 GrayAlpha and requires packed/little, straight alpha, encoded sRGB, builtin profile, and top-left orientation. `model_test.mbt:297-431` covers F32, planar, big-endian, alpha, transfer, profile, orientation, and row-shape rejection. |
| T-53-02 | Tampering | checked component-byte offsets | high | mitigate | closed | `views.mbt:240-285` and `477-548` check view bounds, channel, and component-byte before checked offset arithmetic. `storage_test.mbt:219-235` proves four distinct U16 lane bytes and rejects channel 2, byte index 2, and U16 `get_byte`. |
| T-53-03 | Denial of Service | descriptor plane shape and `OwnedImage` allocation | medium | mitigate | closed | `descriptor.mbt:519-575` uses checked multiplication for component and row sizes; `descriptor.mbt:590-668` validates plane count, shape, storage containment, and overlap before construction. `owned_image.mbt:30-58` charges validated storage through the supplied budget. |
| T-53-04 | Elevation of Privilege | reference/copy capability boundary | medium | mitigate | closed | `descriptor.mbt:741-756` returns false for GrayAlpha. `copy_flip.mbt:50-70,170-188` rejects GrayAlpha/non-U8 before descriptor construction, allocation, or budget consumption; `copy_flip_test.mbt:201-229` proves the fail-closed path and unchanged budget. |
| T-53-05 | Repudiation | compatibility evidence | low | accept | open — below high threshold (non-blocking) | No Phase 53 accepted-risks entry existed before this audit. The declared acceptance is therefore not verified; deterministic all-target tests are execution evidence, not an accepted-risk record. |

## Accepted Risks Log

No accepted risks. T-53-05 remains open pending an explicit accepted-risk entry.

## Threat Flags

None. `53-01-SUMMARY.md` has no `## Threat Flags` section, so no unregistered flag was reported by execution.

## Verification Evidence

- `moon test --target all modules/mb-image/model modules/mb-image/storage modules/mb-image/ops` — passed 81/81 tests on wasm, wasm-gc, js, and native.
- `moon check --target all` — passed; warnings are in pre-existing PNG sources outside Phase 53's implementation scope.
- `git diff --check 041d8a2^..079a18e` — passed.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Blocking Open | Run By |
|---|---:|---:|---:|---:|---|
| 2026-07-23 | 5 | 4 | 1 | 0 | gsd-security-auditor |

## Verdict

**OPEN_THREATS** — T-53-05 is open below the `high` blocking threshold. No implementation mitigation is missing; phase advancement is not blocked because `threats_open: 0`.
