---
phase: 107-hostile-licensed-and-four-target-qualification
reviewed: 2026-07-29T10:45:26Z
depth: standard
files_reviewed: 36
files_reviewed_list:
  - fixtures/font/cff/host-toolchain.lock.json
  - fixtures/font/cff-oracle-tools.json
  - fixtures/font/cff-qualification-cases.json
  - scripts/fixtures/Provision-CffQualificationTools.ps1
  - scripts/fixtures/oracles/fonttools_cff_oracle.py
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
  critical: 5
  warning: 0
  info: 0
  total: 5
status: issues_found
---

# Phase 107：代码审查报告

**审查时间：** 2026-07-29T10:45:26Z  
**深度：** standard  
**审查文件：** 36  
**状态：** issues_found

## Summary

本次范围严格取自 107-01 至 107-06 六份 SUMMARY 的 `key-files.created`/`modified` 并集，过滤 `.planning/`、不存在文件、生成目录与忽略项后共 36 个文件。PowerShell AST、JSON、Python AST、生成器 `-Check`、资格与基准 `-ContractOnly`、MoonBit 格式检查均通过；这些检查没有覆盖下述五项证据真实性和崩溃一致性缺陷。

结论：当前提交不能作为 CFF-06 的可发布资格证据。两个“独立”读取器对 CID keying 的证明是假的；53 行 hostile 矩阵绝大部分没有执行；基准正确性摘要并未散列运行结果；四目标语义相等比较是同源常量的自比较；许可资产和来源台账存在进程终止后永久处于半发布状态的窗口。

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01：AFDKO 读取器把所有 CFF 都报告为 name-keyed，CID 证据与真实字体矛盾

**Classification:** BLOCKER  
**File:** `scripts/fixtures/oracles/Invoke-AfdkoCffOracle.ps1:240`  
**Related:** `scripts/fixtures/Generate-FontQualification.ps1:4999-5044`; `fixtures/font/source-han-serif-2.003r/qualification.json:41,424,603`

**Issue:** AFDKO adapter 无条件输出 `keying = 'name'`。同一 Source Han 字体的规范 profile 与 fontTools 结果均为 `cid`，但已提交 AFDKO projection 为 `name`。生成器的双读取器 agreement projection 又在 4999-5012 行刻意排除 `keying`，并在 5042-5044 行只校验 fontTools 的 keying，因此这个明确矛盾仍被记录为 `exact_normalized_agreement = true`。这使“两个独立语义读取器证明 CID-keyed multi-FD”这一核心资格事实失真。

**Fix:** 让 AFDKO 路径独立解析 CFF Top DICT 的 ROS（或使用固定版本 `tx` 的结构化输出）并生成真实 keying；把 `keying` 和 ROS 纳入两个读取器的 agreement projection，并分别对两侧执行 profile 校验。例如：

```powershell
$afdkoKeying = if ($ros) { 'cid' } else { 'name' }
if ($fontTools.keying -cne $Record.profile.keying -or
    $afdko.keying -cne $Record.profile.keying) {
  throw "Licensed CFF reader keying drifted: $($Record.id)"
}
```

修复后重新生成两份 `qualification.json`、载体、策略摘要和基准来源摘要。

### CR-02：所谓 53 行 hostile/mutation 矩阵主要只是字符串和注释，并未逐行执行

**Classification:** BLOCKER  
**File:** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:445-651`  
**Related:** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:664-717`

**Issue:** 445-526 行仅构造六组 ID 并检查数量总和为 53。随后实际执行的只有 8 个截断、2 个 Type2 错误和 1 个 work one-short；589-651 行虽声明 5 个 mutation window 和 B8 八维名称，却只触发 admission-opening 一个窗口。其余 canonical row 的 category/code/operation/payload/context/GID/publication 以及 caller/ancestor B8 before/after 都只存在于 664-717 行的 JSON 注释中，没有被测试消费或与实际结果比较。Focused runner 因此可以在绝大多数行发生回归时继续通过。

**Fix:** 把 53 行生成为有类型的测试数据并建立显式 dispatcher；每行必须调用对应真实入口，收集完整 outcome，再逐字段严格比较。维护 `visited_ids` 并断言其集合和顺序与 canonical 53 行完全一致。五个 mutation row 必须分别触发 admission-opening、selected-face、Type2-fetch、staged-path、final-commit，且逐维比较 caller/ancestor 的八个预算快照。

