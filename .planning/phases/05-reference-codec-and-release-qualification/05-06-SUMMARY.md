---
phase: 05-reference-codec-and-release-qualification
plan: "06"
subsystem: benchmark-qualification
tags: [moonbit, ppm, benchmark, native, release, sha256, qualification]

requires:
  - phase: 05-reference-codec-and-release-qualification/05-05
    provides: Exact candidate contracts, support policy, and non-marketing claim boundaries
  - phase: 05-reference-codec-and-release-qualification/05-04
    provides: Public PPM stream-transform-stream consumers and rolling correctness digest
provides:
  - Eight correctness-gated public PPM benchmark workloads in an isolated Native workspace
  - Seven-sample environment-complete native release baseline with raw summary evidence
  - Closed-schema static qualification and conservative local catastrophic-regression check
affects: [05-07-release-qualification, 05-08-final-verification, QUAL-05]

tech-stack:
  added: []
  patterns:
    - Independent benchmark workspace consumes candidate modules by public named dependencies without changing release topology
    - Dynamic raw benchmark evidence remains ignored while its checked summaries and SHA-256 identities are tracked

key-files:
  created:
    - benchmarks/moon.work
    - benchmarks/ppm/moon.mod.json
    - benchmarks/ppm/moon.pkg
    - benchmarks/ppm/ppm_bench.mbt
    - scripts/benchmarks/Invoke-PpmBenchmarks.ps1
    - scripts/quality/Test-BenchmarkQualification.ps1
    - release/qualification/benchmark-schema.json
    - release/qualification/ppm-native-release-baseline.json
  modified:
    - .gitignore
    - scripts/quality.ps1

key-decisions:
  - "Keep the benchmark module in a nested workspace so evidence uses public named dependencies without becoming a sixth release-workspace member."
  - "Use one official MoonBit sample per workload per invocation and seven independent invocations as the tracked raw sample series."
  - "Gate only matching local hardware at max(4 times baseline median, baseline median plus 5ms); hosted or different-hardware results remain informational."

patterns-established:
  - "Correctness-before-timing: every MoonBit workload verifies dimensions, byte counts, error code, and rolling257 output before entering it.bench."
  - "Closed evidence: exact ordered keys, eight workload names, seven samples/runs, environment identity, SHA-256 digests, and non-marketing claim are fail-closed."

requirements-completed: [QUAL-05]

coverage:
  - id: D1
    description: Eight named decode, encode, bounded-rejection, and transform-pipeline workloads run only through public codec, image operation, I/O, budget, and storage APIs.
    requirement: QUAL-05
    verification:
      - kind: integration
        ref: "moon -C benchmarks bench --release --target native --frozen ppm; 8/8 passed"
        status: pass
    human_judgment: false
  - id: D2
    description: The checked baseline records seven raw samples per workload, complete parsed summaries, exact environment and source identities, corpus/correctness SHA-256 digests, aggregates, variance, and timestamp.
    requirement: QUAL-05
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/benchmarks/Invoke-PpmBenchmarks.ps1 -Check"
        status: pass
      - kind: integration
        ref: "scripts/quality/Test-BenchmarkQualification.ps1#closed positive and five negative mutations"
        status: pass
    human_judgment: false
  - id: D3
    description: Performance qualification is a conservative catastrophic local regression gate and cannot become a hosted or marketing claim.
    requirement: QUAL-05
    verification:
      - kind: integration
        ref: "Invoke-PpmBenchmarks.ps1 -Check#local-comparable-gated"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality.ps1 -Lane Required; 197/197 tests per required target"
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-07-17
status: complete
---

# Phase 5 Plan 6: Reproducible Benchmark Qualification Summary

**Eight public PPM workloads now carry seven-sample Native release evidence, closed correctness/environment identity, and a deliberately loose local-only regression gate**

## Performance

- **Duration:** 40 min
- **Started:** 2026-07-17T01:38:00Z
- **Completed:** 2026-07-17T02:18:00Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added canonical decode and encode workloads at 64x64, 256x256, and 1024x1024, one bounded header rejection, and a 256x256 decode-flip-encode pipeline. Every workload proves its dimensions, byte count, structured rejection, or rolling257 digest before timing.
- Captured one warmup and seven complete Native release invocations in 555.3 seconds. Each tracked workload carries seven mean samples, mean/median/sample standard deviation/coefficient of variation/min/max, corpus and correctness SHA-256, and threshold policy; each raw run preserves all eight MoonBit summary records and the SHA-256 identity of its ignored complete console evidence.
- Recorded exact moon/moonc/moonrun, benchmark commit and source digest, target, release/frozen mode, Windows/PowerShell/architecture/CPU/logical-core/memory identity, hardware fingerprint, and UTC timestamps.
- Added a closed schema, exact structural validator, five generated negative mutations, static Required integration, and a live comparable-hardware check that passed all eight workloads without making a performance claim.

## Baseline Snapshot

| Workload | Median | Samples |
|---|---:|---:|
| decode 64x64 | 43.97 ms | 7 |
| decode 256x256 | 634.16 ms | 7 |
| decode 1024x1024 | 10.63 s | 7 |
| encode 64x64 | 12.88 ms | 7 |
| encode 256x256 | 204.57 ms | 7 |
| encode 1024x1024 | 3.20 s | 7 |
| reject header token limit | 0.03 ms | 7 |
| decode-flip-encode 256x256 | 1.13 s | 7 |

