---
phase: 107-hostile-licensed-and-four-target-qualification
plan: 02
subsystem: testing
tags: [cff1, licensed-fixtures, source-sans, source-han-serif, provenance, fonttools, afdko, ots]

requires:
  - phase: 107-hostile-licensed-and-four-target-qualification
    plan: 01
    provides: Exact validated execution handoff, locked host manifest, pinned readers, OTS, and licensed intake contracts
provides:
  - Exact official Source Sans 3.052R name-keyed static CFF1 OTF and retained license
  - Exact official Source Han Serif JP 2.003R CID-keyed 18-FD static CFF1 OTF and retained license
  - Closed project-generated qualification/oracle documents and six authoritative manifest records
  - Offline-reconstructible atomic intake with handoff, archive, profile, reader, OTS, and provenance negatives
affects: [107-03, 107-04, 107-05, 107-06, CFF-06]

tech-stack:
  added: []
  patterns: [summary-bound execution handoff, link-free staged archive intake, two-bundle atomic publication, external-payload/generated-metadata classification]

key-files:
  created:
    - fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf
    - fixtures/font/source-sans-3.052r/LICENSE.md
    - fixtures/font/source-sans-3.052r/qualification.json
    - fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf
    - fixtures/font/source-han-serif-2.003r/LICENSE.txt
    - fixtures/font/source-han-serif-2.003r/qualification.json
  modified:
    - scripts/fixtures/Generate-FontQualification.ps1
    - fixtures/manifest.json
    - scripts/quality/Assert-Policy.ps1
    - .gitattributes

key-decisions:
  - "Every licensed intake/check entry point accepts only the literal 107-01 summary-bound handoff path and digest; ambient MNF_CFF_HOST_TOOLCHAIN_INPUT is ignored."
  - "Source Sans LICENSE.md is retained from the exact official 3.052R tag URL because the official OTF release ZIP contains the declared OTF but no license member."
  - "Two-reader agreement compares source/scalar/GID/metrics/bounds and ordered geometry after removing reader-specific contour-close rendering; keying and complete profile facts are validated independently."
  - "The four upstream OTF/license records remain external/OFL-1.1, while the two reconstructed qualification documents are project-generated/Apache-2.0 with explicit upstream cross-links."

patterns-established:
  - "Licensed intake validates both complete bundles and every host identity before any canonical destination changes."
  - "Read-only gates consume exact cached official inputs, run no network acquisition, and hash all canonical destinations before/after negatives."
  - "Generated qualification JSON contains no machine-local path and reconstructs byte-for-byte as LF UTF-8 without BOM."

requirements-completed: [CFF-06]

coverage:
  - id: D1
    description: The summary-bound handoff, safe archive transaction, exact static CFF1 profiles, two semantic readers, and structural OTS gate both licensed bundles before publication.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "Generate-FontQualification.ps1 -CheckIntakeContract/-CheckIntakeNegatives"
        status: pass
    human_judgment: false
  - id: D2
    description: Exact official Source Sans 3.052R and Source Han Serif JP 2.003R OTF/license bytes are tracked under their frozen lengths and SHA-256 identities.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "Generate-FontQualification.ps1 -Intake/-CheckLicensedIntake/-CheckOracleAgreement plus Git blob SHA audit"
        status: pass
    human_judgment: false
  - id: D3
    description: Two closed qualification documents and six ordered manifest records preserve external upstream attribution versus generated project metadata.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "Generate-FontQualification.ps1 -CheckProvenance and scripts/quality/Test-FixturePolicy.ps1"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-07-29
status: complete
---

# Phase 107 Plan 02: Atomic Licensed CFF Intake Summary

**Exact Source Sans 3.052R and 18-FD Source Han Serif JP 2.003R CFF1 assets with summary-bound atomic intake, independent semantic readers, structural OTS, and closed provenance**

## Performance

- **Duration:** 13 min
- **Started:** 2026-07-29T02:53:19Z
- **Completed:** 2026-07-29T03:06:40Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Promoted the exact 334,924-byte Source Sans and 6,210,796-byte Source Han Serif OTFs plus their exact retained licenses without subset, repack, derivative, or duplicated payload.
- Added a fail-closed two-bundle transaction that validates the exact 107-01 handoff, official inputs, link-free ZIP inventory, complete name/CID profiles, fontTools/AFDKO agreement, and OTS before publication.
- Added two machine-path-free qualification documents and six ordered manifest rows that keep upstream payloads external while classifying generator-rendered oracle metadata as project-authored Apache-2.0.

## Task Commits

Each TDD task was committed as RED then GREEN; the exact-payload promotion was one atomic task commit:

1. **Task 1: Prove staged Latin intake and close the two-specimen transaction** — `1ad008a2` (RED), `a1c9b733` (GREEN)
2. **Task 2: Promote the four exact upstream OTF and license files** — `0b63008d` (feat)
3. **Task 3: Commit closed provenance/oracles and synchronize the manifest** — `7a582fa8` (RED), `cbb1e4d0` (GREEN)

## Files Created/Modified

