# Phase 105: Bounded Type 2 Validation and Retained Metrics - Research

**Researched:** 2026-07-28  
**Status:** Complete  
**Scope:** Implementation-ready deltas for the existing v0.34 milestone research

## Executive Recommendation

Implement one private, iterative Type 2 VM over the Phase 104 per-GID descriptors, with checked Q16.16 arithmetic, exact hint framing, explicit local/global call frames, deterministic project-owned random, a fixed-point conservative-bounds sink, and one all-glyph admission transaction. Reuse the existing CFF structural authority and `FontAdmissionLedger`; do not publish `Path2` or run query-time VM work in Phase 105.

The existing four-plan split remains correct:

1. fixed arithmetic, Private DICT seed retention, matrix facts, and private limits;
2. complete non-geometry VM semantics, hints, subroutines, termination, and ledgers;
3. line/curve/flex geometry, matrix normalization, compact retained bounds, and all-GID execution;
4. atomic admission integration, mutation/error precedence, exact/one-short evidence, and regressions.

## Normative Findings

### Type 2 program and number model

- Adobe TN #5177 defines a CharString as byte-coded numbers and operators, with `255` representing a signed 16.16 number and `28` introducing a signed short integer.
- The operator surface is closed. Reserved/undefined operator codes must not be silently ignored. The project may classify recognized CFF2-only operators as Capability and malformed/reserved Type 2 programs as Data.
- The specification's undefined numeric outcomes are not portable semantics. The project should deterministically reject overflow, division by zero, negative square root, invalid integer/index operands, and other undefined numeric cases as Data.
- `random` returns a value in `(0, 1]` but the specification does not prescribe a generator. The context's project-owned xorshift32, per-GID reset, and output mapping are therefore compatible deterministic policy.

### Width, hints, and masks

- A non-default width is the first number and is interpreted as a delta from `nominalWidthX`; omission selects `defaultWidthX`.
- Adobe TN #5176 defines both width values as Private DICT numbers, defaulting to zero.
- Hints occur before path construction. `hintmask` and `cntrmask` are followed by exactly the bytes needed for the complete stem list, one bit per stem.
- A mask is not legal with zero stem hints. Pending stack operands before a mask form additional vertical stems.
- Hints are validation/framing input only for MNF; they do not alter retained geometry.

### Stack, transient storage, subroutines, and termination

- Adobe's implementation limits are: argument stack 48, total H/V stems 96, subroutine nesting 10, CharString length 65535, local/global Subrs count 65536, and TransientArray elements 32.
- `get` before `put` is explicitly undefined. MNF should track initialization and reject uninitialized reads as Data; returning a fabricated zero would accept a program with no defined outline.
- Local/global subroutine bias is `107`, `1131`, or `32768` based solely on the selected INDEX count.
- A subroutine may end with `return` or `endchar`; if it ends with `endchar`, the glyph terminates. The root CharString may itself end with a final call whose target reaches `endchar`. To retain complete-program validation, MNF should allow this only when the call is the tail token of every suspended caller frame.
- Root EOF, subroutine EOF, root `return`, illegal trailing bytes, invalid call indices, and exhausted explicit limits remain deterministic Data/Resource failures.

### Deprecated compatibility forms

- `dotsection` is documented as an obsolete no-op and may be supported as such.
- Four-argument seac-compatible `endchar` is deprecated and requires StandardEncoding name lookup plus component composition. Returning a stable Capability in Phase 105 is preferable to partial support.
- CFF2 variation operators remain out of the static CFF1 phase.

### CFF Private facts and matrices

- Adobe TN #5176 defines `initialRandomSeed` as a Private DICT `number` with default `0`; it is not an SID.
- The Top DICT FontMatrix default is `[0.001 0 0 0.001 0 0]`.
- CID FDArray selects a Font DICT and its Private DICT for each glyph. Preserve explicit presence/absence of an FD-local FontMatrix so name-keyed glyphs cannot multiply the Top matrix twice and omitted FD-local matrices cannot accidentally inject a second `0.001`.
- Continue the context's exact rational composition and normalize to OpenType design units with `head.unitsPerEm`. Freeze multiplication order with hand-derived name-keyed, CID explicit-FD, and CID omitted-FD vectors before broad operator work.

### OpenType metrics authority

- OpenType requires rendering engines to use `hmtx` advance widths for CFF OpenType fonts, even though CFF carries widths.
- Collection faces sharing one CFF table may have different face-local `hmtx` advances for the same GID.
- Therefore Type 2 width is validated for program correctness only. Public advance and LSB stay in `hmtx`; retained CFF bounds supply the geometric extent used by the existing RSB formula.

## Repository Integration

- Extend `CffPrivateDict` to retain checked `initialRandomSeed`.
- Preserve FD FontMatrix presence in `CffFontDict`/`CffGlyphDescriptor`; remove the current name-keyed duplicate Top/FD matrix representation before composition.
- Add private fixed arithmetic, VM/frame, bounds sink, and qualification files beside the existing `cff_*` implementation.
- Split the current structural admission so it stages facts and charge without committing. Execute all GIDs in ascending order, retain only compact optional bounds, preflight combined charge, recheck revision, commit once, then construct complete `AdmittedCff1`.
- Reuse `GlyphBoundsFacts`, existing `hmtx` reading, `FontAdmissionLedger`, and the established State → Resource → Capability → Data precedence.

## Validation Strategy

- Hand-derived arithmetic vectors: signed decode, toward-zero multiply/divide, floor sqrt, overflow edges, negative floor/positive ceil.
- VM vectors: every operator family, stack 48/49, transient written/unwritten, stem 96/97, exact/truncated masks, bias thresholds, nesting 10/11, root/subroutine termination variants, deprecated forms, and deterministic random reset/order independence.
- Geometry vectors: every line/curve/flex form, contour closure, empty glyph, negative fractional bounds, name/CID matrices, omitted FD matrix, and overflow.
- Admission vectors: all-GID ascending first-failure, exact/one-short named limits, source mutation, deliberately mismatched CFF width versus `hmtx`, no retained facts on failure, and one combined budget commit.
- Final phase verification must run native tests plus `moon check --target all`; four-target semantic qualification remains Phase 107.

## Sources

- Adobe Technical Note #5177, *The Type 2 Charstring Format*: https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf
- Adobe Technical Note #5176, *The Compact Font Format Specification*: https://adobe-type-tools.github.io/font-tech-notes/pdfs/5176.CFF.pdf
- OpenType 1.9.1, `CFF ` table: https://learn.microsoft.com/en-us/typography/opentype/spec/cff
- OpenType `hmtx` table: https://learn.microsoft.com/en-us/typography/opentype/otspec170/hmtx

