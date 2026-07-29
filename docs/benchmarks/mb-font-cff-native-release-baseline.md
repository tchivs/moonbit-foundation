# mb-font CFF1 native release baseline

**Scope:** `observation_only` native release measurements for exact reproduction facts. The record establishes no threshold, regression verdict, cross-library comparison, ranking, superiority, CI timing gate, release decision, or marketing claim.

## Closed identity

- Source Git commit: `4dfa228f033e6a8cddefaadac389383a7bdefa77`
- Source tree state: `(clean benchmark inputs; orchestrator auto-chain marker excluded)`
- Exact command: `moon -C benchmarks bench font-cff/cff_bench.mbt --release --target native --frozen`
- Fixed sequence: one excluded warmup followed by seven retained complete captures.

## Workspace and workload provenance

- Workspace members: `../modules/mb-core,../modules/mb-color,../modules/mb-image,../modules/mb-font,./ppm,./font-cff`
- mb-font: `tchivs/mb-font@0.1.0` from tracked `modules/mb-font`; manifest SHA-256 `9f1925d4d2c5a36403881fb31a147c25017e719d452acf537ae0d6e427d75826`; empty cache entries `0`.

| Workload | Fixture | Operation | GIDs | Correctness SHA-256 |
| --- | --- | --- | --- | --- |
| latin-full-admission | source-sans-3.052R | full-admission |  | `175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11` |
| cjk-full-admission | source-han-serif-jp-2.003R | full-admission |  | `26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5` |
| latin-fixed-outline-batch | source-sans-3.052R | outline-batch | 2,3,34,97,321,1024,2477 | `48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d` |
| cjk-high-gid-multi-fd-outline-batch | source-han-serif-jp-2.003R | outline-batch | 2,256,2048,8192,16384,17922 | `9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb` |

## Tracked source identities

| Path | Length | SHA-256 |
| --- | ---: | --- |
| `fixtures/font/cff-qualification-cases.json` | 49782 | `50234e84df712df4842c871970dc78ce992ad504ae5169b6f5ae91f9eb65fc9a` |
| `fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf` | 334924 | `08df266400933d3178d081a45f94a08814c3e55b4b7dd2e0ff69cb1329f13ab6` |
| `fixtures/font/source-sans-3.052r/qualification.json` | 12625 | `2bbea30dd8133e3a8890e3f2263e7120f7c102b0b24a0e3eb3e1187341e3a08f` |
| `fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf` | 6210796 | `e5f502bb193c28829895b098498f0f9dd8f658c760b0f83656ad41c1137a8785` |
| `fixtures/font/source-han-serif-2.003r/qualification.json` | 15556 | `0fef79e962fb1abd23d6982f8271a7cc79491470363d45f50c7c63f3ddad4dcf` |
| `benchmarks/font-cff/generated_cff_evidence.mbt` | 26432208 | `5f0f1c3a4f6c997cd7ed36c4c4c9506e0e70bb6fb27aee6e1650b664ab282873` |
| `benchmarks/font-cff/moon.mod.json` | 262 | `4103bc450bb8dec7708823d8dd60644d08fdd35a0850d826fce82342c940d018` |
| `benchmarks/font-cff/moon.pkg` | 256 | `a22026ab3a2d0a6cea938f029f56a511495234bb57fb62ba3fe2ad32d87b9218` |
| `benchmarks/font-cff/cff_bench.mbt` | 6899 | `818f340695eca11bb23ce862f46f4b16a48c78d962386789368063f72e7a92f4` |
| `benchmarks/moon.work` | 139 | `2562fdf6d4dba04d48b32b207764edb6076c1772d0e53ef1e1712e82ebf93895` |
| `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1` | 66250 | `8b95993b7b3dfa39ac77ebf5b3e9604e3a374cd67fd65b1347372e00eb562d06` |
| `scripts/quality/Test-BenchmarkQualification.ps1` | 8102 | `204901288f0b1691fe1ea0efd3e3ad3165c6349e094a20c3ffb26bbae14ffbec` |

## Toolchain and host

