# Phase 40: Portable Adaptive-Filter Evidence - Research

**Researched:** 2026-07-22  
**Domain:** Public PNG adaptive-filter evidence across MoonBit portable targets  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Evidence corpus and comparison

- **D-01:** Use small deterministic, generated MoonBit RGB8 and straight-RGBA8 fixtures in the PNG public-test layer; do not add external binary fixtures or a new runtime dependency.
- **D-02:** Compare Adaptive against filter-None under the same explicit compression strategy. Each selected fixture must show a strict byte-length improvement, not merely non-regression.
- **D-03:** Keep the corpus intentionally diagnostic: horizontal/vertical predictor-friendly patterns and a fixed expected winner/size relation, rather than benchmark-style broad claims.

### Portable public proof

- **D-04:** Exercise only public eager/chunk encoder factories and `PngDecoder`; do not expose test-only APIs or add a public metrics surface.
- **D-05:** Use a fixed hostile caller-output schedule including zero, one-byte, and ragged capacities. Chunk bytes must exactly equal eager bytes for every evidence case.
- **D-06:** Run each named public evidence case independently on js, wasm, wasm-gc, and native with a cleaned temporary target root; each decoded result must match source dimensions, format, and bytes completely.

### Scope fence

- **D-07:** Do not change Adaptive filtering, compression-selection, resource accounting, factory signatures, or legacy None bytes in this phase. It is evidence-only unless an evidence test proves a Phase 39 regression.

### the agent's Discretion

- Choose the smallest deterministic RGB8 and straight-RGBA8 patterns that produce stable strict wins across all four targets, and encode their expected relations as executable tests.

### Deferred Ideas (OUT OF SCOPE)

None — this phase is intentionally evidence-only and stays within the v0.12 PNG Adaptive-filter milestone.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Keep algorithms and shared models in MoonBit; this phase needs only MoonBit public tests. [VERIFIED: codebase — AGENTS.md]
- Preserve portable js, wasm, wasm-gc, and native behavior through conformance evidence. [VERIFIED: codebase — AGENTS.md]
- Do not add FFI, create public dependency cycles, alter stable APIs, or add GUI-dependent evidence. [VERIFIED: codebase — AGENTS.md]
- Treat performance claims as requiring declared, reproducible evidence; this phase must make only case-specific size assertions. [VERIFIED: codebase — AGENTS.md]
- Use public `*_test.mbt` black-box tests and generated/semantic evidence rather than opaque binary fixtures. [VERIFIED: codebase — AGENTS.md]
- The knowledge-graph file is absent, so code discovery used targeted source inspection; no graph relationship is asserted. [VERIFIED: codebase — .planning/graphs/graph.json absence]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PNGF-04 | Generated RGB8 and straight-RGBA8 cases prove an adaptive-filter win where intended, eager/chunk byte identity under hostile capacities, and complete public PNG decode on js, wasm, wasm-gc, and native. | The public combined factories, source-equality decoder helpers, hostile schedule helper, and focused target script already exist; Phase 40 should add only deterministic fixture/case assertions and target-root cleanup. [VERIFIED: codebase — modules/mb-image/png/encode_test.mbt, stream_encode_test.mbt, scripts/quality/Invoke-PngEncodeEvidence.ps1] |
</phase_requirements>

## Summary

Phase 40 is evidence-only. The encoder already exposes `PngEncoder::new_with_strategies` and `PngChunkEncoder::new_with_strategies`, and `PngDecoder` is already used by public tests to verify width, height, channel count, and every component. Reuse these seams; do not touch encoder implementation, strategy selection, limits, budgets, or public policy. [VERIFIED: codebase — modules/mb-image/png/png.mbt:96-151; encode_test.mbt:93-122; stream_encode_test.mbt:149-180]

