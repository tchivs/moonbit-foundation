---
phase: 04-image-model-views-and-operations
verified: 2026-07-17T00:00:00Z
status: passed
score: 12/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 10/12
  gaps_closed:
    - "Operation allocation derives width, height, and pixels from the validated descriptor; the public interface no longer accepts forgeable dimension/pixel/ResourceCharge inputs."
    - "Reordered planar full views are descriptive-only and reject byte/mutable authority with CapabilityUnavailable before backing or lease access."
  gaps_remaining: []
  regressions: []
---

# Phase 4: Image Model, Views, and Operations Verification Report

**Phase Goal:** `mb-image` exposes an explicit, memory-safe image representation and deterministic foundational operations that reuse `mb-core` and `mb-color` without embedding host or codec policy.
**Verified:** 2026-07-17
**Status:** passed
**Re-verification:** Yes - after Plan 04-09 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Opaque metadata is bounded, canonically ordered, duplicate-free, exact, and uninterpreted. | VERIFIED | `metadata.mbt` validates tokens/counts/totals before one retained allocation; all-target metadata and Required tests pass. |
| 2 | Metadata disposition is bounded, exclusive, ordered, and machine-readable. | VERIFIED | Preserve/transform/discard/loss records are canonical and exercised by operation tests. |
| 3 | Every image description field and color/alpha/orientation/opaque-metadata identity is explicit and inspectable. | VERIFIED | Closed descriptor types expose component, channels, layout, planes, stride, endianness, metadata, and display orientation. |
| 4 | Invalid dimensions, arithmetic, stride, plane count/range, containment, and overlap reject before storage access/allocation. | VERIFIED | Checked descriptor validation and adversarial model evidence remain green. |
| 5 | Owned-image allocation is atomic and cannot undercharge descriptor-derived dimensions or pixels. | VERIFIED | `OwnedImage::new_operation` now takes descriptor, budget, allocator, and work only; width/height/pixels are derived internally. Independently underfunded width, height, pixels, and work reject with unchanged counters; exact success charges once. |
| 6 | Retained immutable and callback-scoped mutable views safely honor packed and planar descriptors, including zero-copy packed crops. | VERIFIED | Packed access/crops/lifetime tests pass. Reordered planar full views expose descriptor/metadata only; byte access and mutable acquisition return stable `CapabilityUnavailable` before backing/lease access, preserving sentinels, budgets, and reacquisition. |
| 7 | Copy and flips are fresh, deterministic, padding-independent, and preserve metadata/orientation. | VERIFIED | All operation callers use descriptor-plus-work allocation; ops suite passes 18/18 on every target. |
| 8 | All eight orientation mappings normalize fresh output to TopLeft against an independent oracle. | VERIFIED | Literal generator-owned mappings remain independent and fully consumed. |
| 9 | Nearest resize and required RGB/RGBA alpha conversions are deterministic and reuse `mb-color`. | VERIFIED | Checked integer-floor mapping and typed alpha delegation pass generated and all-target tests. |
| 10 | Codec contracts are prefix-only and forward-only over Reader/Writer with explicit limits, budgets, diagnostics, progress, and dispositions. | VERIFIED | Exact codec interface has no Seeker/path/URL/registry dependency and short-progress doubles remain green. |
| 11 | Five generated evidence tables, consumer links, rootless topology, four targets, exact interfaces/DAG/publication, and read-only gates fail closed. | VERIFIED | Full Required passed with 174/174 tests per target, exact interfaces and contents, all negatives, and tracked read-only proof. |
| 12 | Deferred formats/codecs/registry/filesystem/host policy remain absent. | VERIFIED | Exact DAG and source classifiers continue to reject deferred/ambient surfaces. |

**Score:** 12/12 truths verified; 0 failed; 0 behavior-unverified.

## Gap Re-verification

### Gap 1: Forgeable allocation accounting - CLOSED

- The former width/height/pixels/work scalar signature no longer exists.
- The generated public interface is exactly `OwnedImage::new_operation(ImageDescriptor, Budget, &Allocator, UInt64)`; the remaining scalar is explicit operation work, while descriptor width, height, and pixel count are derived internally before the one `OwnedBytes` transaction.
- Four independent underfunding cases (width, height, pixels, work) reject without consuming bytes, allocations, dimensions, pixels, or work.
- Exact-budget success consumes bytes/allocation/pixels/work once and records the descriptor dimension ceilings.
- Required negative fixtures reject reintroduction of multiple forgeable UInt64 charge scalars or `ResourceCharge`.

### Gap 2: Packed addressing on planar views - CLOSED

