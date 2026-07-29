---
phase: 107-hostile-licensed-and-four-target-qualification
reviewed: 2026-07-29T13:47:20Z
depth: standard
files_reviewed: 37
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
  critical: 3
  warning: 0
  info: 0
  total: 3
status: issues_found
---

# Phase 107：代码复审报告

**审查时间：** 2026-07-29T13:47:20Z
**深度：** standard
**审查文件：** 37
**状态：** issues_found

## Summary

复审覆盖原 36 个 Phase 107 源文件以及本轮新增的 runtime oracle，并检查 `d494a489..f9704660` 与七个修复提交。原 CR-01 已关闭：AFDKO 路径现在独立解析 ROS、FDArray 和 FDSelect，并与 fontTools 对 CID keying、ROS、FD 数量/选择结果做严格 agreement。原 CR-04 也已关闭：四目标分别执行 MoonBit runtime tracer，实际输出摘要进入 equality-bearing `runtime_observations`。

只读验证中，生成器 `-Check`、FontQualification `-ContractOnly`、native baseline `-Audit` 和 font policy gate 均通过；已提交四目标 evidence 的文件摘要相符、`equal=true`，每个目标有四个实际 runtime observation。这些 gate 没有发现下面三项真实性与数据安全缺陷。结论仍是 **BLOCKER**：原 CR-02、CR-03、CR-05 未关闭，当前证据不能用于发布资格。

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01：53 行 hostile coverage 仍由测试名推断，未逐行执行 canonical outcome

**Classification:** BLOCKER  
**File:** `scripts/quality/Invoke-FontQualification.ps1:893-929`
**Related:** `fixtures/font/cff-qualification-cases.json:602-605`; `modules/mb-font/font/cff_type2_fixture_wbtest.mbt:542-582`

**Issue:** Runner 从每行 `source` 提取文件名和测试名，只要该测试恰好通过一次，就无条件把该行的 `outcome_bound`、`publication_bound` 和 `b8_bound` 全部设为 `true`。53 行实际上只映射到 21 个不同测试。更直接的反例是 `mutation-selected-face` 与 `mutation-final-commit` 都映射到 542 行的 staging 测试，但该测试只验证两 glyph 的访问顺序、charge 和未提交 budget；它没有注入 selected-face 或 final-commit revision mutation，也没有比较 canonical row 的 category/code/operation/payload/context/GID/publication/B8。于是这些 mutation 行未执行仍被 evidence 宣称完全绑定，其他共享测试名的行也有同样问题。

**Fix:** 为 53 个 canonical row 建立显式 dispatcher。每行必须触发对应入口和故障窗口，收集真实 outcome/publication/caller+ancestor B8，再逐字段与该行比较。Runner 应消费每行产生的唯一 row ID 和 observed payload，而不是从通过的测试名推断覆盖：

```powershell
if ($observed.id -cne $row.id -or
    (ConvertTo-CanonicalJson $observed.outcome) -cne
    (ConvertTo-CanonicalJson $row.outcome)) {
  throw "Hostile row observation drifted: $($row.id)"
}
```

### CR-02：baseline Record 仍复制 corpus 摘要，没有散列该次 benchmark 的实际输出

**Classification:** BLOCKER  
**File:** `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1:440-477`
**Related:** `benchmarks/font-cff/cff_bench.mbt:76-88,136-143`

**Issue:** `Get-CffBenchmarkWorkloads` 直接把 corpus 的 `correctness_output_sha256` 复制为 baseline 的 `correctness_sha256`。Benchmark 本身只把该 corpus 字符串与另一个生成常量比较；outline workload 对运行结果只要求 `path.length() > 0`。它从未序列化或散列本次 native 运行产生的 mappings、metrics、path commands 和坐标。因此路径坐标等实际输出发生回归但仍非空时，`-Record` 会继续发布不变的“correctness”摘要。新四目标 tracer 确实散列了真实输出，但 baseline 录制通道既不调用该 tracer，也未把 tracer 源纳入自身 source identity，不能替代此处缺失的观察。

**Fix:** 在 warmup/timing 之前用与计时 workload 相同的 native 实现生成稳定序列化输出，对该次输出计算 SHA-256，并与独立 oracle 摘要严格比较；baseline 只保存这个 observed digest。将共享 serializer/tracer 源加入 baseline source inventory，避免 benchmark 与资格 tracer 漂移。

### CR-03：可捕获的发布失败会删除已覆盖的 canonical qualification，造成数据丢失

**Classification:** BLOCKER  
**File:** `scripts/fixtures/Generate-FontQualification.ps1:5963-5995`

**Issue:** Provenance 更新先用 `Move-Item -Force` 覆盖每个 canonical `qualification.json`，并把目标加入 `$published`。若第二个替换、manifest 替换或注入 failpoint 随后抛出普通异常，catch 会删除 `$published` 中的目标，而不是恢复覆盖前的文件。结果是原本有效的 canonical qualification 被永久删除。新增 durable journal 处理进程终止窗口，但没有保护这个 provenance 文件替换路径的普通异常；因此原 CR-05 的“失败保持旧状态/可恢复事务”保证仍不成立。

**Fix:** 将两个 qualification 和 manifest 纳入同一个 journaled replace 协议。覆盖前保留同卷 backup，并在 journal 中记录精确允许的目标、旧/新摘要和步骤；每步 flush 后推进 journal。捕获异常时恢复旧文件，重启时幂等 roll-forward 或 rollback。任何 catch 都不得简单删除一个已存在并被覆盖的 canonical destination。

---

_Reviewed: 2026-07-29T13:47:20Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
