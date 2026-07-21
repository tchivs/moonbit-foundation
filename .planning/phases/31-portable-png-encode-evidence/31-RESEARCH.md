# Phase 31: Portable PNG Encode Evidence - Research

**Researched:** 2026-07-21  
**Domain:** Four-target public PNG caller-buffered encode evidence  
**Confidence:** HIGH

## User Constraints

No `CONTEXT.md` exists for this phase. The roadmap, requirements, project state, and the phase assignment are controlling scope. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`]

### Locked Decisions

- Phase 31 owns portable hostile-output evidence and one public chunk-decode → image-operation → chunk-encode workflow; it does not redesign the encoder. [VERIFIED: codebase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`]
- Preserve the Phase 29/30 canonical stored-DEFLATE PNG bytes, one shared preflight path, caller-scoped output leases, and sticky terminal behavior. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`, `.planning/phases/29-pausable-png-encode-substrate/29-VERIFICATION.md`, `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`]
- Verify behavior independently on `js`, `wasm`, `wasm-gc`, and `native`; do not substitute all-target interface generation for runtime behavior. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`, `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`] [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]
- Keep the quality path scoped to PNG. Release, registry, credential, FFI, compression optimization, new fixtures, and new public surface are out of scope. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `scripts/quality/Invoke-MoonQuality.ps1`, `AGENTS.md`]

### the agent's Discretion

- Choose compact hostile capacity schedules and black-box helper names, provided each schedule proves exact per-pull/cumulative progress, eager-byte parity, and post-terminal destination non-mutation. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/stream_encode_test.mbt`]
- Reuse the existing `png-portable` executable and PNG lane rather than adding a second example or runner. [VERIFIED: codebase: `examples/png-portable/main/main.mbt`, `scripts/quality/Invoke-MoonQuality.ps1`, `.planning/milestones/v0.8-phases/28-portable-png-streaming-evidence/28-01-SUMMARY.md`]

### Deferred Ideas (OUT OF SCOPE)

- Compression-ratio optimization, host streaming adapters, APNG, colour/metadata expansion, and all release/registry automation remain deferred. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/STATE.md`]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PNGE-04 | Maintainers verify hostile capacities, eager/chunk parity, limits, budgets, and terminals on all four targets. | Add one named public black-box evidence test to `stream_encode_test.mbt`; its name must match the existing isolated runner filter, so the runner executes it once in each target-specific build directory. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |
| PNGE-05 | A library user runs public chunk-decode → operation → chunk-encode with deterministic output evidence. | Change the existing `png-portable` executable's final eager writer route to `PngChunkEncoder` pulls, retain its public chunk decode and bilinear resize, and exact-match its one evidence line from the scoped PNG quality lane. [VERIFIED: codebase: `examples/png-portable/main/main.mbt`, `scripts/quality/Invoke-MoonQuality.ps1`] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain MoonBit; native is primary but portable targets require deliberate conformance. [VERIFIED: codebase: `AGENTS.md`]
- No FFI is needed; package dependencies remain acyclic and explicit. [VERIFIED: codebase: `AGENTS.md`, `modules/mb-image/png/moon.pkg`]
- Public operations and evidence must be deterministic and GUI-independent. [VERIFIED: codebase: `AGENTS.md`]
- Code discovery should prefer the project graph MCP; it was not exposed to this research runtime, so targeted `rg` inspection was used. [VERIFIED: runtime tool availability; `AGENTS.md`]
- Phase execution must remain inside the GSD workflow. [VERIFIED: codebase: `AGENTS.md`]

## Summary