- moon: `moon.exe` SHA-256 `33637c966083a2b86e5074b746db366024f08c55f3b8a766fed804ddb19f98f4`; version output SHA-256 `95c1e2173e065a7534ee6e5a16a56be9d3950139e12b67321fdc0262db049c02`.
- moonc: `moonc.exe` SHA-256 `f4f5528201472d5de11213e4f6a0cca0bfe8be66f04ffa0a23d65dfe163fae92`; version output SHA-256 `b1224a331712d1723675907be52e48e22e50755f93cf73db0a01c55de46bf7c2`.
- moonrun: `moonrun.exe` SHA-256 `641fc857c9696882ac3b5ac8ac75af0d010d252dc7ff9223db5305fe26bc6759`; version output SHA-256 `05f86cdc7a875159e359cb85dfebca0da01c9a9b7e9ebdd85457a9a6643de828`.
- PowerShell: `7.6.3` (`Desktop`, `pwsh.exe`, SHA-256 `8737aa78bdbe2941083c2c3674da3a9c3ab4cabd2cac040d39d1d0c19f9fc20d`).
- Native compiler: `clang.exe`, SHA-256 `a8b7a614eeadd9105f814be3701a7f312cda4cea51751b75b408c16100c94e85`, probe `clang.exe --version`.
- os: `Microsoft Windows 11 企业版 | version=10.0.22631 | build=22631 | architecture=64 位` (probe `Get-CimInstance Win32_OperatingSystem`).
- cpu: `Intel(R) Xeon(R) Platinum 8378C CPU @ 2.80GHz | physical_cores=4 | logical_processors=8` (probe `Get-CimInstance Win32_Processor | Select-Object -First 1`).
- physical_memory_bytes: `34358808576` (probe `Get-CimInstance Win32_ComputerSystem`).
- active_power_scheme: `381b4222-f694-41f0-9685-ff5bb260df2e` (probe `powercfg /GETACTIVESCHEME`).

## Captures

