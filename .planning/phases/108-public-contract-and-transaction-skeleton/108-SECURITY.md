---
phase: 108
slug: public-contract-and-transaction-skeleton
status: verified
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: 2026-07-30
verified: 2026-07-30
---

# Phase 108 — Security

> ASVS L1 verification of the plan-authored STRIDE register. All blocking
> threats are mitigated; the single low-severity accepted risk is recorded
> explicitly below.

## Trust Boundaries

| Boundary | Description | Data crossing |
|----------|-------------|---------------|
| Caller → `mb-text` | Hostile public shaping request enters the closed contract | Scalars, tags, choices, limits, `Budget`, retained `Font` |
| `mb-text` → `mb-font` | Private staged value crosses the opaque shaping transaction seam | Immutable staged run facts and text-side `ResourceCharge` |
| `mb-font` → `mb-core` | Complete authority reaches the budget hierarchy | Checked aggregate `ResourceCharge` |
| Retained source → request scope | Mutable retained font bytes are observed during a synchronous transaction | Source revision and opaque font authority |
| Private representation → public interface | Generated interfaces and immutable accessors define the publication boundary | Opaque glyph/run values; no raw source or table authority |
| Repository → quality evidence | Policy, generated interfaces, tests, and qualification outputs substantiate release claims | Source inventories, semantic identities, target records |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-108-01 | Tampering | Scalar array / retained source | high | mitigate | Full scalar validation and snapshot in `modules/mb-text/text/shape.mbt`; entry and final revision guards in `modules/mb-font/font/shape_transaction.mbt`. | closed |
| T-108-02 | Spoofing / Tampering | `GlyphId` authority | high | mitigate | Private physical `Font` owner and owner check in `modules/mb-font/font/font.mbt`, exercised before table access. | closed |
| T-108-03 | Denial of Service | Charge / budget | high | mitigate | Checked immutable composition and complete hierarchy preflight in `modules/mb-core/budget/budget.mbt`; one transaction commit. | closed |
| T-108-04 | Information Disclosure | Scope / run representation | medium | mitigate | Private scope state, copied private run storage, and sealed generated interfaces expose no source, table, probe, or commit handle. | closed |
| T-108-05 | Tampering | Signed run arithmetic | high | mitigate | Checked signed add, negation, and narrowing in `modules/mb-core/checked/checked.mbt`; checked projection in `shape.mbt`. | closed |
| T-108-06 | Elevation of Privilege | Public nonempty route | high | mitigate | Public nonempty shaping fails closed with `CapabilityUnavailable` before publication or charge. | closed |
| T-108-07 | Tampering | Signed addition | high | mitigate | Sign-specific overflow bounds precede addition; exact MIN/MAX tests cover the boundary. | closed |
| T-108-08 | Tampering | Signed negation | high | mitigate | Only `Int64::MIN` is rejected; boundary tests verify the rule. | closed |
| T-108-09 | Spoofing | `UInt64` → `Int64` projection | high | mitigate | Numeric maximum is proved before representation reinterpretation. | closed |
| T-108-10 | Repudiation | Arithmetic error identity | medium | mitigate | Stable `ArithmeticOverflow` code, operation, and context facts are asserted by tests. | closed |
| T-108-11 | Spoofing | Glyph owner | high | mitigate | Physical owner enforcement rejects a distinct same-range font while accepting aliases. | closed |
| T-108-12 | Tampering / Elevation of Privilege | Escaped scope / retained source | high | mitigate | Shared active cell, `defer` invalidation, revision checks, and exact closed-scope `State` error make escaped aliases inert. | closed |
| T-108-13 | Tampering / Denial of Service | Budget hierarchy | high | mitigate | Combined checked charge, full preflight, final source guard, and one `Budget::charge` call preserve atomicity. | closed |
| T-108-14 | Tampering | Caller scalar array | high | mitigate | Every Unicode scalar is validated before the request-owned copy; mutation regression proves snapshot behavior. | closed |
| T-108-15 | Spoofing | Generated positioned glyph | high | mitigate | Generated provenance invokes owner-checking metrics; foreign-glyph regression rejects cross-font facts. | closed |
| T-108-16 | Denial of Service | Limits / budget | high | mitigate | Both `ShapeLimits` fields are nonzero and exact input/output ceilings plus budget preflight are enforced. | closed |
| T-108-17 | Tampering | RTL / total arithmetic | high | mitigate | Adjustments, RTL advance negation, and totals use checked operations; no fallible work follows the sole commit. | closed |
| T-108-18 | Information Disclosure | Run / generated interface | medium | mitigate | Run records are copied privately and policy rejects raw arrays, source bytes, table facts, probes, and commit handles. | closed |
| T-108-19 | Repudiation | Error-stage winner | medium | mitigate | Executable combined-fault tests enforce `InvalidInput → State → Data → Capability → Resource` with budgets unchanged. | closed |
| T-108-20 | Elevation of Privilege | Public nonempty authority | high | mitigate | Black-box tests and policy prove no public nonempty success path exists in Phase 108. | closed |
| T-108-21 | Tampering | Retained `Font` / shared `Budget` | high | mitigate | Synchronous guarded transaction, repeated revision checks, one final charge, and no persistent cache. | closed |
| T-108-22 | Tampering | Module DAG / policy | high | mitigate | Exact dependency and source inventories enforce `mb-text → mb-font → mb-core`, direct `mb-text → mb-core`, and no reverse edge. | closed |
| T-108-23 | Information Disclosure | Generated interfaces | high | mitigate | Exact semantic allowlists and leak-pattern negatives reject raw authority and private scope operations. | closed |
| T-108-24 | Spoofing | v0.34 compatibility claim | high | mitigate | Font policy retains all 85 qualified lines plus exactly four additions; FontQualification binds production and test identities for the additive transaction seam. | closed |
| T-108-25 | Repudiation | Error / atomicity evidence | medium | mitigate | Policy binds named precedence, mutation, ancestor, ownership, and atomicity tests to stable facts. | closed |
| T-108-26 | Denial of Service | Hostile scalar / limit / overflow input | high | mitigate | Required lanes enumerate js, wasm, wasm-gc, and native; boundary and workspace suites pass on all targets. | closed |
| T-108-27 | Elevation of Privilege | Fixture / probe / commit authority | high | mitigate | Policy rejects public fixtures, probes, commits, and nonempty success symbols; generated interfaces contain none. | closed |
| T-108-28 | Tampering | Retained authority / final commit | high | mitigate | Revision probes, aggregate preflight, final guard, sole commit, and named mutation/ancestor tests close the window. | closed |
| T-108-29 | Information Disclosure | No-UI / no-external-integration boundary | low | accept | The phase intentionally has no UI, SDK, service, registry, or external integration surface. Residual future-drift risk is bounded by the approved no-UI contract, UI safety audit, API-coverage gate, and fail-closed policy scans. | closed — accepted |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-108-01 | T-108-29 | Phase 108 deliberately exposes no UI or external-integration surface. Treating possible future scope drift as a low residual risk is preferable to inventing unused controls; the no-UI, API-coverage, and policy gates detect any later expansion. | GSD auto-chain using developer-approved optimal default | 2026-07-30 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-30 | 29 | 29 | 0 | `gsd-security-auditor` + GSD orchestrator |

## Verification Evidence

- Security verdict before accepted-risk closure: 28 mitigated, 1 low accepted disposition, 0 blocking open.
- Code review: clean after three capped iterations; five findings resolved.
- Goal verification: 20/20 must-haves, 13/13 prohibitions, no gaps or human checks.
- `moon test --target all --frozen`: 1326/1326 on the final native summary, exit 0 for the all-target command.
- `mb-text`: 20/20 on js, wasm, wasm-gc, and native.
- `mb-font`: 284/284 on js, wasm, wasm-gc, and native.
- FontQualification: four equal target records, semantic SHA-256 `80b9f93b381a38d6f2c4a15abb1fab63da10cdc1f89513190d55a2f6cc4751a9`.
- API coverage verify-pre: passed; no external-API integration detected.
- UI review: formal no-UI applicability passed with six pillars N/A and zero findings.

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-07-30
