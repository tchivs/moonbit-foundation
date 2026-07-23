# v0.26 Test Research: Indexed8 Adam7 PNG Encode

**Researched:** 2026-07-24
**Scope:** minimum independent four-target qualification for a new explicit Type-3/8 Indexed8 Adam7 eager and caller-buffered encode route
**Confidence:** HIGH for repository seams and test anchors; MEDIUM for the proposed public entry spelling

## Recommendation

Qualify one explicit, fixed Indexed8 Adam7 profile: Type-3, bit depth 8, `PngInterlaceStrategy::Adam7`, Stored DEFLATE, filter None, RGB PLTE, and the existing canonical optional `tRNS`. Use a 5×5 immutable `PngIndexedImage` whose seven Adam7 passes are all nonempty, and test the eager and chunk bytes against one hand-derived raw pass-raster oracle. This is the smallest evidence set that detects interlace-flag, pass-coordinate, palette/transparency framing, acknowledgement, and public-decode regressions without extending the milestone to selected low-bit Indexed1/2/4 Adam7 or strategy families. [VERIFIED: codebase inspection and v0.25 requirements]

The current Indexed machine cannot yet pass this test: `PngEncodeMachine::new_with_indexed_profile` fixes `interlace_strategy: None`, and indexed preflight computes only ordinary rows. The existing generic Adam7 cursor also receives `ImageView`, whereas Indexed8 pixels live in immutable `PngIndexedImage`. Treat the proposed tests as the red specification for a narrow shared-machine extension, not as evidence that the functionality is already present. [VERIFIED: codebase inspection]

**Primary recommendation:** add one focused test fixture and three test groups—independent eager wire/decode, chunk lifecycle parity, and preflight/compatibility boundaries—while retaining every non-interlaced Indexed8 and low-bit vector unchanged. [VERIFIED: codebase inspection]

## Scope Boundary

### In scope

- Explicit Indexed8 Adam7 output only: bit depth 8, colour type 3, Stored, filter None, existing PLTE and canonical optional `tRNS`. [VERIFIED: requested scope]
- Eager and caller-buffered public routes sharing one bounded machine. [VERIFIED: requested scope]
- Independent IHDR/chunk/CRC/raw-pass assertions, public generic decode, hostile lease schedules, atomic construction/preflight, diagnostics pass-through checks where observable, byte freezes, and the ordinary four-target package run. [VERIFIED: requested scope]

### Explicitly out of scope

- Indexed1/2/4 Adam7, including packed indexed pass traversal. `INDEXADAM7` was deferred until such a bounded traversal contract exists; v0.25 shipped only non-interlaced selected-depth Indexed output. [VERIFIED: v0.25-REQUIREMENTS.md and v0.25-MILESTONE-AUDIT.md]
- Compression/filter strategy selection, quantization, generic image-model changes, staging buffers, FFI, target wrappers, copied source trees, and release automation. [VERIFIED: v0.25-REQUIREMENTS.md]

## Historical Contracts to Preserve

| History | Contract to retain | Test consequence |
|---|---|---|
| Phase 77 | `PngIndexedImage` owns index/RGB/alpha data; opaque palettes omit `tRNS`, while a partial-alpha table emits through its last non-opaque entry; PLTE/tRNS CRC state advances only on acknowledgement. [VERIFIED: 77-01-SUMMARY.md and 77-VERIFICATION.md] | The Adam7 transparent fixture must assert `IHDR -> PLTE -> tRNS -> IDAT -> IEND`, independent CRCs, exact `tRNS` bytes, and public RGBA8 alpha. |
| Phase 78 | `new_indexed8` is a direct shared-machine adapter; zero/one/ragged leases, split/released leases, atomic admission, and sticky terminals are established public behavior. [VERIFIED: 78-01-SUMMARY.md and 78-VERIFICATION.md] | New chunk tests must exercise the same hostile schedules and later-lease sentinels against Adam7 output. |
| Phase 79 | Indexed1/2/4 packed rows are non-interlaced, fixed Stored/None, with independent wire tests; fixed-Eight wrappers preserve Indexed8 compatibility. [VERIFIED: 79-01-SUMMARY.md and 79-VERIFICATION.md] | Do not reuse the packed low-bit helpers for Indexed8 Adam7; retain their vectors as compatibility coverage. |
| Phase 80 | Selected-depth chunk tests compare lease bytes to public eager output; their independent Type-3 wire/decode tests remain in `encode_test.mbt`. [VERIFIED: 80-01-SUMMARY.md and 80-VERIFICATION.md] | Follow that split: raw wire/decode in `encode_test.mbt`, lifecycle/leases in `stream_encode_test.mbt`. |

