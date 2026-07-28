---
phase: 103-hostile-licensed-and-four-target-qualification
audited: 2026-07-28
status: SECURED
asvs_level: 1
threats_total: 24
threats_mitigated: 21
threats_accepted: 3
threats_open: 0
block_on: high
---

# Phase 103 Security Verification

**Verdict:** SECURED

All 24 threats declared by the three Phase 103 plans were checked against the
current implementation and executable evidence. Twenty-one mitigations are
present and effective. The remaining three threats were declared with an
`accept` disposition and are recorded below as low-risk supply-chain
assumptions. There are no open blocking or non-blocking threats.

## Mitigation Results

| Threat | Severity | Result | Verification evidence |
|---|---:|---|---|
| T-103-01-01 | high | MITIGATED | Parent and derivative length/digest, TTC structure, shared payload, checksums, and standalone binding are independently validated by the generator and oracle. |
| T-103-01-02 | high | MITIGATED | The ordered corpus and generated source use closed schemas and byte-for-byte check-only regeneration. |
| T-103-01-03 | medium | MITIGATED | Manifest and oracle retain source, author, license, redistribution, notice, generator, date, and parent/derivative digests. |
| T-103-01-04 | medium | MITIGATED | Runtime source policy rejects ambient filesystem, network, host-font, and FFI access; intake is explicit and digest-gated. |
| T-103-01-05 | high | MITIGATED | Declared-count limits, checked work, and retained-allocation preflights precede attacker-sized traversal. |
| T-103-01-06 | medium | MITIGATED | Normal generation and check-only verification have separate write paths; `-Check` leaves the worktree unchanged. |
| T-103-02-01 | high | MITIGATED | Both licensed faces traverse public collection APIs and the independent standalone DejaVu semantic oracle. |
| T-103-02-02 | high | MITIGATED | The executable 97-case inventory closes hostile, limit, budget, and arithmetic behavior. |
| T-103-02-03 | high | MITIGATED | Tests and evidence validate every structured error field, publication result, and eight-field caller/ancestor budget snapshot. |
| T-103-02-04 | high | MITIGATED | Revision guards and public/private mutation tests reject stale collection and inherited `Font` observations. |
| T-103-02-05 | high | MITIGATED | CFF/CFF2/variable profiles remain inspect-only and WOFF execution remains unavailable before admission or charge. |
| T-103-02-06 | medium | MITIGATED | Qualification uses opaque public facts; mutation hooks remain test-private; the 85-line public surface is locked. |
| T-103-02-07 | medium | MITIGATED | Named standalone identities, source hashes, commit/tree identity, and per-target results prevent compatibility spoofing. |
| T-103-03-01 | high | MITIGATED | Closed record schemas, exact toolchain identities, fixture hashes, and focused-source hashes reject forged records. |
| T-103-03-02 | high | MITIGATED | Semantic comparison removes only top-level `target` and `runner`, then read-backs and hashes every record and comparison. |
| T-103-03-03 | high | MITIGATED | Records retain attributable commands, pass totals, sources, commit, tree, and toolchain data. |
| T-103-03-04 | medium | MITIGATED | Strict-child containment, component link checks, staged writes, and post-initialization link-swap probes protect evidence paths. |
| T-103-03-05 | high | MITIGATED | Four serial target directories, bounded tests, measured runtime, and a 20-minute CI timeout bound qualification work. |
| T-103-03-06 | high | MITIGATED | Known-file cleanup, managed markers, exact CI topology, quoted-key handling, no `continue-on-error`, and success-only upload protect evidence ownership. |
| T-103-03-07 | high | MITIGATED | Policy locks 85 API lines, 13 production sources, five imports, one dependency, four targets, and deferred capability negatives. |
| T-103-03-08 | medium | MITIGATED | Exact derivative lineage, license, notice, sharing, and digest policy rejects provenance tampering. |

## Accepted Risks

| Threat | Severity | Accepted rationale | Verified condition |
|---|---:|---|---|
| T-103-01-SC | low | Phase 103 adds no package or dependency and relies on SHA-256-pinned tooling already owned by repository policy. | The audited implementation introduces no package/dependency edge; toolchain and CI identities are exact and pinned. |
| T-103-02-SC | low | The qualification slice retains the existing `mb-font -> mb-core` sole runtime dependency. | `modules/mb-font/moon.mod.json` and policy independently confirm one dependency and five allowed imports. |
| T-103-03-SC | low | CI action and toolchain supply-chain trust is accepted only under pinned identities and an unchanged dependency graph. | Both CI actions are commit-SHA pinned; moon, moonc, and moonrun match exact policy identities; the dependency graph is unchanged. |

## Final Evidence

- Generator check, fixture policy, foundation policy, evidence-boundary link-swap
  probes, and target-all compilation pass.
- Four ordered target records each report 14 focused gates and 152/152 package
  tests.
- All 29 evidence negatives pass and semantic comparison reports `equal=true`.
- Goal verification reports 16/16 must-haves, no human-verification items, and no
  gaps.
- Code-review remediation closes all reported findings, including nested record
  drift, evidence-path swaps, deferred-capability aliases, CI upload topology,
  quoted YAML keys, step-level continuation, and exact toolchain identity.

No implementation remediation remains.