Phase 30 supplied the complete public contract but deliberately qualified its behavioral tests only on native: `PngChunkEncoder::new` delegates to `PngEncodeMachine::new`, while `pull` applies present → destination set → acknowledgement and persists either `Finished` or the original `CoreError`. Its current tests prove zero/one/irregular progress, RGB/RGBA parity, lease non-retention, and sticky terminals, but they do not qualify the entire evidence set across four runtime targets. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt,stream_encode_test.mbt}`, `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`]

The smallest complete Phase 31 is therefore three evidence edits: add a four-target-named black-box schedule/preflight test, convert the established `png-portable` public executable from eager output to public chunk output, and revise only the existing PNG lane's exact evidence string and stage label. The isolated runner already creates separate target directories and passed its current three selected tests on all four targets during this research; the quality lane already runs the package suite and exact public-example evidence without calling release infrastructure. [VERIFIED: local execution: `Invoke-PngEncodeEvidence.ps1` for all four targets] [VERIFIED: codebase: `scripts/quality/{Invoke-PngEncodeEvidence,Invoke-MoonQuality}.ps1`, `examples/png-portable/main/main.mbt`]

**Primary recommendation:** Plan one evidence-only implementation wave touching `stream_encode_test.mbt`, `examples/png-portable/main/main.mbt`, and `scripts/quality/Invoke-MoonQuality.ps1`; reuse `Invoke-PngEncodeEvidence.ps1` unchanged by naming the new test to match its established filter. [VERIFIED: codebase: `scripts/quality/Invoke-PngEncodeEvidence.ps1`, `.planning/phases/30-public-png-chunk-encoder/30-01-SUMMARY.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Exact caller-buffer progress and terminal non-mutation | Portable package black-box test | Existing isolated runner | The public `PngChunkEncoder::pull` is the behavior under test; the runner provides per-target execution isolation. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt,stream_encode_test.mbt}`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |
| Preflight/limit/budget equivalence | Portable package black-box test | Existing eager encoder oracle | Both eager and chunk construction use `PngEncodeMachine::new` and `_png_encode_preflight`; comparison must retain the observable error and zero-output boundary. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt,encode_test.mbt}`] |
| Public end-to-end workflow | `png-portable` executable | Scoped PNG quality lane | The executable is the actual consumer and the lane exact-matches its one target-neutral evidence line on each runtime. [VERIFIED: codebase: `examples/png-portable/main/main.mbt`, `scripts/quality/Invoke-MoonQuality.ps1`] |
| Target conformance | MoonBit per-target command | Package target metadata | The package declares all four required targets and MoonBit documents that `--target all` expands to these four (not LLVM). [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`] [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |

## Standard Stack

### Core

| Component | Version | Purpose | Why standard |
|---|---:|---|---|
| Existing `tchivs/mb-image/png` | repository current | Sole public `PngChunkDecoder`/`PngChunkEncoder` API and canonical PNG implementation | Phase 31 must prove this API, not a duplicate adapter or alternate encoder. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt,moon.pkg}`] |
| `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Compile and execute the four portable target runs | Installed versions were checked locally; `moon test --help` exposes `wasm`, `wasm-gc`, `js`, `native`, and `all`. [VERIFIED: local `moon --version`, `moonc -v`, `moonrun --version`, `moon test --help`] |
| Existing PNG quality scripts | repository current | Isolated per-target encoder checks and exact public workflow gate | They already contain the required supported-target set, target-directory isolation, and release-route isolation. [VERIFIED: codebase: `scripts/quality/{Invoke-PngEncodeEvidence,Invoke-MoonQuality}.ps1`] |

### Supporting

| Component | Purpose | When to use |
|---|---|---|
| `PngEncoder` plus `MemoryWriter` eager oracle | Compare canonical bytes and preflight errors | Tests only; it is the compatibility oracle, not the Phase 31 public workflow output path. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,encode_test.mbt,stream_encode_test.mbt}`] |
| Existing public decode schedule and `@ops.resize_bilinear` | Provide the meaningful process stage before chunk encode | Preserve the existing 75-byte chunk decode and deterministic 3×1 resize in `png-portable`. [VERIFIED: codebase: `examples/png-portable/main/main.mbt`, `.planning/milestones/v0.8-phases/28-portable-png-streaming-evidence/28-01-VERIFICATION.md`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Extend existing black-box encode test | Build a new PNG evidence package | Rejected: a second test package duplicates fixtures/helpers and does not exercise the established public package test path. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |
| Convert `png-portable` in place | Add a second chunk-encode example | Rejected: Phase 28 established this executable as the sole portable PNG consumer and quality gate; a second example broadens maintenance without improving contract coverage. [VERIFIED: codebase: `.planning/milestones/v0.8-phases/28-portable-png-streaming-evidence/{28-01-SUMMARY.md,28-01-VERIFICATION.md}`, `examples/png-portable/main/main.mbt`] |
| Reuse scoped PNG lane | Add release/registry qualification | Rejected: the current lane's isolation guard rejects release routing and the milestone explicitly defers it. [VERIFIED: codebase: `scripts/quality/Invoke-MoonQuality.ps1`, `.planning/REQUIREMENTS.md`] |

**Installation:** None. This phase introduces no external package, tool, FFI, or new MoonBit module. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`, `.planning/REQUIREMENTS.md`]

## Architecture Patterns

### System Architecture Diagram

```text
compatible RGB8 / straight-RGBA8 image
              |
              v
  PngChunkEncoder::new(limits, budget, diagnostics)
       |                         |
       | failure                 | active encoder
       v                         v
typed eager-equivalent      hostile caller lease schedules
preflight error             0 -> 1 -> irregular capacities
                                 |
                                 v
                   exact written / total_written / outcome
                                 |
                +----------------+----------------+
                |                                 |
                v                                 v
     concatenate and compare               terminal fresh sentinel
       canonical eager bytes               remains unmodified

fixed PNG bytes -> PngChunkDecoder -> resize_bilinear -> PngChunkEncoder
                                                              |
                                                              v
                                         exact 78 bytes + digest + one status line
                                                              |
                                                              v
                                  js / wasm / wasm-gc / native PNG quality lane
```

### Recommended Project Structure

```text
modules/mb-image/png/
  stream_encode_test.mbt       # extend public hostile schedules and atomic preflight evidence
examples/png-portable/main/
  main.mbt                     # switch the final public workflow step to PngChunkEncoder
scripts/quality/
  Invoke-MoonQuality.ps1       # rename/update only PNG workflow evidence expectation
  Invoke-PngEncodeEvidence.ps1 # unchanged: new test name reuses its target-isolated filter
```

### Pattern 1: One public drain helper, three hostile schedules

**What:** Construct a fresh `PngChunkEncoder`, give it only callback-scoped `MutByteLease` values, append exactly `written()` bytes after each pull, and require `total_written()` to equal the collected prefix. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt`, `modules/mb-image/png/stream_encode.mbt`]

