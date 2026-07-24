# Phase 86: Ancillary-Aware Preflight and Shared-Machine Integration - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Finish atomic admission for the selected non-interlaced indexed compression
profile. Before any eager byte, chunk lease, or budget mutation, calculate
selected-depth geometry, actual PLTE, canonical shortest tRNS, and exact
Stored/Fixed output/work facts; admit once and keep the existing acknowledged
machine as the only output path.

</domain>

<decisions>
## Implementation Decisions

### Selected candidate admission
- **D-01:** `PngFrameFacts` remains the sole owner of IHDR, PLTE, canonical
  tRNS, IDAT, and IEND offsets. Build both exact candidate facts before choosing
  Fixed-on-tie or Stored fallback, then retain only the selected frame/output/
  work facts for admission.
- **D-02:** Charge the supplied budget exactly once, only after every selected
  output and work limit check succeeds. All rejection paths leave writer bytes,
  chunk state/lease exposure, and budget unchanged.

### Shared machine integration
- **D-03:** Pass the admitted selected plan/facts through the existing
  `PngEncodeMachine` lifecycle for both eager and caller-buffered APIs. No new
  stream encoder, output buffer, staging container, or separate accounting path
  is permitted.

### Boundary evidence
- **D-04:** Direct tests must prove exact selected output/work limits pass;
  one-less output/work rejects atomically; palette-capacity overflow and
  checked-arithmetic failure also perform no budget charge or observable output.
- **D-05:** Exercise both a Fixed winner and Stored fallback with actual
  palette/transparency facts at each selected non-interlaced Type-3 depth.
  Hostile lease schedules and independent chunk-origin parsing remain Phase 87.

### the agent's Discretion
- Reuse the repository's existing exact-limit, budget-observation, writer-spy,
  and chunk-constructor test helpers rather than inventing a second oracle.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 86 goal, requirements, criteria, and scope guard.
- `.planning/REQUIREMENTS.md` — INDEXCOMP-03 atomic contract.
- `.planning/research/v028-INDEXED-PNG-COMPRESSION.md` — selected accounting and admission boundary.
- `.planning/phases/85-indexed-compression-api-and-fixed-wire-contract/85-CONTEXT.md` — locked API/producer decisions.
- `.planning/phases/85-indexed-compression-api-and-fixed-wire-contract/85-VERIFICATION.md` — verified frame selection and shared producer baseline.
- `modules/mb-image/png/encode.mbt` — indexed preflight, `PngFrameFacts`, and budget charge seams.
- `modules/mb-image/png/stream_encode.mbt` — sole acknowledged machine and chunk construction.
- `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt` — public atomic-admission tests.

</canonical_refs>

<code_context>
## Existing Code Insights

- Phase 85 already has private Stored/Fixed candidate selection and a shared
  indexed producer beneath the existing matcher.
- Indexed construction still has the single preflight-to-machine seam where
  selected facts and one budget charge must be made authoritative.
- Eager writer and chunk APIs both converge at that same machine, so admission
  must be settled before either facade observes state.

</code_context>

<specifics>
## Specific Ideas

The user prioritizes code and tests over release automation and authorizes the
optimal scoped choice; no presentation or delivery work belongs here.

</specifics>

<deferred>
## Deferred Ideas

Dynamic indexed compression, adaptive filters, indexed Adam7 compression,
hostile lease schedules, independent chunk-origin wire parsing, four-target
qualification, release automation, FFI, copied trees, and new public wrappers
remain out of scope.

</deferred>

---

*Phase: 86-Ancillary-Aware Preflight and Shared-Machine Integration*
*Context gathered: 2026-07-24*
