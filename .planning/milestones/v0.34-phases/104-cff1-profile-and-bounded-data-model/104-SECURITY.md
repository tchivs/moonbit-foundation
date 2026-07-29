---
phase: 104
slug: cff1-profile-and-bounded-data-model
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-28
---

# Phase 104 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller bytes → SFNT/CFF profile | Caller-owned bytes and revision state enter checked directory and profile classification. | Untrusted binary structure, offsets, counts |
| CFF windows → retained facts | INDEX, DICT, charset, Encoding, FDArray, and FDSelect data become private structural facts. | Untrusted operands, ranges, SIDs, CIDs |
| Selected collection face → table-local CFF | Root-relative TTC/OTC authority is adapted to one checked CFF table window. | Shared offsets and selected-face authority |
| Staged facts → outline source | Validation, revision state, and resource authority gate private publication. | Retained descriptors and ledger charges |
| CFF reducer → existing glyf workflows | New private CFF dispatch must preserve qualified public glyf behavior. | Closed outline-source variant |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-104-01 | Tampering | CFF offset coordinate spaces | high | mitigate | Checked table windows and collection rebasing tests in `collection_wbtest.mbt`. | closed |
| T-104-02 | Denial of Service | INDEX counts and extents | high | mitigate | Checked arithmetic and exact preflight precede traversal and retained allocation. | closed |
| T-104-03 | Tampering | Typed DICT singleton semantics | high | mitigate | Typed schemas enforce arity, value domains, defaults, and duplicate rejection. | closed |
| T-104-04 | Information Disclosure | Structured error detail | low | accept | Deterministic stage/category contexts expose no ambient or broad caller data. | closed |
| T-104-05 | Tampering | SID/CID and charset resolution | high | mitigate | Complete range/cardinality validation and bounded standard-plus-String SID domain. | closed |
| T-104-06 | Elevation of Privilege | FDSelect environment selection | high | mitigate | Formats 0/3 only, full range/sentinel/FD validation, one descriptor per GID. | closed |
| T-104-07 | Denial of Service | Range expansion and FDArray validation | high | mitigate | Authority preflight covers actual lookup, work, and peak allocation before traversal. | closed |
| T-104-08 | Repudiation | Multi-fault keying errors | medium | accept | Stable encounter/stage precedence and exact/one-short tests make failures reproducible. | closed |
| T-104-09 | Tampering | TTC/OTC offset rebasing | high | mitigate | Root-relative records and checked table-local windows are tested on selected collections. | closed |
| T-104-10 | Denial of Service | Structural work and allocation | high | mitigate | Named ceilings, exact work/peak-allocation charging, and one-short authority regressions. | closed |
| T-104-11 | Tampering | Source mutation and partial publication | high | mitigate | Final revision guard precedes one atomic ledger commit and retained publication. | closed |
| T-104-12 | Elevation of Privilege | Partial CFF outline-source construction | high | mitigate | Private constructors require one complete admitted CFF1 aggregate. | closed |
| T-104-13 | Repudiation | Error precedence | medium | accept | Generated multi-fault fixtures lock deterministic state/resource/capability/data outcomes. | closed |
| T-104-14 | Tampering | Glyf compatibility drift | high | mitigate | Frozen standalone and collection glyf fingerprints plus full native/all-target gates. | closed |
| T-104-15 | Tampering | PaintType/StrokeWidth semantic boundary | high | mitigate | Exact zero is accepted; every well-formed non-zero CffNumber is rejected as Capability. | closed |
| T-104-16 | Tampering | Capability versus malformed encounter order | high | mitigate | Incremental DICT parsing reduces each complete entry before scanning later bytes; double-fault tests cover both orders. | closed |
| T-104-17 | Tampering | Admission publication and budget ledger | high | mitigate | Rejected fixtures assert no descriptor and unchanged bytes, allocations, peak allocation, and work. | closed |
| T-104-18 | Tampering | Existing CFF-02 and glyf behavior | low | accept | Name/CID keying, public glyf fingerprints, 1204 native tests, and four-target checks remain green. | closed |
| T-104-19 | Repudiation | Parser versus reducer error contexts | medium | mitigate | Tests distinguish parser-level Data contexts from completed-entry typed schema/capability contexts. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-104-01 | T-104-04 | Structured errors contain deterministic parser facts only and no ambient or broad caller data. | GSD Phase 104 review | 2026-07-28 |
| AR-104-02 | T-104-08 | Deterministic multi-fault precedence is contract-tested; no security authority is bypassed. | GSD Phase 104 review | 2026-07-28 |
| AR-104-03 | T-104-13 | Error selection is reproducible and does not publish partial state or consume unapproved authority. | GSD Phase 104 review | 2026-07-28 |
| AR-104-04 | T-104-18 | Private CFF changes are fenced by focused keying and public glyf regression suites. | GSD Phase 104 review | 2026-07-28 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-28 | 19 | 19 | 0 | GSD secure-phase ASVS L1 |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-28
