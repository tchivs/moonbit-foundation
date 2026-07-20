# Phase 16: QOI policy and public example quality alignment - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the existing foundation policy and public-example quality checks accurately recognize the already-delivered QOI package and `qoi-portable` example. The phase must make the QOI-specific policy path fail closed on drift and pass for the checked implementation. It must not alter QOI behavior, reintroduce registry operations, restore or remove unrelated release-governance scripts, or reconcile older non-QOI inventory drift.

</domain>

<decisions>
## Implementation Decisions

### QOI policy inventory
- **D-01:** Treat `examples/qoi-portable` as the sixth approved `moon.work` member and preserve the five existing members unchanged.
- **D-02:** Add the existing public `tchivs/mb-image/qoi` package to the foundation policy with its checked package imports, production-source order, public constructor/trait surface, and all four portable targets. Include exactly the QOI source/test/vector files already produced; do not broaden unrelated `ops` publication inventory.
- **D-03:** Extend the policy assertions so a missing/extra QOI package import, target, interface entry, source order, or production file fails deterministically.

### Public consumer qualification
- **D-04:** Add `qoi-portable` to the existing public-example quality path with its public-import allowlist and exact one-line evidence on js, wasm, wasm-gc, and native.
- **D-05:** Keep the quality command bounded to QOI-related assertions and public-example execution. Do not invoke registry observation, credentials, publication, release qualification, or modify unrelated historical artifacts.

### the agent's Discretion
- Generate the policy semantic-interface baseline from the current MoonBit compiler output; choose the smallest local test/fixture edits necessary to prove the new negative cases.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit and scope
- `.planning/v0.4-v0.4-MILESTONE-AUDIT.md` — actual policy regression and explicit non-QOI exclusions.
- `.planning/phases/15-public-qoi-processing-example/15-VERIFICATION.md` — exact public-example output and four-target proof.
- `.planning/phases/14-canonical-qoi-encode-and-four-target-vectors/14-VERIFICATION.md` — existing QOI public package evidence.

### Policy and quality implementation
- `policy/foundation.json` — authoritative public package and publication-file inventory.
- `scripts/quality/Assert-Policy.ps1` — foundation workspace/package assertion implementation.
- `scripts/quality/Invoke-MoonQuality.ps1` — negative quality spine for public package policy drift.
- `scripts/quality/Test-PublicExamples.ps1` — public example isolation and target execution path.
- `moon.work` — approved workspace members.

### QOI evidence
- `modules/mb-image/qoi/moon.pkg` — exact public imports and target declaration.
- `modules/mb-image/qoi/qoi.mbt` — public values.
- `modules/mb-image/qoi/decode.mbt` and `modules/mb-image/qoi/encode.mbt` — trait implementations and public surface.
- `examples/qoi-portable/main/main.mbt` — exact portable output contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Foundation policy and its PowerShell assertions already validate exact workspace/package inventories and public interfaces.
- The QOI module and portable example already provide all required real four-target evidence; Phase 16 only connects them to the existing quality seams.

### Established Patterns
- Public package imports, supported targets, production order, and semantic interfaces are exact/fail-closed policy data.
- Public examples have target-neutral expected output and are executed from isolated workspace consumers.

### Integration Points
- `moon.work`, `policy/foundation.json`, and the three named quality scripts must agree with the existing QOI code and example.

</code_context>

<specifics>
## Specific Ideas

This is a narrow test-and-policy closure phase. The user prioritizes code and tests; registry/release automation remains expressly excluded.

</specifics>

<deferred>
## Deferred Ideas

- Historic `ops` publication-inventory drift and the audit’s separate registry/release-governance artifacts remain separate work.

</deferred>

---

*Phase: 16-QOI policy and public example quality alignment*
*Context gathered: 2026-07-20*
