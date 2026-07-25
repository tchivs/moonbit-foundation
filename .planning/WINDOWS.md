---
schema_version: 1
open_count: 5
waived_count: 0
fixed_count: 0
total_count: 5
last_updated: 2026-07-25T17:25:16.084Z
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
  }
]
````
