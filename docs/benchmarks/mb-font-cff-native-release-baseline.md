# mb-font CFF1 native release baseline

**Scope:** `observation_only` native release measurements for exact reproduction facts. The record establishes no threshold, regression verdict, cross-library comparison, ranking, superiority, CI timing gate, release decision, or marketing claim.

## Closed identity

- Source Git commit: `a890f3cef8aeccd0f52c63513d9d952c2d85c2b6`
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
| `fixtures/font/cff-qualification-cases.json` | 49792 | `e6ede29984b048a51837e317796bf3baf5a5cfbb7a226d60502b36c72da1c16b` |
| `fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf` | 334924 | `08df266400933d3178d081a45f94a08814c3e55b4b7dd2e0ff69cb1329f13ab6` |
| `fixtures/font/source-sans-3.052r/qualification.json` | 12625 | `2bbea30dd8133e3a8890e3f2263e7120f7c102b0b24a0e3eb3e1187341e3a08f` |
| `fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf` | 6210796 | `e5f502bb193c28829895b098498f0f9dd8f658c760b0f83656ad41c1137a8785` |
| `fixtures/font/source-han-serif-2.003r/qualification.json` | 15556 | `0fef79e962fb1abd23d6982f8271a7cc79491470363d45f50c7c63f3ddad4dcf` |
| `benchmarks/font-cff/generated_cff_evidence.mbt` | 26432302 | `d533c6f54f6a83e16d6c43527f9f8b73ccd63e15dfab032de57e2af5c397d0fb` |
| `benchmarks/font-cff/moon.mod.json` | 262 | `4103bc450bb8dec7708823d8dd60644d08fdd35a0850d826fce82342c940d018` |
| `benchmarks/font-cff/moon.pkg` | 256 | `a22026ab3a2d0a6cea938f029f56a511495234bb57fb62ba3fe2ad32d87b9218` |
| `benchmarks/font-cff/cff_runtime_semantics.mbt` | 5792 | `d7a2f21212bb9ee058ec55797612b2d28bf52eb034df0789176378b7ca56d970` |
| `benchmarks/font-cff/cff_bench.mbt` | 7522 | `05aaf80f6d2e5eb6dbda4824668de1af91a9ff542b9e9def3720c24c554851da` |
| `benchmarks/moon.work` | 139 | `2562fdf6d4dba04d48b32b207764edb6076c1772d0e53ef1e1712e82ebf93895` |
| `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1` | 71451 | `6398d93d1061d5137f8455790c95a57c12580159b6439645690a2aed52027b00` |
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
- UTC start: `2026-07-29T17:29:41.9883236Z`
- UTC end: `2026-07-29T17:37:20.3746337Z`
- Exit status: `0`
- Normalized raw output SHA-256: `558f611cceb52bb414357018f2c36f5e7bb318e4c944ee8116288133b3ed736b`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 958.630000000 | 36.470000000 | 908.860000000 | 1020.000000000 | 10 | 1 |
| cjk-full-admission | 26560.000000000 | 414.460000000 | 25900.000000000 | 27290.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.850000000 | 0.344830000 | 2.600000000 | 3.450000000 | 10 | 40 |
| cjk-high-gid-multi-fd-outline-batch | 4.590000000 | 0.314350000 | 4.180000000 | 5.110000000 | 10 | 21 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\metrics.mbt:454:24:&#32;warning:&#32;expression&#32;result&#32;unused&#32;[-Wunused-value]
&#32;&#32;454&#32;|&#32;&#32;&#32;&#32;&#32;&#32;&#32;_M0L5_2aOkS5167-&gt;$0;
&#32;&#32;&#32;&#32;&#32;&#32;|&#32;&#32;&#32;&#32;&#32;&#32;&#32;~~~~~~~~~~~~~~~&#32;&#32;^~
1&#32;warning&#32;generated.
Warning:&#32;[0024]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\cff_bench.mbt:95:11&#32;]
&#32;&#32;&#32;&#32;│
&#32;95&#32;│&#32;)&#32;-&gt;&#32;Unit&#32;raise&#32;{
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_error_type):&#32;The&#32;error&#32;type&#32;of&#32;this&#32;function&#32;is&#32;never&#32;used.
────╯
Warning:&#32;[0024]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\cff_bench.mbt:115:17&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;115&#32;│&#32;)&#32;-&gt;&#32;@font.Font&#32;raise&#32;{
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_error_type):&#32;The&#32;error&#32;type&#32;of&#32;this&#32;function&#32;is&#32;never&#32;used.
─────╯
Warning:&#32;[0024]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\cff_bench.mbt:127:27&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;127&#32;│&#32;)&#32;-&gt;&#32;Array[@font.GlyphId]&#32;raise&#32;{
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_error_type):&#32;The&#32;error&#32;type&#32;of&#32;this&#32;function&#32;is&#32;never&#32;used.
─────╯
Warning:&#32;[0024]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\cff_bench.mbt:139:11&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;139&#32;│&#32;)&#32;-&gt;&#32;Unit&#32;raise&#32;{
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_error_type):&#32;The&#32;error&#32;type&#32;of&#32;this&#32;function&#32;is&#32;never&#32;used.
─────╯
Warning:&#32;[0020]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\cff_qualification_wbtest.mbt:250:11&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;250&#32;│&#32;&#32;&#32;inspect(error.context(),&#32;content="Some(font-source-revision-drift)")
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;───────┬───────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────────&#32;Warning&#32;(deprecated):&#32;Use&#32;Debug&#32;instead&#32;of&#32;Show&#32;for&#32;debugging&#32;purposes.&#32;See&#32;https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:9:3&#32;]
&#32;&#32;&#32;│
&#32;9&#32;│&#32;&#32;&#32;op&#32;:&#32;String
&#32;&#32;&#32;│&#32;&#32;&#32;─┬&#32;&#32;
&#32;&#32;&#32;│&#32;&#32;&#32;&#32;╰──&#32;Warning&#32;(unused_field):&#32;Field&#32;'op'&#32;is&#32;never&#32;read
───╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:10:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;10&#32;│&#32;&#32;&#32;points&#32;:&#32;Array[Int]
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'points'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:15:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;15&#32;│&#32;&#32;&#32;id&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─┬&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;╰──&#32;Warning&#32;(unused_field):&#32;Field&#32;'id'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:20:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;20&#32;│&#32;&#32;&#32;kerning&#32;:&#32;Int
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───┬───&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;╰─────&#32;Warning&#32;(unused_field):&#32;Field&#32;'kerning'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:21:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;21&#32;│&#32;&#32;&#32;bounds&#32;:&#32;Array[Int]
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'bounds'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:22:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;22&#32;│&#32;&#32;&#32;path&#32;:&#32;Array[CffEvidencePathCommand]
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬─&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰───&#32;Warning&#32;(unused_field):&#32;Field&#32;'path'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:27:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;27&#32;│&#32;&#32;&#32;group&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'group'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:28:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;28&#32;│&#32;&#32;&#32;id&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─┬&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;╰──&#32;Warning&#32;(unused_field):&#32;Field&#32;'id'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:29:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;29&#32;│&#32;&#32;&#32;source&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'source'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:30:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;30&#32;│&#32;&#32;&#32;category&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;────┬───&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────&#32;Warning&#32;(unused_field):&#32;Field&#32;'category'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:31:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;31&#32;│&#32;&#32;&#32;code&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬─&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰───&#32;Warning&#32;(unused_field):&#32;Field&#32;'code'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:32:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;32&#32;│&#32;&#32;&#32;operation&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;────┬────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────&#32;Warning&#32;(unused_field):&#32;Field&#32;'operation'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:33:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;33&#32;│&#32;&#32;&#32;requested&#32;:&#32;Int?
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;────┬────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────&#32;Warning&#32;(unused_field):&#32;Field&#32;'requested'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:34:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;34&#32;│&#32;&#32;&#32;limit&#32;:&#32;Int?
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'limit'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:35:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;35&#32;│&#32;&#32;&#32;context&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───┬───&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;╰─────&#32;Warning&#32;(unused_field):&#32;Field&#32;'context'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:36:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;36&#32;│&#32;&#32;&#32;gid&#32;:&#32;Int?
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─┬─&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;╰───&#32;Warning&#32;(unused_field):&#32;Field&#32;'gid'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:37:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;37&#32;│&#32;&#32;&#32;publication&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─────┬─────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰───────&#32;Warning&#32;(unused_field):&#32;Field&#32;'publication'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:38:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;38&#32;│&#32;&#32;&#32;caller_before&#32;:&#32;Array[Int]
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──────┬──────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'caller_before'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:39:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;39&#32;│&#32;&#32;&#32;caller_after&#32;:&#32;Array[Int]
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──────┬─────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰───────&#32;Warning&#32;(unused_field):&#32;Field&#32;'caller_after'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:40:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;40&#32;│&#32;&#32;&#32;ancestor_before&#32;:&#32;Array[Int]
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───────┬───────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'ancestor_before'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:41:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;41&#32;│&#32;&#32;&#32;ancestor_after&#32;:&#32;Array[Int]
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───────┬──────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'ancestor_after'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:42:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;42&#32;│&#32;&#32;&#32;boundary_pair&#32;:&#32;String?
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──────┬──────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'boundary_pair'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:43:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;43&#32;│&#32;&#32;&#32;boundary_kind&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──────┬──────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'boundary_kind'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:44:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;44&#32;│&#32;&#32;&#32;boundary_dimension&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─────────┬────────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'boundary_dimension'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:45:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;45&#32;│&#32;&#32;&#32;boundary_applicable&#32;:&#32;Bool
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─────────┬─────────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰───────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'boundary_applicable'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:46:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;46&#32;│&#32;&#32;&#32;boundary_reason&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───────┬───────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'boundary_reason'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:62:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;62&#32;│&#32;&#32;&#32;id&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─┬&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;╰──&#32;Warning&#32;(unused_field):&#32;Field&#32;'id'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:63:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;63&#32;│&#32;&#32;&#32;canonical_json&#32;:&#32;String
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───────┬──────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'canonical_json'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:9738:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;9738&#32;│&#32;fn&#32;cff_evidence_generated_name_otf()&#32;-&gt;&#32;Bytes&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;───────────────┬───────────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_generated_name_otf'
──────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:9743:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;9743&#32;│&#32;fn&#32;cff_evidence_generated_cid_otf()&#32;-&gt;&#32;Bytes&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;───────────────┬──────────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_generated_cid_otf'
──────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:9748:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;9748&#32;│&#32;fn&#32;cff_evidence_generated_shared_ttc()&#32;-&gt;&#32;Bytes&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;────────────────┬────────────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_generated_shared_ttc'
──────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:10049:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;10049&#32;│&#32;fn&#32;cff_evidence_hostile_rows()&#32;-&gt;&#32;Array[CffEvidenceHostileRow]&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;────────────┬────────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_hostile_rows'
───────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:11221:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;11221&#32;│&#32;fn&#32;cff_evidence_targets()&#32;-&gt;&#32;Array[String]&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;──────────┬─────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰───────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_targets'
───────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:11268:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;11268&#32;│&#32;fn&#32;cff_evidence_public_workflow_ids()&#32;-&gt;&#32;Array[String]&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;────────────────┬───────────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_public_workflow_ids'
───────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:11273:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;11273&#32;│&#32;fn&#32;cff_evidence_compatibility_lock_ids()&#32;-&gt;&#32;Array[String]&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;─────────────────┬─────────────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰───────────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_compatibility_lock_ids'
───────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:11278:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;11278&#32;│&#32;fn&#32;cff_evidence_b8_order()&#32;-&gt;&#32;Array[String]&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;──────────┬──────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_b8_order'
───────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:11283:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;11283&#32;│&#32;fn&#32;cff_evidence_generated_workflows()&#32;-&gt;&#32;Array[CffEvidenceClosedFact]&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;────────────────┬───────────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_generated_workflows'
───────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\generated_cff_evidence.mbt:11313:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;11313&#32;│&#32;fn&#32;cff_evidence_precedence_facts()&#32;-&gt;&#32;Array[CffEvidenceClosedFact]&#32;{
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;──────────────┬──────────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'cff_evidence_precedence_facts'
───────╯
Warning:&#32;[0029]
&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\moon.pkg:5:3&#32;]
&#32;&#32;&#32;│
&#32;5&#32;│&#32;&#32;&#32;"tchivs/mb-core/error"&#32;@error,
&#32;&#32;&#32;│&#32;&#32;&#32;───────────┬──────────&#32;&#32;
&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────────&#32;Warning&#32;(unused_package):&#32;Unused&#32;package&#32;'tchivs/mb-core/error'
───╯
Warning:&#32;[0029]
&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\benchmarks\font-cff\moon.pkg:5:26&#32;]
&#32;&#32;&#32;│
&#32;5&#32;│&#32;&#32;&#32;"tchivs/mb-core/error"&#32;@error,
&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;───┬──&#32;&#32;
&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_package):&#32;Unused&#32;package&#32;alias&#32;'error'
───╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_admission.mbt:56:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;56&#32;│&#32;&#32;&#32;bytes&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'bytes'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_admission.mbt:57:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;57&#32;│&#32;&#32;&#32;allocations&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─────┬─────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰───────&#32;Warning&#32;(unused_field):&#32;Field&#32;'allocations'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_admission.mbt:58:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;58&#32;│&#32;&#32;&#32;allocation_size&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───────┬───────&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'allocation_size'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:132:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;132&#32;│&#32;&#32;&#32;width&#32;:&#32;Type2Fixed?
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'width'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:133:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;133&#32;│&#32;&#32;&#32;stems&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'stems'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:134:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;134&#32;│&#32;&#32;&#32;terminated&#32;:&#32;Bool
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─────┬────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────&#32;Warning&#32;(unused_field):&#32;Field&#32;'terminated'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:142:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;142&#32;│&#32;&#32;&#32;resource&#32;:&#32;@budget.ResourceCharge
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;────┬───&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────&#32;Warning&#32;(unused_field):&#32;Field&#32;'resource'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:147:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;147&#32;│&#32;&#32;&#32;bounds_slots&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──────┬─────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰───────&#32;Warning&#32;(unused_field):&#32;Field&#32;'bounds_slots'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:148:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;148&#32;│&#32;&#32;&#32;executed_bytes&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───────┬──────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'executed_bytes'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:149:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;149&#32;│&#32;&#32;&#32;calls&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'calls'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:150:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;150&#32;│&#32;&#32;&#32;returns&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───┬───&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;╰─────&#32;Warning&#32;(unused_field):&#32;Field&#32;'returns'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:151:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;151&#32;│&#32;&#32;&#32;operators&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;────┬────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────&#32;Warning&#32;(unused_field):&#32;Field&#32;'operators'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:152:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;152&#32;│&#32;&#32;&#32;numbers&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───┬───&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;╰─────&#32;Warning&#32;(unused_field):&#32;Field&#32;'numbers'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:153:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;153&#32;│&#32;&#32;&#32;mask_bytes&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─────┬────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────&#32;Warning&#32;(unused_field):&#32;Field&#32;'mask_bytes'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:154:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;154&#32;│&#32;&#32;&#32;geometry_operators&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─────────┬────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'geometry_operators'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:155:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;155&#32;│&#32;&#32;&#32;points&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───┬──&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'points'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:156:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;156&#32;│&#32;&#32;&#32;contours&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;────┬───&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────&#32;Warning&#32;(unused_field):&#32;Field&#32;'contours'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:157:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;157&#32;│&#32;&#32;&#32;commands&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;────┬───&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────&#32;Warning&#32;(unused_field):&#32;Field&#32;'commands'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:1563:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;1563&#32;│&#32;fn&#32;type2_execute_program(
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;──────────┬──────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'type2_execute_program'
──────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2.mbt:2466:4&#32;]
&#32;&#32;&#32;&#32;&#32;&#32;│
&#32;2466&#32;│&#32;fn&#32;type2_stage_all_glyphs(
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;───────────┬──────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰────────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'type2_stage_all_glyphs'
──────╯
Warning:&#32;[0007]
&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_bounds.mbt:3:3&#32;]
&#32;&#32;&#32;│
&#32;3&#32;│&#32;&#32;&#32;current_x&#32;:&#32;Type2Fixed
&#32;&#32;&#32;│&#32;&#32;&#32;────┬────&#32;&#32;
&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────&#32;Warning&#32;(unused_field):&#32;Field&#32;'current_x'&#32;is&#32;never&#32;read
───╯
Warning:&#32;[0007]
&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_bounds.mbt:4:3&#32;]
&#32;&#32;&#32;│
&#32;4&#32;│&#32;&#32;&#32;current_y&#32;:&#32;Type2Fixed
&#32;&#32;&#32;│&#32;&#32;&#32;────┬────&#32;&#32;
&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────&#32;Warning&#32;(unused_field):&#32;Field&#32;'current_y'&#32;is&#32;never&#32;read
───╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_bounds.mbt:10:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;10&#32;│&#32;&#32;&#32;min_x&#32;:&#32;Type2Fixed
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'min_x'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_bounds.mbt:11:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;11&#32;│&#32;&#32;&#32;min_y&#32;:&#32;Type2Fixed
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'min_y'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_bounds.mbt:12:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;12&#32;│&#32;&#32;&#32;max_x&#32;:&#32;Type2Fixed
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'max_x'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_bounds.mbt:13:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;13&#32;│&#32;&#32;&#32;max_y&#32;:&#32;Type2Fixed
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'max_y'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_bounds.mbt:18:3&#32;]
&#32;&#32;&#32;&#32;│
&#32;18&#32;│&#32;&#32;&#32;bounds&#32;:&#32;GlyphBoundsFacts?
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───┬──&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'bounds'&#32;is&#32;never&#32;read
────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_bounds.mbt:57:21&#32;]
&#32;&#32;&#32;&#32;│
&#32;57&#32;│&#32;fn&#32;Type2BoundsSink::new(
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;─┬─&#32;&#32;
&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰───&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'new'
────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_path.mbt:121:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;121&#32;│&#32;&#32;&#32;bytes&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬──&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰────&#32;Warning&#32;(unused_field):&#32;Field&#32;'bytes'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_path.mbt:122:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;122&#32;│&#32;&#32;&#32;allocations&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;─────┬─────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰───────&#32;Warning&#32;(unused_field):&#32;Field&#32;'allocations'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_path.mbt:123:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;123&#32;│&#32;&#32;&#32;allocation_size&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;───────┬───────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'allocation_size'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_path.mbt:124:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;124&#32;│&#32;&#32;&#32;work&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;──┬─&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;╰───&#32;Warning&#32;(unused_field):&#32;Field&#32;'work'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0007]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_path.mbt:125:3&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;125&#32;│&#32;&#32;&#32;command_capacity&#32;:&#32;UInt64
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;────────┬───────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰─────────&#32;Warning&#32;(unused_field):&#32;Field&#32;'command_capacity'&#32;is&#32;never&#32;read
─────╯
Warning:&#32;[0001]
&#32;&#32;&#32;&#32;&#32;╭─[&#32;D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\font.mbt:228:10&#32;]
&#32;&#32;&#32;&#32;&#32;│
&#32;228&#32;│&#32;fn&#32;Font::glyf_metric_index(self&#32;:&#32;Font)&#32;-&gt;&#32;MetricIndexFacts&#32;{
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;────────┬────────&#32;&#32;
&#32;&#32;&#32;&#32;&#32;│&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;╰──────────&#32;Warning&#32;(unused_value):&#32;Unused&#32;function&#32;'glyf_metric_index'
─────╯
MNF_CFF_BENCH_CORRECTNESS|latin-full-admission|cff-runtime-semantics/1|workload=latin-full-admission|fixture=source-sans-3.052R|source_length=334924|operation=full-admission|scalar=65|mapped_gid=2|kerning=0|gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z]
MNF_CFF_BENCH_CORRECTNESS|cjk-full-admission|cff-runtime-semantics/1|workload=cjk-full-admission|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=full-admission|scalar=65|mapped_gid=34|kerning=0|gid=34,advance=718,lsb=12,bounds=12,0,711,734,path=21[M(332,643);L(450,281);L(216,281);Z;M(418,0);L(711,0);L(711,30);L(619,38);L(384,734);L(328,734);L(97,40);L(12,30);L(12,0);L(236,0);L(236,30);L(139,40);L(206,249);L(461,249);L(529,39);L(418,30);Z]
MNF_CFF_BENCH_CORRECTNESS|latin-fixed-outline-batch|cff-runtime-semantics/1|workload=latin-fixed-outline-batch|fixture=source-sans-3.052R|source_length=334924|operation=outline-batch|glyphs=7[gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z];gid=3,advance=588,lsb=90,bounds=90,0,548,656,path=21[M(90,0);L(299,0);C(446,0,548,64,548,195);C(548,283,496,334,414,349);L(414,353);C(476,373,510,428,510,496);C(510,611,418,656,285,656);L(90,656);Z;M(173,377);L(173,590);L(274,590);C(376,590,428,561,428,485);C(428,418,382,377,270,377);Z;M(173,66);L(173,313);L(287,313);C(402,313,466,276,466,195);C(466,107,400,66,287,66);Z];gid=34,advance=504,lsb=45,bounds=45,-224,492,498,path=37[M(246,-224);C(397,-224,492,-146,492,-56);C(492,25,435,60,322,60);L(228,60);C(162,60,142,82,142,113);C(142,140,156,156,173,171);C(195,160,222,154,246,154);C(345,154,424,219,424,322);C(424,366,406,398,383,419);L(383,423);L(484,423);L(484,486);L(315,486);C(297,493,273,498,246,498);C(147,498,63,431,63,325);C(63,267,94,220,126,194);L(126,190);C(101,173,73,141,73,100);C(73,62,92,36,116,21);L(116,17);C(72,-13,45,-52,45,-93);C(45,-177,127,-224,246,-224);Z;M(246,209);C(190,209,143,254,143,325);C(143,396,189,438,246,438);C(303,438,349,396,349,325);C(349,254,302,209,246,209);Z;M(258,-167);C(170,-167,117,-134,117,-82);C(117,-54,132,-25,167,0);C(188,-6,211,-8,230,-8);L(314,-8);C(377,-8,412,-23,412,-68);C(412,-119,351,-167,258,-167);Z];gid=97,advance=615,lsb=90,bounds=90,-165,564,656,path=17[M(90,0);L(258,0);C(456,0,564,122,564,331);C(564,539,456,656,254,656);L(90,656);Z;M(173,68);L(173,588);L(248,588);C(401,588,478,496,478,331);C(478,165,401,68,248,68);Z;M(168,-165);L(434,-165);L(434,-108);L(168,-108);Z];gid=321,advance=645,lsb=87,bounds=87,-219,558,841,path=25[M(336,-219);C(370,-219,405,-204,426,-187);L(403,-140);C(388,-151,372,-157,352,-157);C(324,-157,299,-142,299,-107);C(299,-67,332,-20,378,-9);C(494,19,558,99,558,271);L(558,656);L(478,656);L(478,269);C(478,110,410,60,323,60);C(237,60,170,110,170,269);L(170,656);L(87,656);L(87,271);C(87,77,173,0,291,-11);C(259,-39,231,-81,231,-127);C(231,-189,278,-219,336,-219);Z;M(245,706);L(319,706);L(482,832);L(478,841);L(377,841);Z];gid=1024,advance=535,lsb=46,bounds=46,-12,489,762,path=25[M(267,-12);C(389,-12,489,80,489,242);C(489,406,389,498,267,498);C(146,498,46,406,46,242);C(46,80,146,-12,267,-12);Z;M(267,56);C(181,56,131,130,131,242);C(131,355,181,430,267,430);C(353,430,404,355,404,242);C(404,130,353,56,267,56);Z;M(170,560);C(222,572,277,606,277,670);C(277,730,219,759,138,762);L(134,711);C(187,708,213,691,213,660);C(213,632,193,609,161,600);Z;M(303,564);L(351,564);L(416,744);L(411,754);L(338,754);Z];gid=2477,advance=425,lsb=48,bounds=48,-8,367,550,path=18[M(160,198);L(232,198);C(217,294,367,301,367,424);C(367,501,305,550,210,550);C(141,550,89,522,48,484);L(88,436);C(122,469,159,485,200,485);C(258,485,287,453,287,414);C(287,321,140,305,160,198);Z;M(89,-8);L(137,-8);C(136,53,161,78,199,78);C(236,78,261,53,260,-8);L(308,-8);C(312,90,270,138,199,138);C(127,138,85,90,89,-8);Z]]
MNF_CFF_BENCH_CORRECTNESS|cjk-high-gid-multi-fd-outline-batch|cff-runtime-semantics/1|workload=cjk-high-gid-multi-fd-outline-batch|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=outline-batch|glyphs=6[gid=2,advance=308,lsb=95,bounds=95,-13,214,747,path=15[M(154,-13);C(189,-13,214,14,214,46);C(214,79,189,104,154,104);C(120,104,95,79,95,46);C(95,14,120,-13,154,-13);Z;M(154,747);C(122,747,102,728,102,689);C(102,637,113,554,129,412);L(141,217);L(167,217);L(180,412);C(196,554,206,637,206,689);C(206,728,186,747,154,747);Z];gid=256,advance=0,lsb=314,bounds=314,484,685,826,path=7[M(499,592);L(342,825);L(314,810);L(496,484);L(685,811);L(657,826);Z];gid=2048,advance=1000,lsb=32,bounds=32,-89,986,832,path=88[M(84,664);L(68,660);C(91,585,117,472,113,387);C(167,328,220,475,84,664);Z;M(368,667);C(359,599,332,464,309,377);L(322,373);C(365,450,407,553,429,610);C(450,609,461,620,463,628);Z;M(849,826);L(837,819);C(859,793,882,748,882,713);C(931,670,986,769,849,826);Z;M(49,761);L(57,732);L(219,732);L(219,314);L(32,314);L(40,285);L(219,285);L(219,-83);L(228,-83);C(258,-83,277,-68,277,-63);L(277,285);L(457,285);C(471,285,481,290,484,301);C(454,331,406,370,406,370);L(364,314);L(277,314);L(277,732);L(441,732);C(455,732,465,737,468,748);C(439,776,391,815,391,815);L(349,761);Z;M(503,633);L(503,384);C(503,226,497,60,413,-73);L(428,-84);C(553,47,561,238,561,385);L(561,408);L(640,408);C(639,216,635,144,623,126);C(620,122,618,120,612,120);C(601,120,574,121,557,122);L(557,106);C(574,102,590,97,598,90);C(607,83,611,67,611,57);C(630,58,647,64,662,78);C(690,107,691,186,693,403);C(712,405,724,410,731,418);L(662,473);L(630,438);L(561,438);L(561,603);L(731,603);C(735,432,747,281,781,159);C(743,74,692,-3,626,-64);L(638,-76);C(705,-27,758,35,799,102);C(816,58,836,19,861,-15);C(888,-56,940,-89,964,-65);C(973,-56,970,-41,948,-1);L(964,152);L(951,154);C(941,114,926,69,917,45);C(908,24,905,23,894,41);C(869,75,849,117,834,166);C(882,264,911,369,929,463);C(957,463,965,469,970,482);L(871,505);C(862,422,844,332,815,245);C(794,350,788,473,787,603);L(944,603);C(958,603,967,608,970,619);C(941,648,894,686,894,686);L(852,633);L(787,633);L(788,792);C(813,795,822,807,824,819);L(729,832);L(730,633);L(572,633);L(503,664);Z];gid=8192,advance=1000,lsb=45,bounds=43,-117,1007,841,path=87[M(581,595);L(581,266);L(593,266);C(617,266,643,279,643,287);L(643,559);C(667,563,676,571,678,584);Z;M(786,611);L(786,246);C(786,233,782,227,766,227);C(750,227,667,234,667,234);L(667,218);C(704,213,725,206,737,197);C(750,187,753,173,755,155);C(840,164,850,192,850,243);L(850,575);C(873,578,883,586,886,600);Z;M(234,523);L(224,513);C(259,494,299,454,311,422);C(372,389,408,508,234,523);Z;M(233,395);L(223,386);C(257,365,296,322,308,289);C(369,252,408,373,233,395);Z;M(187,129);C(181,63,127,13,81,-5);C(59,-16,43,-36,52,-58);C(62,-83,99,-84,127,-68);C(172,-45,225,20,204,129);Z;M(340,125);L(327,121);C(347,74,369,4,368,-51);C(425,-110,497,13,340,125);Z;M(533,125);L(522,119);C(559,74,605,3,616,-53);C(684,-106,741,39,533,125);Z;M(747,138);L(736,129);C(795,81,868,-3,888,-70);C(966,-117,1007,51,747,138);Z;M(267,835);L(256,829);C(291,796,332,742,344,698);L(348,696);L(45,696);L(53,666);L(927,666);C(941,666,950,671,953,682);C(919,713,865,757,865,757);L(817,696);L(599,696);C(637,726,674,762,700,792);C(722,791,734,799,738,811);L(633,841);C(617,798,590,739,565,696);L(389,696);C(421,719,411,801,267,835);Z;M(138,588);L(138,154);L(148,154);C(174,154,200,169,200,174);L(200,559);L(411,559);L(411,245);C(411,232,407,227,392,227);C(374,227,304,233,304,233);L(304,216);C(338,212,356,205,367,196);C(378,187,381,172,383,156);C(462,163,471,192,471,240);L(471,547);C(492,550,508,559,514,566);L(432,627);L(401,588);L(205,588);L(138,619);Z];gid=16384,advance=1000,lsb=42,bounds=42,-35,961,836,path=34[M(464,836);L(464,626);L(96,626);L(104,597);L(464,597);L(464,327);L(128,327);L(136,298);L(464,298);L(464,-6);L(42,-6);L(51,-35);L(934,-35);C(949,-35,958,-30,961,-20);C(924,14,865,59,865,59);L(813,-6);L(533,-6);L(533,298);L(852,298);C(866,298,876,302,879,313);C(843,345,787,389,787,389);L(737,327);L(533,327);L(533,569);C(555,572,563,581,565,595);L(547,597);L(888,597);C(902,597,911,602,914,613);C(878,645,820,690,820,690);L(769,626);L(533,626);L(533,798);C(557,802,568,812,569,826);Z];gid=17922,advance=1000,lsb=380,bounds=380,83,1056,783,path=28[M(400,99);L(410,83);C(639,165,775,306,858,492);C(868,516,892,525,892,545);C(892,567,829,620,802,620);C(787,620,783,608,760,603);C(723,596,501,571,452,571);C(425,571,408,594,392,613);L(380,607);C(381,587,382,574,386,561);C(394,539,431,499,457,499);C(473,499,490,512,509,517);C(552,529,749,559,788,559);C(795,559,799,558,797,549);C(759,376,611,207,400,99);Z;M(953,577);C(1009,577,1056,625,1056,680);C(1056,737,1009,783,953,783);C(896,783,850,737,850,680);C(850,625,896,577,953,577);Z;M(953,610);C(915,610,882,642,882,680);C(882,719,915,751,953,751);C(992,751,1023,719,1023,680);C(1023,642,992,610,953,610);Z]]
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:164&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;958.63&#32;ms&#32;±&#32;&#32;36.47&#32;ms&#32;&#32;&#32;908.86&#32;ms&#32;…&#32;&#32;&#32;1.02&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:191&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.56&#32;s&#32;±&#32;414.46&#32;ms&#32;&#32;&#32;&#32;25.90&#32;s&#32;…&#32;&#32;27.29&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:218&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.85&#32;ms&#32;±&#32;344.83&#32;µs&#32;&#32;&#32;&#32;&#32;2.60&#32;ms&#32;…&#32;&#32;&#32;3.45&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;40&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:241&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.59&#32;ms&#32;±&#32;314.35&#32;µs&#32;&#32;&#32;&#32;&#32;4.18&#32;ms&#32;…&#32;&#32;&#32;5.11&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;21&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 1
- UTC start: `2026-07-29T17:37:20.4462545Z`
- UTC end: `2026-07-29T17:44:09.3032957Z`
- Exit status: `0`
- Normalized raw output SHA-256: `34d2bc705a9db73deb9197dafe8cbed5ebd87d4ace9bff1f5f57bd30ac88f926`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 930.350000000 | 55.270000000 | 867.720000000 | 1040.000000000 | 10 | 1 |
| cjk-full-admission | 26140.000000000 | 313.090000000 | 25490.000000000 | 26650.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.510000000 | 0.123770000 | 2.360000000 | 2.790000000 | 10 | 27 |
| cjk-high-gid-multi-fd-outline-batch | 4.480000000 | 0.473970000 | 4.120000000 | 5.690000000 | 10 | 21 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
MNF_CFF_BENCH_CORRECTNESS|latin-full-admission|cff-runtime-semantics/1|workload=latin-full-admission|fixture=source-sans-3.052R|source_length=334924|operation=full-admission|scalar=65|mapped_gid=2|kerning=0|gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z]
MNF_CFF_BENCH_CORRECTNESS|cjk-full-admission|cff-runtime-semantics/1|workload=cjk-full-admission|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=full-admission|scalar=65|mapped_gid=34|kerning=0|gid=34,advance=718,lsb=12,bounds=12,0,711,734,path=21[M(332,643);L(450,281);L(216,281);Z;M(418,0);L(711,0);L(711,30);L(619,38);L(384,734);L(328,734);L(97,40);L(12,30);L(12,0);L(236,0);L(236,30);L(139,40);L(206,249);L(461,249);L(529,39);L(418,30);Z]
MNF_CFF_BENCH_CORRECTNESS|latin-fixed-outline-batch|cff-runtime-semantics/1|workload=latin-fixed-outline-batch|fixture=source-sans-3.052R|source_length=334924|operation=outline-batch|glyphs=7[gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z];gid=3,advance=588,lsb=90,bounds=90,0,548,656,path=21[M(90,0);L(299,0);C(446,0,548,64,548,195);C(548,283,496,334,414,349);L(414,353);C(476,373,510,428,510,496);C(510,611,418,656,285,656);L(90,656);Z;M(173,377);L(173,590);L(274,590);C(376,590,428,561,428,485);C(428,418,382,377,270,377);Z;M(173,66);L(173,313);L(287,313);C(402,313,466,276,466,195);C(466,107,400,66,287,66);Z];gid=34,advance=504,lsb=45,bounds=45,-224,492,498,path=37[M(246,-224);C(397,-224,492,-146,492,-56);C(492,25,435,60,322,60);L(228,60);C(162,60,142,82,142,113);C(142,140,156,156,173,171);C(195,160,222,154,246,154);C(345,154,424,219,424,322);C(424,366,406,398,383,419);L(383,423);L(484,423);L(484,486);L(315,486);C(297,493,273,498,246,498);C(147,498,63,431,63,325);C(63,267,94,220,126,194);L(126,190);C(101,173,73,141,73,100);C(73,62,92,36,116,21);L(116,17);C(72,-13,45,-52,45,-93);C(45,-177,127,-224,246,-224);Z;M(246,209);C(190,209,143,254,143,325);C(143,396,189,438,246,438);C(303,438,349,396,349,325);C(349,254,302,209,246,209);Z;M(258,-167);C(170,-167,117,-134,117,-82);C(117,-54,132,-25,167,0);C(188,-6,211,-8,230,-8);L(314,-8);C(377,-8,412,-23,412,-68);C(412,-119,351,-167,258,-167);Z];gid=97,advance=615,lsb=90,bounds=90,-165,564,656,path=17[M(90,0);L(258,0);C(456,0,564,122,564,331);C(564,539,456,656,254,656);L(90,656);Z;M(173,68);L(173,588);L(248,588);C(401,588,478,496,478,331);C(478,165,401,68,248,68);Z;M(168,-165);L(434,-165);L(434,-108);L(168,-108);Z];gid=321,advance=645,lsb=87,bounds=87,-219,558,841,path=25[M(336,-219);C(370,-219,405,-204,426,-187);L(403,-140);C(388,-151,372,-157,352,-157);C(324,-157,299,-142,299,-107);C(299,-67,332,-20,378,-9);C(494,19,558,99,558,271);L(558,656);L(478,656);L(478,269);C(478,110,410,60,323,60);C(237,60,170,110,170,269);L(170,656);L(87,656);L(87,271);C(87,77,173,0,291,-11);C(259,-39,231,-81,231,-127);C(231,-189,278,-219,336,-219);Z;M(245,706);L(319,706);L(482,832);L(478,841);L(377,841);Z];gid=1024,advance=535,lsb=46,bounds=46,-12,489,762,path=25[M(267,-12);C(389,-12,489,80,489,242);C(489,406,389,498,267,498);C(146,498,46,406,46,242);C(46,80,146,-12,267,-12);Z;M(267,56);C(181,56,131,130,131,242);C(131,355,181,430,267,430);C(353,430,404,355,404,242);C(404,130,353,56,267,56);Z;M(170,560);C(222,572,277,606,277,670);C(277,730,219,759,138,762);L(134,711);C(187,708,213,691,213,660);C(213,632,193,609,161,600);Z;M(303,564);L(351,564);L(416,744);L(411,754);L(338,754);Z];gid=2477,advance=425,lsb=48,bounds=48,-8,367,550,path=18[M(160,198);L(232,198);C(217,294,367,301,367,424);C(367,501,305,550,210,550);C(141,550,89,522,48,484);L(88,436);C(122,469,159,485,200,485);C(258,485,287,453,287,414);C(287,321,140,305,160,198);Z;M(89,-8);L(137,-8);C(136,53,161,78,199,78);C(236,78,261,53,260,-8);L(308,-8);C(312,90,270,138,199,138);C(127,138,85,90,89,-8);Z]]
MNF_CFF_BENCH_CORRECTNESS|cjk-high-gid-multi-fd-outline-batch|cff-runtime-semantics/1|workload=cjk-high-gid-multi-fd-outline-batch|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=outline-batch|glyphs=6[gid=2,advance=308,lsb=95,bounds=95,-13,214,747,path=15[M(154,-13);C(189,-13,214,14,214,46);C(214,79,189,104,154,104);C(120,104,95,79,95,46);C(95,14,120,-13,154,-13);Z;M(154,747);C(122,747,102,728,102,689);C(102,637,113,554,129,412);L(141,217);L(167,217);L(180,412);C(196,554,206,637,206,689);C(206,728,186,747,154,747);Z];gid=256,advance=0,lsb=314,bounds=314,484,685,826,path=7[M(499,592);L(342,825);L(314,810);L(496,484);L(685,811);L(657,826);Z];gid=2048,advance=1000,lsb=32,bounds=32,-89,986,832,path=88[M(84,664);L(68,660);C(91,585,117,472,113,387);C(167,328,220,475,84,664);Z;M(368,667);C(359,599,332,464,309,377);L(322,373);C(365,450,407,553,429,610);C(450,609,461,620,463,628);Z;M(849,826);L(837,819);C(859,793,882,748,882,713);C(931,670,986,769,849,826);Z;M(49,761);L(57,732);L(219,732);L(219,314);L(32,314);L(40,285);L(219,285);L(219,-83);L(228,-83);C(258,-83,277,-68,277,-63);L(277,285);L(457,285);C(471,285,481,290,484,301);C(454,331,406,370,406,370);L(364,314);L(277,314);L(277,732);L(441,732);C(455,732,465,737,468,748);C(439,776,391,815,391,815);L(349,761);Z;M(503,633);L(503,384);C(503,226,497,60,413,-73);L(428,-84);C(553,47,561,238,561,385);L(561,408);L(640,408);C(639,216,635,144,623,126);C(620,122,618,120,612,120);C(601,120,574,121,557,122);L(557,106);C(574,102,590,97,598,90);C(607,83,611,67,611,57);C(630,58,647,64,662,78);C(690,107,691,186,693,403);C(712,405,724,410,731,418);L(662,473);L(630,438);L(561,438);L(561,603);L(731,603);C(735,432,747,281,781,159);C(743,74,692,-3,626,-64);L(638,-76);C(705,-27,758,35,799,102);C(816,58,836,19,861,-15);C(888,-56,940,-89,964,-65);C(973,-56,970,-41,948,-1);L(964,152);L(951,154);C(941,114,926,69,917,45);C(908,24,905,23,894,41);C(869,75,849,117,834,166);C(882,264,911,369,929,463);C(957,463,965,469,970,482);L(871,505);C(862,422,844,332,815,245);C(794,350,788,473,787,603);L(944,603);C(958,603,967,608,970,619);C(941,648,894,686,894,686);L(852,633);L(787,633);L(788,792);C(813,795,822,807,824,819);L(729,832);L(730,633);L(572,633);L(503,664);Z];gid=8192,advance=1000,lsb=45,bounds=43,-117,1007,841,path=87[M(581,595);L(581,266);L(593,266);C(617,266,643,279,643,287);L(643,559);C(667,563,676,571,678,584);Z;M(786,611);L(786,246);C(786,233,782,227,766,227);C(750,227,667,234,667,234);L(667,218);C(704,213,725,206,737,197);C(750,187,753,173,755,155);C(840,164,850,192,850,243);L(850,575);C(873,578,883,586,886,600);Z;M(234,523);L(224,513);C(259,494,299,454,311,422);C(372,389,408,508,234,523);Z;M(233,395);L(223,386);C(257,365,296,322,308,289);C(369,252,408,373,233,395);Z;M(187,129);C(181,63,127,13,81,-5);C(59,-16,43,-36,52,-58);C(62,-83,99,-84,127,-68);C(172,-45,225,20,204,129);Z;M(340,125);L(327,121);C(347,74,369,4,368,-51);C(425,-110,497,13,340,125);Z;M(533,125);L(522,119);C(559,74,605,3,616,-53);C(684,-106,741,39,533,125);Z;M(747,138);L(736,129);C(795,81,868,-3,888,-70);C(966,-117,1007,51,747,138);Z;M(267,835);L(256,829);C(291,796,332,742,344,698);L(348,696);L(45,696);L(53,666);L(927,666);C(941,666,950,671,953,682);C(919,713,865,757,865,757);L(817,696);L(599,696);C(637,726,674,762,700,792);C(722,791,734,799,738,811);L(633,841);C(617,798,590,739,565,696);L(389,696);C(421,719,411,801,267,835);Z;M(138,588);L(138,154);L(148,154);C(174,154,200,169,200,174);L(200,559);L(411,559);L(411,245);C(411,232,407,227,392,227);C(374,227,304,233,304,233);L(304,216);C(338,212,356,205,367,196);C(378,187,381,172,383,156);C(462,163,471,192,471,240);L(471,547);C(492,550,508,559,514,566);L(432,627);L(401,588);L(205,588);L(138,619);Z];gid=16384,advance=1000,lsb=42,bounds=42,-35,961,836,path=34[M(464,836);L(464,626);L(96,626);L(104,597);L(464,597);L(464,327);L(128,327);L(136,298);L(464,298);L(464,-6);L(42,-6);L(51,-35);L(934,-35);C(949,-35,958,-30,961,-20);C(924,14,865,59,865,59);L(813,-6);L(533,-6);L(533,298);L(852,298);C(866,298,876,302,879,313);C(843,345,787,389,787,389);L(737,327);L(533,327);L(533,569);C(555,572,563,581,565,595);L(547,597);L(888,597);C(902,597,911,602,914,613);C(878,645,820,690,820,690);L(769,626);L(533,626);L(533,798);C(557,802,568,812,569,826);Z];gid=17922,advance=1000,lsb=380,bounds=380,83,1056,783,path=28[M(400,99);L(410,83);C(639,165,775,306,858,492);C(868,516,892,525,892,545);C(892,567,829,620,802,620);C(787,620,783,608,760,603);C(723,596,501,571,452,571);C(425,571,408,594,392,613);L(380,607);C(381,587,382,574,386,561);C(394,539,431,499,457,499);C(473,499,490,512,509,517);C(552,529,749,559,788,559);C(795,559,799,558,797,549);C(759,376,611,207,400,99);Z;M(953,577);C(1009,577,1056,625,1056,680);C(1056,737,1009,783,953,783);C(896,783,850,737,850,680);C(850,625,896,577,953,577);Z;M(953,610);C(915,610,882,642,882,680);C(882,719,915,751,953,751);C(992,751,1023,719,1023,680);C(1023,642,992,610,953,610);Z]]
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:164&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;930.35&#32;ms&#32;±&#32;&#32;55.27&#32;ms&#32;&#32;&#32;867.72&#32;ms&#32;…&#32;&#32;&#32;1.04&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:191&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.14&#32;s&#32;±&#32;313.09&#32;ms&#32;&#32;&#32;&#32;25.49&#32;s&#32;…&#32;&#32;26.65&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:218&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.51&#32;ms&#32;±&#32;123.77&#32;µs&#32;&#32;&#32;&#32;&#32;2.36&#32;ms&#32;…&#32;&#32;&#32;2.79&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;27&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:241&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.48&#32;ms&#32;±&#32;473.97&#32;µs&#32;&#32;&#32;&#32;&#32;4.12&#32;ms&#32;…&#32;&#32;&#32;5.69&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;21&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 2
- UTC start: `2026-07-29T17:44:09.3163646Z`
- UTC end: `2026-07-29T17:50:59.6153510Z`
- Exit status: `0`
- Normalized raw output SHA-256: `25e93958be01a5e76cbe7e02c0424017bd540027b8583e438bfd9f9ee38dfcda`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 919.590000000 | 47.520000000 | 857.830000000 | 990.770000000 | 10 | 1 |
| cjk-full-admission | 26040.000000000 | 218.180000000 | 25640.000000000 | 26460.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.670000000 | 0.240090000 | 2.370000000 | 3.020000000 | 10 | 35 |
| cjk-high-gid-multi-fd-outline-batch | 4.570000000 | 0.334950000 | 4.220000000 | 5.160000000 | 10 | 24 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
MNF_CFF_BENCH_CORRECTNESS|latin-full-admission|cff-runtime-semantics/1|workload=latin-full-admission|fixture=source-sans-3.052R|source_length=334924|operation=full-admission|scalar=65|mapped_gid=2|kerning=0|gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z]
MNF_CFF_BENCH_CORRECTNESS|cjk-full-admission|cff-runtime-semantics/1|workload=cjk-full-admission|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=full-admission|scalar=65|mapped_gid=34|kerning=0|gid=34,advance=718,lsb=12,bounds=12,0,711,734,path=21[M(332,643);L(450,281);L(216,281);Z;M(418,0);L(711,0);L(711,30);L(619,38);L(384,734);L(328,734);L(97,40);L(12,30);L(12,0);L(236,0);L(236,30);L(139,40);L(206,249);L(461,249);L(529,39);L(418,30);Z]
MNF_CFF_BENCH_CORRECTNESS|latin-fixed-outline-batch|cff-runtime-semantics/1|workload=latin-fixed-outline-batch|fixture=source-sans-3.052R|source_length=334924|operation=outline-batch|glyphs=7[gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z];gid=3,advance=588,lsb=90,bounds=90,0,548,656,path=21[M(90,0);L(299,0);C(446,0,548,64,548,195);C(548,283,496,334,414,349);L(414,353);C(476,373,510,428,510,496);C(510,611,418,656,285,656);L(90,656);Z;M(173,377);L(173,590);L(274,590);C(376,590,428,561,428,485);C(428,418,382,377,270,377);Z;M(173,66);L(173,313);L(287,313);C(402,313,466,276,466,195);C(466,107,400,66,287,66);Z];gid=34,advance=504,lsb=45,bounds=45,-224,492,498,path=37[M(246,-224);C(397,-224,492,-146,492,-56);C(492,25,435,60,322,60);L(228,60);C(162,60,142,82,142,113);C(142,140,156,156,173,171);C(195,160,222,154,246,154);C(345,154,424,219,424,322);C(424,366,406,398,383,419);L(383,423);L(484,423);L(484,486);L(315,486);C(297,493,273,498,246,498);C(147,498,63,431,63,325);C(63,267,94,220,126,194);L(126,190);C(101,173,73,141,73,100);C(73,62,92,36,116,21);L(116,17);C(72,-13,45,-52,45,-93);C(45,-177,127,-224,246,-224);Z;M(246,209);C(190,209,143,254,143,325);C(143,396,189,438,246,438);C(303,438,349,396,349,325);C(349,254,302,209,246,209);Z;M(258,-167);C(170,-167,117,-134,117,-82);C(117,-54,132,-25,167,0);C(188,-6,211,-8,230,-8);L(314,-8);C(377,-8,412,-23,412,-68);C(412,-119,351,-167,258,-167);Z];gid=97,advance=615,lsb=90,bounds=90,-165,564,656,path=17[M(90,0);L(258,0);C(456,0,564,122,564,331);C(564,539,456,656,254,656);L(90,656);Z;M(173,68);L(173,588);L(248,588);C(401,588,478,496,478,331);C(478,165,401,68,248,68);Z;M(168,-165);L(434,-165);L(434,-108);L(168,-108);Z];gid=321,advance=645,lsb=87,bounds=87,-219,558,841,path=25[M(336,-219);C(370,-219,405,-204,426,-187);L(403,-140);C(388,-151,372,-157,352,-157);C(324,-157,299,-142,299,-107);C(299,-67,332,-20,378,-9);C(494,19,558,99,558,271);L(558,656);L(478,656);L(478,269);C(478,110,410,60,323,60);C(237,60,170,110,170,269);L(170,656);L(87,656);L(87,271);C(87,77,173,0,291,-11);C(259,-39,231,-81,231,-127);C(231,-189,278,-219,336,-219);Z;M(245,706);L(319,706);L(482,832);L(478,841);L(377,841);Z];gid=1024,advance=535,lsb=46,bounds=46,-12,489,762,path=25[M(267,-12);C(389,-12,489,80,489,242);C(489,406,389,498,267,498);C(146,498,46,406,46,242);C(46,80,146,-12,267,-12);Z;M(267,56);C(181,56,131,130,131,242);C(131,355,181,430,267,430);C(353,430,404,355,404,242);C(404,130,353,56,267,56);Z;M(170,560);C(222,572,277,606,277,670);C(277,730,219,759,138,762);L(134,711);C(187,708,213,691,213,660);C(213,632,193,609,161,600);Z;M(303,564);L(351,564);L(416,744);L(411,754);L(338,754);Z];gid=2477,advance=425,lsb=48,bounds=48,-8,367,550,path=18[M(160,198);L(232,198);C(217,294,367,301,367,424);C(367,501,305,550,210,550);C(141,550,89,522,48,484);L(88,436);C(122,469,159,485,200,485);C(258,485,287,453,287,414);C(287,321,140,305,160,198);Z;M(89,-8);L(137,-8);C(136,53,161,78,199,78);C(236,78,261,53,260,-8);L(308,-8);C(312,90,270,138,199,138);C(127,138,85,90,89,-8);Z]]
MNF_CFF_BENCH_CORRECTNESS|cjk-high-gid-multi-fd-outline-batch|cff-runtime-semantics/1|workload=cjk-high-gid-multi-fd-outline-batch|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=outline-batch|glyphs=6[gid=2,advance=308,lsb=95,bounds=95,-13,214,747,path=15[M(154,-13);C(189,-13,214,14,214,46);C(214,79,189,104,154,104);C(120,104,95,79,95,46);C(95,14,120,-13,154,-13);Z;M(154,747);C(122,747,102,728,102,689);C(102,637,113,554,129,412);L(141,217);L(167,217);L(180,412);C(196,554,206,637,206,689);C(206,728,186,747,154,747);Z];gid=256,advance=0,lsb=314,bounds=314,484,685,826,path=7[M(499,592);L(342,825);L(314,810);L(496,484);L(685,811);L(657,826);Z];gid=2048,advance=1000,lsb=32,bounds=32,-89,986,832,path=88[M(84,664);L(68,660);C(91,585,117,472,113,387);C(167,328,220,475,84,664);Z;M(368,667);C(359,599,332,464,309,377);L(322,373);C(365,450,407,553,429,610);C(450,609,461,620,463,628);Z;M(849,826);L(837,819);C(859,793,882,748,882,713);C(931,670,986,769,849,826);Z;M(49,761);L(57,732);L(219,732);L(219,314);L(32,314);L(40,285);L(219,285);L(219,-83);L(228,-83);C(258,-83,277,-68,277,-63);L(277,285);L(457,285);C(471,285,481,290,484,301);C(454,331,406,370,406,370);L(364,314);L(277,314);L(277,732);L(441,732);C(455,732,465,737,468,748);C(439,776,391,815,391,815);L(349,761);Z;M(503,633);L(503,384);C(503,226,497,60,413,-73);L(428,-84);C(553,47,561,238,561,385);L(561,408);L(640,408);C(639,216,635,144,623,126);C(620,122,618,120,612,120);C(601,120,574,121,557,122);L(557,106);C(574,102,590,97,598,90);C(607,83,611,67,611,57);C(630,58,647,64,662,78);C(690,107,691,186,693,403);C(712,405,724,410,731,418);L(662,473);L(630,438);L(561,438);L(561,603);L(731,603);C(735,432,747,281,781,159);C(743,74,692,-3,626,-64);L(638,-76);C(705,-27,758,35,799,102);C(816,58,836,19,861,-15);C(888,-56,940,-89,964,-65);C(973,-56,970,-41,948,-1);L(964,152);L(951,154);C(941,114,926,69,917,45);C(908,24,905,23,894,41);C(869,75,849,117,834,166);C(882,264,911,369,929,463);C(957,463,965,469,970,482);L(871,505);C(862,422,844,332,815,245);C(794,350,788,473,787,603);L(944,603);C(958,603,967,608,970,619);C(941,648,894,686,894,686);L(852,633);L(787,633);L(788,792);C(813,795,822,807,824,819);L(729,832);L(730,633);L(572,633);L(503,664);Z];gid=8192,advance=1000,lsb=45,bounds=43,-117,1007,841,path=87[M(581,595);L(581,266);L(593,266);C(617,266,643,279,643,287);L(643,559);C(667,563,676,571,678,584);Z;M(786,611);L(786,246);C(786,233,782,227,766,227);C(750,227,667,234,667,234);L(667,218);C(704,213,725,206,737,197);C(750,187,753,173,755,155);C(840,164,850,192,850,243);L(850,575);C(873,578,883,586,886,600);Z;M(234,523);L(224,513);C(259,494,299,454,311,422);C(372,389,408,508,234,523);Z;M(233,395);L(223,386);C(257,365,296,322,308,289);C(369,252,408,373,233,395);Z;M(187,129);C(181,63,127,13,81,-5);C(59,-16,43,-36,52,-58);C(62,-83,99,-84,127,-68);C(172,-45,225,20,204,129);Z;M(340,125);L(327,121);C(347,74,369,4,368,-51);C(425,-110,497,13,340,125);Z;M(533,125);L(522,119);C(559,74,605,3,616,-53);C(684,-106,741,39,533,125);Z;M(747,138);L(736,129);C(795,81,868,-3,888,-70);C(966,-117,1007,51,747,138);Z;M(267,835);L(256,829);C(291,796,332,742,344,698);L(348,696);L(45,696);L(53,666);L(927,666);C(941,666,950,671,953,682);C(919,713,865,757,865,757);L(817,696);L(599,696);C(637,726,674,762,700,792);C(722,791,734,799,738,811);L(633,841);C(617,798,590,739,565,696);L(389,696);C(421,719,411,801,267,835);Z;M(138,588);L(138,154);L(148,154);C(174,154,200,169,200,174);L(200,559);L(411,559);L(411,245);C(411,232,407,227,392,227);C(374,227,304,233,304,233);L(304,216);C(338,212,356,205,367,196);C(378,187,381,172,383,156);C(462,163,471,192,471,240);L(471,547);C(492,550,508,559,514,566);L(432,627);L(401,588);L(205,588);L(138,619);Z];gid=16384,advance=1000,lsb=42,bounds=42,-35,961,836,path=34[M(464,836);L(464,626);L(96,626);L(104,597);L(464,597);L(464,327);L(128,327);L(136,298);L(464,298);L(464,-6);L(42,-6);L(51,-35);L(934,-35);C(949,-35,958,-30,961,-20);C(924,14,865,59,865,59);L(813,-6);L(533,-6);L(533,298);L(852,298);C(866,298,876,302,879,313);C(843,345,787,389,787,389);L(737,327);L(533,327);L(533,569);C(555,572,563,581,565,595);L(547,597);L(888,597);C(902,597,911,602,914,613);C(878,645,820,690,820,690);L(769,626);L(533,626);L(533,798);C(557,802,568,812,569,826);Z];gid=17922,advance=1000,lsb=380,bounds=380,83,1056,783,path=28[M(400,99);L(410,83);C(639,165,775,306,858,492);C(868,516,892,525,892,545);C(892,567,829,620,802,620);C(787,620,783,608,760,603);C(723,596,501,571,452,571);C(425,571,408,594,392,613);L(380,607);C(381,587,382,574,386,561);C(394,539,431,499,457,499);C(473,499,490,512,509,517);C(552,529,749,559,788,559);C(795,559,799,558,797,549);C(759,376,611,207,400,99);Z;M(953,577);C(1009,577,1056,625,1056,680);C(1056,737,1009,783,953,783);C(896,783,850,737,850,680);C(850,625,896,577,953,577);Z;M(953,610);C(915,610,882,642,882,680);C(882,719,915,751,953,751);C(992,751,1023,719,1023,680);C(1023,642,992,610,953,610);Z]]
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:164&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;919.59&#32;ms&#32;±&#32;&#32;47.52&#32;ms&#32;&#32;&#32;857.83&#32;ms&#32;…&#32;990.77&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:191&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.04&#32;s&#32;±&#32;218.18&#32;ms&#32;&#32;&#32;&#32;25.64&#32;s&#32;…&#32;&#32;26.46&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:218&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.67&#32;ms&#32;±&#32;240.09&#32;µs&#32;&#32;&#32;&#32;&#32;2.37&#32;ms&#32;…&#32;&#32;&#32;3.02&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;35&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:241&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.57&#32;ms&#32;±&#32;334.95&#32;µs&#32;&#32;&#32;&#32;&#32;4.22&#32;ms&#32;…&#32;&#32;&#32;5.16&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;24&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 3
- UTC start: `2026-07-29T17:50:59.6328636Z`
- UTC end: `2026-07-29T17:57:47.2610819Z`
- Exit status: `0`
- Normalized raw output SHA-256: `ceb38a133c02264aaf6617b0eb59361a80ea2bf5d588323048ada98088d1dd5e`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 912.460000000 | 34.360000000 | 868.390000000 | 978.340000000 | 10 | 1 |
| cjk-full-admission | 26120.000000000 | 144.480000000 | 25890.000000000 | 26330.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.990000000 | 0.448010000 | 2.540000000 | 3.860000000 | 10 | 29 |
| cjk-high-gid-multi-fd-outline-batch | 4.370000000 | 0.276220000 | 4.040000000 | 4.820000000 | 10 | 22 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
MNF_CFF_BENCH_CORRECTNESS|latin-full-admission|cff-runtime-semantics/1|workload=latin-full-admission|fixture=source-sans-3.052R|source_length=334924|operation=full-admission|scalar=65|mapped_gid=2|kerning=0|gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z]
MNF_CFF_BENCH_CORRECTNESS|cjk-full-admission|cff-runtime-semantics/1|workload=cjk-full-admission|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=full-admission|scalar=65|mapped_gid=34|kerning=0|gid=34,advance=718,lsb=12,bounds=12,0,711,734,path=21[M(332,643);L(450,281);L(216,281);Z;M(418,0);L(711,0);L(711,30);L(619,38);L(384,734);L(328,734);L(97,40);L(12,30);L(12,0);L(236,0);L(236,30);L(139,40);L(206,249);L(461,249);L(529,39);L(418,30);Z]
MNF_CFF_BENCH_CORRECTNESS|latin-fixed-outline-batch|cff-runtime-semantics/1|workload=latin-fixed-outline-batch|fixture=source-sans-3.052R|source_length=334924|operation=outline-batch|glyphs=7[gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z];gid=3,advance=588,lsb=90,bounds=90,0,548,656,path=21[M(90,0);L(299,0);C(446,0,548,64,548,195);C(548,283,496,334,414,349);L(414,353);C(476,373,510,428,510,496);C(510,611,418,656,285,656);L(90,656);Z;M(173,377);L(173,590);L(274,590);C(376,590,428,561,428,485);C(428,418,382,377,270,377);Z;M(173,66);L(173,313);L(287,313);C(402,313,466,276,466,195);C(466,107,400,66,287,66);Z];gid=34,advance=504,lsb=45,bounds=45,-224,492,498,path=37[M(246,-224);C(397,-224,492,-146,492,-56);C(492,25,435,60,322,60);L(228,60);C(162,60,142,82,142,113);C(142,140,156,156,173,171);C(195,160,222,154,246,154);C(345,154,424,219,424,322);C(424,366,406,398,383,419);L(383,423);L(484,423);L(484,486);L(315,486);C(297,493,273,498,246,498);C(147,498,63,431,63,325);C(63,267,94,220,126,194);L(126,190);C(101,173,73,141,73,100);C(73,62,92,36,116,21);L(116,17);C(72,-13,45,-52,45,-93);C(45,-177,127,-224,246,-224);Z;M(246,209);C(190,209,143,254,143,325);C(143,396,189,438,246,438);C(303,438,349,396,349,325);C(349,254,302,209,246,209);Z;M(258,-167);C(170,-167,117,-134,117,-82);C(117,-54,132,-25,167,0);C(188,-6,211,-8,230,-8);L(314,-8);C(377,-8,412,-23,412,-68);C(412,-119,351,-167,258,-167);Z];gid=97,advance=615,lsb=90,bounds=90,-165,564,656,path=17[M(90,0);L(258,0);C(456,0,564,122,564,331);C(564,539,456,656,254,656);L(90,656);Z;M(173,68);L(173,588);L(248,588);C(401,588,478,496,478,331);C(478,165,401,68,248,68);Z;M(168,-165);L(434,-165);L(434,-108);L(168,-108);Z];gid=321,advance=645,lsb=87,bounds=87,-219,558,841,path=25[M(336,-219);C(370,-219,405,-204,426,-187);L(403,-140);C(388,-151,372,-157,352,-157);C(324,-157,299,-142,299,-107);C(299,-67,332,-20,378,-9);C(494,19,558,99,558,271);L(558,656);L(478,656);L(478,269);C(478,110,410,60,323,60);C(237,60,170,110,170,269);L(170,656);L(87,656);L(87,271);C(87,77,173,0,291,-11);C(259,-39,231,-81,231,-127);C(231,-189,278,-219,336,-219);Z;M(245,706);L(319,706);L(482,832);L(478,841);L(377,841);Z];gid=1024,advance=535,lsb=46,bounds=46,-12,489,762,path=25[M(267,-12);C(389,-12,489,80,489,242);C(489,406,389,498,267,498);C(146,498,46,406,46,242);C(46,80,146,-12,267,-12);Z;M(267,56);C(181,56,131,130,131,242);C(131,355,181,430,267,430);C(353,430,404,355,404,242);C(404,130,353,56,267,56);Z;M(170,560);C(222,572,277,606,277,670);C(277,730,219,759,138,762);L(134,711);C(187,708,213,691,213,660);C(213,632,193,609,161,600);Z;M(303,564);L(351,564);L(416,744);L(411,754);L(338,754);Z];gid=2477,advance=425,lsb=48,bounds=48,-8,367,550,path=18[M(160,198);L(232,198);C(217,294,367,301,367,424);C(367,501,305,550,210,550);C(141,550,89,522,48,484);L(88,436);C(122,469,159,485,200,485);C(258,485,287,453,287,414);C(287,321,140,305,160,198);Z;M(89,-8);L(137,-8);C(136,53,161,78,199,78);C(236,78,261,53,260,-8);L(308,-8);C(312,90,270,138,199,138);C(127,138,85,90,89,-8);Z]]
MNF_CFF_BENCH_CORRECTNESS|cjk-high-gid-multi-fd-outline-batch|cff-runtime-semantics/1|workload=cjk-high-gid-multi-fd-outline-batch|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=outline-batch|glyphs=6[gid=2,advance=308,lsb=95,bounds=95,-13,214,747,path=15[M(154,-13);C(189,-13,214,14,214,46);C(214,79,189,104,154,104);C(120,104,95,79,95,46);C(95,14,120,-13,154,-13);Z;M(154,747);C(122,747,102,728,102,689);C(102,637,113,554,129,412);L(141,217);L(167,217);L(180,412);C(196,554,206,637,206,689);C(206,728,186,747,154,747);Z];gid=256,advance=0,lsb=314,bounds=314,484,685,826,path=7[M(499,592);L(342,825);L(314,810);L(496,484);L(685,811);L(657,826);Z];gid=2048,advance=1000,lsb=32,bounds=32,-89,986,832,path=88[M(84,664);L(68,660);C(91,585,117,472,113,387);C(167,328,220,475,84,664);Z;M(368,667);C(359,599,332,464,309,377);L(322,373);C(365,450,407,553,429,610);C(450,609,461,620,463,628);Z;M(849,826);L(837,819);C(859,793,882,748,882,713);C(931,670,986,769,849,826);Z;M(49,761);L(57,732);L(219,732);L(219,314);L(32,314);L(40,285);L(219,285);L(219,-83);L(228,-83);C(258,-83,277,-68,277,-63);L(277,285);L(457,285);C(471,285,481,290,484,301);C(454,331,406,370,406,370);L(364,314);L(277,314);L(277,732);L(441,732);C(455,732,465,737,468,748);C(439,776,391,815,391,815);L(349,761);Z;M(503,633);L(503,384);C(503,226,497,60,413,-73);L(428,-84);C(553,47,561,238,561,385);L(561,408);L(640,408);C(639,216,635,144,623,126);C(620,122,618,120,612,120);C(601,120,574,121,557,122);L(557,106);C(574,102,590,97,598,90);C(607,83,611,67,611,57);C(630,58,647,64,662,78);C(690,107,691,186,693,403);C(712,405,724,410,731,418);L(662,473);L(630,438);L(561,438);L(561,603);L(731,603);C(735,432,747,281,781,159);C(743,74,692,-3,626,-64);L(638,-76);C(705,-27,758,35,799,102);C(816,58,836,19,861,-15);C(888,-56,940,-89,964,-65);C(973,-56,970,-41,948,-1);L(964,152);L(951,154);C(941,114,926,69,917,45);C(908,24,905,23,894,41);C(869,75,849,117,834,166);C(882,264,911,369,929,463);C(957,463,965,469,970,482);L(871,505);C(862,422,844,332,815,245);C(794,350,788,473,787,603);L(944,603);C(958,603,967,608,970,619);C(941,648,894,686,894,686);L(852,633);L(787,633);L(788,792);C(813,795,822,807,824,819);L(729,832);L(730,633);L(572,633);L(503,664);Z];gid=8192,advance=1000,lsb=45,bounds=43,-117,1007,841,path=87[M(581,595);L(581,266);L(593,266);C(617,266,643,279,643,287);L(643,559);C(667,563,676,571,678,584);Z;M(786,611);L(786,246);C(786,233,782,227,766,227);C(750,227,667,234,667,234);L(667,218);C(704,213,725,206,737,197);C(750,187,753,173,755,155);C(840,164,850,192,850,243);L(850,575);C(873,578,883,586,886,600);Z;M(234,523);L(224,513);C(259,494,299,454,311,422);C(372,389,408,508,234,523);Z;M(233,395);L(223,386);C(257,365,296,322,308,289);C(369,252,408,373,233,395);Z;M(187,129);C(181,63,127,13,81,-5);C(59,-16,43,-36,52,-58);C(62,-83,99,-84,127,-68);C(172,-45,225,20,204,129);Z;M(340,125);L(327,121);C(347,74,369,4,368,-51);C(425,-110,497,13,340,125);Z;M(533,125);L(522,119);C(559,74,605,3,616,-53);C(684,-106,741,39,533,125);Z;M(747,138);L(736,129);C(795,81,868,-3,888,-70);C(966,-117,1007,51,747,138);Z;M(267,835);L(256,829);C(291,796,332,742,344,698);L(348,696);L(45,696);L(53,666);L(927,666);C(941,666,950,671,953,682);C(919,713,865,757,865,757);L(817,696);L(599,696);C(637,726,674,762,700,792);C(722,791,734,799,738,811);L(633,841);C(617,798,590,739,565,696);L(389,696);C(421,719,411,801,267,835);Z;M(138,588);L(138,154);L(148,154);C(174,154,200,169,200,174);L(200,559);L(411,559);L(411,245);C(411,232,407,227,392,227);C(374,227,304,233,304,233);L(304,216);C(338,212,356,205,367,196);C(378,187,381,172,383,156);C(462,163,471,192,471,240);L(471,547);C(492,550,508,559,514,566);L(432,627);L(401,588);L(205,588);L(138,619);Z];gid=16384,advance=1000,lsb=42,bounds=42,-35,961,836,path=34[M(464,836);L(464,626);L(96,626);L(104,597);L(464,597);L(464,327);L(128,327);L(136,298);L(464,298);L(464,-6);L(42,-6);L(51,-35);L(934,-35);C(949,-35,958,-30,961,-20);C(924,14,865,59,865,59);L(813,-6);L(533,-6);L(533,298);L(852,298);C(866,298,876,302,879,313);C(843,345,787,389,787,389);L(737,327);L(533,327);L(533,569);C(555,572,563,581,565,595);L(547,597);L(888,597);C(902,597,911,602,914,613);C(878,645,820,690,820,690);L(769,626);L(533,626);L(533,798);C(557,802,568,812,569,826);Z];gid=17922,advance=1000,lsb=380,bounds=380,83,1056,783,path=28[M(400,99);L(410,83);C(639,165,775,306,858,492);C(868,516,892,525,892,545);C(892,567,829,620,802,620);C(787,620,783,608,760,603);C(723,596,501,571,452,571);C(425,571,408,594,392,613);L(380,607);C(381,587,382,574,386,561);C(394,539,431,499,457,499);C(473,499,490,512,509,517);C(552,529,749,559,788,559);C(795,559,799,558,797,549);C(759,376,611,207,400,99);Z;M(953,577);C(1009,577,1056,625,1056,680);C(1056,737,1009,783,953,783);C(896,783,850,737,850,680);C(850,625,896,577,953,577);Z;M(953,610);C(915,610,882,642,882,680);C(882,719,915,751,953,751);C(992,751,1023,719,1023,680);C(1023,642,992,610,953,610);Z]]
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:164&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;912.46&#32;ms&#32;±&#32;&#32;34.36&#32;ms&#32;&#32;&#32;868.39&#32;ms&#32;…&#32;978.34&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:191&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.12&#32;s&#32;±&#32;144.48&#32;ms&#32;&#32;&#32;&#32;25.89&#32;s&#32;…&#32;&#32;26.33&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:218&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.99&#32;ms&#32;±&#32;448.01&#32;µs&#32;&#32;&#32;&#32;&#32;2.54&#32;ms&#32;…&#32;&#32;&#32;3.86&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;29&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:241&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.37&#32;ms&#32;±&#32;276.22&#32;µs&#32;&#32;&#32;&#32;&#32;4.04&#32;ms&#32;…&#32;&#32;&#32;4.82&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;22&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 4
- UTC start: `2026-07-29T17:57:47.2727674Z`
- UTC end: `2026-07-29T18:04:35.5947818Z`
- Exit status: `0`
- Normalized raw output SHA-256: `752463bcd86f84c486252fc81d39517d53da4467c138a4f41bf4d5449ea9957a`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 967.960000000 | 52.800000000 | 891.270000000 | 1050.000000000 | 10 | 1 |
| cjk-full-admission | 25920.000000000 | 677.060000000 | 25250.000000000 | 26840.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.540000000 | 0.068690000 | 2.420000000 | 2.620000000 | 10 | 40 |
| cjk-high-gid-multi-fd-outline-batch | 4.320000000 | 0.436690000 | 3.880000000 | 5.140000000 | 10 | 23 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
MNF_CFF_BENCH_CORRECTNESS|latin-full-admission|cff-runtime-semantics/1|workload=latin-full-admission|fixture=source-sans-3.052R|source_length=334924|operation=full-admission|scalar=65|mapped_gid=2|kerning=0|gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z]
MNF_CFF_BENCH_CORRECTNESS|cjk-full-admission|cff-runtime-semantics/1|workload=cjk-full-admission|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=full-admission|scalar=65|mapped_gid=34|kerning=0|gid=34,advance=718,lsb=12,bounds=12,0,711,734,path=21[M(332,643);L(450,281);L(216,281);Z;M(418,0);L(711,0);L(711,30);L(619,38);L(384,734);L(328,734);L(97,40);L(12,30);L(12,0);L(236,0);L(236,30);L(139,40);L(206,249);L(461,249);L(529,39);L(418,30);Z]
MNF_CFF_BENCH_CORRECTNESS|latin-fixed-outline-batch|cff-runtime-semantics/1|workload=latin-fixed-outline-batch|fixture=source-sans-3.052R|source_length=334924|operation=outline-batch|glyphs=7[gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z];gid=3,advance=588,lsb=90,bounds=90,0,548,656,path=21[M(90,0);L(299,0);C(446,0,548,64,548,195);C(548,283,496,334,414,349);L(414,353);C(476,373,510,428,510,496);C(510,611,418,656,285,656);L(90,656);Z;M(173,377);L(173,590);L(274,590);C(376,590,428,561,428,485);C(428,418,382,377,270,377);Z;M(173,66);L(173,313);L(287,313);C(402,313,466,276,466,195);C(466,107,400,66,287,66);Z];gid=34,advance=504,lsb=45,bounds=45,-224,492,498,path=37[M(246,-224);C(397,-224,492,-146,492,-56);C(492,25,435,60,322,60);L(228,60);C(162,60,142,82,142,113);C(142,140,156,156,173,171);C(195,160,222,154,246,154);C(345,154,424,219,424,322);C(424,366,406,398,383,419);L(383,423);L(484,423);L(484,486);L(315,486);C(297,493,273,498,246,498);C(147,498,63,431,63,325);C(63,267,94,220,126,194);L(126,190);C(101,173,73,141,73,100);C(73,62,92,36,116,21);L(116,17);C(72,-13,45,-52,45,-93);C(45,-177,127,-224,246,-224);Z;M(246,209);C(190,209,143,254,143,325);C(143,396,189,438,246,438);C(303,438,349,396,349,325);C(349,254,302,209,246,209);Z;M(258,-167);C(170,-167,117,-134,117,-82);C(117,-54,132,-25,167,0);C(188,-6,211,-8,230,-8);L(314,-8);C(377,-8,412,-23,412,-68);C(412,-119,351,-167,258,-167);Z];gid=97,advance=615,lsb=90,bounds=90,-165,564,656,path=17[M(90,0);L(258,0);C(456,0,564,122,564,331);C(564,539,456,656,254,656);L(90,656);Z;M(173,68);L(173,588);L(248,588);C(401,588,478,496,478,331);C(478,165,401,68,248,68);Z;M(168,-165);L(434,-165);L(434,-108);L(168,-108);Z];gid=321,advance=645,lsb=87,bounds=87,-219,558,841,path=25[M(336,-219);C(370,-219,405,-204,426,-187);L(403,-140);C(388,-151,372,-157,352,-157);C(324,-157,299,-142,299,-107);C(299,-67,332,-20,378,-9);C(494,19,558,99,558,271);L(558,656);L(478,656);L(478,269);C(478,110,410,60,323,60);C(237,60,170,110,170,269);L(170,656);L(87,656);L(87,271);C(87,77,173,0,291,-11);C(259,-39,231,-81,231,-127);C(231,-189,278,-219,336,-219);Z;M(245,706);L(319,706);L(482,832);L(478,841);L(377,841);Z];gid=1024,advance=535,lsb=46,bounds=46,-12,489,762,path=25[M(267,-12);C(389,-12,489,80,489,242);C(489,406,389,498,267,498);C(146,498,46,406,46,242);C(46,80,146,-12,267,-12);Z;M(267,56);C(181,56,131,130,131,242);C(131,355,181,430,267,430);C(353,430,404,355,404,242);C(404,130,353,56,267,56);Z;M(170,560);C(222,572,277,606,277,670);C(277,730,219,759,138,762);L(134,711);C(187,708,213,691,213,660);C(213,632,193,609,161,600);Z;M(303,564);L(351,564);L(416,744);L(411,754);L(338,754);Z];gid=2477,advance=425,lsb=48,bounds=48,-8,367,550,path=18[M(160,198);L(232,198);C(217,294,367,301,367,424);C(367,501,305,550,210,550);C(141,550,89,522,48,484);L(88,436);C(122,469,159,485,200,485);C(258,485,287,453,287,414);C(287,321,140,305,160,198);Z;M(89,-8);L(137,-8);C(136,53,161,78,199,78);C(236,78,261,53,260,-8);L(308,-8);C(312,90,270,138,199,138);C(127,138,85,90,89,-8);Z]]
MNF_CFF_BENCH_CORRECTNESS|cjk-high-gid-multi-fd-outline-batch|cff-runtime-semantics/1|workload=cjk-high-gid-multi-fd-outline-batch|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=outline-batch|glyphs=6[gid=2,advance=308,lsb=95,bounds=95,-13,214,747,path=15[M(154,-13);C(189,-13,214,14,214,46);C(214,79,189,104,154,104);C(120,104,95,79,95,46);C(95,14,120,-13,154,-13);Z;M(154,747);C(122,747,102,728,102,689);C(102,637,113,554,129,412);L(141,217);L(167,217);L(180,412);C(196,554,206,637,206,689);C(206,728,186,747,154,747);Z];gid=256,advance=0,lsb=314,bounds=314,484,685,826,path=7[M(499,592);L(342,825);L(314,810);L(496,484);L(685,811);L(657,826);Z];gid=2048,advance=1000,lsb=32,bounds=32,-89,986,832,path=88[M(84,664);L(68,660);C(91,585,117,472,113,387);C(167,328,220,475,84,664);Z;M(368,667);C(359,599,332,464,309,377);L(322,373);C(365,450,407,553,429,610);C(450,609,461,620,463,628);Z;M(849,826);L(837,819);C(859,793,882,748,882,713);C(931,670,986,769,849,826);Z;M(49,761);L(57,732);L(219,732);L(219,314);L(32,314);L(40,285);L(219,285);L(219,-83);L(228,-83);C(258,-83,277,-68,277,-63);L(277,285);L(457,285);C(471,285,481,290,484,301);C(454,331,406,370,406,370);L(364,314);L(277,314);L(277,732);L(441,732);C(455,732,465,737,468,748);C(439,776,391,815,391,815);L(349,761);Z;M(503,633);L(503,384);C(503,226,497,60,413,-73);L(428,-84);C(553,47,561,238,561,385);L(561,408);L(640,408);C(639,216,635,144,623,126);C(620,122,618,120,612,120);C(601,120,574,121,557,122);L(557,106);C(574,102,590,97,598,90);C(607,83,611,67,611,57);C(630,58,647,64,662,78);C(690,107,691,186,693,403);C(712,405,724,410,731,418);L(662,473);L(630,438);L(561,438);L(561,603);L(731,603);C(735,432,747,281,781,159);C(743,74,692,-3,626,-64);L(638,-76);C(705,-27,758,35,799,102);C(816,58,836,19,861,-15);C(888,-56,940,-89,964,-65);C(973,-56,970,-41,948,-1);L(964,152);L(951,154);C(941,114,926,69,917,45);C(908,24,905,23,894,41);C(869,75,849,117,834,166);C(882,264,911,369,929,463);C(957,463,965,469,970,482);L(871,505);C(862,422,844,332,815,245);C(794,350,788,473,787,603);L(944,603);C(958,603,967,608,970,619);C(941,648,894,686,894,686);L(852,633);L(787,633);L(788,792);C(813,795,822,807,824,819);L(729,832);L(730,633);L(572,633);L(503,664);Z];gid=8192,advance=1000,lsb=45,bounds=43,-117,1007,841,path=87[M(581,595);L(581,266);L(593,266);C(617,266,643,279,643,287);L(643,559);C(667,563,676,571,678,584);Z;M(786,611);L(786,246);C(786,233,782,227,766,227);C(750,227,667,234,667,234);L(667,218);C(704,213,725,206,737,197);C(750,187,753,173,755,155);C(840,164,850,192,850,243);L(850,575);C(873,578,883,586,886,600);Z;M(234,523);L(224,513);C(259,494,299,454,311,422);C(372,389,408,508,234,523);Z;M(233,395);L(223,386);C(257,365,296,322,308,289);C(369,252,408,373,233,395);Z;M(187,129);C(181,63,127,13,81,-5);C(59,-16,43,-36,52,-58);C(62,-83,99,-84,127,-68);C(172,-45,225,20,204,129);Z;M(340,125);L(327,121);C(347,74,369,4,368,-51);C(425,-110,497,13,340,125);Z;M(533,125);L(522,119);C(559,74,605,3,616,-53);C(684,-106,741,39,533,125);Z;M(747,138);L(736,129);C(795,81,868,-3,888,-70);C(966,-117,1007,51,747,138);Z;M(267,835);L(256,829);C(291,796,332,742,344,698);L(348,696);L(45,696);L(53,666);L(927,666);C(941,666,950,671,953,682);C(919,713,865,757,865,757);L(817,696);L(599,696);C(637,726,674,762,700,792);C(722,791,734,799,738,811);L(633,841);C(617,798,590,739,565,696);L(389,696);C(421,719,411,801,267,835);Z;M(138,588);L(138,154);L(148,154);C(174,154,200,169,200,174);L(200,559);L(411,559);L(411,245);C(411,232,407,227,392,227);C(374,227,304,233,304,233);L(304,216);C(338,212,356,205,367,196);C(378,187,381,172,383,156);C(462,163,471,192,471,240);L(471,547);C(492,550,508,559,514,566);L(432,627);L(401,588);L(205,588);L(138,619);Z];gid=16384,advance=1000,lsb=42,bounds=42,-35,961,836,path=34[M(464,836);L(464,626);L(96,626);L(104,597);L(464,597);L(464,327);L(128,327);L(136,298);L(464,298);L(464,-6);L(42,-6);L(51,-35);L(934,-35);C(949,-35,958,-30,961,-20);C(924,14,865,59,865,59);L(813,-6);L(533,-6);L(533,298);L(852,298);C(866,298,876,302,879,313);C(843,345,787,389,787,389);L(737,327);L(533,327);L(533,569);C(555,572,563,581,565,595);L(547,597);L(888,597);C(902,597,911,602,914,613);C(878,645,820,690,820,690);L(769,626);L(533,626);L(533,798);C(557,802,568,812,569,826);Z];gid=17922,advance=1000,lsb=380,bounds=380,83,1056,783,path=28[M(400,99);L(410,83);C(639,165,775,306,858,492);C(868,516,892,525,892,545);C(892,567,829,620,802,620);C(787,620,783,608,760,603);C(723,596,501,571,452,571);C(425,571,408,594,392,613);L(380,607);C(381,587,382,574,386,561);C(394,539,431,499,457,499);C(473,499,490,512,509,517);C(552,529,749,559,788,559);C(795,559,799,558,797,549);C(759,376,611,207,400,99);Z;M(953,577);C(1009,577,1056,625,1056,680);C(1056,737,1009,783,953,783);C(896,783,850,737,850,680);C(850,625,896,577,953,577);Z;M(953,610);C(915,610,882,642,882,680);C(882,719,915,751,953,751);C(992,751,1023,719,1023,680);C(1023,642,992,610,953,610);Z]]
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:164&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;967.96&#32;ms&#32;±&#32;&#32;52.80&#32;ms&#32;&#32;&#32;891.27&#32;ms&#32;…&#32;&#32;&#32;1.05&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:191&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;25.92&#32;s&#32;±&#32;677.06&#32;ms&#32;&#32;&#32;&#32;25.25&#32;s&#32;…&#32;&#32;26.84&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:218&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.54&#32;ms&#32;±&#32;&#32;68.69&#32;µs&#32;&#32;&#32;&#32;&#32;2.42&#32;ms&#32;…&#32;&#32;&#32;2.62&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;40&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:241&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.32&#32;ms&#32;±&#32;436.69&#32;µs&#32;&#32;&#32;&#32;&#32;3.88&#32;ms&#32;…&#32;&#32;&#32;5.14&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;23&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 5
- UTC start: `2026-07-29T18:04:35.6042670Z`
- UTC end: `2026-07-29T18:11:07.8975654Z`
- Exit status: `0`
- Normalized raw output SHA-256: `3fff79a808e6f5e1c1651eb0a14120c614ffb2e3f0d5fd915e320b2c433b48f1`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 881.920000000 | 33.080000000 | 834.240000000 | 937.500000000 | 10 | 1 |
| cjk-full-admission | 25100.000000000 | 316.540000000 | 24590.000000000 | 25470.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.830000000 | 0.231680000 | 2.600000000 | 3.400000000 | 10 | 36 |
| cjk-high-gid-multi-fd-outline-batch | 4.200000000 | 0.146900000 | 3.980000000 | 4.400000000 | 10 | 26 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
MNF_CFF_BENCH_CORRECTNESS|latin-full-admission|cff-runtime-semantics/1|workload=latin-full-admission|fixture=source-sans-3.052R|source_length=334924|operation=full-admission|scalar=65|mapped_gid=2|kerning=0|gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z]
MNF_CFF_BENCH_CORRECTNESS|cjk-full-admission|cff-runtime-semantics/1|workload=cjk-full-admission|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=full-admission|scalar=65|mapped_gid=34|kerning=0|gid=34,advance=718,lsb=12,bounds=12,0,711,734,path=21[M(332,643);L(450,281);L(216,281);Z;M(418,0);L(711,0);L(711,30);L(619,38);L(384,734);L(328,734);L(97,40);L(12,30);L(12,0);L(236,0);L(236,30);L(139,40);L(206,249);L(461,249);L(529,39);L(418,30);Z]
MNF_CFF_BENCH_CORRECTNESS|latin-fixed-outline-batch|cff-runtime-semantics/1|workload=latin-fixed-outline-batch|fixture=source-sans-3.052R|source_length=334924|operation=outline-batch|glyphs=7[gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z];gid=3,advance=588,lsb=90,bounds=90,0,548,656,path=21[M(90,0);L(299,0);C(446,0,548,64,548,195);C(548,283,496,334,414,349);L(414,353);C(476,373,510,428,510,496);C(510,611,418,656,285,656);L(90,656);Z;M(173,377);L(173,590);L(274,590);C(376,590,428,561,428,485);C(428,418,382,377,270,377);Z;M(173,66);L(173,313);L(287,313);C(402,313,466,276,466,195);C(466,107,400,66,287,66);Z];gid=34,advance=504,lsb=45,bounds=45,-224,492,498,path=37[M(246,-224);C(397,-224,492,-146,492,-56);C(492,25,435,60,322,60);L(228,60);C(162,60,142,82,142,113);C(142,140,156,156,173,171);C(195,160,222,154,246,154);C(345,154,424,219,424,322);C(424,366,406,398,383,419);L(383,423);L(484,423);L(484,486);L(315,486);C(297,493,273,498,246,498);C(147,498,63,431,63,325);C(63,267,94,220,126,194);L(126,190);C(101,173,73,141,73,100);C(73,62,92,36,116,21);L(116,17);C(72,-13,45,-52,45,-93);C(45,-177,127,-224,246,-224);Z;M(246,209);C(190,209,143,254,143,325);C(143,396,189,438,246,438);C(303,438,349,396,349,325);C(349,254,302,209,246,209);Z;M(258,-167);C(170,-167,117,-134,117,-82);C(117,-54,132,-25,167,0);C(188,-6,211,-8,230,-8);L(314,-8);C(377,-8,412,-23,412,-68);C(412,-119,351,-167,258,-167);Z];gid=97,advance=615,lsb=90,bounds=90,-165,564,656,path=17[M(90,0);L(258,0);C(456,0,564,122,564,331);C(564,539,456,656,254,656);L(90,656);Z;M(173,68);L(173,588);L(248,588);C(401,588,478,496,478,331);C(478,165,401,68,248,68);Z;M(168,-165);L(434,-165);L(434,-108);L(168,-108);Z];gid=321,advance=645,lsb=87,bounds=87,-219,558,841,path=25[M(336,-219);C(370,-219,405,-204,426,-187);L(403,-140);C(388,-151,372,-157,352,-157);C(324,-157,299,-142,299,-107);C(299,-67,332,-20,378,-9);C(494,19,558,99,558,271);L(558,656);L(478,656);L(478,269);C(478,110,410,60,323,60);C(237,60,170,110,170,269);L(170,656);L(87,656);L(87,271);C(87,77,173,0,291,-11);C(259,-39,231,-81,231,-127);C(231,-189,278,-219,336,-219);Z;M(245,706);L(319,706);L(482,832);L(478,841);L(377,841);Z];gid=1024,advance=535,lsb=46,bounds=46,-12,489,762,path=25[M(267,-12);C(389,-12,489,80,489,242);C(489,406,389,498,267,498);C(146,498,46,406,46,242);C(46,80,146,-12,267,-12);Z;M(267,56);C(181,56,131,130,131,242);C(131,355,181,430,267,430);C(353,430,404,355,404,242);C(404,130,353,56,267,56);Z;M(170,560);C(222,572,277,606,277,670);C(277,730,219,759,138,762);L(134,711);C(187,708,213,691,213,660);C(213,632,193,609,161,600);Z;M(303,564);L(351,564);L(416,744);L(411,754);L(338,754);Z];gid=2477,advance=425,lsb=48,bounds=48,-8,367,550,path=18[M(160,198);L(232,198);C(217,294,367,301,367,424);C(367,501,305,550,210,550);C(141,550,89,522,48,484);L(88,436);C(122,469,159,485,200,485);C(258,485,287,453,287,414);C(287,321,140,305,160,198);Z;M(89,-8);L(137,-8);C(136,53,161,78,199,78);C(236,78,261,53,260,-8);L(308,-8);C(312,90,270,138,199,138);C(127,138,85,90,89,-8);Z]]
MNF_CFF_BENCH_CORRECTNESS|cjk-high-gid-multi-fd-outline-batch|cff-runtime-semantics/1|workload=cjk-high-gid-multi-fd-outline-batch|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=outline-batch|glyphs=6[gid=2,advance=308,lsb=95,bounds=95,-13,214,747,path=15[M(154,-13);C(189,-13,214,14,214,46);C(214,79,189,104,154,104);C(120,104,95,79,95,46);C(95,14,120,-13,154,-13);Z;M(154,747);C(122,747,102,728,102,689);C(102,637,113,554,129,412);L(141,217);L(167,217);L(180,412);C(196,554,206,637,206,689);C(206,728,186,747,154,747);Z];gid=256,advance=0,lsb=314,bounds=314,484,685,826,path=7[M(499,592);L(342,825);L(314,810);L(496,484);L(685,811);L(657,826);Z];gid=2048,advance=1000,lsb=32,bounds=32,-89,986,832,path=88[M(84,664);L(68,660);C(91,585,117,472,113,387);C(167,328,220,475,84,664);Z;M(368,667);C(359,599,332,464,309,377);L(322,373);C(365,450,407,553,429,610);C(450,609,461,620,463,628);Z;M(849,826);L(837,819);C(859,793,882,748,882,713);C(931,670,986,769,849,826);Z;M(49,761);L(57,732);L(219,732);L(219,314);L(32,314);L(40,285);L(219,285);L(219,-83);L(228,-83);C(258,-83,277,-68,277,-63);L(277,285);L(457,285);C(471,285,481,290,484,301);C(454,331,406,370,406,370);L(364,314);L(277,314);L(277,732);L(441,732);C(455,732,465,737,468,748);C(439,776,391,815,391,815);L(349,761);Z;M(503,633);L(503,384);C(503,226,497,60,413,-73);L(428,-84);C(553,47,561,238,561,385);L(561,408);L(640,408);C(639,216,635,144,623,126);C(620,122,618,120,612,120);C(601,120,574,121,557,122);L(557,106);C(574,102,590,97,598,90);C(607,83,611,67,611,57);C(630,58,647,64,662,78);C(690,107,691,186,693,403);C(712,405,724,410,731,418);L(662,473);L(630,438);L(561,438);L(561,603);L(731,603);C(735,432,747,281,781,159);C(743,74,692,-3,626,-64);L(638,-76);C(705,-27,758,35,799,102);C(816,58,836,19,861,-15);C(888,-56,940,-89,964,-65);C(973,-56,970,-41,948,-1);L(964,152);L(951,154);C(941,114,926,69,917,45);C(908,24,905,23,894,41);C(869,75,849,117,834,166);C(882,264,911,369,929,463);C(957,463,965,469,970,482);L(871,505);C(862,422,844,332,815,245);C(794,350,788,473,787,603);L(944,603);C(958,603,967,608,970,619);C(941,648,894,686,894,686);L(852,633);L(787,633);L(788,792);C(813,795,822,807,824,819);L(729,832);L(730,633);L(572,633);L(503,664);Z];gid=8192,advance=1000,lsb=45,bounds=43,-117,1007,841,path=87[M(581,595);L(581,266);L(593,266);C(617,266,643,279,643,287);L(643,559);C(667,563,676,571,678,584);Z;M(786,611);L(786,246);C(786,233,782,227,766,227);C(750,227,667,234,667,234);L(667,218);C(704,213,725,206,737,197);C(750,187,753,173,755,155);C(840,164,850,192,850,243);L(850,575);C(873,578,883,586,886,600);Z;M(234,523);L(224,513);C(259,494,299,454,311,422);C(372,389,408,508,234,523);Z;M(233,395);L(223,386);C(257,365,296,322,308,289);C(369,252,408,373,233,395);Z;M(187,129);C(181,63,127,13,81,-5);C(59,-16,43,-36,52,-58);C(62,-83,99,-84,127,-68);C(172,-45,225,20,204,129);Z;M(340,125);L(327,121);C(347,74,369,4,368,-51);C(425,-110,497,13,340,125);Z;M(533,125);L(522,119);C(559,74,605,3,616,-53);C(684,-106,741,39,533,125);Z;M(747,138);L(736,129);C(795,81,868,-3,888,-70);C(966,-117,1007,51,747,138);Z;M(267,835);L(256,829);C(291,796,332,742,344,698);L(348,696);L(45,696);L(53,666);L(927,666);C(941,666,950,671,953,682);C(919,713,865,757,865,757);L(817,696);L(599,696);C(637,726,674,762,700,792);C(722,791,734,799,738,811);L(633,841);C(617,798,590,739,565,696);L(389,696);C(421,719,411,801,267,835);Z;M(138,588);L(138,154);L(148,154);C(174,154,200,169,200,174);L(200,559);L(411,559);L(411,245);C(411,232,407,227,392,227);C(374,227,304,233,304,233);L(304,216);C(338,212,356,205,367,196);C(378,187,381,172,383,156);C(462,163,471,192,471,240);L(471,547);C(492,550,508,559,514,566);L(432,627);L(401,588);L(205,588);L(138,619);Z];gid=16384,advance=1000,lsb=42,bounds=42,-35,961,836,path=34[M(464,836);L(464,626);L(96,626);L(104,597);L(464,597);L(464,327);L(128,327);L(136,298);L(464,298);L(464,-6);L(42,-6);L(51,-35);L(934,-35);C(949,-35,958,-30,961,-20);C(924,14,865,59,865,59);L(813,-6);L(533,-6);L(533,298);L(852,298);C(866,298,876,302,879,313);C(843,345,787,389,787,389);L(737,327);L(533,327);L(533,569);C(555,572,563,581,565,595);L(547,597);L(888,597);C(902,597,911,602,914,613);C(878,645,820,690,820,690);L(769,626);L(533,626);L(533,798);C(557,802,568,812,569,826);Z];gid=17922,advance=1000,lsb=380,bounds=380,83,1056,783,path=28[M(400,99);L(410,83);C(639,165,775,306,858,492);C(868,516,892,525,892,545);C(892,567,829,620,802,620);C(787,620,783,608,760,603);C(723,596,501,571,452,571);C(425,571,408,594,392,613);L(380,607);C(381,587,382,574,386,561);C(394,539,431,499,457,499);C(473,499,490,512,509,517);C(552,529,749,559,788,559);C(795,559,799,558,797,549);C(759,376,611,207,400,99);Z;M(953,577);C(1009,577,1056,625,1056,680);C(1056,737,1009,783,953,783);C(896,783,850,737,850,680);C(850,625,896,577,953,577);Z;M(953,610);C(915,610,882,642,882,680);C(882,719,915,751,953,751);C(992,751,1023,719,1023,680);C(1023,642,992,610,953,610);Z]]
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:164&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;881.92&#32;ms&#32;±&#32;&#32;33.08&#32;ms&#32;&#32;&#32;834.24&#32;ms&#32;…&#32;937.50&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:191&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;25.10&#32;s&#32;±&#32;316.54&#32;ms&#32;&#32;&#32;&#32;24.59&#32;s&#32;…&#32;&#32;25.47&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:218&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.83&#32;ms&#32;±&#32;231.68&#32;µs&#32;&#32;&#32;&#32;&#32;2.60&#32;ms&#32;…&#32;&#32;&#32;3.40&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;36&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:241&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.20&#32;ms&#32;±&#32;146.90&#32;µs&#32;&#32;&#32;&#32;&#32;3.98&#32;ms&#32;…&#32;&#32;&#32;4.40&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;26&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 6
- UTC start: `2026-07-29T18:11:07.9106331Z`
- UTC end: `2026-07-29T18:17:39.7034674Z`
- Exit status: `0`
- Normalized raw output SHA-256: `807ffc3333ca62e06247eab4dd4668a613b8aaab3da2a92f90a62d1c45670d43`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 898.910000000 | 41.590000000 | 858.450000000 | 995.340000000 | 10 | 1 |
| cjk-full-admission | 25070.000000000 | 364.440000000 | 24610.000000000 | 25630.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.500000000 | 0.120650000 | 2.390000000 | 2.730000000 | 10 | 39 |
| cjk-high-gid-multi-fd-outline-batch | 4.140000000 | 0.259640000 | 3.810000000 | 4.480000000 | 10 | 25 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
MNF_CFF_BENCH_CORRECTNESS|latin-full-admission|cff-runtime-semantics/1|workload=latin-full-admission|fixture=source-sans-3.052R|source_length=334924|operation=full-admission|scalar=65|mapped_gid=2|kerning=0|gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z]
MNF_CFF_BENCH_CORRECTNESS|cjk-full-admission|cff-runtime-semantics/1|workload=cjk-full-admission|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=full-admission|scalar=65|mapped_gid=34|kerning=0|gid=34,advance=718,lsb=12,bounds=12,0,711,734,path=21[M(332,643);L(450,281);L(216,281);Z;M(418,0);L(711,0);L(711,30);L(619,38);L(384,734);L(328,734);L(97,40);L(12,30);L(12,0);L(236,0);L(236,30);L(139,40);L(206,249);L(461,249);L(529,39);L(418,30);Z]
MNF_CFF_BENCH_CORRECTNESS|latin-fixed-outline-batch|cff-runtime-semantics/1|workload=latin-fixed-outline-batch|fixture=source-sans-3.052R|source_length=334924|operation=outline-batch|glyphs=7[gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z];gid=3,advance=588,lsb=90,bounds=90,0,548,656,path=21[M(90,0);L(299,0);C(446,0,548,64,548,195);C(548,283,496,334,414,349);L(414,353);C(476,373,510,428,510,496);C(510,611,418,656,285,656);L(90,656);Z;M(173,377);L(173,590);L(274,590);C(376,590,428,561,428,485);C(428,418,382,377,270,377);Z;M(173,66);L(173,313);L(287,313);C(402,313,466,276,466,195);C(466,107,400,66,287,66);Z];gid=34,advance=504,lsb=45,bounds=45,-224,492,498,path=37[M(246,-224);C(397,-224,492,-146,492,-56);C(492,25,435,60,322,60);L(228,60);C(162,60,142,82,142,113);C(142,140,156,156,173,171);C(195,160,222,154,246,154);C(345,154,424,219,424,322);C(424,366,406,398,383,419);L(383,423);L(484,423);L(484,486);L(315,486);C(297,493,273,498,246,498);C(147,498,63,431,63,325);C(63,267,94,220,126,194);L(126,190);C(101,173,73,141,73,100);C(73,62,92,36,116,21);L(116,17);C(72,-13,45,-52,45,-93);C(45,-177,127,-224,246,-224);Z;M(246,209);C(190,209,143,254,143,325);C(143,396,189,438,246,438);C(303,438,349,396,349,325);C(349,254,302,209,246,209);Z;M(258,-167);C(170,-167,117,-134,117,-82);C(117,-54,132,-25,167,0);C(188,-6,211,-8,230,-8);L(314,-8);C(377,-8,412,-23,412,-68);C(412,-119,351,-167,258,-167);Z];gid=97,advance=615,lsb=90,bounds=90,-165,564,656,path=17[M(90,0);L(258,0);C(456,0,564,122,564,331);C(564,539,456,656,254,656);L(90,656);Z;M(173,68);L(173,588);L(248,588);C(401,588,478,496,478,331);C(478,165,401,68,248,68);Z;M(168,-165);L(434,-165);L(434,-108);L(168,-108);Z];gid=321,advance=645,lsb=87,bounds=87,-219,558,841,path=25[M(336,-219);C(370,-219,405,-204,426,-187);L(403,-140);C(388,-151,372,-157,352,-157);C(324,-157,299,-142,299,-107);C(299,-67,332,-20,378,-9);C(494,19,558,99,558,271);L(558,656);L(478,656);L(478,269);C(478,110,410,60,323,60);C(237,60,170,110,170,269);L(170,656);L(87,656);L(87,271);C(87,77,173,0,291,-11);C(259,-39,231,-81,231,-127);C(231,-189,278,-219,336,-219);Z;M(245,706);L(319,706);L(482,832);L(478,841);L(377,841);Z];gid=1024,advance=535,lsb=46,bounds=46,-12,489,762,path=25[M(267,-12);C(389,-12,489,80,489,242);C(489,406,389,498,267,498);C(146,498,46,406,46,242);C(46,80,146,-12,267,-12);Z;M(267,56);C(181,56,131,130,131,242);C(131,355,181,430,267,430);C(353,430,404,355,404,242);C(404,130,353,56,267,56);Z;M(170,560);C(222,572,277,606,277,670);C(277,730,219,759,138,762);L(134,711);C(187,708,213,691,213,660);C(213,632,193,609,161,600);Z;M(303,564);L(351,564);L(416,744);L(411,754);L(338,754);Z];gid=2477,advance=425,lsb=48,bounds=48,-8,367,550,path=18[M(160,198);L(232,198);C(217,294,367,301,367,424);C(367,501,305,550,210,550);C(141,550,89,522,48,484);L(88,436);C(122,469,159,485,200,485);C(258,485,287,453,287,414);C(287,321,140,305,160,198);Z;M(89,-8);L(137,-8);C(136,53,161,78,199,78);C(236,78,261,53,260,-8);L(308,-8);C(312,90,270,138,199,138);C(127,138,85,90,89,-8);Z]]
MNF_CFF_BENCH_CORRECTNESS|cjk-high-gid-multi-fd-outline-batch|cff-runtime-semantics/1|workload=cjk-high-gid-multi-fd-outline-batch|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=outline-batch|glyphs=6[gid=2,advance=308,lsb=95,bounds=95,-13,214,747,path=15[M(154,-13);C(189,-13,214,14,214,46);C(214,79,189,104,154,104);C(120,104,95,79,95,46);C(95,14,120,-13,154,-13);Z;M(154,747);C(122,747,102,728,102,689);C(102,637,113,554,129,412);L(141,217);L(167,217);L(180,412);C(196,554,206,637,206,689);C(206,728,186,747,154,747);Z];gid=256,advance=0,lsb=314,bounds=314,484,685,826,path=7[M(499,592);L(342,825);L(314,810);L(496,484);L(685,811);L(657,826);Z];gid=2048,advance=1000,lsb=32,bounds=32,-89,986,832,path=88[M(84,664);L(68,660);C(91,585,117,472,113,387);C(167,328,220,475,84,664);Z;M(368,667);C(359,599,332,464,309,377);L(322,373);C(365,450,407,553,429,610);C(450,609,461,620,463,628);Z;M(849,826);L(837,819);C(859,793,882,748,882,713);C(931,670,986,769,849,826);Z;M(49,761);L(57,732);L(219,732);L(219,314);L(32,314);L(40,285);L(219,285);L(219,-83);L(228,-83);C(258,-83,277,-68,277,-63);L(277,285);L(457,285);C(471,285,481,290,484,301);C(454,331,406,370,406,370);L(364,314);L(277,314);L(277,732);L(441,732);C(455,732,465,737,468,748);C(439,776,391,815,391,815);L(349,761);Z;M(503,633);L(503,384);C(503,226,497,60,413,-73);L(428,-84);C(553,47,561,238,561,385);L(561,408);L(640,408);C(639,216,635,144,623,126);C(620,122,618,120,612,120);C(601,120,574,121,557,122);L(557,106);C(574,102,590,97,598,90);C(607,83,611,67,611,57);C(630,58,647,64,662,78);C(690,107,691,186,693,403);C(712,405,724,410,731,418);L(662,473);L(630,438);L(561,438);L(561,603);L(731,603);C(735,432,747,281,781,159);C(743,74,692,-3,626,-64);L(638,-76);C(705,-27,758,35,799,102);C(816,58,836,19,861,-15);C(888,-56,940,-89,964,-65);C(973,-56,970,-41,948,-1);L(964,152);L(951,154);C(941,114,926,69,917,45);C(908,24,905,23,894,41);C(869,75,849,117,834,166);C(882,264,911,369,929,463);C(957,463,965,469,970,482);L(871,505);C(862,422,844,332,815,245);C(794,350,788,473,787,603);L(944,603);C(958,603,967,608,970,619);C(941,648,894,686,894,686);L(852,633);L(787,633);L(788,792);C(813,795,822,807,824,819);L(729,832);L(730,633);L(572,633);L(503,664);Z];gid=8192,advance=1000,lsb=45,bounds=43,-117,1007,841,path=87[M(581,595);L(581,266);L(593,266);C(617,266,643,279,643,287);L(643,559);C(667,563,676,571,678,584);Z;M(786,611);L(786,246);C(786,233,782,227,766,227);C(750,227,667,234,667,234);L(667,218);C(704,213,725,206,737,197);C(750,187,753,173,755,155);C(840,164,850,192,850,243);L(850,575);C(873,578,883,586,886,600);Z;M(234,523);L(224,513);C(259,494,299,454,311,422);C(372,389,408,508,234,523);Z;M(233,395);L(223,386);C(257,365,296,322,308,289);C(369,252,408,373,233,395);Z;M(187,129);C(181,63,127,13,81,-5);C(59,-16,43,-36,52,-58);C(62,-83,99,-84,127,-68);C(172,-45,225,20,204,129);Z;M(340,125);L(327,121);C(347,74,369,4,368,-51);C(425,-110,497,13,340,125);Z;M(533,125);L(522,119);C(559,74,605,3,616,-53);C(684,-106,741,39,533,125);Z;M(747,138);L(736,129);C(795,81,868,-3,888,-70);C(966,-117,1007,51,747,138);Z;M(267,835);L(256,829);C(291,796,332,742,344,698);L(348,696);L(45,696);L(53,666);L(927,666);C(941,666,950,671,953,682);C(919,713,865,757,865,757);L(817,696);L(599,696);C(637,726,674,762,700,792);C(722,791,734,799,738,811);L(633,841);C(617,798,590,739,565,696);L(389,696);C(421,719,411,801,267,835);Z;M(138,588);L(138,154);L(148,154);C(174,154,200,169,200,174);L(200,559);L(411,559);L(411,245);C(411,232,407,227,392,227);C(374,227,304,233,304,233);L(304,216);C(338,212,356,205,367,196);C(378,187,381,172,383,156);C(462,163,471,192,471,240);L(471,547);C(492,550,508,559,514,566);L(432,627);L(401,588);L(205,588);L(138,619);Z];gid=16384,advance=1000,lsb=42,bounds=42,-35,961,836,path=34[M(464,836);L(464,626);L(96,626);L(104,597);L(464,597);L(464,327);L(128,327);L(136,298);L(464,298);L(464,-6);L(42,-6);L(51,-35);L(934,-35);C(949,-35,958,-30,961,-20);C(924,14,865,59,865,59);L(813,-6);L(533,-6);L(533,298);L(852,298);C(866,298,876,302,879,313);C(843,345,787,389,787,389);L(737,327);L(533,327);L(533,569);C(555,572,563,581,565,595);L(547,597);L(888,597);C(902,597,911,602,914,613);C(878,645,820,690,820,690);L(769,626);L(533,626);L(533,798);C(557,802,568,812,569,826);Z];gid=17922,advance=1000,lsb=380,bounds=380,83,1056,783,path=28[M(400,99);L(410,83);C(639,165,775,306,858,492);C(868,516,892,525,892,545);C(892,567,829,620,802,620);C(787,620,783,608,760,603);C(723,596,501,571,452,571);C(425,571,408,594,392,613);L(380,607);C(381,587,382,574,386,561);C(394,539,431,499,457,499);C(473,499,490,512,509,517);C(552,529,749,559,788,559);C(795,559,799,558,797,549);C(759,376,611,207,400,99);Z;M(953,577);C(1009,577,1056,625,1056,680);C(1056,737,1009,783,953,783);C(896,783,850,737,850,680);C(850,625,896,577,953,577);Z;M(953,610);C(915,610,882,642,882,680);C(882,719,915,751,953,751);C(992,751,1023,719,1023,680);C(1023,642,992,610,953,610);Z]]
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:164&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;898.91&#32;ms&#32;±&#32;&#32;41.59&#32;ms&#32;&#32;&#32;858.45&#32;ms&#32;…&#32;995.34&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:191&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;25.07&#32;s&#32;±&#32;364.44&#32;ms&#32;&#32;&#32;&#32;24.61&#32;s&#32;…&#32;&#32;25.63&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:218&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.50&#32;ms&#32;±&#32;120.65&#32;µs&#32;&#32;&#32;&#32;&#32;2.39&#32;ms&#32;…&#32;&#32;&#32;2.73&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;39&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:241&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.14&#32;ms&#32;±&#32;259.64&#32;µs&#32;&#32;&#32;&#32;&#32;3.81&#32;ms&#32;…&#32;&#32;&#32;4.48&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;25&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

