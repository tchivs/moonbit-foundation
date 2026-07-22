# Project Research Summary

**Project:** MoonBit Native Foundation — v0.17 GrayAlpha16 PNG Interchange
**Domain:** Portable, bounded image interchange in Pure MoonBit
**Researched:** 2026-07-23
**Confidence:** HIGH

## Executive Summary

v0.17 is a deliberately narrow, additive interoperability milestone for `mb-image`: library users need to construct packed U16 grayscale-plus-straight-alpha images and encode them as non-interlaced PNG colour type 4, bit depth 16. The proven expert approach is not a new codec or a generic image-processing expansion. It is one additional model identity and one private encode profile routed through the existing checked storage, atomic preflight, filtering, DEFLATE planning, and acknowledgement-safe replay machine.

The implementation should remain **Pure MoonBit with no new dependencies**. Reuse `ChannelOrder::GrayAlpha`, generic packed-U16 component-byte access, the existing `mb-core`/`mb-color` dependencies, and the portable PNG package. Add neither FFI, external codecs, target branches, copied code, image-sized conversion buffers, a second stream driver, nor release/registry work. The public decoder already accepts type-4/16 data but intentionally returns canonical straight RGBA8 high bytes; the roadmap must specify wire fidelity and decode canonicalization as separate guarantees.

The chief risks are component-level endianness, confusing two semantic channels with four wire bytes, incomplete integration of Fixed/Dynamic replay, and accidental legacy drift. Mitigate them with an explicit `GrayAlpha16` profile, one scalar wire reader mapping each pixel to `gray_hi, gray_lo, alpha_hi, alpha_lo`, checked four-byte stride arithmetic, pre-write mutation validation, literal asymmetric wire vectors, hostile caller leases, frozen legacy vectors, and an unchanged all-target Pure MoonBit suite.

## Key Findings

### Recommended Stack

Extend the existing workspace `tchivs/mb-image` module only. The required capabilities are already present in its model, storage, and PNG packages, with `mb-core` and `mb-color` as its existing workspace dependencies. This is a profile extension, not a dependency-selection problem: a third-party codec would bypass the project-owned deterministic limits, caller-owned lease semantics, and portability contract.

**Core technologies:**

- **MoonBit and the existing `mb-image` module:** model, checked storage, PNG codec, and tests — keeps the implementation portable and repository-owned.
- **`mb-image/model`:** `ImageFormat::graya16()` and strict descriptor admission — uses the existing two-component `ChannelOrder::GrayAlpha` rather than inventing a second channel order.
- **`mb-image/storage`:** generic packed-U16 component-byte views — supplies checked gray/alpha byte access without a special backing store or unsafe offsets.
- **`mb-image/png`:** private `GrayAlpha16` profile and explicit eager/chunk factory families — preserves one bounded preflight/replay implementation for all strategies.
- **Existing `mb-core` and `mb-color` dependencies:** checked arithmetic, budgets, leases, alpha and sRGB identities — no additional package is justified.

### Expected Features

**Must have (table stakes):**

- Packed U16 GrayAlpha model: exactly two packed components in gray/alpha order, straight alpha, canonical metadata, and checked U16 component access.
- Explicit `PngEncoder::new_graya16*` and `PngChunkEncoder::new_graya16*` families: non-interlaced type-4/depth-16 output only; legacy constructors must never infer the profile.
- Exact four-byte PNG wire serialization: each pixel is `Ghi,Glo,Ahi,Alo`, independent of source storage endianness.
- Existing bounded semantics: Stored, FixedOrStored, and DynamicOrFixedOrStored crossed with None and Adaptive; atomic rejection and caller-owned output behavior remain intact.
- Honest public decode contract: decoding returns straight RGBA8 `(Ghi,Ghi,Ghi,Ahi)`, while full U16 fidelity is proved at the PNG wire boundary.
- Literal compatibility and portable evidence: frozen Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 vectors plus all-target public tests.

**Should have (quality differentiators):**

- One profile-aware scalar pipeline with no converted rows or duplicate stream implementation.
- Byte-identical output from equivalent little- and big-endian U16 backing storage.
- Caller-buffered tests that prove accepted-prefix accounting, untouched lease tails, and sticky terminal states, not merely eventual output bytes.

**Defer:**

- Adam7 GrayAlpha16, RGB16/RGBA16 profiles, palette/low-bit/`tRNS` modes, automatic transparency conversion, GrayAlpha processing operations, a U16 public decoder result, dependencies/FFI, and release automation. None is required for this interchangeable two-component slice.

### Architecture Approach

Use one additive model identity and one private encode profile. The flow is `ImageFormat::graya16()` and `ImageDescriptor` admission → generic packed U16 `OwnedImage`/views → explicit eager or chunk factories → `PngEncodeMachine::new_with_profile` → atomic preflight and a scalar big-endian wire reader → existing filter/compression/replay state → type-4/16 PNG bytes. Existing decode then canonicalizes to RGBA8 high bytes. This exactly combines the U16/wire/replay precedent from v0.15 with the two-component/type-4 precedent from v0.16.

