---
phase: 107
slug: hostile-licensed-and-four-target-qualification
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-30
---

# Phase 107 — Security

> ASVS L1 security closeout for hostile, licensed, four-target, and native
> benchmark qualification. All threats were authored in the six plans before
> execution; no high-severity threat was accepted or left open.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Upstream acquisition → licensed staging | Only pinned archives, declared members, licenses, and hashes may enter staging. | Externally authored OTF/license bytes and provenance. |
| Host oracle → canonical evidence | Two independent readers and closed adapters must agree before evidence publication. | Parsed CFF facts, outcomes, and SHA-256 identities. |
| Private carrier → public observations | Licensed bytes and private FD facts remain package-private; only format-neutral observations cross. | Mappings, metrics, bounds, paths, errors, and B8 snapshots. |
| Mutable source → staged publication | Revision checks and atomic promotion prevent partial or stale publication. | Qualified font state and generated evidence bundles. |
| Portable target runners → comparison | Four isolated target records are normalized only for declared runner/target fields. | Deterministic semantic observations from js, wasm, wasm-gc, and native. |
| Native benchmark → recorded baseline | Correctness output is bound before timing; capture requires a clean tracked workspace. | Raw samples, workload output, host/toolchain facts, and aggregate statistics. |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-107-01-01 | Spoofing | caller host identities | high | mitigate | Closed roles, paths, versions, hashes, provenance, and invoked-digest reconciliation; exercised by generator and qualification gates. | closed |
| T-107-01-02 | Tampering | oracle independence | high | mitigate | Distinct adapters, substitution negatives, exact semantic agreement, and structural-only OTS; review confirmed independent oracle flow. | closed |
| T-107-01-03 | Tampering | canonical outcomes | high | mitigate | Literal assertion trace binds error, GID, publication, and real caller/ancestor B8 for all 53 hostile rows. | closed |
| T-107-01-04 | Denial of service | hostile corpus | high | mitigate | Closed bounded recipes and exact/one-short limits; four targets each observed 53/53 hostile rows. | closed |
| T-107-01-05 | Information disclosure | local paths | low | accept | Committed evidence retains roles and digests only; absolute handoff paths remain ignored and run-scoped. | closed |
| T-107-02-01 | Spoofing | upstream assets/licenses | high | mitigate | Exact official URL, tag, archive member, license length, and hash checks. | closed |
| T-107-02-02 | Tampering | semantic/profile facts | high | mitigate | Two-reader agreement plus exact profile/FD and OTS structural gates. | closed |
| T-107-02-03 | Elevation of privilege | archive extraction | high | mitigate | Declared members only with path, link, collision, and expansion rejection. | closed |
| T-107-02-04 | Repudiation | licensed lineage | high | mitigate | External and generated authorship/license records remain separate and cross-linked to exact identities. | closed |
| T-107-02-05 | Denial of service | partial promotion | high | mitigate | Both bundles publish in one recoverable transaction; ordinary exceptions roll back and termination rolls forward. | closed |
| T-107-03-01 | Spoofing | local module resolution | high | mitigate | Frozen empty-cache workspace with canonical tracked roots and digests. | closed |
| T-107-03-02 | Tampering | generated carrier | high | mitigate | Exact reconstruction, single-owner digest/chunk scans, and no hand-edit path. | closed |
| T-107-03-03 | Information disclosure | private facts | high | mitigate | Package-private carrier and generator-delimited fact-only private regions. | closed |
| T-107-03-04 | Elevation of privilege | public/private boundary | high | mitigate | No private exports or evidence-package references to private mb-font data. | closed |
| T-107-03-05 | Repudiation | expected facts | high | mitigate | All 53 canonical source locators and private mirrors are mandatory and drift-negative tested. | closed |
| T-107-04-01 | Spoofing | carrier/public facts | high | mitigate | Single carrier with field-by-field public observations and exact target comparison. | closed |
| T-107-04-02 | Information disclosure | private FD facts | high | mitigate | Private FD assertions remain in the existing white-box package and are not exported. | closed |
| T-107-04-03 | Tampering | hostile outcomes | high | mitigate | Generator-delimited literal rows, exact mirror/source checks, and stale-field negatives. | closed |
| T-107-04-04 | Elevation of privilege | mutation hooks | high | mitigate | Existing no-op hooks only, one callback, exact state-error precedence, and atomicity tests. | closed |
| T-107-04-05 | Repudiation | budget/publication | high | mitigate | Every failure carries four B8 snapshots and publication state from the actual operation budgets. | closed |
| T-107-05-01 | Spoofing | target/toolchain/module | high | mitigate | Exact targets, toolchain, host lock, local roots, and substitution negatives. | closed |
| T-107-05-02 | Tampering | records/normalization | high | mitigate | Closed schemas, read-back hashes, and explicit target/runner-only projection. | closed |
| T-107-05-03 | Elevation of privilege | evidence cleanup | high | mitigate | Strict child, link-free, marker, product, and write-swap gates. | closed |
| T-107-05-04 | Tampering | API/dependency/source | high | mitigate | Independent interface, import, dependency, source, and capability policy checks. | closed |
| T-107-05-05 | Repudiation | documentation claims | medium | mitigate | Exact claim boundary and fixture/licensing policy tests. | closed |
| T-107-05-06 | Information disclosure | local paths | low | accept | Records retain repository-relative identities and approved host facts only. | closed |
| T-107-06-01 | Spoofing | command/toolchain/module | high | mitigate | Fixed command and exact toolchain/host with frozen local resolution. | closed |
| T-107-06-02 | Tampering | workload/correctness | high | mitigate | Tracked carrier/assets/GIDs/digests and correctness-before-timing. | closed |
| T-107-06-03 | Tampering | budget measurements | high | mitigate | One factory plus static/dynamic checks proving fresh budgets per operation. | closed |
| T-107-06-04 | Repudiation | dirty provenance | high | mitigate | Capture requires clean committed inputs and fails closed before benchmark execution when dirty. | closed |
| T-107-06-05 | Tampering | samples/statistics | high | mitigate | Raw hashes, exact sample order/count, statistic recomputation, and read-only audit contract. | closed |
| T-107-06-06 | Repudiation | interpretation | high | mitigate | Closed observation-only claim and forbidden-field negatives. | closed |
| T-107-06-07 | Information disclosure | host facts | low | accept | Only approved reproducibility facts are recorded; secrets and user paths are forbidden. | closed |

*Only open threats at or above the configured `high` threshold count toward
`threats_open`. There are none.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-107-01 | T-107-01-05 | A run-scoped ignored handoff must carry an absolute caller path, but no such path enters committed evidence. | GSD plan contract | 2026-07-30 |
| AR-107-02 | T-107-05-06 | Relative repository identities and approved host facts are necessary for reproducibility and disclose no secret. | GSD plan contract | 2026-07-30 |
| AR-107-03 | T-107-06-07 | Approved OS/CPU/toolchain facts are necessary for an observation-only native baseline; paths and secrets are prohibited. | GSD plan contract | 2026-07-30 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-30 | 33 | 33 | 0 | Codex / GSD ASVS L1 short-circuit |

Evidence includes the six executed plan summaries, final code review
(`0 Critical / 0 Warning`), generator and qualification negative probes, the
four-target FontQualification run (`275/275`, `53/53`, `4/4` per target), and
the workspace-wide four-target regression (`1287/1287` per target).

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-30
