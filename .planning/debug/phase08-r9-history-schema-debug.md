---
status: awaiting_human_verify
trigger: "按 GSD debug 流程调查并修复：Plan 08-24 的凭据无关 PrepareAttempt 在 r9 clean clone / InitializeBoundary 后、创建 active locator 之前，被 StrictMode 对历史 r8 记录读取缺失 prepare_job_id 和 prepare_attempt_completed 阻断。r9 tag 已存在且不可重用；不需要也绝不允许任何 tag/push/dispatch/凭据读取/PublishOne/registry mutation。你不是独占代码库：只负责与该历史读取合同直接相关的脚本、测试及一个新的 .planning/debug/phase08-r9-history-schema-*.md（若流程需要）；不得修改/暂存用户既有脏文件（.planning/config.json、治理 docs、.codebase-memory、research-plan-input/cache）或回退别人的改动。科学方法确定根因，添加回归测试后作最小 fail-closed 的兼容修复，运行相关 PrepareAttempt/qualification/prelive 回归并原子提交；说明为何历史字段缺失是已验证 r8 终止证据而不允许降低其他历史完整性。报告根因、提交、测试和任何偏差。"
created: 2026-07-19T07:59:53Z
updated: 2026-07-19T08:47:00Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: "The exact r8 legacy-property inventory plus immutable record digest and pre-locator failure stage accepts the one attested r8 terminal schema and rejects mutations."
test: "Self-verification is complete; preserve the external no-tag/no-dispatch constraint and await parent/orchestrator confirmation that no real r9 workflow should be attempted because r9 already exists."
expecting: "The strict and prelive regressions remain green while no human or automated process reuses the r9 tag or performs a credential/registry operation."
next_action: "Report the verified root cause, scoped changes, passing regressions, and the unrelated qualification ZIP-fixture limitation to the parent agent."
reasoning_checkpoint:
  hypothesis: "New-P08PreparedAttempt reads post-r8 fields directly under caller-enforced StrictMode; r8's protected record intentionally predates and omits them, so the read throws before the exact terminal proof can be evaluated."
  confirming_evidence:
    - "The committed r8 policy record has neither prepare_job_id nor prepare_attempt_completed, while its protected record digest is 8a7729234a62425d0082a7b7a4615f2757ab4bc59938925b8ca031e2e00c10c8."
    - "The direct strict-mode regression is RED with `The property 'prepare_job_id' cannot be found on this object` before its controlled Invoke-P08Git sentinel and without an active locator."
    - "The r9 zero-write pre-live fixture independently accepts and asserts r8 as a pre-locator, no-run, zero-downstream terminal record."
  falsification_test: "If the exact property inventory already includes either post-r8 field, or a direct strict-mode test still throws before its pre-git sentinel after replacing direct dereferences, this hypothesis is false."
  fix_rationale: "The fix recognizes only the immutable r8 record's exact legacy property inventory and digest; it does not make fields generally optional, so unknown/mutated history remains rejected before any side effect."
  blind_spots: "The full HostedRun qualification fixture has a different invocation scope and therefore does not itself trigger the caller-enforced StrictMode exception; the direct regression covers that scope, while the public fixture verifies normal PrepareAttempt completion."

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: "A credential-free PrepareAttempt in an r9 clean clone proceeds through InitializeBoundary and creates the active locator before any network, credential, tag, push, dispatch, PublishOne, or registry mutation operation."
actual: "StrictMode blocks before active-locator creation because an imported historical r8 record lacks prepare_job_id and prepare_attempt_completed."
errors: "StrictMode historical-record validation rejects missing prepare_job_id and prepare_attempt_completed in r8 history."
reproduction: "Run Plan 08-24's credential-free PrepareAttempt/prelive path in an r9 clean clone after InitializeBoundary, with historical r8 records present and before active-locator creation."
started: "Observed during Plan 08-24 r9 clean-clone prelive/PrepareAttempt qualification."

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-07-19T07:59:53Z
  checked: "Initial repository status and active debug-session inventory."
  found: "The worktree contains unrelated user changes only in .planning/config.json, governance docs, .codebase-memory, and research inputs/cache; none will be modified or staged."
  implication: "The fix must be isolated to history-read-contract scripts/tests plus this debug record."
- timestamp: 2026-07-19T08:02:00Z
  checked: "Knowledge base, r8 pre-live session, and repository-wide identifier search."
  found: "The knowledge base has no two-keyword match. The r8 session proves a historical eight-record view is intentional, and current qualification explicitly binds r9 PrepareAttempt to r8 history. Release-intent tests show prepare_job_id and prepare_attempt_completed are fields asserted for r6/r7, indicating a schema-evolution boundary rather than a general optional-field policy."
  implication: "Data-shape/schema-evolution and strict-field-inventory checks are the primary fault-tree branch; compatibility must be narrow to the attested r8 terminal shape."
- timestamp: 2026-07-19T08:07:00Z
  checked: "r8 policy object, New-P08PreparedAttempt implementation, and zero-write R9 pre-live fixture."
  found: "The committed r8 object has no prepare_job_id or prepare_attempt_completed properties, while New-P08PreparedAttempt dereferences both under StrictMode. Test-Phase08R9PreLive passes using the same r8 fixture and explicitly verifies its exact pre-locator zero-downstream terminal fields. A direct function probe stopped at its caller-binding guard, so it did not test the schema branch."
  implication: "The observed r8 shape is real and independently authorized; reproduce through the public InitializeBoundary -> PrepareAttempt path to test the exact read order."