These values are local qualification evidence only. They are not throughput promises, cross-machine comparisons, or marketing claims.

## Task Commits

1. **Task 1 RED: Define failing benchmark inventory** - `cdef444` (test)
2. **Task 1 GREEN: Add correctness-gated public workloads** - `2d9c183` (feat)
3. **Task 2: Qualify reproducible baseline evidence** - `fbecf00` (test)
4. **Verification fix: Isolate benchmark workspace** - `dc511b8` (fix)
5. **Evidence fix: Bind baseline to isolated workspace commit** - `3427c12` (fix)

## Files Created/Modified

- `benchmarks/ppm/ppm_bench.mbt` - Eight named public-API workloads and untimed correctness gates.
- `benchmarks/ppm/moon.mod.json`, `benchmarks/ppm/moon.pkg` - Native-only nonpublication benchmark consumer.
- `benchmarks/moon.work` - Isolated workspace resolving the three candidate modules without altering release membership.
- `scripts/benchmarks/Invoke-PpmBenchmarks.ps1` - Capture, parse, aggregate, environment/digest validation, and live check harness.
- `release/qualification/benchmark-schema.json` - Closed declarative schema for the tracked record.
- `release/qualification/ppm-native-release-baseline.json` - Seven-run checked baseline.
- `scripts/quality/Test-BenchmarkQualification.ps1` - Static positive validation plus extra-field, order, environment, digest, and sample-count negatives.
- `scripts/quality.ps1` - Required static benchmark qualification integration.
- `.gitignore` - Dynamic raw benchmark evidence exclusion.

## Decisions Made

- One MoonBit summary sample is captured per workload invocation because the official harness performs its own adaptive batching; seven independent invocations supply the planned raw cross-run series and variance.
- Baseline evidence owns the complete parsed MoonBit summaries and SHA-256 of each complete raw output, while the host-specific text remains in ignored `artifacts/benchmarks/`.
- Live performance failure is possible only for the exact same hardware fingerprint outside hosted CI and only beyond `max(4 * baseline median, baseline median + 5 ms)`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a minimal benchmark module and workspace**
- **Found during:** Task 1 RED
- **Issue:** The pinned toolchain cannot execute `benchmarks/ppm` without a containing module/workspace; the plan listed only package files.
- **Fix:** Added a Native-only nonpublication module and public named dependencies.
- **Verification:** All eight workloads compile and run through public APIs.
- **Committed in:** `cdef444`

**2. [Rule 1 - Bug] Reduced each official invocation to one recorded MoonBit sample**
- **Found during:** Task 1 GREEN verification
- **Issue:** The default ten samples made byte-wise 1024x1024 public codec evidence exceed a practical capture window.
- **Fix:** Set `count=1` per workload and retained seven independent harness invocations; adaptive MoonBit batching and complete run summaries remain recorded.
- **Verification:** Full 8/8 invocation completes in about 65-77 seconds; seven-run capture completed.
- **Committed in:** `2d9c183`

**3. [Rule 1 - Bug] Isolated benchmark workspace from exact release topology**
- **Found during:** First full Required run
- **Issue:** Registering the benchmark module in root `moon.work` violated the exact five-member release allowlist.
- **Fix:** Restored root workspace byte-for-byte and moved evidence resolution to `benchmarks/moon.work` with `moon -C benchmarks`.
- **Verification:** Focused nested benchmark, live check, and full Required pass; release workspace remains five members.
- **Committed in:** `dc511b8`, `3427c12`

**Total deviations:** 3 auto-fixed (2 blocking/correctness, 1 runtime practicality). **Impact:** Evidence is independently consumable and release topology is stricter than the original package-only assumption; benchmark scope and threshold policy are unchanged.

## Issues Encountered

- The first full Required run intentionally stopped on the benchmark's accidental sixth root workspace membership; the isolated workspace corrected the topology before final verification.
- Required continues to print the expected missing-README negative fixture diagnostic while returning success.

## User Setup Required

None.

## Verification

- `moon -C benchmarks bench --release --target native --frozen ppm`: 8/8 workloads passed.
- Baseline capture: one warmup plus seven formal invocations, 555.3 seconds, eight summaries per invocation.
- `pwsh -NoProfile -File scripts/quality/Test-BenchmarkQualification.ps1`: closed positive record and five negative mutations passed.
- `pwsh -NoProfile -File scripts/benchmarks/Invoke-PpmBenchmarks.ps1 -Check`: local-comparable-gated, 8/8 passed in 77.0 seconds after workspace isolation.
- `pwsh -NoProfile -File scripts/quality.ps1 -Lane Required`: passed in 127.4 seconds with 197/197 tests on each required target, exact interfaces/package inventories/docs, and read-only proof.

## Self-Check: PASSED

- All eight created artifacts and two intended integrations exist; dynamic evidence is ignored.
- Commits `cdef444`, `2d9c183`, `fbecf00`, `dc511b8`, and `3427c12` resolve in repository history.
- Baseline commit/source identities, seven sample counts, eight workload order, environment keys, correctness digests, threshold constants, and non-marketing claim all validate fail-closed.

## Next Phase Readiness

- Plan 05-07 can consume a tracked, exact benchmark qualification record without adding benchmark artifacts to candidate packages.
- Plan 05-08 can include the static benchmark gate in repeated Required runs and reserve live timing for explicit comparable-host checks.

---
*Phase: 05-reference-codec-and-release-qualification*
*Completed: 2026-07-17*
