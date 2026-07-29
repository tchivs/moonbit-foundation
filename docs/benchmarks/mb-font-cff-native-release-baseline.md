# mb-font CFF1 native release baseline

**Scope:** `observation_only` native release measurements for exact reproduction facts. The record establishes no threshold, regression verdict, cross-library comparison, ranking, superiority, CI timing gate, release decision, or marketing claim.

## Closed identity

- Source Git commit: `efede01c280e654b79c3d12ca1cddabe750a85ec`
- Source tree state: `(clean benchmark inputs; orchestrator auto-chain marker excluded)`
- Exact command: `moon -C benchmarks bench font-cff/cff_bench.mbt --release --target native --frozen`
- Fixed sequence: one excluded warmup followed by seven retained complete captures.

## Workspace and workload provenance

- Workspace members: `../modules/mb-core,../modules/mb-color,../modules/mb-image,../modules/mb-font,./ppm,./font-cff`
- mb-font: `tchivs/mb-font@0.1.0` from tracked `modules/mb-font`; manifest SHA-256 `9f1925d4d2c5a36403881fb31a147c25017e719d452acf537ae0d6e427d75826`; empty cache entries `0`.

| Workload | Fixture | Operation | GIDs | Correctness SHA-256 |
| --- | --- | --- | --- | --- |
| latin-full-admission | source-sans-3.052R | full-admission |  | `18ee23225ee236464bff292ecbb27b8730f0a91a61ef8580565d665e53b976f6` |
| cjk-full-admission | source-han-serif-jp-2.003R | full-admission |  | `9eb460dcf7adf96bf2c6ebd66a06b1ca50d21b17d2b6a4b1af118c222f6575f6` |
| latin-fixed-outline-batch | source-sans-3.052R | outline-batch | 2,3,34,97,321,1024,2477 | `cb351d9e0af5379e261c3e5cd014b77048943419c42a0a52d60be4c8d7f73994` |
| cjk-high-gid-multi-fd-outline-batch | source-han-serif-jp-2.003R | outline-batch | 2,256,2048,8192,16384,17922 | `c5ee2c463a026a7b1cd65206a20c753fc520f3619deb06be84ff993e9c544fd8` |

## Tracked source identities

| Path | Length | SHA-256 |
| --- | ---: | --- |
| `fixtures/font/cff-qualification-cases.json` | 49778 | `bd3aa34dfaae926737fd9a9e05bb8f029a85be037800cd22b39af2308c8da5ba` |
| `fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf` | 334924 | `08df266400933d3178d081a45f94a08814c3e55b4b7dd2e0ff69cb1329f13ab6` |
| `fixtures/font/source-sans-3.052r/qualification.json` | 12189 | `18a2e5a9b3f22cdab80b304642283c3f820e9d040a41fce993293c4658be0e73` |
| `fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf` | 6210796 | `e5f502bb193c28829895b098498f0f9dd8f658c760b0f83656ad41c1137a8785` |
| `fixtures/font/source-han-serif-2.003r/qualification.json` | 14167 | `574e064cace153a7e58bd4095918b1158e6497ff0b671ca660fd42f124d5b99f` |
| `benchmarks/font-cff/generated_cff_evidence.mbt` | 26432203 | `48bec8cf25263521ca93ca0acda49f48f78ab43bbce48968ead9cd2856903135` |
| `benchmarks/font-cff/moon.mod.json` | 262 | `4103bc450bb8dec7708823d8dd60644d08fdd35a0850d826fce82342c940d018` |
| `benchmarks/font-cff/moon.pkg` | 256 | `a22026ab3a2d0a6cea938f029f56a511495234bb57fb62ba3fe2ad32d87b9218` |
| `benchmarks/font-cff/cff_bench.mbt` | 6881 | `11f57939dac0d327c65d7128fc2c0158803d3a36cad4ec40d8ebe9f8b0086ef8` |
| `benchmarks/moon.work` | 139 | `2562fdf6d4dba04d48b32b207764edb6076c1772d0e53ef1e1712e82ebf93895` |
| `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1` | 66248 | `02ee9a2e651ad39c7a5d5fd2b3126be0d709526c4c02a7a03ec550afadb6a57b` |
| `scripts/quality/Test-BenchmarkQualification.ps1` | 8102 | `204901288f0b1691fe1ea0efd3e3ad3165c6349e094a20c3ffb26bbae14ffbec` |

## Toolchain and host

- moon: `moon.exe` SHA-256 `33637c966083a2b86e5074b746db366024f08c55f3b8a766fed804ddb19f98f4`; version output SHA-256 `95c1e2173e065a7534ee6e5a16a56be9d3950139e12b67321fdc0262db049c02`.
- moonc: `moonc.exe` SHA-256 `f4f5528201472d5de11213e4f6a0cca0bfe8be66f04ffa0a23d65dfe163fae92`; version output SHA-256 `b1224a331712d1723675907be52e48e22e50755f93cf73db0a01c55de46bf7c2`.
- moonrun: `moonrun.exe` SHA-256 `641fc857c9696882ac3b5ac8ac75af0d010d252dc7ff9223db5305fe26bc6759`; version output SHA-256 `05f86cdc7a875159e359cb85dfebca0da01c9a9b7e9ebdd85457a9a6643de828`.
- PowerShell: `5.1.22621.6931` (`Desktop`, `powershell.exe`, SHA-256 `3247bcfd60f6dd25f34cb74b5889ab10ef1b3ec72b4d4b3d95b5b25b534560b8`).
- Native compiler: `clang.exe`, SHA-256 `a8b7a614eeadd9105f814be3701a7f312cda4cea51751b75b408c16100c94e85`, probe `clang.exe --version`.
- os: `Microsoft Windows 11 企业版 | version=10.0.22631 | build=22631 | architecture=64 位` (probe `Get-CimInstance Win32_OperatingSystem`).
- cpu: `Intel(R) Xeon(R) Platinum 8378C CPU @ 2.80GHz | physical_cores=4 | logical_processors=8` (probe `Get-CimInstance Win32_Processor | Select-Object -First 1`).
- physical_memory_bytes: `34358808576` (probe `Get-CimInstance Win32_ComputerSystem`).
- active_power_scheme: `381b4222-f694-41f0-9685-ff5bb260df2e` (probe `powercfg /GETACTIVESCHEME`).

