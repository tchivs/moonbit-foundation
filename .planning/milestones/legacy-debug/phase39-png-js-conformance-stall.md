---
status: diagnosed
trigger: "pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png spends multiple minutes at PNG colour conformance public evidence: moon -C modules/mb-image test png --target js --frozen after Phase39 Adaptive changes. Focused new tests 12/12 passed all targets. Process sustained CPU without output; quality was terminated to avoid indefinite run and build caches cleaned. Diagnose only; use only modules/mb-image/_build/phase39-active if reproduction is required, and clean it before reporting."
created: 2026-07-22T02:29:51.8853478Z
updated: 2026-07-22T02:48:10Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: "Confirmed: the apparent JS stall is finite, CPU-bound generated PNG decoder conformance work, dominated by pre-Phase39 per-byte hostile-schedule tests. It is not an Adaptive encoding loop."
test: "Completed diagnosis-only investigation."
expecting: "No further action without a separately authorized quality/runtime-budget decision."
next_action: "Return the root-cause report to the requesting workflow."

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: "The Png quality lane completes PNG colour conformance public evidence on the JS target in a bounded normal test duration."
actual: "moon -C modules/mb-image test png --target js --frozen ran for multiple minutes with sustained CPU and no output; it was terminated to avoid an indefinite run."
errors: "No error output reported."
reproduction: "Run pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png; the observed command is moon -C modules/mb-image test png --target js --frozen."
started: "After Phase39 Adaptive changes; focused new tests passed 12/12 on all targets."

## Eliminated
<!-- APPEND only - prevents re-investigating -->


## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-07-22T02:29:51.8853478Z
  checked: "Initial workspace state"
  found: "Current branch is chore/gitignore-tool-state; unrelated tracked edits already exist in modules/mb-image/qoi/encode.mbt, qoi.mbt, stream_decode.mbt, and stream_encode.mbt."
  implication: "Investigation must not alter or attribute existing QOI edits."
- timestamp: 2026-07-22T02:32:10Z
  checked: "Knowledge base and Png quality lane implementation"
  found: "No knowledge-base entry has two-keyword overlap with sustained CPU/no output/PNG JavaScript. The reported command is called once per target in the 'PNG colour conformance public evidence' stage, before README checks and before the all-target test stage."
  implication: "The stall is localized to the package-wide PNG JavaScript test invocation, not to quality output capture, README checking, or a later all-target test command."
- timestamp: 2026-07-22T02:32:10Z
  checked: "PNG package inventory"
  found: "The package contains black-box/internal test files including deflate_wbtest, encode_test, encode_wbtest, generated_decode_vectors_test, generated_vectors_test, png_test, raster_decode_wbtest, stream_decode_test, stream_decode_wbtest, stream_encode_test, stream_encode_wbtest, and structural_wbtest."
  implication: "A focused Phase39 test passing does not establish package-wide JS behavior; controlled narrowing across test files is required."
- timestamp: 2026-07-22T02:34:20Z
  checked: "MoonBit test command capabilities and Phase39 commit history"
  found: "moon test supports --outline, -f/--filter glob, -i/--index when one file is selected, --build-only, and --target-dir. Phase39 changed adaptive planning/replay (39-02) and public adaptive strategy factories/tests (39-03)."
  implication: "The reported command can be reproduced without default cache writes and then isolated one named test at a time."
- timestamp: 2026-07-22T02:36:30Z
  checked: "Cold isolated reproduction: moon -C modules/mb-image test png --target js --frozen --target-dir _build/phase39-active"
  found: "The test outline enumerated public and internal PNG tests, including the new adaptive tests. The exact package-wide JavaScript command completed successfully within the 60-second observation boundary (the enclosing outline-plus-test command took 50.7 seconds); it did not require termination."
  implication: "The symptom is reproducible as a substantial silent JavaScript operation but not as an indefinite hang in a fresh dedicated target directory. Further evidence must separate cold compile cost from test execution cost."
