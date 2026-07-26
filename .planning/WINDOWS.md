---
schema_version: 1
open_count: 12
waived_count: 0
fixed_count: 3
total_count: 15
last_updated: 2026-07-26T09:59:23.761Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 54 | deviation | modules/mb-image/png/encode_test.mbt |  | Big-endian GrayAlpha16 parity omitted because Phase 53 rejects Big-endian GrayAlpha descriptors. | open |  | 2026-07-22T21:13:07.814Z |  |
| 2 | 57 | unrun-verify | modules/mb-image/png |  | Full native PNG suite did not complete because the current moon.exe stopped making CPU progress in the shared workspace; exact focused runs were used instead. | open |  | 2026-07-23T00:01:48.557Z |  |
| 3 | 57 | deviation | modules/mb-image/png/stream_encode_test.mbt |  | Full native PNG suite hit existing png.whitebox_test.exe exit 0xc0000409; focused Phase 57 regressions passed. | open |  | 2026-07-23T00:11:23.125Z |  |
| 4 | 80 | unrun-verify | modules/mb-image/png/stream_encode_test.mbt |  | moon -C modules/mb-image test png --target all --frozen did not complete; rerun four-target PNG package qualification | open |  | 2026-07-23T21:52:24.286Z |  |
| 5 | 92 | deviation | modules/mb-svg/svg/scene_wbtest.mbt |  | Updated source-boundary fixture to use geometrically admissible values under derived-coordinate checks. | open |  | 2026-07-25T17:25:16.084Z |  |
| 6 | 93 | deviation | .planning/STATE.md |  | Repaired malformed active-phase position before state advancement. | open |  | 2026-07-25T18:55:21.879Z |  |
| 7 | 94 | deviation | scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 |  | Captured MoonBit warning output and parsed runner glyphs safely in Windows PowerShell. | open |  | 2026-07-25T20:18:18.679Z |  |
| 8 | 94 | deviation | scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 |  | Created the planned baseline documentation directory when it was absent. | open |  | 2026-07-25T20:18:19.137Z |  |
| 9 | 94 | deviation | scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 |  | Made Markdown audit data and aggregate validation Windows PowerShell 5.1-safe. | open |  | 2026-07-25T20:18:19.584Z |  |
| 10 | 94 | deviation | docs/benchmarks/mb-svg-native-release-baseline.md |  | Escaped raw output in preformatted blocks to preserve exact bytes without diff whitespace. | open |  | 2026-07-25T20:18:20.030Z |  |
| 11 | 96 | deviation | modules/mb-svg/svg/geometry_wbtest.mbt |  | Tracer helper Result type was corrected before verification. | open |  | 2026-07-25T22:26:33.731Z |  |
| 12 | 96 | deviation | modules/mb-svg/svg/lower_wbtest.mbt |  | Manual line and point-list test rows use 65537 because 65536 is admitted without the parser fixture transform. | open |  | 2026-07-25T22:33:25.404Z |  |
| 13 | 97 | deviation | modules/mb-font/font/font.mbt |  | Preserved, reviewed, and repaired an in-scope Task 3 draft with unknown provenance | fixed |  | 2026-07-26T09:58:43.531Z | 2026-07-26T09:59:22.595Z |
| 14 | 97 | deviation | modules/mb-font/font/tables.mbt |  | Restored stable missing-table and detailed head error contracts during coordinator expansion | fixed |  | 2026-07-26T09:58:44.060Z | 2026-07-26T09:59:23.177Z |
| 15 | 97 | deviation | modules/mb-font/font/generated_fonts.mbt |  | Stabilized a late generated OS/2 metric update across all four targets | fixed |  | 2026-07-26T09:58:44.599Z | 2026-07-26T09:59:23.761Z |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "54",
    "file": "modules/mb-image/png/encode_test.mbt",
    "line": null,
    "description": "Big-endian GrayAlpha16 parity omitted because Phase 53 rejects Big-endian GrayAlpha descriptors.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-22T21:13:07.814Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "unrun-verify",
    "phase": "57",
    "file": "modules/mb-image/png",
    "line": null,
    "description": "Full native PNG suite did not complete because the current moon.exe stopped making CPU progress in the shared workspace; exact focused runs were used instead.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-23T00:01:48.557Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "57",
    "file": "modules/mb-image/png/stream_encode_test.mbt",
    "line": null,
    "description": "Full native PNG suite hit existing png.whitebox_test.exe exit 0xc0000409; focused Phase 57 regressions passed.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-23T00:11:23.125Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "80",
    "file": "modules/mb-image/png/stream_encode_test.mbt",
    "line": null,
    "description": "moon -C modules/mb-image test png --target all --frozen did not complete; rerun four-target PNG package qualification",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-23T21:52:24.286Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "92",
    "file": "modules/mb-svg/svg/scene_wbtest.mbt",
    "line": null,
    "description": "Updated source-boundary fixture to use geometrically admissible values under derived-coordinate checks.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T17:25:16.084Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "93",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Repaired malformed active-phase position before state advancement.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T18:55:21.879Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "94",
    "file": "scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1",
    "line": null,
    "description": "Captured MoonBit warning output and parsed runner glyphs safely in Windows PowerShell.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T20:18:18.679Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "94",
    "file": "scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1",
    "line": null,
    "description": "Created the planned baseline documentation directory when it was absent.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T20:18:19.137Z",
    "resolved_at": null
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "94",
    "file": "scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1",
    "line": null,
    "description": "Made Markdown audit data and aggregate validation Windows PowerShell 5.1-safe.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T20:18:19.584Z",
    "resolved_at": null
  },
  {
    "id": 10,
    "kind": "deviation",
    "phase": "94",
    "file": "docs/benchmarks/mb-svg-native-release-baseline.md",
    "line": null,
    "description": "Escaped raw output in preformatted blocks to preserve exact bytes without diff whitespace.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T20:18:20.030Z",
    "resolved_at": null
  },
  {
    "id": 11,
    "kind": "deviation",
    "phase": "96",
    "file": "modules/mb-svg/svg/geometry_wbtest.mbt",
    "line": null,
    "description": "Tracer helper Result type was corrected before verification.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T22:26:33.731Z",
    "resolved_at": null
  },
  {
    "id": 12,
    "kind": "deviation",
    "phase": "96",
    "file": "modules/mb-svg/svg/lower_wbtest.mbt",
    "line": null,
    "description": "Manual line and point-list test rows use 65537 because 65536 is admitted without the parser fixture transform.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T22:33:25.404Z",
    "resolved_at": null
  },
  {
    "id": 13,
    "kind": "deviation",
    "phase": "97",
    "file": "modules/mb-font/font/font.mbt",
    "line": null,
    "description": "Preserved, reviewed, and repaired an in-scope Task 3 draft with unknown provenance",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-26T09:58:43.531Z",
    "resolved_at": "2026-07-26T09:59:22.595Z"
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "97",
    "file": "modules/mb-font/font/tables.mbt",
    "line": null,
    "description": "Restored stable missing-table and detailed head error contracts during coordinator expansion",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-26T09:58:44.060Z",
    "resolved_at": "2026-07-26T09:59:23.177Z"
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "97",
    "file": "modules/mb-font/font/generated_fonts.mbt",
    "line": null,
    "description": "Stabilized a late generated OS/2 metric update across all four targets",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-26T09:58:44.599Z",
    "resolved_at": "2026-07-26T09:59:23.761Z"
  }
]
````