### Retained capture 7
- UTC start: `2026-07-29T18:17:39.7125971Z`
- UTC end: `2026-07-29T18:24:25.7832071Z`
- Exit status: `0`
- Normalized raw output SHA-256: `40e0228d920be8de09c85b3f4c124022f1ec10cd9ec71ab8706819f4e61afdeb`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 924.640000000 | 40.240000000 | 876.800000000 | 992.040000000 | 10 | 1 |
| cjk-full-admission | 26010.000000000 | 459.730000000 | 25320.000000000 | 26790.000000000 | 10 | 1 |
| latin-fixed-outline-batch | 2.790000000 | 0.173480000 | 2.570000000 | 3.050000000 | 10 | 40 |
| cjk-high-gid-multi-fd-outline-batch | 4.390000000 | 0.218810000 | 4.130000000 | 4.820000000 | 10 | 24 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

<pre class="cff-native-output">
MNF_CFF_BENCH_CORRECTNESS|latin-full-admission|cff-runtime-semantics/1|workload=latin-full-admission|fixture=source-sans-3.052R|source_length=334924|operation=full-admission|scalar=65|mapped_gid=2|kerning=0|gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z]
MNF_CFF_BENCH_CORRECTNESS|cjk-full-admission|cff-runtime-semantics/1|workload=cjk-full-admission|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=full-admission|scalar=65|mapped_gid=34|kerning=0|gid=34,advance=718,lsb=12,bounds=12,0,711,734,path=21[M(332,643);L(450,281);L(216,281);Z;M(418,0);L(711,0);L(711,30);L(619,38);L(384,734);L(328,734);L(97,40);L(12,30);L(12,0);L(236,0);L(236,30);L(139,40);L(206,249);L(461,249);L(529,39);L(418,30);Z]
MNF_CFF_BENCH_CORRECTNESS|latin-fixed-outline-batch|cff-runtime-semantics/1|workload=latin-fixed-outline-batch|fixture=source-sans-3.052R|source_length=334924|operation=outline-batch|glyphs=7[gid=2,advance=544,lsb=3,bounds=3,0,541,656,path=16[M(203,367);C(227,440,248,512,268,588);L(272,588);C(293,512,314,440,338,367);L(369,267);L(172,267);Z;M(3,0);L(88,0);L(151,200);L(390,200);L(452,0);L(541,0);L(319,656);L(225,656);Z];gid=3,advance=588,lsb=90,bounds=90,0,548,656,path=21[M(90,0);L(299,0);C(446,0,548,64,548,195);C(548,283,496,334,414,349);L(414,353);C(476,373,510,428,510,496);C(510,611,418,656,285,656);L(90,656);Z;M(173,377);L(173,590);L(274,590);C(376,590,428,561,428,485);C(428,418,382,377,270,377);Z;M(173,66);L(173,313);L(287,313);C(402,313,466,276,466,195);C(466,107,400,66,287,66);Z];gid=34,advance=504,lsb=45,bounds=45,-224,492,498,path=37[M(246,-224);C(397,-224,492,-146,492,-56);C(492,25,435,60,322,60);L(228,60);C(162,60,142,82,142,113);C(142,140,156,156,173,171);C(195,160,222,154,246,154);C(345,154,424,219,424,322);C(424,366,406,398,383,419);L(383,423);L(484,423);L(484,486);L(315,486);C(297,493,273,498,246,498);C(147,498,63,431,63,325);C(63,267,94,220,126,194);L(126,190);C(101,173,73,141,73,100);C(73,62,92,36,116,21);L(116,17);C(72,-13,45,-52,45,-93);C(45,-177,127,-224,246,-224);Z;M(246,209);C(190,209,143,254,143,325);C(143,396,189,438,246,438);C(303,438,349,396,349,325);C(349,254,302,209,246,209);Z;M(258,-167);C(170,-167,117,-134,117,-82);C(117,-54,132,-25,167,0);C(188,-6,211,-8,230,-8);L(314,-8);C(377,-8,412,-23,412,-68);C(412,-119,351,-167,258,-167);Z];gid=97,advance=615,lsb=90,bounds=90,-165,564,656,path=17[M(90,0);L(258,0);C(456,0,564,122,564,331);C(564,539,456,656,254,656);L(90,656);Z;M(173,68);L(173,588);L(248,588);C(401,588,478,496,478,331);C(478,165,401,68,248,68);Z;M(168,-165);L(434,-165);L(434,-108);L(168,-108);Z];gid=321,advance=645,lsb=87,bounds=87,-219,558,841,path=25[M(336,-219);C(370,-219,405,-204,426,-187);L(403,-140);C(388,-151,372,-157,352,-157);C(324,-157,299,-142,299,-107);C(299,-67,332,-20,378,-9);C(494,19,558,99,558,271);L(558,656);L(478,656);L(478,269);C(478,110,410,60,323,60);C(237,60,170,110,170,269);L(170,656);L(87,656);L(87,271);C(87,77,173,0,291,-11);C(259,-39,231,-81,231,-127);C(231,-189,278,-219,336,-219);Z;M(245,706);L(319,706);L(482,832);L(478,841);L(377,841);Z];gid=1024,advance=535,lsb=46,bounds=46,-12,489,762,path=25[M(267,-12);C(389,-12,489,80,489,242);C(489,406,389,498,267,498);C(146,498,46,406,46,242);C(46,80,146,-12,267,-12);Z;M(267,56);C(181,56,131,130,131,242);C(131,355,181,430,267,430);C(353,430,404,355,404,242);C(404,130,353,56,267,56);Z;M(170,560);C(222,572,277,606,277,670);C(277,730,219,759,138,762);L(134,711);C(187,708,213,691,213,660);C(213,632,193,609,161,600);Z;M(303,564);L(351,564);L(416,744);L(411,754);L(338,754);Z];gid=2477,advance=425,lsb=48,bounds=48,-8,367,550,path=18[M(160,198);L(232,198);C(217,294,367,301,367,424);C(367,501,305,550,210,550);C(141,550,89,522,48,484);L(88,436);C(122,469,159,485,200,485);C(258,485,287,453,287,414);C(287,321,140,305,160,198);Z;M(89,-8);L(137,-8);C(136,53,161,78,199,78);C(236,78,261,53,260,-8);L(308,-8);C(312,90,270,138,199,138);C(127,138,85,90,89,-8);Z]]
MNF_CFF_BENCH_CORRECTNESS|cjk-high-gid-multi-fd-outline-batch|cff-runtime-semantics/1|workload=cjk-high-gid-multi-fd-outline-batch|fixture=source-han-serif-jp-2.003R|source_length=6210796|operation=outline-batch|glyphs=6[gid=2,advance=308,lsb=95,bounds=95,-13,214,747,path=15[M(154,-13);C(189,-13,214,14,214,46);C(214,79,189,104,154,104);C(120,104,95,79,95,46);C(95,14,120,-13,154,-13);Z;M(154,747);C(122,747,102,728,102,689);C(102,637,113,554,129,412);L(141,217);L(167,217);L(180,412);C(196,554,206,637,206,689);C(206,728,186,747,154,747);Z];gid=256,advance=0,lsb=314,bounds=314,484,685,826,path=7[M(499,592);L(342,825);L(314,810);L(496,484);L(685,811);L(657,826);Z];gid=2048,advance=1000,lsb=32,bounds=32,-89,986,832,path=88[M(84,664);L(68,660);C(91,585,117,472,113,387);C(167,328,220,475,84,664);Z;M(368,667);C(359,599,332,464,309,377);L(322,373);C(365,450,407,553,429,610);C(450,609,461,620,463,628);Z;M(849,826);L(837,819);C(859,793,882,748,882,713);C(931,670,986,769,849,826);Z;M(49,761);L(57,732);L(219,732);L(219,314);L(32,314);L(40,285);L(219,285);L(219,-83);L(228,-83);C(258,-83,277,-68,277,-63);L(277,285);L(457,285);C(471,285,481,290,484,301);C(454,331,406,370,406,370);L(364,314);L(277,314);L(277,732);L(441,732);C(455,732,465,737,468,748);C(439,776,391,815,391,815);L(349,761);Z;M(503,633);L(503,384);C(503,226,497,60,413,-73);L(428,-84);C(553,47,561,238,561,385);L(561,408);L(640,408);C(639,216,635,144,623,126);C(620,122,618,120,612,120);C(601,120,574,121,557,122);L(557,106);C(574,102,590,97,598,90);C(607,83,611,67,611,57);C(630,58,647,64,662,78);C(690,107,691,186,693,403);C(712,405,724,410,731,418);L(662,473);L(630,438);L(561,438);L(561,603);L(731,603);C(735,432,747,281,781,159);C(743,74,692,-3,626,-64);L(638,-76);C(705,-27,758,35,799,102);C(816,58,836,19,861,-15);C(888,-56,940,-89,964,-65);C(973,-56,970,-41,948,-1);L(964,152);L(951,154);C(941,114,926,69,917,45);C(908,24,905,23,894,41);C(869,75,849,117,834,166);C(882,264,911,369,929,463);C(957,463,965,469,970,482);L(871,505);C(862,422,844,332,815,245);C(794,350,788,473,787,603);L(944,603);C(958,603,967,608,970,619);C(941,648,894,686,894,686);L(852,633);L(787,633);L(788,792);C(813,795,822,807,824,819);L(729,832);L(730,633);L(572,633);L(503,664);Z];gid=8192,advance=1000,lsb=45,bounds=43,-117,1007,841,path=87[M(581,595);L(581,266);L(593,266);C(617,266,643,279,643,287);L(643,559);C(667,563,676,571,678,584);Z;M(786,611);L(786,246);C(786,233,782,227,766,227);C(750,227,667,234,667,234);L(667,218);C(704,213,725,206,737,197);C(750,187,753,173,755,155);C(840,164,850,192,850,243);L(850,575);C(873,578,883,586,886,600);Z;M(234,523);L(224,513);C(259,494,299,454,311,422);C(372,389,408,508,234,523);Z;M(233,395);L(223,386);C(257,365,296,322,308,289);C(369,252,408,373,233,395);Z;M(187,129);C(181,63,127,13,81,-5);C(59,-16,43,-36,52,-58);C(62,-83,99,-84,127,-68);C(172,-45,225,20,204,129);Z;M(340,125);L(327,121);C(347,74,369,4,368,-51);C(425,-110,497,13,340,125);Z;M(533,125);L(522,119);C(559,74,605,3,616,-53);C(684,-106,741,39,533,125);Z;M(747,138);L(736,129);C(795,81,868,-3,888,-70);C(966,-117,1007,51,747,138);Z;M(267,835);L(256,829);C(291,796,332,742,344,698);L(348,696);L(45,696);L(53,666);L(927,666);C(941,666,950,671,953,682);C(919,713,865,757,865,757);L(817,696);L(599,696);C(637,726,674,762,700,792);C(722,791,734,799,738,811);L(633,841);C(617,798,590,739,565,696);L(389,696);C(421,719,411,801,267,835);Z;M(138,588);L(138,154);L(148,154);C(174,154,200,169,200,174);L(200,559);L(411,559);L(411,245);C(411,232,407,227,392,227);C(374,227,304,233,304,233);L(304,216);C(338,212,356,205,367,196);C(378,187,381,172,383,156);C(462,163,471,192,471,240);L(471,547);C(492,550,508,559,514,566);L(432,627);L(401,588);L(205,588);L(138,619);Z];gid=16384,advance=1000,lsb=42,bounds=42,-35,961,836,path=34[M(464,836);L(464,626);L(96,626);L(104,597);L(464,597);L(464,327);L(128,327);L(136,298);L(464,298);L(464,-6);L(42,-6);L(51,-35);L(934,-35);C(949,-35,958,-30,961,-20);C(924,14,865,59,865,59);L(813,-6);L(533,-6);L(533,298);L(852,298);C(866,298,876,302,879,313);C(843,345,787,389,787,389);L(737,327);L(533,327);L(533,569);C(555,572,563,581,565,595);L(547,597);L(888,597);C(902,597,911,602,914,613);C(878,645,820,690,820,690);L(769,626);L(533,626);L(533,798);C(557,802,568,812,569,826);Z];gid=17922,advance=1000,lsb=380,bounds=380,83,1056,783,path=28[M(400,99);L(410,83);C(639,165,775,306,858,492);C(868,516,892,525,892,545);C(892,567,829,620,802,620);C(787,620,783,608,760,603);C(723,596,501,571,452,571);C(425,571,408,594,392,613);L(380,607);C(381,587,382,574,386,561);C(394,539,431,499,457,499);C(473,499,490,512,509,517);C(552,529,749,559,788,559);C(795,559,799,558,797,549);C(759,376,611,207,400,99);Z;M(953,577);C(1009,577,1056,625,1056,680);C(1056,737,1009,783,953,783);C(896,783,850,737,850,680);C(850,625,896,577,953,577);Z;M(953,610);C(915,610,882,642,882,680);C(882,719,915,751,953,751);C(992,751,1023,719,1023,680);C(1023,642,992,610,953,610);Z]]
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:164&#32;("bench&#32;cff/latin-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;924.64&#32;ms&#32;±&#32;&#32;40.24&#32;ms&#32;&#32;&#32;876.80&#32;ms&#32;…&#32;992.04&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:191&#32;("bench&#32;cff/cjk-full-admission")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;26.01&#32;s&#32;±&#32;459.73&#32;ms&#32;&#32;&#32;&#32;25.32&#32;s&#32;…&#32;&#32;26.79&#32;s&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;&#32;1&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:218&#32;("bench&#32;cff/latin-fixed-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;2.79&#32;ms&#32;±&#32;173.48&#32;µs&#32;&#32;&#32;&#32;&#32;2.57&#32;ms&#32;…&#32;&#32;&#32;3.05&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;40&#32;runs
[moonbit-foundation/font-cff-evidence]&#32;bench&#32;cff_bench.mbt:241&#32;("bench&#32;cff/cjk-high-gid-multi-fd-outline-batch")&#32;ok
time&#32;(mean&#32;±&#32;σ)&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;range&#32;(min&#32;…&#32;max)&#32;
&#32;&#32;&#32;4.39&#32;ms&#32;±&#32;218.81&#32;µs&#32;&#32;&#32;&#32;&#32;4.13&#32;ms&#32;…&#32;&#32;&#32;4.82&#32;ms&#32;&#32;in&#32;10&#32;×&#32;&#32;&#32;&#32;&#32;24&#32;runs
Total&#32;tests:&#32;4,&#32;passed:&#32;4,&#32;failed:&#32;0.
</pre>
</details>