## Captures

### Warmup (excluded)
- UTC start: `2026-07-29T09:16:07.8221356Z`
- UTC end: `2026-07-29T09:22:11.0455714Z`
- Exit status: `0`
- Normalized raw output SHA-256: `a69beb561aef5b8b82d6ce61eae31cd32c353093862b71edcd1d59a5f5a9f420`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 965.570000000 | 67.020000000 | 895.090000000 | 1120.000000000 | 10 | 1 |
| cjk-full-admission | 26750.000000000 | 357.920000000 | 26380.000000000 | 27410.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.580000000 | 0.103750000 | 2.460000000 | 2.750000000 | 10 | 42 |
| cjk-high-gid-multi-fd-outline-batch | 4.670000000 | 0.284400000 | 4.210000000 | 4.980000000 | 10 | 23 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;965.57&#32;ms&#32;±&#32;&#32;67.02&#32;ms&#32;&#32;&#32;895.09&#32;ms&#32;…&#32;&#32;&#32;1.12&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.75&#32;s&#32;±&#32;357.92&#32;ms&#32;&#32;&#32;&#32;26.38&#32;s&#32;…&#32;&#32;27.41&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.58&#32;ms&#32;±&#32;103.75&#32;µs&#32;&#32;&#32;&#32;&#32;2.46&#32;ms&#32;…&#32;&#32;&#32;2.75&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;42&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.67&#32;ms&#32;±&#32;284.40&#32;µs&#32;&#32;&#32;&#32;&#32;4.21&#32;ms&#32;…&#32;&#32;&#32;4.98&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;23&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 1
- UTC start: `2026-07-29T09:22:11.1079834Z`
- UTC end: `2026-07-29T09:28:16.8232475Z`
- Exit status: `0`
- Normalized raw output SHA-256: `f2ede9810741df3e830cedf271a505c0265f2ab19e4f29f0e72c857f32897b8f`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 965.970000000 | 83.670000000 | 894.990000000 | 1180.000000000 | 10 | 1 |
| cjk-full-admission | 26930.000000000 | 359.400000000 | 26410.000000000 | 27510.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 3.020000000 | 0.562090000 | 2.560000000 | 4.110000000 | 10 | 40 |
| cjk-high-gid-multi-fd-outline-batch | 4.880000000 | 0.721370000 | 4.120000000 | 6.650000000 | 10 | 23 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;965.97&#32;ms&#32;±&#32;&#32;83.67&#32;ms&#32;&#32;&#32;894.99&#32;ms&#32;…&#32;&#32;&#32;1.18&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.93&#32;s&#32;±&#32;359.40&#32;ms&#32;&#32;&#32;&#32;26.41&#32;s&#32;…&#32;&#32;27.51&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;3.02&#32;ms&#32;±&#32;562.09&#32;µs&#32;&#32;&#32;&#32;&#32;2.56&#32;ms&#32;…&#32;&#32;&#32;4.11&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;40&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.88&#32;ms&#32;±&#32;721.37&#32;µs&#32;&#32;&#32;&#32;&#32;4.12&#32;ms&#32;…&#32;&#32;&#32;6.65&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;23&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 2
- UTC start: `2026-07-29T09:28:16.8362679Z`
- UTC end: `2026-07-29T09:34:07.6875141Z`
- Exit status: `0`
- Normalized raw output SHA-256: `0c9cbf7344d2e5e5f39f7f4083ea199b83e53dabdfdd73785f2b3b8f6c4eaaa0`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 974.970000000 | 80.390000000 | 901.740000000 | 1180.000000000 | 10 | 1 |
| cjk-full-admission | 25710.000000000 | 355.650000000 | 25260.000000000 | 26210.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.740000000 | 0.352110000 | 2.440000000 | 3.530000000 | 10 | 36 |
| cjk-high-gid-multi-fd-outline-batch | 4.330000000 | 0.283370000 | 3.940000000 | 4.770000000 | 10 | 22 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;974.97&#32;ms&#32;±&#32;&#32;80.39&#32;ms&#32;&#32;&#32;901.74&#32;ms&#32;…&#32;&#32;&#32;1.18&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;25.71&#32;s&#32;±&#32;355.65&#32;ms&#32;&#32;&#32;&#32;25.26&#32;s&#32;…&#32;&#32;26.21&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.74&#32;ms&#32;±&#32;352.11&#32;µs&#32;&#32;&#32;&#32;&#32;2.44&#32;ms&#32;…&#32;&#32;&#32;3.53&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;36&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.33&#32;ms&#32;±&#32;283.37&#32;µs&#32;&#32;&#32;&#32;&#32;3.94&#32;ms&#32;…&#32;&#32;&#32;4.77&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;22&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 3
- UTC start: `2026-07-29T09:34:07.7024742Z`
- UTC end: `2026-07-29T09:40:04.7084369Z`
- Exit status: `0`
- Normalized raw output SHA-256: `d5c89d216394457d9c50c3a4a9769843cfb94866a6aabea212b835bd9386beba`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 962.590000000 | 94.530000000 | 864.420000000 | 1210.000000000 | 10 | 1 |
| cjk-full-admission | 26300.000000000 | 288.430000000 | 25950.000000000 | 26700.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.570000000 | 0.094850000 | 2.460000000 | 2.760000000 | 10 | 37 |
| cjk-high-gid-multi-fd-outline-batch | 4.690000000 | 0.556860000 | 4.130000000 | 5.480000000 | 10 | 22 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;962.59&#32;ms&#32;±&#32;&#32;94.53&#32;ms&#32;&#32;&#32;864.42&#32;ms&#32;…&#32;&#32;&#32;1.21&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.30&#32;s&#32;±&#32;288.43&#32;ms&#32;&#32;&#32;&#32;25.95&#32;s&#32;…&#32;&#32;26.70&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.57&#32;ms&#32;±&#32;&#32;94.85&#32;µs&#32;&#32;&#32;&#32;&#32;2.46&#32;ms&#32;…&#32;&#32;&#32;2.76&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;37&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.69&#32;ms&#32;±&#32;556.86&#32;µs&#32;&#32;&#32;&#32;&#32;4.13&#32;ms&#32;…&#32;&#32;&#32;5.48&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;22&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 4
- UTC start: `2026-07-29T09:40:04.7843515Z`
- UTC end: `2026-07-29T09:45:59.1229693Z`
- Exit status: `0`
- Normalized raw output SHA-256: `0561532652b916104faaaef37a504e59ace007d780d0f260c356e47020b78afb`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 929.170000000 | 63.750000000 | 872.340000000 | 1080.000000000 | 10 | 1 |
| cjk-full-admission | 26100.000000000 | 301.940000000 | 25670.000000000 | 26550.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.960000000 | 0.342140000 | 2.470000000 | 3.490000000 | 10 | 32 |
| cjk-high-gid-multi-fd-outline-batch | 4.260000000 | 0.159190000 | 4.070000000 | 4.500000000 | 10 | 24 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;929.17&#32;ms&#32;±&#32;&#32;63.75&#32;ms&#32;&#32;&#32;872.34&#32;ms&#32;…&#32;&#32;&#32;1.08&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.10&#32;s&#32;±&#32;301.94&#32;ms&#32;&#32;&#32;&#32;25.67&#32;s&#32;…&#32;&#32;26.55&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.96&#32;ms&#32;±&#32;342.14&#32;µs&#32;&#32;&#32;&#32;&#32;2.47&#32;ms&#32;…&#32;&#32;&#32;3.49&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;32&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.26&#32;ms&#32;±&#32;159.19&#32;µs&#32;&#32;&#32;&#32;&#32;4.07&#32;ms&#32;…&#32;&#32;&#32;4.50&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;24&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 5
- UTC start: `2026-07-29T09:45:59.1428740Z`
- UTC end: `2026-07-29T09:52:08.0650166Z`
- Exit status: `0`
- Normalized raw output SHA-256: `932903d56b5b2b5d5802c5c543654f19a6b6318629619668fd752bbe4c86c411`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 981.270000000 | 87.870000000 | 898.390000000 | 1170.000000000 | 10 | 1 |
| cjk-full-admission | 27080.000000000 | 673.410000000 | 26390.000000000 | 28080.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.830000000 | 0.260760000 | 2.560000000 | 3.340000000 | 10 | 36 |
| cjk-high-gid-multi-fd-outline-batch | 5.000000000 | 0.389320000 | 4.570000000 | 5.590000000 | 10 | 16 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;981.27&#32;ms&#32;±&#32;&#32;87.87&#32;ms&#32;&#32;&#32;898.39&#32;ms&#32;…&#32;&#32;&#32;1.17&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;27.08&#32;s&#32;±&#32;673.41&#32;ms&#32;&#32;&#32;&#32;26.39&#32;s&#32;…&#32;&#32;28.08&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.83&#32;ms&#32;±&#32;260.76&#32;µs&#32;&#32;&#32;&#32;&#32;2.56&#32;ms&#32;…&#32;&#32;&#32;3.34&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;36&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;5.00&#32;ms&#32;±&#32;389.32&#32;µs&#32;&#32;&#32;&#32;&#32;4.57&#32;ms&#32;…&#32;&#32;&#32;5.59&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;16&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 6
- UTC start: `2026-07-29T09:52:08.0767311Z`
- UTC end: `2026-07-29T09:58:17.6034036Z`
- Exit status: `0`
- Normalized raw output SHA-256: `a3867c382d307180c31404ed74fdddd528ef6e64f9378bc44b1089bc0bb940d9`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 1050.000000000 | 64.180000000 | 964.990000000 | 1180.000000000 | 10 | 1 |
| cjk-full-admission | 26960.000000000 | 458.280000000 | 26300.000000000 | 27450.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.620000000 | 0.210500000 | 2.420000000 | 2.990000000 | 10 | 38 |
| cjk-high-gid-multi-fd-outline-batch | 4.470000000 | 0.281330000 | 4.160000000 | 4.900000000 | 10 | 23 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;1.05&#32;s&#32;±&#32;&#32;64.18&#32;ms&#32;&#32;&#32;964.99&#32;ms&#32;…&#32;&#32;&#32;1.18&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.96&#32;s&#32;±&#32;458.28&#32;ms&#32;&#32;&#32;&#32;26.30&#32;s&#32;…&#32;&#32;27.45&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.62&#32;ms&#32;±&#32;210.50&#32;µs&#32;&#32;&#32;&#32;&#32;2.42&#32;ms&#32;…&#32;&#32;&#32;2.99&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;38&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.47&#32;ms&#32;±&#32;281.33&#32;µs&#32;&#32;&#32;&#32;&#32;4.16&#32;ms&#32;…&#32;&#32;&#32;4.90&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;23&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 7
- UTC start: `2026-07-29T09:58:17.6159201Z`
- UTC end: `2026-07-29T10:04:21.7290379Z`
- Exit status: `0`
- Normalized raw output SHA-256: `619a256854f4a987942ee018b6b33c409beb2660a585916eecbd7054de68edf8`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 990.400000000 | 66.390000000 | 923.270000000 | 1160.000000000 | 10 | 1 |
| cjk-full-admission | 26760.000000000 | 278.200000000 | 26400.000000000 | 27260.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.720000000 | 0.138880000 | 2.560000000 | 3.030000000 | 10 | 40 |
| cjk-high-gid-multi-fd-outline-batch | 4.480000000 | 0.198920000 | 4.290000000 | 4.990000000 | 10 | 23 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:147&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;990.40&#32;ms&#32;±&#32;&#32;66.39&#32;ms&#32;&#32;&#32;923.27&#32;ms&#32;…&#32;&#32;&#32;1.16&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:173&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.76&#32;s&#32;±&#32;278.20&#32;ms&#32;&#32;&#32;&#32;26.40&#32;s&#32;…&#32;&#32;27.26&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:199&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.72&#32;ms&#32;±&#32;138.88&#32;µs&#32;&#32;&#32;&#32;&#32;2.56&#32;ms&#32;…&#32;&#32;&#32;3.03&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;40&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:221&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.48&#32;ms&#32;±&#32;198.92&#32;µs&#32;&#32;&#32;&#32;&#32;4.29&#32;ms&#32;…&#32;&#32;&#32;4.99&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;23&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

