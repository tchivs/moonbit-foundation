# Phase 60: Bounded Adam7 Streaming Semantics - Research

**Researched:** 2026-07-23
**Domain:** MoonBit PNG bounded streaming replay integrity for GrayAlpha8 Adam7
**Confidence:** LOW (the required confidence seam classifies direct codebase evidence as LOW; the implementation evidence itself was inspected and targeted regressions pass.)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Replace the U16-only pre-lease revision check with a profile-neutral
  guard at the shared chunk pull seam. It must run before a lease can receive a
  replay byte, while preserving established terminal diagnostics for existing
  profiles.
- **D-02:** Cover a legal GrayAlpha8 Adam7 image in each None/Adaptive ×
  Stored/FixedOrStored/DynamicOrFixedOrStored combination. Mutate only after
  framing/progress has begun, then require zero bytes in the next lease,
  accepted-only totals, untouched lease tail, and the identical sticky error on
  later pulls.
- **D-03:** Retain the existing pass-local Adam7 traversal, filter contexts,
  preflight ledger, and replay plans. No GrayAlpha8-specific encoder branch,
  image/pass staging, or alternative replay mechanism is allowed.
- **D-04:** Keep incompatible descriptor, capability, geometry, output, work,
  and budget admission atomic before eager output or caller lease exposure;
  preserve legacy non-interlaced behavior.

### the agent's Discretion

- Reuse the smallest existing U16 replay-guard and Adam7 mutation helpers;
  production should change only the common revision-validation seam and tests
  should remain phase-local. Public all-target schedule and wire/decode proof
  stays in Phase 61.

### Deferred Ideas (OUT OF SCOPE)

- Public literal wire/decode, fresh zero/one/ragged schedules, frozen legacy
  matrix, and four-target package evidence belong to Phase 61.
- Decoder widening, Big-endian changes, staging, alternate encoders, release
  automation, registry publication, target wrappers, and source-tree copies
  remain outside this milestone.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must remain MoonBit-native; do not introduce a foreign codec implementation. [CITED: AGENTS.md]
- Keep public module dependencies acyclic and public API changes compatible with the project SemVer policy. [CITED: AGENTS.md]
- Keep public operations deterministic and GUI-independent. [CITED: AGENTS.md]
- Treat performance claims as requiring reproducible workloads and baselines. [CITED: AGENTS.md]
- Do not silently alter ecosystem/module boundaries; new module or architectural changes need an RFC. [CITED: AGENTS.md]
- Preserve the repository’s GSD workflow; this research recommends only the existing PNG module and its existing phase-local tests. [CITED: AGENTS.md]
- Code discovery should use the codebase graph first when its MCP tools are available; this runtime did not expose those tools and has no `.planning/graphs/graph.json`, so targeted `rg` and source inspection supplied the fallback evidence. [VERIFIED: workspace inspection]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GRAYA8A7-02 | Every legal None/Adaptive × Stored/FixedOrStored/DynamicOrFixedOrStored GrayAlpha8 Adam7 selection reuses the shared bounded pass traversal, atomic preflight, filtering, compression, and replay path; checked U8 source mutation fails before any further lease write with a zero-write sticky terminal result. | Generalize the one pre-lease guard in `PngChunkEncoder::pull`; reuse the existing GrayAlpha16 Adam7 six-pair mutation helper shape and GrayAlpha8 phase-local fixtures. [CITED: modules/mb-image/png/stream_encode.mbt:440] [CITED: modules/mb-image/png/stream_encode_test.mbt:3293] |
</phase_requirements>

## Summary

Phase 59 already proves fresh GrayAlpha8 Adam7 chunk/eager byte identity for all six compression/filter pairs, and it routes those factories through the profile-aware `PngEncodeMachine`. That machine captures `source.mutation_revision()` during successful preflight and builds its stored, fixed, or dynamic replay cursor from the same source/profile/interlace inputs. [CITED: modules/mb-image/png/stream_encode_test.mbt:1248] [CITED: modules/mb-image/png/stream_encode.mbt:675]

The only Phase-60 production gap is that `PngChunkEncoder::pull` calls `validate_u16_replay_revision` before any destination write, but that routine deliberately returns success for every non-U16 profile. Renaming/generalizing this method to a profile-neutral revision guard, retaining the exact `png-encode-{stored|fixed|dynamic}-replay-drift` selection, covers U8 GrayAlpha8 without a new encoder, buffer, traversal, plan, or error vocabulary. [CITED: modules/mb-image/png/stream_encode.mbt:440] [CITED: modules/mb-image/png/stream_encode.mbt:840]

