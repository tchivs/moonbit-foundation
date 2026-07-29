---
phase: 107
fixed_at: 2026-07-29T13:35:55.5509321Z
review_path: .planning/phases/107-hostile-licensed-and-four-target-qualification/107-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 107：代码审查修复报告

**修复时间：** 2026-07-29T13:35:55.5509321Z  
**源审查：** `.planning/phases/107-hostile-licensed-and-four-target-qualification/107-REVIEW.md`  
**迭代：** 1

**摘要：**

- 范围内问题：5
- 已修复：5
- 已跳过：0

## 已修复问题

### CR-01：AFDKO 读取器把所有 CFF 都报告为 name-keyed，CID 证据与真实字体矛盾

**状态：** fixed  
**修改文件：** `.planning/phases/107-hostile-licensed-and-four-target-qualification/107-01-SUMMARY.md`, `.planning/phases/107-hostile-licensed-and-four-target-qualification/107-02-SUMMARY.md`, `fixtures/font/cff-oracle-tools.json`, `fixtures/font/source-han-serif-2.003r/qualification.json`, `fixtures/font/source-sans-3.052r/qualification.json`, `fixtures/manifest.json`, `policy/foundation.json`, `scripts/fixtures/Generate-FontQualification.ps1`, `scripts/fixtures/oracles/Invoke-AfdkoCffOracle.ps1`, `scripts/fixtures/oracles/fonttools_cff_oracle.py`, `scripts/quality/Assert-Policy.ps1`  
**提交：** `dd3a7690`  
**应用的修复：** AFDKO 适配器现在独立解析 CFF Top DICT，报告真实 name/CID keying、ROS、FD 数量、FD 覆盖、选定 FD 与 FDSelect 格式；两个读取器的 agreement projection 与 profile 校验都包含 keying/ROS，并重新生成许可字体资格、manifest 和策略身份。

### CR-02：所谓 53 行 hostile/mutation 矩阵主要只是字符串和注释，并未逐行执行

**状态：** fixed: requires human verification  
**修改文件：** `policy/foundation.json`, `scripts/quality/Invoke-FontQualification.ps1`  
**提交：** `e97f206e`  
**应用的修复：** 资格运行器从 canonical 53 行导出精确源测试绑定，逐行调用真实 MoonBit 测试，并把有序覆盖、实际通过状态以及 outcome/publication/B8 绑定写入每个目标记录；完整运行确认四个目标各有 53 行且没有未绑定或失败行。

### CR-03：基准“正确性 SHA-256”只散列工作负载标签，不散列字体运行结果

**状态：** fixed: requires human verification  
**修改文件：** `benchmarks/font-cff/cff_bench.mbt`, `benchmarks/font-cff/cff_qualification_wbtest.mbt`, `benchmarks/font-cff/generated_cff_evidence.mbt`, `docs/benchmarks/mb-font-cff-native-release-baseline.md`, `fixtures/font/cff-qualification-cases.json`, `policy/foundation.json`, `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1`, `scripts/fixtures/Generate-FontQualification.ps1`, `scripts/fixtures/oracles/fonttools_cff_runtime_oracle.py`, `scripts/quality/Invoke-FontQualification.ps1`  
**提交：** `9dcfea3e`, `016699b5`  
**应用的修复：** MoonBit tracer 现在序列化实际 source/open 事实、scalar→GID、metrics、bounds、kerning，以及固定 GID 的全部 path command 和坐标；四个摘要由固定 fontTools 4.63.0 独立 oracle 校验。基准保存实际输出摘要，并以一次排除 warmup、七次保留采样重新原子记录当前 native 基线。

### CR-04：四目标语义相等比较比较的是同一份期望数据，不是四个后端的观察结果

**状态：** fixed: requires human verification  
**修改文件：** `scripts/quality/Invoke-FontQualification.ps1`  
**提交：** `74b84a48`  
**应用的修复：** 每个 JS、Wasm、Wasm-GC 和 native 运行现在捕获并解析该后端产生的 closed-schema runtime observations；比较只移除 `target` 和 `runner` 元数据，保留并比较每个后端实际观察到的四个 runtime correctness 输出。

### CR-05：许可资产、qualification 和 manifest 的“原子发布”无法抵抗进程终止

**状态：** fixed  
**修改文件：** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `policy/foundation.json`, `scripts/fixtures/Generate-FontQualification.ps1`, `scripts/quality/Assert-Policy.ps1`  
**提交：** `935201a8`, `4dfa228f`  
**应用的修复：** 许可 bundle、qualification 与 manifest 发布由同一 durable journal 覆盖；journal 使用 write-through、flush-to-disk 和原子替换，每个幂等发布步骤都会持久化进度，下一次入口先 roll-forward 并在完整 provenance CheckOnly 成功后清理。六个真实 `FailFast` 终止边界均验证了 journal 恢复、canonical 快照不变及无临时残留。

## 验证

- 生成器、oracle agreement/provenance、私有证据镜像、单 payload owner、许可 intake 和六个终止恢复边界均通过。
- 基准 `-ContractOnly` 的 26 个负向探针通过；新 native baseline 原子记录完成，`-Audit` 验证 tracked inputs、workspace、raw hashes、一次排除 warmup、七次保留采样和六项统计通过。
- `Assert-FontFoundationPolicy` 通过；Moon 检查为 34 个既有未使用警告、0 错误。
- 完整四目标资格运行通过：JS、Wasm、Wasm-GC、native 各 `274/274`；每目标 53 个 hostile 行全部 passed 且 outcome/publication/B8 全绑定；四个 runtime workload 全部 observed。
- 四目标比较为 `equal: true`，只规范化 `target,runner`，最终 semantic SHA-256 为 `b5cb31ba015d452fa3a36244408a5e512608632c2f07b8fa2d033461cc522933`。
- 范围外的全仓 `Assert-FoundationPolicy` 当前仍报告 `tchivs/mb-core/math` imports 计数预期 1、实际 2；Phase 107 使用的字体专项策略门禁不受影响。

---

_Fixed: 2026-07-29T13:35:55.5509321Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
