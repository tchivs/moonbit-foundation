---
status: complete
type: resolved-debug-knowledge-base
updated: 2026-07-28
---

# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## required-colr-manifest-cwd — PNG structural generation wrote platform newlines into the shared manifest
- **Date:** 2026-07-27
- **Error patterns:** `Failed to canonicalize input filter directory README.missing.mbt.md`, `Generated artifact is stale or non-deterministic: fixtures/manifest.json`, COLR deterministic generated evidence, CRLF manifest drift
- **Root cause(s):** code: `Generate-PngStructuralVectors.ps1` writes raw platform-newline `ConvertTo-Json` text into the shared manifest; environment: Windows emits CRLF, producing raw bytes that violate the repository LF contract while Git filtering hides the drift
- **Fix:** added a platform-independent canonical text helper with CRLF/LF/no-terminal/repeated-terminal boundary self-tests and routed the PNG structural manifest write through it
- **Files changed:** `scripts/fixtures/Generate-PngStructuralVectors.ps1`
- **Why not caught:** the generator's existing checks covered fixture identity, digest, and generated tables but had no boundary contract for manifest newline bytes; Git normalization hid the raw-byte drift until a later deterministic generator compared the manifest
- **Recurrence guard:** `Assert-CanonicalTextContract` in `scripts/fixtures/Generate-PngStructuralVectors.ps1` exercises CRLF, LF, missing-terminal-newline, and repeated-terminal-newline inputs before every generation/check, while `ConvertTo-CanonicalText` enforces exactly one terminal LF at the manifest writer boundary
---

## ttc-work-precedence-order — TTC staged work authority conflicted with DSIG semantic precedence
- **Date:** 2026-07-28
- **Error patterns:** Phase 101 precedence blocker, `structural_work - 1`, declaration_work-1, structural_work-1, exact_work-1, `font-collection-dsig-version`, `font-collection-dsig-count`, `font-collection-dsig-flags`, `font-collection-search-facts`
- **Root cause(s):** contract/config: D-18 and its research/plan copies omitted the declaration-work and structural-work `max_work`/Budget preflights required before attacker-counted loops; code: `font_collection_parse_dsig_declaration` conflated early bounded record-count discovery with DSIG version/count-zero/flags semantics, placing those semantic failures before face/protected/alias validation
- **Fix:** split bounded DSIG record-count discovery from semantic declaration validation; preserved early tuple/count ceilings and declaration/structural preflights, deferred DSIG semantics until after face/protected/alias validation, and documented the declaration/structural/exact authority tiers
- **Files changed:** `modules/mb-font/font/collection_parser.mbt`, `modules/mb-font/font/collection_test.mbt`, `.planning/phases/101-collection-contract-and-bounded-envelope/101-CONTEXT.md`, `.planning/phases/101-collection-contract-and-bounded-envelope/101-RESEARCH.md`, `.planning/phases/101-collection-contract-and-bounded-envelope/101-03-PLAN.md`, `.planning/phases/101-collection-contract-and-bounded-envelope/101-02-SUMMARY.md`, `.planning/phases/101-collection-contract-and-bounded-envelope/101-03-SUMMARY.md`
- **Why not caught:** the Phase 101 verification/review gate had precedence tests, but they did not exercise declaration_work-1 or structural_work-1 under both authority sources and did not combine malformed face facts with DSIG version, zero-count, or flags errors
- **Recurrence guard:** `modules/mb-font/font/collection_test.mbt` tests `TTC-01 staged work authority has exact stable precedence boundaries` and `TTC-01 DSIG authority precedes faces but DSIG semantics follow them` freeze all three one-short tiers, both authority sources, tuple authority, and DSIG semantic conflicts
---
