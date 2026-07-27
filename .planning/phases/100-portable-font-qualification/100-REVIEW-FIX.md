---
phase: 100-portable-font-qualification
fixed_at: 2026-07-27T19:21:57Z
review_path: .planning/phases/100-portable-font-qualification/100-REVIEW.md
iteration: 14
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 100: Code Review Fix Report

**Fixed at:** 2026-07-27T19:21:57Z
**Source review:** `.planning/phases/100-portable-font-qualification/100-REVIEW.md`
**Iteration:** 14

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0
- Review status: re-review required; the source review was not marked passed

The first thirteen iterations resolved the original findings, target-platform
blockers, mutable archive transport, installer-step shell binding, and an
initial hosted Required budget increase. Run `30296167480` proved immutable
installation, blocking POSIX containment, FontQualification, and LLVM on exact
commit `280a5462389f23a23b30e3285eb3946014b00279`. Required again produced no
test failure: at the 1200-second bound it had completed js, wasm, wasm-gc, and
most native work. Together with the earlier 900-second timeout and prior
approximately 12-minute success, this establishes substantial hosted-runner
variance and supports a final bounded budget sized for the observed tail.

## Fixed Issues

### WR-04 follow-up: Required CI budget expires during a healthy suite

**Files modified:** `.github/workflows/quality.yml`, `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Test-QualityWorkflowPolicy.ps1`
**Commit:** 8897f1c1
**Applied fix:** Only the Required job budget changed: its outer job timeout is
now exactly 35 minutes and the bounded wrapper timeout is exactly 1800 seconds.
The five-minute outer margin remains available for verified process-tree
cleanup and the unconditional diagnostic upload. The POSIX containment gate,
fail-closed wrapper semantics, and `if: ${{ always() }}` upload remain exact.
Structural policy binds the pair and rejects one-sided changes, proportional
drift, an inverted or zero cleanup margin, expansion of either non-Required
job, a non-fail-closed Required step, conditional upload, or removal of the
POSIX gate.

## Verification

- Run `30294583132` passed immutable installation in all three jobs, POSIX
  containment, FontQualification, and LLVM. Its Required diagnostic artifact
  `8664537914` (ZIP SHA-256
  `c3df95eef517f47d14cab58b507fc1292c052b243ea922c1d39974d2df2aa329`)
  reported `timed_out=true`, `exit_code=null`, `process_tree_terminated=true`,
  `termination_status=session-terminated-verified`, and `status=failure`.
  Its stdout contained many passing summaries, including `1112/1112`, and was
  still in wasm execution at termination.
- Run `30296167480` again passed immutable installation in all three jobs,
  POSIX containment, FontQualification, and LLVM. Required artifact
  `8665274582` (ZIP SHA-256
  `08f7151557b4e2e7989b337eba8e21b6a117b187db1eba49817be8cf44a6fc6f`)
  reported the same pure bounded result at 1200 seconds:
  `timed_out=true`, `exit_code=null`, `process_tree_terminated=true`,
  `termination_status=session-terminated-verified`, and `status=failure`.
  Stdout completed js, wasm, and wasm-gc, repeatedly reported `1112/1112`,
  completed most native work, and stopped near the independent native-module
  tail without a test failure.
- Run `30292283329` previously completed the same full Required lane in about
  12 minutes. The final 30-minute inner bound retains meaningful finite
  control while accommodating both observed hosted timeouts; the 35-minute
  outer bound retains five minutes for containment verification and artifact
  upload.
- Content-addressed workflow policy matrix: canonical pass plus 43 negative
  cases. New budget cases reject independent outer or inner drift, paired
  drift, cleanup-margin inversion, non-Required expansion, fail-open execution,
  conditional diagnostics, and POSIX-gate removal.
- PowerShell parser checks, exact structural workflow checks, and scoped
  `git diff --check`: passed.
- Windows Job Object regression passed; the fresh one-second Required wrapper
  exited nonzero as expected with `timed_out=true`, `exit_code=null`,
  `process_tree_terminated=true`, `termination_status=job-terminated-verified`,
  and `status=failure`.
- Per instruction, no direct full local Required run was attempted for this
  budget-only iteration.
- Full FontQualification lane: focused outline `1/1`, focused hostile `1/1`, and font package `103/103` on every target.
- Four evidence records: `pass=true`, 11 hostile outcomes each, `comparison.equal=true`, normalized only by `target,runner`.
- Semantic SHA-256: `65b63177ed296ffa4cb1f46a4c6943d6036a71d70eb1b8409830a35e65fcdef8`.
- A GitHub Actions rerun is required to prove the new 1800-second bounded
  Required budget on the hosted Ubuntu runner.

## Prior Iteration Commits

- `d62238b0` — CR-01 exact format-6 cmap length validation.
- `cd2c5790` — CR-02 initial managed evidence boundary.
- `778fa907` — CR-03 initial tracked timeout cleanup.
- `5086de0a` — CR-04 exact focused hostile evidence gate.
- `7661bbbd` — WR-01 current oracle version.
- `e54c67af` — WR-02 exact CI toolchain pin.
- `b947f160` — residual CR-02 link/junction containment.
- `db895c83` — residual CR-03 ancestry tracker verification.
- `d3aa3f56` — residual CR-03 Windows Job Object containment.
- `e8010df2` — residual CR-03 POSIX session containment.
- `39ebeee9` — WR-02 content-addressed CI transport.
- `5e287b04` — WR-02 Linux execute modes and identity array capture.
- `02460c90` — WR-02 scoped staged identity `PATH`.
- `0204d19c` — WR-02 exact current core archive layout.
- `e4164861` — WR-02 isolated core archive promotion.
- `902db958` — WR-02 verified core bundle generation.
- `b1b2cb67` — WR-02 exact executable/data toolchain manifest.
- `f01a8cef` — WR-03 immutable release asset transport.
- `7ecb34b6` — WR-04 exact installer-step shell binding.
- `280a5462` — WR-04 initial Required CI timeout budget.

---

_Fixed: 2026-07-27T19:21:57Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 14_
