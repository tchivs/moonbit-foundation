---
phase: 04-image-model-views-and-operations
verified: 2026-07-17T00:00:00Z
status: gaps_found
score: 10/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Owned-image construction enforces every declared storage, dimension, pixel, and work budget without trusting caller-supplied accounting."
    status: failed
    reason: "The public OwnedImage::new_operation API accepts width, height, pixels, and work independently from the validated descriptor and forwards them without equality checks. A public black-box repro constructed a 2x1, 2-pixel descriptor under a budget whose width, height, pixels, and work limits were all zero by passing four zero charge scalars; construction returned Ok."
    artifacts:
      - path: modules/mb-image/storage/owned_image.mbt
        issue: "Lines 50-73 expose and trust independent charge scalars, permitting resource-accounting undercharge."
    missing:
      - "Make operation allocation accounting non-forgeable: derive width, height, and pixels from the descriptor and validate/derive work from a closed operation contract, or make the scalar factory package-private behind trusted operation entry points."
      - "Add public black-box tests proving mismatched/zero charge scalars cannot construct a nonzero image and all budget counters remain atomic on rejection."
      - "Add a Required negative/source/interface gate that prevents a public forgeable accounting seam from returning."
  - truth: "Immutable and mutable image views honor the descriptor's packed or planar layout while enforcing each plane's validated range."
    status: failed
    reason: "ImageView::from_owned and MutImageView::from_owned always select plane 0, while get_byte/set_byte use packed channel_count*bytes_per_component addressing and do not reject Planar. A public black-box repro used valid disjoint planar ranges ordered [4..6), [0..2), [2..4): full-view access (0,0,0) returned Ok, while another valid logical pixel/channel attempted an offset beyond storage and returned Err. The API therefore exposes layout-dependent incorrect access instead of a safe planar contract or a structured capability rejection."
    artifacts:
      - path: modules/mb-image/storage/views.mbt
        issue: "Lines 54-69 and 248-263 retain only plane 0; lines 129-174 and 286-338 perform packed addressing without a PlaneLayout::Packed guard."
    missing:
      - "Either implement plane-aware immutable/mutable access for planar descriptors or reject planar full-view byte access and mutable acquisition with CapabilityUnavailable before any backing access."
      - "Add adversarial public tests for reordered/discontiguous planar ranges, padded planar rows, every channel/plane boundary, and unchanged sentinels on rejection."
      - "Extend generated storage cases and Required negatives so planar full-view access cannot silently regress to packed addressing."
---

# Phase 4: Image Model, Views, and Operations Verification Report

**Phase Goal:** `mb-image` exposes an explicit, memory-safe image representation and deterministic foundational operations that reuse `mb-core` and `mb-color` without embedding host or codec policy.
**Verified:** 2026-07-17
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Opaque metadata is bounded, canonically ordered, duplicate-free, exact, and uninterpreted. | VERIFIED | `metadata.mbt` validates all tokens/counts/totals before one `OwnedBytes` allocation; metadata tests passed on all four targets. |
| 2 | Metadata disposition is bounded, exclusive, ordered, and machine-readable. | VERIFIED | `MetadataDisposition::new` sorts fields and rejects within/across-category duplicates; operation tests exercise preserve/transform/discard/loss. |
| 3 | Every image description field and color/alpha/orientation/opaque-metadata identity is explicit and inspectable. | VERIFIED | `descriptor.mbt` exposes closed component/channel/layout/endianness/plane/metadata/orientation values; model tests passed 13/13 per target. |
| 4 | Invalid dimensions, arithmetic, stride, plane count/range, containment, and overlap reject before storage access/allocation. | VERIFIED | Checked descriptor pipeline validates positive dimensions, exact row shape, storage containment, and pairwise half-open disjointness; adversarial model tests pass. |
| 5 | Owned-image allocation is atomic and cannot undercharge declared image/work resources. | FAILED | Public `OwnedImage::new_operation` trusts caller-supplied width/height/pixels/work; focused black-box repro constructed a nonzero descriptor while those budget dimensions were all zero. |
| 6 | Retained immutable and callback-scoped mutable views safely honor packed and planar descriptors, including zero-copy crops. | FAILED | Full planar views use plane-0 plus packed addressing without a layout guard. Packed crop, empty-view, stale-handle, and disjoint split behavior is otherwise tested and correct. |
| 7 | Copy and flips are fresh, deterministic, padding-independent, and preserve metadata/orientation. | VERIFIED | `copy_flip.mbt` gates the three packed U8 formats, allocates fresh tight output, and copies logical bytes only; ops tests pass 18/18 per target. |
| 8 | All eight orientation mappings normalize fresh output to TopLeft against an independent oracle. | VERIFIED | Literal generator-owned 3x2 mappings are independent from production `orientation_destination`; all eight are consumed by behavioral tests. |
| 9 | Nearest resize and required RGB/RGBA alpha conversions are deterministic and reuse `mb-color`. | VERIFIED | Resize uses checked `floor(dst*src/dst_extent)` with preflighted maximum products; conversion calls `mb-color/alpha`; focused ops suite passes all targets. |
| 10 | Codec contracts are prefix-only and forward-only over Reader/Writer with explicit limits, budgets, diagnostics, progress, and dispositions. | VERIFIED | `contracts.mbt` exposes no Seeker/path/URL/registry; one-byte Reader and Writer doubles exercise short progress. |
| 11 | Five generated evidence tables, consumer links, rootless topology, four targets, exact interfaces/DAG/publication, and read-only gates fail closed. | VERIFIED | Generator `-Check`, five independent consumers, 23 image negatives, README checks, exact interfaces and package allowlist all passed in Required. |
| 12 | Deferred formats/codecs/registry/filesystem/host policy remain absent. | VERIFIED | Source/import classifiers and exact package DAG reject these surfaces; Phase 5 retains PPM ownership. |