**Primary recommendation:** Change only the common revision-validation method used at `PngChunkEncoder::pull`, remove its U16-profile exemption, and add a GrayAlpha8 Adam7 six-pair mutation matrix that directly mirrors the existing GrayAlpha16 assertion sequence. [CITED: modules/mb-image/png/stream_encode.mbt:456] [CITED: modules/mb-image/png/stream_encode_test.mbt:3220]

**Measured replay corpus (2026-07-23):** A controlled native run established a three-fixture all-seven-pass GrayAlpha8 Adam7 corpus. `stored-ramp-5x5` is the existing legal 5×5 helper with `s = 5*y + x`, `G = 0x20 + s`, and `A = 0xa0 + s`; `fixed-flat-5x5` is 5×5 with every pixel `(G, A) = (0x34, 0xa7)`; `dynamic-periodic-128x5` is 128×5 with `i = 2*(128*y + x)`, `G = i mod 5`, and `A = (i + 1) mod 5`. The 5×5 existing helper documents that this geometry exercises every Adam7 pass; all three fixtures keep both dimensions at least five. [VERIFIED: controlled local measurement] [CITED: modules/mb-image/png/stream_encode_test.mbt:175]

## Measured GrayAlpha8 Adam7 BTYPE Corpus

The phase-local replay test must create these exact deterministic images, assert `prefix[43] & 0x07`, and use the indicated public selector. A strategy fallback cannot satisfy the matrix. [VERIFIED: controlled local measurement]

| Fixture | Dimensions and pixel generator | Selector | None | Adaptive |
|---------|-------------------------------|----------|------|----------|
| `stored-ramp-5x5` | 5×5; `s=5*y+x`; `G=0x20+s`, `A=0xa0+s` | `Stored` | `0x01` | `0x01` |
| `fixed-flat-5x5` | 5×5; every pixel `G=0x34`, `A=0xa7` | `FixedOrStored` | `0x03` | `0x03` |
| `dynamic-periodic-128x5` | 128×5; `i=2*(128*y+x)`; `G=i mod 5`, `A=(i+1) mod 5` | `DynamicOrFixedOrStored` | `0x05` | `0x05` |

