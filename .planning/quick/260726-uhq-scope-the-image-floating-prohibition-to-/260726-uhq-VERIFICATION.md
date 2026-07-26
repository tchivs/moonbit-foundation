---
quick_id: 260726-uhq
verified: 2026-07-26T14:05:00Z
status: passed
score: 6/6 must-haves verified
commit: d0afa0e3c0b551cfa79eb656798c1668fc2de6d3
evidence:
  - "ImageFloatingPolicySelfTest ran without -Lane, exited 0, and printed the exact success marker."
  - "The self-test invoked the live image portable prohibition and existing image negative matrix; all negatives failed closed."
  - "Independent inventory scan found exactly 4 processing to_double calls, 9 processing decimal literals, 2 resize Double tokens, 4 resize to_double calls, and no other production-ops floating inventory."
  - "mb-image ops passed 48/48 on js, wasm, wasm-gc, and native."
  - "Commit d0afa0e changes only scripts/quality/Invoke-MoonQuality.ps1; image implementation sources are unchanged."
gaps: []
---

# Quick 260726-uhq Verification

**Goal:** Scope the image floating prohibition to audited typed color/blend math while retaining fail-closed integer geometry and indexing.

**Verdict:** PASSED. All six must-haves are proven by the committed policy implementation, its production self-test seam, direct source inventory, existing negative matrix, and independently rerun four-target ops tests. SUMMARY statements were not treated as evidence.

## Must-Have Verification

| # | Must-have | Status | Evidence |
|---|---|---|---|
| 1 | Image geometry and source-index mapping remain checked UInt64 operations with no floating conversion or backend rounding. | VERIFIED | The production policy rejects every `round`, `floor`, or `ceil` call before applying exceptions. The live portable-source scan passed. The self-test rejects a `floor()` mapping and all five geometry literal spellings. Actual resize inventory contains no decimal/exponent literal and only the two audited bounded remainder/extent conversions. |
| 2 | Only the audited Phase 10 box-blur color average and i66 bilinear blend fractions may use `Double`/`to_double` in production ops. | VERIFIED | `Assert-ImageOpsFloatingPolicy` binds each admitted anchored form to its canonical file and function and requires cardinality one. Independent scanning found exactly four `window.to_double()` uses in `processing.mbt`, two private `Double` parameters plus four remainder/extent conversions in `resize.mbt`, and zero floating tokens in every other production ops file. |
| 3 | Any new `Double`, `to_double`, inferred decimal/exponent literal, `round`, `floor`, or `ceil` token outside the exact audited inventory fails closed. | VERIFIED | After removing each exact allowed form once, the helper rejects residual `Double`, `.to_double(`, floating literals, and rounding calls. Self-test negatives cover unauthorized conversions, duplicate/missing/moved forms, extra/missing/moved typed-color literals, and `0.5`, `1.`, `.5`, `1e3`, `1.0e-3`; each must match its exact policy-specific error. The `value1e3` identifier boundary control passes. |
| 4 | Public image operation signatures cannot introduce `Double` geometry parameters. | VERIFIED | An explicit public-declaration `Double` regex rejects public ops declarations before exception processing. The self-test's public `resize(width : Double)` negative fails for the exact expected reason; residual-token enforcement provides a second backstop. |
| 5 | The existing image negative matrix and a dedicated no-write floating-policy self-test pass. | VERIFIED | `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -ImageFloatingPolicySelfTest` ran with no `-Lane`, exited 0, called `Assert-ImagePortableProhibitions` and `Assert-ImageQualificationNegativeFixtures`, reported all existing image negatives rejected, and printed `Image floating policy self-test passed.` Worktree status remained unchanged apart from the already-untracked SUMMARY. |
| 6 | Current processing and bilinear implementations remain unchanged and pass on all four targets. | VERIFIED | Commit `d0afa0e` changes only the quality script. Independent runs of `moon -C modules/mb-image test ops --target {js,wasm,wasm-gc,native} --frozen` each passed 48/48 with zero failures. |

## Exact Production Inventory

| File | Allowed inventory observed | Status |
|---|---|---|
| `processing.mbt` | Four typed `rr`/`gg`/`bb`/`aa` divisions by `window.to_double()`; nine literals: two `1.0`, Rec.709 `0.2126`/`0.7152`/`0.0722`, four `0.0` accumulators; zero explicit `Double` | EXACT |
| `resize.mbt` | Private `x_fraction : Double` and `y_fraction : Double`; `remainder_y / height` and `remainder_x / width` conversions (four `.to_double()` calls total); zero decimal/exponent literals | EXACT |
| Other production ops files | Zero `Double`, `.to_double(`, decimal/exponent literals, or rounding calls | EXACT |

## Adversarial Boundary Coverage

| Boundary / negative | Evidence | Status |
|---|---|---|
| Identifier `value1e3` | Positive self-test input passes without exponent-literal misclassification | VERIFIED |
| Decimal/exponent spellings | Parameterized exact-error negatives cover `0.5`, `1.`, `.5`, `1e3`, `1.0e-3` | VERIFIED |
| Wrong y axis | `remainder_x.to_double() / height.to_double()` receives the dedicated wrong-axis error | VERIFIED |
| Wrong x axis | `remainder_y.to_double() / width.to_double()` receives the dedicated wrong-axis error | VERIFIED |
| Missing/duplicate/moved forms | Processing and resize forms are cardinality-checked and function-bound; focused negatives match exact errors | VERIFIED |
| Existing floating resize negative | Existing image qualification matrix reports `floating resize` rejected | VERIFIED |

## Artifact and Wiring Checks

| Artifact / link | Status | Evidence |
|---|---|---|
| `scripts/quality/Invoke-MoonQuality.ps1` | VERIFIED | Substantive 214-line policy/self-test addition; working copy matches `d0afa0e`; no TBD/FIXME/XXX/PLACEHOLDER markers found. |
| `260726-uhq-SUMMARY.md` | VERIFIED | Exists with complete frontmatter and focused evidence; intentionally uncommitted per plan. |
| General image source prohibition → ops floating policy | WIRED | `Assert-ImageSourceTextProhibitions` calls `Assert-ImageOpsFloatingPolicy` for every `modules/mb-image/ops/*` production source. |
| No-Lane self-test dispatch | WIRED | Top-level `ImageFloatingPolicySelfTest` dispatch invokes the production helper/matrices and returns before the Lane requirement. |
| Policy → processing/resize canonical forms | WIRED | Exact path selection, anchored form removal, cardinality checks, and function ownership checks are active in the production helper. |

## Focused Execution

| Command | Result |
|---|---|
| `Invoke-MoonQuality.ps1 -ImageFloatingPolicySelfTest` | PASS, exit 0; portable prohibition and existing negative matrix included |
| `moon ... test ops --target js --frozen` | PASS, 48/48 |
| `moon ... test ops --target wasm --frozen` | PASS, 48/48 |
| `moon ... test ops --target wasm-gc --frozen` | PASS, 48/48 |
| `moon ... test ops --target native --frozen` | PASS, 48/48 |
| `git diff --check` | PASS |
| Commit scope | PASS; only `scripts/quality/Invoke-MoonQuality.ps1` modified |

## Notes

- The opaque-alpha allowlist is correctly bound to the actual production function `load_linear_premultiplied_rgb8`; this resolves the plan's stale shorthand without widening the allowed expression inventory.
- The two additional maintenance adjustments in the commit update stale quality assertions for the current mutable-view gate and README wording. Both remain inside the sole planned quality-script artifact and are exercised by the live portable/negative checks.
- Full Required was not run.

## Gaps

None.

_Verifier: gsd-verifier_
