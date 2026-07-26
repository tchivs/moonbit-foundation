---
quick_id: 260726-sss
phase: quick-260726-sss
plan: 01
description: Make the mb-core narrowing prohibition compiler-semantic and remove the two real CRC UInt64-to-Int calls
type: execute
wave: 1
depends_on: []
autonomous: true
files_modified:
  - "scripts/quality/Invoke-MoonQuality.ps1"
  - "modules/mb-core/crc/crc.mbt"
must_haves:
  truths:
    - "The core prohibition classifies every `.to_int()` call from compiler hover data instead of receiver-text heuristics."
    - "Byte, UInt16, Char, and Double conversions remain accepted; UInt64 conversion is accepted exactly once in checked/checked.mbt and rejected everywhere else."
    - "Hover failure, malformed JSON, an absent signature, an unknown receiver, or a second checked-package UInt64 call fails closed."
    - "The two CRC table-index conversions are provably bounded by `0xffUL`, narrow losslessly through Byte, and no longer resolve as UInt64::to_int."
    - "bits/bits.mbt remains unchanged because its receiver is Byte."
    - "The full Required quality lane passes in a detached disposable worktree before the parent governance quick is resumed."
  artifacts:
    - path: "scripts/quality/Invoke-MoonQuality.ps1"
      provides: "Compiler-semantic core narrowing classifier and fail-closed positive/negative matrix"
    - path: "modules/mb-core/crc/crc.mbt"
      provides: "CRC index expressions whose final to_int receiver is Byte after an explicit 0xff bound"
    - path: ".planning/quick/260726-sss-make-the-mb-core-narrowing-prohibition-t/260726-sss-SUMMARY.md"
      provides: "Execution and detached Required-lane evidence"
  key_links:
    - from: "scripts/quality/Invoke-MoonQuality.ps1"
      to: "moon ide hover"
      via: "Each real `.to_int()` token is resolved with `--no-check --output-json` after a deterministic mb-core semantic warm-up"
      pattern: "ide.*hover.*output-json"
    - from: "scripts/quality/Invoke-MoonQuality.ps1"
      to: "modules/mb-core/checked/checked.mbt"
      via: "The UInt64 signature classifier permits one exact canonical implementation site and asserts exact singleton cardinality"
      pattern: "UInt64::to_int"
    - from: "modules/mb-core/crc/crc.mbt"
      to: "crc32_table"
      via: "The low eight bits are converted UInt64 -> Byte -> Int before array indexing"
      pattern: "0xffUL.*to_byte.*to_int"
---

<objective>
Replace the false-positive lexical core narrowing gate with a compiler-semantic, fail-closed classifier, and remove the only two uncontrolled `UInt64::to_int` calls from CRC code.

Purpose: The Required lane currently stops at `bits.mbt` even though compiler hover proves that call is `Byte::to_int`. The repair must accept safe widening/conversion sites without weakening the ban on uncontrolled UInt64 backend narrowing.

Output: Two atomic source commits, a passing semantic negative matrix and mb-core target matrix, then a complete quick summary carrying detached Required-lane evidence.
</objective>

<execution_context>
@C:/Users/Admin/.codex/gsd-core/workflows/execute-plan.md
@C:/Users/Admin/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@AGENTS.md
@.planning/STATE.md
@scripts/quality/Invoke-MoonQuality.ps1
@modules/mb-core/checked/checked.mbt
@modules/mb-core/crc/crc.mbt
@modules/mb-core/bits/bits.mbt
@.planning/quick/260726-qdh-fix-required-quality-wrapper-lane-forwar/260726-qdh-PLAN.md

The failed detached Required run reached `CORE portable source and documentation prohibitions` after all preceding governance, RFC, toolchain, interface-baseline, and WORK-04 stages passed. The current source regex rejects every `.to_int()` outside checked.mbt, regardless of receiver type.

A read-only compiler-hover inventory resolved all 83 current mb-core calls: Byte=16, UInt16=56, Char=7, Double=1, UInt64=3. The UInt64 sites are checked/checked.mbt's guarded implementation plus crc/crc.mbt lines 46 and 59. `bits.mbt` resolves to Byte. `moon ide hover --no-check --output-json` resolves a cached site in about 0.1 seconds.

