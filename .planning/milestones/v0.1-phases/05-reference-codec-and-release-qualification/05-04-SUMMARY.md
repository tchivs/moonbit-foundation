---
phase: 05-reference-codec-and-release-qualification
plan: "04"
subsystem: public-example-consumers
tags: [moonbit, ppm, public-api, source-isolation, native-adapter]

requires:
  - phase: 05-reference-codec-and-release-qualification/05-03
    provides: Complete strict P6 decoder, encoder, and canonical conformance corpus
  - phase: 04-image-model-views-and-operations
    provides: Public flip operation and inspectable metadata disposition
provides:
  - Four-target public in-memory decode-transform-encode executable with exact digest evidence
  - Native CLI-shaped adapter with fully injected streams, options, limits, budget, diagnostics, and transform
  - Separate copied-source and unpublished-registry qualification outcomes
affects: [05-05-documentation, 05-07-release-qualification, QUAL-02, QUAL-03]

tech-stack:
  added: []
  patterns:
    - Executable example modules are nonpublication moon.work members with normal named dependencies
    - Source-isolation success and registry-resolution blocking are distinct machine-readable outcomes
    - Native command shape remains a capability-injected library seam with a memory-only main

key-files:
  created:
    - examples/ppm-portable/main/main.mbt
    - examples/ppm-native-cli/main/adapter.mbt
    - examples/ppm-native-cli/main/main.mbt
    - release/qualification/example-consumers-schema.json
  modified:
    - moon.work
    - scripts/quality/Test-PublicExamples.ps1
    - scripts/quality/Invoke-MoonQuality.ps1
    - scripts/quality/Assert-Policy.ps1

key-decisions:
  - "Use rolling257 modulo 1000000007 as the portable exact-byte digest, fixed to 806175100 for the canonical flipped output."
  - "Keep examples as named-dependency nonpublication workspace members and copy the complete source workspace for independent source-isolation proof."
  - "Classify the unchanged no-workspace downstream probe only as blocked_unpublished_namespace; do not fabricate artifact or registry consumption."

patterns-established:
  - "Public example qualification source-audits exact imports and rejects private or ambient capability tokens before execution."
  - "Every clean-source run executes both examples; the separate registry probe copies only the unchanged portable module manifest."

requirements-completed: [QUAL-02, QUAL-03]

coverage:
  - id: D1
    description: Portable MemoryReader to decode to horizontal flip to MemoryWriter encode executes with exact semantic evidence on all four targets.
    requirement: QUAL-02
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-PublicExamples.ps1 -Example portable -Mode workspace -Target all"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false
  - id: D2
    description: Native adapter receives every capability and policy input explicitly and handles one-byte Reader and Writer progress with exact counts and digest.
    requirement: QUAL-02
    verification:
      - kind: integration
        ref: "examples/ppm-native-cli/main/main.mbt; qualify report workspace_examples.native"
        status: pass
    human_judgment: false
  - id: D3
    description: Copied complete sources execute independently while unchanged named downstream dependencies honestly report the unpublished namespace blocker.
    requirement: QUAL-03
    verification:
      - kind: integration
        ref: "artifacts/release-qualification/examples.json#source_isolation and registry_resolution"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-07-17
status: complete
---

# Phase 5 Plan 4: Public Examples and Source-Isolation Qualification Summary

**Four-target public PPM transform consumer plus an injected Native adapter, qualified by exact output evidence, copied-source execution, and an honest unpublished-registry blocker**

## Performance

- **Duration:** 18 min
- **Completed:** 2026-07-17T01:18:05Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Added a public-only portable executable that decodes canonical P6 bytes, performs `flip_horizontal`, re-encodes, and verifies dimensions, exact 17-byte progress, five preserved metadata fields, and digest `806175100` on `js`, `wasm`, `wasm-gc`, and `native`.
- Added a Native CLI-shaped `transcode` seam that receives Reader, Writer, decode/encode options, codec limits, budget, diagnostics, and transform explicitly; its memory-only main proves one-byte progress in both directions.
- Added exact source/import and manifest audits, complete copied-source workspace execution, and a separate unchanged-manifest no-workspace probe whose only accepted result is `registry_resolution: blocked_unpublished_namespace`.
- Integrated example qualification into Required; the final lane passed with 197/197 tests on every required target and all interface/package/read-only gates.

