---
phase: 102
slug: root-relative-selected-face-admission
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-07-28
---

# Phase 102 — Security

> ASVS L1 verification of the plan-authored STRIDE register against root-relative selected-face admission, its review fixes, and four-target policy evidence.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Retained collection root → selected parser | Mutable, caller-owned TTC/OTC bytes are reparsed for one cached supported face without copying | Absolute directory location, root-relative table ranges, opening revision |
| Caller limits/budget → selected admission | Fresh caller and ancestor authority must precede attacker-sized traversal while the real charge remains atomic | Source/table extents, allocations, allocation size, cumulative work |
| Collection checksum mode → shared font pipeline | Selected faces reuse standalone semantic admission while changing only the whole-root adjustment rule | Per-table checksums, zeroed `head` adjustment, collection-mode aggregate policy |
| Private selected facts → public `Font` | One admitted collection face crosses into the existing opaque `Font` contract | Metrics, mapping, glyph identity, kerning, outlines; no parser/storage facts |
| Portable source → policy classifier/four targets | Pure MoonBit source and its executable interpolations must remain visible to fail-closed policy gates | js, wasm, wasm-gc, native interface and source-boundary evidence |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-102-01-01 | Tampering | Directory base and table offsets | high | mitigate | Checked absolute directory addressing with unchanged root table offsets; wrong-rebase, touching, intersection, cached-count, and overflow regressions | closed |
| T-102-01-02 | Tampering | Checksum mode | high | mitigate | Shared per-table and zeroed-`head` checks with standalone-only aggregate validation; standalone aggregate error remains locked | closed |
| T-102-01-03 | Denial of service | `cmap`/`kern` declared loops | high | mitigate | Live cumulative caller/ancestor preflights cover directory, checksum, `cmap`, `kern`, and remaining semantic loop families before traversal | closed |
| T-102-01-04 | Repudiation | Deferred budget accounting | high | mitigate | Collection mode preflights without charging; exact/ancestor-short/overflow cases prove complete budget equality and no double count | closed |
| T-102-01-05 | Denial of service | Standalone compatibility drift | high | mitigate | Standalone still uses incremental admission with historical ordering, exact work, one-short, and aggregate-checksum behavior | closed |
| T-102-01-06 | Information disclosure | Private mode leakage | medium | mitigate | Checksum/commit modes and ledger remain private; exact public interface admits only the intended method | closed |
| T-102-01-SC | Tampering | Dependency supply chain | low | accept | No dependency, package, installer, or workflow change; `mb-font` remains dependent only on existing `mb-core` | closed — accepted |
| T-102-02-01 | Tampering | Root-relative selected tables | high | mitigate | `open_face` forwards the retained root and cached absolute face facts; records remain collection-root-relative | closed |
| T-102-02-02 | Denial of service | Unrelated siblings | high | mitigate | Only the indexed cached face enters semantic admission; exact sharing and poison CFF/CFF2/variable siblings are isolated | closed |
| T-102-02-03 | Denial of service | Selected declared work | high | mitigate | Directory, profile/checksum, semantic lookup, and remaining work are cumulatively preflighted against live caller/ancestor budgets | closed |
| T-102-02-04 | Repudiation | Partial selected charge/publication | high | mitigate | Exact final preflight, final revision guard, one charge, then publication; failures preserve all eight budget dimensions | closed |
| T-102-02-05 | Tampering | Retained-source mutation | high | mitigate | Revision-first facade and final guard cover mutation/restoration; inherited `Font` queries reject stale roots | closed |
| T-102-02-06 | Tampering | Collection checksum policy | high | mitigate | Collection uses shared per-table/`head` checks and skips only whole-root adjustment; bad selected tables still fail | closed |
| T-102-02-07 | Information disclosure | Public selected internals | medium | mitigate | Public selection returns the existing opaque `Font`; exact 85-line allowlist and private/parser/storage negatives pass | closed |
| T-102-02-SC | Tampering | Dependency supply chain | low | accept | No install, dependency, package, or workflow change; exact dependency checks remain enforced | closed — accepted |
| T-102-03-01 | Tampering | Standalone/selected semantic equivalence | high | mitigate | Both forms share `font_from_admitted_facts`; public metrics, mapping, glyph, kerning, and exact outline observations match | closed |
| T-102-03-02 | Denial of service | Multi-fault precedence | high | mitigate | Revision → index → profile → authority/data/checksum → semantics → final budget/revision/charge order is frozen by pairwise tests | closed |
| T-102-03-03 | Repudiation | Failed budget transaction | high | mitigate | Every selected failure checks complete eight-dimensional budget equality | closed |
| T-102-03-04 | Tampering | Selected/standalone checksums | high | mitigate | Selected table/`head` behavior and standalone aggregate failure are independently qualified | closed |
| T-102-03-05 | Tampering | Source mutation | high | mitigate | Pre-selection, mid-selection, post-publication, repeat, and mutate/restore cases fail atomically | closed |
| T-102-03-06 | Information disclosure | Accidental public internals | high | mitigate | Exact one-method interface and private-leak negatives pass; post-review lexer keeps executable interpolation policy-visible and fails closed | closed |
| T-102-03-07 | Tampering | Target-specific semantics | high | mitigate | Common public/private evidence passes on js, wasm, wasm-gc, and native; target-all interface/policy gates pass | closed |
| T-102-03-SC | Tampering | Dependency supply chain | low | accept | Phase adds only the exact public interface line; no dependency/install manifest changes and the existing edge is preserved | closed — accepted |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-102-01 | T-102-01-SC | Private parser refactoring adds no dependency; inherited registry/toolchain exposure remains low and below the configured block threshold. | Plan 102-01 disposition, verified by GSD security audit | 2026-07-28 |
| AR-102-02 | T-102-02-SC | Selected-face admission adds no package, installer, FFI, or host adapter; the existing `mb-core` dependency boundary is unchanged. | Plan 102-02 disposition, verified by GSD security audit | 2026-07-28 |
| AR-102-03 | T-102-03-SC | Four-target qualification and policy hardening add no runtime dependency; residual pinned toolchain risk remains low. | Plan 102-03 disposition, verified by GSD security audit | 2026-07-28 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open Blocking | Accepted | Run By |
|------------|---------------|--------|---------------|----------|--------|
| 2026-07-28 | 23 | 23 | 0 | 3 | `gsd-security-auditor` (ASVS L1) |

Audit facts:

- Plan-time register verified at branch commit `111f368b`; all 23 rows retain their declared disposition.
- CR-01 fix `8195a491` places cumulative caller/ancestor authority before every registered selected-admission loop family while preserving atomic charging.
- CR-02 fixes `a89f013f` and `d8dccd6c` make comment/string/interpolation policy scanning stateful and fail closed.
- Baseline `67dd1481` to audited implementation adds no dependency manifest, installer, FFI, or workflow change.
- No SUMMARY contains an unregistered `## Threat Flags` section.

## Sign-Off

- [x] All plan-authored threats have a disposition.
- [x] All mitigations are verified against implementation and tests.
- [x] Accepted low risks are documented.
- [x] `threats_open: 0` confirmed at `block_on: high`.
- [x] Frontmatter status is `verified`.

**Approval:** verified 2026-07-28
