---
phase: 105
slug: bounded-type-2-validation-and-retained-metrics
status: verified
verdict: SECURED
threats_open: 0
asvs_level: 1
created: 2026-07-29
---

# Phase 105 — Security

> Per-phase security contract: retroactive STRIDE threat register and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller bytes → Type 2 VM | Untrusted CharStrings, subroutines, DICT numbers, and masks enter the checked interpreter. | Opcodes, operands, byte windows |
| Caller limits → execution authority | Public limits and budget state authorize VM work, calls, geometry, retained objects, and scratch storage. | Named ceilings and ancestor budgets |
| Mutable source → staged facts | Revision guards protect parsing and execution from caller mutation. | Byte revision and deterministic errors |
| Staged glyphs → admitted font | All-GID bounds and metrics remain private until validation, authority preflight, and final revision checks succeed. | Bounds, metrics, charges, outline source |
| CFF width → public metrics | Type 2 width facts are validated without overriding face-local `hmtx` authority. | Glyph metrics and retained facts |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| TH-105-01 | Denial of Service | Resource and allocation amplification | high | mitigate | Fixed limits, 11-slot frame sizing, four preallocated VM arrays, cumulative retained-object authority, and exact/one-short adversarial tests. | closed |
| TH-105-02 | Tampering / Denial of Service | Arithmetic overflow and unsafe narrowing | high | mitigate | Checked Q16.16 arithmetic, exact allocation-free wide rational cancellation, checked CFF number conversion, and boundary regressions. | closed |
| TH-105-03 | Denial of Service | Recursive or cyclic subroutines | high | mitigate | Iterative frames, semantic depth 10, physical capacity 11, call/work ceilings, and depth/cycle tests avoid host recursion. | closed |
| TH-105-04 | Tampering | Subroutine bias, index, window, and termination | high | mitigate | Count-derived bias, signed index validation, checked INDEX views, and strict return/endchar/trailing-byte rules. | closed |
| TH-105-05 | Tampering / Denial of Service | Hint-mask framing desynchronization | high | mitigate | Stem arity and ceilings, nonzero-stem mask requirement, exact mask payload length, and truncation/limit tests. | closed |
| TH-105-06 | Tampering | Mutation and revision TOCTOU | high | mitigate | Common revision preference guards fetch/decode/operator/GID exits and the final pre-commit admission boundary. | closed |
| TH-105-07 | Tampering / Denial of Service | Partial publication or caller charge | critical | mitigate | All-GID results stay staged; combined authority is preflighted before one final revision guard, commit, and publication. | closed |
| TH-105-08 | Tampering | Failed operator or GID leaks geometry | high | mitigate | Geometry ceilings precede retained state; bounds materialize only after glyph success and cumulative authority; first failure returns no staged result. | closed |
| TH-105-09 | Tampering | Type 2 width overrides public metrics | medium | mitigate | Admitted facts retain checked `hmtx` authority and public metrics read only the face-local `hmtx` window. | closed |

*Only open threats at or above `workflow.security_block_on: high` count toward `threats_open`.*

---

## Verification Evidence

- `modules/mb-font/font/limits.mbt:223-278` and `cff_type2.mbt:1345-1366` establish checked depth, frame, and scratch authority.
- `modules/mb-font/font/cff_type2_fixed.mbt:45-476` implements checked fixed-point and exact wide rational arithmetic.
- `modules/mb-font/font/cff_type2.mbt:1134-1329,1470-2157` enforces subroutine, mask, revision, staging, and retained-resource contracts.
- `modules/mb-font/font/cff_admission.mbt:1667-1748` combines structural and VM authority before the sole commit and publication seam.
- `105-REVIEW-FINAL.md` records a clean deep final review with zero findings.
- Security audit rerun: `moon test modules/mb-font/font --target native -j 2` — 243/243 passed.
- Post-fix workspace evidence: native 1252/1252 passed; `moon check --target all` completed with 0 errors and 31 existing warnings.
- No unregistered threat flags were found.

---

## Security Audit Trail

| Audit Date | Method | Threats Total | Closed | Open | Verdict |
|------------|--------|---------------|--------|------|---------|
| 2026-07-29 | Retroactive STRIDE, ASVS L1 | 9 | 9 | 0 | SECURED |

---

## Sign-Off

- [x] All threats have a disposition.
- [x] Every high/critical threat has implementation and test evidence.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` and `verdict: SECURED` set in frontmatter.

**Approval:** SECURED 2026-07-29