## Task Commits

1. **Task 1 RED: Define failing public example qualification** - `72d546f` (test)
2. **Task 1 GREEN: Add portable PPM transform consumer** - `6b19a3b` (feat)
3. **Task 2 RED: Freeze isolation and registry outcomes** - `f9f00ba` (test)
4. **Task 2 GREEN: Qualify injected Native PPM adapter** - `9af54df` (feat)

## Files Created/Modified

- `examples/ppm-portable/` - Four-target named-dependency public executable.
- `examples/ppm-native-cli/` - Native injected adapter, short-progress doubles, and memory-only main.
- `scripts/quality/Test-PublicExamples.ps1` - Workspace execution, exact source audit, copied-source isolation, registry probe, and report writer.
- `release/qualification/example-consumers-schema.json` - Closed machine-readable outcome contract.
- `moon.work` and `scripts/quality/Assert-Policy.ps1` - Exact nonpublication example workspace membership.
- `scripts/quality/Invoke-MoonQuality.ps1` - Required example-consumer gate.
- `.gitignore` - Dynamic local qualification report exclusion.

## Decisions Made

- The portable digest is a checked byte-for-byte rolling digest with stable small-integer arithmetic, avoiding backend-specific crypto or overflow behavior inside the example.
- Workspace execution, copied-source execution, and registry dependency resolution remain three different claims; only the first two pass before publication.
- The Native wrapper injects memory doubles only. It does not own path, argument, environment, registry, seeker, or global capability policy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Registered examples as exact nonpublication workspace members**
- **Found during:** Task 1 workspace execution
- **Issue:** Independent example modules with normal named dependencies require workspace membership for honest local source resolution, while the existing policy allowed only the three publishable modules.
- **Fix:** Added both example modules to `moon.work` and extended the exact workspace-member assertion without adding them to the publication-module inventory.
- **Files modified:** `moon.work`, `scripts/quality/Assert-Policy.ps1`
- **Verification:** Foundation policy assertion and full Required passed.
- **Committed in:** `6b19a3b`, `9af54df`

**2. [Rule 3 - Blocking] Integrated and isolated dynamic qualification evidence**
- **Found during:** Task 2 qualification
- **Issue:** The planned report needs a persistent local path and Required ownership without becoming a tracked machine-specific release record.
- **Fix:** Added the exact Required stage and ignored only dynamic `artifacts/release-qualification/*.json` output while keeping its schema tracked.
- **Files modified:** `.gitignore`, `scripts/quality/Invoke-MoonQuality.ps1`
- **Verification:** Full Required completed read-only with the report present.
- **Committed in:** `9af54df`

**Total deviations:** 2 blocking qualification integrations. **Impact:** No public module API, codec behavior, publication inventory, or artifact-consumer claim changed.

## Issues Encountered

- MoonBit disallows error-raising `assert_eq` directly in `main`; each executable instead computes one complete validity predicate and prints the success record only when all semantic checks hold. The qualification script rejects any alternate output.

## User Setup Required

None.

## Verification

- Portable workspace example: passed on all four targets.
- Native adapter: passed on Native with one-byte Reader and Writer progress.
- Copied complete-source workspace: `source_isolation: pass`.
- No-workspace unchanged named-dependency probe: `registry_resolution: blocked_unpublished_namespace`.
- `moon check --target all --deny-warn --frozen`: passed.
- `pwsh -NoProfile -File scripts/quality.ps1 -Lane Required`: passed with 197/197 tests per target and read-only tracked checkout proof.

## Self-Check: PASSED

- All planned example, quality, and schema artifacts exist.
- Commits `72d546f`, `6b19a3b`, `f9f00ba`, and `9af54df` resolve in repository history.
- No TODO, FIXME, placeholder, private import, ambient host access, exact mb-image artifact consumer, or fabricated registry pass remains.

## Next Phase Readiness

- Plan 05-05 can document both verified public examples and the exact target/support matrix.
- Later release qualification can consume the frozen schema while preserving the unpublished downstream registry blocker.

---
*Phase: 05-reference-codec-and-release-qualification*
*Completed: 2026-07-17*
