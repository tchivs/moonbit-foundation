---
phase: 54-bounded-type-4-16-encoder
verified: 2026-07-22T21:35:59Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 54: Bounded Type-4/16 Encoder Verification Report

**Phase Goal:** Library users can encode compatible packed U16 GrayAlpha images through explicit eager and caller-buffered factories as bounded, non-interlaced Type-4/16 PNGs.
**Verified:** 2026-07-22T21:35:59Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can choose explicit eager or caller-buffered GrayAlpha16 PNG factories and receive a non-interlaced PNG with colour type 4, bit depth 16, and each source pair serialized as `Ghi,Glo,Ahi,Alo`. | ✓ VERIFIED | Both complete public factory families exist: `PngEncoder::new_graya16*` (`png.mbt:224-260`) and `PngChunkEncoder::new_graya16*` (`stream_encode.mbt:164-225`). Their combined forms bind `GrayAlpha16` and `None` interlace. The profile emits depth `0x10`, type `0x04`, and interlace `0` (`stream_encode.mbt:1125-1131`); the U16 scalar reader maps each lane separately through checked component access (`encode.mbt:427-445`). Literal non-symmetric eager and chunk tests assert `12 34 A7 C5 BE 0F 5A 76` after the filter byte (`encode_test.mbt:1018-1029`, `stream_encode_test.mbt:944-964`). |
| 2 | A compatible GrayAlpha16 image can use None or Adaptive filtering with Stored, FixedOrStored, or DynamicOrFixedOrStored compression through the same bounded encoding behavior, without image-sized staging. | ✓ VERIFIED | Admission returns a four-byte stride (`encode.mbt:141-160`), and all three planned states choose the profile-aware filtered cursor whenever the U16 wire predicate holds (`stream_encode.mbt:629-663`). The one preflight function threads `profile`, `channels`, filter, and strategy through Stored, Fixed, and Dynamic planning before one budget charge (`encode.mbt:1601-1806`). Six-pair eager and chunk matrices pass; the Adaptive literal test proves a four-byte Sub stride (`encode_test.mbt:1060-1099`, `stream_encode_test.mbt:967-1000`). Production buffers are only fixed RFC/algorithm bounds (not raster-sized): the matcher window is 262 bytes and dynamic tables have fixed alphabet sizes (`encode.mbt:914-951,1197-1237`). |
| 3 | Incompatible inputs and capability, geometry, output, work, or budget failures leave the eager writer empty and expose neither a usable caller-buffered lease nor partial output. | ✓ VERIFIED | Generic source validation precedes all row traversal (`encode.mbt:54-160`); profile non-interlace rejection precedes preflight (`encode.mbt:1524-1564`); all limits precede the sole `budget.charge` (`encode.mbt:1783-1806`). `new_graya16_with_strategies` returns the preflight error before constructing a chunk encoder (`stream_encode.mbt:208-225,591-606`). The public all-six-pair regression checks equal typed eager/chunk errors, zero writer position, unchanged budget, and every sentinel lease byte for incompatible, geometry, output, work, and budget failures (`stream_encode_test.mbt:2460-2501,2627-2643`). |
| 4 | A caller-buffered GrayAlpha16 encoder advances only for accepted bytes and preserves its replay/terminal contract across supported strategy selections. | ✓ VERIFIED | `pull` calls the U16 mutation guard before `destination.set`, then advances the machine and total only after a destination write succeeds and is acknowledged (`stream_encode.mbt:366-451`). Ordinary six-pair drains assert `total_written == emitted output length` for each GrayAlpha16 route (`stream_encode_test.mbt:565-584,967-1000`). The named Fixed and Dynamic Adaptive replay test accepts framing bytes, mutates a checked alpha component, then proves zero-write, unchanged total, untouched first and later leases, and same sticky error; it also asserts the selected Fixed/Dynamic DEFLATE routes (`stream_encode_test.mbt:2818-2886`). |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Private GrayAlpha16 profile and explicit eager factory family. | ✓ VERIFIED | Exists, substantive, and exposes the four additive eager constructors; the combined form selects the private profile and no interlace. |
| `modules/mb-image/png/encode.mbt` | Strict GrayAlpha16 admission and component-aware U16 PNG wire reader. | ✓ VERIFIED | Exists, substantive, and supplies the 4-byte geometry fact plus per-component little-endian-to-PNG-byte-order mapping for every traversal. |
| `modules/mb-image/png/stream_encode.mbt` | Explicit caller-buffered factories, profile-aware cursors/replay, and Type-4/16 IHDR. | ✓ VERIFIED | Exists, substantive, and the public combined factory directly enters `PngEncodeMachine::new_with_profile`; the machine owns all three cursor routes and pre-write replay validation. |
| `modules/mb-image/png/encode_test.mbt` | Focused eager framing, wire-order, strategy, and Adaptive-stride evidence. | ✓ VERIFIED | Real `OwnedImage` fixtures write non-symmetric checked U16 gray/alpha bytes; assertions inspect actual generated PNG bytes. |
| `modules/mb-image/png/stream_encode_test.mbt` | Caller-buffered parity, atomic admission, and sticky replay evidence. | ✓ VERIFIED | Real public factories, mutable leases, resource budgets, and source mutation are exercised; no synthetic preflight substitute is used. |