Use explicit `FixedOrStored` for both the None baseline and Adaptive candidate. Stored output length is calculated from scanline length and block count before it is emitted, so filtering does not change its size; `FixedOrStored` is the smallest existing route whose fixed-Huffman plan consumes the selected filtered bytes and can therefore demonstrate a filter-caused win. [VERIFIED: codebase — modules/mb-image/png/encode.mbt:1193-1215, 1220-1250]

The smallest high-signal candidate corpus is a 32x1 RGB8 horizontal ramp and a 16x8 straight-RGBA8 horizontal-and-vertical ramp. Their selected-filter residuals deliberately introduce long runs at distances one or four, while the None stream avoids those short-distance repetitions. The exact strict size relation is an executable acceptance condition, not an unverified absolute byte constant. [ASSUMED]

**Primary recommendation:** Add four named public tests (RGB eager, RGBA eager, RGB chunk, RGBA chunk) using explicit `FixedOrStored`, assert `adaptive.length() < none.length()`, exact hostile chunk/eager parity, and full `PngDecoder` source equality; change the focused PowerShell script to run every named test on one temporary cleaned target directory per target. [VERIFIED: codebase — reusable public helpers and existing focused script]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Generated RGB8/RGBA8 evidence sources | Test/package layer | Storage/model | Tests create `OwnedImage` values and populate pixels through views; production image representation remains unchanged. [VERIFIED: codebase — encode_test.mbt:24-62; stream_encode_test.mbt:21-56] |
| Adaptive-vs-None size comparison | PNG public encoder API | PNG preflight/compression planner | Tests select the same public `FixedOrStored` route with a different public filter option; the private planner owns final Deflate selection. [VERIFIED: codebase — png.mbt:137-149; encode.mbt:1229-1250] |
| Hostile caller-output proof | PNG public chunk encoder API | Caller-owned bytes leases | The test drives `pull` through zero, one-byte, and ragged leases, then compares accumulated bytes to eager output. [VERIFIED: codebase — stream_encode_test.mbt:245-294, 891-945] |
| Decode-fidelity proof | PNG public decoder API | Storage/model | `PngDecoder` restores an image and existing helpers compare descriptor shape and every sample. [VERIFIED: codebase — encode_test.mbt:93-122; stream_encode_test.mbt:149-180] |
| Four-target isolation | Quality script / Moon CLI | OS temporary storage | The script owns target directories and must remove them after each target-specific invocation. [VERIFIED: codebase — scripts/quality/Invoke-PngEncodeEvidence.ps1:1-25] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` test runner | `0.1.20260713` | Execute focused public PNG cases independently per portable target. | It is the repository's established test command and supports `--target`, `--target-dir`, `--frozen`, and `-f`. [VERIFIED: local environment and scripts/quality/Invoke-PngEncodeEvidence.ps1] |
| Existing MNF PNG public API | Repository source | Create eager/chunk encoders and decode outputs without test-only hooks. | It is the required public contract for PNGF-04. [VERIFIED: codebase — modules/mb-image/png/png.mbt] |

### Supporting

| Component | Purpose | When to Use |
|---|---|---|
| `png_filter_strategy_decode_matches_source` | Eager descriptor/component oracle. | RGB and RGBA eager evidence. [VERIFIED: codebase — encode_test.mbt:93-122] |
| `png_stream_test_eager_with_strategies` | Explicit eager strategy/filter encoder. | Construct None and Adaptive bytes under the same compression strategy. [VERIFIED: codebase — stream_encode_test.mbt:82-98] |
| `png_chunk_test_drain_encoder` | Fixed schedule chunk drain with progress validation. | Baseline chunk byte collection. [VERIFIED: codebase — stream_encode_test.mbt:269-294] |
| `png_chunk_test_drain_hostile` | Stronger hostile drain: zero-capacity semantics, ragged progress, sticky terminal checks, and eager byte parity. | Use or factor its schedule checks for every new Adaptive evidence case. [VERIFIED: codebase — stream_encode_test.mbt:891-945] |
| `png_stream_test_fixed_or_stored_corpus_decode_matches_source` | Complete descriptor/component decode oracle. | Chunk evidence, including decoding returned chunk bytes. [VERIFIED: codebase — stream_encode_test.mbt:149-180] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| `FixedOrStored` | `Stored` | Reject: Stored size is a function of scanline length/block framing, not filtered values, so it cannot provide the required strict size win. [VERIFIED: codebase — encode.mbt:1193-1215, 1220-1228] |
| `FixedOrStored` | `DynamicOrFixedOrStored` | Reject for this evidence: it adds Dynamic-vs-Fixed selection as a confounder; use the already-covered Dynamic tests only for regression context. [VERIFIED: codebase — encode.mbt:1252-1292; stream_encode_test.mbt:713-716] |
| Generated source pixels | Binary PNG fixtures | Reject: the locked scope requires generated MoonBit fixtures and no external fixture/runtime dependency. |
| Semantic source equality | Exact whole-file golden PNG bytes | Reject: PNGF-04 needs a strict relation and interoperability proof, while absolute output snapshots would overconstrain valid implementation details. [VERIFIED: codebase — AGENTS.md testing convention; CONTEXT.md D-03/D-04] |

**Installation:** None — this phase installs no package or runtime. [VERIFIED: codebase — phase scope and existing toolchain]

## Architecture Patterns

### System Architecture Diagram

```text
generated RGB8 / straight-RGBA8 source
               |
               +--> eager public encoder (FixedOrStored + None) ----> baseline byte length
               |
               +--> eager public encoder (FixedOrStored + Adaptive) -> strict shorter length
               |                                                     |
               |                                                     +--> PngDecoder -> descriptor + all pixels == source
               |
               +--> chunk public encoder (same Adaptive route)
                         |
                         +--> [0, 1, 3, 2, 5, ...] caller capacities
                         |
                         +--> accumulated chunk bytes == eager Adaptive bytes
                                                               |
                                                               +--> PngDecoder -> descriptor + all pixels == source