- `ImageView::get_byte` performs the shared packed-U8 capability gate before coordinate or `ByteView` access.
- `OwnedImage::with_mut_view` performs the same capability decision before `OwnedBytes::with_mut`, so an unsupported planar image acquires no lease.
- `MutImageView` access/crop retains defensive eligibility checks.
- The original reordered planes `[4..6), [0..2), [2..4)` now remain inspectable through format/metadata but byte and mutable authority both return stable `CapabilityUnavailable` contexts.
- White-box sentinel evidence proves `ABCDEF` is unchanged, budget snapshots are identical, and the raw owner lease can be reacquired immediately and repeatedly after rejection.

## Required Artifacts

| Artifact | Status | Details |
|---|---|---|
| `modules/mb-image/metadata/metadata.mbt` | VERIFIED | Substantive, wired, behaviorally tested. |
| `modules/mb-image/model/descriptor.mbt` | VERIFIED | Explicit validated general packed/planar model. |
| `modules/mb-image/storage/owned_image.mbt` | VERIFIED | Descriptor-derived atomic allocation and pre-lease planar gate. |
| `modules/mb-image/storage/views.mbt` | VERIFIED | Retained packed views and fail-closed planar authority. |
| `modules/mb-image/ops/{copy_flip,orientation,resize,convert}.mbt` | VERIFIED | Descriptor-plus-work fresh deterministic operations. |
| `modules/mb-image/codec/contracts.mbt` | VERIFIED | Reader/Writer-only backend-neutral contracts. |
| `scripts/fixtures/Generate-ImageVectors.ps1` | VERIFIED | Byte-stable five-package evidence and independent orientation oracle. |
| `scripts/quality/{Assert-Policy,Invoke-MoonQuality}.ps1` | VERIFIED | Exact interface and synthetic negative enforcement for both closed gaps. |

## Key Link Verification

| From | To | Status | Details |
|---|---|---|---|
| storage allocation | validated descriptor + mb-core bytes/budget | WIRED | Dimensions/pixels derive from descriptor; one combined charge precedes allocation. |
| storage views | descriptor layout + mb-core ByteView/lease | WIRED | Packed eligibility precedes backing/lease authority. |
| ops | storage operation factory | WIRED | Copy/flips/orientation/resize/conversions pass descriptor plus work only. |
| model | metadata + mb-color | WIRED | Explicit identity-bearing metadata remains intact. |
| codec | mb-core Reader/Writer | WIRED | No seek or ambient host policy. |
| quality | policy/interfaces/tests | WIRED | Positive exact contracts and regression negatives both execute in Required. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Closed allocation + reordered planar repros, all targets | `moon -C modules/mb-image test storage --target all --frozen` | 14/14 per target | PASS |
| Operation migration regression, all targets | `moon -C modules/mb-image test ops --target all --frozen` | 18/18 per target | PASS |
| Full qualification | `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` | 174/174 per target; exact interfaces, negatives, generated evidence, package allowlists, read-only proof | PASS |

## Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| IMAG-01 | SATISFIED | Explicit inspectable descriptor and metadata model. |
| IMAG-02 | SATISFIED | Checked validation plus descriptor-derived atomic allocation accounting. |
| IMAG-03 | SATISFIED | Safe retained packed access and fail-closed planar descriptive views. |
| IMAG-04 | SATISFIED | Zero-copy packed crops, canonical empty views, stale-handle invalidation, disjoint splits, and pre-lease planar rejection. |
| IMAG-05 | SATISFIED | Deterministic copy/flips/orientation/resize/conversions on four targets. |
| IMAG-06 | SATISFIED | Executable per-operation metadata dispositions. |
| IMAG-07 | SATISFIED | Prefix/Reader/Writer codec seam without registry/filesystem/seek policy. |

## Decision Coverage

D-01 through D-07 remain covered by the explicit checked model; D-08 is closed by descriptor-derived atomic accounting; D-09 through D-12 are covered by retained packed views and fail-closed planar authority; D-13 through D-17 are covered by deterministic operations; D-18 through D-20 by bounded metadata dispositions; D-21 through D-22 by codec contracts; D-23 through D-25 by generated evidence, four-target Required policy, and explicit deferrals.

## Anti-Patterns Found

No blocker anti-patterns or untracked TBD/FIXME/XXX debt markers were found in the changed Phase 4 surface. The new exact negatives reject both previously observed failure classes.

## Probe Execution

No standalone probe scripts are declared. Package tests, generated evidence checks, executable README checks, policy negatives, and Required are the phase's executable verification surfaces.

## Human Verification Required

None. All Phase 4 truths are deterministic library/API behaviors with executable evidence.

## Gaps Summary

Both initial verification gaps are closed with public-interface, behavioral, counter, sentinel, lease, negative-fixture, and four-target evidence. No regressions or remaining gaps were found. Phase 4 achieves its goal and is ready to proceed.

---

_Verified: 2026-07-17_
_Verifier: gsd-verifier_
