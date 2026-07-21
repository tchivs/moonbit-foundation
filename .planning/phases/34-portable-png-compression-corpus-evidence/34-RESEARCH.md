# Phase 34: Portable PNG Compression Corpus Evidence - Research

**Researched:** 2026-07-22  
**Domain:** Deterministic MoonBit PNG compression-corpus regression evidence  
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

No `CONTEXT.md` exists for Phase 34. The approved roadmap, PNGC-04, Phase 32/33 plans and verification reports, and the existing PNG quality lane constrain this phase. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`, `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`]

### Locked Decisions

- Prove a deterministic portable corpus on js, wasm, wasm-gc, and native; optimized eager and chunk output must decode to their source images and give matching target-neutral evidence. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- Prove `FixedOrStored` is never larger than the explicit Stored baseline across the declared corpus, and prove a compression win for flat RGB8 and flat straight-RGBA8 images. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- Keep the scope out of dynamic Huffman, adaptive filters, a 32 KiB dictionary, FFI codecs, host streams, APNG, colour transforms, metadata work, policy/release automation, and registry publication. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

### the agent's Discretion

- Choose the smallest deterministic in-memory corpus, its assertions, and the target-isolated command pattern, provided every assertion uses public eager/chunk encoder and decoder contracts. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`]

### Deferred Ideas (OUT OF SCOPE)

- New compression planning, fixed-Huffman emission, admission rules, public API, compatibility-policy, or private replay behavior are Phase 32/33 responsibilities already completed. [VERIFIED: codebase: `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`, `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`]
- Benchmarks, wall-clock performance claims, external fixture acquisition, generated fixture pipelines, and a new evidence runner are not required by PNGC-04. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PNGC-04 | Maintainers can reproduce a deterministic corpus proving valid decoder round trips and never-larger FixedOrStored output, including a declared compression win for flat RGB8 and RGBA8 images. | One named black-box corpus test can generate two flat images in memory, compare explicit Stored and FixedOrStored sizes, prove repeated eager and hostile-capacity chunk byte equality, and decode both optimized paths before comparing all source pixels. Run that named test independently on the four declared targets with distinct target directories. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt,moon.pkg}`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |

## Project Constraints (from AGENTS.md)

- Keep core algorithms and shared models in MoonBit; portable code must respect explicit capability boundaries and the four supported targets. [VERIFIED: `AGENTS.md`, `modules/mb-image/png/moon.pkg`]
- Keep public/package dependencies modular, deterministic, and usable without GUI or host state; do not add FFI for this evidence phase. [VERIFIED: `AGENTS.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`]
- Use the project code graph for code discovery when exposed; no graph MCP tool or `.planning/graphs/graph.json` was available here, so the research used targeted source inspection as the documented fallback. [VERIFIED: `AGENTS.md`, local graph availability check]
- Do not make direct implementation edits outside the active GSD workflow; this research creates only the requested phase artifact. [VERIFIED: `AGENTS.md`]

## Summary

Phase 33 already gives `FixedOrStored` the crucial implementation invariant: its exact planner selects fixed output only when the complete PNG length is no larger than Stored, while existing tests prove a fixed block for a flat 32-pixel RGB8 image, hostile-capacity eager/chunk parity for RGB8 and RGBA8, decoder success, and all-four-target focused execution. Phase 34 should not duplicate that white-box/planner coverage; it should turn the public behavior into one reproducible corpus evidence test. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,encode_test.mbt,stream_encode_test.mbt}`, `.planning/phases/33-fixed-or-stored-png-planning-and-emission/{33-01-SUMMARY.md,33-02-SUMMARY.md,33-VERIFICATION.md}`]