- `.gitattributes` — preserves the exact CRLF bytes of the Source Sans upstream license.
- `fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf` — exact official name-keyed CFF1 Latin specimen.
- `fixtures/font/source-sans-3.052r/LICENSE.md` — exact retained Source Sans 3.052R OFL-1.1 license bytes.
- `fixtures/font/source-sans-3.052r/qualification.json` — project-generated closed profile, lineage, reader, OTS, and host-chain facts.
- `fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf` — exact official CID-keyed 18-FD CFF1 CJK specimen.
- `fixtures/font/source-han-serif-2.003r/LICENSE.txt` — exact retained Source Han Serif 2.003R OFL-1.1 license bytes.
- `fixtures/font/source-han-serif-2.003r/qualification.json` — project-generated ROS, FDSelect, local/global Subr, high-GID, reader, OTS, and lineage facts.
- `fixtures/manifest.json` — preserves all 14 prior rows and appends four external plus two generated records.
- `scripts/fixtures/Generate-FontQualification.ps1` — owns handoff validation, offline staged checks, exact intake, oracle reconstruction, atomic publication, and manifest closure.
- `scripts/quality/Assert-Policy.ps1` — closes the fixture-policy allowlist over the six new records.

## Decisions Made

- Used only the ignored handoff at `artifacts/release-qualification/phase-107/107-01-host-toolchain-handoff.json` with SHA-256 `340e878b488ae3bec90a6b55c380d85cd33673611ce5258c4291d46ffc45dc3e`.
- Kept reader-specific glyph naming and contour-close formatting outside the agreement projection while retaining exact source, mapping, metric, bounds, and geometry equality; complete name/CID keying and FD facts remain separately exact.
- Preserved upstream authorship/licensing for the four payload/notice files and project authorship/Apache-2.0 only for the two generated qualification documents.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Source contract] Retained Source Sans license from the exact official tag**
- **Found during:** Task 1
- **Issue:** The official `OTF-source-sans-3.052R.zip` contains `SourceSans3-Regular.otf` but no `LICENSE.md` member, despite the planned archive-member wording.
- **Fix:** Bound the exact official tag URL `raw.githubusercontent.com/adobe-fonts/source-sans/3.052R/LICENSE.md`, retained the frozen 4,579-byte/SHA-256 identity, and required it in the same two-bundle transaction.
- **Files modified:** `scripts/fixtures/Generate-FontQualification.ps1`
- **Verification:** Offline intake contract and provenance reconstruction pass; the retained license digest is exact.
- **Committed in:** `a1c9b733`

**2. [Rule 2 - Integrity] Disabled Git text normalization for the exact Source Sans license**
- **Found during:** Task 2 post-commit blob audit
- **Issue:** Repository-wide `text=auto eol=lf` normalized the official CRLF license from 4,579 to 4,486 bytes in Git.
- **Fix:** Added a single-path `.gitattributes` `-text` rule and rebuilt the Task 2 commit so the Git blob retains the exact upstream bytes.
- **Files modified:** `.gitattributes`
- **Verification:** Git blob is 4,579 bytes with SHA-256 `89ad2c4f66dd29127527493e729c31e731f111cf10faf5774c3db9275ed0c22c`.
- **Committed in:** `0b63008d`

**3. [Rule 3 - Blocking policy drift] Synchronized fixture policy with the authoritative manifest**
- **Found during:** Task 3 verification
- **Issue:** `Test-FixturePolicy.ps1` rejected the required 20-row manifest because `Assert-Policy.ps1` still froze 14 rows; its Phase 103 collection-case digest was also stale after the tracked Phase 106 corpus update.
- **Fix:** Added the six exact Phase 107 records and synchronized the existing collection-case digest to the already tracked canonical file/manifest identity.
- **Files modified:** `scripts/quality/Assert-Policy.ps1`
- **Verification:** The full fixture identity/containment matrix passes.
- **Committed in:** `cbb1e4d0`

---

**Total deviations:** 3 auto-fixed (1 Rule 1, 1 Rule 2, 1 Rule 3).
**Impact on plan:** All fixes were required to retain exact upstream bytes and make the mandated fixture-policy verification authoritative; no runtime, API, evidence module, MoonBit carrier, or licensed payload scope was added.

## Issues Encountered

- The official Source Sans OTF archive omits the tag license, so the exact retained notice comes from the official immutable tag URL rather than an archive member.
- Git text normalization required a path-specific binary treatment before the license could be considered exact in repository history.

## TDD Gate Compliance

- Task 1: RED `1ad008a2` failed on the unimplemented intake gate; GREEN `a1c9b733` passed the contract, negative, and tracer feedback gates.
- Task 3: RED `7a582fa8` failed on missing qualification documents; GREEN `cbb1e4d0` passed exact provenance reconstruction and fixture policy.

## Known Stubs

None. Empty arrays and nulls in qualification profile facts are closed semantics for the name-keyed font's absent ROS/FD/high-GID fields, not placeholders.

## Authentication Gates

None.

## Threat Flags

No unplanned threat surface was introduced. Network acquisition, archive parsing, subprocess readers, OTS, filesystem staging, and atomic publication are all declared by T-107-02-01 through T-107-02-05 and covered by exact-digest, path/link/collision, tool-identity, reader-disagreement, and destination-preservation gates.

## User Setup Required

None. The exact validated 107-01 execution handoff remains the sole host-path authority.

## Next Phase Readiness

- Plan 107-03 can consume two immutable licensed fixture bundles and two closed qualification documents without network, tool discovery, or payload duplication.
- The CJK record freezes Adobe/Identity/0, all FDs 0-17, exact local/global Subrs, and non-empty GID 17922 on FD 17.

## Self-Check: PASSED

All ten changed implementation/artifact files, the SUMMARY, five task commits, exact Git blob identities, and the complete plan verification suite were confirmed after summary creation.

---
*Phase: 107-hostile-licensed-and-four-target-qualification*
*Completed: 2026-07-29*
