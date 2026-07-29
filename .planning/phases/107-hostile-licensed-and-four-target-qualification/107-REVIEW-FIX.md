---
phase: 107
fixed_at: 2026-07-29T16:55:29Z
review_path: .planning/phases/107-hostile-licensed-and-four-target-qualification/107-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 107：代码审查修复报告

**修复时间：** 2026-07-29T16:55:29Z
**源审查：** `.planning/phases/107-hostile-licensed-and-four-target-qualification/107-REVIEW.md`
**迭代：** 3

**摘要：**

- 范围内问题：2
- 已修复：2
- 已跳过：0

## 已修复问题

### CR-01：Type 2 hostile 行把无关 Budget 的 B8 当作实际操作观察

**状态：** fixed: requires human verification
**修改文件：** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `fixtures/font/cff-qualification-cases.json`, `benchmarks/font-cff/generated_cff_evidence.mbt`, `policy/foundation.json`
**提交：** `b780d3f3`, `824b84c5`
**应用的修复：** Type 2 与 semantic hostile 行现在先创建 caller/ancestor Budget，再把同一个 caller 传给真实 Type 2 staging 操作，并从这对对象直接采集操作前后的 B8。八个 Type 2 program 行和十个 semantic program 行不再使用预计算 VM 结果或事后创建的无关 Budget；mutation Type 2 fetch 也构造真实 mutable descriptor 并执行同一路径。生成 corpus、MoonBit evidence 与受管 source identity 随实现同步更新。

### CR-02：hostile 修复破坏 canonical source locator，并留下 21 行陈旧 private mirror

**状态：** fixed: requires human verification
**修改文件：** `fixtures/font/cff-qualification-cases.json`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `benchmarks/font-cff/generated_cff_evidence.mbt`, `scripts/fixtures/Generate-FontQualification.ps1`, `scripts/quality/Invoke-FontQualification.ps1`, `policy/foundation.json`
**提交：** `b780d3f3`, `816e09b5`, `824b84c5`
**应用的修复：** 重新物化全部 53 个 canonical source locator 和全部 53 个 private evidence mirror；缺少 mirror region marker 现在 fail closed。普通 generator `-Check` 与官方完整/`ContractOnly` 入口都会强制执行 locator/mirror canonical gate，并用临时副本验证陈旧 locator 与单字段 mirror 漂移均被拒绝。source identity 已更新到本轮提交后的精确内容。

## 验证

- PowerShell parser 对 `Generate-FontQualification.ps1` 与 `Invoke-FontQualification.ps1` 均通过。
- `Generate-FontQualification.ps1 -CheckPrivateEvidenceMirrors` 通过；独立核对 source locator 为 53/53、private mirror 为 53/53。
- `Generate-FontQualification.ps1 -Check` 通过，并明确执行陈旧 locator 与单字段 mirror 漂移负向探针；`Invoke-FontQualification.ps1 -ContractOnly` 通过闭合 gate。
- native focused hostile tracer 为 `1/1`，实际输出 53 个 hostile row。
- js、wasm、wasm-gc、native 四个独立 tracer 均通过：每目标完整 package `275/275`、hostile row `53/53`、runtime observation `4/4`。
- FontPolicy 通过；全目标 Moon 检查为 0 errors，仅有既有 unused/deprecated warnings。
- 完整 FontQualification lane 通过：js、wasm、wasm-gc、native 各 `275/275`，每目标 53/53 hostile row、4/4 runtime observation，records 与 comparison 的 errors 均为 null。
- 四目标 comparison 顺序严格为 `js, wasm, wasm-gc, native`，`equal: true`；最终 semantic SHA-256 为 `ad7d5e8842177249875c7d29436442c783ceab87ec2fd5d55694f8cb43887c38`。
- 按要求仅运行 baseline `-Audit`。它在执行 benchmark 前因既有未提交的 `.planning/config.json` 与本报告而按 clean-worktree 前置条件 fail closed；未运行、也未尝试 baseline `-Record`。

---

_Fixed: 2026-07-29T16:55:29Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