**When to use:** Execute it for RGB8 and straight-RGBA8 sources under `empty-then-one-byte` (`[0, 1]`), `one-byte` (`[1]`), and `zero-tiny-ragged` (`[0, 8, 4, 1, 13, 2, 5, 3, 21]`). The nonzero ragged suffix is the existing public PNG hostile packet sequence; prepending zero adds the output-empty lease case. [VERIFIED: codebase: `modules/mb-image/png/stream_decode_test.mbt`, `modules/mb-image/png/stream_encode_test.mbt`] [ASSUMED: exact encoder schedule labels and the zero-prefixed reuse]

**Required assertions:** Every active call has `written() <= capacity`; zero capacity returns `0/0/NeedOutput`; the aggregate equals the eager oracle exactly; final and repeated terminal pulls return zero bytes with unchanged sentinel-filled destination; and a released lease failure is replayed without later mutation. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,stream_encode_test.mbt}`, `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`]

### Pattern 2: Atomic public preflight parity

**What:** In the same four-target-named test, compare `PngChunkEncoder::new` with the eager `PngEncoder` oracle for an output-byte limit, exhausted work budget, and unsupported retained metadata. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,encode_test.mbt,stream_encode.mbt}`]

**When to use:** Verify category/code/context and relevant requested/limit fields, confirm eager writer position is zero, and confirm the rejected constructor leaves its `Budget::remaining().work()` unchanged. The public constructor receives no destination lease, so a rejected construction cannot expose a PNG byte. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,encode_test.mbt,stream_encode.mbt}`] [ASSUMED: include every listed error field when non-`None`]

### Pattern 3: Public workflow consumes and emits chunks

**What:** Retain the current fixed public decoding schedule and bilinear resize, then use `PngChunkEncoder::new` with a reusable max-capacity `OwnedBytes` owner and a named output schedule; copy only the accepted prefix after every callback closes. [VERIFIED: codebase: `examples/png-portable/main/main.mbt`, `examples/qoi-portable/main/main.mbt`, `modules/mb-image/png/stream_encode.mbt`]

**When to use:** Freeze input bytes/read count, resize pixels, output pull count, exact canonical 78 bytes, and digest `626208771` in the executable and quality-lane expectation. The current eager route already proves the 78-byte/digest baseline identically on all four targets. [VERIFIED: local execution: `moon -C examples/png-portable run main --target {js,wasm,wasm-gc,native} --frozen`; codebase: `examples/png-portable/main/main.mbt`, `scripts/quality/Invoke-MoonQuality.ps1`]

### Anti-Patterns to Avoid

- **Eager output in the Phase 31 example:** Do not leave `MemoryWriter`/`PngEncoder` in the workflow; it would not exercise PNGE-05's public chunk output. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `examples/png-portable/main/main.mbt`]
- **A new public encoder fixture/API:** Do not edit `png.mbt`, interface policy, or package imports; Phase 30 froze that public surface. [VERIFIED: codebase: `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`]
- **Only `moon info --target all`:** It validates generated API availability, not hostile runtime behavior; run the per-target evidence runner and the scoped PNG lane. [VERIFIED: codebase: `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`]
- **Broad quality routing:** Do not call Required, QOI, or release lanes; `Assert-PngLaneIsolation` intentionally fails if those routes are reached. [VERIFIED: codebase: `scripts/quality/Invoke-MoonQuality.ps1`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Second byte emitter or oracle | A test-only PNG encoder | Existing eager `PngEncoder` and public `PngChunkEncoder` | They are the two contractual paths whose byte/error parity matters. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |
| New target orchestrator | New PowerShell/Python runner | `Invoke-PngEncodeEvidence.ps1` | It validates the four declared targets and gives each target a dedicated build directory. [VERIFIED: codebase: `scripts/quality/Invoke-PngEncodeEvidence.ps1`] |
| New public workflow project | Extra MoonBit executable/module | Existing `examples/png-portable` | It already proves public chunk decode, a real pure operation, canonical bytes, and quality-lane output. [VERIFIED: codebase: `examples/png-portable/main/main.mbt`, `scripts/quality/Invoke-MoonQuality.ps1`] |
| New binary fixture family | Hand-authored output test data | Existing fixed PNG source/expected output and generated decode corpus | The workflow's source/output are already frozen; Phase 31 needs output-capacity behavior, not new decode coverage. [VERIFIED: codebase: `examples/png-portable/main/main.mbt`, `.planning/milestones/v0.8-phases/28-portable-png-streaming-evidence/28-01-VERIFICATION.md`] |

**Key insight:** Phase 31 should increase only the observable evidence surface: the single public encoder and its existing portable consumer already contain the product behavior. [VERIFIED: codebase: `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`, `.planning/ROADMAP.md`]

## Common Pitfalls

### Pitfall 1: Empty capacity treated as completion

**What goes wrong:** A zero-length lease can be reported as `Finished` or can advance totals without a destination write. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt`]