The smallest sufficient corpus is two generated-in-test records: flat 32×1 RGB8 and flat 32×1 straight RGBA8, with every component byte `0xaa`. These cases reuse the existing package-private `png_stream_test_flat_image` constructor and stay far below its declared resource limits. For each case, the test must encode explicit `Stored`, encode `FixedOrStored` eagerly twice, drain configured `FixedOrStored` through the existing `[0, 1, 3, 2, 5]` caller-capacity schedule, decode both optimized byte sequences through `PngDecoder`, and compare every decoded component to the source. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:2-17,59-93,120-145,183-195`, `modules/mb-image/png/encode_test.mbt:90-127`]

**Primary recommendation:** Add a single named public black-box corpus test to `modules/mb-image/png/stream_encode_test.mbt`, using the two in-memory flat records and existing helpers; assert `optimized_eager.length() <= stored.length()`, assert a strict `<` win for each named flat record, assert repeated eager/chunk byte equality, decode both optimized outputs, and run that exact test with one target directory per required target. [VERIFIED: codebase: `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt,moon.pkg}`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Corpus construction | PNG package black-box test tier | Image storage model | The fixtures are package-private MoonBit `OwnedImage` values, not user input, downloaded files, or a runtime service. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:21-93`] |
| Baseline and optimized measurement | PNG public encoder API | Private Phase 33 planner | The test selects public `Stored` and `FixedOrStored` factories and measures resulting PNG byte lengths; it must not inspect or recreate the private plan. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode_test.mbt}`, `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`] |
| Eager/chunk determinism and parity | PNG public encoder adapters | Caller-owned output leases | Two eager runs and one configured chunk drain exercise deterministic public construction and arbitrary valid caller capacity handling. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:64-79,96-145,183-195`] |
| Validity oracle | PNG public decoder API | Image-view pixel comparison | `PngDecoder` with complete-input decoding proves emitted bytes are consumable; a source-to-decoded component loop proves the result represents the generated image. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,120-126,159-172`] |
| Portable evidence execution | MoonBit test runner | Target-specific build directory | `moon test` supports each of js/wasm/wasm-gc/native and `--target-dir`; separate directories prevent build-artifact cross-talk. [VERIFIED: local `moon test --help`; `modules/mb-image/png/moon.pkg`; `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |

## Standard Stack

### Core

| Library / component | Version | Purpose | Why standard |
|---|---:|---|---|
| MoonBit PNG package `tchivs/mb-image/png` | repository source | Owns `PngEncoder`, `PngChunkEncoder`, `PngDecoder`, deterministic fixed-or-stored selection, and test helpers. | It is the existing portable implementation under test; Phase 34 adds evidence only. [VERIFIED: codebase: `modules/mb-image/png/{moon.pkg,png.mbt,encode.mbt,stream_encode.mbt}`] |
| MoonBit test blocks | `moon 0.1.20260713` locally | Run deterministic package-private black-box regression evidence. | MoonBit test blocks execute through `moon test`, and the installed CLI exposes target, filter, frozen, outline, and target-directory options. [VERIFIED: local `moon --version`, local `moon test --help`] [CITED: https://docs.moonbitlang.com/en/stable/language/tests.html] |
| Existing `stream_encode_test.mbt` helpers | repository source | Build flat images, eagerly encode selected strategy, drain caller-buffered output, and manage callback-scoped output leases. | Reuse avoids a new fixture framework or stream/measurement abstraction. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:21-145`] |

### Supporting

| Component | Purpose | When to use |
|---|---|---|
| `PngDecoder::new()` through `@codec.ImageDecoder::decode` | Complete-input validity and source-pixel round-trip oracle. | Decode each optimized eager and configured chunk corpus byte sequence. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,120-126,159-172`] |
| `PngCompressionStrategy::{Stored, FixedOrStored}` | Explicit baseline/optimized comparison without changing legacy constructors. | Encode the corpus through the two named configured strategies. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`, `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`] |
| `moon test --target-dir` | Isolated build artifacts per target. | Four independently invoked target-evidence commands. [VERIFIED: local `moon test --help`; `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|---|---|---|
| Two in-memory flat test records | Checked-in binary PNG fixtures or external downloads | Rejected: the corpus source is trivial to generate deterministically with existing helpers; fixtures/downloads add provenance, refresh, and portability work without increasing PNGC-04 coverage. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:82-93`, `.planning/ROADMAP.md`] |
| One named package test | A new PowerShell runner or a benchmark program | Rejected: `moon test` already supports target filtering and target directories; the Phase 31 runner exists for a broader public workflow and would be unnecessary machinery for this package-local corpus. [VERIFIED: local `moon test --help`; `scripts/quality/Invoke-PngEncodeEvidence.ps1`; `.planning/phases/31-portable-png-encode-evidence/31-VERIFICATION.md`] |
| Byte-length predicate | Wall-clock benchmarks or compression-ratio reports | Rejected: PNGC-04 asks for deterministic never-larger and flat-image win evidence, not timing claims; elapsed time is target/host dependent. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `AGENTS.md`] |
| Existing `PngDecoder` + pixel comparison | Hand-written DEFLATE/PNG parser or a foreign codec oracle | Rejected: the package already exposes a complete-input decoder and uses it in encoder tests; external codecs and FFI are out of scope. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,120-126`, `.planning/ROADMAP.md`] |