The measurement command was `moon -C modules/mb-image test png --target native --frozen -f 'TEMP Phase 60 GrayAlpha8 Adam7 BTYPE corpus measurement'`; it passed 1/1 while the reversible test was present and was removed immediately after the run. The durable implementation verification command is `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 replay mutations are sticky for every strategy pair'`; the implementation test must encode the table’s six explicit BTYPE checks. [VERIFIED: controlled local measurement]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Atomic descriptor/capability/limit admission | API / Backend | Database / Storage — source view only | The profile-aware preflight validates source facts, computes selected work, checks limits, and charges budget before returning a machine. [CITED: modules/mb-image/png/encode.mbt:1600] |
| Adam7 pass-local filtering | API / Backend | Database / Storage — source reads | The bounded cursor resolves a pass and row from logical position, then calls the Adam7-specific row winner and candidate byte functions. [CITED: modules/mb-image/png/encode.mbt:724] |
| Compression planning and bounded replay | API / Backend | — | Stored, fixed, and dynamic plans are selected from common preflight traversals and replay through owned scalar cursor state. [CITED: modules/mb-image/png/encode.mbt:1677] |
| Caller-lease ownership and replay-drift terminal | API / Backend | — | `PngChunkEncoder::pull` is the only destination-lease write seam and transitions failures to its sticky `Failed` state. [CITED: modules/mb-image/png/stream_encode.mbt:440] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit `moon` toolchain | `0.1.20260713` (`75c7e1f`) | Compile and run the existing PNG package tests. [VERIFIED: `moon --version`] | This repository’s checked toolchain is already pinned to that version in project stack guidance. [CITED: AGENTS.md] |
| `modules/mb-image/png` | workspace module | Existing single portable PNG encoder, preflight ledger, filters, plans, and chunk interface. [CITED: modules/mb-image/png/stream_encode.mbt:430] | The phase is explicitly constrained to extend this shared route, not introduce a package. [CITED: 60-CONTEXT.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@storage.OwnedImage` / `ImageView` | workspace API | Construct legal mutable GrayAlpha8 test input and expose the mutation revision observed by the machine. [CITED: modules/mb-image/png/stream_encode_test.mbt:177] | Use only in the phase-local mutation fixture and test helper. [CITED: modules/mb-image/png/stream_encode_test.mbt:3220] |
| `@bytes.MutByteLease` | workspace API | Assert no bytes are written into a sentinel-filled caller lease after drift. [CITED: modules/mb-image/png/stream_encode.mbt:440] | Use for first failed and later sticky pulls. [CITED: modules/mb-image/png/stream_encode_test.mbt:3244] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Profile-neutral common revision guard | GrayAlpha8-only pull branch | Rejected: it duplicates the shared seam and violates D-03 without improving timing or diagnostics. [CITED: 60-CONTEXT.md] |
| Existing `source_revision` comparison | Stage image/pass bytes before replay | Rejected: staging is out of scope and would alter the bounded architecture. [CITED: 60-CONTEXT.md] |
| Existing selected-plan error strings | New U8-specific drift diagnostics | Rejected: D-01 requires established diagnostics to remain unchanged. [CITED: 60-CONTEXT.md] |

**Installation:** None — no external packages are required. [VERIFIED: workspace inspection]

## Architecture Patterns

### System Architecture Diagram

```text
legal GrayAlpha8 ImageView
        |
        v
profile-aware atomic preflight
  -> Adam7 pass geometry + pass-local filters
  -> Stored / Fixed / Dynamic selected plan
  -> captures source_revision
        |
        v
PngChunkEncoder::pull(destination lease)
        |
        +-- revision unchanged --> present byte -> destination.set -> acknowledge -> accepted total
        |
        +-- revision changed ----> selected-plan drift error -> sticky Failed -> zero destination writes
```

The diagram describes the existing single machine flow; Phase 60 changes only the predicate that permits active-machine lease emission. [CITED: modules/mb-image/png/stream_encode.mbt:440] [CITED: modules/mb-image/png/stream_encode.mbt:675]

### Recommended Project Structure

```text
modules/mb-image/png/
├── stream_encode.mbt       # Rename/generalize the common pre-lease revision guard only
└── stream_encode_test.mbt  # GrayAlpha8 Adam7 mutation fixture/helper/matrix beside existing tests
```

No new package, target wrapper, source copy, staging layer, or encoder file is warranted. [CITED: 60-CONTEXT.md]

### Pattern 1: Guard before any caller-lease mutation

**What:** Compare the admitted `source_revision` to the current source revision at the start of every active `pull`, before the `while` loop can call `destination.set`. [CITED: modules/mb-image/png/stream_encode.mbt:455]

**When to use:** On every profile that can replay source-derived bytes after successful preflight, including GrayAlpha8. [CITED: modules/mb-image/png/stream_encode.mbt:695]

**Example:**

```moonbit
// Source: modules/mb-image/png/stream_encode.mbt:840
fn PngEncodeMachine::validate_replay_revision(
  self : PngEncodeMachine,
) -> Result[Unit, @error.CoreError] {
  if self.source.mutation_revision() == self.source_revision { return Ok(()) }
  match self.plan {
    PngDeflatePlan::Fixed(_) => Err(_png_encode_machine_state_error("png-encode-fixed-replay-drift"))
    PngDeflatePlan::Dynamic(_) => Err(_png_encode_machine_state_error("png-encode-dynamic-replay-drift"))
    PngDeflatePlan::Stored(_) => Err(_png_encode_machine_state_error("png-encode-stored-replay-drift"))
  }
}
```

This is the intended minimal shape: remove only the U16 profile predicate; keep the plan dispatch and its strings byte-for-byte equivalent. [CITED: modules/mb-image/png/stream_encode.mbt:844]

### Pattern 2: Pass-local Adam7 adaptive filtering

**What:** Resolve `(pass, row, in_row)` from the logical cursor and choose/retain an Adaptive filter winner at each pass-local row tag. [CITED: modules/mb-image/png/encode.mbt:724]

**When to use:** Preserve this behavior untouched while exercising GrayAlpha8 Adam7 with both `None` and `Adaptive`. [CITED: 60-CONTEXT.md]

**Example:**

```moonbit
// Source: modules/mb-image/png/encode.mbt:729
if self.interlace_strategy == PngInterlaceStrategy::Adam7 {
  let (pass, row, in_row) = _png_adam7_cursor_location(self.source, self.channels, self.index)?
  if in_row == 0UL {
    let winner = match self.filter_strategy {
      PngFilterStrategy::None => PngRowFilter::None
      PngFilterStrategy::Adaptive => _png_adam7_row_winner(
        self.source, self.profile, pass, row, self.channels,
      )?
    }
    // emit the pass-local tag and retain winner for that pass row
  }
}
```

### Anti-Patterns to Avoid

- **Guarding only U16 or only GrayAlpha8:** Either leaves another replayable profile unprotected or creates a special path; validate all profiles at the common seam. [CITED: modules/mb-image/png/stream_encode.mbt:844]
- **Checking after `destination.set`:** A drift error would arrive after the caller lease has been modified, violating D-01/D-02. [CITED: modules/mb-image/png/stream_encode.mbt:467] [CITED: 60-CONTEXT.md]
- **Replacing plan-specific errors with a generic drift error:** Existing Sticky-error comparisons deliberately depend on the selected-plan diagnostic. [CITED: modules/mb-image/png/stream_encode.mbt:849]
- **Adding image/pass staging or a second encoder:** Both are explicit scope violations and unnecessary because current cursor/replay state is bounded. [CITED: 60-CONTEXT.md] [CITED: modules/mb-image/png/encode.mbt:909]
- **Reusing the existing non-interlaced GrayAlpha8 admission helper unchanged:** It calls the non-interlaced strategy constructors, so Phase 60 must use or minimally parameterize the GrayAlpha16 Adam7-shaped helper with the explicit GrayAlpha8 Adam7 constructor. [CITED: modules/mb-image/png/stream_encode_test.mbt:2781] [CITED: modules/mb-image/png/stream_encode_test.mbt:3220]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Replay change detection | Per-profile byte fingerprints or GrayAlpha8-specific state | Captured `source_revision` plus the shared pre-lease comparison. [CITED: modules/mb-image/png/stream_encode.mbt:695] | O(1), already captured at admission, and preserves the existing selected-plan integrity semantics. [CITED: modules/mb-image/png/stream_encode.mbt:840] |
| Adam7 filtering | A new GrayAlpha8 row/pass walker | Existing `PngFilteredCursor` and `_png_adam7_cursor_location`. [CITED: modules/mb-image/png/encode.mbt:672] | It already owns pass-local rows and filter history without materializing pass buffers. [CITED: modules/mb-image/png/encode.mbt:588] |
| Atomic admission | Test-only eager/chunk preflight duplication | Existing profile-aware `PngEncodeMachine::new_with_profile`. [CITED: modules/mb-image/png/stream_encode.mbt:665] | Both eager and chunk paths are already fed by the one preflight ledger. [CITED: modules/mb-image/png/encode.mbt:1822] |
| Lease assertions | New ownership abstraction | Existing sentinel owners, `with_mut`, pull results, and `png_chunk_test_same_error`. [CITED: modules/mb-image/png/stream_encode_test.mbt:3244] | The helper already proves zero write, accepted-only total, all-tail preservation, and sticky error identity. [CITED: modules/mb-image/png/stream_encode_test.mbt:3253] |

**Key insight:** The machine has already recorded the profile-neutral fact needed for this phase (`source_revision`); the defect is only the U16 predicate that suppresses using it for a legal U8 replay. [CITED: modules/mb-image/png/stream_encode.mbt:550] [CITED: modules/mb-image/png/stream_encode.mbt:844]

## Common Pitfalls

### Pitfall 1: Mutation happens before meaningful replay evidence

**What goes wrong:** A test that mutates before any acknowledged byte does not prove preservation of accepted-only accounting across a replay boundary. [CITED: modules/mb-image/png/stream_encode_test.mbt:3232]

**Why it happens:** The tested encoder may never have passed through framing or advanced `total_written`. [CITED: modules/mb-image/png/stream_encode.mbt:499]

**How to avoid:** Pull one-byte leases until at least 44 bytes (PNG framing and first IDAT byte) have been acknowledged, assert the plan header, then mutate. [CITED: modules/mb-image/png/stream_encode_test.mbt:3232]

**Warning signs:** A test lacks a saved `accepted_total` and does not distinguish `NeedOutput` from an immediate `Failed` result. [CITED: modules/mb-image/png/stream_encode_test.mbt:3243]

### Pitfall 2: Only checking the first sentinel byte

**What goes wrong:** A partial write can escape detection if the implementation writes later in the lease. [CITED: modules/mb-image/png/stream_encode_test.mbt:3256]

**Why it happens:** The old GrayAlpha16 helper checks each byte of the first and later lease deliberately. [CITED: modules/mb-image/png/stream_encode_test.mbt:3256]

**How to avoid:** Fill each post-mutation lease with `Z` and iterate its full requested capacity after both the first failed pull and the later sticky pull. [CITED: modules/mb-image/png/stream_encode_test.mbt:3256]

**Warning signs:** A test checks `later.view().get(0)` only, or asks for a zero-capacity post-mutation lease. [CITED: modules/mb-image/png/stream_encode_test.mbt:3197]

### Pitfall 3: Losing plan-route coverage

**What goes wrong:** `FixedOrStored` or `DynamicOrFixedOrStored` can legally select a fallback, leaving the intended replay route unproved. [CITED: modules/mb-image/png/stream_encode_test.mbt:3237]

**Why it happens:** Selected DEFLATE plan is data-dependent. [CITED: modules/mb-image/png/encode.mbt:1704]

**How to avoid:** Keep `prefix[43] & 0x07` assertions. Use the measured `stored-ramp-5x5` rows for Stored `0x01`, `fixed-flat-5x5` for Fixed `0x03`, and `dynamic-periodic-128x5` for Dynamic `0x05`; exercise each under both filters. Do not substitute the U16 fixture without preserving the measured U8 generator and dimensions. [VERIFIED: controlled local measurement]

**Warning signs:** The six-pair test merely reaches `Failed` after mutation but never asserts the selected pre-mutation route. [CITED: modules/mb-image/png/stream_encode_test.mbt:3237]

### Pitfall 4: Accidentally moving Phase 61 work into Phase 60

**What goes wrong:** Fresh zero/one/ragged schedules, wire/decode or four-target work increases scope without strengthening the pre-lease mutation proof. [CITED: 60-CONTEXT.md]

**How to avoid:** Reuse one-byte pre-mutation pulls and nonzero sentinel post-mutation leases only; leave new hostile schedule and public wire/decode evidence to Phase 61. [CITED: 60-CONTEXT.md]

## Code Examples

Verified patterns from the current module:

### Common operation: Test the full GrayAlpha8 Adam7 drift matrix

```moonbit
// Pattern source: modules/mb-image/png/stream_encode_test.mbt:3296
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    png_graya8_adam7_replay_mutation_is_sticky(
      selected_graya8_adam7_replay_corpus(strategy, filter),
      strategy,
      filter,
      PngInterlaceStrategy::Adam7,
      expected_btype(strategy),
      7UL,
    )
  }
}
```

The implementation should name/use Phase-60-local GrayAlpha8 helpers rather than alter the existing U16 helper or fixtures; retain the U16 helper as regression evidence. Map Stored to `stored-ramp-5x5`, Fixed to `fixed-flat-5x5`, and Dynamic to `dynamic-periodic-128x5`, preserving the explicit BTYPE assertions for both filters. [CITED: modules/mb-image/png/stream_encode_test.mbt:177] [CITED: modules/mb-image/png/stream_encode_test.mbt:3220] [VERIFIED: controlled local measurement]

### Common operation: Preserve sticky terminal accounting

```moonbit
// Pattern source: modules/mb-image/png/stream_encode_test.mbt:3243
let accepted_total = prefix.length().to_uint64()
mutate_source_after_prefix(image)
let first_failed = pull_into_sentinel(encoder, post_capacity)
assert(first_failed.written() == 0UL)
assert(first_failed.total_written() == accepted_total)
assert_all_bytes_are_sentinel(first_lease)
let sticky = pull_into_fresh_sentinel(encoder, post_capacity)
assert(sticky.written() == 0UL)
assert(sticky.total_written() == accepted_total)
assert(png_chunk_test_same_error(first_error, sticky_error))
assert_all_bytes_are_sentinel(later_lease)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| U16-only pre-lease source-revision validation | Profile-neutral source-revision validation at the shared chunk pull seam | Phase 60 implementation | GrayAlpha8 Adam7 obtains the same zero-write, sticky replay-drift behavior while retaining legacy error strings. [CITED: modules/mb-image/png/stream_encode.mbt:844] |