### Warmup (excluded)
- UTC start: `2026-07-29T12:26:40.2013803Z`
- UTC end: `2026-07-29T12:33:15.3302181Z`
- Exit status: `0`
- Normalized raw output SHA-256: `b02128b7c5347f51d17aaa5fd730ae208b12bcba1927a46850ee12425b44baf6`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 1070.000000000 | 41.620000000 | 1030.000000000 | 1150.000000000 | 10 | 1 |
| cjk-full-admission | 29160.000000000 | 383.540000000 | 28710.000000000 | 29740.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 3.310000000 | 0.327980000 | 2.820000000 | 3.790000000 | 10 | 40 |
| cjk-high-gid-multi-fd-outline-batch | 4.750000000 | 0.606810000 | 4.220000000 | 6.120000000 | 10 | 24 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;1.07&#32;s&#32;±&#32;&#32;41.62&#32;ms&#32;&#32;&#32;&#32;&#32;1.03&#32;s&#32;…&#32;&#32;&#32;1.15&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;29.16&#32;s&#32;±&#32;383.54&#32;ms&#32;&#32;&#32;&#32;28.71&#32;s&#32;…&#32;&#32;29.74&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;3.31&#32;ms&#32;±&#32;327.98&#32;µs&#32;&#32;&#32;&#32;&#32;2.82&#32;ms&#32;…&#32;&#32;&#32;3.79&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;40&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.75&#32;ms&#32;±&#32;606.81&#32;µs&#32;&#32;&#32;&#32;&#32;4.22&#32;ms&#32;…&#32;&#32;&#32;6.12&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;24&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 1
- UTC start: `2026-07-29T12:33:15.3769325Z`
- UTC end: `2026-07-29T12:39:47.7108605Z`
- Exit status: `0`
- Normalized raw output SHA-256: `4ba4719f237f0ebc53165b6ee27b228ec75032e8d2966f1f9f666614f04e3ccd`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 1030.000000000 | 46.160000000 | 963.910000000 | 1100.000000000 | 10 | 1 |
| cjk-full-admission | 28860.000000000 | 305.820000000 | 28490.000000000 | 29330.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.910000000 | 0.303070000 | 2.560000000 | 3.530000000 | 10 | 30 |
| cjk-high-gid-multi-fd-outline-batch | 4.960000000 | 0.488450000 | 4.310000000 | 5.790000000 | 10 | 22 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;1.03&#32;s&#32;±&#32;&#32;46.16&#32;ms&#32;&#32;&#32;963.91&#32;ms&#32;…&#32;&#32;&#32;1.10&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;28.86&#32;s&#32;±&#32;305.82&#32;ms&#32;&#32;&#32;&#32;28.49&#32;s&#32;…&#32;&#32;29.33&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.91&#32;ms&#32;±&#32;303.07&#32;µs&#32;&#32;&#32;&#32;&#32;2.56&#32;ms&#32;…&#32;&#32;&#32;3.53&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;30&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.96&#32;ms&#32;±&#32;488.45&#32;µs&#32;&#32;&#32;&#32;&#32;4.31&#32;ms&#32;…&#32;&#32;&#32;5.79&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;22&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 2
- UTC start: `2026-07-29T12:39:47.7176278Z`
- UTC end: `2026-07-29T12:46:18.5766946Z`
- Exit status: `0`
- Normalized raw output SHA-256: `3d142d6cb39166b90fdb582b38f0968d34fd278df155aae80658c796e214e365`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 1030.000000000 | 48.150000000 | 974.660000000 | 1100.000000000 | 10 | 1 |
| cjk-full-admission | 28690.000000000 | 251.640000000 | 28360.000000000 | 29060.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.960000000 | 0.162850000 | 2.800000000 | 3.210000000 | 10 | 37 |
| cjk-high-gid-multi-fd-outline-batch | 5.160000000 | 0.338690000 | 4.790000000 | 5.750000000 | 10 | 21 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;1.03&#32;s&#32;±&#32;&#32;48.15&#32;ms&#32;&#32;&#32;974.66&#32;ms&#32;…&#32;&#32;&#32;1.10&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;28.69&#32;s&#32;±&#32;251.64&#32;ms&#32;&#32;&#32;&#32;28.36&#32;s&#32;…&#32;&#32;29.06&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.96&#32;ms&#32;±&#32;162.85&#32;µs&#32;&#32;&#32;&#32;&#32;2.80&#32;ms&#32;…&#32;&#32;&#32;3.21&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;37&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;5.16&#32;ms&#32;±&#32;338.69&#32;µs&#32;&#32;&#32;&#32;&#32;4.79&#32;ms&#32;…&#32;&#32;&#32;5.75&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;21&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 3
- UTC start: `2026-07-29T12:46:18.5868927Z`
- UTC end: `2026-07-29T12:53:12.4290119Z`
- Exit status: `0`
- Normalized raw output SHA-256: `08639cb4c05d40dab3d2c6fee16dbbd8803eda337ad5b7df09f636dab3c22e4f`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 1110.000000000 | 42.310000000 | 1050.000000000 | 1150.000000000 | 10 | 1 |
| cjk-full-admission | 30660.000000000 | 1010.000000000 | 29070.000000000 | 31760.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 3.250000000 | 0.286550000 | 2.820000000 | 3.680000000 | 10 | 33 |
| cjk-high-gid-multi-fd-outline-batch | 5.110000000 | 0.446900000 | 4.470000000 | 5.850000000 | 10 | 23 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;1.11&#32;s&#32;±&#32;&#32;42.31&#32;ms&#32;&#32;&#32;&#32;&#32;1.05&#32;s&#32;…&#32;&#32;&#32;1.15&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;30.66&#32;s&#32;±&#32;&#32;&#32;1.01&#32;s&#32;&#32;&#32;&#32;29.07&#32;s&#32;…&#32;&#32;31.76&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;3.25&#32;ms&#32;±&#32;286.55&#32;µs&#32;&#32;&#32;&#32;&#32;2.82&#32;ms&#32;…&#32;&#32;&#32;3.68&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;33&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;5.11&#32;ms&#32;±&#32;446.90&#32;µs&#32;&#32;&#32;&#32;&#32;4.47&#32;ms&#32;…&#32;&#32;&#32;5.85&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;23&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 4
- UTC start: `2026-07-29T12:53:12.4367010Z`
- UTC end: `2026-07-29T12:59:31.1517288Z`
- Exit status: `0`
- Normalized raw output SHA-256: `1ee2ce32cb8c6005d8d9ecb00fc4d83aded07e704a8b409fcf1e8ba3787b4eae`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 1050.000000000 | 37.060000000 | 998.490000000 | 1130.000000000 | 10 | 1 |
| cjk-full-admission | 27750.000000000 | 499.190000000 | 27120.000000000 | 28560.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 3.150000000 | 0.499400000 | 2.670000000 | 4.170000000 | 10 | 29 |
| cjk-high-gid-multi-fd-outline-batch | 4.540000000 | 0.280810000 | 4.050000000 | 4.930000000 | 10 | 23 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;1.05&#32;s&#32;±&#32;&#32;37.06&#32;ms&#32;&#32;&#32;998.49&#32;ms&#32;…&#32;&#32;&#32;1.13&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;27.75&#32;s&#32;±&#32;499.19&#32;ms&#32;&#32;&#32;&#32;27.12&#32;s&#32;…&#32;&#32;28.56&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;3.15&#32;ms&#32;±&#32;499.40&#32;µs&#32;&#32;&#32;&#32;&#32;2.67&#32;ms&#32;…&#32;&#32;&#32;4.17&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;29&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.54&#32;ms&#32;±&#32;280.81&#32;µs&#32;&#32;&#32;&#32;&#32;4.05&#32;ms&#32;…&#32;&#32;&#32;4.93&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;23&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 5
- UTC start: `2026-07-29T12:59:31.1587466Z`
- UTC end: `2026-07-29T13:05:41.6196381Z`
- Exit status: `0`
- Normalized raw output SHA-256: `20dbe69c9fa05c1331b3ce5c65cc11beda7b9ef4fa8682ba5ef3a78ea5c923cb`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 988.780000000 | 58.610000000 | 912.320000000 | 1080.000000000 | 10 | 1 |
| cjk-full-admission | 27250.000000000 | 322.160000000 | 26740.000000000 | 27640.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.820000000 | 0.309890000 | 2.540000000 | 3.400000000 | 10 | 32 |
| cjk-high-gid-multi-fd-outline-batch | 4.680000000 | 0.386630000 | 4.280000000 | 5.510000000 | 10 | 20 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;988.78&#32;ms&#32;±&#32;&#32;58.61&#32;ms&#32;&#32;&#32;912.32&#32;ms&#32;…&#32;&#32;&#32;1.08&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;27.25&#32;s&#32;±&#32;322.16&#32;ms&#32;&#32;&#32;&#32;26.74&#32;s&#32;…&#32;&#32;27.64&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.82&#32;ms&#32;±&#32;309.89&#32;µs&#32;&#32;&#32;&#32;&#32;2.54&#32;ms&#32;…&#32;&#32;&#32;3.40&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;32&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.68&#32;ms&#32;±&#32;386.63&#32;µs&#32;&#32;&#32;&#32;&#32;4.28&#32;ms&#32;…&#32;&#32;&#32;5.51&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;20&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 6
- UTC start: `2026-07-29T13:05:41.6249398Z`
- UTC end: `2026-07-29T13:12:03.2682283Z`
- Exit status: `0`
- Normalized raw output SHA-256: `7836ffa80069db40bdf9e218462834dd5e3d938a21a9502d8c70ea0076e3ce06`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 997.620000000 | 40.770000000 | 945.680000000 | 1060.000000000 | 10 | 1 |
| cjk-full-admission | 28080.000000000 | 345.120000000 | 27670.000000000 | 28690.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 3.030000000 | 0.215550000 | 2.750000000 | 3.400000000 | 10 | 37 |
| cjk-high-gid-multi-fd-outline-batch | 4.620000000 | 0.355680000 | 4.240000000 | 5.210000000 | 10 | 20 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;997.62&#32;ms&#32;±&#32;&#32;40.77&#32;ms&#32;&#32;&#32;945.68&#32;ms&#32;…&#32;&#32;&#32;1.06&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;28.08&#32;s&#32;±&#32;345.12&#32;ms&#32;&#32;&#32;&#32;27.67&#32;s&#32;…&#32;&#32;28.69&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;3.03&#32;ms&#32;±&#32;215.55&#32;µs&#32;&#32;&#32;&#32;&#32;2.75&#32;ms&#32;…&#32;&#32;&#32;3.40&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;37&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.62&#32;ms&#32;±&#32;355.68&#32;µs&#32;&#32;&#32;&#32;&#32;4.24&#32;ms&#32;…&#32;&#32;&#32;5.21&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;20&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 7
- UTC start: `2026-07-29T13:12:03.2743084Z`
- UTC end: `2026-07-29T13:18:11.7646716Z`
- Exit status: `0`
- Normalized raw output SHA-256: `17c32c0fa92a028e1d4f642c382abae4a00c27f19fcbf7962aaf849bdc86ad83`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 979.430000000 | 33.660000000 | 926.390000000 | 1030.000000000 | 10 | 1 |
| cjk-full-admission | 27150.000000000 | 287.350000000 | 26830.000000000 | 27660.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.800000000 | 0.289960000 | 2.490000000 | 3.370000000 | 10 | 36 |
| cjk-high-gid-multi-fd-outline-batch | 4.880000000 | 0.544800000 | 4.230000000 | 5.630000000 | 10 | 21 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;979.43&#32;ms&#32;±&#32;&#32;33.66&#32;ms&#32;&#32;&#32;926.39&#32;ms&#32;…&#32;&#32;&#32;1.03&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;27.15&#32;s&#32;±&#32;287.35&#32;ms&#32;&#32;&#32;&#32;26.83&#32;s&#32;…&#32;&#32;27.66&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.80&#32;ms&#32;±&#32;289.96&#32;µs&#32;&#32;&#32;&#32;&#32;2.49&#32;ms&#32;…&#32;&#32;&#32;3.37&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;36&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.88&#32;ms&#32;±&#32;544.80&#32;µs&#32;&#32;&#32;&#32;&#32;4.23&#32;ms&#32;…&#32;&#32;&#32;5.63&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;21&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

