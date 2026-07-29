---
phase: 107-hostile-licensed-and-four-target-qualification
reviewed: 2026-07-29T16:17:06Z
depth: standard
files_reviewed: 38
files_reviewed_list:
  - fixtures/font/cff/host-toolchain.lock.json
  - fixtures/font/cff-oracle-tools.json
  - fixtures/font/cff-qualification-cases.json
  - scripts/fixtures/Provision-CffQualificationTools.ps1
  - scripts/fixtures/oracles/fonttools_cff_oracle.py
  - scripts/fixtures/oracles/fonttools_cff_runtime_oracle.py
  - scripts/fixtures/oracles/Invoke-AfdkoCffOracle.ps1
  - scripts/fixtures/Generate-FontQualification.ps1
  - fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf
  - fixtures/font/source-sans-3.052r/LICENSE.md
  - fixtures/font/source-sans-3.052r/qualification.json
  - fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf
  - fixtures/font/source-han-serif-2.003r/LICENSE.txt
  - fixtures/font/source-han-serif-2.003r/qualification.json
  - fixtures/manifest.json
  - scripts/quality/Assert-Policy.ps1
  - .gitattributes
  - benchmarks/font-cff/moon.mod.json
  - benchmarks/font-cff/moon.pkg
  - benchmarks/font-cff/generated_cff_evidence.mbt
  - benchmarks/font-cff/cff_qualification_wbtest.mbt
  - benchmarks/font-cff/cff_runtime_semantics.mbt
  - modules/mb-font/font/cff_cid_fixture_wbtest.mbt
  - modules/mb-font/font/cff_hostile_fixture_wbtest.mbt
  - modules/mb-font/font/font_qualification_test.mbt
  - scripts/quality/Invoke-FontQualification.ps1
  - scripts/quality/Test-FontQualificationEvidenceBoundary.ps1
  - policy/foundation.json
  - .github/workflows/quality.yml
  - modules/mb-font/moon.mod.json
  - modules/mb-font/README.mbt.md
  - modules/mb-font/CHANGELOG.md
  - docs/policies/licensing-and-fixtures.md
  - docs/benchmarks/mb-font-cff-native-release-baseline.md
  - benchmarks/moon.work
  - benchmarks/font-cff/cff_bench.mbt
  - scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1
  - scripts/quality/Test-BenchmarkQualification.ps1
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 107：代码复审报告（迭代 3）

**审查时间：** 2026-07-29T16:17:06Z
**深度：** standard
**审查文件：** 38
**状态：** issues_found

## Summary

本轮覆盖原 36 个 Phase 107 文件、第二轮加入的 runtime oracle，以及本轮新增的共享 runtime serializer；检查了 `919edff4..f975345f` 和提交 `e00d3b62`、`7f4181ea`、`fd2c885a`、`edb03d37`、`8b0b937e`。

原 AFDKO 问题保持关闭：独立适配器仍从 CFF 字节解析 ROS、FDArray、FDSelect、used FD 和 selected FD。原四目标 runtime 问题也保持关闭：目标 tracer 实际序列化 mappings、metrics、bounds 和完整 path commands/坐标。Benchmark 修复闭合了同次调用输出、独立 fontTools oracle、严格四行顺序、八次一致性和 baseline 原始 payload；三文件 provenance transaction 也具备精确目标、old/new SHA、普通异常 rollback、FailFast roll-forward 和残留清理。本轮未在这两部分发现新的 Critical 或 Warning。

只读验证结果：generator `-Check`、provenance、FontQualification `-ContractOnly` 和 native focused tracer 均通过；native 实际为 `275/275`、53 hostile rows 和 4 runtime observations。专用 `-CheckPrivateEvidenceMirrors` 则立即失败。Baseline `-Audit` 未重跑，因为其 clean-tree gate 按设计拒绝 orchestrator 保留的 `.planning/config.json` 与 `107-REVIEW-FIX.md` 未暂存状态；已直接检查 committed baseline schema、八组原始输出及 digest 关系，未执行禁止的 `-Record`。