## Existing Seams and Gaps

| Seam | Current behavior | v0.26 test implication |
|---|---|---|
| `PngIndexedImage` | Immutable owned source supplies `index_at`, `palette_byte_at`, and `alpha_at`; source validation already happens before the sole owned allocation. [VERIFIED: codebase inspection] | Use a 5×5 source built in tests; no model fixture or mutable image is needed. |
| Indexed preflight | `_png_encode_indexed_preflight_with_profile` derives depth, PLTE cap, ordinary row bytes, canonical `tRNS`, frame facts, limits, and one work charge. [VERIFIED: codebase inspection] | Add an Adam7-specific preflight assertion for pass-derived scanline/IDAT/frame/work facts and exact-vs-one-less admission. |
| Indexed machine | `new_with_indexed_profile` stores the immutable source but fixes `PngInterlaceStrategy::None`. [VERIFIED: codebase inspection] | A focused Adam7 factory/preflight test must fail before implementation and assert IHDR interlace byte `1` after it. |
| Adam7 geometry | Existing generic encoder uses `_png_adam7_passes` and pass-local cursor logic; the public decoder already expands indexed Adam7 rows using the same geometry. [VERIFIED: codebase inspection] | Reuse geometry only as production behavior; hand-derive the expected 5×5 indexed pass bytes in tests. |
| Acknowledged transport | `PngChunkEncoder::pull` writes a leased byte, then calls `acknowledge`; completed/failed states return zero-write sticky outcomes. [VERIFIED: codebase inspection] | Reuse the Indexed8 hostile-drain/released-lease templates without a new transport harness. |
| Diagnostics | Indexed eager/chunk construction accepts `@error.Diagnostics`, but the inspected indexed machine receives it as `_diagnostics`; no existing Indexed test asserts a public diagnostics snapshot or event. [VERIFIED: codebase search] | Preserve the same diagnostics object through both eager/chunk rejection calls and assert the typed error context. Add a non-mutation assertion only if the diagnostics API exposes a stable public observation; do not add a test-only hook. [ASSUMED] |

## Canonical 5×5 Test Fixture

Use a partial-alpha four-entry palette and a coordinate-distinct, canonical unpacked index raster. It forces PLTE, a three-byte canonical `tRNS`, every Adam7 pass, and every public palette-alpha outcome. The fixture is deliberately local to encoder qualification, rather than a generated source tree or production helper. [VERIFIED: codebase inspection]

```text
palette entries (RGB / alpha):
  0 = 12 34 56 / 00
  1 = A0 B0 C0 / FF
  2 = 11 22 33 / 80
  3 = 44 55 66 / FF

indices by row:
  0 1 2 3 1
  2 3 1 0 2
  1 0 3 2 1
  3 2 0 1 3
  2 1 3 0 2
```

The fixture uses four palette entries, so canonical `tRNS` is exactly `00 FF 80`; it remains Type-3/8 and carries no low-bit packing obligation. [VERIFIED: phase 77 canonical tRNS contract; fixture values are proposed]

### Independent Stored/None Adam7 raw-raster oracle

For the fixture above, write the expected decompressed scanline payload directly in the test, one `00` filter byte for every nonempty Adam7 pass row. The coordinate order below is the independent oracle; do not call encoder helpers, `_png_adam7_passes`, a production cursor, or a second encoder to derive it. [ASSUMED]

| Adam7 pass | Coordinates in emitted row order | Raw scanline bytes |
|---:|---|---|
| 1 | `(0,0)` | `00 00` |
| 2 | `(4,0)` | `00 01` |
| 3 | `(0,4) (4,4)` | `00 02 02` |
| 4 | `(2,0)`; `(2,4)` | `00 02 00 03` |
| 5 | `(0,2) (2,2) (4,2)` | `00 01 03 01` |
| 6 | `(1,0) (3,0)`; `(1,2) (3,2)`; `(1,4) (3,4)` | `00 01 03 00 00 02 00 01 00` |
| 7 | `(0..4,1)`; `(0..4,3)` | `00 02 03 01 00 02 00 03 02 00 01 03` |