**Installation:** No external package, tool, fixture download, or FFI is required. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/moon.pkg`]

## Package Legitimacy Audit

Not applicable: Phase 34 must not install a package. [VERIFIED: codebase: `.planning/ROADMAP.md`, `modules/mb-image/png/moon.pkg`]

## Architecture Patterns

### System Architecture Diagram

```text
Declarative in-test corpus
  ├─ flat-rgb8-32x1 (0xaa × 96 components)
  └─ flat-rgba8-32x1 (0xaa × 128 components)
             |
             v
   public configured eager encoders
   Stored --------------------> stored_bytes ----------------------+
   FixedOrStored (twice) -----> optimized_eager_a / _b             |
             |                                                     |
             v                                                     v
 public configured chunk encoder, schedule [0,1,3,2,5]       byte-length checks
             |                                               <= for all records
             v                                               < for each flat record
      optimized_chunk
             |
             +--> eager_a == eager_b == chunk (determinism/parity)
             |
             +--> PngDecoder complete-input decode (both optimized outputs)
                         |
                         v
                 source descriptor/components equal decoded image
                         |
                         v
          `moon test` repeated independently on js/wasm/wasm-gc/native
```

The diagram intentionally leaves plan selection, fixed bit emission, private work accounting, and PNG framing below the public test boundary; those are Phase 33 implementation responsibilities. [VERIFIED: codebase: `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`, `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`]

### Recommended Test Shape

Keep all new helpers and the one named test in `modules/mb-image/png/stream_encode_test.mbt`; that file already owns the necessary flat-image, eager selected-strategy, chunk-drain, lease, and resource-limit helpers. Do not create a corpus file, test module, script, executable, or quality-lane stage. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:2-145`, `scripts/quality/Invoke-MoonQuality.ps1:767-811`]

Declare the corpus directly in MoonBit as two cases, not as opaque bytes:

| Case ID | Source | Required measurement result |
|---|---|---|
| `flat-rgb8-32x1` | `png_stream_test_flat_image(3UL, 32UL)`; every RGB component is `0xaa`. | `FixedOrStored` eager length is `<= Stored` and strictly `< Stored`; repeated eager and configured chunk bytes match; both optimized outputs decode to all 32 RGB source pixels. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:82-93,183-195`] |
| `flat-rgba8-32x1` | `png_stream_test_flat_image(4UL, 32UL)`; every straight-RGBA component is `0xaa`. | `FixedOrStored` eager length is `<= Stored` and strictly `< Stored`; repeated eager and configured chunk bytes match; both optimized outputs decode to all 32 RGBA source pixels. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:82-93,183-195`] |