## Seven-capture descriptive statistics

| Workload | Mean (ms) | Median (ms) | Sample standard deviation (ms, n-1=6) | Minimum (ms) | Maximum (ms) | Coefficient of variation |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| latin-full-admission | 919.404285714 | 919.590000000 | 27.013033186 | 881.920000000 | 967.960000000 | 0.029381017 |
| cjk-full-admission | 25771.428571429 | 26010.000000000 | 474.567472246 | 25070.000000000 | 26140.000000000 | 0.018414481 |
| latin-fixed-outline-batch | 2.690000000 | 2.670000000 | 0.187527776 | 2.500000000 | 2.990000000 | 0.069712928 |
| cjk-high-gid-multi-fd-outline-batch | 4.352857143 | 4.370000000 | 0.149857075 | 4.140000000 | 4.570000000 | 0.034427290 |

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
    "git_commit": "a890f3cef8aeccd0f52c63513d9d952c2d85c2b6",
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
      "length": 49792,
      "sha256": "e6ede29984b048a51837e317796bf3baf5a5cfbb7a226d60502b36c72da1c16b"
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
      "length": 26432302,
      "sha256": "d533c6f54f6a83e16d6c43527f9f8b73ccd63e15dfab032de57e2af5c397d0fb"
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
      "path": "benchmarks/font-cff/cff_runtime_semantics.mbt",
      "length": 5792,
      "sha256": "d7a2f21212bb9ee058ec55797612b2d28bf52eb034df0789176378b7ca56d970"
    },
    {
      "path": "benchmarks/font-cff/cff_bench.mbt",
      "length": 7522,
      "sha256": "05aaf80f6d2e5eb6dbda4824668de1af91a9ff542b9e9def3720c24c554851da"
    },
    {
      "path": "benchmarks/moon.work",
      "length": 139,
      "sha256": "2562fdf6d4dba04d48b32b207764edb6076c1772d0e53ef1e1712e82ebf93895"
    },
    {
      "path": "scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1",
      "length": 71451,
      "sha256": "6398d93d1061d5137f8455790c95a57c12580159b6439645690a2aed52027b00"
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
      "started_utc": "2026-07-29T17:29:41.9883236Z",
      "ended_utc": "2026-07-29T17:37:20.3746337Z",
      "exit_code": 0,
      "output_sha256": "558f611cceb52bb414357018f2c36f5e7bb318e4c944ee8116288133b3ed736b",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 958.63,
          "sigma_ms": 36.47,
          "minimum_ms": 908.86,
          "maximum_ms": 1020.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 26560.0,
          "sigma_ms": 414.46,
          "minimum_ms": 25900.0,
          "maximum_ms": 27290.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.85,
          "sigma_ms": 0.34483,
          "minimum_ms": 2.6,
          "maximum_ms": 3.45,
          "batch_size": 10,
          "runs": 40
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.59,
          "sigma_ms": 0.31435,
          "minimum_ms": 4.18,
          "maximum_ms": 5.11,
          "batch_size": 10,
          "runs": 21
        }
      ],
      "correctness": [
        {
          "id": "latin-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11",
          "observed": true
        },
        {
          "id": "cjk-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5",
          "observed": true
        },
        {
          "id": "latin-fixed-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d",
          "observed": true
        },
        {
          "id": "cjk-high-gid-multi-fd-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb",
          "observed": true
        }
      ]
    },
    {
      "id": "1",
      "label": "retained capture 1",
      "started_utc": "2026-07-29T17:37:20.4462545Z",
      "ended_utc": "2026-07-29T17:44:09.3032957Z",
      "exit_code": 0,
      "output_sha256": "34d2bc705a9db73deb9197dafe8cbed5ebd87d4ace9bff1f5f57bd30ac88f926",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 930.35,
          "sigma_ms": 55.27,
          "minimum_ms": 867.72,
          "maximum_ms": 1040.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 26140.0,
          "sigma_ms": 313.09,
          "minimum_ms": 25490.0,
          "maximum_ms": 26650.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.51,
          "sigma_ms": 0.12377,
          "minimum_ms": 2.36,
          "maximum_ms": 2.79,
          "batch_size": 10,
          "runs": 27
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.48,
          "sigma_ms": 0.47397,
          "minimum_ms": 4.12,
          "maximum_ms": 5.69,
          "batch_size": 10,
          "runs": 21
        }
      ],
      "correctness": [
        {
          "id": "latin-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11",
          "observed": true
        },
        {
          "id": "cjk-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5",
          "observed": true
        },
        {
          "id": "latin-fixed-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d",
          "observed": true
        },
        {
          "id": "cjk-high-gid-multi-fd-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb",
          "observed": true
        }
      ]
    },
    {
      "id": "2",
      "label": "retained capture 2",
      "started_utc": "2026-07-29T17:44:09.3163646Z",
      "ended_utc": "2026-07-29T17:50:59.6153510Z",
      "exit_code": 0,
      "output_sha256": "25e93958be01a5e76cbe7e02c0424017bd540027b8583e438bfd9f9ee38dfcda",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 919.59,
          "sigma_ms": 47.52,
          "minimum_ms": 857.83,
          "maximum_ms": 990.77,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 26040.0,
          "sigma_ms": 218.18,
          "minimum_ms": 25640.0,
          "maximum_ms": 26460.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.67,
          "sigma_ms": 0.24009,
          "minimum_ms": 2.37,
          "maximum_ms": 3.02,
          "batch_size": 10,
          "runs": 35
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.57,
          "sigma_ms": 0.33495,
          "minimum_ms": 4.22,
          "maximum_ms": 5.16,
          "batch_size": 10,
          "runs": 24
        }
      ],
      "correctness": [
        {
          "id": "latin-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11",
          "observed": true
        },
        {
          "id": "cjk-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5",
          "observed": true
        },
        {
          "id": "latin-fixed-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d",
          "observed": true
        },
        {
          "id": "cjk-high-gid-multi-fd-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb",
          "observed": true
        }
      ]
    },
    {
      "id": "3",
      "label": "retained capture 3",
      "started_utc": "2026-07-29T17:50:59.6328636Z",
      "ended_utc": "2026-07-29T17:57:47.2610819Z",
      "exit_code": 0,
      "output_sha256": "ceb38a133c02264aaf6617b0eb59361a80ea2bf5d588323048ada98088d1dd5e",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 912.46,
          "sigma_ms": 34.36,
          "minimum_ms": 868.39,
          "maximum_ms": 978.34,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 26120.0,
          "sigma_ms": 144.48,
          "minimum_ms": 25890.0,
          "maximum_ms": 26330.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.99,
          "sigma_ms": 0.44801,
          "minimum_ms": 2.54,
          "maximum_ms": 3.86,
          "batch_size": 10,
          "runs": 29
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.37,
          "sigma_ms": 0.27622,
          "minimum_ms": 4.04,
          "maximum_ms": 4.82,
          "batch_size": 10,
          "runs": 22
        }
      ],
      "correctness": [
        {
          "id": "latin-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11",
          "observed": true
        },
        {
          "id": "cjk-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5",
          "observed": true
        },
        {
          "id": "latin-fixed-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d",
          "observed": true
        },
        {
          "id": "cjk-high-gid-multi-fd-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb",
          "observed": true
        }
      ]
    },
    {
      "id": "4",
      "label": "retained capture 4",
      "started_utc": "2026-07-29T17:57:47.2727674Z",
      "ended_utc": "2026-07-29T18:04:35.5947818Z",
      "exit_code": 0,
      "output_sha256": "752463bcd86f84c486252fc81d39517d53da4467c138a4f41bf4d5449ea9957a",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 967.96,
          "sigma_ms": 52.8,
          "minimum_ms": 891.27,
          "maximum_ms": 1050.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 25920.0,
          "sigma_ms": 677.06,
          "minimum_ms": 25250.0,
          "maximum_ms": 26840.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.54,
          "sigma_ms": 0.06869,
          "minimum_ms": 2.42,
          "maximum_ms": 2.62,
          "batch_size": 10,
          "runs": 40
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.32,
          "sigma_ms": 0.43669,
          "minimum_ms": 3.88,
          "maximum_ms": 5.14,
          "batch_size": 10,
          "runs": 23
        }
      ],
      "correctness": [
        {
          "id": "latin-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11",
          "observed": true
        },
        {
          "id": "cjk-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5",
          "observed": true
        },
        {
          "id": "latin-fixed-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d",
          "observed": true
        },
        {
          "id": "cjk-high-gid-multi-fd-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb",
          "observed": true
        }
      ]
    },
    {
      "id": "5",
      "label": "retained capture 5",
      "started_utc": "2026-07-29T18:04:35.6042670Z",
      "ended_utc": "2026-07-29T18:11:07.8975654Z",
      "exit_code": 0,
      "output_sha256": "3fff79a808e6f5e1c1651eb0a14120c614ffb2e3f0d5fd915e320b2c433b48f1",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 881.92,
          "sigma_ms": 33.08,
          "minimum_ms": 834.24,
          "maximum_ms": 937.5,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 25100.0,
          "sigma_ms": 316.54,
          "minimum_ms": 24590.0,
          "maximum_ms": 25470.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.83,
          "sigma_ms": 0.23168,
          "minimum_ms": 2.6,
          "maximum_ms": 3.4,
          "batch_size": 10,
          "runs": 36
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.2,
          "sigma_ms": 0.1469,
          "minimum_ms": 3.98,
          "maximum_ms": 4.4,
          "batch_size": 10,
          "runs": 26
        }
      ],
      "correctness": [
        {
          "id": "latin-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11",
          "observed": true
        },
        {
          "id": "cjk-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5",
          "observed": true
        },
        {
          "id": "latin-fixed-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d",
          "observed": true
        },
        {
          "id": "cjk-high-gid-multi-fd-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb",
          "observed": true
        }
      ]
    },
    {
      "id": "6",
      "label": "retained capture 6",
      "started_utc": "2026-07-29T18:11:07.9106331Z",
      "ended_utc": "2026-07-29T18:17:39.7034674Z",
      "exit_code": 0,
      "output_sha256": "807ffc3333ca62e06247eab4dd4668a613b8aaab3da2a92f90a62d1c45670d43",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 898.91,
          "sigma_ms": 41.59,
          "minimum_ms": 858.45,
          "maximum_ms": 995.34,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 25070.0,
          "sigma_ms": 364.44,
          "minimum_ms": 24610.0,
          "maximum_ms": 25630.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.5,
          "sigma_ms": 0.12065,
          "minimum_ms": 2.39,
          "maximum_ms": 2.73,
          "batch_size": 10,
          "runs": 39
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.14,
          "sigma_ms": 0.25964,
          "minimum_ms": 3.81,
          "maximum_ms": 4.48,
          "batch_size": 10,
          "runs": 25
        }
      ],
      "correctness": [
        {
          "id": "latin-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11",
          "observed": true
        },
        {
          "id": "cjk-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5",
          "observed": true
        },
        {
          "id": "latin-fixed-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d",
          "observed": true
        },
        {
          "id": "cjk-high-gid-multi-fd-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb",
          "observed": true
        }
      ]
    },
    {
      "id": "7",
      "label": "retained capture 7",
      "started_utc": "2026-07-29T18:17:39.7125971Z",
      "ended_utc": "2026-07-29T18:24:25.7832071Z",
      "exit_code": 0,
      "output_sha256": "40e0228d920be8de09c85b3f4c124022f1ec10cd9ec71ab8706819f4e61afdeb",
      "summaries": [
        {
          "name": "latin-full-admission",
          "mean_ms": 924.64,
          "sigma_ms": 40.24,
          "minimum_ms": 876.8,
          "maximum_ms": 992.04,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "cjk-full-admission",
          "mean_ms": 26010.0,
          "sigma_ms": 459.73,
          "minimum_ms": 25320.0,
          "maximum_ms": 26790.0,
          "batch_size": 10,
          "runs": 1
        },
        {
          "name": "latin-fixed-outline-batch",
          "mean_ms": 2.79,
          "sigma_ms": 0.17348,
          "minimum_ms": 2.57,
          "maximum_ms": 3.05,
          "batch_size": 10,
          "runs": 40
        },
        {
          "name": "cjk-high-gid-multi-fd-outline-batch",
          "mean_ms": 4.39,
          "sigma_ms": 0.21881,
          "minimum_ms": 4.13,
          "maximum_ms": 4.82,
          "batch_size": 10,
          "runs": 24
        }
      ],
      "correctness": [
        {
          "id": "latin-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11",
          "observed": true
        },
        {
          "id": "cjk-full-admission",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5",
          "observed": true
        },
        {
          "id": "latin-fixed-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d",
          "observed": true
        },
        {
          "id": "cjk-high-gid-multi-fd-outline-batch",
          "schema": "cff-runtime-semantics/1",
          "correctness_sha256": "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb",
          "observed": true
        }
      ]
    }
  ],
  "aggregates": [
    {
      "name": "latin-full-admission",
      "values": {
        "mean_ms": 919.404285714,
        "median_ms": 919.59,
        "sample_standard_deviation_ms": 27.013033186,
        "minimum_ms": 881.92,
        "maximum_ms": 967.96,
        "coefficient_of_variation": 0.029381017
      }
    },
    {
      "name": "cjk-full-admission",
      "values": {
        "mean_ms": 25771.428571429,
        "median_ms": 26010.0,
        "sample_standard_deviation_ms": 474.567472246,
        "minimum_ms": 25070.0,
        "maximum_ms": 26140.0,
        "coefficient_of_variation": 0.018414481
      }
    },
    {
      "name": "latin-fixed-outline-batch",
      "values": {
        "mean_ms": 2.69,
        "median_ms": 2.67,
        "sample_standard_deviation_ms": 0.187527776,
        "minimum_ms": 2.5,
        "maximum_ms": 2.99,
        "coefficient_of_variation": 0.069712928
      }
    },
    {
      "name": "cjk-high-gid-multi-fd-outline-batch",
      "values": {
        "mean_ms": 4.352857143,
        "median_ms": 4.37,
        "sample_standard_deviation_ms": 0.149857075,
        "minimum_ms": 4.14,
        "maximum_ms": 4.57,
        "coefficient_of_variation": 0.03442729
      }
    }
  ]
}
-->