**Major components:**

1. **Model and descriptor validation** — define the U16 GrayAlpha identity, packed row geometry, straight-alpha/canonical metadata, and unchanged operation gates.
2. **Generic storage/views** — read and write two U16 components through checked component-byte APIs; no alternate image container.
3. **PNG profile and factory boundary** — make GrayAlpha16 explicit for eager and caller-buffered encoders while preserving legacy constructor selection.
4. **Shared bounded encode machine** — performs four-byte stride preflight, scalar wire traversal, filters, Stored/Fixed/Dynamic planning, replay integrity, output limits, and lease acknowledgement.
5. **Public evidence boundary** — proves wire bytes, documented decode canonicalization, lease ownership, legacy stability, and four-target conformance.

### Critical Pitfalls

1. **Reversing an entire four-byte pixel instead of each U16 component** — map position to pixel, component lane, and byte within the component; require unequal gray/alpha values and both backing byte orders.
2. **Only partially adding the type-4/16 profile** — make profile admission, row size, IHDR (`16/4/0`), factory interlace policy, and cursor selection exhaustive; test every public factory family.
3. **Using a two-byte stride for a four-byte raster** — use checked `width * 4` row arithmetic through the existing preflight ledger and test exact/one-over geometry, output, work, and budget limits before output or lease mutation.
4. **Letting Fixed/Dynamic replay read a mutated U16 source** — extend the current Gray16 revision guard to GrayAlpha16 and validate before any destination byte is written; assert sticky failure and untouched sentinels.
5. **Overclaiming public decode fidelity or weakening legacy routes** — distinguish full wire preservation from RGBA8 high-byte canonicalization, and retain literal existing-profile vectors in eager and chunk suites.

## Implications for Roadmap

The roadmap should contain exactly three sequential phases. They align with the completed Gray16 (v0.15) and GrayAlpha8 (v0.16) delivery model, preserve clear handoffs, and avoid mixing model admission, encoder internals, and qualification evidence.

### Phase 53: GrayAlpha16 Model and Checked Storage Contract

**Rationale:** The encoder cannot safely infer a two-component U16 source until descriptor validation, row geometry, alpha association, and generic storage/view behavior agree. This phase establishes the only new public source identity before any PNG factory can consume it.

**Delivers:** `ImageFormat::graya16()`; deliberate admission of packed U16 `ChannelOrder::GrayAlpha` with straight alpha, encoded builtin sRGB, top-left orientation, and valid packed rows; checked two-channel/two-byte component access; unchanged U8 GrayAlpha and existing Gray/RGB/RGBA behavior; explicit continued rejection of unsupported GrayAlpha operations.

**Measurable requirements:**

- **GRAYA16-01:** Construct non-symmetric U16 gray/alpha pairs and read all four component bytes through public generic views; reject a third channel or third component byte.
- Reject planar, F32, missing/premultiplied alpha, noncanonical colour metadata, invalid orientation, and malformed row layouts before allocation.
- Prove both valid U16 storage byte orders can be described where the existing descriptor contract permits them, without altering the U8 GrayAlpha identity.

**Avoids:** accidental lane/alpha-association changes, unchecked offsets, and broadened processing/copy/flip semantics.

### Phase 54: Bounded Non-Interlaced Type-4/16 PNG Encoder Path

**Rationale:** With a strict source contract in place, this phase can add the private profile across the one shared machine rather than duplicating encoding logic. It is the only phase that changes PNG production code.

**Delivers:** private `PngEncodeProfile::GrayAlpha16`; explicit baseline, compression-only, filter-only, and combined `new_graya16*` factories on `PngEncoder` and `PngChunkEncoder`; fail-closed source admission; `IHDR = depth 16, colour type 4, methods 0/0, interlace 0`; a component-aware U16 scalar wire reader; and GrayAlpha16 coverage in Stored/Fixed/Dynamic cursors and replay revision validation.

**Measurable requirements:**

- **GRAYA16-02:** Incompatible U8 GrayAlpha, U16 Gray, RGB8, and RGBA8 inputs fail before eager output, budget charge, or a usable chunk encoder; Adam7 is defensively rejected.
- **GRAYA16-03 (implementation):** All six compression/filter pairs use stride four and emit `Ghi,Glo,Ahi,Alo` from either source storage order, with type-4/16/non-interlaced framing.
- Exact and one-over limit tests for dimensions, output, work, and budget preserve writer position zero and caller-lease sentinels on rejection.
- Fixed/Dynamic replay detects post-admission mutation before its next lease write and remains sticky.