The strict comparison is the declared compression-win record. The non-strict comparison is asserted separately for every corpus record, so future corpus additions inherit the never-larger predicate instead of depending on an informal statement. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/encode.mbt:361-384`]

### Pattern 1: Public Corpus Case Evaluation

**What:** Evaluate one generated image through explicit Stored, two independently constructed optimized eager encoders, and one optimized chunk encoder. Measure only completed PNG `Bytes` lengths; decode both optimized byte sequences and compare source pixels. [VERIFIED: codebase: `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`]

**When to use:** For PNGC-04 evidence only; retain Phase 33 white-box tests for exact plan/bit/admission invariants. [VERIFIED: codebase: `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`]

**Example:**

```moonbit
// Test-only sketch; use existing png_stream_test_* helpers.
fn assert_fixed_or_stored_corpus_case(channels : UInt64) -> Unit {
  let image = png_stream_test_flat_image(channels, 32UL)
  let stored = png_stream_test_eager_with_strategy(image, PngCompressionStrategy::Stored)
  let eager_a = png_stream_test_eager_with_strategy(image, PngCompressionStrategy::FixedOrStored)
  let eager_b = png_stream_test_eager_with_strategy(image, PngCompressionStrategy::FixedOrStored)
  let chunk = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap() |> png_chunk_test_drain_encoder([0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()

  inspect(eager_a.length() <= stored.length(), content="true")
  inspect(eager_a.length() < stored.length(), content="true")
  inspect(eager_a == eager_b && eager_a == chunk, content="true")
  assert_png_decodes_to_source(eager_a, image)
  assert_png_decodes_to_source(chunk, image)
}

test "PNG fixed-or-stored corpus evidence is deterministic, valid, never-larger, and wins flat RGB8/RGBA8" {
  assert_fixed_or_stored_corpus_case(3UL)
  assert_fixed_or_stored_corpus_case(4UL)
}
```

The actual helper should use the established `PngDecoder` complete-input call and a nested `x`/`channel` equality loop rather than adding a checksum, parser, fixture serializer, or benchmark counter. The shown pipeline is illustrative; preserve valid MoonBit call syntax when implementing it. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,159-172`, `modules/mb-image/png/stream_encode_test.mbt:120-145,183-195`]

### Pattern 2: Target-Isolated Evidence Without a New Script

Run the named test once per target with an explicit unique `--target-dir`. First run `--outline` with the same filter and verify the exact test name is listed; this prevents a successful zero-test glob run. Then run the same filter normally. [VERIFIED: local `moon test --help`; `.planning/phases/33-fixed-or-stored-png-planning-and-emission/{33-02-SUMMARY.md,33-VERIFICATION.md}`]

```powershell
$targets = 'js', 'wasm', 'wasm-gc', 'native'
$filter = '*PNG fixed-or-stored corpus evidence*'
foreach ($target in $targets) {
  moon -C modules/mb-image test png --target $target --frozen --outline -f $filter
  moon -C modules/mb-image test png --target $target `
    --target-dir "_build/png-fixed-or-stored-corpus/$target" --frozen -f $filter
}
```

The planner should require inspection of each outline for the one exact new test name before treating the filtered command as evidence. The Phase 34 implementation must not commit this loop as a repository script; it is a reproducible verification command pattern. [VERIFIED: local `moon test --help`; `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`; `scripts/quality/Invoke-PngEncodeEvidence.ps1`]

### Anti-Patterns to Avoid

- **Treating an optimized-vs-optimized comparison as the size oracle:** compare `FixedOrStored` directly with an explicit configured `Stored` eager baseline for the same source. [VERIFIED: codebase: `modules/mb-image/png/png.mbt`, `.planning/REQUIREMENTS.md`]
- **Using only eager/chunk byte equality as validity proof:** equality can preserve the same malformed bytes; decode both optimized products with complete-input mode and compare the source pixels. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,159-172`]
- **Using wall-clock time, benchmarks, or host-specific compression tooling:** these would not provide target-neutral deterministic PNGC-04 evidence. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `AGENTS.md`]
- **Adding a runner or quality-lane stage for one test:** direct target-isolated `moon test` commands already supply the needed execution boundary. [VERIFIED: local `moon test --help`; `scripts/quality/Invoke-PngEncodeEvidence.ps1`]
- **Locking absolute compressed byte sequences or byte counts for the optimized cases:** Phase 34 needs validity, determinism, and relative size properties; private implementation refactoring may legitimately change optimized bytes while preserving those contracts. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Corpus storage | Binary fixture files, a manifest parser, or a fixture generator | Two direct in-test `png_stream_test_flat_image` calls | The cases are deterministic, inspectable, and already supported by the test helper. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:82-93`] |
| Optimized-size measurement | PNG chunk parser or DEFLATE bit counter | `Bytes::length()` on completed public encoder output | PNGC-04 compares final emitted PNG size, and completed output bytes are already materialized by existing helpers. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:64-79,120-145`, `.planning/REQUIREMENTS.md`] |
| Decoder oracle | External tool, FFI codec, or a test-only PNG parser | Existing public `PngDecoder` complete-input decode and component comparison | It is the established encoder-test validity pattern and stays within the portable package. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,120-126,159-172`] |
| Determinism oracle | A hash/digest subsystem or cross-process harness | Two eager byte sequences plus configured chunk byte sequence equality | Byte equality is stronger and simpler for the exact same generated input. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:183-195`] |
| Four-target runner | New PowerShell/CI program | Four direct `moon test --target <target> --target-dir <dir>` invocations | The CLI and Phase 31 evidence pattern already support isolated target execution. [VERIFIED: local `moon test --help`; `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |

**Key insight:** The corpus should be a small behavioral oracle, not a second compressor test harness: public byte lengths establish the size contract, public byte equality establishes determinism/parity, and public decode plus source pixels establish validity. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{encode_test.mbt,stream_encode_test.mbt}`]

