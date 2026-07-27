---
status: resolved
trigger: "The current-HEAD Required quality lane fails in COLR deterministic generated evidence after a negative Moon documentation check resolves README.missing.mbt.md from the wrong working directory, then reports fixtures/manifest.json as stale or non-deterministic."
created: 2026-07-27
updated: 2026-07-27
---

# Required COLR manifest working-directory regression

## Symptoms

- Expected: `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/phase97-canonical` completes with the exact `Required quality lane passed.` marker on the current Phase 97 HEAD.
- Actual: the lane reaches `COLR deterministic generated evidence`, a native Moon negative check fails while canonicalizing `README.missing.mbt.md`, and the stage then reports `fixtures/manifest.json` as stale or non-deterministic.
- Error: `Failed to canonicalize input filter directory README.missing.mbt.md` / `系统找不到指定的文件 (os error 2)`, followed by `Generated artifact is stale or non-deterministic: fixtures/manifest.json`.
- Timeline: reproduced after Phase 97 policy changes that anchored production Moon invocations for foreign-working-directory safety; the same Required lane passed at pre-Phase-97 commit `affe872`.
- Reproduction: from the repository root, run `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/phase97-canonical`.

## Current Focus

- bug_class: bohrbug
- reasoning_checkpoint:
    hypothesis: `Generate-PngStructuralVectors.ps1` causes the later COLR failure because its non-check manifest write preserves Windows CRLF from `ConvertTo-Json`, while every shared-manifest generator and `.gitattributes` require canonical LF bytes.
    confirming_evidence:
      - a fresh detached worktree starts with a 6033-byte LF-only manifest; one structural generation changes it to 6156 bytes with 123 CR bytes; the isolated color check then reproduces the exact manifest failure.
      - the active manifest and both structural generated tables share the writer timestamp, and the structural script's only manifest write passes raw `ConvertTo-Json` output to `WriteAllText`.
      - root/module cwd probes and manifest hashing prove the negative README fixture neither resolves incorrectly nor changes manifest state.
    falsification_test: if reverting only the canonical newline transformation still leaves a fresh-worktree structural-generation followed by color-check sequence passing, this root-cause hypothesis is wrong.
    fix_rationale: normalize CRLF and bare CR to LF and enforce exactly one terminal LF before writing the shared manifest; this fixes the producing boundary rather than weakening the byte-identical consumer check.
    blind_spots: verification cannot prove behavior on every PowerShell/runtime combination, but a platform-independent helper contract covers CRLF, LF, no-terminal-newline, and repeated-terminal-newline inputs.
    candidate_causes:
      - code: the structural PNG generator is the only shared-manifest writer that serializes raw `ConvertTo-Json` text without canonical newline normalization.
      - environment: Windows PowerShell emits CRLF JSON text, and Git's `text=auto eol=lf` clean filter masks the raw worktree byte drift from status.
    and_gate: yes — the failure requires the unnormalized writer and a runtime producing CRLF; Git filtering is an additional masking condition but is not required for the byte mismatch itself.
- integration_process:
    pid: 34208
    state: exited-success
    stdout: D:/AI-Data/temp/Admin/mnf-required-colr-full.stdout.log
    stderr: D:/AI-Data/temp/Admin/mnf-required-colr-full.stderr.log
- human_verification: approved — the exact automated Required command passed with the required success marker and 1048/1048 on all four targets.
- next_action: archive the resolved session, commit the verified code fix and debug records, and update the durable debug knowledge base.

## Evidence

- timestamp: 2026-07-27
  source: Required quality lane
  observation: governance, fixture provenance, source inventory, benchmark, compatibility, toolchain, foundation policy, source audits, core gates, and color vector regeneration passed before the COLR stage failed.
- timestamp: 2026-07-27
  source: Moon error chain
  observation: native `check` failed during build-plan calculation because `README.missing.mbt.md` could not be canonicalized; the stage surfaced the enclosing generated-artifact drift message for `fixtures/manifest.json`.
- timestamp: 2026-07-27
  source: project and agent skill discovery
  observation: the worktree has no project skill indexes or rules and the configured `gsd-debugger` agent-skills query returned empty; repository rules require graph-first code discovery and preserving the unrelated untracked 97-UAT and VPU summary files.