- timestamp: 2026-07-19T08:11:00Z
  checked: "Public InitializeBoundary -> PrepareAttempt reproduction using an isolated state root and no PrepareProvider."
  found: "The public path fails with `The property 'prepare_job_id' cannot be found on this object` and no active locator exists. This occurs before Invoke-P08Git, provider materialization, credentials, network, dispatch, or registry operations."
  implication: "The strict missing-property dereference is the direct and reproducible blocking mechanism, not tag state, credentials, provider behavior, or active-locator collision."
- timestamp: 2026-07-19T08:15:00Z
  checked: "Initial execution of Test-Phase08Qualification after adding its regression."
  found: "The no-argument test exits through its default R8ContractOnly branch and does not invoke Assert-P08FixtureContract. The standalone StrictMode probe still fails on the missing r8 prepare_job_id."
  implication: "The apparent GREEN did not test PrepareAttempt; FixtureOnly is required for an unambiguous RED/GREEN result."
- timestamp: 2026-07-19T08:21:00Z
  checked: "Test-Phase08Qualification -FixtureOnly after adding the no-tag seam."
  found: "FixtureOnly reaches New-P08PreparedAttempt, but the script invocation scope does not reproduce the caller-enforced StrictMode property failure; it proceeds to a deliberately narrow git stub and fails on an unrelated `status --porcelain=v1 --untracked-files=all` read."
  implication: "The public fixture is suitable for GREEN end-to-end verification once its read-only git stub delegates safe local reads, but a direct strict-scope regression is required to protect the precise root cause."
- timestamp: 2026-07-19T08:25:00Z
  checked: "New Test-Phase08PrepareHistorySchema strict-mode regression before production change."
  found: "RED: it reports `expected the pre-git sentinel ... got The property 'prepare_job_id' cannot be found`, proving the original strict read blocks the exact r8 record before any git or locator operation."
  implication: "Root cause meets the action threshold: mechanism is understood, reliably reproduced, and alternatives involving tags, credentials, providers, or locator state are contradicted by execution order."
- timestamp: 2026-07-19T08:34:00Z
  checked: "Focused strict-mode regression after replacing the two reported missing-field reads."
  found: "It next fails on missing hosted_preflight_dispatched. The exact committed r8 inventory also omits that post-r8 field."
  implication: "The root mechanism is confirmed more strongly: all r8 post-schema direct reads must be excluded. The exact inventory and immutable digest remain the fail-closed compatibility boundary."
- timestamp: 2026-07-19T08:39:00Z
  checked: "Focused strict-mode regression after removing all r8-absent direct reads."
  found: "It now fails closed with P08-PREPARE-HISTORICAL-BINDING because the code expects failure_stage=prepare_attempt_local_canonical_archive_validation, while the immutable r8 record attests prepared_bundle_raw_archive_validation_before_locator."
  implication: "This is a second, independent schema-evolution mismatch. The exact r8 digest confirms the actual stage is the protected terminal evidence; accepting the later-stage value would either reject r8 or redefine its history."
- timestamp: 2026-07-19T08:47:00Z
  checked: "Focused strict-mode regression, default r8 qualification contract, r9 zero-write pre-live fixture, PowerShell parsing, and diff whitespace."
  found: "Test-Phase08PrepareHistorySchema passes its exact legacy-r8 positive path and added-field/digest-drift negative paths. Test-Phase08Qualification default R8ContractOnly and Test-Phase08R9PreLive pass. All three edited PowerShell files parse and git diff --check passes."
  implication: "The root cause is fixed and fail-closed regression protection is in place without tag, push, dispatch, credential read, PublishOne, or registry mutation."
- timestamp: 2026-07-19T08:47:00Z
  checked: "Test-Phase08Qualification -FixtureOnly."
  found: "It reaches the credential-free PrepareProvider after historical validation, then fails P08-QUAL-PREPARE-RAW because the test's generated mb-core ZIP is considered canonical by the current toolchain rather than the fixture's required noncanonical input."
  implication: "The full qualification fixture was exercised and confirms the historical block is cleared; its later ZIP-fixture failure is unrelated and intentionally left outside this history-schema fix."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "New-P08PreparedAttempt applies a later history schema to protected r8 evidence: it directly dereferences post-r8 fields (prepare_job_id, prepare_attempt_completed, and hosted_preflight_dispatched) under StrictMode and, after those reads are avoided, compares r8's attested pre-locator failure_stage against a later PrepareAttempt-stage value. The immutable r8 terminal record intentionally omits the fields and attests prepared_bundle_raw_archive_validation_before_locator, so the reader blocks before any git read, provider work, or active-locator creation."
fix: "Recognize only the exact ordered r8 legacy-property inventory and immutable r8 record SHA-256; validate its attested prepared_bundle_raw_archive_validation_before_locator terminal stage; and retain all existing terminal-value and zero-counter checks. Added a strict-mode regression and made the existing PrepareAttempt qualification fixture inject the r9 peel/read response instead of creating a local tag."
verification: "PASS: strict-mode positive and mutation-negative regression; default r8 qualification contract; r9 zero-write pre-live; PowerShell parser; git diff --check. FixtureOnly PrepareAttempt reaches the post-history provider but stops on an unrelated current-toolchain ZIP-fixture canonicalization mismatch (P08-QUAL-PREPARE-RAW). No prohibited operation was run."
files_changed: [scripts/quality/Invoke-Phase08HostedRun.ps1, scripts/quality/Test-Phase08Qualification.ps1, scripts/quality/Test-Phase08PrepareHistorySchema.ps1, .planning/debug/phase08-r9-history-schema-debug.md]
