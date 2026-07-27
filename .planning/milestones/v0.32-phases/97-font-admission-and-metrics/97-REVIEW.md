---
phase: 97-font-admission-and-metrics
reviewed: 2026-07-27T02:53:25Z
depth: deep
files_reviewed: 14
files_reviewed_list:
  - modules/mb-font/CHANGELOG.md
  - modules/mb-font/font/cursor.mbt
  - modules/mb-font/font/directory.mbt
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/font_wbtest.mbt
  - modules/mb-font/font/font.mbt
  - modules/mb-font/font/limits.mbt
  - modules/mb-font/font/metrics.mbt
  - modules/mb-font/font/moon.pkg
  - modules/mb-font/font/tables.mbt
  - modules/mb-font/moon.mod.json
  - modules/mb-font/README.mbt.md
  - policy/foundation.json
  - scripts/quality/Assert-Policy.ps1
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 97: Code Review Report

**Reviewed:** 2026-07-27T02:53:25Z
**Depth:** deep
**Files Reviewed:** 14
**Status:** clean

## Summary

The exact original 14-file Phase 97 scope was reviewed at HEAD `9c6e450a`
after fixes `d8d947ac`, `3d724111`, and `c2fcaa49`. No remaining correctness,
security, or maintainability defect was found.

The requested clean-gate repairs are effective:

| Gate | Deep-review result |
| --- | --- |
| Terminal format-4 glyph validation | Direct and indexed terminal mappings now use the ordinary mapping formula, reject non-zero glyph IDs outside `maxp.numGlyphs`, and include the terminal span in aggregate work. |
| Semantic cmap work preflights | Encoding-record discovery and each cumulative format-4 segment-discovery pass check both `FontLimits.max_work` and the shared `Budget` before entering the attacker-count-driven loop. |
| Directory selector ledger | Directory search facts use a bounded selector helper, selector work is included in the shared directory total, and discovery preflight and final charge reuse that same total. |

The broader admission call chain was also re-traced from `Font::open` through
directory discovery and normalization, aggregate charge formation, checksum
and profile validation, required-table admission, cmap/name/post envelopes,
metric-index construction, retained-source revision checks, and public metric
queries. Earlier fixes remain present: overlap and normalization work,
directory and `loca` allocation ceilings, repeated lookup/table scans,
format-4 and format-12 structural and glyph-cardinality validation, canonical
cmap/name ordering, name-language and post-name domains, `head`
`glyphDataFormat`, malformed-data classification, and pre-charge post-name
limits.

The independent policy selector still fails closed through its exact Phase 97
interface allowlist. Constructor, snake-case, camel-case, acronym, compound
filesystem/host/FFI, and deferred font-capability aliases are covered by
negative probes, while production interface generation is rooted at
`modules/mb-font`.

The repository knowledge graph was indexed first. Its current extractor
exposed file and documentation nodes for `mb-font` but no MoonBit function
call edges, so the required MoonBit call-chain analysis was completed by full
source inspection and targeted direct call-site tracing.

Verification completed successfully:

- `moon -C modules/mb-font check --target all --frozen --deny-warn` passed.
- `moon -C modules/mb-font test --target all --frozen --deny-warn -p tchivs/mb-font/font` passed 39/39 tests on each of `wasm`, `wasm-gc`, `js`, and `native`.
- `Assert-FontFoundationPolicy -PolicyPath .\policy\foundation.json` passed, including generated-interface and deferred-capability negative checks.
- `policy/foundation.json` parsed as JSON and `Assert-Policy.ps1` parsed through the PowerShell AST without errors.
- `git diff --check` passed for the exact review scope.

All reviewed files meet the Phase 97 quality gate. No issues found.

## Narrative Findings (AI reviewer)

No Critical, Warning, or Info findings remain in the reviewed scope.

---

_Reviewed: 2026-07-27T02:53:25Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