## Seven-capture descriptive statistics

| Workload | Mean (ms) | Median (ms) | Sample standard deviation (ms, n-1=6) | Minimum (ms) | Maximum (ms) | Coefficient of variation |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 979.195714286 | 974.970000000 | 36.774501065 | 929.170000000 | 1050.000000000 | 0.037555823 |
| cjk-full-admission | 26548.571428571 | 26760.000000000 | 517.700961670 | 25710.000000000 | 27080.000000000 | 0.019500144 |
| latin-fixed-outline-batch | 2.780000000 | 2.740000000 | 0.167032931 | 2.570000000 | 3.020000000 | 0.060083788 |
| cjk-high-gid-multi-fd-outline-batch | 4.587142857 | 4.480000000 | 0.278430978 | 4.260000000 | 5.000000000 | 0.060698127 |

## Read-only audit

Run `./scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 -Audit`. Audit reads tracked inputs and this committed document only; it executes no MoonBit command and writes no file.

<!-- CFF-BASELINE-DATA
{
    "schema_version":  "mnf-mb-font-cff-native-baseline/1.0.0",
    "claim":  {
                  "type":  "observation_only",
                  "interpretation":  "native release measurements for exact reproduction facts only"
              },
    "identity":  {
                     "git_commit":  "efede01c280e654b79c3d12ca1cddabe750a85ec",
                     "tree_status":  "(clean benchmark inputs; orchestrator auto-chain marker excluded)"
                 },
    "execution":  {
                      "command":  "moon -C benchmarks bench font-cff/cff_bench.mbt --release --target native --frozen",
                      "working_directory":  ".",
                      "target":  "native",
                      "release":  true,
                      "frozen":  true,
                      "output_encoding":  "normalized UTF-8 without BOM",
                      "warmup_count":  1,
                      "retained_capture_count":  7
                  },
    "workspace":  {
                      "member_order":  [
                                           "../modules/mb-core",
                                           "../modules/mb-color",
                                           "../modules/mb-image",
                                           "../modules/mb-font",
                                           "./ppm",
                                           "./font-cff"
                                       ],
                      "resolution":  {
                                         "module":  "tchivs/mb-font",
                                         "version":  "0.1.0",
                                         "manifest_sha256":  "9f1925d4d2c5a36403881fb31a147c25017e719d452acf537ae0d6e427d75826",
                                         "source_root":  "modules/mb-font",
                                         "local":  true,
                                         "tracked":  true,
                                         "empty_cache_entries":  0
                                     }
                  },
    "sources":  [
                    {
                        "path":  "fixtures/font/cff-qualification-cases.json",
                        "length":  49778,
                        "sha256":  "bd3aa34dfaae926737fd9a9e05bb8f029a85be037800cd22b39af2308c8da5ba"
                    },
                    {
                        "path":  "fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf",
                        "length":  334924,
                        "sha256":  "08df266400933d3178d081a45f94a08814c3e55b4b7dd2e0ff69cb1329f13ab6"
                    },
                    {
                        "path":  "fixtures/font/source-sans-3.052r/qualification.json",
                        "length":  12189,
                        "sha256":  "18a2e5a9b3f22cdab80b304642283c3f820e9d040a41fce993293c4658be0e73"
                    },
                    {
                        "path":  "fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf",
                        "length":  6210796,
                        "sha256":  "e5f502bb193c28829895b098498f0f9dd8f658c760b0f83656ad41c1137a8785"
                    },
                    {
                        "path":  "fixtures/font/source-han-serif-2.003r/qualification.json",
                        "length":  14167,
                        "sha256":  "574e064cace153a7e58bd4095918b1158e6497ff0b671ca660fd42f124d5b99f"
                    },
                    {
                        "path":  "benchmarks/font-cff/generated_cff_evidence.mbt",
                        "length":  26432203,
                        "sha256":  "48bec8cf25263521ca93ca0acda49f48f78ab43bbce48968ead9cd2856903135"
                    },
                    {
                        "path":  "benchmarks/font-cff/moon.mod.json",
                        "length":  262,
                        "sha256":  "4103bc450bb8dec7708823d8dd60644d08fdd35a0850d826fce82342c940d018"
                    },
                    {
                        "path":  "benchmarks/font-cff/moon.pkg",
                        "length":  256,
                        "sha256":  "a22026ab3a2d0a6cea938f029f56a511495234bb57fb62ba3fe2ad32d87b9218"
                    },
                    {
                        "path":  "benchmarks/font-cff/cff_bench.mbt",
                        "length":  6881,
                        "sha256":  "11f57939dac0d327c65d7128fc2c0158803d3a36cad4ec40d8ebe9f8b0086ef8"
                    },
                    {
                        "path":  "benchmarks/moon.work",
                        "length":  139,
                        "sha256":  "2562fdf6d4dba04d48b32b207764edb6076c1772d0e53ef1e1712e82ebf93895"
                    },
                    {
                        "path":  "scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1",
                        "length":  66248,
                        "sha256":  "02ee9a2e651ad39c7a5d5fd2b3126be0d709526c4c02a7a03ec550afadb6a57b"
                    },
                    {
                        "path":  "scripts/quality/Test-BenchmarkQualification.ps1",
                        "length":  8102,
                        "sha256":  "204901288f0b1691fe1ea0efd3e3ad3165c6349e094a20c3ffb26bbae14ffbec"
                    }
                ],
    "workloads":  [
                      {
                          "id":  "latin-full-admission",
                          "test_name":  "cff/latin-full-admission",
                          "fixture_id":  "source-sans-3.052R",
                          "operation":  "full-admission",
                          "gids":  [

                                   ],
                          "correctness_input":  "latin-full-admission|source-sans-3.052R|all-2478",
                          "correctness_sha256":  "18ee23225ee236464bff292ecbb27b8730f0a91a61ef8580565d665e53b976f6"
                      },
                      {
                          "id":  "cjk-full-admission",
                          "test_name":  "cff/cjk-full-admission",
                          "fixture_id":  "source-han-serif-jp-2.003R",
                          "operation":  "full-admission",
                          "gids":  [

                                   ],
                          "correctness_input":  "cjk-full-admission|source-han-serif-jp-2.003R|all-17923",
                          "correctness_sha256":  "9eb460dcf7adf96bf2c6ebd66a06b1ca50d21b17d2b6a4b1af118c222f6575f6"
                      },
                      {
                          "id":  "latin-fixed-outline-batch",
                          "test_name":  "cff/latin-fixed-outline-batch",
                          "fixture_id":  "source-sans-3.052R",
                          "operation":  "outline-batch",
                          "gids":  [
                                       2,
                                       3,
                                       34,
                                       97,
                                       321,
                                       1024,
                                       2477
                                   ],
                          "correctness_input":  "latin-fixed-outline-batch|source-sans-3.052R|2,3,34,97,321,1024,2477",
                          "correctness_sha256":  "cb351d9e0af5379e261c3e5cd014b77048943419c42a0a52d60be4c8d7f73994"
                      },
                      {
                          "id":  "cjk-high-gid-multi-fd-outline-batch",
                          "test_name":  "cff/cjk-high-gid-multi-fd-outline-batch",
                          "fixture_id":  "source-han-serif-jp-2.003R",
                          "operation":  "outline-batch",
                          "gids":  [
                                       2,
                                       256,
                                       2048,
                                       8192,
                                       16384,
                                       17922
                                   ],
                          "correctness_input":  "cjk-high-gid-multi-fd-outline-batch|source-han-serif-jp-2.003R|2,256,2048,8192,16384,17922",
                          "correctness_sha256":  "c5ee2c463a026a7b1cd65206a20c753fc520f3619deb06be84ff993e9c544fd8"
                      }
                  ],
    "toolchain":  {
                      "moon":  {
                                   "executable":  "moon.exe",
                                   "executable_sha256":  "33637c966083a2b86e5074b746db366024f08c55f3b8a766fed804ddb19f98f4",
                                   "version_output_sha256":  "95c1e2173e065a7534ee6e5a16a56be9d3950139e12b67321fdc0262db049c02",
                                   "version":  "moon 0.1.20260713 (75c7e1f 2026-07-13) ~\\.moon\\bin\\moon.exe\nmoonc v0.10.4+2cc641edf (2026-07-15) D:\\AI-Data\\moonbit\\bin\\moonc.exe\nmoonrun 0.1.20260713 (75c7e1f 2026-07-13) D:\\AI-Data\\moonbit\\bin\\moonrun.exe\n\nFeature flags enabled: rr_moon_mod,rr_moon_pkg"
                               },
                      "moonc":  {
                                    "executable":  "moonc.exe",
                                    "executable_sha256":  "f4f5528201472d5de11213e4f6a0cca0bfe8be66f04ffa0a23d65dfe163fae92",
                                    "version_output_sha256":  "b1224a331712d1723675907be52e48e22e50755f93cf73db0a01c55de46bf7c2",
                                    "version":  "v0.10.4+2cc641edf (2026-07-15)"
                                },
                      "moonrun":  {
                                      "executable":  "moonrun.exe",
                                      "executable_sha256":  "641fc857c9696882ac3b5ac8ac75af0d010d252dc7ff9223db5305fe26bc6759",
                                      "version_output_sha256":  "05f86cdc7a875159e359cb85dfebca0da01c9a9b7e9ebdd85457a9a6643de828",
                                      "version":  "moonrun 0.1.20260713 (75c7e1f 2026-07-13)"
                                  }
                  },
    "host":  {
                 "powershell":  {
                                    "version":  "5.1.22621.6931",
                                    "edition":  "Desktop",
                                    "executable":  "powershell.exe",
                                    "executable_sha256":  "3247bcfd60f6dd25f34cb74b5889ab10ef1b3ec72b4d4b3d95b5b25b534560b8"
                                },
                 "dotnet_runtime":  "4.0.30319.42000",
                 "os":  {
                            "value":  "Microsoft Windows 11 \u4F01\u4E1A\u7248 | version=10.0.22631 | build=22631 | architecture=64 \u4F4D",
                            "attempted":  "Get-CimInstance Win32_OperatingSystem"
                        },
                 "cpu":  {
                             "value":  "Intel(R) Xeon(R) Platinum 8378C CPU @ 2.80GHz | physical_cores=4 | logical_processors=8",
                             "attempted":  "Get-CimInstance Win32_Processor | Select-Object -First 1"
                         },
                 "physical_memory_bytes":  {
                                               "value":  "34358808576",
                                               "attempted":  "Get-CimInstance Win32_ComputerSystem"
                                           },
                 "active_power_scheme":  {
                                             "value":  "381b4222-f694-41f0-9685-ff5bb260df2e",
                                             "attempted":  "powercfg /GETACTIVESCHEME"
                                         },
                 "native_compiler":  {
                                         "executable":  "clang.exe",
                                         "executable_sha256":  "a8b7a614eeadd9105f814be3701a7f312cda4cea51751b75b408c16100c94e85",
                                         "version":  "clang version 22.1.8 (https://github.com/llvm/llvm-project.git ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)\nTarget: x86_64-w64-windows-gnu\nThread model: posix\nInstalledDir: C:/Users/Admin/AppData/Local/Microsoft/WinGet/Packages/MartinStorsjo.LLVM-MinGW.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/llvm-mingw-20260616-ucrt-x86_64/bin\nConfiguration file: C:/Users/Admin/AppData/Local/Microsoft/WinGet/Packages/MartinStorsjo.LLVM-MinGW.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/llvm-mingw-20260616-ucrt-x86_64/bin/x86_64-w64-windows-gnu.cfg",
                                         "probe":  "clang.exe --version"
                                     }
             },
    "runs":  [
                 {
                     "id":  "warmup",
                     "label":  "excluded warmup",
                     "started_utc":  "2026-07-29T09:16:07.8221356Z",
                     "ended_utc":  "2026-07-29T09:22:11.0455714Z",
                     "exit_code":  0,
                     "output_sha256":  "a69beb561aef5b8b82d6ce61eae31cd32c353093862b71edcd1d59a5f5a9f420",
                     "summaries":  [
                                       {
                                           "name":  "latin-full-admission",
                                           "mean_ms":  965.57,
                                           "sigma_ms":  67.02,
                                           "minimum_ms":  895.09,
                                           "maximum_ms":  1120,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "cjk-full-admission",
                                           "mean_ms":  26750,
                                           "sigma_ms":  357.92,
                                           "minimum_ms":  26380,
                                           "maximum_ms":  27410,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "latin-fixed-outline-batch",
                                           "mean_ms":  2.58,
                                           "sigma_ms":  0.10375,
                                           "minimum_ms":  2.46,
                                           "maximum_ms":  2.75,
                                           "batch_size":  10,
                                           "runs":  42
                                       },
                                       {
                                           "name":  "cjk-high-gid-multi-fd-outline-batch",
                                           "mean_ms":  4.67,
                                           "sigma_ms":  0.2844,
                                           "minimum_ms":  4.21,
                                           "maximum_ms":  4.98,
                                           "batch_size":  10,
                                           "runs":  23
                                       }
                                   ]
                 },
                 {
                     "id":  "1",
                     "label":  "retained capture 1",
                     "started_utc":  "2026-07-29T09:22:11.1079834Z",
                     "ended_utc":  "2026-07-29T09:28:16.8232475Z",
                     "exit_code":  0,
                     "output_sha256":  "f2ede9810741df3e830cedf271a505c0265f2ab19e4f29f0e72c857f32897b8f",
                     "summaries":  [
                                       {
                                           "name":  "latin-full-admission",
                                           "mean_ms":  965.97,
                                           "sigma_ms":  83.67,
                                           "minimum_ms":  894.99,
                                           "maximum_ms":  1180,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "cjk-full-admission",
                                           "mean_ms":  26930,
                                           "sigma_ms":  359.4,
                                           "minimum_ms":  26410,
                                           "maximum_ms":  27510,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "latin-fixed-outline-batch",
                                           "mean_ms":  3.02,
                                           "sigma_ms":  0.56209,
                                           "minimum_ms":  2.56,
                                           "maximum_ms":  4.11,
                                           "batch_size":  10,
                                           "runs":  40
                                       },
                                       {
                                           "name":  "cjk-high-gid-multi-fd-outline-batch",
                                           "mean_ms":  4.88,
                                           "sigma_ms":  0.72137,
                                           "minimum_ms":  4.12,
                                           "maximum_ms":  6.65,
                                           "batch_size":  10,
                                           "runs":  23
                                       }
                                   ]
                 },
                 {
                     "id":  "2",
                     "label":  "retained capture 2",
                     "started_utc":  "2026-07-29T09:28:16.8362679Z",
                     "ended_utc":  "2026-07-29T09:34:07.6875141Z",
                     "exit_code":  0,
                     "output_sha256":  "0c9cbf7344d2e5e5f39f7f4083ea199b83e53dabdfdd73785f2b3b8f6c4eaaa0",
                     "summaries":  [
                                       {
                                           "name":  "latin-full-admission",
                                           "mean_ms":  974.97,
                                           "sigma_ms":  80.39,
                                           "minimum_ms":  901.74,
                                           "maximum_ms":  1180,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "cjk-full-admission",
                                           "mean_ms":  25710,
                                           "sigma_ms":  355.65,
                                           "minimum_ms":  25260,
                                           "maximum_ms":  26210,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "latin-fixed-outline-batch",
                                           "mean_ms":  2.74,
                                           "sigma_ms":  0.35211,
                                           "minimum_ms":  2.44,
                                           "maximum_ms":  3.53,
                                           "batch_size":  10,
                                           "runs":  36
                                       },
                                       {
                                           "name":  "cjk-high-gid-multi-fd-outline-batch",
                                           "mean_ms":  4.33,
                                           "sigma_ms":  0.28337,
                                           "minimum_ms":  3.94,
                                           "maximum_ms":  4.77,
                                           "batch_size":  10,
                                           "runs":  22
                                       }
                                   ]
                 },
                 {
                     "id":  "3",
                     "label":  "retained capture 3",
                     "started_utc":  "2026-07-29T09:34:07.7024742Z",
                     "ended_utc":  "2026-07-29T09:40:04.7084369Z",
                     "exit_code":  0,
                     "output_sha256":  "d5c89d216394457d9c50c3a4a9769843cfb94866a6aabea212b835bd9386beba",
                     "summaries":  [
                                       {
                                           "name":  "latin-full-admission",
                                           "mean_ms":  962.59,
                                           "sigma_ms":  94.53,
                                           "minimum_ms":  864.42,
                                           "maximum_ms":  1210,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "cjk-full-admission",
                                           "mean_ms":  26300,
                                           "sigma_ms":  288.43,
                                           "minimum_ms":  25950,
                                           "maximum_ms":  26700,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "latin-fixed-outline-batch",
                                           "mean_ms":  2.57,
                                           "sigma_ms":  0.09485,
                                           "minimum_ms":  2.46,
                                           "maximum_ms":  2.76,
                                           "batch_size":  10,
                                           "runs":  37
                                       },
                                       {
                                           "name":  "cjk-high-gid-multi-fd-outline-batch",
                                           "mean_ms":  4.69,
                                           "sigma_ms":  0.55686,
                                           "minimum_ms":  4.13,
                                           "maximum_ms":  5.48,
                                           "batch_size":  10,
                                           "runs":  22
                                       }
                                   ]
                 },
                 {
                     "id":  "4",
                     "label":  "retained capture 4",
                     "started_utc":  "2026-07-29T09:40:04.7843515Z",
                     "ended_utc":  "2026-07-29T09:45:59.1229693Z",
                     "exit_code":  0,
                     "output_sha256":  "0561532652b916104faaaef37a504e59ace007d780d0f260c356e47020b78afb",
                     "summaries":  [
                                       {
                                           "name":  "latin-full-admission",
                                           "mean_ms":  929.17,
                                           "sigma_ms":  63.75,
                                           "minimum_ms":  872.34,
                                           "maximum_ms":  1080,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "cjk-full-admission",
                                           "mean_ms":  26100,
                                           "sigma_ms":  301.94,
                                           "minimum_ms":  25670,
                                           "maximum_ms":  26550,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "latin-fixed-outline-batch",
                                           "mean_ms":  2.96,
                                           "sigma_ms":  0.34214,
                                           "minimum_ms":  2.47,
                                           "maximum_ms":  3.49,
                                           "batch_size":  10,
                                           "runs":  32
                                       },
                                       {
                                           "name":  "cjk-high-gid-multi-fd-outline-batch",
                                           "mean_ms":  4.26,
                                           "sigma_ms":  0.15919,
                                           "minimum_ms":  4.07,
                                           "maximum_ms":  4.5,
                                           "batch_size":  10,
                                           "runs":  24
                                       }
                                   ]
                 },
                 {
                     "id":  "5",
                     "label":  "retained capture 5",
                     "started_utc":  "2026-07-29T09:45:59.1428740Z",
                     "ended_utc":  "2026-07-29T09:52:08.0650166Z",
                     "exit_code":  0,
                     "output_sha256":  "932903d56b5b2b5d5802c5c543654f19a6b6318629619668fd752bbe4c86c411",
                     "summaries":  [
                                       {
                                           "name":  "latin-full-admission",
                                           "mean_ms":  981.27,
                                           "sigma_ms":  87.87,
                                           "minimum_ms":  898.39,
                                           "maximum_ms":  1170,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "cjk-full-admission",
                                           "mean_ms":  27080,
                                           "sigma_ms":  673.41,
                                           "minimum_ms":  26390,
                                           "maximum_ms":  28080,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "latin-fixed-outline-batch",
                                           "mean_ms":  2.83,
                                           "sigma_ms":  0.26076,
                                           "minimum_ms":  2.56,
                                           "maximum_ms":  3.34,
                                           "batch_size":  10,
                                           "runs":  36
                                       },
                                       {
                                           "name":  "cjk-high-gid-multi-fd-outline-batch",
                                           "mean_ms":  5,
                                           "sigma_ms":  0.38932,
                                           "minimum_ms":  4.57,
                                           "maximum_ms":  5.59,
                                           "batch_size":  10,
                                           "runs":  16
                                       }
                                   ]
                 },
                 {
                     "id":  "6",
                     "label":  "retained capture 6",
                     "started_utc":  "2026-07-29T09:52:08.0767311Z",
                     "ended_utc":  "2026-07-29T09:58:17.6034036Z",
                     "exit_code":  0,
                     "output_sha256":  "a3867c382d307180c31404ed74fdddd528ef6e64f9378bc44b1089bc0bb940d9",
                     "summaries":  [
                                       {
                                           "name":  "latin-full-admission",
                                           "mean_ms":  1050,
                                           "sigma_ms":  64.18,
                                           "minimum_ms":  964.99,
                                           "maximum_ms":  1180,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "cjk-full-admission",
                                           "mean_ms":  26960,
                                           "sigma_ms":  458.28,
                                           "minimum_ms":  26300,
                                           "maximum_ms":  27450,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "latin-fixed-outline-batch",
                                           "mean_ms":  2.62,
                                           "sigma_ms":  0.2105,
                                           "minimum_ms":  2.42,
                                           "maximum_ms":  2.99,
                                           "batch_size":  10,
                                           "runs":  38
                                       },
                                       {
                                           "name":  "cjk-high-gid-multi-fd-outline-batch",
                                           "mean_ms":  4.47,
                                           "sigma_ms":  0.28133,
                                           "minimum_ms":  4.16,
                                           "maximum_ms":  4.9,
                                           "batch_size":  10,
                                           "runs":  23
                                       }
                                   ]
                 },
                 {
                     "id":  "7",
                     "label":  "retained capture 7",
                     "started_utc":  "2026-07-29T09:58:17.6159201Z",
                     "ended_utc":  "2026-07-29T10:04:21.7290379Z",
                     "exit_code":  0,
                     "output_sha256":  "619a256854f4a987942ee018b6b33c409beb2660a585916eecbd7054de68edf8",
                     "summaries":  [
                                       {
                                           "name":  "latin-full-admission",
                                           "mean_ms":  990.4,
                                           "sigma_ms":  66.39,
                                           "minimum_ms":  923.27,
                                           "maximum_ms":  1160,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "cjk-full-admission",
                                           "mean_ms":  26760,
                                           "sigma_ms":  278.2,
                                           "minimum_ms":  26400,
                                           "maximum_ms":  27260,
                                           "batch_size":  10,
                                           "runs":  1
                                       },
                                       {
                                           "name":  "latin-fixed-outline-batch",
                                           "mean_ms":  2.72,
                                           "sigma_ms":  0.13888,
                                           "minimum_ms":  2.56,
                                           "maximum_ms":  3.03,
                                           "batch_size":  10,
                                           "runs":  40
                                       },
                                       {
                                           "name":  "cjk-high-gid-multi-fd-outline-batch",
                                           "mean_ms":  4.48,
                                           "sigma_ms":  0.19892,
                                           "minimum_ms":  4.29,
                                           "maximum_ms":  4.99,
                                           "batch_size":  10,
                                           "runs":  23
                                       }
                                   ]
                 }
             ],
    "aggregates":  [
                       {
                           "name":  "latin-full-admission",
                           "values":  {
                                          "mean_ms":  979.195714286,
                                          "median_ms":  974.97,
                                          "sample_standard_deviation_ms":  36.774501065,
                                          "minimum_ms":  929.17,
                                          "maximum_ms":  1050,
                                          "coefficient_of_variation":  0.037555823
                                      }
                       },
                       {
                           "name":  "cjk-full-admission",
                           "values":  {
                                          "mean_ms":  26548.571428571,
                                          "median_ms":  26760,
                                          "sample_standard_deviation_ms":  517.70096167,
                                          "minimum_ms":  25710,
                                          "maximum_ms":  27080,
                                          "coefficient_of_variation":  0.019500144
                                      }
                       },
                       {
                           "name":  "latin-fixed-outline-batch",
                           "values":  {
                                          "mean_ms":  2.78,
                                          "median_ms":  2.74,
                                          "sample_standard_deviation_ms":  0.167032931,
                                          "minimum_ms":  2.57,
                                          "maximum_ms":  3.02,
                                          "coefficient_of_variation":  0.060083788
                                      }
                       },
                       {
                           "name":  "cjk-high-gid-multi-fd-outline-batch",
                           "values":  {
                                          "mean_ms":  4.587142857,
                                          "median_ms":  4.48,
                                          "sample_standard_deviation_ms":  0.278430978,
                                          "minimum_ms":  4.26,
                                          "maximum_ms":  5,
                                          "coefficient_of_variation":  0.060698127
                                      }
                       }
                   ]
}
-->
