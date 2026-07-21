# Phase 28: Portable PNG Streaming Evidence - Research

**Researched:** 2026-07-21
**Domain:** Portable MoonBit PNG chunk-decoding conformance and public workflow evidence
**Confidence:** HIGH

## User Constraints

- Follow the established GSD sequence and choose the strongest compatible option without a user decision. [VERIFIED: orchestrator task]
- Keep this milestone focused on functional code and tests; do not expand release, registry, credential, or publication automation. [VERIFIED: `.planning/REQUIREMENTS.md`, `.planning/STATE.md`]
- Phase 28 owns evidence over the stable public `PngChunkDecoder`; it does not add a public streaming encoder. [VERIFIED: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PNGS-04 | Maintainers run adversarial split schedules and one public PNG chunk-decode workflow unchanged on js, wasm, wasm-gc, and native. | Use the existing generated decode corpus, add a public all-record schedule harness for accepted and rejected records, and convert the one existing PNG public executable to chunk-decode → bilinear-resize → eager-encode. [VERIFIED: `.planning/ROADMAP.md`, `modules/mb-image/png/stream_decode_test.mbt`, `examples/png-portable/main/main.mbt`] |

## Summary

Phase 27 already supplies the correct product boundary: `PngChunkDecoder::push` consumes caller-owned `ByteView` values synchronously, returns a byte count plus `NeedInput`/`Failed`, and only `finish()` can move a `DecodeResult` out of the private machine. The generated corpus is current and exercises 3,850 decode cases, while its source generator includes accepted stored/fixed/dynamic, split-IDAT, filtered, colour, Adam7, malformed, resource, and hostile-DEFLATE cases. [VERIFIED: `.planning/phases/27-public-png-chunk-decoder/27-03-VERIFICATION.md`, `modules/mb-image/png/{png,stream_decode,stream_decode_test}.mbt`, `scripts/fixtures/Generate-PngDecodeVectors.ps1`]

The right Phase 28 implementation is deliberately small: extend the existing public PNG stream tests rather than creating a second decoder, reuse the existing `examples/png-portable` workspace member rather than adding an example, and retain the eager `PngEncoder`. The one-byte public harness proves every byte boundary; a second named mixed schedule catches errors in turn accounting and chunk aggregation. The example should feed its existing 75-byte source through `PngChunkDecoder`, perform the established bilinear resize, then use the existing eager encoder and freeze one four-target line. [VERIFIED: `modules/mb-image/png/stream_decode_test.mbt`, `examples/png-portable/main/main.mbt`, `.planning/quick/260721-j94-extend-the-portable-png-public-workflow-/260721-j94-SUMMARY.md`]

**Primary recommendation:** Add one black-box generated-corpus public schedule harness and one in-place `png-portable` chunk-decode workflow; add only the existing PNG quality lane's exact evidence line check, without new source packages, FFI, streaming output, or release work.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Hostile chunk conformance | Portable package tests | Generated-fixture generator | The public test package owns observable `push`/`finish` behavior; the generator remains the source of corpus bytes and freshness checking. [VERIFIED: `modules/mb-image/png/{stream_decode_test,generated_decode_vectors_test}.mbt`, `scripts/fixtures/Generate-PngDecodeVectors.ps1`] |
| Boundary-state selection | Public one-byte schedule | Existing white-box classifier tests | One-byte delivery proves every public byte boundary; private tests remain the right place to prove retained DEFLATE phase identity. [VERIFIED: `modules/mb-image/png/{stream_decode_test,stream_decode_wbtest}.mbt`] |
| Public workflow | `examples/png-portable` executable | Existing PNG eager encoder and resize operation | The executable already has portable dependencies, a fixed source/output, and exact evidence. [VERIFIED: `examples/png-portable/main/{main.mbt,moon.pkg}`, `modules/mb-image/png/encode.mbt`] |
| Four-target evidence | PNG quality lane plus direct MoonBit commands | README documentation | `moon run` takes one target at a time, while package tests support `--target all`. [VERIFIED: `.planning/phases/22-canonical-png-encode-and-portable-evidence/22-01-SUMMARY.md`, `scripts/quality/Invoke-MoonQuality.ps1`] |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why standard |
|---|---:|---|---|
| Existing `tchivs/mb-image/png` | repository-local | Public `PngChunkDecoder`, eager `PngEncoder`, generated PNG vectors | It contains the only supported portable PNG surface and all four targets. [VERIFIED: `modules/mb-image/png/{moon.pkg,png.mbt,stream_decode.mbt}`] |
| `moon` | `0.1.20260713` | Run package tests and each executable target | Installed toolchain supports js, wasm, wasm-gc, and native. [VERIFIED: local `moon --version`, `modules/mb-image/png/moon.pkg`] |
| PowerShell | `7.6.3` | Generated-vector freshness and isolated PNG quality lane | These are the repository's existing deterministic evidence entry points. [VERIFIED: local `$PSVersionTable.PSVersion`, `scripts/{fixtures/Generate-PngDecodeVectors,quality/Invoke-MoonQuality}.ps1`] |

### Supporting

| Component | Purpose | When to use |
|---|---|---|
| `@ops.resize_bilinear` | Existing deterministic public image operation | The single PNG consumer must show real chunk decode → operation → eager encode, not a no-op transport demo. [VERIFIED: `examples/png-portable/main/main.mbt`, `.planning/quick/260721-j94-extend-the-portable-png-public-workflow-/260721-j94-SUMMARY.md`] |
| `Generate-PngDecodeVectors.ps1 -Check` | Corpus freshness/provenance check | Before every phase gate and after any fixture/generator change. [VERIFIED: `scripts/fixtures/Generate-PngDecodeVectors.ps1`, `scripts/quality/Invoke-MoonQuality.ps1`] |

**Installation:** None. This phase adds no external package or tool. [VERIFIED: `modules/mb-image/png/moon.pkg`, `.planning/REQUIREMENTS.md`]

## Architecture Patterns

### System Architecture Diagram

```text
generated PNG corpus ──> public schedule test ──> PngChunkDecoder.push(ByteView)
                                      │                  │
                                      │                  ├── NeedInput / exact accepted count
                                      │                  ├── sticky typed failure
                                      │                  └── finish() -> DecodeResult
                                      │                                  │
                                      └── eager PngDecoder oracle <──────┘

fixed png-portable bytes ──> PngChunkDecoder ──> resize_bilinear ──> eager PngEncoder
                                                                      │
                                              exact bytes + digest + one status line ──> four targets
```

### Recommended Project Structure

```text
modules/mb-image/png/
  stream_decode_test.mbt   # public schedule and result/terminal assertions
examples/png-portable/main/
  main.mbt                 # sole public chunk-decode → operation → eager-encode workflow
scripts/quality/
  Invoke-MoonQuality.ps1   # existing PNG-lane exact four-target line gate
modules/mb-image/
  README.mbt.md            # public workflow documentation
```

### Pattern 1: Exhaustive one-byte oracle plus mixed packet schedule

**What:** Run every generated record twice through the public API: first an empty push followed by every source byte as a one-byte view; then a deterministic, nonuniform packet schedule. Compare the final result or first terminal error to an independently initialized eager decode. [VERIFIED: `modules/mb-image/png/stream_decode_test.mbt`, `.planning/phases/27-public-png-chunk-decoder/27-03-VERIFICATION.md`]

**When to use:** For every accepted and rejected record in the existing `_generated_png_decode_cases()` corpus. The one-byte lane is the authoritative all-boundary proof; the mixed lane verifies that accounting is not accidentally tied to one-byte calls. [VERIFIED: `modules/mb-image/png/stream_decode_test.mbt`, `scripts/fixtures/Generate-PngDecodeVectors.ps1`]

**Exact schedule suite:**

| Schedule | Input turns | Required assertions |
|---|---|---|
| `empty-then-one-byte` | `0`, then one byte until source exhaustion or first failure | Every active byte is consumed as `1`; empty push is `NeedInput`/0; accepted records remain `NeedInput` until `finish`; rejected records stop at their first typed failure and later input consumes 0. This covers signature, framing, IDAT payload/CRC, DEFLATE, filters, IEND, and every EOF prefix. [VERIFIED: `modules/mb-image/png/stream_decode_test.mbt`, `scripts/fixtures/Generate-PngDecodeVectors.ps1`] |
| `ragged-public-packets` | cycle `[8, 4, 1, 13, 2, 5, 3, 21]`, clipping final turn | Each active push reports the actual admitted prefix, never exposes an image, and is followed by the same finish/sticky comparison. This catches aggregate-call accounting without duplicating parser tests. [ASSUMED: recommended fixed test schedule] |
| `workflow-zero-signature-ihdr-idat-deflate-iend` | `[0, 8, 4, 4, 13, 4, 4, 4, 1, 2, 4, 11, 4, 4, 4, 4]` for the existing 75-byte example | The sum is 75; it separates signature, IHDR framing, IDAT header, zlib header/stored-DEFLATE portions, IDAT CRC, IEND header, and IEND CRC. Every push remains `NeedInput`; `finish` alone transfers the image. [VERIFIED: `examples/png-portable/main/main.mbt`; arithmetic is implementation guidance] |

### Pattern 2: Existing example in place, eager output deliberately retained

Use the existing `examples/png-portable/main` executable; replace only its Reader/eager decode step with `PngChunkDecoder`. Preserve its 2×1 source, 3×1 bilinear output, eager `PngEncoder`, 78-byte canonical bytes, and digest `626208771`. Update its line to identify the named input schedule, push count, `bytes_read=75`, existing resize fields, `bytes_written=78`, and digest. [VERIFIED: `examples/png-portable/main/main.mbt`, `.planning/quick/260721-j94-extend-the-portable-png-public-workflow-/260721-j94-SUMMARY.md`]

### Anti-Patterns to Avoid

- **A second PNG parser or a buffered eager decoder:** test only the published `PngChunkDecoder`; parsing remains in the verified private machine. [VERIFIED: `.planning/phases/27-public-png-chunk-decoder/27-03-VERIFICATION.md`]
- **A public PNG streaming encoder:** the workflow must explicitly use the existing eager `PngEncoder`; public resumable encoding is future scope. [VERIFIED: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`]
- **A second public example/workspace:** modify `png-portable` in place, as the QOI evidence phase did. [VERIFIED: `.planning/milestones/v0.5-phases/19-portable-streaming-qoi-evidence/19-01-SUMMARY.md`]
- **Release/registry qualification reuse:** extend only the scoped `Png` lane stage and its existing isolation sequence; do not invoke broader release or registry routes. [VERIFIED: `scripts/quality/Invoke-MoonQuality.ps1`, `.planning/REQUIREMENTS.md`]

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| PNG test data | New hand-authored binary fixture set | Existing generated 3,850-case decode corpus | It already derives accepted/rejected, split-IDAT, DEFLATE, colour, raster, and limit cases and has a freshness check. [VERIFIED: `scripts/fixtures/Generate-PngDecodeVectors.ps1`, `.planning/phases/27-public-png-chunk-decoder/27-03-VERIFICATION.md`] |
| Chunk decoder | Test-only parser or source accumulator | Existing public `PngChunkDecoder` | It is the actual API under evidence, with exact consumption and finish-only ownership. [VERIFIED: `modules/mb-image/png/{png,stream_decode}.mbt`] |
| Output streaming | New `PngStreamEncoder` | Existing eager `PngEncoder` | Phase scope explicitly excludes public streaming encoding. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Cross-target runner | New runner/framework | Existing MoonBit command plus scoped Png quality lane | Both are already authoritative and deterministic. [VERIFIED: `scripts/quality/Invoke-MoonQuality.ps1`] |

## Common Pitfalls

### Pitfall 1: Treating accepted-only one-byte coverage as PNGS-04 completion

**What goes wrong:** The current public one-byte test covers accepted generated profiles, while rejected records may be delivered as one whole view. That does not prove first-failure consumption or sticky terminal behavior at every rejected prefix. [VERIFIED: `modules/mb-image/png/stream_decode_test.mbt`]

**How to avoid:** Run the same public byte-by-byte scheduler over rejected records; stop at the first `Failed`, assert typed equality with an eager oracle, assert exact consumed prefix and zero-consumption replay, then assert `finish()` returns the identical error. [VERIFIED: `.planning/phases/27-public-png-chunk-decoder/27-03-VERIFICATION.md`; exact all-record extension is implementation guidance]

### Pitfall 2: Calling `finish()` at IEND rather than after the scheduled source

**What goes wrong:** Early completion could hide trailing-input behavior. [VERIFIED: `modules/mb-image/png/stream_decode.mbt`]

**How to avoid:** Deliver the schedule through all source bytes (or its first terminal error) and call `finish()` once; accepted records must be `NeedInput` after IEND CRC, not successful before finish. [VERIFIED: `modules/mb-image/png/stream_decode_test.mbt`, `.planning/phases/27-public-png-chunk-decoder/27-03-VERIFICATION.md`]

### Pitfall 3: Duplicating Phase 27 private DEFLATE proof in a public-only phase

**What goes wrong:** A test may label ordinary chunk splits as dynamic/fixed tree coverage without proving the retained phase. [VERIFIED: `.planning/phases/27-public-png-chunk-decoder/27-03-VERIFICATION.md`]

**How to avoid:** Retain the existing white-box literal phase vectors as the DEFLATE-state proof; Phase 28's all-record one-byte public delivery proves the public contract over those bytes. [VERIFIED: `modules/mb-image/png/stream_decode_wbtest.mbt`, `.planning/phases/27-public-png-chunk-decoder/27-03-SUMMARY.md`]

### Pitfall 4: Adding a broad quality controller

**What goes wrong:** Public example verification can accidentally enter qualification/release/registry work, violating milestone scope. [VERIFIED: `.planning/REQUIREMENTS.md`, `scripts/quality/Invoke-MoonQuality.ps1`]

**How to avoid:** Add a single PNG public-workflow stage to `Invoke-PngQualityLane` and update only its exact stage trace. The lane already isolates Png policy, corpus checks, four-target tests, and portable workflow execution. [VERIFIED: `scripts/quality/Invoke-MoonQuality.ps1`]

## Code Examples

### Public schedule loop

```moonbit
let decoder = @png.PngChunkDecoder::new(limits, budget, diagnostics)
for turn in schedule {
  let chunk = source.view().subview(cursor, turn).unwrap()
  let pushed = decoder.push(chunk)
  // Assert exact consumed count and NeedInput/first sticky failure.
  cursor = cursor + pushed.consumed()
}
let result = decoder.finish().unwrap()
```

The public API returns `PngChunkPushResult` from `push` and transfers `@codec.DecodeResult` only from `finish`. [VERIFIED: `modules/mb-image/png/png.mbt`, `modules/mb-image/png/stream_decode.mbt`]

### Required phase gate

```powershell
pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check
moon -C modules/mb-image test png --target all --frozen
moon -C examples/png-portable run main --target js --frozen
moon -C examples/png-portable run main --target wasm --frozen
moon -C examples/png-portable run main --target wasm-gc --frozen
moon -C examples/png-portable run main --target native --frozen
pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png
```

The package command supports all targets; executable runs are per target. [VERIFIED: `.planning/phases/22-canonical-png-encode-and-portable-evidence/22-01-SUMMARY.md`, `scripts/quality/Invoke-MoonQuality.ps1`]

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | `[8,4,1,13,2,5,3,21]` is the best compact mixed public packet schedule. | Exact schedule suite | It could miss a desirable aggregate boundary; one-byte coverage remains complete, so only supplementary coverage changes. |
| A2 | The existing four-target PNG quality lane is the minimal suitable location for the public workflow status-line gate. | Pattern 2 / Pitfall 4 | The planner may find a more scoped existing entry point; it must retain the same no-release isolation. |

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | package tests and public runs | Yes | `0.1.20260713` | — |
| `moonc` | MoonBit compilation | Yes | `v0.10.4+2cc641edf` | — |
| `moonrun` | portable runtime execution | Yes | `0.1.20260713` | — |
| `pwsh` | fixture and quality commands | Yes | `7.6.3` | — |

All availability values are [VERIFIED: local version commands]. No external dependency or package installation is needed.

## Validation Architecture

| Property | Value |
|---|---|
| Framework | MoonBit black-box `*_test.mbt`, private continuation `*_wbtest.mbt`, generated fixture freshness, and an existing scoped quality lane. [VERIFIED: `modules/mb-image/png`, `scripts/quality/Invoke-MoonQuality.ps1`] |
| Quick run | `moon -C modules/mb-image test png --target native --frozen` |
| Full suite | `moon -C modules/mb-image test png --target all --frozen` |

| Req ID | Behavior | Test type | Automated command |
|---|---|---|---|
| PNGS-04 | Every generated accepted/rejected record is checked under empty + one-byte and ragged public schedules for exact per-call progress, finish result/error, and sticky terminal behavior. | black-box package test | `moon -C modules/mb-image test png --target all --frozen` |
| PNGS-04 | Fixed source is chunk-decoded, bilinear-resized, eagerly encoded, and has exact bytes/digest/status output on four targets. | public executable | four individual `moon -C examples/png-portable run main --target … --frozen` commands |
| PNGS-04 | Corpus is current and the scoped PNG lane executes the exact portable line without broad release work. | generator + integration | `Generate-PngDecodeVectors.ps1 -Check`; `Invoke-MoonQuality.ps1 -Lane Png` |

**Wave 0 gaps:** None. Existing public test, example, generator, and Png quality lane are the intended artifacts; Phase 28 extends them in place. [VERIFIED: `modules/mb-image/png/stream_decode_test.mbt`, `examples/png-portable/main/main.mbt`, `scripts/quality/Invoke-MoonQuality.ps1`]

## Security Domain

| ASVS category | Applies | Standard control |
|---|---|---|
| V5 Input Validation | Yes | All-byte public scheduling over generated hostile inputs, typed terminal comparison, and existing CRC/zlib/raster/limit checks. [VERIFIED: `modules/mb-image/png/{stream_decode,stream_decode_test,stream_decode_wbtest}.mbt`] |
| V8 Data Protection | Yes | `push` never exposes an image; `finish` transfers only after strict terminal validation. [VERIFIED: `modules/mb-image/png/stream_decode.mbt`] |
| V2/V3/V4/V6 | No | This portable codec has no authentication, sessions, access control, or cryptographic security function; PNG CRC/Adler are data-integrity format checks. [VERIFIED: `modules/mb-image/png/moon.pkg`, `.planning/phases/27-public-png-chunk-decoder/27-RESEARCH.md`] |

| Pattern | STRIDE | Mitigation |
|---|---|---|
| Fragmented malformed input hides a parser/accounting error | Tampering / DoS | Every rejected generated record runs under public per-byte and mixed schedule delivery; first error is compared and replayed. [ASSUMED: Phase 28 test prescription] |
| Result leaks before final EOF | Information disclosure | Assert no result from `push`, `NeedInput` through full IEND, and completion only after `finish`. [VERIFIED: `modules/mb-image/png/{png,stream_decode,stream_decode_test}.mbt`] |
| Quality proof widens into release infrastructure | Elevation of privilege | Keep the existing Png lane's scoped stage trace and forbid release/registry additions. [VERIFIED: `scripts/quality/Invoke-MoonQuality.ps1`, `.planning/REQUIREMENTS.md`] |

## Project Constraints (from AGENTS.md)

- Keep the algorithm and evidence in MoonBit; provide conformance evidence on js, wasm, wasm-gc, and native. [VERIFIED: `AGENTS.md`, `modules/mb-image/png/moon.pkg`]
- Do not introduce FFI or a foreign codec stack. [VERIFIED: `AGENTS.md`, `.planning/REQUIREMENTS.md`]
- Preserve modular public dependencies and stable documented public API behavior. [VERIFIED: `AGENTS.md`, `modules/mb-image/png/moon.pkg`]
- Use black-box tests for public behavior, white-box tests for internal invariants, and semantic binary assertions rather than opaque snapshots. [VERIFIED: `AGENTS.md`, `modules/mb-image/png/{stream_decode_test,stream_decode_wbtest}.mbt`]
- Repository graph tools are not exposed in this agent runtime; code inspection used the documented fallback. [VERIFIED: agent tool availability, `AGENTS.md`]

## Open Questions

None blocking. The planner should use the named schedules above and keep any further schedule metadata inside tests unless an implementation constraint demonstrably requires generator schema expansion.

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/{png,stream_decode,stream_decode_test,stream_decode_wbtest}.mbt` — public contract, current schedule coverage, private-state evidence, and terminal behavior.
- `scripts/fixtures/Generate-PngDecodeVectors.ps1` — generated corpus coverage and freshness command.
- `examples/png-portable/main/{main.mbt,moon.pkg}` — existing fixed public workflow and its portable dependency boundary.
- `scripts/quality/Invoke-MoonQuality.ps1` — isolated Png lane and current exact output stage.
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and Phase 27 final verification — binding PNGS-04 scope and completed public API boundary.

### Secondary (MEDIUM confidence)

- `.planning/milestones/v0.5-phases/19-portable-streaming-qoi-evidence/19-01-{PLAN,SUMMARY}.md` — established in-place public streaming-evidence pattern.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new dependency and all required tools are locally available.
- Architecture: HIGH — built directly on verified Phase 27 public behavior and existing example/quality paths.
- Pitfalls: HIGH — gaps are visible in current accepted-only versus corpus-wide schedule tests; supplementary packet choice is explicitly assumed.

**Research date:** 2026-07-21
**Valid until:** Phase 28 implementation begins; refresh if the PNG public API or generated corpus schema changes first.
