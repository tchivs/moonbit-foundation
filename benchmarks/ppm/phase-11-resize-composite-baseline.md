# Phase 11 local resize-composite benchmark record

This is local reproducibility and regression evidence only. It is not a performance
claim, threshold, or release authority.

## Workload provenance

| Field | Value |
| --- | --- |
| Workload | `ppm/pipeline/resize-composite/256x256` |
| Foreground | Deterministic opaque strict PPM, 128x128, resized nearest-neighbor to 256x256 |
| Destination | Deterministic opaque strict PPM, 256x256 |
| Public operation sequence | strict decode foreground and destination -> nearest resize -> RGB8 to straight RGBA8 for both -> source-over -> straight RGBA8 to RGB8 -> strict PPM encode |
| Target | native, release build |
| Command | `moon -C benchmarks bench --release --target native --frozen ppm` |
| Warmup | One untimed direct-command warmup at 2026-07-20T09:02:14.5247140Z; completed 9/9 benchmark cases |
| moon | `0.1.20260713 (75c7e1f 2026-07-13)` |
| moonc | `v0.10.4+2cc641edf (2026-07-15)` |
| moonrun | `0.1.20260713 (75c7e1f 2026-07-13)` |
| Host facts | Windows 11 Enterprise, 10.0.22631, 64-bit |
| foreground source digest | rolling257: `452546923` |
| destination source digest | rolling257: `434905955` |
| correctness digest | rolling257 encoded output: `327163577` |

The checked benchmark constructs both PPM sources outside the measured closure,
then validates the 256x256 encoded output size and correctness digest before
timing the same public pipeline. All codec limits and per-operation budgets are
fresh and explicit in `ppm_bench.mbt`.

## Captures

Each capture is one separate direct frozen native command. The retained summary
is the named workload's one-run mean/range line; every command completed all
9 benchmark cases successfully.

| Capture | Started (UTC) | Timing summary | Result |
| --- | --- | --- | --- |
| 1 | 2026-07-20T09:03:16.8850167Z | 3.89 s ± 0.00 ns; range 3.89 s to 3.89 s; 1 x 1 run | 9/9 passed |
| 2 | 2026-07-20T09:04:31.2779841Z | 3.09 s ± 0.00 ns; range 3.09 s to 3.09 s; 1 x 1 run | 9/9 passed |
| 3 | 2026-07-20T09:05:33.8201412Z | 2.81 s ± 0.00 ns; range 2.81 s to 2.81 s; 1 x 1 run | 9/9 passed |
| 4 | 2026-07-20T09:06:33.3848228Z | 2.93 s ± 0.00 ns; range 2.93 s to 2.93 s; 1 x 1 run | 9/9 passed |
| 5 | 2026-07-20T09:07:35.2583254Z | 3.05 s ± 0.00 ns; range 3.05 s to 3.05 s; 1 x 1 run | 9/9 passed |
| 6 | 2026-07-20T09:08:37.9852735Z | 2.98 s ± 0.00 ns; range 2.98 s to 2.98 s; 1 x 1 run | 9/9 passed |
| 7 | 2026-07-20T09:09:41.2899211Z | 2.99 s ± 0.00 ns; range 2.99 s to 2.99 s; 1 x 1 run | 9/9 passed |

## Transparent aggregate

The seven local observations have arithmetic mean **3.11 s**, minimum **2.81 s**,
and maximum **3.89 s**. They are host-dependent observations retained solely to
make this exact workload reproducible and comparable in future local runs.
