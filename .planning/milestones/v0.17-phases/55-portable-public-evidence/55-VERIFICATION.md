---
phase: 55-portable-public-evidence
verified: 2026-07-22T22:10:14Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 55: Portable Public Evidence Verification Report

**Phase Goal:** Library users have independent public proof that GrayAlpha16 PNG output is wire-faithful, caller-buffered-safe, legacy-compatible, and portable across every supported target.
**Verified:** 2026-07-22T22:10:14Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Public legal GrayAlpha16 samples `(1234,A7C5)/(BE0F,5A76)` prove literal Type-4/16 `Ghi,Glo,Ahi,Alo` order and straight-RGBA8 high-byte decoder canonicalization. | ✓ VERIFIED | `png_encode_graya16_image` constructs the legal little-endian backing as `34,12,C5,A7,0F,BE,76,5A` (`encode_test.mbt:182-211`). The public eager test invokes `PngEncoder::new_graya16_with_strategies(Stored, None)`, checks the PNG signature/IHDR (`depth=16`, `type=4`, non-interlaced), and independently asserts the complete filtered raster `00 12 34 A7 C5 BE 0F 5A 76` at `:1067-1085`. Its decoder helper uses `ImageDecoder::decode(PngDecoder::new(), ...)` and checks `U8/Rgba` `(12,12,12,A7)` and `(BE,BE,BE,5A)` at `:480-512`. The same helper runs for all six public eager strategy/filter pairs (`:1115-1154`). |
| 2 | Every compression/filter pair has independent zero-capacity, one-byte, and ragged caller-buffered evidence with eager identity, accepted-only totals, untouched lease tails, and sticky success terminals. | ✓ VERIFIED | `PNG GrayAlpha16 chunk public evidence` crosses Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive (`stream_encode_test.mbt:1294-1328`). For each pair it performs a direct zero-length lease check and independently drains fresh encoders under `[0,1]`, `[1]`, and `[0,8,4,1,13,2,5,3,21]`. The shared drain uses the public chunk factory; proves `total_written == accepted_prefix + written`; copies only written bytes; checks every unwritten and post-finish sentinel byte remains `Z`; compares output with a fresh public eager oracle; then verifies a later seven-byte lease reports `0`, unchanged total, and sticky `Finished` (`:710-834`). |
| 3 | Literal Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 compatibility PNG vectors remain frozen in eager and caller-buffered tests, and the same package suite passes on all four portable targets. | ✓ VERIFIED | The eager frozen-vector test has complete literal Stored/None PNG values for all five formats and compares the relevant public eager factory outputs (`encode_test.mbt:874-978`). The chunk counterpart uses the same five literal values and caller-buffered drains (`stream_encode_test.mbt:1371-1486`). The package declares `+js+wasm+wasm-gc+native` in `modules/mb-image/moon.mod.json`. Direct rerun was deliberately skipped because an already-running `moon` process (PID 289128) holds the build lock; the recorded Phase-55 all-target invocation `moon -C modules/mb-image test png --target all --frozen` completed 204/204 tests on wasm, wasm-gc, js, and native. This is accepted execution evidence per the verification handoff. |
| 4 | The existing strict descriptor-boundary rejection of Big-endian GrayAlpha16 remains covered; public evidence creates only legal little-endian GrayAlpha16 sources. | ✓ VERIFIED | The public test directly constructs a U16/Packed/Big GrayAlpha descriptor and requires `Err` before PNG admission (`encode_test.mbt:1087-1111`). The two Phase-55 test commits add only the legal little-endian fixture; the source image helper explicitly uses `ImageFormat::graya16()` and writes only its four legal little-endian component bytes (`:182-211`). |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode_test.mbt` | Public GrayAlpha16 Stored/None wire vector, decoder canonicalization, six-pair eager semantics, and literal eager compatibility vectors. | ✓ VERIFIED | Exists and is substantive (1,300+ lines); `verify.artifacts` reports no issues. It uses only public encoder/decoder seams and literal byte assertions, not a derived encoder oracle for the Type-4/16 raster or frozen vectors. |
| `modules/mb-image/png/stream_encode_test.mbt` | GrayAlpha16 hostile drains/matrix, accepted-prefix lease ownership and sticky terminal checks, and literal chunk vectors. | ✓ VERIFIED | Exists and is substantive (3,000+ lines); `verify.artifacts` reports no issues. Fresh public chunk encoders, caller-owned mutable leases, and an independent eager output are exercised for every schedule. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PngEncoder::new_graya16_with_strategies` | `PngDecoder::new` | Generated Stored/None public bytes are inspected at the raster boundary, then decoded through `ImageDecoder::decode`. | ✓ WIRED | The eager test calls the public factory, asserts literal bytes from its generated PNG, then passes those exact bytes to `png_encode_graya16_public_decode_is_canonical`, which calls the public decoder. |
| `PngChunkEncoder::new_graya16_with_strategies` | `PngEncoder::new_graya16_with_strategies` | Each fresh zero, one-byte, and ragged chunk run equals a fresh eager oracle for the same pair. | ✓ WIRED | The matrix calls the public eager helper and the public chunk factory with identical image/strategy/filter values; the drain compares every completed chunk output with that eager byte sequence. |