**Score:** 10/12 truths verified; 2 failed; 0 behavior-unverified.

### Required Artifacts

| Artifact | Status | Details |
|---|---|---|
| `modules/mb-image/metadata/metadata.mbt` | VERIFIED | Substantive, imported by model/ops/codec, and behaviorally tested. |
| `modules/mb-image/model/descriptor.mbt` | VERIFIED | Substantive validated model, wired into storage/ops/codec. |
| `modules/mb-image/storage/owned_image.mbt` | BLOCKER | Substantive and wired, but public operation accounting is forgeable. |
| `modules/mb-image/storage/views.mbt` | BLOCKER | Substantive and wired, but planar full-view access uses packed addressing. |
| `modules/mb-image/ops/{copy_flip,orientation,resize,convert}.mbt` | VERIFIED | Fresh-output deterministic operation spine with executable tests. |
| `modules/mb-image/codec/contracts.mbt` | VERIFIED | Reader/Writer-only open traits and explicit bounded contracts. |
| `scripts/fixtures/Generate-ImageVectors.ps1` | VERIFIED | Byte-stable seven-artifact generation and independent orientation oracle. |
| `modules/mb-image/README.mbt.md` | VERIFIED | Executable on js, wasm, wasm-gc, and native. |

### Key Link Verification

| From | To | Status | Details |
|---|---|---|---|
| metadata | mb-core bytes/budget | WIRED | Exact values use retained `OwnedBytes`; allocation uses caller budget. |
| model | metadata + mb-color | WIRED | `ImageMetadata` retains opaque metadata and explicit color/profile identities. |
| storage | mb-core bytes leases | PARTIAL | Retention and callback invalidation are wired; planar addressing violates the descriptor link. |
| ops | storage + metadata + mb-color alpha | WIRED | Fresh image results, dispositions, and typed alpha calls are exercised. |
| codec | mb-core Reader/Writer | WIRED | Trait signatures and short-progress doubles use Reader/Writer only. |
| quality classifiers | policy/foundation.json | WIRED | Exact five-package topology, interfaces, imports, publication, targets, and fixture ownership passed. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Model contracts, all targets | `moon -C modules/mb-image test model --target all --frozen` | 13/13 per target | PASS |
| Storage contracts, all targets | `moon -C modules/mb-image test storage --target all --frozen` | 11/11 per target | PASS |
| Operation contracts, all targets | `moon -C modules/mb-image test ops --target all --frozen` | 18/18 per target | PASS |
| Codec contracts, all targets | `moon -C modules/mb-image test codec --target all --frozen` | 6/6 per target | PASS |
| Generated evidence | `pwsh -NoProfile -File ./scripts/fixtures/Generate-ImageVectors.ps1 -Check` | Seven artifacts byte-identical | PASS |
| Full Required lane | `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` | 171/171 per target; read-only proof passed | PASS |
| Focused planar/accounting repro | Temporary public black-box storage tests, native | Both tests passed: observed packed planar addressing and successful zero-scalar undercharge | CONFIRMED GAP |

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| IMAG-01 | SATISFIED | Explicit descriptor model and public inspection tests. |
| IMAG-02 | BLOCKED | Forgeable `new_operation` accounting violates pre-allocation resource enforcement. |
| IMAG-03 | BLOCKED | Planar full-view access does not honor validated plane layout/ranges. |
| IMAG-04 | SATISFIED | Packed zero-copy crops, canonical empty immutable views, stale mutable handles, and disjoint splits pass. |
| IMAG-05 | SATISFIED | Copy/flips/orientation/resize/conversions pass deterministic four-target tests. |
| IMAG-06 | SATISFIED | Per-operation executable metadata dispositions pass. |
| IMAG-07 | SATISFIED | Prefix/Reader/Writer codec seam has no ambient registry/filesystem/seek dependency. |

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|---|---|---|---|
| `modules/mb-image/storage/owned_image.mbt` | Public caller-trusted accounting scalars | BLOCKER | Resource ceilings can be bypassed. |
| `modules/mb-image/storage/views.mbt` | Plane-0 capture plus packed addressing without layout guard | BLOCKER | Valid planar descriptors receive incorrect full-view semantics. |
| Phase-modified sources | Untracked TBD/FIXME/XXX debt markers | None | No blocking debt markers found. |

### Probe Execution

No standalone probe scripts are declared for this phase; package tests, generator check, README checks, and Required are the executable verification surfaces.

### Human Verification Required

None. Both failures are deterministic public-API behaviors with executable repros.

### Gaps Summary

Phase 4 is close but does not yet achieve its memory/resource-safe representation goal. The deterministic operation, metadata, codec, generated-evidence, target, documentation, and policy contracts are verified. Two storage-boundary defects remain: non-forgeable operation accounting and layout-correct planar view access. The structured frontmatter above is ready for gap-closure planning.

---

_Verified: 2026-07-17_
_Verifier: gsd-verifier_