## Common Pitfalls

### Pitfall 1: A filter passes without running the corpus

**What goes wrong:** MoonBit filters are glob patterns, and a literal or stale pattern can yield a false-green zero-test run. [VERIFIED: local `moon test --help`; `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`]

**How to avoid:** Give the corpus one distinctive test name, run `--outline` with the exact same glob on each target, verify the name appears, then run the filtered test. [VERIFIED: local `moon test --help`; `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-02-SUMMARY.md`]

### Pitfall 2: The "never larger" claim covers only one winner

**What goes wrong:** A strict win assertion on one RGB fixture does not protect RGBA or any future corpus record from regression. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`]

**How to avoid:** Evaluate a declarative two-case list/loop; for every entry assert `optimized <= stored`, and separately assert `<` for the `flat-rgb8-32x1` and `flat-rgba8-32x1` records. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/stream_encode_test.mbt:82-93`]

### Pitfall 3: Decode checks only one byte or only eager output

**What goes wrong:** A first-pixel check misses channel/position corruption and does not directly show the caller-buffered bytes are valid. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,159-172`]

**How to avoid:** Decode eager and chunk optimized outputs with `require_complete_input=true`; compare width, height, channel count/format as appropriate, then every `x` and channel component to the generated source. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:159-172`, `modules/mb-image/png/stream_encode_test.mbt:160-195`]

### Pitfall 4: Shared build output hides target mistakes

**What goes wrong:** An aggregate invocation is not the independent target-isolated evidence style already established for portable PNG encode evidence. [VERIFIED: codebase: `.planning/STATE.md`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`, `.planning/milestones/v0.9-phases/31-portable-png-encode-evidence/31-VERIFICATION.md`]

**How to avoid:** Use the explicit per-target command with `_build/png-fixed-or-stored-corpus/<target>` and retain the scoped PNG quality lane as the broader final regression gate. [VERIFIED: codebase: `scripts/quality/{Invoke-PngEncodeEvidence.ps1,Invoke-MoonQuality.ps1}`]

## Code Examples

### Decoder/source oracle helper

```moonbit
fn assert_png_decodes_to_source(bytes : Bytes, source : @storage.OwnedImage) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_stream_test_budget(work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  // Assert dimensions/format, then compare every x/channel byte to source.view().
}
```

This follows the existing complete-input decoder construction and should be extended only with deterministic descriptor and component comparisons. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,159-172`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| `FixedOrStored` was a stored-emission selection seam with no compression claim. | Phase 33 now makes a bounded exact fixed-or-stored choice before output. | Phase 33 | Phase 34 can measure public completed bytes rather than promise an optimization before it exists. [VERIFIED: codebase: `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`, `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`] |
| Four-target PNG encode evidence uses a dedicated script for the broader hostile-capacity/public-workflow suite. | Phase 34 needs only a direct named package test and documented target-isolated commands. | Phase 34 recommendation | The corpus remains a minimal regression test instead of adding runner infrastructure. [VERIFIED: codebase: `scripts/quality/Invoke-PngEncodeEvidence.ps1`, `.planning/REQUIREMENTS.md`] |

**Deprecated/outdated:** Do not retain Phase 32's statement that `FixedOrStored` has no size guarantee; Phase 33 has implemented exact fixed-or-stored selection and Phase 34 must test its required relative-size evidence. [VERIFIED: codebase: `.planning/phases/32-png-compression-strategy-and-compatibility/32-VERIFICATION.md`, `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`, `.planning/REQUIREMENTS.md`]

## Assumptions Log

No assumptions remain: the recommended corpus shape, test helpers, target set, CLI options, requirement boundary, and Phase 33 fixed-or-stored invariant were verified from the current repository and installed toolchain. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/{moon.pkg,encode.mbt,encode_test.mbt,stream_encode_test.mbt}`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`; local `moon test --help`]

## Open Questions

None. The two flat cases are sufficient and directly map to the two explicitly required win categories; adding a non-winning/fallback case is optional regression breadth, not a Phase 34 requirement. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Compile/run corpus on four targets | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` / `moonrun` | MoonBit compilation/execution | ✓ | `v0.10.4+2cc641edf` / `0.1.20260713` | — [VERIFIED: local `moonc -v`, `moonrun --version`] |
| PowerShell | Copyable target-loop verification command | ✓ | `7.6.3` | Run the four `moon` commands manually. [VERIFIED: local `pwsh --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local command probes]

