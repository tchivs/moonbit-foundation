---
phase: 106
slug: cubic-path-and-public-ttc-integration
status: verified
threats_open: 0
threats_total: 18
threats_closed: 18
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: 2026-07-29
verified: 2026-07-29
---

# Phase 106 — Security

> Per-phase security contract for standalone and collection-selected static CFF1 admission and native cubic outline publication.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller-owned font bytes → complete admission | Attacker-controlled SFNT/CFF directories, common tables, CharStrings, matrices, subroutines, and collection records validate before `Font` publication. | Untrusted binary data and structural facts |
| Retained descriptor → selected Type 2 VM | Only a checked receiving-font `GlyphId`, immutable environment, and retained exact authority may reach the sole VM. | Glyph identity, ByteView, VM facts |
| Exact rational geometry → public `Path2` | Rational matrix results convert to finite `Double` values only at the `Point2` boundary. | Numeric geometry |
| VM/path authority → caller and ancestors | Every allocation and unit of attacker-controlled work is preflighted before use and committed once. | Budget counters and allocation limits |
| Mutable source → atomic query | Authorized probes may observe revision changes before execution, during fetch, or after staging; no partial result may escape. | Revision identity and staged path |
| Collection root → selected face | Face index, root-relative table offsets, directory start, and table count remain bounded by the collection authority. | TTC/OTC directory coordinates |
| Selected CFF window → CFF-local parser | CFF-internal offsets remain relative to the checked table window, without copy or rebasing. | Table-local offsets |
| Shared CFF bytes → face-local common facts | Outline storage may be shared while cmap, hmtx, kern, head, hhea, and OS/2 remain selected-face local. | Mapping, metrics, kerning, line facts |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|-----------|----------|-----------|----------|-------------|-------------------------|--------|
| T-106-01 | Tampering | Shared geometry sink and per-GID command count | high | mitigate | One operator loop feeds shared geometry; retained/emitted command mismatches fail before publication and are covered by mismatch tests. | closed |
| T-106-02 | Denial of Service | `Path2` backing store and VM scratch | high | mitigate | Checked `capacity * 64`, exact allocation facts, caller/ancestor preflight before construction or VM reads, one final charge; exact/one-short tests pass. | closed |
| T-106-03 | Tampering | Rational-to-`Double` path boundary | high | mitigate | Matrices remain rational through quotient-plus-remainder conversion; invalid/non-finite conversion returns `Data` without a path. | closed |
| T-106-04 | Elevation of Privilege | Private CFF facts crossing public API | medium | mitigate | `AdmittedCff1` and outline-source variants remain private; only a complete aggregate projects into the opaque `Font`. | closed |
| T-106-05 | Spoofing | Type 2 width versus hmtx metric identity | medium | mitigate | Public metrics use face-local hmtx and retained bounds; a deliberate width-mismatch fixture freezes hmtx authority. | closed |
| T-106-06 | Repudiation | Error operation/context stability | low | accept | Structured fields remain stable and private operations are rebound at public boundaries; format-neutral public error regressions pass. | closed |
| T-106-07 | Spoofing | Receiving-font `GlyphId` validation | high | mitigate | Revision and cardinality checks precede descriptor lookup; foreign/out-of-range GIDs return no result and charge no budget. | closed |
| T-106-08 | Tampering | Retained `ByteView` during outline execution | high | mitigate | Initial, pre-execution, per-read, post-stage, and final revision guards return `State` with unchanged budgets. | closed |
| T-106-09 | Denial of Service | Selected VM/path arrays and work | high | mitigate | Exact retained path work is preflighted before VM/path allocation; final guard → one charge → immediate return; nested one-short tests pass. | closed |
| T-106-10 | Tampering | Retained versus emitted command cardinality | medium | mitigate | Command-count and actual-path-length disagreement plus checked capacity overflow fail before charge. | closed |
| T-106-11 | Repudiation | State/Resource/Capability/Data ordering | medium | mitigate | Multi-fault tests freeze category, code, public operation, context, result absence, and unchanged counters. | closed |
| T-106-12 | Information Disclosure | Partial path on error | low | accept | Staged `Path2` stays private through probes and final guard; all earlier failures expose only `Err`; success returns immediately after the sole charge. | closed |
| T-106-13 | Tampering | Root-relative versus table-local offsets | high | mitigate | Selected adapters retain collection-root directory authority while CFF parsing uses the checked table-local `TableWindow`; coordinate tests pass. | closed |
| T-106-14 | Spoofing | Shared CFF with face-local common tables | high | mitigate | Each face retains independent required common facts; divergent cmap/hmtx/kern/line fixtures share only CFF bytes and produce identical paths. | closed |
| T-106-15 | Tampering | Selected collection revision identity | high | mitigate | Collection opening revision is supplied to admission and checked at authorized execution/commit seams; mutation tests pass. | closed |
| T-106-16 | Denial of Service | Selected admission and outline authority | high | mitigate | Existing limits plus exact caller/ancestor preflight cover directory, CFF, VM, kern, and path allocations/work; selected one-short matrices pass. | closed |
| T-106-17 | Elevation of Privilege | Unsupported collection profiles | medium | mitigate | Closed dispatch accepts only `StaticGlyf` and supported static `Cff`; CFF2, variable, mixed, and other profiles retain capability rejection. | closed |
| T-106-18 | Tampering | `StaticGlyf` branch compatibility | medium | mitigate | Existing production arm and error precedence remain intact; standalone/collection fingerprints cover queries, paths, errors, and all charge dimensions. | closed |

*All 18 registered threats are closed. No open threats exist at or above the `high` blocking threshold.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-106-01 | T-106-06 | Low residual repudiation risk is bounded by stable structured error fields and format-neutral public operation regressions; private context text is not a public enum or authority boundary. | Phase 106 plan and security audit | 2026-07-29 |
| AR-106-02 | T-106-12 | Low residual disclosure risk is contained because staged paths never cross a public boundary on failure and every pre-commit failure exposes only structured `Err`. | Phase 106 plan and security audit | 2026-07-29 |

---

## Verification Evidence

- `moon test modules/mb-core/math --target native`: 91/91 passed.
- Exact path charge: 4/4 passed.
- Atomic outline: 4/4 passed.
- Standalone CFF1: 4/4 passed.
- Selected CFF1: 2/2 passed.
- Static-glyf compatibility: 5/5 passed.
- Positive mid-glyph caller/ancestor one-short authority: 2/2 passed.
- Format-neutral public errors: 1/1 passed.
- Full repository native suite: 1281/1281 passed.
- `moon check --target all`: 0 errors.
- Final Phase 106 code review: clean, 0 findings across 19 files.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-29 | 18 | 18 | 0 | `gsd-security-auditor` (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-07-29