The concatenated raw payload is 36 bytes: 25 index bytes plus 11 filter bytes. Stored DEFLATE therefore has one 47-byte IDAT payload (`2` zlib header + `5` Stored header + `36` raw bytes + `4` Adler-32); with 4-entry PLTE and three-byte tRNS, the complete PNG is 143 bytes. These are independently derived proposed expected values and must be checked once against the implementation only through test assertions. [ASSUMED]

## Minimum Qualification Matrix

| Behavior | Minimal assertion | Existing anchor to reuse | Suggested file |
|---|---|---|---|
| IHDR profile | Assert width/height `5x5`, depth `08`, colour type `03`, compression/filter `00/00`, and interlace `01`; assert non-interlaced existing Indexed8 remains `00`. [VERIFIED: codebase inspection] | Indexed wire assertions; GrayAlpha8/RGBA16 Adam7 framing assertions. [VERIFIED: codebase inspection] | `encode_test.mbt` |
| Seven-pass sequence | Parse Stored IDAT to raw bytes and compare exactly with the 36-byte independent table above; this proves all seven passes and all pass-row filter bytes. [ASSUMED] | `png_encode_public_stored_scanlines` Adam7 tests show the established raw-raster pattern. [VERIFIED: codebase inspection] | `encode_test.mbt` |
| PLTE/tRNS and CRC | Independently parse all chunks; assert PLTE 12 bytes, `tRNS` 3 bytes, chunk order, and CRC-32 for IHDR/PLTE/tRNS/IDAT/IEND. [VERIFIED: codebase inspection] | `png_indexed_crc32`, `png_indexed_u32`, `png_indexed_slice`, and Indexed8 transparent chunk test. [VERIFIED: codebase inspection] | `encode_test.mbt` |
| Public canonical decode | Decode transparent Adam7 bytes with public generic `PngDecoder`; assert `RGBA8` and every coordinate maps to its RGB/alpha entry. Also drain an all-opaque counterpart and assert `RGB8`, no tRNS, and all components. [VERIFIED: codebase inspection] | Existing Indexed8 RGB8/RGBA8 public assertions and decoder indexed-Adam7 path. [VERIFIED: codebase inspection] | `encode_test.mbt` |
| Eager/chunk identity | Fresh eager and fresh chunk encoders must produce byte-identical complete PNGs for the transparent 5×5 fixture. [VERIFIED: codebase inspection] | `png_indexed_chunk_drain` / `png_indexed_chunk_eager`; low-bit public eager oracle pattern. [VERIFIED: codebase inspection] | `encode_test.mbt` plus `stream_encode_test.mbt` |
| Hostile leases | Fresh chunk machines under `[0,1]`, `[1]`, and `[0,1,3,2,5]`; assert accepted-only totals, output equality, and `Z`-filled unused tails. [VERIFIED: codebase inspection] | `png_stream_indexed_hostile_drain` and `png_stream_indexed_low_bit_hostile_drain`. [VERIFIED: codebase inspection] | `stream_encode_test.mbt` |
| Sticky success/error | After `Finished`, a fresh sentinel lease gets zero writes and `Finished`; release a 1-byte lease before first pull, then assert the same sticky typed error and no later-lease mutation. [VERIFIED: codebase inspection] | Indexed8 and selected-depth released-lease helpers. [VERIFIED: codebase inspection] | `stream_encode_test.mbt` |
| Atomic preflight/budget | Eager: output limit one below exact and work budget one below exact leave writer at zero and complete budget snapshot unchanged. Chunk: equivalent constructor failures occur before a lease is exposed and preserve snapshot. [VERIFIED: codebase inspection] | `png_adam7_same_remaining`, Indexed8 admission test, and generic Adam7 exact/one-less tests. [VERIFIED: codebase inspection] | `encode_test.mbt`, `stream_encode_test.mbt`, `encode_wbtest.mbt` |
| Diagnostics | Supply a fresh diagnostics object on each rejected eager/chunk call and retain the existing typed error vocabulary; only assert diagnostics contents if a public read API is found. [VERIFIED: codebase search] | Existing public factory call signature. [VERIFIED: codebase inspection] | same admission tests |
| Legacy byte freeze | Retain the 89-byte opaque Indexed8 vector and the 112-byte transparent non-interlaced vector; retain low-bit 1/2/4 vectors unchanged. [VERIFIED: codebase inspection and v0.25 verification] | Existing Indexed8/low-bit literal tests. [VERIFIED: codebase inspection] | `encode_test.mbt` |

