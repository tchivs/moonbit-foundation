---
phase: 100
slug: portable-font-qualification
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-07-27
verified_commit: 8897f1c17bd7b35cd41213c7d00055265f13b953
---

# Phase 100 — Security

> Retroactive verification of the six plan-time STRIDE registers against the
> final implementation, deep code review, four-target qualification evidence,
> and hosted Required evidence.

## Trust Boundaries

| Boundary | Description | Data crossing |
|----------|-------------|---------------|
| External archives → pinned intake | Network bytes are admitted only after immutable-address, length, SHA-256, member-layout, executable-manifest, and identity checks. | MoonBit toolchain/core and DejaVu archive bytes |
| Canonical fixtures → generated MoonBit | Generated literals must reproduce the licensed immutable fixture exactly and pass deterministic `-Check`. | Font bytes, provenance, license, oracle facts |
| Untrusted font bytes → public Font API | Parser envelopes, checked arithmetic, budgets, and publication rules must fail closed on malformed or exhausted input. | SFNT tables, cmap records, glyph outlines |
| Independent oracle → test expectations | A closed versioned PowerShell reader, not `mb-font`, owns complete expected vectors and fingerprints. | 74 ordered Path2 commands and public facts |
| Target runner → qualification evidence | Evidence is published only after exact focused and full-package target tests succeed. | Target identity, test identity, semantic record |
| Four target records → normalized comparison | Normalization may remove only runner metadata and must preserve all semantic facts. | js, wasm, wasm-gc, and native evidence |
| Required wrapper → process session/tree | Bounded execution must contain, terminate, reap, and report every descendant on Windows and POSIX. | Commands, stdout/stderr, exit and termination state |
| CI workflow → uploaded artifacts | Only exact successful focused evidence may use the passing artifact boundary; Required diagnostics remain disjoint. | Font evidence and Required diagnostics |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Verified mitigation/evidence | Status |
|-----------|----------|-----------|----------|-------------|------------------------------|--------|
| T-100-01-01 | Tampering | DejaVu archive intake | high | mitigate | Locked archive/member size and SHA checks precede extraction and repository generation. | closed |
| T-100-01-02 | Spoofing | Independent oracle | high | mitigate | Versioned schema 1.1.0 closed PowerShell SFNT oracle; unknown/drifted schema and generated-source drift fail. | closed |
| T-100-01-03 | Tampering | Generated MoonBit bytes | high | mitigate | Literal reconstruction, exact length/SHA, and byte-for-byte generator `-Check` are enforced. | closed |
| T-100-01-04 | Repudiation | External licensing | medium | mitigate | Exact DejaVu notice, source identity, immutable hashes, and redistribution records are committed and checked. | closed |
| T-100-01-05 | Denial of service | Generated source compilation | medium | mitigate | Deterministic bounded chunks compile on js, wasm, wasm-gc, and native. | closed |
| T-100-01-SC | Tampering | Dependency supply chain | low | accept | Generation installs no package dependency and uses pinned repository tooling plus .NET BCL. | closed |
| T-100-02-01 | Tampering | cmap format-6 length fields | high | mitigate | Exact length, entry-count, evenness, checked arithmetic, and in-table envelope tests fail closed. | closed |
| T-100-02-02 | Elevation of privilege | cmap selection | high | mitigate | Only exact 1/0/6 coexistence is recognized; retained rank/lookup variants remain formats 4/12. | closed |
| T-100-02-03 | Denial of service | cmap admission work | medium | mitigate | The record scan is charged once; ignored format-6 bodies are never traversed or separately charged. | closed |
| T-100-02-04 | Repudiation | Public scope | medium | mitigate | Generated semantic interface and focused policy classifier confirm no public-surface expansion. | closed |
| T-100-02-SC | Tampering | Dependency supply chain | low | accept | The parser repair adds no package or runtime dependency and uses existing checked primitives. | closed |
| T-100-03-01 | Denial of service | Hostile font operations | high | mitigate | Exact and one-short FontLimits/work-budget cases exercise the public entry points and fail without publication. | closed |
| T-100-03-02 | Tampering | Target-specific outcomes | high | mitigate | One closed ID matrix runs without skips in four isolated supported-target invocations. | closed |
| T-100-03-03 | Spoofing | Target evidence | high | mitigate | Records are written only after exact tests succeed and bind source, fixture, toolchain, and test identity. | closed |
| T-100-03-04 | Repudiation | Partial publication | medium | mitigate | Structured Result assertions prove no Font, Path2, or stale value is published on failure. | closed |
| T-100-03-05 | Tampering | Evidence normalization | high | mitigate | Only target/runner fields are removed; every semantic field is canonicalized and byte-compared. | closed |
| T-100-03-SC | Tampering | Dependency supply chain | low | accept | Qualification adds no package or runtime dependency and uses pinned MoonBit/PowerShell tooling. | closed |
| T-100-04-01 | Elevation of privilege | Font capability boundary | high | mitigate | Source-aware policy rejects host/FFI/GUI/shaping/hinting/CFF/rasterization execution and extra dependencies. | closed |
| T-100-04-02 | Tampering | Public interface and inventory | high | mitigate | Exact 56-line interface, source/test inventory, imports, targets, and dependency edges are frozen with negative probes. | closed |
| T-100-04-03 | Spoofing | Focused target evidence | high | mitigate | Four complete passing target records, hostile IDs, semantic equality, and pinned identities are mandatory. | closed |
| T-100-04-04 | Tampering | Fixture provenance | high | mitigate | Exact hashes/license/redistribution, manifest order, generator drift, and oracle schema are verified. | closed |
| T-100-04-SC | Tampering | Dependency supply chain | low | accept | No package-manager or new runtime dependency is introduced. | closed |
| T-100-05-01 | Denial of service | Required child process | high | mitigate | Windows suspended-launch Job Object and POSIX verified session containment enforce bounded full-descendant termination and reaping. | closed |
| T-100-05-02 | Spoofing | Passing CI artifact | high | mitigate | Policy binds the exact upload step, success condition, full action SHA, artifact name, and focused path. | closed |
| T-100-05-03 | Tampering | Focused evidence | high | mitigate | Managed cleanup rejects link/reparse traversal; focused records and Required diagnostics remain disjoint and integrity-checked. | closed |
| T-100-05-04 | Repudiation | Required outcome | medium | mitigate | Deterministic JSON records command, timeout, streams, exit, tree termination, termination status, and final status. | closed |
| T-100-05-05 | Information disclosure | Diagnostics upload | low | accept | The distinct diagnostic artifact contains only build/test output and invocation metadata. | closed |
| T-100-05-SC | Tampering | CI action/toolchain supply chain | medium | mitigate | Actions use full commit SHAs; immutable prerelease assets are verified by archive/binary digests, exact layout, manifest, and identities before PATH promotion. | closed |
| T-100-06-01 | Tampering | Oracle command vectors | high | mitigate | Complete vectors, counts, and fingerprints are recomputed from the same array under schema 1.1.0 with drift checks. | closed |
| T-100-06-02 | Spoofing | Target outline fingerprint evidence | high | mitigate | Record construction is gated by the exact filtered 1/1 DejaVu assertion and records command/pass identity. | closed |
| T-100-06-03 | Tampering | Generated expectations | high | mitigate | Structured expectations come only from freshly recomputed oracle output and byte-compare in `-Check`. | closed |
| T-100-06-04 | Repudiation | Partial Path2 coverage | medium | mitigate | Exact lengths and every one of 74 ordered command variants/coordinates are structurally asserted. | closed |
| T-100-06-05 | Elevation of privilege | Runtime/public scope | high | mitigate | Symbols remain test-private; no runtime SHA dependency or public-interface change exists. | closed |
| T-100-06-06 | Denial of service | Focused qualification | low | accept | The immutable 74-command matrix and one filtered test per target remain bounded by existing target timeouts. | closed |
| T-100-06-SC | Tampering | Dependency supply chain | low | accept | Generation uses existing PowerShell/.NET and the content-addressed pinned MoonBit toolchain only. | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-100-01 | T-100-01-SC | Offline generation has no package-manager dependency; residual risk is limited to the pinned local runtime/toolchain. | Plan-time contract, verified by Codex | 2026-07-27 |
| AR-100-02 | T-100-02-SC | The bounded parser repair uses only existing primitives and adds no dependency edge. | Plan-time contract, verified by Codex | 2026-07-27 |
| AR-100-03 | T-100-03-SC | Qualification tooling introduces no runtime dependency or package installation. | Plan-time contract, verified by Codex | 2026-07-27 |
| AR-100-04 | T-100-04-SC | Policy and interface gates detect dependency expansion; residual low risk is accepted. | Plan-time contract, verified by Codex | 2026-07-27 |
| AR-100-05 | T-100-05-05 | CI diagnostics contain only non-secret build/test output and are separated from passing evidence. | Plan-time contract, verified by Codex | 2026-07-27 |
| AR-100-06 | T-100-06-06 | Fixed immutable vectors and target timeouts bound the focused qualification workload. | Plan-time contract, verified by Codex | 2026-07-27 |
| AR-100-07 | T-100-06-SC | Test generation has no new dependency edge and uses authenticated pinned tooling. | Plan-time contract, verified by Codex | 2026-07-27 |

## Verification Evidence

- Deep code review: `100-REVIEW.md`, status `clean`, 0 findings.
- Goal verification: `100-VERIFICATION.md`, status `passed`, 4/4 must-haves.
- Hosted run: `30297979654` on exact implementation commit
  `8897f1c17bd7b35cd41213c7d00055265f13b953`; all three jobs passed.
- Required artifact `8666037685`: `timed_out=false`, `exit_code=0`,
  `process_tree_terminated=true`,
  `termination_status=exited-session-terminated-verified`, `status=pass`.
- Font artifact `8665402336`: four supported targets passed with complete
  74-command assertions and equal semantic SHA-256
  `65b63177ed296ffa4cb1f46a4c6943d6036a71d70eb1b8409830a35e65fcdef8`.
- Policy matrix: canonical workflow plus 43 negative mutations passed,
  including immutable-address and installer-shell binding probes.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-27 | 35 | 35 | 0 | Codex (`gsd-secure-phase`, ASVS L1) |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks are documented in the Accepted Risks Log
- [x] `threats_open: 0` confirmed at the configured `high` blocking threshold
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-27