## Seven-capture descriptive statistics

| Workload | Mean (ms) | Median (ms) | Sample standard deviation (ms, n-1=6) | Minimum (ms) | Maximum (ms) | Coefficient of variation |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 1026.547142857 | 1030.000000000 | 44.761259557 | 979.430000000 | 1110.000000000 | 0.043603706 |
| cjk-full-admission | 28348.571428571 | 28080.000000000 | 1210.694409164 | 27150.000000000 | 30660.000000000 | 0.042707422 |
| latin-fixed-outline-batch | 2.988571429 | 2.960000000 | 0.166876059 | 2.800000000 | 3.250000000 | 0.055838069 |
| cjk-high-gid-multi-fd-outline-batch | 4.850000000 | 4.880000000 | 0.243104916 | 4.540000000 | 5.160000000 | 0.050124725 |

## Read-only audit

Run `./scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 -Audit`. Audit reads tracked inputs and this committed document only; it executes no MoonBit command and writes no file.

<!-- CFF-BASELINE-DATA
{
  "schema_version": "mnf-mb-font-cff-native-baseline/1.0.0",
  "claim": {
    "type": "observation_only",
    "interpretation": "native release measurements for exact reproduction facts only"
  },
  "identity": {
    "git_commit": "4dfa228f033e6a8cddefaadac389383a7bdefa77",
    "tree_status": "(clean benchmark inputs; orchestrator auto-chain marker excluded)"
  },
  "execution": {
    "command": "moon -C benchmarks bench font-cff/cff_bench.mbt --release --target native --frozen",
    "working_directory": ".",
    "target": "native",
    "release": true,
    "frozen": true,
    "output_encoding": "normalized UTF-8 without BOM",
    "warmup_count": 1,
    "retained_capture_count": 7
  },
  "workspace": {
    "member_order": [
      "../modules/mb-core",
      "../modules/mb-color",
      "../modules/mb-image",
      "../modules/mb-font",
      "./ppm",
      "./font-cff"
    ],
    "resolution": {
      "module": "tchivs/mb-font",
      "version": "0.1.0",
      "manifest_sha256": "9f1925d4d2c5a36403881fb31a147c25017e719d452acf537ae0d6e427d75826",
      "source_root": "modules/mb-font",
      "local": true,
      "tracked": true,
      "empty_cache_entries": 0
    }
  },
  "sources": [
    {
      "path": "fixtures/font/cff-qualification-cases.json",
      "length": 49782,
      "sha256": "50234e84df712df4842c871970dc78ce992ad504ae5169b6f5ae91f9eb65fc9a"
    },
    {
      "path": "fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf",
      "length": 334924,
      "sha256": "08df266400933d3178d081a45f94a08814c3e55b4b7dd2e0ff69cb1329f13ab6"
    },
    {
      "path": "fixtures/font/source-sans-3.052r/qualification.json",
      "length": 12625,
      "sha256": "2bbea30dd8133e3a8890e3f2263e7120f7c102b0b24a0e3eb3e1187341e3a08f"
    },
    {
      "path": "fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf",
      "length": 6210796,
      "sha256": "e5f502bb193c28829895b098498f0f9dd8f658c760b0f83656ad41c1137a8785"
    },
    {
      "path": "fixtures/font/source-han-serif-2.003r/qualification.json",
      "length": 15556,
      "sha256": "0fef79e962fb1abd23d6982f8271a7cc79491470363d45f50c7c63f3ddad4dcf"
    },
    {
      "path": "benchmarks/font-cff/generated_cff_evidence.mbt",
      "length": 26432208,
      "sha256": "5f0f1c3a4f6c997cd7ed36c4c4c9506e0e70bb6fb27aee6e1650b664ab282873"
    },
    {
      "path": "benchmarks/font-cff/moon.mod.json",
      "length": 262,
      "sha256": "4103bc450bb8dec7708823d8dd60644d08fdd35a0850d826fce82342c940d018"
    },
    {
      "path": "benchmarks/font-cff/moon.pkg",
      "length": 256,
      "sha256": "a22026ab3a2d0a6cea938f029f56a511495234bb57fb62ba3fe2ad32d87b9218"
    },
    {
      "path": "benchmarks/font-cff/cff_bench.mbt",
      "length": 6899,
      "sha256": "818f340695eca11bb23ce862f46f4b16a48c78d962386789368063f72e7a92f4"
    },
    {
      "path": "benchmarks/moon.work",
      "length": 139,
      "sha256": "2562fdf6d4dba04d48b32b207764edb6076c1772d0e53ef1e1712e82ebf93895"
    },
    {
      "path": "scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1",
      "length": 66250,
      "sha256": "8b95993b7b3dfa39ac77ebf5b3e9604e3a374cd67fd65b1347372e00eb562d06"
    },
    {
      "path": "scripts/quality/Test-BenchmarkQualification.ps1",
      "length": 8102,
      "sha256": "204901288f0b1691fe1ea0efd3e3ad3165c6349e094a20c3ffb26bbae14ffbec"
    }
  ],
  "workloads": [
    {
      "id": "latin-full-admission",
      "test_name": "cff/latin-full-admission",
      "fixture_id": "source-sans-3.052R",
      "operation": "full-admission",
      "gids": [],
      "correctness_input": "latin-full-admission|source-sans-3.052R|all-2478",
      "correctness_sha256": "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11"
    },
    {
      "id": "cjk-full-admission",
      "test_name": "cff/cjk-full-admission",
      "fixture_id": "source-han-serif-jp-2.003R",
      "operation": "full-admission",
      "gids": [],
      "correctness_input": "cjk-full-admission|source-han-serif-jp-2.003R|all-17923",
      "correctness_sha256": "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5"
    },
    {
      "id": "latin-fixed-outline-batch",
      "test_name": "cff/latin-fixed-outline-batch",
      "fixture_id": "source-sans-3.052R",
      "operation": "outline-batch",
      "gids": [
        2,
        3,
        34,
        97,
        321,
        1024,
        2477
      ],
      "correctness_input": "latin-fixed-outline-batch|source-sans-3.052R|2,3,34,97,321,1024,2477",
      "correctness_sha256": "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d"
    },
    {
      "id": "cjk-high-gid-multi-fd-outline-batch",
      "test_name": "cff/cjk-high-gid-multi-fd-outline-batch",
      "fixture_id": "source-han-serif-jp-2.003R",
      "operation": "outline-batch",
      "gids": [
        2,
        256,
        2048,
        8192,
        16384,
        17922
      ],
      "correctness_input": "cjk-high-gid-multi-fd-outline-batch|source-han-serif-jp-2.003R|2,256,2048,8192,16384,17922",
      "correctness_sha256": "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb"
    }
  ],
  "toolchain": {
    "moon": {
      "executable": "moon.exe",
      "executable_sha256": "33637c966083a2b86e5074b746db366024f08c55f3b8a766fed804ddb19f98f4",
      "version_output_sha256": "95c1e2173e065a7534ee6e5a16a56be9d3950139e12b67321fdc0262db049c02",
      "version": "moon 0.1.20260713 (75c7e1f 2026-07-13) ~\\.moon\\bin\\moon.exe\nmoonc v0.10.4+2cc641edf (2026-07-15) D:\\AI-Data\\moonbit\\bin\\moonc.exe\nmoonrun 0.1.20260713 (75c7e1f 2026-07-13) D:\\AI-Data\\moonbit\\bin\\moonrun.exe\n\nFeature flags enabled: rr_moon_mod,rr_moon_pkg"
    },
    "moonc": {
      "executable": "moonc.exe",
      "executable_sha256": "f4f5528201472d5de11213e4f6a0cca0bfe8be66f04ffa0a23d65dfe163fae92",
      "version_output_sha256": "b1224a331712d1723675907be52e48e22e50755f93cf73db0a01c55de46bf7c2",
      "version": "v0.10.4+2cc641edf (2026-07-15)"
    },
    "moonrun": {
      "executable": "moonrun.exe",
      "executable_sha256": "641fc857c9696882ac3b5ac8ac75af0d010d252dc7ff9223db5305fe26bc6759",
      "version_output_sha256": "05f86cdc7a875159e359cb85dfebca0da01c9a9b7e9ebdd85457a9a6643de828",
      "version": "moonrun 0.1.20260713 (75c7e1f 2026-07-13)"
    }
  },
  "host": {
    "powershell": {
      "version": "7.6.3",
      "edition": "Desktop",
      "executable": "pwsh.exe",
      "executable_sha256": "8737aa78bdbe2941083c2c3674da3a9c3ab4cabd2cac040d39d1d0c19f9fc20d"
    },
    "dotnet_runtime": "10.0.9",
    "os": {
      "value": "Microsoft Windows 11 \u4F01\u4E1A\u7248 | version=10.0.22631 | build=22631 | architecture=64 \u4F4D",
      "attempted": "Get-CimInstance Win32_OperatingSystem"
    },
    "cpu": {
      "value": "Intel(R) Xeon(R) Platinum 8378C CPU @ 2.80GHz | physical_cores=4 | logical_processors=8",
      "attempted": "Get-CimInstance Win32_Processor | Select-Object -First 1"
    },
    "physical_memory_bytes": {
      "value": "34358808576",
      "attempted": "Get-CimInstance Win32_ComputerSystem"
    },
    "active_power_scheme": {
      "value": "381b4222-f694-41f0-9685-ff5bb260df2e",
      "attempted": "powercfg /GETACTIVESCHEME"
    },
    "native_compiler": {
      "executable": "clang.exe",
      "executable_sha256": "a8b7a614eeadd9105f814be3701a7f312cda4cea51751b75b408c16100c94e85",
      "version": "clang version 22.1.8 (https://github.com/llvm/llvm-project.git ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)\nTarget: x86_64-w64-windows-gnu\nThread model: posix\nInstalledDir: C:/Users/Admin/AppData/Local/Microsoft/WinGet/Packages/MartinStorsjo.LLVM-MinGW.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/llvm-mingw-20260616-ucrt-x86_64/bin\nConfiguration file: C:/Users/Admin/AppData/Local/Microsoft/WinGet/Packages/MartinStorsjo.LLVM-MinGW.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/llvm-mingw-20260616-ucrt-x86_64/bin/x86_64-w64-windows-gnu.cfg",
      "probe": "clang.exe --version"
    }
  },
  "runs": [
    {
      "id": "warmup",
      "label": "excluded warmup",
      "started_utc": "2026-07-29T12:26:40.2013803Z",
      "ended_utc": "2026-07-29T12:33:15.3302181Z",
      "exit_code": 0,
      "output_sha256": "b02128b7c5347f51d17aaa5fd730ae208b12bcba1927a46850ee12425b44baf6",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 1070.0,
          "sigma_ms": 41.62,
          "minimum_ms": 1030.0,
          "maximum_ms": 1150.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 29160.0,
          "sigma_ms": 383.54,
          "minimum_ms": 28710.0,
          "maximum_ms": 29740.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 3.31,
          "sigma_ms": 0.32798,
          "minimum_ms": 2.82,
          "maximum_ms": 3.79,
          "batch_size": 10,
          "runs": 40
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.75,
          "sigma_ms": 0.60681,
          "minimum_ms": 4.22,
          "maximum_ms": 6.12,
          "batch_size": 10,
          "runs": 24
        }
      ]
    },
    {
      "id": "1",
      "label": "retained capture 1",
      "started_utc": "2026-07-29T12:33:15.3769325Z",
      "ended_utc": "2026-07-29T12:39:47.7108605Z",
      "exit_code": 0,
      "output_sha256": "4ba4719f237f0ebc53165b6ee27b228ec75032e8d2966f1f9f666614f04e3ccd",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 1030.0,
          "sigma_ms": 46.16,
          "minimum_ms": 963.91,
          "maximum_ms": 1100.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 28860.0,
          "sigma_ms": 305.82,
          "minimum_ms": 28490.0,
          "maximum_ms": 29330.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.91,
          "sigma_ms": 0.30307,
          "minimum_ms": 2.56,
          "maximum_ms": 3.53,
          "batch_size": 10,
          "runs": 30
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.96,
          "sigma_ms": 0.48845,
          "minimum_ms": 4.31,
          "maximum_ms": 5.79,
          "batch_size": 10,
          "runs": 22
        }
      ]
    },
    {
      "id": "2",
      "label": "retained capture 2",
      "started_utc": "2026-07-29T12:39:47.7176278Z",
      "ended_utc": "2026-07-29T12:46:18.5766946Z",
      "exit_code": 0,
      "output_sha256": "3d142d6cb39166b90fdb582b38f0968d34fd278df155aae80658c796e214e365",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 1030.0,
          "sigma_ms": 48.15,
          "minimum_ms": 974.66,
          "maximum_ms": 1100.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 28690.0,
          "sigma_ms": 251.64,
          "minimum_ms": 28360.0,
          "maximum_ms": 29060.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.96,
          "sigma_ms": 0.16285,
          "minimum_ms": 2.8,
          "maximum_ms": 3.21,
          "batch_size": 10,
          "runs": 37
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 5.16,
          "sigma_ms": 0.33869,
          "minimum_ms": 4.79,
          "maximum_ms": 5.75,
          "batch_size": 10,
          "runs": 21
        }
      ]
    },
    {
      "id": "3",
      "label": "retained capture 3",
      "started_utc": "2026-07-29T12:46:18.5868927Z",
      "ended_utc": "2026-07-29T12:53:12.4290119Z",
      "exit_code": 0,
      "output_sha256": "08639cb4c05d40dab3d2c6fee16dbbd8803eda337ad5b7df09f636dab3c22e4f",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 1110.0,
          "sigma_ms": 42.31,
          "minimum_ms": 1050.0,
          "maximum_ms": 1150.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 30660.0,
          "sigma_ms": 1010.0,
          "minimum_ms": 29070.0,
          "maximum_ms": 31760.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 3.25,
          "sigma_ms": 0.28655,
          "minimum_ms": 2.82,
          "maximum_ms": 3.68,
          "batch_size": 10,
          "runs": 33
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 5.11,
          "sigma_ms": 0.4469,
          "minimum_ms": 4.47,
          "maximum_ms": 5.85,
          "batch_size": 10,
          "runs": 23
        }
      ]
    },
    {
      "id": "4",
      "label": "retained capture 4",
      "started_utc": "2026-07-29T12:53:12.4367010Z",
      "ended_utc": "2026-07-29T12:59:31.1517288Z",
      "exit_code": 0,
      "output_sha256": "1ee2ce32cb8c6005d8d9ecb00fc4d83aded07e704a8b409fcf1e8ba3787b4eae",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 1050.0,
          "sigma_ms": 37.06,
          "minimum_ms": 998.49,
          "maximum_ms": 1130.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 27750.0,
          "sigma_ms": 499.19,
          "minimum_ms": 27120.0,
          "maximum_ms": 28560.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 3.15,
          "sigma_ms": 0.4994,
          "minimum_ms": 2.67,
          "maximum_ms": 4.17,
          "batch_size": 10,
          "runs": 29
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.54,
          "sigma_ms": 0.28081,
          "minimum_ms": 4.05,
          "maximum_ms": 4.93,
          "batch_size": 10,
          "runs": 23
        }
      ]
    },
    {
      "id": "5",
      "label": "retained capture 5",
      "started_utc": "2026-07-29T12:59:31.1587466Z",
      "ended_utc": "2026-07-29T13:05:41.6196381Z",
      "exit_code": 0,
      "output_sha256": "20dbe69c9fa05c1331b3ce5c65cc11beda7b9ef4fa8682ba5ef3a78ea5c923cb",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 988.78,
          "sigma_ms": 58.61,
          "minimum_ms": 912.32,
          "maximum_ms": 1080.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 27250.0,
          "sigma_ms": 322.16,
          "minimum_ms": 26740.0,
          "maximum_ms": 27640.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.82,
          "sigma_ms": 0.30989,
          "minimum_ms": 2.54,
          "maximum_ms": 3.4,
          "batch_size": 10,
          "runs": 32
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.68,
          "sigma_ms": 0.38663,
          "minimum_ms": 4.28,
          "maximum_ms": 5.51,
          "batch_size": 10,
          "runs": 20
        }
      ]
    },
    {
      "id": "6",
      "label": "retained capture 6",
      "started_utc": "2026-07-29T13:05:41.6249398Z",
      "ended_utc": "2026-07-29T13:12:03.2682283Z",
      "exit_code": 0,
      "output_sha256": "7836ffa80069db40bdf9e218462834dd5e3d938a21a9502d8c70ea0076e3ce06",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 997.62,
          "sigma_ms": 40.77,
          "minimum_ms": 945.68,
          "maximum_ms": 1060.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 28080.0,
          "sigma_ms": 345.12,
          "minimum_ms": 27670.0,
          "maximum_ms": 28690.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 3.03,
          "sigma_ms": 0.21555,
          "minimum_ms": 2.75,
          "maximum_ms": 3.4,
          "batch_size": 10,
          "runs": 37
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.62,
          "sigma_ms": 0.35568,
          "minimum_ms": 4.24,
          "maximum_ms": 5.21,
          "batch_size": 10,
          "runs": 20
        }
      ]
    },
    {
      "id": "7",
      "label": "retained capture 7",
      "started_utc": "2026-07-29T13:12:03.2743084Z",
      "ended_utc": "2026-07-29T13:18:11.7646716Z",
      "exit_code": 0,
      "output_sha256": "17c32c0fa92a028e1d4f642c382abae4a00c27f19fcbf7962aaf849bdc86ad83",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 979.43,
          "sigma_ms": 33.66,
          "minimum_ms": 926.39,
          "maximum_ms": 1030.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 27150.0,
          "sigma_ms": 287.35,
          "minimum_ms": 26830.0,
          "maximum_ms": 27660.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.8,
          "sigma_ms": 0.28996,
          "minimum_ms": 2.49,
          "maximum_ms": 3.37,
          "batch_size": 10,
          "runs": 36
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.88,
          "sigma_ms": 0.5448,
          "minimum_ms": 4.23,
          "maximum_ms": 5.63,
          "batch_size": 10,
          "runs": 21
        }
      ]
    }
  ],
  "aggregates": [
    {
      "name": "latin-full-admission",
      "values": {
        "mean_ms": 1026.547142857,
        "median_ms": 1030.0,
        "sample_standard_deviation_ms": 44.761259557,
        "minimum_ms": 979.43,
        "maximum_ms": 1110.0,
        "coefficient_of_variation": 0.043603706
      }
    },
    {
      "name": "cjk-full-admission",
      "values": {
        "mean_ms": 28348.571428571,
        "median_ms": 28080.0,
        "sample_standard_deviation_ms": 1210.694409164,
        "minimum_ms": 27150.0,
        "maximum_ms": 30660.0,
        "coefficient_of_variation": 0.042707422
      }
    },
    {
      "name": "latin-fixed-outline-batch",
      "values": {
        "mean_ms": 2.988571429,
        "median_ms": 2.96,
        "sample_standard_deviation_ms": 0.166876059,
        "minimum_ms": 2.8,
        "maximum_ms": 3.25,
        "coefficient_of_variation": 0.055838069
      }
    },
    {
      "name": "cjk-high-gid-multi-fd-outline-batch",
      "values": {
        "mean_ms": 4.85,
        "median_ms": 4.88,
        "sample_standard_deviation_ms": 0.243104916,
        "minimum_ms": 4.54,
        "maximum_ms": 5.16,
        "coefficient_of_variation": 0.050124725
      }
    }
  ]
}
-->
