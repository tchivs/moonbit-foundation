---
schema_version: 1
open_count: 18
waived_count: 0
fixed_count: 3
total_count: 21
last_updated: 2026-07-27T07:21:06.464Z
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
| 16 | 97 | unrun-verify | docs/rfcs/0001-moonbit-native-foundation.md |  | Plan 97-03 full Required gate cannot complete because policy records RFC 0001 Accepted while the canonical RFC and index remain Proposed; root will resolve separately. | open |  | 2026-07-26T10:53:33.620Z |  |
| 17 | 97 | deviation | policy/foundation.json |  | Reconciled pre-existing core utility, blend, image ops, and canvas import inventories so the planned exact mb-font selector could execute against the live workspace. | open |  | 2026-07-26T10:53:41.483Z |  |
| 18 | 98 | deviation | .planning/STATE.md |  | Repaired legacy Phase 98 state counters so plan advancement is parseable | open |  | 2026-07-27T06:16:12.454Z |  |
| 19 | 98 | unrun-verify | scripts/quality.ps1 |  | Full Required lane reached the known Windows unscoped moon test --target js stall in mb-image/png after all Phase 98 policy and scoped checks passed; exact process tree was terminated and the command was not retried. | open |  | 2026-07-27T07:18:53.174Z |  |
| 20 | 98 | deviation | scripts/quality/Assert-Policy.ps1 |  | Phase 98 advanced the independent font policy classifier and exact cmap/kern inventories so the generated public interface can pass fail-closed policy validation. | open |  | 2026-07-27T07:18:53.803Z |  |
| 21 | 98 | deviation | .planning/STATE.md |  | Reconciled stale Plan 98-02 activity, 5/6 progress prose, open-requirement text, Phase ? decision labels, and operator next step after final plan advancement. | open |  | 2026-07-27T07:21:06.464Z |  |

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
  },
  {
    "id": 16,
    "kind": "unrun-verify",
    "phase": "97",
    "file": "docs/rfcs/0001-moonbit-native-foundation.md",
    "line": null,
    "description": "Plan 97-03 full Required gate cannot complete because policy records RFC 0001 Accepted while the canonical RFC and index remain Proposed; root will resolve separately.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-26T10:53:33.620Z",
    "resolved_at": null
  },
  {
    "id": 17,
    "kind": "deviation",
    "phase": "97",
    "file": "policy/foundation.json",
    "line": null,
    "description": "Reconciled pre-existing core utility, blend, image ops, and canvas import inventories so the planned exact mb-font selector could execute against the live workspace.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-26T10:53:41.483Z",
    "resolved_at": null
  },
  {
    "id": 18,
    "kind": "deviation",
    "phase": "98",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Repaired legacy Phase 98 state counters so plan advancement is parseable",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T06:16:12.454Z",
    "resolved_at": null
  },
  {
    "id": 19,
    "kind": "unrun-verify",
    "phase": "98",
    "file": "scripts/quality.ps1",
    "line": null,
    "description": "Full Required lane reached the known Windows unscoped moon test --target js stall in mb-image/png after all Phase 98 policy and scoped checks passed; exact process tree was terminated and the command was not retried.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T07:18:53.174Z",
    "resolved_at": null
  },
  {
    "id": 20,
    "kind": "deviation",
    "phase": "98",
    "file": "scripts/quality/Assert-Policy.ps1",
    "line": null,
    "description": "Phase 98 advanced the independent font policy classifier and exact cmap/kern inventories so the generated public interface can pass fail-closed policy validation.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T07:18:53.803Z",
    "resolved_at": null
  },
  {
    "id": 21,
    "kind": "deviation",
    "phase": "98",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled stale Plan 98-02 activity, 5/6 progress prose, open-requirement text, Phase ? decision labels, and operator next step after final plan advancement.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T07:21:06.464Z",
    "resolved_at": null
  }
]
````