The parent quick `260726-qdh` remains paused. This quick does not edit its plan, summary, Phase 97 ledgers, WINDOWS.md, STATE.md, ROADMAP.md, or unrelated/untracked paths.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Replace the lexical ban with a compiler-semantic fail-closed classifier</name>
  <files>scripts/quality/Invoke-MoonQuality.ps1</files>
  <action>
Refactor the core `.to_int()` prohibition into two layers:

1. A pure signature policy helper that accepts the exact safe receiver signatures currently used (`Byte`, `UInt16`, `Char`, `Double`), records or accepts the one canonical `UInt64::to_int` only for `modules/mb-core/checked/checked.mbt`, and rejects UInt64 elsewhere plus unknown/missing signatures.
2. A real-source scanner that enumerates every `[.]to_int\s*\(` match, computes a one-based source location inside the `to_int` token, invokes the pinned toolchain's `moon ide hover --no-check --loc <relative-path:line:column> --output-json`, parses the first code signature, and feeds it to the pure policy helper.

Before semantic scanning, perform one deterministic native mb-core check/warm-up through the existing Moon command wrapper so `--no-check` never depends on a stale or absent IDE cache. For a regex match at zero-based absolute offset `match.Index`, compute `line = newline-count(prefix) + 1`, `lastNewline = prefix.LastIndexOf("`n")`, and a one-based column inside the method token as `match.Index - lastNewline + 1`; pass that exact location to hover. Treat nonzero hover exit, stderr-only output, invalid JSON, absent `contents`, or an unrecognized signature as a hard failure containing the relative source location. Count resolved UInt64 sites across the complete scan and assert exactly one canonical checked.mbt site.

Add a guarded, production-owned self-test entry to this script: an optional `-CoreNarrowingSelfTest` switch may be used without `-Lane`; when selected it runs the pure classifier matrix and exits without dispatching a quality lane. Otherwise `-Lane` remains required by an explicit fail-closed runtime check before `Invoke-MoonQuality`. The matrix must prove exact safe signatures are accepted and that UInt64-outside-checked, a second canonical UInt64 site, unknown signature, malformed/absent semantic data, and a simulated hover failure are rejected. Each negative assertion must match the expected narrowing-specific failure text, so an unrelated exception cannot satisfy it. Do not infer receiver types from local variable names or regexes.
  </action>
  <verify>
Run exactly:

`pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -CoreNarrowingSelfTest`

Require exit 0 and an explicit self-test success marker. Then run the production core scan and confirm the inventory resolves exactly Byte=16, UInt16=56, Char=7, Double=1, UInt64=3 before Task 2 and rejects the two CRC sites with the expected uncontrolled-UInt64 error. Run `git diff --check -- scripts/quality/Invoke-MoonQuality.ps1`. Commit only Task 1's quality-script change with quick ID `260726-sss`; do not include Task 2.
  </verify>
  <done>The semantic classifier distinguishes safe receiver types from UInt64, all uncertainty fails closed, and its negative matrix exercises the production policy helper.</done>
</task>

<task type="auto">
  <name>Task 2: Remove the two uncontrolled CRC UInt64-to-Int calls and qualify mb-core</name>
  <files>modules/mb-core/crc/crc.mbt</files>
  <action>
For each CRC table index, retain the local `& 0xffUL` mathematical bound and insert `.to_byte()` before `.to_int()`. This makes the UInt64-to-Byte step lossless by construction and the final backend-index conversion a widening `Byte::to_int`, without adding a package dependency or changing CRC's public API/error model.

Do not modify bits.mbt, checked.mbt, moon.pkg, generated interfaces, or unrelated core conversion sites. Use compiler hover to prove both edited CRC calls now resolve as `Byte::to_int` and the complete semantic inventory contains exactly one `UInt64::to_int`, at the canonical guarded checked.mbt site.

