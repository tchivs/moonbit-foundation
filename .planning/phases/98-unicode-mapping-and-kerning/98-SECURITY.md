---
phase: 98
slug: unicode-mapping-and-kerning
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-27
---

# Phase 98 — Security

> Per-phase security contract for hostile cmap/kern admission, guarded Unicode and kerning queries, resource accounting, and publication-policy enforcement.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller font bytes → cmap admission | Attacker-controlled records, offsets, groups, segments, glyph values, and table envelopes enter deterministic selection and lookup admission. | Untrusted binary data |
| Caller font bytes → optional kern admission | Attacker-controlled classic, Apple, and unknown headers, subtable lengths, pair counts, search helpers, keys, and values enter classification. | Untrusted binary data |
| Caller limits/budget → admission coordinator | Semantic ceilings and mutable shared resource accounting constrain every attacker-declared traversal. | Resource authority and mutable budget state |
| Caller scalar/GlyphIds → public query | Signed scalar input and opaque identifiers cross into admitted table-local lookup state. | Caller-controlled query values |
| Retained backing → published result | The caller can mutate retained bytes after admission or during a query. | Mutable retained `ByteView` |
| Private parser facts → public interface/policy | Only opaque glyphs, signed kerning, and explicit limits may cross the compatibility boundary. | Public API and package metadata |
| Generated hostile fixtures → four targets | Equivalent malformed and boundary cases must retain semantics across JS, Wasm, Wasm-GC, and native. | Portable conformance evidence |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-98-01-01 | Tampering | Malicious cmap bytes | high | mitigate | Checked widened offsets and lengths, contained format-4/12 envelopes, sorted ranges, mapped-glyph cardinality, raw-zero semantics, and hostile fixtures gate admission. | closed |
| T-98-01-02 | Denial of Service | Cmap record/group/segment/candidate loops | high | mitigate | Explicit ceilings, cumulative `max_work`, shared-budget preflight, precharged record/segment discovery, and exact-once aggregate subtraction cover successful and malformed paths. | closed |
| T-98-01-03 | Tampering | Retained source during scalar lookup | high | mitigate | Pre/post revision guards surround lookup; deterministic mid-query mutation tests prove post-read drift prevents `GlyphId` publication. | closed |
| T-98-01-04 | Tampering | Glyph range and format-4 address math | high | mitigate | Checked range-offset arithmetic, admitted mapped-glyph bounds, raw-zero handling, and opaque construction prevent forged or out-of-range glyph identities. | closed |
| T-98-01-05 | Spoofing | Cmap error-taxonomy confusion | medium | mitigate | Tests distinguish invalid scalar, malformed data, unsupported capability, revision state, and resource exhaustion; glyph zero is reserved for valid misses. | closed |
| T-98-01-06 | Tampering | Partial cmap publication | high | mitigate | Selection and validation remain inside the atomic `Font::open` transaction, followed by one final revision guard and sole `Font` construction. | closed |
| T-98-02-01 | Tampering | Malicious kern bytes | high | mitigate | Exact contained classic/Apple envelopes, canonical helpers, strict ordered unique keys, signed reads, pair bounds, and exact exhaustion gate recognized data. | closed |
| T-98-02-02 | Denial of Service | Optional directory/subtable/pair loops | high | mitigate | Explicit subtable/pair ceilings and separately checked semantic/shared budgets precharge attacker-controlled scans; malformed failures consume work and successful admission charges once. | closed |
| T-98-02-03 | Tampering | Retained source during kerning lookup | high | mitigate | Pre/post revision guards surround lookup; deterministic mid-query mutation tests prove post-read drift prevents adjustment publication. | closed |
| T-98-02-04 | Tampering | Foreign glyphs and pair-key construction | high | mitigate | Both opaque IDs are revalidated against the receiving font before checked pair-key lookup; admitted keys are in range and strictly ordered. | closed |
| T-98-02-05 | Spoofing | Kern absence/capability/data confusion | high | mitigate | Private `KernState` preserves Absent/Supported/Unsupported; zero is only absence/miss, unsupported queries return Capability, and malformed recognized bytes fail opening as Data. | closed |
| T-98-02-06 | Tampering | Partial kern publication | high | mitigate | Discovery, classification, validation, and required failure-path work charging complete before the single atomic `Font` publication; bytes and allocations remain uncommitted on failure. | closed |
| T-98-03-01 | Tampering | Hostile portable fixtures | high | mitigate | Exact malformed offset, length, order, range, and helper cases run through public open/query paths on all four targets without partial publication. | closed |
| T-98-03-02 | Denial of Service | Cross-target declared work | high | mitigate | Exact-fit, one-short, repeated-failure, ceiling, cumulative `max_work`, and shared-budget tests pass identically on JS, Wasm, Wasm-GC, and native. | closed |
| T-98-03-03 | Tampering | Mutation across public workflows | high | mitigate | All-query mutation/mutate-back coverage plus focused post-read interleaving tests enforce fail-closed behavior before any result is returned. | closed |
| T-98-03-04 | Tampering | Glyph/key correctness across workflows | high | mitigate | Public foreign-ID tests and private mapped-glyph/pair-key proofs revalidate receiving-font bounds before lookup and publication. | closed |
| T-98-03-05 | Spoofing | Portable error-taxonomy drift | high | mitigate | Black-box tests freeze InvalidInput, Data, Capability, State, and Resource facts across all supported targets. | closed |
| T-98-03-06 | Tampering | Interface or private-fact leakage | high | mitigate | Byte-stable generated `.mbti` and fail-closed policy permit only `glyph_for_scalar`, `kerning`, explicit kern ceilings, and the expanded limits constructor. | closed |
| T-98-SC | Tampering | Package/dependency publication | low | mitigate | Frozen commands and exact policy enforce four targets, exact source order, manifest description, no FFI/host surface, and `tchivs/mb-core` as the only runtime dependency. | closed |

*Only open threats at or above `workflow.security_block_on: high` count toward `threats_open`; this audit has no open threats at any severity.*

---

## Accepted Risks Log

No accepted risks. The early no-install supply-chain observation was superseded by the final exact manifest, source, target, dependency, and generated-interface policy enforcement.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-27 | 19 | 19 | 0 | Codex / GSD secure-phase |

Evidence:

- `98-REVIEW.md`: final deep review, 14 files, zero findings after four fixes.
- `98-REVIEW-FIX.md`: cumulative 4/4 review findings fixed, including failure-path cmap/kern work charging.
- `98-VERIFICATION.md`: 16/16 phase must-haves verified.
- `modules/mb-font/font/font_test.mbt` and `font_wbtest.mbt`: 65/65 on JS, Wasm, Wasm-GC, and native.
- Generated interface SHA-256 remained byte-stable; font policy, manifest-description, bilingual README, and diff checks passed.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-27