## Test File Plan

### `modules/mb-image/png/encode_test.mbt` — public independent qualification

1. Add one `png_encode_indexed8_adam7_source(transparent : Bool)` helper using the 5×5 fixture, and a public eager helper for the new explicit Adam7 entry. The exact public entry spelling is intentionally not prescribed here. [ASSUMED]
2. Add `PNG Indexed8 Adam7 eager wire, PLTE/tRNS, and public decode`: independently parse the complete transparent eager result; assert IHDR, each chunk/CRC, 36 raw pass bytes, and all 25 RGBA8 pixels. [ASSUMED]
3. In the same test or a sibling opaque test, prove no tRNS and public RGB8 canonicalization for all 25 pixels. [ASSUMED]
4. Extend the existing public chunk drain/eager helpers, or add Adam7-specific siblings, so chunk-origin bytes receive the same independent parser/decode oracle instead of only comparing against eager. [VERIFIED: Phase 78 test split]
5. Add exact and one-less eager output/work cases using the actual admitted Adam7 length/work; assert typed failure, writer position `0`, unchanged complete budget snapshots, and no broadening of existing `encode_indexed8`. [ASSUMED]
6. Keep the existing 89-byte opaque, 112-byte transparent, and Indexed1/2/4 literal tests untouched; their continued execution is the compatibility assertion. [VERIFIED: codebase inspection]

### `modules/mb-image/png/stream_encode_test.mbt` — public lifecycle qualification

1. Add an Adam7-specific eager oracle/drain helper rather than changing low-bit selected-depth helpers. It must construct only the future explicit Indexed8 Adam7 chunk route and compare to a separately fresh eager Adam7 result. [ASSUMED]
2. Run the three schedules `[0UL, 1UL]`, `[1UL]`, and `[0UL, 1UL, 3UL, 2UL, 5UL]`; check `written <= capacity`, accepted-only totals, collected bytes, untouched `Z` tails, zero-write sticky completion, and output equality. [VERIFIED: codebase inspection]
3. Release the first 1-byte lease before `pull`, then replay into a fresh `Z` lease. Check zero writes, unchanged total, identical typed error, and untouched first/later lease bytes. [VERIFIED: codebase inspection]
4. Add output-limit, zero-pixel-budget, and one-less-work rejection cases at factory construction. Snapshot every resource-limit field before/after; no lease exists on `Err`. Reuse the existing diagnostics parameter and error-context check. [VERIFIED: codebase inspection]

### `modules/mb-image/png/encode_wbtest.mbt` — narrow internal fact checks

1. Assert a 5×5 Indexed8 Adam7 preflight has profile `Indexed8`, interlace `Adam7`, 36 scanline bytes, one Stored block, 47-byte IDAT, PLTE/tRNS frame offsets, 143-byte total, and selected work equal to the planned frame total for the fixed profile. These numeric facts are proposed from the independent fixture and require implementation confirmation. [ASSUMED]
2. Verify `present()` leaves the next `tRNS` byte and `trns_crc` unchanged until `acknowledge`, then verify progress exactly once; retain Phase 77’s generic tRNS acknowledgement test as regression coverage. [VERIFIED: codebase inspection]
3. Do not duplicate the full raster oracle here; public `encode_test.mbt` owns the independent wire result. [VERIFIED: Phase 78/80 test ownership]

### Do not change for this milestone

- `png_test.mbt` already demonstrates decoder-side indexed Adam7 support through generic raster machinery; use it as confidence in the public decode oracle, not as a second generated encoder fixture. [VERIFIED: codebase inspection]
- `generated_vectors*.mbt` and copied fixture trees are unnecessary for one fixed encode qualification vector. [ASSUMED]
- Low-bit selected-depth helpers/tests remain non-interlaced regression coverage; do not add an Adam7 mode or pass-packer to them. [VERIFIED: v0.25 requirements]

## Failure Modes the Tests Must Catch