- timestamp: 2026-07-27
  source: codebase knowledge graph
  observation: graph search under the repository's nominal `moonbit-foundation` project returned no COLR/manifest/quality-stage symbols, so the active isolated worktree is not discoverable under that graph snapshot.
- timestamp: 2026-07-27
  source: active-worktree graph index
  observation: fast indexing completed with 14,253 nodes and 14,206 edges, but the index explicitly excludes `scripts/`, `fixtures/`, and generated build directories; the only broad COLR/manifest search hit was the branch node, so repository rules permit literal search for the PowerShell call path.
- timestamp: 2026-07-27
  source: debug knowledge recall
  observation: no MemPalace recall tool was available and `.planning/debug/knowledge-base.md` is absent, so there is no prior-resolution candidate to privilege.
- timestamp: 2026-07-27
  source: literal symptom search
  observation: `Invoke-MoonQuality.ps1:437` invokes the negative README check with `-C modules/mb-core check README.missing.mbt.md`; line 1052 owns the COLR stage; `Generate-ColorVectors.ps1:95` emits the misleading stale/non-deterministic error and line 524 emits `fixtures/manifest.json`.
- timestamp: 2026-07-27
  source: SBFL precondition check
  observation: SBFL is skipped because the failing integration path has no per-test coverage spectrum with both passing and failing tests; deterministic call-path tracing and differential reproduction remain applicable.
- timestamp: 2026-07-27
  source: full call-path reading
  observation: `quality.ps1` anchors the process at repository root; `Assert-CoreQualificationNegativeFixtures` accepts any exception from `moon -C modules/mb-core check README.missing.mbt.md`; after that stage returns, the COLR stage independently calls `Generate-ColorVectors.ps1 -Artifacts all -Check`.
- timestamp: 2026-07-27
  source: full generator reading
  observation: the color generator anchors paths to its own repository root, reads the existing manifest only to preserve/replace records, renders expected bytes entirely in memory, and throws the stale/non-deterministic message only after a direct byte comparison; it never invokes Moon or consumes the README error.
- timestamp: 2026-07-27
  source: isolated negative README experiment
  observation: the exact root-cwd Moon command deterministically returns the reported canonicalization error but leaves `fixtures/manifest.json` byte-identical and clean, directly falsifying causation between the two events.
- timestamp: 2026-07-27
  source: isolated COLR generator check
  observation: both color vector JSON files are byte-identical and the check then fails immediately on `fixtures/manifest.json`; no README command participates, confirming an independent deterministic manifest mismatch.
- timestamp: 2026-07-27
  source: read-only expected-manifest render
  observation: expected SHA-256 is `1b4707387339e2b339915575f2c040650074c51fb98989e5b6b3d697c32a3e7d` at 6033 bytes while actual SHA-256 is `032c40b73ead826506187ce01d8f5d941e092097c042c63853820893c5fcff9d` at 6156 bytes; after CRLF normalization every line is identical and the 123-byte delta equals one extra CR per newline.
- timestamp: 2026-07-27
  source: newline and Git normalization inspection
  observation: the failing manifest has 123 CR bytes and 124 LF bytes while all passing generated artifacts have zero CR bytes; `.gitattributes` explicitly sets `* text=auto eol=lf`, but global `core.autocrlf=true` and Git's path-filtered hash equals HEAD, so `git status` masks the raw-byte CRLF mutation.
- timestamp: 2026-07-27
  source: pre-COLR fixture-policy write audit
  observation: `Test-FixturePolicy.ps1` writes only GUID-named temporary fixture roots and deletes them; other pre-COLR policy tests likewise target temporary copies. No Required-lane stage before COLR writes the repository manifest.
- timestamp: 2026-07-27
  source: differential commit history
  observation: between known-good `affe872` and current HEAD, neither `fixtures/manifest.json` nor any fixture generator changed; only `Invoke-MoonQuality.ps1` changed among the scoped quality/fixture files. The CRLF worktree bytes are therefore not encoded in the Phase 97 commit diff.
- timestamp: 2026-07-27
  source: Phase 97 invocation diff
  observation: the only `Invoke-MoonQuality.ps1` changes add library mode and root the generated-interface classifier; `Invoke-MoonCommand`, the negative README invocation, stage order, and `quality.ps1` cwd wrapper are unchanged from known-good `affe872`.
