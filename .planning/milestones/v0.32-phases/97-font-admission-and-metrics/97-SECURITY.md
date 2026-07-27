---
phase: 97
slug: font-admission-and-metrics
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-27
---

# Phase 97 — Security

> Per-phase security contract for hostile standalone TrueType admission, retained-byte ownership, metric queries, and publication-policy enforcement.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller bytes → `Font::open` | Attacker-controlled SFNT counts, offsets, tags, checksums, table payloads, and cross-table cardinalities enter the parser. | Untrusted binary data |
| Caller limits/budget → admission coordinator | Caller-owned ceilings and mutable resource accounting constrain all declaration-driven parsing work. | Resource authority and mutable budget state |
| Retained backing → public query | Caller mutation can invalidate admitted table windows and cached facts. | Mutable retained `ByteView` |
| Private parser facts → public `Font` | Only mutually consistent, fully checked facts may cross the publication boundary. | Parsed font state |
| Public `GlyphId` → receiving `Font` | An opaque identifier may originate from another font and must be checked again. | Caller-controlled opaque value |
| Generated interface/policy → consumers | Accidental private, host, filesystem, FFI, or deferred APIs could become compatibility surface. | Public API and package metadata |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-97-01 | Tampering | `cursor.mbt`, `directory.mbt` offsets/counts | high | mitigate | Checked widened arithmetic, exact table-local views, canonical directory structure, hostile one-short/overflow tests. | closed |
| T-97-02 | Denial of Service | Declared table/count/checksum work | high | mitigate | `FontLimits` intersection plus exact preflight and one atomic `Budget` charge covering directory, checksum, cmap, name, post, and metric work. | closed |
| T-97-03 | Tampering | Retained source after admission | high | mitigate | Opening revision captured, checked before publication, and guarded by every public query; mutation and mutate-back tests pass. | closed |
| T-97-04 | Tampering | Private facts → public `Font` | high | mitigate | A single coordinator publishes `Font` only after complete directory/table/metric agreement and final revision validation. | closed |
| T-97-05 | Information Disclosure | Structured parser errors | low | accept | Errors contain bounded diagnostic facts and stable tokens only; no source bytes, table contents, host paths, or repository secrets. | closed |
| T-97-06 | Elevation of Privilege | Host/FFI capability leakage | low | accept | The portable package has no host capability; exact interface and selector policy reject filesystem, FFI, native, and deferred aliases. | closed |
| T-97-02-01 | Tampering | Directory ranges, aliases, and checksums | high | mitigate | Sorted unique tags, alignment/non-overlap, checked ranges, table-local views, table checksums, and whole-font adjustment are admission gates. | closed |
| T-97-02-02 | Denial of Service | Directory/table scans | high | mitigate | Exact discovery, selector, normalization, checksum, and table traversal work is preflighted and charged under shared limits. | closed |
| T-97-02-03 | Tampering | Required tables and cross-cardinality | high | mitigate | Required versions/envelopes and hmtx/loca/cmap/name/post relationships are validated before construction. | closed |
| T-97-02-04 | Tampering | Retained backing storage | medium | mitigate | Revision is checked immediately before publication and on every global/per-glyph query. | closed |
| T-97-02-05 | Information Disclosure | Structured parser failures | low | accept | Stable `CoreError` facts omit source contents, secrets, and host paths while preserving deterministic diagnosis. | closed |
| T-97-03-01 | Tampering | hmtx/loca/glyf lookup | high | mitigate | Checked cardinality/index/range arithmetic, monotonic loca validation, table-local views, and complete non-empty glyph-header containment. | closed |
| T-97-03-02 | Denial of Service | Glyph/count/work declarations | high | mitigate | Counts and semantic traversals are bounded by `FontLimits` and exact atomic budget preflight/charge boundaries. | closed |
| T-97-03-03 | Tampering | Retained `ByteView` after publication | high | mitigate | Mutation revision is checked before each `Font` query and before publishing source-derived metrics. | closed |
| T-97-03-04 | Tampering | Cross-font `GlyphId` | medium | mitigate | Construction remains opaque and every receiving `Font` revalidates the numeric glyph range before lookup. | closed |
| T-97-03-05 | Information Disclosure | Public generated `.mbti` | medium | mitigate | Exact semantic-interface policy permits only the intended opaque font/glyph, limits, and named metric surface. | closed |
| T-97-SC | Tampering | Package/dependency resolution | low | mitigate | Frozen MoonBit commands and policy enforce `tchivs/mb-core` as the only runtime dependency and prohibit package installation. | closed |

*Only open threats at or above `workflow.security_block_on: high` count toward `threats_open`; this audit has no open threats at any severity.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-97-01 | T-97-05 | Bounded structured diagnostics are required for deterministic parser automation and expose no source contents or secrets. | Phase 97 threat model | 2026-07-27 |
| AR-97-02 | T-97-06 | A pure portable package has no authority to elevate; repository policy continuously prevents host/FFI capability leakage. | Phase 97 threat model | 2026-07-27 |
| AR-97-03 | T-97-02-05 | Stable bounded error facts are necessary for conformance and omit sensitive payload and host information. | Phase 97 threat model | 2026-07-27 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-27 | 17 | 17 | 0 | Codex / GSD secure-phase |

Evidence:

- `97-REVIEW.md`: deep review, 14 files, 0 findings.
- `modules/mb-font/font/font_test.mbt` and `font_wbtest.mbt`: 39/39 tests on JS, Wasm, Wasm-GC, and native.
- `moon -C modules/mb-font check --target all --deny-warn --frozen`: passed.
- `Assert-FontFoundationPolicy`: complete policy and foreign-working-directory selectors passed.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-27
