# Phase 70: Resumable RGBA16 PNG Encoding - Research

**Researched:** 2026-07-23
**Domain:** Caller-buffered, non-interlaced PNG Type-6/16 encoding in MoonBit
**Confidence:** LOW — the research seam classifies the `codebase` provider as LOW; the phase-specific implementation and test facts below were directly inspected in the current source tree. [VERIFIED: codebase]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public chunk selection
- **D-01:** Add the four `PngChunkEncoder::new_rgba16*` factory shapes matching the eager RGBA16 family; each selects `PngEncodeProfile::Rgba16` with `PngInterlaceStrategy::None`.
- **D-02:** Reuse `PngEncodeMachine::new_with_profile` and the existing `pull` lifecycle unchanged; a fresh eager encoder remains the byte-identity oracle.

### Hostile caller contract
- **D-03:** Prove parity under zero-capacity, one-byte, and ragged leases; count only acknowledged bytes and retain the one-pull lease boundary.
- **D-04:** Incompatible profiles, output/work/budget rejection, replay mutation, destination failure, and later pulls after failure retain existing atomic and sticky typed-terminal semantics.

### Scope and compatibility
- **D-05:** Keep the generic caller-buffered constructor frozen on RGB8/RGBA8 and do not add RGBA16 Adam7 selection, output staging, a new encoder machine, FFI, copied source trees, or release automation. Phase 71 owns Adam7; Phase 72 owns broad qualification.

### the agent's Discretion
- Use the closest `new_graya16` constructor family and existing stream-encode schedule harness; add only RGBA16-specific parity and lifecycle evidence.

### Deferred Ideas (OUT OF SCOPE)
- RGBA16 Adam7 selector and multipass evidence — Phase 71.
- Independent hostile matrix and portable qualification — Phase 72.
- Staging buffers, FFI, release automation, and copied-source workflows — out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RGBA16ENC-02 | Library users can select a caller-buffered RGBA16 encoder that reuses the bounded encoder machine, has eager-identical bytes under hostile capacities, retains accepted-only lease progress and sticky typed terminals, and exposes no partial output before atomic admission succeeds. | Add the four explicit façade factories to the existing profile-aware construction seam; reuse the GrayAlpha16 schedule, admission, and replay-mutation harnesses with an RGBA16 source and eager RGBA16 oracle. [VERIFIED: codebase] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain MoonBit-first; native stubs must stay isolated and replaceable. [VERIFIED: AGENTS.md]
- Public modules must keep acyclic, explicitly documented dependencies and preserve SemVer compatibility once stable. [VERIFIED: AGENTS.md]
- Public operations must be deterministic and usable without GUI state; benchmarks need declared reproducible workloads. [VERIFIED: AGENTS.md]
- This phase must not silently redefine module boundaries or architecture without an RFC. [VERIFIED: AGENTS.md]
- Code discovery should prefer the project knowledge graph; no graph file or graph MCP tool was available in this runtime, so the targeted source inspection fallback was used. [VERIFIED: codebase]
- No project skill directories were present, and `.planning/config.json` explicitly disables Nyquist validation. [VERIFIED: codebase]

## Summary

Phase 69 already introduced `PngEncodeProfile::Rgba16`, the Type-6/16 IHDR selection, U16 component-byte traversal, and four eager `PngEncoder::new_rgba16*` factories. `PngEncodeMachine::new_with_profile` is the single atomic admission/construction seam, and `PngChunkEncoder::pull` is format-agnostic: it validates source revision before leasing, writes then acknowledges each accepted byte, advances `total_written` only after acknowledgement, and caches `Finished` or typed `Failed` terminals. [VERIFIED: codebase]

The smallest Phase 70 change is therefore additive: define exactly four non-interlaced `PngChunkEncoder::new_rgba16*` factories in `stream_encode.mbt`, each forwarding `PngEncodeProfile::Rgba16` to `PngEncodeMachine::new_with_profile`; leave `pull`, generic chunk factories, `png.mbt`, `encode.mbt`, and white-box machine code untouched. Add a compact RGBA16 test helper and adapt only the proven GrayAlpha16 public schedule, atomic-admission, and replay-mutation patterns in `stream_encode_test.mbt`. [VERIFIED: codebase]