- timestamp: 2026-07-27
  source: root-versus-module Moon probes
  observation: `README.mbt.md` succeeds both via root `moon -C modules/mb-core` and module cwd, while `README.missing.mbt.md` fails with the identical canonicalization chain in both forms. `-C` resolves filters correctly and the missing-path failure is intentional.
- timestamp: 2026-07-27
  source: manifest reference and timestamp audit
  observation: Phase 97 artifacts record no fixture-generator invocation and explicitly state no fixture-manifest addition; the manifest was last modified at 2026-07-27 00:04:27 Asia/Shanghai, over five hours before known-good commit `affe872` and over eight hours before the only Phase 97 quality-script change.
- timestamp: 2026-07-27
  source: filesystem last-writer cohort
  observation: within five seconds of the manifest's last write, the only repository outputs modified were PNG decode vectors followed by `modules/mb-image/png/generated_vectors_test.mbt` and `generated_vectors_wbtest.mbt`; the latter two share the manifest's timestamp to the millisecond, directly identifying a non-check `Generate-PngStructuralVectors.ps1` run.
- timestamp: 2026-07-27
  source: disposable-worktree causal reproduction
  observation: current HEAD checked out with `before_bytes=6033 before_cr=0 before_lf=124`; running the structural generator changed it to `after_bytes=6156 after_cr=123 after_lf=124`, after which the color generator passed both color JSON files and failed exactly on `fixtures/manifest.json`.
- timestamp: 2026-07-27
  source: patched active-worktree regeneration
  observation: the structural generator's boundary self-tests passed, regeneration completed, and the shared manifest changed from 6156-byte CRLF to 6033-byte LF-only bytes (`cr=0`, `lf=124`); generated MoonBit tables remained unchanged.
- timestamp: 2026-07-27
  source: patched disposable-worktree target test
  observation: a fresh LF-only manifest remained exactly 6033 bytes with zero CR after structural regeneration, and the full color generator check passed all seven byte-identical artifacts including `fixtures/manifest.json`.
- timestamp: 2026-07-27
  source: adjacent manifest checks
  observation: PNG structural, PNG decode, Image, and PPM checks passed after LF normalization; QOI failed its raw manifest byte comparison, so guardrail acceptance is paused until that contract disagreement is classified and resolved.
- timestamp: 2026-07-27
  source: QOI baseline classification
  observation: a clean detached current-HEAD worktree also fails `Generate-QoiVectors.ps1 -Check` before any patch is applied (on its generated MoonBit output); therefore QOI is a pre-existing neighbor failure, not newly broken by this fix. Its manifest renderer already canonicalizes CRLF to LF.
- timestamp: 2026-07-27
  source: remaining guardrail checks
  observation: fixture-policy fail-closed matrix passed; the scoped diff is additive plus a targeted writer replacement with no behavior deletion and `git diff --check` passes; Stryker/dotnet-stryker and configuration are absent, so mutation testing is explicitly skipped.
- timestamp: 2026-07-27
  source: first full-lane integration attempt
  observation: the harness timed out after 904 seconds while the lane was in `WORK-05 workspace test target wasm`; it had already passed the repaired COLR stage and the complete JS target sequence. This is a bounded-run timeout, not a test failure.
- timestamp: 2026-07-27
  source: detached full-lane integration result
  observation: the exact original command reached terminal success with `Required quality lane passed.`; every workspace and independent module suite reported `Total tests: 1048, passed: 1048, failed: 0` on js, wasm, wasm-gc, and native.
- timestamp: 2026-07-27
  source: final worktree inspection
  observation: `fixtures/manifest.json` has no content diff after LF normalization; the only tracked code diff is the 21-addition/1-replacement structural generator fix, `git diff --check` passes, and the unrelated untracked 97-UAT and VPU summary remain untouched.
- timestamp: 2026-07-27
  source: human verification checkpoint
  observation: the user approved the fix after the exact automated Required command emitted `Required quality lane passed.` and reported 1048/1048 tests passing on js, wasm, wasm-gc, and native.

## Eliminated

