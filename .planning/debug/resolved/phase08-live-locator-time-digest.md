---
status: resolved
trigger: "Phase 08 Plan 08-07 PrepareAttempt creates a live locator, but Open-P08BoundaryStore rejects it with P08-BOUNDARY-LOCATOR-DIGEST after JSON reload"
created: 2026-07-19
updated: 2026-07-19
---

# Debug Session: Phase 08 Live Locator Time Digest

## Symptoms

- Expected: A locator written by PrepareAttempt at boundary `09548df/r1` reopens with the same digest.
- Actual: Any later `Open-P08BoundaryStore` mode fails with `P08-BOUNDARY-LOCATOR-DIGEST: Locator digest drifted`.
- Reproduction: Write a live locator whose `created_at_utc` originates from `git show %cI` with a non-UTC offset, reload it through `ConvertFrom-Json`, then open the boundary store.
- Constraints: Do not modify tags, origin, StateRoot, or hosted-run state; do not read secrets or publish.

## Current Focus

reasoning_checkpoint:
  hypothesis: `Get-P08BoundaryLocatorProjection` causes locator digest drift because its `DateTime` branch appends a literal `Z` to local wall-clock fields instead of converting the represented instant to UTC.
  confirming_evidence:
    - The source directly shows `DateTime.ToString('yyyy-MM-ddTHH:mm:ssZ')`, while the other branch calls `DateTimeOffset.Parse(...).UtcDateTime.ToString(...)`.
    - On `China Standard Time`, the same `2026-07-19T04:08:31+08:00` input projected as `2026-07-18T20:08:31Z` from string/DateTimeOffset but `2026-07-19T04:08:31Z` after JSON reload to `System.DateTime`.
  falsification_test: A write/reload fixture would disprove the hypothesis if the pre-fix digest remained stable or if explicit UTC conversion of only the `DateTime` branch did not make all three representations project identically.
  fix_rationale: Converting `DateTime` to UTC before applying the canonical `Z` format makes both runtime branches hash the same instant rather than their representation-specific wall-clock fields.
  blind_spots: The direct reproduction is on a non-UTC Windows timezone; adjacent live-locator projection code is separate and is outside the reported boundary-locator failure.
next_action: None; the regression and adjacent matrices passed independent session-manager verification.

## Evidence

- timestamp: 2026-07-19T00:00:00+08:00
  observation: `git show %cI` supplied `2026-07-19T04:08:31+08:00`; the string projection normalized it to `2026-07-18T20:08:31Z`, but JSON reload yielded a local `DateTime` that was formatted as `2026-07-19T04:08:31Z`.
  implication: Digest input changes solely because the runtime representation changes during JSON serialization/deserialization.
- timestamp: 2026-07-19T00:05:00+08:00
  observation: The debug knowledge base has no entry with overlapping locator, timestamp, JSON, or digest-drift symptoms; common-pattern review identifies Date format mismatch and Type/Coercion as the relevant candidates.
  implication: There is no known-pattern shortcut; the recorded representation-normalization hypothesis must be tested directly.
- timestamp: 2026-07-19T00:06:00+08:00
  observation: Codebase-memory graph tools are not available in this session, and the first whole-file read exceeded the tool output limit.
  implication: Repository instructions permit a text-search fallback; inspect the exact projection and test seams in bounded line ranges.
- timestamp: 2026-07-19T00:08:00+08:00
  observation: `Get-P08BoundaryLocatorProjection` line 327 formats a `DateTime` directly with a literal `Z`; line 328 parses every non-`DateTime` representation as `DateTimeOffset`, converts it through `UtcDateTime`, and then formats it.
  implication: The code has two normalization contracts for one digest field; a JSON-reloaded `DateTime` can encode local wall-clock time as though it were UTC.
- timestamp: 2026-07-19T00:10:00+08:00
  observation: The focused pre-fix test returned string=`2026-07-18T20:08:31Z`, DateTimeOffset=`2026-07-18T20:08:31Z`, and JSON-reloaded DateTime=`2026-07-19T04:08:31Z`; the reloaded value was `System.DateTime`, Kind Local.
  implication: The hypothesis is confirmed by direct, representation-only reproduction with no locator content changes.
- timestamp: 2026-07-19T00:12:00+08:00
  observation: The new `Test-Phase08LiveSeam.ps1` write/reload fixture failed before the production change with `P08-BOUNDARY-LOCATOR-TIME` after the preceding adapter fixtures passed.
  implication: The regression test is red and isolates the reported boundary locator time/digest seam.
- timestamp: 2026-07-19T00:14:00+08:00
  observation: After adding `ToUniversalTime()` only to the `DateTime` branch, the unchanged `Test-Phase08LiveSeam.ps1 -PreflightOnly` fixture passed together with the existing live adapter and workflow fixtures.
  implication: The minimal fix makes the original representation/digest regression green without disturbing the focused seam.
- timestamp: 2026-07-19T00:16:00+08:00
  observation: `Test-ReleasePublisherNegative.ps1` passed its reducer and controller recovery matrices; `Test-PreparedReleaseBundle.ps1` passed its deterministic selector and adversarial fail-closed matrix.
  implication: Adjacent publisher and prepared-bundle behavior remains intact.
- timestamp: 2026-07-19T00:17:00+08:00
  observation: `git diff --check` passed, and the owned diff contains only the one-line UTC normalization plus the 13-line regression fixture; no other tracked file is part of this fix.
  implication: The change is minimal, scoped, and ready for session-manager review.

## Eliminated

- hypothesis: Boundary revision or locator content other than time changed.
  reason: The reported drift occurs immediately after reload of the locator created for the same `09548df/r1` boundary.

## Resolution

- root_cause: `Get-P08BoundaryLocatorProjection` treated JSON-reloaded local `DateTime` values as already UTC by formatting them with a literal `Z`, while its string/DateTimeOffset path normalized the same instant to UTC. The canonical digest projection therefore changed solely when `ConvertFrom-Json` changed the runtime representation.
- fix: Convert `DateTime` locator timestamps to UTC before applying the canonical `yyyy-MM-ddTHH:mm:ssZ` format, and add a write/reload fixture that checks string, DateTime, DateTimeOffset, and digest equality for a non-UTC timestamp.
- verification: RED before fix: `Test-Phase08LiveSeam.ps1 -PreflightOnly` failed at `P08-BOUNDARY-LOCATOR-TIME`. GREEN after fix: the same command passed live adapter and workflow fixtures. Adjacent `Test-ReleasePublisherNegative.ps1` and `Test-PreparedReleaseBundle.ps1` both passed, and `git diff --check` reported no errors.
- files_changed: [scripts/quality/Invoke-Phase08HostedRun.ps1, scripts/quality/Test-Phase08LiveSeam.ps1]