**Missing dependencies with fallback:** None. [VERIFIED: local command probes]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | The portable PNG corpus has no identity boundary. [VERIFIED: codebase: `modules/mb-image/png`] |
| V3 Session Management | no | The test owns no session state. [VERIFIED: codebase: `modules/mb-image/png`] |
| V4 Access Control | no | The package test exposes no authorization surface. [VERIFIED: codebase: `modules/mb-image/png`] |
| V5 Input Validation | yes | Use only generated compatible RGB8/straight-RGBA8 sources and complete-input decoder mode; Phase 33 retains bounded preflight for actual public inputs. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,encode_test.mbt,stream_encode_test.mbt}`] |
| V6 Cryptography | no | PNG CRC-32 and zlib Adler-32 are format integrity checks, not cryptographic controls. [CITED: https://www.w3.org/TR/png-3/] |

### Known Threat Patterns for This Evidence

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Size regression hidden by a selected fixed-byte assertion | Tampering | Compare completed public `FixedOrStored` byte length to explicit public `Stored` bytes for every corpus record. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/png.mbt`] |
| Corrupt but parity-identical eager/chunk output | Tampering | Complete-input decode both optimized byte sequences and compare all source components. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,159-172`] |
| Target-specific false green | Tampering | One outlined and executed filtered test per declared target with a unique target directory. [VERIFIED: local `moon test --help`; `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |
| Fixture/network supply chain | Tampering / Denial of Service | Generate the two corpus images in the test; do not download or parse external fixtures. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:82-93`, `.planning/ROADMAP.md`] |

## Validation Architecture

Skipped: `workflow.nyquist_validation` is explicitly `false` in `.planning/config.json`. [VERIFIED: codebase: `.planning/config.json`]

## Test Plan

| Behavior | Test location | Required assertion |
|---|---|---|
| Minimal deterministic corpus | `modules/mb-image/png/stream_encode_test.mbt` | One distinctive test evaluates exactly `flat-rgb8-32x1` and `flat-rgba8-32x1`, generated via existing helper, with no file/network dependency. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:82-93`, `.planning/REQUIREMENTS.md`] |
| Never-larger and declared flat wins | Same test | For every case, `optimized_eager.length() <= stored.length()`; for each named flat case, `optimized_eager.length() < stored.length()`. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/encode.mbt:361-384`] |
| Deterministic eager/chunk evidence | Same test | Two optimized eager byte sequences are equal; configured chunk drain under `[0,1,3,2,5]` equals the eager sequence. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt:120-145,183-195`] |
| Decoder/source round trips | Same test | Decode eager and chunk optimized bytes with complete-input mode and compare every source component. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:97-107,159-172`] |
| Isolated target evidence | Verification command | Outline then execute the exact named test on js, wasm, wasm-gc, and native with separate target directories. [VERIFIED: local `moon test --help`; `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |
| Broader regression | Existing quality lane | Run `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png`; do not edit the lane. [VERIFIED: codebase: `scripts/quality/Invoke-MoonQuality.ps1:767-811`] |

**Suggested commands after implementation:**

```powershell
# Per target: first confirm the filter names the corpus test, then execute it in an isolated directory.
moon -C modules/mb-image test png --target js --frozen --outline -f '*PNG fixed-or-stored corpus evidence*'
moon -C modules/mb-image test png --target js --target-dir '_build/png-fixed-or-stored-corpus/js' --frozen -f '*PNG fixed-or-stored corpus evidence*'
moon -C modules/mb-image test png --target wasm --frozen --outline -f '*PNG fixed-or-stored corpus evidence*'
moon -C modules/mb-image test png --target wasm --target-dir '_build/png-fixed-or-stored-corpus/wasm' --frozen -f '*PNG fixed-or-stored corpus evidence*'
moon -C modules/mb-image test png --target wasm-gc --frozen --outline -f '*PNG fixed-or-stored corpus evidence*'
moon -C modules/mb-image test png --target wasm-gc --target-dir '_build/png-fixed-or-stored-corpus/wasm-gc' --frozen -f '*PNG fixed-or-stored corpus evidence*'
moon -C modules/mb-image test png --target native --frozen --outline -f '*PNG fixed-or-stored corpus evidence*'
moon -C modules/mb-image test png --target native --target-dir '_build/png-fixed-or-stored-corpus/native' --frozen -f '*PNG fixed-or-stored corpus evidence*'
pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png
```