`verify.key-links` reports both links as unresolved only because its schema requires `from` to be a relative file path; the Plan uses component symbols. Manual source tracing above verifies both executable links.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `encode_test.mbt` | Type-4/16 raster and decoded pixels | Mutable legal U16 `OwnedImage` backing → public eager encoder → PNG bytes → public decoder | Four non-symmetric gray/alpha source lanes flow into explicit raster assertions and decoded RGBA8 high-byte assertions. | ✓ FLOWING |
| `stream_encode_test.mbt` | Caller-buffered output/progress | Fresh public chunk encoder → caller leases → accepted output array; separate public eager encoder | The output compares actual generated bytes; totals and untouched mutable-lease tails are checked per pull, not hard-coded. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Complete public PNG evidence across portable targets | `moon -C modules/mb-image test png --target all --frozen` | Recorded independently during Phase 55: 204 passed, 0 failed on wasm, wasm-gc, js, and native. A concurrent `moon` PID 289128 held the build lock during this verification, so no competing rerun was started. | ✓ PASS (recorded execution evidence) |
| GrayAlpha16 eager wire/decode and chunk ownership behavior | Named tests in the same package: `PNG GrayAlpha16 public eager wire and decode fidelity`; `PNG GrayAlpha16 chunk public evidence` | Both are included by the recorded all-target 204/204 run; direct named rerun is blocked by the same build lock. | ✓ PASS (recorded execution evidence) |

### Probe Execution

Step 7c: **SKIPPED** — Phase 55 contains no declared probe, and no `scripts/**/tests/probe-*.sh` file was discovered.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| GRAYA16-04 | `55-01-PLAN.md` | Generated GrayAlpha16 PNGs prove literal U16 wire fidelity and RGBA8 high-byte canonicalization; hostile capacities retain parity/progress/tails/sticky terminals; frozen legacy vectors and all-target evidence remain stable. | ✓ SATISFIED | Truths 1–4 directly cover each requirement clause. `REQUIREMENTS.md` maps GRAYA16-04 exclusively to Phase 55, and that sole requirement is declared by the plan: no orphaned Phase-55 requirement exists. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, TODO/HACK/placeholder marker, empty implementation, hard-coded empty output, target-specific branch, FFI, or native-only path in either Phase-55 test artifact. `git diff --check 39dd3ff..HEAD` is clean. | ℹ️ Info | No stub, debt-marker, or portability blocker found. |

### Disconfirmation Checks

- **Wire evidence that only checks symmetric bytes:** falsified. All four bytes of each source pair differ; a swapped lane, swapped component, or little-endian PNG mistake breaks the literal raster assertion.
- **Parity test that hides rejected writes or terminal mutation:** falsified. The drain increments the asserted prefix only from `written`, checks cumulative totals before copying, checks all unaccepted and terminal lease bytes, and probes a later terminal call.
- **Frozen-vector claim without a GrayAlpha8 baseline:** falsified. Complete GrayAlpha8 literals are present in both eager and caller-buffered vector tests alongside Gray8, Gray16, RGB8, and RGBA8.
- **Uncovered error path:** the Phase-55 goal is a success-evidence phase; expected negative descriptor admission remains directly asserted by the Big-endian rejection test. Phase 54 already owns and tests resource/admission failure atomicity. No required Phase-55 error path is untested.

### Gaps Summary

No gaps found. The codebase contains all public evidence required by GRAYA16-04, and the recorded all-target suite provides behavioral execution evidence without disrupting the active build process.

---

_Verified: 2026-07-22T22:10:14Z_
_Verifier: the agent (gsd-verifier)_
