# Phase 64: GrayAlpha16 Decode Qualification - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Qualify the explicit GrayAlpha16 decoder across legal filters and Adam7, hostile
resource/metadata boundaries, frozen generic compatibility, and all portable
targets. No new decode/encode capability is introduced.

</domain>

<decisions>
## Implementation Decisions

- **D-01:** Use independent non-symmetric Type-4/16 vectors that exercise full
  `Ghi,Glo,Ahi,Alo` preservation after each supported filter and Adam7 pass.
- **D-02:** Exercise eager and chunk preservation through malformed metadata,
  resource limits, split input, and terminal paths; each failure remains atomic
  and generic decoding remains unchanged.
- **D-03:** Run the ordinary full PNG package on wasm, wasm-gc, js, and native;
  no wrapper, target-specific fixture, or generated expected output substitutes
  for that command.

### the agent's Discretion

- Reuse the smallest public helper/vector patterns. Keep production code frozen
  unless a qualification test exposes a genuine Phase 62/63 contract defect.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` — GRA16DEC-03 scope.
- Phase 62 and 63 verification reports — frozen eager/chunk contract.
- `.planning/research/v020-SUMMARY.md` and PITFALLS — endianness/resource rules.
- `modules/mb-image/png/*_test.mbt` — existing filters, Adam7, hostile input,
  frozen vector, and all-target PNG evidence patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

- The preservation profile already shares the only decoder machine; qualification
  tests must not add a profile-specific traversal or buffer.
- Generic RGBA8 high-byte canonicalization is the primary compatibility baseline.

</code_context>

<deferred>
## Deferred Ideas

- Colour-managed conversion, a public conversion API, generic result widening,
  new storage, FFI, release automation, wrappers, and copied-source workflows.

</deferred>