- timestamp: 2026-07-22T02:38:20Z
  checked: "First attempt to time warm build-only and filtered tests"
  found: "The PowerShell wrapper used the reserved automatic variable $args, so it invoked moon without a subcommand and failed in 235 ms. No MoonBit test was run in that attempt."
  implication: "This control error neither supports nor refutes any product hypothesis; the measurements must be repeated with direct commands."
- timestamp: 2026-07-22T02:40:05Z
  checked: "Warm isolated build and selected Adaptive test execution"
  found: "With the same phase39-active cache, JS --build-only completed successfully in 109 ms. The test filter 'PNG adaptive*' completed successfully in 4.31 s, with no stderr output."
  implication: "Phase39 Adaptive public tests are bounded and fast after compilation; a per-test execution loop is no longer the leading explanation for the original sustained CPU/no-output observation."
- timestamp: 2026-07-22T02:42:00Z
  checked: "Warm full package JavaScript execution and Phase39 change inventory"
  found: "The full warmed PNG suite still completed successfully but took 35.025 s, versus 109 ms for warm build-only. Phase39 production/test changes are concentrated in encode.mbt, stream_encode.mbt, png.mbt, encode_wbtest.mbt, stream_encode_wbtest.mbt, and stream_encode_test.mbt; filtered Adaptive public tests take only 4.31 s."
  implication: "The observed latency is primarily test execution, not compilation. Whole-suite isolation must identify whether its dominant test is Adaptive or unrelated."
- timestamp: 2026-07-22T02:44:35Z
  checked: "Warm per-file JavaScript test isolation"
  found: "The dominant files are png/stream_decode_test.mbt (23.466 s) and png/png_test.mbt (8.333 s); together they account for 31.799 s of the 35.025-second full suite. The Phase39-touched png/stream_encode_test.mbt takes 3.919 s, encode_test.mbt 846 ms, and the remaining files are each below 0.5 s except none."
  implication: "The original package-wide JS latency is explained by decode test groups that Phase39 did not modify. Adaptive encoding does not directly cause the dominant runtime cost."
- timestamp: 2026-07-22T02:46:30Z
  checked: "Dominant test-code paths"
  found: "stream_decode_test.mbt runs every generated decode case through an empty-then-one-byte schedule and a ragged schedule, then separately pushes every byte of every accepted case and compares every generated case's one-byte chunk outcome to an eager decode. png_test.mbt separately decodes the generated public corpus and the fixed/dynamic generated decode vectors. These files are outside the Phase39 changed-file inventory."
  implication: "The sustained CPU with no runner progress is expected from thousands of synchronous public decoder calls over generated vectors and per-byte subviews; MoonBit emits no per-test progress until the package command exits."
- timestamp: 2026-07-22T02:46:30Z
  checked: "Root-cause falsification test"
  found: "If Adaptive replay were the cause, the filtered 'PNG adaptive*' set or Phase39 stream_encode_test.mbt would dominate warmed JS duration. Instead they take 4.31 s and 3.919 s respectively, while untouched decode files take 31.799 s."
  implication: "This directly falsifies the hypothesis that Phase39 Adaptive test execution causes the package-wide stall."
- timestamp: 2026-07-22T02:48:10Z
  checked: "Isolated reproduction cleanup"
  found: "moon -C modules/mb-image --target-dir _build/phase39-active clean removed the exact dedicated target directory, and its absence was verified."
  implication: "No build cache or diagnostic artifacts from this investigation remain."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "The JS command is not hung in Phase39 Adaptive filtering. Its finite but silent runtime is dominated by pre-existing generated decoder conformance: stream_decode_test.mbt repeatedly sends every generated PNG through public one-byte and hostile packet schedules and compares them with eager decoding, while png_test.mbt decodes the generated public/fixed/dynamic corpus again. These synchronous loops consume CPU and the MoonBit runner provides no progress output."
fix: "Diagnosis only — no production, test, policy, or quality-lane change authorized. If a future change is desired, it should be a separately approved observability/runtime-budget decision for decoder corpus tests, not an Adaptive encoder change."
verification: "Exact fresh isolated command completed within 60 seconds; warmed full suite completed in 35.025 seconds; filtered Adaptive set completed in 4.31 seconds; per-file timings isolated 31.799 seconds to untouched decode test files."
files_changed: []