**How to avoid:** Assert the initial zero-capacity pull is `written=0`, `total_written=0`, and `NeedOutput`, then continue with nonempty capacities. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt`]

### Pitfall 2: Canonical parity checked only at a prefix

**What goes wrong:** A schedule can look correct until a chunk/header/checksum boundary but omit or duplicate a later byte. [VERIFIED: codebase: `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`]

**How to avoid:** Collect exactly the `written()` prefix per pull and compare the completed aggregate byte-for-byte to the eager result for both RGB8 and straight-RGBA8. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt`]

### Pitfall 3: Terminal proof accidentally mutates a new lease

**What goes wrong:** A completed or failed encoder observes a later destination and overwrites a sentinel despite reporting zero progress. [VERIFIED: codebase: `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`]

**How to avoid:** Supply a fresh sentinel-filled owner after both success and a released-lease failure; assert `written=0`, stable total/error, and byte-for-byte unchanged owner. [VERIFIED: codebase: `modules/mb-image/png/stream_encode_test.mbt`, `modules/mb-image/png/stream_encode.mbt`]

### Pitfall 4: Constructor rejection tested only through eager Writer

**What goes wrong:** Existing eager tests can pass while public construction changes error/budget behavior before a caller receives an encoder. [VERIFIED: codebase: `modules/mb-image/png/{encode_test.mbt,stream_encode.mbt}`]

**How to avoid:** Add direct `PngChunkEncoder::new` limit, work-budget, and capability cases to the four-target filtered test and compare each to the eager oracle. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `scripts/quality/Invoke-PngEncodeEvidence.ps1`]

## Code Examples

### Public output pull loop

```moonbit
// Source pattern: examples/qoi-portable/main/main.mbt and PngChunkEncoder::pull.
let output : Array[Byte] = []
while !finished {
  let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  // Assert written <= capacity and total == previous prefix + written.
  // Copy only [0, written), then accept NeedOutput or finish exactly once.
}
```

The QOI portable example already proves this caller-owned-lease pattern, while PNG exposes the analogous `PngChunkPullResult` API. [VERIFIED: codebase: `examples/qoi-portable/main/main.mbt`, `modules/mb-image/png/{png.mbt,stream_encode.mbt}`]

### Required four-target evidence invocation

```powershell
pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target js
pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target wasm
pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target wasm-gc
pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target native
pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png
```

The first four commands passed their current three-test filter during research; Phase 31's new specifically named test will join that filter without changing runner routing. [VERIFIED: local execution: all four `Invoke-PngEncodeEvidence.ps1` targets] [VERIFIED: codebase: `scripts/quality/Invoke-PngEncodeEvidence.ps1`]

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| Phase 28 public workflow: chunk decode → resize → eager PNG encode | Phase 31 target: chunk decode → resize → public `PngChunkEncoder` | The consumer proves both caller-buffered halves of the portable PNG workflow while keeping the same canonical output evidence. [VERIFIED: codebase: `.planning/milestones/v0.8-phases/28-portable-png-streaming-evidence/28-01-VERIFICATION.md`, `.planning/REQUIREMENTS.md`, `examples/png-portable/main/main.mbt`] |
| Phase 30 focused native contract test | Phase 31 four-target hostile schedule and preflight evidence | Behavioral conformance becomes explicit for js, wasm, wasm-gc, and native. [VERIFIED: codebase: `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`, `.planning/ROADMAP.md`] |

