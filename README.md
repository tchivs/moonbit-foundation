# MoonBit Native Foundation

[![CI](https://github.com/tchivs/moonbit-foundation/actions/workflows/quality.yml/badge.svg?branch=main)](https://github.com/tchivs/moonbit-foundation/actions/workflows/quality.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-0.1.x%20candidate-orange.svg)](.planning/ROADMAP.md)
[![Targets](https://img.shields.io/badge/targets-js%20%7C%20wasm%20%7C%20wasm--gc%20%7C%20native-5c6bc0.svg)](.planning/PROJECT.md)

English · [中文](#中文)

## English

MoonBit Native Foundation (MNF) is an RFC-led, native-first foundation for
graphics, documents, media, and system-oriented MoonBit software. It provides
small, composable modules with explicit boundaries, deterministic behavior,
bounded resource use, and deliberate portability across MoonBit targets.

MNF is infrastructure rather than an end-user application. Image editors,
whiteboards, PDF/SVG tools, OCR pipelines, CLIs, MCP servers, and WebAssembly
applications are intended to consume these contracts instead of rebuilding
incompatible foundations.

### Status

The repository is in active `0.1.x` candidate development. The modules are not
stable and have not been published as a public release. The active line is
v0.27, focused on low-bit indexed Adam7 PNG encoding; the workspace also
contains candidate `mb-canvas` and `mb-svg` implementations.

Publication remains gated on verifying the exact Mooncakes namespace authority.
No candidate API should be treated as a stable compatibility promise.

### Modules

Every module is independently publishable and currently targets `js`, `wasm`,
`wasm-gc`, and `native` unless its manifest says otherwise. Native is the
preferred performance and system-integration target.

| Module | Responsibility | Direct dependencies |
| --- | --- | --- |
| [`tchivs/mb-core`](modules/mb-core/README.mbt.md) | Checked arithmetic, bounded storage, budgets, I/O, diagnostics, and host capabilities | — |
| [`tchivs/mb-color`](modules/mb-color/README.mbt.md) | Explicit color identities, sRGB transfer, alpha semantics, quantization, and profiles | `mb-core` |
| [`tchivs/mb-image`](modules/mb-image/README.mbt.md) | Image descriptors, storage/views, raster operations, codec contracts, PPM, QOI, and PNG | `mb-core`, `mb-color` |
| [`tchivs/mb-canvas`](modules/mb-canvas/README.mbt.md) | Deterministic drawing lists and coverage-antialiased rasterization into `mb-image` surfaces | `mb-core`, `mb-color`, `mb-image` |
| [`tchivs/mb-svg`](modules/mb-svg/README.mbt.md) | Bounded SVG parsing and scene-tree lowering into an `mb-canvas` drawing list | `mb-core`, `mb-color`, `mb-image`, `mb-canvas` |

The dependency direction is deliberately downward: SVG parses documents, canvas
executes geometry, image owns pixels/codecs, color owns color semantics, and
core owns safety and capability primitives.

### Quick start

The CI-verified development baseline is:

- `moon 0.1.20260713` (`75c7e1f`)
- `moonc v0.10.4+2cc641edf`
- `moonrun 0.1.20260713` (`75c7e1f`)

Run the required quality lane from PowerShell:

```powershell
./scripts/quality.ps1 `
  -Lane Required `
  -EvidenceDirectory artifacts/release-qualification/local
```

Run the SVG end-to-end example:

```powershell
moon -C examples/mb-svg-demo run main --target native --frozen
```

For a focused PNG check:

```powershell
moon -C modules/mb-image info --target all --frozen
moon -C modules/mb-image test png --target native --frozen
```

### Design commitments

- Core algorithms and shared data models are MoonBit-owned wherever practical.
- Native integration is isolated behind documented, replaceable capability
  boundaries.
- Public packages have explicit, acyclic dependencies and narrow imports.
- Limits and checked arithmetic are preflighted before allocation, mutation, or
  output; caller-buffered machines preserve rejected tails and sticky errors.
- New behavior is opt-in when compatibility bytes must remain frozen.
- Automation is deterministic and does not depend on GUI state.
- New modules and breaking architectural changes require an RFC.

### Documentation and contribution

- [Architecture](docs/architecture/overview.md)
- [Getting started](docs/guides/getting-started.md)
- [Development](docs/guides/development.md)
- [Testing](docs/testing/testing.md)
- [Configuration](docs/configuration/configuration.md)
- [Contributing](CONTRIBUTING.md)
- [RFC index](docs/rfcs/README.md)
- [Policies](docs/policies/)
- [Security policy](SECURITY.md)

### Stability and publication

All current modules are `0.1.0` candidates. Until a module is declared stable,
its compatibility policy is the executable pre-1.0 policy documented in the
module README and RFC 0001. Registry mutations remain a separately verified
operation; a manifest name is not a claim that a package has been published.

## 中文

MoonBit Native Foundation（MNF）是一个由 RFC 驱动、以 Native 为优先的
MoonBit 基础设施项目，面向图形、文档、媒体以及系统软件。项目提供边界
清晰、可组合、可确定性执行并且受资源约束的模块，同时有意识地支持
`js`、`wasm`、`wasm-gc` 和 `native` 目标。

MNF 不是终端应用，而是供图像工具、白板、PDF/SVG 工具、OCR 管线、CLI、
MCP 服务、IDE 扩展、桌面软件和 WebAssembly 应用复用的基础合同。

### 当前状态

仓库目前处于 `0.1.x` candidate 开发阶段，模块尚未声明稳定，也没有声称
已经完成公开发布。当前主线是 v0.27，重点是低位深索引 Adam7 PNG 编码；
工作区同时包含 candidate 状态的 `mb-canvas` 和 `mb-svg` 实现。

发布仍需先验证 Mooncakes 的确切命名空间权限。任何 candidate API 都不应
被视为稳定兼容承诺。

### 模块划分

| 模块 | 职责 | 直接依赖 |
| --- | --- | --- |
| [`tchivs/mb-core`](modules/mb-core/README.mbt.md) | 检查算术、有界存储、预算、I/O、诊断和宿主能力 | — |
| [`tchivs/mb-color`](modules/mb-color/README.mbt.md) | 显式颜色语义、sRGB 传递、Alpha、量化和 Profile | `mb-core` |
| [`tchivs/mb-image`](modules/mb-image/README.mbt.md) | 图像描述、存储/视图、栅格操作、编解码合同、PPM、QOI、PNG | `mb-core`、`mb-color` |
| [`tchivs/mb-canvas`](modules/mb-canvas/README.mbt.md) | 确定性的绘制列表和覆盖率抗锯齿栅格化 | `mb-core`、`mb-color`、`mb-image` |
| [`tchivs/mb-svg`](modules/mb-svg/README.mbt.md) | 有界 SVG 解析，并降级为 `mb-canvas` 绘制列表 | `mb-core`、`mb-color`、`mb-image`、`mb-canvas` |

依赖方向保持向下：SVG 负责文档解析，Canvas 负责几何执行，Image 负责
像素和编解码，Color 负责颜色语义，Core 负责安全和能力基础。

### 快速开始

CI 验证的工具链基线为：

- `moon 0.1.20260713`（`75c7e1f`）
- `moonc v0.10.4+2cc641edf`
- `moonrun 0.1.20260713`（`75c7e1f`）

在 PowerShell 中运行必需质量检查：

```powershell
./scripts/quality.ps1 `
  -Lane Required `
  -EvidenceDirectory artifacts/release-qualification/local
```

运行 SVG 到像素的端到端示例：

```powershell
moon -C examples/mb-svg-demo run main --target native --frozen
```

运行聚焦的 PNG 检查：

```powershell
moon -C modules/mb-image info --target all --frozen
moon -C modules/mb-image test png --target native --frozen
```

### 设计原则

- 核心算法和共享数据模型尽量由 MoonBit 实现。
- Native 集成必须位于文档化、可替换的窄能力边界之后。
- 公共包依赖显式、无环，并保持最小导入面。
- 在分配、修改或输出前完成限制和检查算术预检；调用方缓冲机器保留
  被拒绝的尾部和粘性错误。
- 需要保持兼容字节时，新行为必须显式选择，不能悄悄改变旧输出。
- 自动化过程必须确定性执行，不依赖 GUI 状态。
- 新模块和破坏性架构变化必须先经过 RFC。

### 文档与贡献

- [架构](docs/architecture/overview.md)
- [开始使用](docs/guides/getting-started.md)
- [开发指南](docs/guides/development.md)
- [测试指南](docs/testing/testing.md)
- [配置说明](docs/configuration/configuration.md)
- [贡献指南](CONTRIBUTING.md)
- [RFC 索引](docs/rfcs/README.md)
- [项目策略](docs/policies/)
- [安全策略](SECURITY.md)

### 稳定性与发布

当前模块均为 `0.1.0` candidate。在模块正式声明稳定之前，兼容性以模块
README 和 RFC 0001 中可执行的 pre-1.0 策略为准。注册表操作必须单独验证；
manifest 中出现模块名称不代表该包已经发布。

## License / 许可证

Apache License 2.0 — [LICENSE](LICENSE)
