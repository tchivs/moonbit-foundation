---
phase: 107
fixed_at: 2026-07-29T16:05:50Z
review_path: .planning/phases/107-hostile-licensed-and-four-target-qualification/107-REVIEW.md
iteration: 2
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 107：代码审查修复报告

**修复时间：** 2026-07-29T16:05:50Z  
**源审查：** `.planning/phases/107-hostile-licensed-and-four-target-qualification/107-REVIEW.md`  
**迭代：** 2

**摘要：**

- 范围内问题：3
- 已修复：3
- 已跳过：0
- 本轮复审重新编号如下：复审 CR-01 = 原 CR-02，复审 CR-02 = 原 CR-03，复审 CR-03 = 原 CR-05。提交消息沿用原始编号，便于与第一轮审查和修复历史对应。

## 已修复问题

### CR-01（原 CR-02）：53 行 hostile coverage 仍由测试名推断，未逐行执行 canonical outcome

**状态：** fixed: requires human verification  
**修改文件：** `benchmarks/font-cff/generated_cff_evidence.mbt`, `fixtures/font/cff-qualification-cases.json`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `policy/foundation.json`, `scripts/quality/Invoke-FontQualification.ps1`  
**提交：** `e00d3b62`  
**应用的修复：** 新增 native hostile row observation tracer 和严格闭合 schema parser。53 个 canonical row 逐一执行真实入口，按唯一 row ID 校验 outcome、category、code、operation、payload、context、GID、publication 以及 caller/ancestor B8；runner 拒绝未知、重复、缺失和未绑定行，不再从共享测试名推断覆盖。四目标完整资格运行实际各捕获并绑定 53/53 行。

### CR-02（原 CR-03）：baseline Record 仍复制 corpus 摘要，没有散列该次 benchmark 的实际输出

**状态：** fixed: requires human verification  
**修改文件：** `benchmarks/font-cff/cff_bench.mbt`, `benchmarks/font-cff/cff_qualification_wbtest.mbt`, `benchmarks/font-cff/cff_runtime_semantics.mbt`, `benchmarks/font-cff/generated_cff_evidence.mbt`, `docs/benchmarks/mb-font-cff-native-release-baseline.md`, `fixtures/font/cff-qualification-cases.json`, `policy/foundation.json`, `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1`, `scripts/fixtures/Generate-FontQualification.ps1`, `scripts/fixtures/oracles/fonttools_cff_runtime_oracle.py`, `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Invoke-FontQualification.ps1`  
**提交：** `7f4181ea`, `edb03d37`, `8b0b937e`  
**应用的修复：** benchmark 在计时区间外使用共享 serializer 序列化同次 native workload 的实际 mappings、metrics、bounds 和完整 path commands/坐标，输出闭合的 `MNF_CFF_BENCH_CORRECTNESS` 记录；录制器严格解析并散列实际输出，与独立 corpus oracle 比较，且把共享 serializer 纳入 source identity。只执行一次 `-Record`，原子录制一次排除 warmup、七次保留 capture 的 observed baseline；随后只读 `-Audit` 验证 tracked inputs、workspace、raw hashes、采样集合和六项统计。

### CR-03（原 CR-05）：可捕获的发布失败会删除已覆盖的 canonical qualification，造成数据丢失

**状态：** fixed: requires human verification  
**修改文件：** `scripts/fixtures/Generate-FontQualification.ps1`  
**提交：** `fd2c885a`  
**应用的修复：** 两个 qualification 和 manifest 现在由同一个 durable journal transaction 发布。协议只允许三个精确目标，使用同卷 stage/backup，持久化旧/新 SHA-256 和步骤计数；进程终止后幂等 roll-forward，普通异常则逆序恢复并验证旧摘要。六个终止 failpoint 与三个普通异常 failpoint 均恢复成功，未留下 journal、stage、backup 或 rollback 残留。

## 验证

- `Generate-FontQualification.ps1 -Check`、licensed intake、provenance、intake negatives、FontQualification `-ContractOnly`、CFF benchmark `-ContractOnly` 与 benchmark qualification contract probes 均通过。
- hostile tracer 在 js、wasm、wasm-gc、native 四个目标各实际捕获 53/53 个唯一 row；缺失、重复、未知及字段篡改负向探针通过。
- 正确性通道的四个 observed SHA-256 分别为 `175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11`、`26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5`、`48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d`、`9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb`，与独立 oracle 一致。
- exactly one native baseline `-Record` 成功，baseline SHA-256 为 `7f087d42aded809d5d003cf7ae88da1cc12401226cf82f35de2b88757316dea9`；后续 `-Audit` 与 FontPolicy 均通过。
- 完整四目标资格运行通过：js、wasm、wasm-gc、native 各 `275/275`，每目标 53/53 hostile row、4/4 runtime observation，0 errors。
- 四目标 comparison 顺序严格为 `js, wasm, wasm-gc, native`，`equal: true`；最终 semantic SHA-256 为 `ba2bcccb84406e13ee5d0dd7ab74715a5d05877822fd3b03238965d8b0125089`。
- 全目标 Moon 检查通过；输出仅含既有 unused/deprecated 警告，没有新增错误。

---

_Fixed: 2026-07-29T16:05:50Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 2_