`verify.artifacts` reports all 5/5 Plan-01 artifacts and the Plan-02 stream test artifact substantive and present.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `stream_encode.mbt` | Eager/chunk `graya16` factories select `GrayAlpha16` with `None` interlace. | ✓ WIRED | Both factory families use the same private profile; the chunk combined factory calls `PngEncodeMachine::new_with_profile`. |
| `encode.mbt` | `stream_encode.mbt` | Profile-aware preflight, filtered cursor construction, plan selection, and replay. | ✓ WIRED | The machine calls profile-aware preflight and retains profile-aware Stored, Fixed, and Dynamic cursors. |
| `encode.mbt` | `encode_test.mbt` | Component-aware scalar reader produces four non-symmetric wire lanes. | ✓ WIRED | The automated literal-pattern probe missed the prose token `Ghi`; manual link tracing proves `_png_wire_byte` is the producer and the focused test asserts its literal output. |
| `stream_encode_test.mbt` | `stream_encode.mbt` | Public combined factories enter the machine before a chunk encoder can exist. | ✓ WIRED | The all-pair atomicity helper calls `new_graya16_with_strategies` directly and observes only `Err` on rejected construction. |
| `stream_encode_test.mbt` | `encode.mbt` | Checked U16 mutation is caught before a caller lease write. | ✓ WIRED | The replay test uses `set_component_byte`; `pull` invokes the shared U16 revision guard before `destination.set`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `encode.mbt` | Wire byte | Legal little-endian packed `ImageView` component storage → `_png_wire_byte` | Checked `get_component_byte(pixel,row,component,storage_byte)` yields actual source data, not a static fallback. | ✓ FLOWING |
| `stream_encode.mbt` | Filter/planner/replay bytes | Profile-aware cursors over the same source and four-byte stride | Stored, Fixed, and Dynamic selected states all read the scalar producer; no separate GrayAlpha16 data source exists. | ✓ FLOWING |
| `stream_encode_test.mbt` | Eager/chunk comparison bytes | Public eager writer and caller-owned chunk leases | Generated bytes are compared only after real drains; `total_written` is checked against accepted output. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Type-4/16 factories, wire lanes, six strategy pairs, atomic admission, and sticky replay on every supported target | `moon -C modules/mb-image test png --target all --frozen --filter '*GrayAlpha16*'` | 7 passed, 0 failed on wasm, wasm-gc, js, and native. | ✓ PASS |
| Legacy PNG routes remain compatible with the additive profile extension | `moon -C modules/mb-image test png --target native --frozen` | 203 passed, 0 failed. | ✓ PASS |

### Probe Execution

Step 7c: **SKIPPED** — neither Phase 54 plan/summary declares a probe and `scripts/` contains no conventional `probe-*.sh` file.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GRAYA16-02 | `54-01-PLAN.md` | Explicit eager and caller-buffered compatible U16 Gray+Alpha factories emit non-interlaced Type-4/16 with `Ghi,Glo,Ahi,Alo` wire order. | ✓ SATISFIED | Truth 1; literal wire tests and all-target focused suite prove factory, IHDR, and lane order. |
| GRAYA16-03 | `54-01-PLAN.md`, `54-02-PLAN.md` | Reuse shared bounded preflight/filter/planning/replay path and keep unsupported/resource failures pre-exposure atomic. | ✓ SATISFIED | Truths 2–4; six-pair, atomicity, and replay tests execute the public route. |

`REQUIREMENTS.md` maps exactly GRAYA16-02 and GRAYA16-03 to Phase 54; no Phase-54 requirement is orphaned from the plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, TODO/HACK/placeholder marker, empty implementation, or hard-coded empty output was found in the five Phase-54 PNG files. | ℹ️ Info | No completion-blocking stub or debt marker found. |
| `54-PATTERNS.md`, `54-RESEARCH.md` | multiple | `git diff --check 5cb48fe..HEAD` reports trailing whitespace in planning prose only. | ℹ️ Info | Does not affect the PNG implementation or any phase must-have; no source/runtime whitespace finding. |

### Disconfirmation Checks

- **Partial Type-4 implementation:** falsified. The implementation changes not just IHDR but source admission, U16 scalar mapping, all three planner cursors, and replay validation; literal tests expose both gray and alpha lanes.
- **Misleading parity-only test:** falsified. Eager/chunk equality is supplemented by literal IHDR/scanline assertions, four-byte Adaptive residuals, selected DEFLATE-route checks, and source-mutation failure tests.
- **Uncovered failure path:** falsified for the phase contract. The all-pair helper covers incompatible source plus geometry, output, work, and budget limits, and asserts writer/budget/lease state rather than merely an error value.
- **Scope widening:** falsified. The production diff touches only the existing PNG package and adds one profile/factory composition; it contains no FFI, target branch, source copy, alternate encoder, or image-sized buffer. The locked Phase-53 descriptor rejects big-endian GrayAlpha16 before PNG admission, so the Plan-01 big-endian parity wording was correctly not implemented as a model-widening exception.

### Gaps Summary

No gaps found. The only key-link query miss was a literal `Ghi`-token check; source-to-test tracing and the passing non-symmetric wire test verify that connection. Phase 55-owned hostile zero/one/ragged capacity vectors and frozen public interoperability evidence are deferred by the roadmap and are not missing Phase-54 deliverables.

---

_Verified: 2026-07-22T21:35:59Z_
_Verifier: the agent (gsd-verifier)_