**Avoids:** host-endian wire corruption, two-byte row undercounting, partial profile upgrades, image-sized staging, and a divergent second streaming path.

### Phase 55: Portable GrayAlpha16 Public Interchange Evidence

**Rationale:** Production implementation is complete after Phase 54; this phase turns it into a dependable public contract, without introducing new production capabilities. It is the release-quality proof boundary.

**Delivers:** literal wire and decode evidence; eager/chunk parity under hostile leases; frozen legacy vectors; and four-target qualification using the unchanged public Pure MoonBit package suite.

**Measurable requirements:**

- **GRAYA16-03 (public evidence):** A two-pixel Stored/None vector with unequal samples asserts inflated scanline `00 12 34 A7 C5 D2 E1 4C 3B`; equivalent little-/big-endian source backing produces identical PNG bytes.
- **GRAYA16-04:** Public decode asserts `(R,G,B,A) = (Ghi,Ghi,Ghi,Ahi)` with distinct low bytes, while a filtered path exercises byte-per-pixel `4` reconstruction.
- All six compression/filter pairs use fresh chunk encoders under zero-capacity, one-byte, and deterministic ragged leases; assert eager equality, accepted-only totals, untouched unwritten tails, sticky completion, and no hidden target branches.
- Retain literal eager and chunk vectors for Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8; run `moon -C modules/mb-image test png --target all --frozen` and record per-target results for js, wasm, wasm-gc, and native.

**Avoids:** header-only testing, regenerated expectations, native-only confidence, and an inflated decoder promise.

### Phase Ordering Rationale

- Phase 53 creates the strict data model consumed by all later work; it prevents the encoder from guessing component count, alpha semantics, or row layout.
- Phase 54 is the single production integration point: it reuses existing Pure MoonBit machinery and connects source identity to canonical PNG bytes under established resource and replay rules.
- Phase 55 owns verification-only public evidence. Separating it keeps feature implementation auditable, preserves the existing pattern, and provides an independent compatibility/portability gate.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 54:** Yes — inspect every profile-dependent preflight, IHDR, scalar cursor, filter stride, Fixed/Dynamic replay, and mutation guard seam. This is local-code research rather than external-stack research.
- **Phase 55:** Light validation research — confirm all-target test invocation and current test count in the implementation environment; research did not claim a fresh v0.17 all-target result because the exploratory run exceeded its command window.

Phases with standard patterns (skip research-phase):

- **Phase 53:** The v0.15 U16 storage and v0.16 GrayAlpha model precedents fully document the required pattern; plan directly from current descriptor/view seams.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Local module/dependency seams show that all required capabilities already exist; no external package is needed. |
| Features | HIGH | The narrow capability boundary and measurable acceptance evidence are corroborated by current code and v0.15/v0.16 completion artifacts. |
| Architecture | HIGH | Current profile-aware preflight/replay construction plus direct predecessor phases establish the exact component boundaries and order. |
| Pitfalls | HIGH | Repository-specific risks were traced to concrete existing Gray16-only and GrayAlpha8-only seams; PNG normative wording is MEDIUM corroboration. |

**Overall confidence:** HIGH

### Gaps to Address

- **Fresh v0.17 portable qualification:** Do not reuse archived 196/196 success as a v0.17 result. Phase 55 must execute and record the current all-target PNG suite.
- **Final public spelling:** Research recommends `graya16` and `new_graya16*` for parity with existing naming; confirm exact exported spellings during Phase 53/54 planning, without changing the explicit-factory rule.
- **Normative PNG reference confidence:** The W3C PNG specification corroborates type-4/16, gray-then-alpha, MSB-first, straight-alpha behavior, but the decisive implementation guidance is verified local code and predecessor evidence.

## Sources

### Primary (HIGH confidence)

- `.planning/research/STACK.md` — no-dependency, Pure MoonBit extension and existing seam inventory.
- `.planning/research/FEATURES.md` — feature boundary, exclusions, measurable requirement candidates, and recommended order.
- `.planning/research/ARCHITECTURE.md` — exact model/storage/profile/preflight/replay/data-flow boundaries.
- `.planning/research/PITFALLS.md` — component-endianness, stride, replay, atomicity, and portability risk controls.
- `.planning/milestones/v0.15-phases/47-*`, `48-*`, `49-*` — verified U16 wire, replay, hostile-lease, and four-target precedent.
- `.planning/milestones/v0.16-phases/50-*`, `51-*`, `52-*` — verified GrayAlpha model, type-4 profile, and public-evidence precedent.

### Secondary (MEDIUM confidence)

- [W3C PNG Specification, Third Edition](https://www.w3.org/TR/png-3/) — type 4 permits 16-bit samples; sample order is gray then alpha, with MSB-first 16-bit wire values and unassociated alpha.

---
*Research completed: 2026-07-23*
*Ready for roadmap: yes*
