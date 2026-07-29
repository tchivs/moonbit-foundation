---
schema_version: 1
open_count: 60
waived_count: 0
fixed_count: 3
total_count: 63
last_updated: 2026-07-29T21:26:33.190Z
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
| 22 | 99 | deviation | .planning/STATE.md |  | SDK advance left machine-readable plan position and continuity prose stale; normalized to completed 99-02 state. | open |  | 2026-07-27T10:51:22.018Z |  |
| 23 | 99 | deviation | .planning/STATE.md |  | Normalized stale final-phase progress prose and metrics after SDK advanced Plan 99-03 to verification. | open |  | 2026-07-27T11:06:57.004Z |  |
| 24 | 100 | deviation | modules/mb-font/font/outline.mbt |  | Accepted normative 0-3 byte zero glyph alignment padding with strict rejection coverage. | open |  | 2026-07-27T14:47:22.500Z |  |
| 25 | 100 | deviation | fixtures/font/dejavu-sans-2.37/oracle.json |  | Qualified U+034C as the supported composite while preserving the U+00E9 grid-rounding capability boundary. | open |  | 2026-07-27T14:47:23.453Z |  |
| 26 | 100 | deviation | fixtures/font/qualification-cases.json |  | Corrected staged one-short outline budget requested and limit expectations. | open |  | 2026-07-27T14:47:24.109Z |  |
| 27 | 100 | deviation | .planning/STATE.md |  | Normalized stale machine-readable plan position and Phase 100 decision attribution after SDK advancement. | open |  | 2026-07-27T14:48:26.488Z |  |
| 28 | 100 | deviation | scripts/fixtures/Generate-FontQualification.ps1 |  | Corrected generated scalar expectations from UInt64 to the public glyph_for_scalar Int input type. | open |  | 2026-07-27T15:59:11.669Z |  |
| 29 | 100 | deviation | .planning/STATE.md |  | Synchronized final Plan 6 of 6 verification state after stale SDK metadata output. | open |  | 2026-07-27T15:59:12.307Z |  |
| 30 | 106 | deviation | modules/mb-font/font/cff_admission_wbtest.mbt |  | Updated exact CFF retained-ledger expectations for 32-byte bounds-plus-command slots | open |  | 2026-07-28T19:31:08.387Z |  |
| 31 | 106 | deviation | modules/mb-font/font/font_test.mbt |  | Reclassified static CFF1 OTTO as supported in legacy capability fixtures | open |  | 2026-07-28T19:31:08.887Z |  |
| 32 | 106 | deviation | .planning/STATE.md |  | Normalized SDK-generated Phase 106 decision labels and stale execution prose after plan advancement | open |  | 2026-07-28T19:32:15.560Z |  |
| 33 | 106 | deviation | .planning/STATE.md |  | Normalized stale Plan 01 activity and Plan 02 next-step prose after 106-02 state advancement | open |  | 2026-07-28T19:51:31.058Z |  |
| 34 | 106 | deviation | modules/mb-font/font/collection_test.mbt |  | Retargeted legacy unsupported-profile assertions after CFF1 became selectable | open |  | 2026-07-28T20:27:41.878Z |  |
| 35 | 106 | deviation | modules/mb-font/font/font.mbt |  | Preserved the collection capability error boundary for selected CFF1 | open |  | 2026-07-28T20:27:42.376Z |  |
| 36 | 106 | deviation | .planning/STATE.md |  | Normalized SDK-generated Phase 106 completion metadata | open |  | 2026-07-28T20:27:42.867Z |  |
| 37 | 107 | deviation | scripts/fixtures/Provision-CffQualificationTools.ps1 |  | Avoided redundant full SDK inventory scans inside one-field negative mutations. | open |  | 2026-07-29T02:47:33.943Z |  |
| 38 | 107 | deviation | scripts/fixtures/Test-CffQualificationContracts.ps1 |  | Corrected dynamic PowerShell splatting so every named validation mode executes. | open |  | 2026-07-29T02:47:34.500Z |  |
| 39 | 107 | deviation | .planning/STATE.md |  | Normalized SDK-emitted Phase ? decision labels to Phase 107 after state advancement. | open |  | 2026-07-29T02:47:56.180Z |  |
| 40 | 107 | deviation | scripts/fixtures/Generate-FontQualification.ps1 |  | Source Sans 3.052R retained license comes from the exact official tag URL because the OTF release ZIP omits LICENSE.md | open |  | 2026-07-29T03:08:12.959Z |  |
| 41 | 107 | deviation | .gitattributes |  | Path-specific -text rule preserves the exact upstream CRLF Source Sans license bytes | open |  | 2026-07-29T03:08:13.551Z |  |
| 42 | 107 | deviation | scripts/quality/Assert-Policy.ps1 |  | Fixture policy synchronized to six new licensed qualification records and the live Phase 106 collection digest | open |  | 2026-07-29T03:08:14.152Z |  |
| 43 | 107 | deviation | modules/mb-font/font/cff_type2.mbt |  | Corrected Type 2 hint substitution after path start for licensed CFF outlines | open |  | 2026-07-29T05:31:38.613Z |  |
| 44 | 107 | deviation | modules/mb-font/font/cmap.mbt |  | Accepted recognized cmap companion records used by licensed qualification fonts | open |  | 2026-07-29T05:31:39.122Z |  |
| 45 | 107 | deviation | fixtures/font/cff-qualification-cases.json |  | Reconciled canonical nonempty GIDs and source locators with executable evidence | open |  | 2026-07-29T05:31:39.655Z |  |
| 46 | 107 | deviation | scripts/fixtures/Generate-FontQualification.ps1 |  | Added exact one-shot materializers for planned private evidence regions | open |  | 2026-07-29T05:31:40.166Z |  |
| 47 | 107 | deviation | modules/mb-font/font/cff_type2_fixture_wbtest.mbt |  | Replaced backend-specific Array capacity lock with portable live-frame semantics | open |  | 2026-07-29T05:31:40.662Z |  |
| 48 | 107 | deviation | .planning/STATE.md |  | Normalized stale SDK-generated Phase 107 Plan 04 execution metadata | open |  | 2026-07-29T05:32:44.798Z |  |
| 49 | 107 | deviation | .planning/phases/107-hostile-licensed-and-four-target-qualification/107-05-SUMMARY.md |  | Corrected PowerShell array composition in focused assertions | open |  | 2026-07-29T06:47:16.409Z |  |
| 50 | 107 | deviation | .planning/phases/107-hostile-licensed-and-four-target-qualification/107-05-SUMMARY.md |  | Refreshed the live Phase 103 collection corpus semantic lock | open |  | 2026-07-29T06:47:16.998Z |  |
| 51 | 107 | deviation | .planning/phases/107-hostile-licensed-and-four-target-qualification/107-05-SUMMARY.md |  | Removed a false-positive CFF2 flow heuristic | open |  | 2026-07-29T06:47:17.594Z |  |
| 52 | 107 | deviation | .planning/phases/107-hostile-licensed-and-four-target-qualification/107-05-SUMMARY.md |  | Synchronized documentation changes with exact policy file identities | open |  | 2026-07-29T06:47:18.126Z |  |
| 53 | 107 | deviation | .planning/STATE.md |  | Normalized stale SDK-generated Phase 107 Plan 05 execution metadata | open |  | 2026-07-29T06:48:23.110Z |  |
| 54 | 107 | deviation | scripts/quality/Assert-Policy.ps1 |  | Extended policy validation for the closed native CFF baseline contract. | open |  | 2026-07-29T10:33:33.738Z |  |
| 55 | 107 | deviation | scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 |  | Preserved closed JSON schema order through baseline round-trip. | open |  | 2026-07-29T10:33:34.282Z |  |
| 56 | 107 | deviation | scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 |  | Separated atomic temp content validation from clean current-input verification. | open |  | 2026-07-29T10:33:34.864Z |  |
| 57 | 107 | deviation | scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 |  | Corrected synthetic canonical timing and policy staging fixtures. | open |  | 2026-07-29T10:33:35.422Z |  |
| 58 | 107 | deviation | scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 |  | Canonicalized active power-scheme identity to its locale-independent GUID. | open |  | 2026-07-29T10:33:36.050Z |  |
| 59 | 107 | deviation | scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 |  | Made existing baseline replacement atomic under Windows PowerShell/.NET Framework. | open |  | 2026-07-29T10:33:36.615Z |  |
| 60 | 107 | deviation | .planning/STATE.md |  | Normalized stale Plan 05 activity and Phase ? decision labels after final Plan 06 state advancement. | open |  | 2026-07-29T10:34:38.319Z |  |
| 61 | 108 | unrun-verify | modules/mb-font/font/cff_admission.mbt |  | Exact mb-text native --deny-warn gate is blocked by pre-existing mb-font CFF unused-code warnings; all four functional target checks and focused tests pass. | open |  | 2026-07-29T21:24:41.065Z |  |
| 62 | 108 | deviation | modules/mb-text/text/contract_test.mbt |  | Replaced a malformed hand-transcribed test font with a deterministic valid fixture builder. | open |  | 2026-07-29T21:26:32.679Z |  |
| 63 | 108 | deviation | .planning/STATE.md |  | Repaired stale Plan: Not planned state so the SDK could advance Phase 108 from Plan 1 to Plan 2. | open |  | 2026-07-29T21:26:33.190Z |  |

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
  },
  {
    "id": 22,
    "kind": "deviation",
    "phase": "99",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "SDK advance left machine-readable plan position and continuity prose stale; normalized to completed 99-02 state.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T10:51:22.018Z",
    "resolved_at": null
  },
  {
    "id": 23,
    "kind": "deviation",
    "phase": "99",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Normalized stale final-phase progress prose and metrics after SDK advanced Plan 99-03 to verification.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T11:06:57.004Z",
    "resolved_at": null
  },
  {
    "id": 24,
    "kind": "deviation",
    "phase": "100",
    "file": "modules/mb-font/font/outline.mbt",
    "line": null,
    "description": "Accepted normative 0-3 byte zero glyph alignment padding with strict rejection coverage.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T14:47:22.500Z",
    "resolved_at": null
  },
  {
    "id": 25,
    "kind": "deviation",
    "phase": "100",
    "file": "fixtures/font/dejavu-sans-2.37/oracle.json",
    "line": null,
    "description": "Qualified U+034C as the supported composite while preserving the U+00E9 grid-rounding capability boundary.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T14:47:23.453Z",
    "resolved_at": null
  },
  {
    "id": 26,
    "kind": "deviation",
    "phase": "100",
    "file": "fixtures/font/qualification-cases.json",
    "line": null,
    "description": "Corrected staged one-short outline budget requested and limit expectations.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T14:47:24.109Z",
    "resolved_at": null
  },
  {
    "id": 27,
    "kind": "deviation",
    "phase": "100",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Normalized stale machine-readable plan position and Phase 100 decision attribution after SDK advancement.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T14:48:26.488Z",
    "resolved_at": null
  },
  {
    "id": 28,
    "kind": "deviation",
    "phase": "100",
    "file": "scripts/fixtures/Generate-FontQualification.ps1",
    "line": null,
    "description": "Corrected generated scalar expectations from UInt64 to the public glyph_for_scalar Int input type.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T15:59:11.669Z",
    "resolved_at": null
  },
  {
    "id": 29,
    "kind": "deviation",
    "phase": "100",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Synchronized final Plan 6 of 6 verification state after stale SDK metadata output.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T15:59:12.307Z",
    "resolved_at": null
  },
  {
    "id": 30,
    "kind": "deviation",
    "phase": "106",
    "file": "modules/mb-font/font/cff_admission_wbtest.mbt",
    "line": null,
    "description": "Updated exact CFF retained-ledger expectations for 32-byte bounds-plus-command slots",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T19:31:08.387Z",
    "resolved_at": null
  },
  {
    "id": 31,
    "kind": "deviation",
    "phase": "106",
    "file": "modules/mb-font/font/font_test.mbt",
    "line": null,
    "description": "Reclassified static CFF1 OTTO as supported in legacy capability fixtures",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T19:31:08.887Z",
    "resolved_at": null
  },
  {
    "id": 32,
    "kind": "deviation",
    "phase": "106",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Normalized SDK-generated Phase 106 decision labels and stale execution prose after plan advancement",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T19:32:15.560Z",
    "resolved_at": null
  },
  {
    "id": 33,
    "kind": "deviation",
    "phase": "106",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Normalized stale Plan 01 activity and Plan 02 next-step prose after 106-02 state advancement",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T19:51:31.058Z",
    "resolved_at": null
  },
  {
    "id": 34,
    "kind": "deviation",
    "phase": "106",
    "file": "modules/mb-font/font/collection_test.mbt",
    "line": null,
    "description": "Retargeted legacy unsupported-profile assertions after CFF1 became selectable",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T20:27:41.878Z",
    "resolved_at": null
  },
  {
    "id": 35,
    "kind": "deviation",
    "phase": "106",
    "file": "modules/mb-font/font/font.mbt",
    "line": null,
    "description": "Preserved the collection capability error boundary for selected CFF1",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T20:27:42.376Z",
    "resolved_at": null
  },
  {
    "id": 36,
    "kind": "deviation",
    "phase": "106",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Normalized SDK-generated Phase 106 completion metadata",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T20:27:42.867Z",
    "resolved_at": null
  },
  {
    "id": 37,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/fixtures/Provision-CffQualificationTools.ps1",
    "line": null,
    "description": "Avoided redundant full SDK inventory scans inside one-field negative mutations.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T02:47:33.943Z",
    "resolved_at": null
  },
  {
    "id": 38,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/fixtures/Test-CffQualificationContracts.ps1",
    "line": null,
    "description": "Corrected dynamic PowerShell splatting so every named validation mode executes.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T02:47:34.500Z",
    "resolved_at": null
  },
  {
    "id": 39,
    "kind": "deviation",
    "phase": "107",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Normalized SDK-emitted Phase ? decision labels to Phase 107 after state advancement.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T02:47:56.180Z",
    "resolved_at": null
  },
  {
    "id": 40,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/fixtures/Generate-FontQualification.ps1",
    "line": null,
    "description": "Source Sans 3.052R retained license comes from the exact official tag URL because the OTF release ZIP omits LICENSE.md",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T03:08:12.959Z",
    "resolved_at": null
  },
  {
    "id": 41,
    "kind": "deviation",
    "phase": "107",
    "file": ".gitattributes",
    "line": null,
    "description": "Path-specific -text rule preserves the exact upstream CRLF Source Sans license bytes",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T03:08:13.551Z",
    "resolved_at": null
  },
  {
    "id": 42,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/quality/Assert-Policy.ps1",
    "line": null,
    "description": "Fixture policy synchronized to six new licensed qualification records and the live Phase 106 collection digest",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T03:08:14.152Z",
    "resolved_at": null
  },
  {
    "id": 43,
    "kind": "deviation",
    "phase": "107",
    "file": "modules/mb-font/font/cff_type2.mbt",
    "line": null,
    "description": "Corrected Type 2 hint substitution after path start for licensed CFF outlines",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T05:31:38.613Z",
    "resolved_at": null
  },
  {
    "id": 44,
    "kind": "deviation",
    "phase": "107",
    "file": "modules/mb-font/font/cmap.mbt",
    "line": null,
    "description": "Accepted recognized cmap companion records used by licensed qualification fonts",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T05:31:39.122Z",
    "resolved_at": null
  },
  {
    "id": 45,
    "kind": "deviation",
    "phase": "107",
    "file": "fixtures/font/cff-qualification-cases.json",
    "line": null,
    "description": "Reconciled canonical nonempty GIDs and source locators with executable evidence",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T05:31:39.655Z",
    "resolved_at": null
  },
  {
    "id": 46,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/fixtures/Generate-FontQualification.ps1",
    "line": null,
    "description": "Added exact one-shot materializers for planned private evidence regions",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T05:31:40.166Z",
    "resolved_at": null
  },
  {
    "id": 47,
    "kind": "deviation",
    "phase": "107",
    "file": "modules/mb-font/font/cff_type2_fixture_wbtest.mbt",
    "line": null,
    "description": "Replaced backend-specific Array capacity lock with portable live-frame semantics",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T05:31:40.662Z",
    "resolved_at": null
  },
  {
    "id": 48,
    "kind": "deviation",
    "phase": "107",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Normalized stale SDK-generated Phase 107 Plan 04 execution metadata",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T05:32:44.798Z",
    "resolved_at": null
  },
  {
    "id": 49,
    "kind": "deviation",
    "phase": "107",
    "file": ".planning/phases/107-hostile-licensed-and-four-target-qualification/107-05-SUMMARY.md",
    "line": null,
    "description": "Corrected PowerShell array composition in focused assertions",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T06:47:16.409Z",
    "resolved_at": null
  },
  {
    "id": 50,
    "kind": "deviation",
    "phase": "107",
    "file": ".planning/phases/107-hostile-licensed-and-four-target-qualification/107-05-SUMMARY.md",
    "line": null,
    "description": "Refreshed the live Phase 103 collection corpus semantic lock",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T06:47:16.998Z",
    "resolved_at": null
  },
  {
    "id": 51,
    "kind": "deviation",
    "phase": "107",
    "file": ".planning/phases/107-hostile-licensed-and-four-target-qualification/107-05-SUMMARY.md",
    "line": null,
    "description": "Removed a false-positive CFF2 flow heuristic",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T06:47:17.594Z",
    "resolved_at": null
  },
  {
    "id": 52,
    "kind": "deviation",
    "phase": "107",
    "file": ".planning/phases/107-hostile-licensed-and-four-target-qualification/107-05-SUMMARY.md",
    "line": null,
    "description": "Synchronized documentation changes with exact policy file identities",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T06:47:18.126Z",
    "resolved_at": null
  },
  {
    "id": 53,
    "kind": "deviation",
    "phase": "107",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Normalized stale SDK-generated Phase 107 Plan 05 execution metadata",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T06:48:23.110Z",
    "resolved_at": null
  },
  {
    "id": 54,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/quality/Assert-Policy.ps1",
    "line": null,
    "description": "Extended policy validation for the closed native CFF baseline contract.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T10:33:33.738Z",
    "resolved_at": null
  },
  {
    "id": 55,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1",
    "line": null,
    "description": "Preserved closed JSON schema order through baseline round-trip.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T10:33:34.282Z",
    "resolved_at": null
  },
  {
    "id": 56,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1",
    "line": null,
    "description": "Separated atomic temp content validation from clean current-input verification.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T10:33:34.864Z",
    "resolved_at": null
  },
  {
    "id": 57,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1",
    "line": null,
    "description": "Corrected synthetic canonical timing and policy staging fixtures.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T10:33:35.422Z",
    "resolved_at": null
  },
  {
    "id": 58,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1",
    "line": null,
    "description": "Canonicalized active power-scheme identity to its locale-independent GUID.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T10:33:36.050Z",
    "resolved_at": null
  },
  {
    "id": 59,
    "kind": "deviation",
    "phase": "107",
    "file": "scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1",
    "line": null,
    "description": "Made existing baseline replacement atomic under Windows PowerShell/.NET Framework.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T10:33:36.615Z",
    "resolved_at": null
  },
  {
    "id": 60,
    "kind": "deviation",
    "phase": "107",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Normalized stale Plan 05 activity and Phase ? decision labels after final Plan 06 state advancement.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T10:34:38.319Z",
    "resolved_at": null
  },
  {
    "id": 61,
    "kind": "unrun-verify",
    "phase": "108",
    "file": "modules/mb-font/font/cff_admission.mbt",
    "line": null,
    "description": "Exact mb-text native --deny-warn gate is blocked by pre-existing mb-font CFF unused-code warnings; all four functional target checks and focused tests pass.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T21:24:41.065Z",
    "resolved_at": null
  },
  {
    "id": 62,
    "kind": "deviation",
    "phase": "108",
    "file": "modules/mb-text/text/contract_test.mbt",
    "line": null,
    "description": "Replaced a malformed hand-transcribed test font with a deterministic valid fixture builder.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T21:26:32.679Z",
    "resolved_at": null
  },
  {
    "id": 63,
    "kind": "deviation",
    "phase": "108",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Repaired stale Plan: Not planned state so the SDK could advance Phase 108 from Plan 1 to Plan 2.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T21:26:33.190Z",
    "resolved_at": null
  }
]
````