| Failure mode | Test that catches it |
|---|---|
| IHDR says non-interlaced while payload is pass-ordered, or vice versa | Exact IHDR byte `28 == 01` plus the full raw pass oracle. [ASSUMED] |
| Pass geometry uses full-image row coordinates or skips an empty/local pass row | 5×5 all-seven-pass fixture and 36-byte row-by-row oracle. [ASSUMED] |
| PLTE/tRNS is omitted, reordered, truncated, or its CRC advances before acceptance | Independent chunk parser/CRC plus white-box preview/ack check. [VERIFIED: Phase 77 pattern] |
| Chunk shares a mistaken eager implementation | Chunk-origin bytes independently parse/decode; not only `chunk == eager`. [VERIFIED: Phase 78 pattern] |
| Progress or CRC advances on zero/rejected leases | Zero-first hostile schedule, accepted-only totals, sentinel tails, and released-lease sticky replay. [VERIFIED: codebase inspection] |
| Preflight charges work or writes output before an Adam7 failure | Exact/one-less output/work snapshots and writer/lease absence. [VERIFIED: codebase inspection] |
| Existing Indexed8/non-interlaced or selected low-bit bytes change | Existing literal vector tests remain untouched and execute in the package gate. [VERIFIED: codebase inspection] |

## Four-Target Gate

Run only the ordinary PNG package command after focused native red/green tests pass:

```powershell
moon -C modules/mb-image test png --target all --frozen
```

This exercises the module’s declared wasm, wasm-gc, js, and native targets. v0.25’s final audit used the same ordinary gate and recorded 286/286 passing tests per target; do not replace it with a filter, wrapper, copied source tree, or target-specific expectation. [VERIFIED: modules/mb-image/moon.mod.json and v0.25-MILESTONE-AUDIT.md]

## Open Questions / Planning Gates

1. **Public API spelling:** Existing Indexed8 public APIs are fixed non-interlaced `encode_indexed8` and `new_indexed8`; unlike ImageView profiles they have no current interlace selector. The plan must choose an explicit opt-in eager/chunk spelling without changing those compatibility wrappers. [VERIFIED: codebase inspection]
2. **Indexed Adam7 traversal seam:** Existing Adam7 raw/cursor functions accept `ImageView`, while the indexed source is separate and immutable. The implementation plan needs one bounded indexed-coordinate adapter inside the existing machine, followed by the independent test matrix above; it must not retrofit low-bit packed traversal. [VERIFIED: codebase inspection]
3. **Diagnostics observability:** No current Indexed encode test asserts diagnostic contents and the indexed constructors use an underscore-prefixed diagnostics parameter. Before promising a diagnostics-state assertion, verify whether the diagnostics type exposes a stable public snapshot/query. [VERIFIED: codebase search]

## Sources

- `modules/mb-image/png/{png,encode,stream_encode}.mbt` — Indexed profiles, existing fixed interlace seam, shared state machine, Adam7 geometry, and public constructors. [VERIFIED: codebase inspection]
- `modules/mb-image/png/{encode_test,encode_wbtest,stream_encode_test,raster_decode}.mbt` — Indexed CRC/vector, Adam7 raw-raster, hostile lease, atomic admission, and indexed-Adam7 decode anchors. [VERIFIED: codebase inspection]
- `.planning/milestones/v0.24-phases/{77-indexed-png-transparency,78-resumable-indexed-png-qualification}` — transparency, acknowledged CRC, streaming, and qualification contracts. [VERIFIED: phase artifacts]
- `.planning/milestones/v0.25-REQUIREMENTS.md`, Phase 79/80 summaries/verifications, and v0.25 audit/integration — selected-depth history, completion evidence, and explicit `INDEXADAM7` deferral. [VERIFIED: planning artifacts]

## Confidence

- **Test locations and reusable helpers: HIGH.** All named test and production seams were inspected directly. [VERIFIED: codebase inspection]
- **Fixture geometry and raw bytes: MEDIUM.** The proposed 5×5 fixture/pass table was hand-derived for an independent oracle; implementation should first land it as a failing test and verify any arithmetic discrepancy without deriving expected data from production helpers. [ASSUMED]
- **Diagnostics non-mutation assertion: LOW.** Error/budget/output atomicity is established, but no public diagnostics observation was found in the indexed encode tests. [VERIFIED: codebase search]