Run focused crc and bits tests and the full mb-core suite across js, wasm, wasm-gc, and native with the pinned/frozen toolchain. Commit only Task 2's CRC change in a second atomic commit with quick ID `260726-sss`; do not recommit Task 1.
  </action>
  <verify>
`moon ide hover --no-check --loc` reports `fn Byte::to_int(self : Byte) -> Int` for both CRC sites and bits.mbt. The production scanner reports one canonical UInt64 site. Run focused package tests with:

`moon -C modules/mb-core test crc --target all --frozen`

`moon -C modules/mb-core test bits --target all --frozen`

Then run this fail-fast full matrix:

`pwsh -NoProfile -Command '$ErrorActionPreference="Stop"; foreach($target in @("js","wasm","wasm-gc","native")) { & moon -C modules/mb-core test --target $target --frozen; if($LASTEXITCODE -ne 0){ throw "mb-core $target tests failed with exit $LASTEXITCODE" } }'`

Require every invocation to exit zero, then run `git diff --check`.
  </verify>
  <done>No uncontrolled UInt64-to-Int site remains, CRC behavior is unchanged, and mb-core passes all supported targets.</done>
</task>

<task type="auto">
  <name>Task 3: Prove the repository Required lane in isolation and record completion</name>
  <files>.planning/quick/260726-sss-make-the-mb-core-narrowing-prohibition-t/260726-sss-SUMMARY.md</files>
  <action>
Resolve the Task 2 SHA with `git rev-parse HEAD`. Create a detached disposable worktree using a GUID child under the explicit task root `[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-260726-sss'))`. The child leaf must match `required-[0-9a-f]{32}` and its full path must remain under that exact task root. Use `New-Item -ItemType Directory` only for the bounded task root, then `git worktree add --detach $worktree $task2Sha`.

Wrap qualification and cleanup in `try/finally`. From the exact worktree run:

`pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/local`

Capture combined output and the process exit code; require exit code 0 and the terminal message `Required quality lane passed.`. If a later unrelated gate fails, stop and report the new exact blocker without claiming this quick complete.

In `finally`, parse `git worktree list --porcelain` and require an exact normalized `worktree <path>` membership match before any cleanup. Revalidate the task-root containment and leaf regex, inspect `git -C $worktree status --porcelain`, and run `git worktree remove $worktree` only when all checks pass and the worktree is clean. If membership, containment, leaf, or cleanliness validation fails, preserve the worktree and report its exact path. Never call broad `git worktree prune`, never remove any other worktree, and never recursively delete a computed directory.

Write SUMMARY.md with `status: complete`, the two source commits, compiler-hover inventory, focused/all-target test results, and detached Required evidence. Do not commit SUMMARY.md or update STATE.md; the quick orchestrator owns verification and docs tracking.
  </action>
  <verify>SUMMARY frontmatter is complete, all referenced commits resolve, the detached command and success marker are recorded, and the main tracked worktree contains only the intended quick artifacts after source commits.</verify>
  <done>The complete Required lane passes from the committed source state and the quick is ready for independent verification.</done>
</task>

</tasks>

<verification>
- Production semantic classification is type-aware and fails closed on every unresolved/unknown case.
- The only remaining `UInt64::to_int` in mb-core is the guarded implementation in checked/checked.mbt.
- CRC and bits focused tests plus the complete mb-core four-target matrix pass.
- A detached full Required lane exits zero and prints its success marker.
- No qdh ledger, Phase 97, ROADMAP, unrelated worktree, or untracked user path is changed.
</verification>

<success_criteria>
- The original `bits.mbt` false positive is eliminated without exempting files or weakening UInt64 enforcement.
- Both real CRC UInt64 calls are gone and retain their exact low-byte behavior.
- Negative fixtures prove fail-closed semantics for UInt64, duplicate canonical sites, unknown signatures, and tool failure.
- The full Required lane passes from a clean detached checkout.
</success_criteria>

<output>
After completion, create `.planning/quick/260726-sss-make-the-mb-core-narrowing-prohibition-t/260726-sss-SUMMARY.md`.
</output>