### CR-03：基准“正确性 SHA-256”只散列工作负载标签，不散列字体运行结果

**Classification:** BLOCKER  
**File:** `fixtures/font/cff-qualification-cases.json:476-519`  
**Related:** `benchmarks/font-cff/cff_qualification_wbtest.mbt:307-371`; `benchmarks/font-cff/cff_bench.mbt:59-88,136-143`; `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1:440-477,1188-1209`

**Issue:** 四个 `correctness_input_sha256` 都恰好是对应 `correctness_input` 描述字符串本身的 SHA-256。公开正确性测试对 full-admission 只检查 GID 列表为空，对 outline batch 只检查 `path.length() > 0`。基准脚本随后把这个输入标签散列原样改名为 `correctness_sha256` 写入基准。字体解析、high-GID FD 选择、metrics、路径命令或坐标即使产生错误，只要 outline 非空，这个“正确性”散列也完全不变。

**Fix:** 定义跨目标稳定的实际输出序列化格式：full-admission 至少包含公开 profile/映射/metrics 摘要；outline workload 必须包含每个固定 GID 的所有 path command 与坐标（以及需要冻结的 FD 观察）。在计时闭包外运行实现并对该输出计算 SHA-256，与独立 oracle 生成并冻结的期望摘要比较；baseline 中保存这个实际输出摘要，而不是输入描述摘要。

### CR-04：四目标语义相等比较比较的是同一份期望数据，不是四个后端的观察结果

**Classification:** BLOCKER  
**File:** `scripts/quality/Invoke-FontQualification.ps1:896-923`  
**Related:** `scripts/quality/Invoke-FontQualification.ps1:1000-1034,1090-1116,1455-1460`

**Issue:** 每个 target 的测试结束后，`New-FontQualificationEvidenceRecord` 都调用同一个 `Get-FontQualificationSemanticSections`，从仓库 fixtures、policy 和源文件重新构造全部 equality-bearing 字段；`focused_assertions` 也只是预先声明的测试名称。目标执行产生的唯一事实位于 `runner`，而比较前恰好删除 `target` 和 `runner`。所以只要四次命令退出成功，剩余 payload 天然逐字相同；比较器没有接收任何 JS/Wasm/Wasm-GC/native 的实际语义输出，无法发现后端分歧。

**Fix:** 让 MoonBit focused tests/专用 tracer 在每个后端输出同一 closed schema 的实际观察值，并由 runner 捕获、解析和写入 target record。比较时只规范化真正允许变化的 target/runner 元数据，保留并比较每个后端实际产生的 profile、public facts、hostile outcomes、B8 snapshots 和 correctness output digests；不要从 canonical 输入反向填充“观察结果”。

### CR-05：许可资产、qualification 和 manifest 的“原子发布”无法抵抗进程终止

**Classification:** BLOCKER  
**File:** `scripts/fixtures/Generate-FontQualification.ps1:5150-5234`  
**Related:** `scripts/fixtures/Generate-FontQualification.ps1:5666-5726`

**Issue:** 两个 specimen 目录在 5202-5205 行逐个 `Move-Item`，而异常回滚仅对可捕获异常有效；若进程在第一次 rename 后被终止，仓库会留下跨 bundle 半发布状态，下次运行又在 5180-5181 行拒绝恢复。更大的事务被拆成 `Publish-CffLicensedBundles` 和之后的 `Update-OrCheckCffLicensedProvenance`，因此还可能留下字体/许可证已发布而 qualification/manifest 缺失。provenance 阶段同样先逐个移动两个 qualification，再替换 manifest，进程终止会绕过 catch，形成它自己明确拒绝的 partial state。日志声称“published atomically”，但文件系统上不存在这样的多路径原子性。

**Fix:** 把两个字体、两个许可证、两个 qualification 和新 manifest 纳入同一个可恢复事务：在同卷 staging 中写完并校验全部文件，落盘包含目标、旧/新摘要与事务阶段的 durable journal，再按幂等步骤 rename；每次入口首先完成或回滚遗留 journal。只有 manifest 和全部目标一致后才删除 journal。若不实现恢复协议，必须取消“atomic”保证，并且不得在 provenance 就绪前写入任何 canonical destination。

---

_Reviewed: 2026-07-29T10:45:26Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