**Primary recommendation:** Add four non-interlaced RGBA16 chunk façade constructors and one focused public test family; reuse the existing bounded machine and `pull` unchanged. [VERIFIED: codebase]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Explicit RGBA16 chunk factory selection | API / Backend | — | The public MoonBit façade chooses the existing private profile and passes construction through the shared machine. [VERIFIED: codebase] |
| Atomic source/profile/resource admission | API / Backend | — | `PngEncodeMachine::new_with_profile` calls the profile-aware preflight before it returns a machine. [VERIFIED: codebase] |
| Byte emission, acknowledgement, and progress | API / Backend | — | `PngChunkEncoder::pull` owns one caller lease at a time and delegates canonical bytes to `PngEncodeMachine`. [VERIFIED: codebase] |
| Immutable source pixels | Database / Storage | API / Backend | The caller-owned `ImageView` is retained by the machine; revision checking prevents post-admission mutation from entering a later lease. [VERIFIED: codebase] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit `moon` | `0.1.20260713` (`moonc v0.10.4+2cc641edf`) | Compile and run the package tests. | Installed project toolchain; no new runtime or package is needed. [VERIFIED: local toolchain] |
| Existing `mb-image/png` package | workspace source | Profile-aware bounded PNG machine and chunk façade. | The phase is explicitly constrained to reuse these existing seams. [VERIFIED: codebase] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|
| `@bytes.OwnedBytes` / `MutByteLease` | workspace source | Caller-owned output leases in tests and public `pull`. | Reuse the existing schedule harness; do not introduce a different buffer abstraction. [VERIFIED: codebase] |
| `@io.MemoryWriter` | workspace source | Fresh eager bytes used as the identity oracle. | Build each oracle through `PngEncoder::new_rgba16*`, separate from the chunk encoder. [VERIFIED: codebase] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit RGBA16 chunk factories | Widen `PngChunkEncoder::new*` generic constructors | Rejected by D-05: it changes frozen RGB8/RGBA8 admission behavior. [VERIFIED: 70-CONTEXT.md] |
| Existing machine and `pull` | RGBA16-specific machine, staging buffer, or wrapper | Rejected by D-02/D-05: it duplicates the atomic and sticky-terminal contract without adding capability. [VERIFIED: 70-CONTEXT.md] |
| Non-interlaced factory set | RGBA16 all-strategies/interlace selector | Rejected for this phase: Adam7 belongs to Phase 71. [VERIFIED: 70-CONTEXT.md] |

