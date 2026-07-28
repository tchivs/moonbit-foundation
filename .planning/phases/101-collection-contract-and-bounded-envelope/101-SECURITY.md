---
phase: 101
slug: collection-contract-and-bounded-envelope
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-07-28
---

# Phase 101 — Security

> ASVS L1 verification of the plan-authored STRIDE register against the implemented collection boundary.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller bytes → collection parser | Caller-owned, mutable, hostile TTC/OTC bytes enter bounded structural inspection | Headers, face offsets, table records, DSIG envelopes |
| Caller limits/budget → parser work | Caller and package ceilings authorize retained memory, allocations, declarations, pair comparisons, and normalization | Eight collection limits plus atomic `Budget` charge |
| Private parser → public facade | Compact normalized facts cross into an opaque `FontCollection` identity | Face count, closed profiles, unverified DSIG status |
| Portable module → four targets | One MoonBit implementation must preserve identical narrowing and error semantics | js, wasm, wasm-gc, native |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-101-01-01 | Denial of service | Source/header/count admission | high | mitigate | Authority and staged work preflights in `collection_parser.mbt`; exact/one-over atomic tests | closed |
| T-101-01-02 | Tampering | Root-relative parser identity | high | mitigate | Retained root `ByteView`, checked root subranges, wrong-rebase regression | closed |
| T-101-01-03 | Tampering | Cached collection queries | high | mitigate | Revision-first queries and final pre-publication guard; mutation/restoration tests | closed |
| T-101-01-04 | Information disclosure | Public generated interface | medium | mitigate | Private parser facts and exact independent interface/private-leak policy gate | closed |
| T-101-01-05 | Repudiation | Collection versus standalone entry points | medium | mitigate | Separate `FontCollection::open`; unchanged standalone `Font::open` blob and signature | closed |
| T-101-01-SC | Tampering | Dependency supply chain | low | accept | No dependency/manifest change; `mb-font` remains pinned to `mb-core` only | closed — accepted |
| T-101-02-01 | Denial of service | Face/table declarations | high | mitigate | Face, per-face, cumulative and declaration-work ceilings before dependent loops | closed |
| T-101-02-02 | Tampering | Directory/table coordinate origin | high | mitigate | Direct root-relative record offsets and checked range construction | closed |
| T-101-02-03 | Tampering | Overlap/shared-table identity | high | mitigate | Protected/table/alias replay and exact range+tag+length+checksum sharing rule | closed |
| T-101-02-04 | Denial of service | Pair comparisons/normalization | high | mitigate | Checked work formulas, staged authority and exact retained accounting | closed |
| T-101-02-05 | Repudiation | Partial budget publication | high | mitigate | Preflights, final revision guard, one atomic charge, then publication | closed |
| T-101-02-06 | Information disclosure | Raw normalized facts | medium | mitigate | Private normalized records and negative generated-interface checks | closed |
| T-101-02-SC | Tampering | Dependency supply chain | low | accept | No new runtime dependency, FFI, or host adapter; policy inventory unchanged | closed — accepted |
| T-101-03-01 | Denial of service | DSIG traversal | high | mitigate | DSIG byte/count authority, checked record/block ranges and exact pair work | closed |
| T-101-03-02 | Spoofing | Public DSIG status | high | mitigate | Closed `Absent`/`PresentUnverified` enum; payload content is never trusted or read | closed |
| T-101-03-03 | Tampering | DSIG/protected/table overlap | high | mitigate | Root-bounded DSIG ranges, protected inclusion and block non-overlap checks | closed |
| T-101-03-04 | Tampering | Source revision race | high | mitigate | Post-normalization final revision comparison and deterministic race test | closed |
| T-101-03-05 | Repudiation | Partial budget/publication | high | mitigate | Complete preflight plus final guard/single charge/construction sequence | closed |
| T-101-03-06 | Information disclosure | Error/parser surface | medium | mitigate | Closed errors, exact contexts and generated-interface leak gate | closed |
| T-101-03-07 | Tampering | Target-specific narrowing | high | mitigate | Four-target policy, interface equality and 131/131 qualification evidence | closed |
| T-101-03-SC | Tampering | Dependency supply chain | low | accept | Pure portable MoonBit implementation; no dependency or workspace delta | closed — accepted |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-101-01 | T-101-01-SC | Phase adds no dependency; residual registry/toolchain supply-chain risk is inherited and below the configured block threshold. | Plan 101-01 disposition, verified by GSD security audit | 2026-07-28 |
| AR-101-02 | T-101-02-SC | Phase adds no dependency; existing pinned MoonBit/`mb-core` supply-chain exposure is unchanged. | Plan 101-02 disposition, verified by GSD security audit | 2026-07-28 |
| AR-101-03 | T-101-03-SC | Four-target qualification adds no runtime package, FFI, or host adapter; inherited toolchain risk remains low. | Plan 101-03 disposition, verified by GSD security audit | 2026-07-28 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open Blocking | Accepted | Run By |
|------------|---------------|--------|---------------|----------|--------|
| 2026-07-28 | 21 | 21 | 0 | 3 | `gsd-security-auditor` (ASVS L1) |

## Sign-Off

- [x] All plan-authored threats have a disposition.
- [x] All mitigations are verified against implementation and tests.
- [x] Accepted low risks are documented.
- [x] `threats_open: 0` confirmed at `block_on: high`.
- [x] Frontmatter status is `verified`.

**Approval:** verified 2026-07-28