The four target names are exactly the package's supported target set, and `--target all` is an additional aggregate regression command rather than a replacement for the required isolated evidence. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `scripts/quality/Invoke-MoonQuality.ps1:799`; local `moon test --help`] [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]

## Exact Scope Fences

- Modify only `modules/mb-image/png/stream_encode_test.mbt` during implementation; this research file is the only current change. Do not create new source, fixture, script, example, policy, workflow, or documentation files. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt`, `.planning/REQUIREMENTS.md`, `scripts/quality/Invoke-MoonQuality.ps1:767-811`]
- Do not change `encode.mbt`, `stream_encode.mbt`, `png.mbt`, public declarations, legacy Stored constructors, compression-plan selection, fixed replay, resource admission, or Phase 33 white-box tests. [VERIFIED: codebase: `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`, `.planning/REQUIREMENTS.md`]
- Do not add external fixtures, downloads, generated-vector updates, FFI/foreign decoder checks, benchmark reports, wall-clock measurements, dynamic Huffman, adaptive filtering, dictionary expansion, host streaming, APNG, colour work, metadata work, release work, registry work, or quality-lane changes. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `scripts/quality/Invoke-MoonQuality.ps1:767-811`]
- Do not replace `<=` / `<` relative assertions with frozen optimized bytes or exact byte counts; the Phase requirement is representation-independent relative-size evidence plus determinism/validity. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`]

## Sources

### Primary (HIGH confidence)

- Codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — Phase 34 goal, PNGC-04 requirement, exclusions, and four-target decision.
- Codebase: `.planning/phases/32-png-compression-strategy-and-compatibility/{32-RESEARCH.md,32-01-PLAN.md,32-01-SUMMARY.md,32-VERIFICATION.md}` — public strategy seam and legacy Stored compatibility boundary.
- Codebase: `.planning/phases/33-fixed-or-stored-png-planning-and-emission/{33-RESEARCH.md,33-01-PLAN.md,33-02-PLAN.md,33-01-SUMMARY.md,33-02-SUMMARY.md,33-VERIFICATION.md}` — exact planner, Phase 33 test coverage, and explicit Phase 34 handoff.
- Codebase: `modules/mb-image/png/{moon.pkg,encode.mbt,encode_test.mbt,stream_encode_test.mbt}` — package targets, exact no-larger selection, test helpers, decoder pattern, and current public parity evidence.
- Codebase: `scripts/quality/{Invoke-PngEncodeEvidence.ps1,Invoke-MoonQuality.ps1}` — established isolated target-directory evidence and scoped PNG quality gate.
- Local toolchain: `moon --version`, `moon test --help`, `moonc -v`, `moonrun --version`, `pwsh --version` — installed versions and command capability.

### Secondary (MEDIUM confidence)

- [MoonBit test documentation](https://docs.moonbitlang.com/en/stable/language/tests.html) — test-block execution through `moon test`.
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — declared target behavior and `--target all` target expansion.
- [PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — PNG integrity-check terminology.

### Tertiary (LOW confidence)

None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — the phase uses existing MoonBit package/test/decoder facilities and installs nothing. [VERIFIED: codebase: `modules/mb-image/png/{moon.pkg,encode_test.mbt,stream_encode_test.mbt}`]
- Architecture: HIGH — Phase 33 verification confirms the fixed-or-stored public behavior, and Phase 31 confirms isolated target-directory evidence precedent. [VERIFIED: codebase: `.planning/phases/33-fixed-or-stored-png-planning-and-emission/33-VERIFICATION.md`, `.planning/milestones/v0.9-phases/31-portable-png-encode-evidence/31-VERIFICATION.md`]
- Pitfalls: HIGH — filtered test false-greens and target-isolation requirements are recorded in prior phase evidence and exposed by the installed CLI. [VERIFIED: codebase: `.planning/phases/33-fixed-or-stored-png-planning-and-emission/{33-02-SUMMARY.md,33-VERIFICATION.md}`, local `moon test --help`]

**Research date:** 2026-07-22  
**Valid until:** 2026-08-21 (repository-local test design; revisit if the Phase 33 public API or target set changes).