- hypothesis: the negative README command mutates or influences `fixtures/manifest.json`, causing the later COLR mismatch.
  evidence: the isolated command reproduced the exact OS-path error with exit -1, while the manifest SHA-256 remained `032C40B73EAD826506187CE01D8F5D941E092097C042C63853820893C5FCFF9D` and tracked status remained clean before and after.
  timestamp: 2026-07-27
- hypothesis: a pre-COLR Required-lane fixture-policy helper rewrites the repository manifest with CRLF.
  evidence: the only manifest write in `Test-FixturePolicy.ps1` targets a unique temporary root; the production policy assertion only reads the repository manifest, and no pre-COLR generator stage writes it.
  timestamp: 2026-07-27
- hypothesis: a Phase 97 fixture-generator change introduced the CRLF manifest bytes.
  evidence: `git log` and `git diff affe872..HEAD` show no changes to the manifest or any fixture generator; only the quality invocation script changed in the scoped paths.
  timestamp: 2026-07-27
- hypothesis: Phase 97 changed the negative README invocation so its missing filter resolves from the wrong cwd and causes the COLR failure.
  evidence: the invocation and cwd wrapper are unchanged from known-good `affe872`; existing/missing filter probes behave identically from root-with-`-C` and module cwd, and the isolated failure does not alter the manifest.
  timestamp: 2026-07-27

## Resolution

- root_cause: "code: `Generate-PngStructuralVectors.ps1` writes raw platform-newline `ConvertTo-Json` text into the shared manifest; environment: Windows emits CRLF, producing raw bytes that violate the repository LF contract while Git filtering hides the drift"
- fix: "added a platform-independent canonical text helper with CRLF/LF/no-terminal/repeated-terminal boundary self-tests and routed the PNG structural manifest write through it"
- verification:
    target_test: { result: pass, detail: "fresh-worktree structural generation preserves LF and subsequent full Color check passes" }
    mutation_check: { result: skipped, reason_if_skipped: "no Stryker/dotnet-stryker configuration or executable for PowerShell", mutant_killed: null }
    no_op_deletion: { result: pass, deletion_justified_by_rca: false, detail: "additive helper/self-tests plus targeted writer routing; no behavior deletion" }
    adjacent_tests:
      result: pass
      suites_run:
        - "Generate-PngStructuralVectors.ps1 -Check"
        - "Generate-PngDecodeVectors.ps1 -Check"
        - "Generate-ImageVectors.ps1 -Check"
        - "Generate-PpmVectors.ps1 -Check"
        - "Test-FixturePolicy.ps1"
        - "exact Required quality lane"
      note: "QOI check is excluded as a pre-existing baseline failure reproduced on clean current HEAD before this patch"
    revert_and_reconfirm: { result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, detail: "unpatched fresh worktree writes 123 CR bytes and Color check fails; patched fresh worktree retains zero CR and Color check passes" }
    human_verification: { result: pass, detail: "user approved the exact automated Required command with the required success marker and 1048/1048 on all four targets" }
    guardrail_verdict: accepted
- files_changed: ["scripts/fixtures/Generate-PngStructuralVectors.ps1"]
- oracle_type: specified

## Prevention

- causal_branches:
    code:
      - the PNG structural generator passed raw `ConvertTo-Json` output directly to `WriteAllText`.
      - raw serialization made the shared manifest's byte format depend on the host newline convention.
      - raw-byte consumers require the repository's canonical LF representation, so equivalent JSON with CRLF was rejected.
    environment_and_config:
      - Windows PowerShell emitted CRLF in the serialized JSON.
      - `.gitattributes` and `core.autocrlf` normalized Git's indexed view, masking the divergent raw worktree bytes during ordinary status and hash inspection.
    and_gate: the unnormalized code path and a CRLF-emitting runtime jointly produced the failure; Git filtering masked the drift but was not required to create it.
- why_not_caught: the generator's existing checks covered fixture identity, digest, and generated tables but had no boundary contract for manifest newline bytes; Git normalization hid the raw-byte drift until a later deterministic generator compared the manifest.
- recurrence_guard: `Assert-CanonicalTextContract` in `scripts/fixtures/Generate-PngStructuralVectors.ps1` now exercises CRLF, LF, missing-terminal-newline, and repeated-terminal-newline inputs before every generation/check, while `ConvertTo-CanonicalText` enforces exactly one terminal LF at the manifest writer boundary.