PowerShell per target: create owned temp target root -> run each named selector -> finally remove root
```

### Recommended Project Structure

```text
modules/mb-image/png/
├── encode_test.mbt          # RGB/RGBA eager strict-size + decoder cases
└── stream_encode_test.mbt   # matching hostile chunk parity + decoder cases
scripts/quality/
└── Invoke-PngEncodeEvidence.ps1  # independent target invocations with temporary-root cleanup
```

### Pattern 1: Explicit paired encoder comparison

**What:** For one generated source, encode twice via `new_with_strategies`: `FixedOrStored + None` and `FixedOrStored + Adaptive`; assert only the strict relation `adaptive.length() < none.length()`. [VERIFIED: codebase — png.mbt:137-149]

**When to use:** Every eager evidence test. It proves filtering has an intended encoded-size effect without changing the explicit compression strategy. [VERIFIED: codebase — REQUIREMENTS.md PNGF-04; CONTEXT.md D-02]

**Implementation guidance:** Do not compare an Adaptive route against a legacy/default constructor, and do not write a fixed absolute output length. The former changes two axes; the latter makes the diagnostic corpus a fragile byte-format snapshot. [VERIFIED: codebase — CONTEXT.md D-02/D-03]

### Pattern 2: One source builder, named case wrappers

**What:** Define a shared package-private generated-case builder/helper, then expose four separately named tests that each call it once. Separate names are required so the quality script can execute each case independently on each target. [VERIFIED: codebase — Invoke-PngEncodeEvidence.ps1 accepts one `-f` selector]

**Recommended fixture formulas:**

| Named case | Geometry | Pixel formula | Expected selected-filter behavior | Expected relation |
|---|---:|---|---|---|
| RGB8 horizontal | 32x1 | At column `x`: `(x, x+64, x+128)`. | `Sub` turns all post-first-pixel channel deltas into `1`; None has no useful distance-1..4 repetition. | Adaptive `<` None under `FixedOrStored`. [ASSUMED] |
| Straight-RGBA8 vertical | 16x8 | At `(x,y)`: `(3x+y, 3x+y+64, 3x+y+128, 200)`. | The first row is Sub-friendly; later rows are Up-friendly with RGB residual `1` and alpha residual `0`, producing repeated distance-four groups. | Adaptive `<` None under `FixedOrStored`. [ASSUMED] |

These formulas stay below 256 at the stated geometries and create valid RGB8/straight-RGBA8 source bytes. The formulas are source-driven candidates and must be accepted only when the focused four-target test establishes the strict relation. [ASSUMED]

### Pattern 3: Hostile chunk proof per case

**What:** Build the chunk encoder with the same public combined factory as eager Adaptive and drain it with a fixed schedule containing zero, one, and ragged capacities. Compare its accumulated bytes byte-for-byte to eager Adaptive bytes, then decode the chunk bytes with the same complete source oracle. [VERIFIED: codebase — stream_encode_test.mbt:311-335, 891-945]

**Required schedule:** `[0UL, 1UL, 3UL, 2UL, 5UL]` is already proven by combined Adaptive chunk coverage; the stronger existing schedule `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]` is preferred because it covers the locked zero/one/ragged contract in one deterministic schedule. [VERIFIED: codebase — stream_encode_test.mbt:328-330, 1027-1034]

### Concrete named tests and locations

| Location | Test name | Required assertions |
|---|---|---|
| `modules/mb-image/png/encode_test.mbt` | `PNG adaptive filter evidence RGB8 horizontal eager strictly beats None and decodes completely` | Explicit paired `FixedOrStored` output; strict size relation; `PngDecoder` returns width, height, RGB8 channel count, and every source component. [VERIFIED: codebase — reusable eager helper/oracle] |
| `modules/mb-image/png/encode_test.mbt` | `PNG adaptive filter evidence straight-RGBA8 vertical eager strictly beats None and decodes completely` | Same as RGB, with straight RGBA source. [VERIFIED: codebase — reusable eager helper/oracle] |
| `modules/mb-image/png/stream_encode_test.mbt` | `PNG adaptive filter evidence RGB8 horizontal chunk exactly matches eager and decodes completely` | Explicit Adaptive chunk factory; stronger hostile schedule; bytes equal eager Adaptive; decoded chunk result equals source. [VERIFIED: codebase — reusable chunk helper/oracle] |
| `modules/mb-image/png/stream_encode_test.mbt` | `PNG adaptive filter evidence straight-RGBA8 vertical chunk exactly matches eager and decodes completely` | Same as RGB chunk case, with straight RGBA source. [VERIFIED: codebase — reusable chunk helper/oracle] |

### Anti-Patterns to Avoid

- **Using Stored to prove a filter-size win:** stored payload length does not depend on residual values. [VERIFIED: codebase — encode.mbt:1193-1215]
- **Comparing different compression strategies:** it breaks the explicit same-strategy requirement and turns compression selection into a confounder. [VERIFIED: codebase — CONTEXT.md D-02]
- **A loop with one generic test name:** it prevents the script from independently executing every named evidence case. [VERIFIED: codebase — CONTEXT.md D-06]
- **A test-only metric or filter-inspection API:** the public factories and output bytes are the intended contract. [VERIFIED: codebase — CONTEXT.md D-04]
- **Leaving `_build/png-encode-evidence` behind:** it violates the requested clean temporary target-root proof and risks stale artifacts influencing a run. [VERIFIED: codebase — scripts/quality/Invoke-PngEncodeEvidence.ps1:10-24; CONTEXT.md D-06]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Image builder | A new pixel-storage type | Existing `OwnedImage` helpers. | They already set RGB8 versus straight-RGBA8 metadata and plane layout correctly. [VERIFIED: codebase — encode_test.mbt:24-62; stream_encode_test.mbt:21-56] |
| Chunk pump | A second lease/progress implementation | `png_chunk_test_drain_encoder` / the hostile-drain structure. | Existing code validates total progress and terminal behavior. [VERIFIED: codebase — stream_encode_test.mbt:269-294, 891-945] |
| PNG semantic oracle | Hand parsing PNG chunks/filters | Public `PngDecoder` plus existing descriptor/component equality helpers. | It proves interoperability through the same public decoder users call. [VERIFIED: codebase — encode_test.mbt:93-122; stream_encode_test.mbt:149-180] |
| Target isolation | A persistent package build directory | GUID-owned OS temporary target root in `try/finally`. | It prevents stale artifacts and leaves no persistent build directory. [ASSUMED] |

**Key insight:** This phase should add assertions around already-public behavior; it should not duplicate encoder, chunk, or decoder mechanics. [VERIFIED: codebase — CONTEXT.md D-04/D-07]

## Common Pitfalls

### Pitfall 1: Choosing Stored for the baseline/comparison

**What goes wrong:** Adaptive and None have identical stored encoded length, so a strict win is impossible even when row residuals improve. [VERIFIED: codebase — encode.mbt:1193-1215]

**How to avoid:** Use the same explicit `FixedOrStored` strategy for both bytes and assert Adaptive is strictly shorter. [VERIFIED: codebase — encode.mbt:1229-1250]

### Pitfall 2: An accidental compression-plan winner

**What goes wrong:** A sparse/noisy fixture may make one side choose Stored while the other chooses Fixed, making a brittle or misleading test; Dynamic would add a third planner decision. [VERIFIED: codebase — encode.mbt:1243-1250, 1265-1290]

**How to avoid:** Use predictor-generated repeated residuals, retain the same explicit `FixedOrStored` factory on both sides, and let the required strict output relation be the acceptance check. If either candidate does not hold on all targets, change only fixture dimensions/formula—not encoder code. [ASSUMED]

### Pitfall 3: A size win without full public fidelity proof

**What goes wrong:** A length assertion could pass even if output has a decode or channel-order fault. [VERIFIED: codebase — PNGF-04]

**How to avoid:** Decode both evidence outputs relevant to the named test through `PngDecoder`, compare width, height, channel count/format, and every source component. [VERIFIED: codebase — encode_test.mbt:93-122; stream_encode_test.mbt:149-180]

### Pitfall 4: Hostile schedule omitted from a case

**What goes wrong:** A normal drain can conceal a preview/acknowledgement defect at zero or small leases. [VERIFIED: codebase — Phase 39 verification]

**How to avoid:** Invoke the public chunk factory for each named source with one fixed schedule containing zero, one-byte, and ragged capacities, then compare the whole byte sequence to eager Adaptive. [VERIFIED: codebase — CONTEXT.md D-05; stream_encode_test.mbt:891-945]

### Pitfall 5: Evidence script leaves or reuses state

**What goes wrong:** The current script targets `_build/png-encode-evidence/<target>` and has no cleanup block, contrary to the phase requirement for a cleaned temporary target root. [VERIFIED: codebase — scripts/quality/Invoke-PngEncodeEvidence.ps1:10-24]

**How to avoid:** In the script, allocate a GUID-named child of `[IO.Path]::GetTempPath()`, pass it via `--target-dir`, execute exact test selectors separately, and remove that exact owned path in `finally` after resolving/verifying it is inside the temp root. [ASSUMED]

## Code Examples

### Strict same-strategy eager relation

```moonbit
let none = eager(source, FixedOrStored, None)
let adaptive = eager(source, FixedOrStored, Adaptive)
if adaptive.length() >= none.length() {
  abort("adaptive evidence strict win")
}
decode_and_compare_every_component(adaptive, source)
```

This is a conceptual composition of the existing explicit eager helper and decoder equality helper, not a new encoder API. [VERIFIED: codebase — stream_encode_test.mbt:82-98; encode_test.mbt:93-122]

### Adaptive hostile caller-buffer proof

```moonbit
let eager = eager(source, FixedOrStored, Adaptive)
let chunk = chunk_encoder(source, FixedOrStored, Adaptive)
let chunked = drain(chunk, [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL])
if chunked != eager { abort("adaptive chunk eager parity") }
decode_and_compare_every_component(chunked, source)
```

The existing drain implementation provides the progress and terminal assertions that this conceptual example elides. [VERIFIED: codebase — stream_encode_test.mbt:891-945]

### Focused, clean target invocation

```powershell
$root = Join-Path ([IO.Path]::GetTempPath()) ('mnf-png-adaptive-evidence-' + [guid]::NewGuid().ToString('N'))
try {
  foreach ($selector in $evidenceSelectors) {
    & moon -C modules/mb-image test png --target $Target --target-dir $root --frozen -f $selector
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
} finally {
  if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
```

Before removing the directory, implementation must prove that the resolved path is a child of the OS temp root and has the script-owned prefix. [ASSUMED]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Legacy filter-None bytes and default Stored constructor | Explicit opt-in Adaptive alongside existing compression strategies | Phase 40 can compare a new route without mutating compatibility bytes. [VERIFIED: codebase — png.mbt:113-149; Phase 39 verification] |
| Generic Adaptive route coverage | Case-specific generated strict-win evidence | PNGF-04 gets a reproducible public proof instead of a broad performance claim. [VERIFIED: codebase — encode_test.mbt:124-146; stream_encode_test.mbt:308-335; REQUIREMENTS.md PNGF-04] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | RESOLVED — the fixed R1-R3/A1-A3 probe found strict `FixedOrStored + Adaptive < FixedOrStored + None` on every portable target. The first ordered winners are R1 and A1. | CandidateSelection, 2026-07-22 | Final corpus is limited to those selected formulas. |
| A2 | A GUID-owned OS temporary directory with verified containment is the best implementation of cleaned target-root isolation for this script. | Don't Hand-Roll; Pitfalls; Code Examples | Cleanup could be incomplete or unsafe; implementation must validate containment before deletion. |
| A3 | The existing package-private test helpers can be shared across `encode_test.mbt` and `stream_encode_test.mbt`; if MoonBit visibility prevents that, duplicate only the tiny source formula, not encoder/chunk/decode logic. | Architecture Patterns | Compile failure; keep fixture builder local to each test file with identical documented formula. |

## Open Questions

1. **Do both candidates select Fixed rather than Stored on every target?**
   - What we know: `FixedOrStored` deterministically chooses Fixed when its complete output is no longer than Stored; the candidate residuals are intentionally matcher-friendly. [VERIFIED: codebase — encode.mbt:1243-1250]
   - What's unclear: no fixture-specific four-target measurement was run during research-only work. [VERIFIED: research scope]
   - Recommendation: let the new strict relation be the hard test; optionally add a Fixed BTYPE assertion only after the first all-target result confirms it is stable. [ASSUMED]

2. **Can the exact cross-file fixture helper be shared?**
   - What we know: each existing file already has independently usable image, eager, chunk, and decoder helpers. [VERIFIED: codebase — encode_test.mbt; stream_encode_test.mbt]
   - What's unclear: the local declaration visibility convention was not independently compiled in this research pass. [ASSUMED]
   - Recommendation: prefer one shared package-private fixture helper; fall back to two small identical helpers if compiler visibility requires it. [ASSUMED]

## A1 Candidate-Selection Evidence

**A1: RESOLVED** — run 2026-07-22 with:

```powershell
& .\scripts\quality\Invoke-PngEncodeEvidence.ps1 -Mode CandidateSelection
```

| Target | R1 | R2 | R3 | A1 | A2 | A3 |
|---|---|---|---|---|---|---|
| js | pass | pass | pass | pass | pass | pass |
| wasm | pass | pass | pass | pass | pass | pass |
| wasm-gc | pass | pass | pass | pass | pass | pass |
| native | pass | pass | pass | pass | pass | pass |

The ordered all-target selections are **R1** (RGB8 32x1 horizontal) and **A1** (straight-RGBA8 16x8). Each candidate was invoked separately from a GUID-owned temporary target root, and the runner removed that root in `finally` after containment and prefix validation.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Focused test selectors on all targets | ✓ | `0.1.20260713` | — [VERIFIED: local environment] |
| `moonc` | MoonBit compilation | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local environment] |
| `moonrun` | Moon runtime target support | ✓ | `0.1.20260713` | — [VERIFIED: local environment] |
| PowerShell | Existing evidence script | ✓ | Current shell | — [VERIFIED: local environment] |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment]

**Missing dependencies with fallback:** None. [VERIFIED: local environment]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | No authentication surface changes. [VERIFIED: codebase — phase scope] |
| V3 Session Management | No | No session surface changes. [VERIFIED: codebase — phase scope] |
| V4 Access Control | No | No access-control surface changes. [VERIFIED: codebase — phase scope] |
| V5 Input Validation | Yes, for script-owned cleanup path | Validate the target selector with `ValidateSet`; validate temp-root containment and script-owned prefix before recursive cleanup. [VERIFIED: codebase — Invoke-PngEncodeEvidence.ps1:1-24; ASSUMED cleanup extension] |
| V6 Cryptography | No | No cryptographic operation is introduced. [VERIFIED: codebase — phase scope] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Recursive deletion of an unintended target directory | Tampering | Use a GUID-owned temp child, resolve the path, require temp-root containment and expected prefix, then delete only that exact path in `finally`. [ASSUMED] |
| Stale target artifacts masking a portability failure | Tampering | Fresh target root per script invocation and guaranteed cleanup. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/png.mbt` — public encoder/chunk factories, filter strategy, and public decoder. [VERIFIED: codebase]
- `modules/mb-image/png/encode.mbt` — filter winner rule, short-distance matcher, and Stored/Fixed/Dynamic preflight selection. [VERIFIED: codebase]
- `modules/mb-image/png/encode_test.mbt` — eager source construction and complete public decoder equality oracle. [VERIFIED: codebase]
- `modules/mb-image/png/stream_encode_test.mbt` — public combined chunk route, hostile schedules, progress checks, and decoder oracle. [VERIFIED: codebase]
- `scripts/quality/Invoke-PngEncodeEvidence.ps1` — existing isolated target command and its persistent-root gap. [VERIFIED: codebase]
- `.planning/phases/39-bounded-filter-planning-and-replay/39-VERIFICATION.md` — preserved Phase 39 deterministic, bounded, acknowledgement-safe contracts. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- Local MoonBit toolchain probe — installed Moon toolchain versions. [VERIFIED: local environment]

### Tertiary (LOW confidence)

- Fixture-size recommendation and temporary-root implementation details are explicitly recorded in the Assumptions Log and must be validated by the focused four-target test. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new dependencies; current MoonBit tools and repository public APIs were inspected. [VERIFIED: local environment and codebase]
- Architecture: HIGH — all required seams exist in the current public tests and focused script. [VERIFIED: codebase]
- Fixture selection: LOW — formulas are source-driven candidates but have not been measured on the four targets in this research-only pass. [ASSUMED]
- Pitfalls: HIGH — Stored length invariance, strategy selection, hostile drain behavior, and current script persistence are visible in current source. [VERIFIED: codebase]

**Research date:** 2026-07-22  
**Valid until:** Fixture candidate validation is due immediately in the Phase 40 focused test; code-structure findings are valid until the PNG public test/encoder seams change.