**Deprecated/outdated:** Treating the eager `PngEncoder` as the final public-workflow output path is outdated for the v0.9 evidence phase; retain it solely as an oracle. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The zero-prefixed Phase-28 ragged sequence is the best compact irregular output schedule. | Pattern 1 | Low: any deterministic schedule containing zero, one-byte, and varied capacities satisfies the requirement if it preserves the listed assertions. |
| A2 | Compare every nonempty observable `CoreError` field in public/eager preflight parity. | Pattern 2 | Low: the planner may select the project’s established error-equality helper instead, but must retain category/code/context and budget atomicity. |

## Open Questions

None blocking. The output schedule label and exact pull count are implementation details that should be frozen together in `main.mbt` and the PNG quality-lane expected line. [VERIFIED: codebase: `examples/png-portable/main/main.mbt`, `scripts/quality/Invoke-MoonQuality.ps1`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | package tests and public workflow | Yes | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` | MoonBit compilation | Yes | `v0.10.4+2cc641edf` | — [VERIFIED: local `moonc -v`] |
| `moonrun` | target execution | Yes | `0.1.20260713` | — [VERIFIED: local `moonrun --version`] |
| PowerShell | evidence/quality scripts | Yes | `7.6.3` | — [VERIFIED: local `$PSVersionTable.PSVersion`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local version checks]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V5 Input Validation | Yes | Exercise public constructor capability/limit/budget rejections and exact output capacity accounting on all four targets. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`, `.planning/REQUIREMENTS.md`] |
| V8 Data Protection | Yes | Terminal pulls must not mutate a later caller-owned mutable lease; only accepted bytes are copied from a callback-scoped lease. [VERIFIED: codebase: `modules/mb-image/png/{stream_encode.mbt,stream_encode_test.mbt}`] |
| V2/V3/V4/V6 | No | The portable codec has no authentication, session, access-control, or cryptographic secret function. [VERIFIED: codebase: `modules/mb-image/png/moon.pkg`] |

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Hostile tiny/empty destination capacities cause counter drift | Tampering / DoS | Exact per-pull and cumulative assertions under zero, one-byte, and ragged schedules. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`, `modules/mb-image/png/stream_encode_test.mbt`] |
| Stale terminal state writes to a new owner | Tampering / Information Disclosure | Fresh sentinel-owner checks after completion and typed failure. [VERIFIED: codebase: `.planning/phases/30-public-png-chunk-encoder/30-VERIFICATION.md`] |
| Constructor bypass changes resource admission | DoS | Public/eager preflight error and remaining-budget parity on all targets. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt,encode_test.mbt}`] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt,stream_encode_test.mbt,encode_test.mbt}` — public API, preflight, byte acknowledgement, and current native evidence.
- `examples/png-portable/main/main.mbt` and `examples/qoi-portable/main/main.mbt` — current public PNG flow and caller-owned output-loop precedent.
- `scripts/quality/{Invoke-PngEncodeEvidence,Invoke-MoonQuality}.ps1` — target isolation, lane ordering, and exact evidence gate.
- Phase 28/29/30 research, summaries, and verification reports — confirmed handoff boundaries and existing target proof.
- Local execution — all four current `Invoke-PngEncodeEvidence.ps1` targets passed; all four current `png-portable` runs produced the identical 78-byte/digest line.

### Secondary (MEDIUM confidence)

- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — supported-target expressions and `--target all` expansion. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]
- [MoonBit command help](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — documented target choices. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]

### Tertiary (LOW confidence)

- None beyond A1–A2, which are explicitly marked `[ASSUMED]`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all selected components are installed, current repository components; no external packages are added. [VERIFIED: local version checks; codebase: `modules/mb-image/png/moon.pkg`]
- Architecture: HIGH — the public encoder, example, runners, and Phase 30 boundary are directly inspected. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt,stream_encode.mbt}`, `examples/png-portable/main/main.mbt`, `scripts/quality/Invoke-MoonQuality.ps1`]
- Pitfalls: HIGH — each follows from current terminal/preflight implementation and previously verified phase evidence. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt,stream_encode.mbt,stream_encode_test.mbt}`, Phase 29/30 verification reports]

**Research date:** 2026-07-21  
**Valid until:** 2026-08-20, unless the MoonBit toolchain or portable-target policy changes.
