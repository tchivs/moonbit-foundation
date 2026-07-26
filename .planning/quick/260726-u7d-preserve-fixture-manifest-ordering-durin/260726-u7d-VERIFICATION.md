---
quick_id: 260726-u7d
verified: 2026-07-26T13:53:00Z
status: passed
score: 5/5 must-haves verified
commit: 3e8229ff1e236b04849b22a3b93fa90830477dae
evidence:
  - "Manifest self-test exited 0 and printed: PPM manifest self-test passed."
  - "Image -Check and PPM -Check both exited 0 against canonical artifacts."
  - "Fixture policy exited 0 and printed: Fixture identity and containment matrix passed."
  - "Manifest and generated PPM Moon hashes were unchanged by all focused no-write checks."
  - "Commit 3e8229f changes only scripts/fixtures/Generate-PpmVectors.ps1."
gaps: []
---

# Quick 260726-u7d Verification

**Goal:** Preserve fixture manifest ordering during PPM vector regeneration.

**Verdict:** PASSED. The source implementation, production self-test, focused IMAG sequence, and fixture-policy check independently support every plan must-have. SUMMARY claims were not treated as proof.

## Must-Have Verification

| # | Must-have | Status | Evidence |
|---|---|---|---|
| 1 | PPM regeneration replaces its owned manifest record at its existing position and never moves foreign records. | VERIFIED | `Merge-PpmManifestRecord` walks the existing array in order, emits the canonical PPM record at the encountered index, and passes every foreign object through directly. The manifest renderer calls this helper. Canonical order remains Image, PPM, QOI, PNG, Color, SVG; PPM `-Check` accepts the byte-identical manifest. |
| 2 | A duplicate PPM record fails with its exact ID; a missing PPM record is appended deterministically. | VERIFIED | The helper throws `Duplicate owned PPM manifest record ID 'ppm-p6-conformance-vectors'.` on the second owned record and appends the canonical record only when unseen. The production self-test exercises both paths and passes. |
| 3 | The production merge helper has a no-write self-test for duplicate, missing, identity/order, and idempotence behavior. | VERIFIED | `Invoke-ManifestSelfTest` calls the production helper in memory and asserts the exact duplicate error, missing append, foreign reference identity, serialized values, replacement index, and two-pass logical identity. It exited 0 and printed the required success marker. |
| 4 | Two complete PPM generations are byte-idempotent and `-Check` passes. | VERIFIED | The self-test applies the complete-input merge twice and compares serialized output. The focused production `-Check` regenerated expected manifest and Moon content in memory and accepted both canonical files. SHA-256 remained `1b4707387339e2b339915575f2c040650074c51fb98989e5b6b3d697c32a3e7d` for the manifest and `da850ec87313a0a5168d2d42460e26e02c5c18f2898d2fc17cfd6f31c03efedb` for generated PPM Moon code. |
| 5 | The Required IMAG generated-evidence sequence accepts both Image and PPM artifacts. | VERIFIED | `Generate-ImageVectors.ps1 -Check` exited 0 and reported all Image artifacts byte-identical; the immediately following `Generate-PpmVectors.ps1 -Check` exited 0. |

## Artifact and Wiring Checks

| Artifact / link | Status | Evidence |
|---|---|---|
| `scripts/fixtures/Generate-PpmVectors.ps1` | VERIFIED | Exists, contains substantive merge and self-test logic, matches commit `3e8229f`, and contains no TODO/FIXME/XXX/TBD/HACK/PLACEHOLDER markers. |
| `260726-u7d-SUMMARY.md` | VERIFIED | Exists with complete frontmatter, source commit, hashes, and focused verification records; intentionally uncommitted as required by the plan. |
| PPM generator → `fixtures/manifest.json` | WIRED | The normal production path passes `manifest.records` and the canonical PPM record to `Merge-PpmManifestRecord`, then serializes the returned records into the generated manifest. |

## Focused No-Write Checks

| Check | Result |
|---|---|
| `Generate-PpmVectors.ps1 -ManifestSelfTest` | PASS, exit 0 |
| `Generate-ImageVectors.ps1 -Check` | PASS, exit 0 |
| `Generate-PpmVectors.ps1 -Check` | PASS, exit 0 |
| `Test-FixturePolicy.ps1` | PASS, exit 0; identity and containment matrix passed |
| Hash comparison before/after all checks | PASS; manifest and generated PPM Moon hashes unchanged |
| Commit and worktree scope | PASS; commit changes only the PPM generator; focused checks created no source or fixture diff |
| `git diff --check` | PASS |

## Adversarial Review

- The former PPM/Color extraction and reassembly path is removed; no global sort or foreign-record regrouping remains.
- Foreign objects are retained by reference, and the self-test checks both reference identity and serialized values.
- Duplicate detection is fail-closed and exact-ID-specific.
- The helper is wired into production manifest rendering rather than existing only as test code.
- Full Required was intentionally not run, per verification scope.

## Gaps

None.

_Verifier: gsd-verifier_