**Installation:** None — Phase 70 adds no external packages. [VERIFIED: 70-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Caller ImageView + limits + budget + diagnostics
                 |
                 v
PngChunkEncoder::new_rgba16* (four public non-interlaced façades)
                 |
                 v
PngEncodeMachine::new_with_profile(Rgba16, ..., None)
                 |
        atomic profile/resource preflight
                 |
                 v
PngChunkEncoder::pull(one MutByteLease)
   | validate revision -> present byte -> destination.set -> acknowledge
   |                                       |                     |
   |                                       +-- failure ----------> Failed(error), no later lease writes
   +-- full lease ------------------------------------------------> NeedOutput
   +-- final acknowledgement ------------------------------------> Finished
```

The data flow above is the existing architecture; Phase 70 supplies only the missing RGBA16 entry points. [VERIFIED: codebase]

### Recommended Project Structure

```text
modules/mb-image/png/
├── stream_encode.mbt        # add the four RGBA16 chunk factories only
├── stream_encode_test.mbt   # add RGBA16 source/oracle and public lifecycle evidence
├── png.mbt                  # unchanged public types/profile enum
└── encode.mbt               # unchanged Phase 69 admission and U16 wire path
```

### Pattern 1: Explicit high-precision profile façade

**What:** Match the existing `new_graya16`, `new_graya16_with_compression_strategy`, `new_graya16_with_filter_strategy`, and `new_graya16_with_strategies` shapes, substituting only `PngEncodeProfile::Rgba16`. [VERIFIED: codebase]

**When to use:** Each `PngChunkEncoder::new_rgba16*` factory must fix `PngInterlaceStrategy::None`; do not expose `with_interlace_strategy` or `with_all_strategies` in this phase. [VERIFIED: 70-CONTEXT.md]

**Example:**

```moonbit
// Source: modules/mb-image/png/stream_encode.mbt (GrayAlpha16 analogue)
pub fn PngChunkEncoder::new_rgba16_with_strategies(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = PngEncodeMachine::new_with_profile(
    source, PngEncodeProfile::Rgba16, strategy, filter_strategy,
    PngInterlaceStrategy::None, limits, budget, diagnostics,
  )?
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}
```

The code is a planning sketch: follow the repository's existing `match`-based error-return syntax if MoonBit's `?` form is not accepted in this context. [VERIFIED: codebase]

### Pattern 2: Fresh eager bytes as the chunk identity oracle

**What:** Construct a fresh `PngEncoder::new_rgba16_with_strategies` output, then drain a separate `PngChunkEncoder::new_rgba16_with_strategies` under fixed schedules and compare complete bytes. [VERIFIED: codebase]

**When to use:** Cover Stored, FixedOrStored, and DynamicOrFixedOrStored crossed with None and Adaptive filters, because the closest GrayAlpha16 public evidence already proves that schedule matrix. [VERIFIED: codebase]

### Anti-Patterns to Avoid

- **Changing `pull`:** It already owns destination failure, revision validation, acknowledgement, progress, and sticky terminals for all profiles. [VERIFIED: codebase]
- **Adding an RGBA16 raster buffer:** The current machine retains source plus canonical emitter state and is explicitly bounded. [VERIFIED: codebase]
- **Reusing a chunk result as the oracle:** Use a separately constructed eager RGBA16 encoder, as D-02 requires. [VERIFIED: 70-CONTEXT.md]
- **Adding RGBA16 Adam7 APIs:** This would consume Phase 71 scope. [VERIFIED: 70-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| U16 RGBA wire mapping | A second Type-6/16 byte conversion path | Phase 69 `PngEncodeProfile::Rgba16` machine path | It already selects the profile-specific component traversal and Type-6/16 output. [VERIFIED: codebase] |
| Admission/resource transaction | Factory-local validation or output measurement | `PngEncodeMachine::new_with_profile` | It invokes the shared preflight before a chunk encoder is returned. [VERIFIED: codebase] |
| Lease/progress state machine | Format-specific chunk loop | Existing `PngChunkEncoder::pull` | It writes a byte before acknowledging it, updates progress from `machine.completed()`, and stores terminal state. [VERIFIED: codebase] |
| Hostile schedule harness | A new ad-hoc loop | `png_stream_graya16_public_drain` pattern | It proves zero/one/ragged leases, untouched tails, eager parity, and sticky completion. [VERIFIED: codebase] |

**Key insight:** RGBA16 changes profile selection, not caller-buffered transport semantics; the narrow factory seam is sufficient because the existing shared machine already has the required profile and lifecycle behavior. [VERIFIED: codebase]

## Common Pitfalls

### Pitfall 1: Accidentally exposing Adam7

**What goes wrong:** Copying the full GrayAlpha16 family would add interlace-selection constructors. [VERIFIED: codebase]

**Why it happens:** `new_graya16_with_interlace_strategy` and `new_graya16_with_all_strategies` exist as later capability precedent. [VERIFIED: codebase]

**How to avoid:** Copy only the four eager-RGBA16-aligned shapes and hard-code `PngInterlaceStrategy::None`. [VERIFIED: 70-CONTEXT.md]

**Warning signs:** A proposed `new_rgba16_with_interlace_strategy` or `new_rgba16_with_all_strategies` appears in the diff. [VERIFIED: 70-CONTEXT.md]

### Pitfall 2: Testing only byte parity

**What goes wrong:** A parity-only test can miss zero-capacity progress, lease-tail ownership, and sticky terminals. [VERIFIED: codebase]

**Why it happens:** The chunk encoder's public contract spans `written`, `total_written`, lease isolation, and later-pull outcomes. [VERIFIED: codebase]

**How to avoid:** Reuse the complete GrayAlpha16 drain harness and its `[0,1]`, `[1]`, and ragged schedules. [VERIFIED: codebase]

**Warning signs:** Tests collect bytes without asserting untouched sentinel tails or terminal pulls. [VERIFIED: codebase]

### Pitfall 3: Mutation or destination failure writing a later lease

**What goes wrong:** A source revision failure or released destination lease could advance progress or alter caller memory after failure. [VERIFIED: codebase]

**Why it happens:** These errors occur at the boundary between canonical emission and caller-owned storage. [VERIFIED: codebase]

**How to avoid:** Add one RGBA16 replay-mutation test modeled on `png_graya16_replay_mutation_is_sticky`, and retain the existing generic released-lease failure behavior rather than modifying `pull`. [VERIFIED: codebase]

**Warning signs:** A failed pull reports nonzero `written`, changes `total_written`, or a subsequent sentinel lease differs from `Z`. [VERIFIED: codebase]

## Code Examples

Verified patterns from the current source tree:

### Hostile caller-buffer schedule

```moonbit
// Source: modules/mb-image/png/stream_encode_test.mbt (GrayAlpha16 analogue)
for schedule in [
  [0UL, 1UL],
  [1UL],
  [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
] {
  png_stream_rgba16_public_drain(image, strategy, filter_strategy, schedule, eager)
}
```

The drain helper must assert `written <= capacity`, accepted-only total progress, untouched lease tails, byte equality with fresh eager output, and a zero-write `Finished` later pull. [VERIFIED: codebase]

### Atomic RGBA16 admission

```moonbit
// Source: modules/mb-image/png/stream_encode_test.mbt (GrayAlpha16 analogue)
let chunk = PngChunkEncoder::new_rgba16_with_strategies(
  image.view(), strategy, filter_strategy, limits, chunk_budget,
  @error.Diagnostics::new(),
).unwrap_err()
```

For incompatible profile, width, output, work, and budget rejections, compare the chunk error with a fresh eager RGBA16 error and assert no budget reservation or caller-lease mutation. [VERIFIED: codebase]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Eager-only explicit RGBA16 profile | Phase 69 `PngEncodeProfile::Rgba16` plus eager factory family | Phase 69, 2026-07-23 | Phase 70 can expose the same profile through chunk factories without changing U16 emission. [VERIFIED: 69-VERIFICATION.md] |
| Generic chunk constructors for RGB8/RGBA8 | Explicit high-precision chunk factory families | Existing Gray/GrayAlpha additions; RGBA16 pending | Keep generic admission frozen and make high precision opt-in. [VERIFIED: codebase] |

**Deprecated/outdated:** No production API is deprecated by this phase; it is additive and explicitly preserves generic chunk constructors. [VERIFIED: 70-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The current codebase inspection is sufficient to plan this internal, codebase-only additive phase without external library documentation. | Sources | Low — execution can confirm with the focused MoonBit tests. [ASSUMED] |

## Open Questions (RESOLVED)

1. **Should Phase 70 independently run all four target suites? — No.**
   - Resolution: the Phase 70 gate is the focused RGBA16 JS test family; Phase 72 owns multi-target portable qualification, per D-05. [VERIFIED: 70-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| MoonBit `moon` / `moonc` / `moonrun` | Compile and run PNG package tests | ✓ | `moon 0.1.20260713`; `moonc v0.10.4+2cc641edf` | — [VERIFIED: local toolchain] |

**Missing dependencies with no fallback:** None. [VERIFIED: local toolchain]

**Missing dependencies with fallback:** None. [VERIFIED: local toolchain]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No authentication surface is introduced. [VERIFIED: 70-CONTEXT.md] |
| V3 Session Management | no | No session state is introduced. [VERIFIED: 70-CONTEXT.md] |
| V4 Access Control | no | The public API operates only on caller-supplied image views and leases. [VERIFIED: codebase] |
| V5 Input Validation | yes | Reuse `PngEncodeMachine::new_with_profile` preflight for profile, geometry, output, work, and budget admission. [VERIFIED: codebase] |
| V6 Cryptography | no | PNG encoding adds no cryptographic operation. [VERIFIED: 70-CONTEXT.md] |

### Known Threat Patterns for MoonBit PNG chunk encoding

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Source mutation after admission | Tampering | `validate_replay_revision` fails before a later caller lease receives a byte, then the typed failure is sticky. [VERIFIED: codebase] |
| Exhaustion through output/work/budget request | Denial of service | Shared preflight rejects before machine creation, output, or budget reservation. [VERIFIED: codebase] |
| Released or invalid destination lease | Tampering | Existing `pull` converts `destination.set` failure into a sticky typed terminal; do not reimplement it. [VERIFIED: codebase] |

## Sources

### Primary (HIGH confidence)

- None — no external authoritative documentation was required for this codebase-only phase. [VERIFIED: research scope]

### Secondary (MEDIUM confidence)

- None. [VERIFIED: research scope]

### Tertiary (LOW confidence)

- `modules/mb-image/png/stream_encode.mbt` — direct inspection of the GrayAlpha16 constructor family, profile-aware machine construction, revision guard, and `pull` lifecycle. [VERIFIED: codebase]
- `modules/mb-image/png/stream_encode_test.mbt` — direct inspection of the schedule, atomic-admission, destination-failure, and replay-mutation harnesses; two targeted GrayAlpha16 tests passed on JS. [VERIFIED: codebase]
- `modules/mb-image/png/png.mbt`, `encode_test.mbt`, Phase 69 context/summary/verification, and Phase 70 context/requirements/roadmap/state — explicit RGBA16 profile/factory contract, known two-pixel source lanes, and phase scope. [VERIFIED: codebase]

## Metadata

**Confidence breakdown:**
- Standard stack: LOW — no package research was needed; the research seam classifies direct codebase evidence as LOW. [VERIFIED: codebase]
- Architecture: LOW — derived from current source ownership and direct control flow inspection. [VERIFIED: codebase]
- Pitfalls: LOW — derived from explicit public contract tests and locked phase decisions. [VERIFIED: codebase]

**Research date:** 2026-07-23
**Valid until:** 2026-08-22 — stable internal seams, unless Phase 70 implementation changes them. [ASSUMED]