结论仍为 **BLOCKER**：hostile 修复把至少 19 行的 B8 绑定到未参与操作的预算，并且破坏了 canonical source/mirror gate；主资格运行仍错误地通过这两项。

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01：Type 2 hostile 行把无关 Budget 的 B8 当作实际操作观察

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:282-308`
**Related:** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:364-535,769-806`

**Issue:** `cff_qualification_observe_type2_row` 和前十个 semantic-limit 分支先通过 `type2_vm_wb_run*` / `type2_fixture_run` 完成真实 Type 2 操作，再把已经产生的 `Result` 传给 `cff_qualification_emit_type2_observation`。该 emitter 到此时才新建 ancestor/caller Budget，并立即读取其 before/after；这对 Budget 从未传入被观察的操作。`mutation-type2-fetch` 同样创建 caller/ancestor 后直接调用不接受该 Budget 的 VM，再输出未参与操作的 B8。因此至少 19 个 canonical row 的 outcome 来自真实操作，但 caller/ancestor B8 来自另一条无关状态线。全部值恰好保持 `[4096,32,16384,0,0,0,0,16384]`，所以 53-row comparison 与 native `275/275` 都会接受这项伪绑定。

**Fix:** 让 tracer 在创建 caller child 后，通过实际消费该 child 的 staging/admission/outline 入口执行每一行，再从同一 caller 与 ancestor 读取 after。不要接受预先计算的 `Result`：

```moonbit
fn observe_with_budget(
  run : (@budget.Budget) -> Result[Type2VmResult, @error.CoreError],
) -> Unit raise {
  let (ancestor, caller) = cff_qualification_standard_hostile_budget()
  let caller_before = caller.remaining()
  let ancestor_before = ancestor.remaining()
  let result = run(caller) // the observed operation must consume this child
  // emit result plus caller.remaining() and ancestor.remaining()
}
```

对纯 VM 边界应通过 `type2_stage_all_glyphs` 或实际 admission wrapper 连接 Budget；若某行定义上没有 B8 authority，则 corpus 必须显式表达不可适用，而不能制造一个未参与调用的 Budget 快照。增加一个负向探针，使 outcome 正确但 B8 来自另一 Budget 时必然失败。

### CR-02：hostile 修复破坏 canonical source locator，并留下 21 行陈旧 private mirror

**Classification:** BLOCKER
**File:** `fixtures/font/cff-qualification-cases.json:537-605`
**Related:** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1068,1655-1709`; `scripts/fixtures/Generate-FontQualification.ps1:4416-4436,6737-6747`

**Issue:** `e00d3b62` 在 hostile 文件既有测试之前插入了约 991 行 tracer，但 corpus 仍把 structural rows 指向旧 locator `cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases`；真实测试现在位于 1068 行。执行专用 `-CheckPrivateEvidenceMirrors` 会在第一行报 `source assertion locator drifted`。即使先修 locator，嵌入在 1655-1709 行的 `// hostile` private mirror 仍有 21/53 行与当前 corpus 不同，包括修复提交调整的 requested/limit/context/B8 值。主 `-Check` 只重建 generated evidence，未调用 `Assert-CffPrivateEvidenceMirrors`，所以 generator `-Check` 与 native focused tracer 都在 canonical source trace 已失效时通过。

**Fix:** 从真实测试符号重新生成全部 53 个 source locators，运行 `-MaterializePrivateEvidenceMirrors` 刷新整个 marker region，再要求：

```powershell
./scripts/fixtures/Generate-FontQualification.ps1 -CheckPrivateEvidenceMirrors
```

通过后才允许 qualification。将 `Assert-CffPrivateEvidenceMirrors` 纳入普通 `-Check`（以及 FontQualification 前置 gate），并增加 locator-shift 与单字段 mirror drift 负向探针，防止后续插入代码再次静默切断 canonical source trace。

---

_Reviewed: 2026-07-29T16:17:06Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