**Deprecated/outdated:**

- `validate_u16_replay_revision` as a U16-gated semantic contract: replace it with a profile-neutral name/condition while preserving its selected-plan error mapping. [CITED: modules/mb-image/png/stream_encode.mbt:844]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. All three GrayAlpha8 Adam7 BTYPE corpus claims were measured directly for both filters. [VERIFIED: controlled local measurement] | — | — |

## Open Questions

None. The controlled measurement resolved the Fixed/Dynamic corpus gate: the three-fixture matrix above produces Stored `0x01`, Fixed `0x03`, and Dynamic `0x05` for both filters. [VERIFIED: controlled local measurement]

## Environment Availability

Step 2.6: SKIPPED — this is a code-and-test-only change with no service, package, or CLI dependency beyond the already-installed MoonBit repository toolchain. [VERIFIED: `moon --version`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | This in-process image encoder has no user authentication boundary. [CITED: modules/mb-image/png/stream_encode.mbt:440] |
| V3 Session Management | no | The encoder state is a per-instance pull state, not an authenticated session. [CITED: modules/mb-image/png/stream_encode.mbt:2] |
| V4 Access Control | no | This phase introduces no resource authorization capability. [CITED: 60-CONTEXT.md] |
| V5 Input Validation | yes | Retain profile-aware descriptor/capability validation and checked geometry/output/work/budget preflight before construction. [CITED: modules/mb-image/png/encode.mbt:71] [CITED: modules/mb-image/png/encode.mbt:1782] |
| V6 Cryptography | no | PNG compression/replay has no cryptographic operation in this scope. [CITED: 60-CONTEXT.md] |

### Known Threat Patterns for bounded PNG streaming

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Source mutation after admission changes replay input | Tampering | Compare captured/current source revisions before the active pull writes any lease byte; map to existing plan-specific sticky drift error. [CITED: modules/mb-image/png/stream_encode.mbt:840] |
| Invalid source/limits produce observable partial output | Tampering / Denial of Service | Keep the shared preflight limit checks and single post-check budget charge before returning eager/chunk machinery. [CITED: modules/mb-image/png/encode.mbt:1782] [CITED: modules/mb-image/png/stream_encode.mbt:430] |
| Caller lease is partially modified on a failed pull | Tampering | Test nonzero sentinel leases on first failure and later sticky failure; the guard remains before the first `destination.set`. [CITED: modules/mb-image/png/stream_encode.mbt:456] [CITED: modules/mb-image/png/stream_encode_test.mbt:3256] |

## Sources

### Primary (LOW confidence under seam classification)

- [modules/mb-image/png/stream_encode.mbt](../../../modules/mb-image/png/stream_encode.mbt) — active pull seam, captured source revision, U16-only guard, plan-specific diagnostics, and profile factory construction.
- [modules/mb-image/png/encode.mbt](../../../modules/mb-image/png/encode.mbt) — profile admission, Adam7 cursor/filter behavior, atomic preflight, selected compression plan, and ledger/budget checks.
- [modules/mb-image/png/stream_encode_test.mbt](../../../modules/mb-image/png/stream_encode_test.mbt) — six-pair GrayAlpha8 fresh parity/admission tests and GrayAlpha16 mutation helper/matrix.
- [Phase 59 verification](../59-grayalpha8-adam7-factory-and-pass-profile/59-VERIFICATION.md) — completed predecessor evidence and explicitly deferred replay coverage.

### Executed verification

- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 chunk all strategy parity'` — passed (1/1). [VERIFIED: local test run]
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 strategy admission is atomic'` — passed (1/1). [VERIFIED: local test run]
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 replay mutations are sticky for every strategy pair'` — passed (1/1). [VERIFIED: local test run]
- `moon -C modules/mb-image test png --target native --frozen -f 'TEMP Phase 60 GrayAlpha8 Adam7 BTYPE corpus measurement'` — passed (1/1); the test was temporary and removed after the controlled measurement. [VERIFIED: controlled local measurement]

## Metadata

**Confidence breakdown:**

- Standard stack: LOW — direct workspace/toolchain inspection; no external package decision is involved. [VERIFIED: `moon --version`]
- Architecture: LOW — direct source inspection and targeted existing regression runs; the mandatory confidence seam rated provider `codebase` LOW. [VERIFIED: `gsd-tools classify-confidence`]
- Pitfalls: LOW — derived from direct current helper/source behavior and a controlled native BTYPE measurement; the corpus gate is resolved, but future selector changes require remeasurement. [CITED: modules/mb-image/png/stream_encode_test.mbt:3220] [VERIFIED: controlled local measurement]

**Research date:** 2026-07-23
**Valid until:** Implementation of Phase 60, or 30 days if the PNG replay seam remains unchanged. [ASSUMED]
