---
phase: 68-rgba16-decode-qualification
verified: 2026-07-23
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
---

# Phase 68: RGBA16 Decode Qualification Verification

## Result

**Passed.** `RGBA16DEC-04` is covered by independent public wire fixtures,
public eager/chunk hostile regressions, first-IDAT resource-boundary tests,
and the ordinary PNG package on every supported target.

| Truth | Evidence | Result |
|---|---|---|
| Independent Type-6/16 filters and Adam7 retain every explicit lane | `png_test.mbt` commits `df5ff5c`, `85e8036`, `9a4c32c`, `922a962`; summary records fixed all-filter and all-seven-pass fixtures, exact component assertions, and frozen generic projection. | Verified |
| Eager and chunk hostile behavior stays safe and generic remains frozen | Task 2 public tests exercise truncated, malformed, profile-invalid and one-less-resource inputs through both `decode_rgba16` and `new_rgba16`, with typed no-result/sticky behavior. | Verified |
| Eight-byte normal/Adam7 resource preflight is atomic | `stream_decode_wbtest.mbt` commits `fcab20d`, `59f5609`; exact/one-less output, image and work matrices assert first-IDAT rejection before lifecycle/outcome exposure. | Verified |
| Portable ordinary package evidence is complete | `moon -C modules/mb-image test png --target wasm --frozen`, `wasm-gc`, `js`, and `native` each passed **245/245** serially. | Verified |

## Focused Evidence

- `moon -C modules/mb-image test png --target js --frozen --filter '*rgba16*'` passed **10/10**.
- The qualification plan explicitly prohibits encoder-derived or generated decoder oracles; the implementation summary records hand-authored CRC-valid literals and no production source/API change.
- Existing Phase 66 and 67 contracts remain covered by their verification reports; Phase 68 adds qualification only.

## Scope Check

No alternative decoder, public API, copied source tree, FFI, release script, or target-specific expectation was introduced. The pre-existing untracked Phase 66 `research-plan-input.json` remains outside this phase and uncommitted.

**Verification status:** passed
