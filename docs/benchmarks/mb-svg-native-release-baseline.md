# mb-svg native release baseline

**Scope:** A native-host observation for like-for-like reproduction only. It makes no cross-target comparison, threshold, ranking, CI gate, regression conclusion, or marketing claim.

## Comparison identity

- Git commit: `c5e95efa46e6cad35e33515dbff3322abfef9da0`
- worktree: (clean)
- Working directory: `.`
- Exact native command: `moon bench modules/mb-svg/svg --release --target native --frozen`
- Comparison rule: comparable only if workload order/names, command, target, release mode, frozen mode, source/corpus/correctness digests, toolchain identity, and every recorded host fact agree exactly. Otherwise the records are **not comparable** and no inference is made.

## Functional qualification context (not timing evidence)

- Qualification command: `moon bench modules/mb-svg/svg --target all --frozen`
- Successful target labels: `wasm`, `wasm-gc`, `js`, `native`. No timing values from that command are retained here.

## Workload and source provenance

| Workload | Corpus SHA-256 | Canonical correctness SHA-256 |
| --- | --- | --- |
| path-parse/1000-line-to | `e97e1c8a8e29fdb3e84c309e421de34d41cbab7583cf1e88cf94a67af51eb259` | `0c7d3af32d324a136215c1158c4aab127d11e160f4b9239991114a0303762f22` |
| transform-composition/50-segment | `c0ed3307e143d7cb20fd90e531e6208a14bbe2e42ce2816a0579d04cbd320840` | `ec32349185e19b24757e391c72ac5fa8709f889847a0035b7257fc3e0ba483ff` |
| parse-to-lower/50-rect | `db053c95e904e016041f8b2f4a5e6471ed4bf1b144cfd0fc99c44d7d670cdddc` | `e76479b6744a5f062c21d7e5502971a45388346767e9d91aea0119c4340c18e5` |

- `svg_bench.mbt` SHA-256: `64dce536ca6f67b41bc6a3f80819583903b15caea97389cd9094ee4f46e6cfd3`
- `moon.pkg` SHA-256: `72d5d68152a6938e869db7362a9397e1d4dfd1c61e668b0fd3d165523440e672`
- Combined source SHA-256: `b795c4dc89793a681ac5d59b498da59e69180f9fb270bc6261af7bea9721db1f`

## Toolchain and host facts

- moon observed: `moon 0.1.20260713 (75c7e1f 2026-07-13) ~\.moon\bin\moon.exe
moonc v0.10.4+2cc641edf (2026-07-15) D:\AI-Data\moonbit\bin\moonc.exe
moonrun 0.1.20260713 (75c7e1f 2026-07-13) D:\AI-Data\moonbit\bin\moonrun.exe

Feature flags enabled: rr_moon_mod,rr_moon_pkg`
- moon policy: `0.1.20260713 (75c7e1f 2026-07-13)`
- moonc observed: `v0.10.4+2cc641edf (2026-07-15)`
- moonc policy: `v0.10.4+2cc641edf (2026-07-15)`
- moonrun observed: `moonrun 0.1.20260713 (75c7e1f 2026-07-13)`
- moonrun policy: `0.1.20260713 (75c7e1f 2026-07-13)`
- PowerShell: `5.1.22621.6931`; .NET runtime: `4.0.30319.42000`
- os: `Microsoft Windows 11 企业版 | version=10.0.22631 | build=22631 | architecture=64 位` (probe: `Get-CimInstance Win32_OperatingSystem`)
- cpu: `Intel(R) Xeon(R) Platinum 8378C CPU @ 2.80GHz | physical_cores=4 | logical_processors=8` (probe: `Get-CimInstance Win32_Processor | Select-Object -First 1`)
- physical_memory_bytes: `34358808576` (probe: `Get-CimInstance Win32_ComputerSystem`)
- active_power_scheme: `电源方案 GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (平衡)` (probe: `powercfg /GETACTIVESCHEME`)

## Captures

One successful warmup is retained for provenance and excluded from all statistics. Captures 1 through 7 are separate successful native release invocations.

### Warmup (excluded from summary)
- UTC start: `2026-07-25T20:08:46.5949739Z`
- UTC end: `2026-07-25T20:08:56.1176460Z`
- Exit status: `0`
- Output SHA-256: `d78bfba73286c07ee00a035fcb2070345920e5898ba334ea2e96fc0d2d3299ca`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.700000000 | 0.076640000 | 1.620000000 | 1.820000000 | 10 | 63 |
| transform-composition/50-segment | 0.127430000 | 0.008420000 | 0.120810000 | 0.148210000 | 10 | 822 |
| parse-to-lower/50-rect | 0.914270000 | 0.053710000 | 0.849500000 | 1.030000000 | 10 | 117 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-canvas\canvas\stroke.mbt:319:23 ]
     │
 319 │     let (tx, ty) = if not(pl.closed) && (i == 0 || i == n - 1) {
     │                       ─┬─  
     │                        ╰─── Warning (deprecated): Use !expr instead
─────╯
Warning: [0001]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-core\math\bezier.mbt:57:4 ]
    │
 57 │ fn bezier2_derivative(p0 : Point2, p1 : Point2, p2 : Point2, t : Double) -> Vector2 {
    │    ─────────┬────────  
    │             ╰────────── Warning (unused_value): Unused function 'bezier2_derivative'
────╯
Warning: [0001]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-core\math\bezier.mbt:68:4 ]
    │
 68 │ fn bezier3_derivative(
    │    ─────────┬────────  
    │             ╰────────── Warning (unused_value): Unused function 'bezier3_derivative'
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-core\text\xml_escape.mbt:131:26 ]
     │
 131 │       let inner = entity.substring(start=2, end=entity.length() - 1)
     │                          ────┬────  
     │                              ╰────── Warning (deprecated): Use `str[:]` or `str[:].to_string()` instead
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-core\text\xml_escape.mbt:136:31 ]
     │
 136 │           let hex_str = inner.substring(start=1)
     │                               ────┬────  
     │                                   ╰────── Warning (deprecated): Use `str[:]` or `str[:].to_string()` instead
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\color.mbt:244:19 ]
     │
 244 │     result.push(p.to_string())
     │                   ────┬────  
     │                       ╰────── Warning (deprecated): Use `to_owned` to allocate an owned String from a StringView; use `Show::to_string` or format strings for display
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\length.mbt:29:16 ]
    │
 29 │       return t.substring(end=t.length() - sf.length())
    │                ────┬────  
    │                    ╰────── Warning (deprecated): Use `str[:]` or `str[:].to_string()` instead
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:13:9 ]
    │
 13 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:32:9 ]
    │
 32 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:48:9 ]
    │
 48 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:55:9 ]
    │
 55 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:70:9 ]
    │
 70 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:88:9 ]
    │
 88 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:92:9 ]
    │
 92 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:96:9 ]
    │
 96 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:113:9 ]
     │
 113 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:117:9 ]
     │
 117 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:121:9 ]
     │
 121 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:125:9 ]
     │
 125 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:129:9 ]
     │
 129 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:148:9 ]
     │
 148 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:164:9 ]
     │
 164 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:168:9 ]
     │
 168 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:200:9 ]
     │
 200 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:215:9 ]
     │
 215 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:220:9 ]
     │
 220 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:243:9 ]
     │
 243 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:264:9 ]
     │
 264 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:279:9 ]
     │
 279 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:294:9 ]
     │
 294 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:309:9 ]
     │
 309 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:323:9 ]
     │
 323 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:345:9 ]
     │
 345 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:349:9 ]
     │
 349 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:370:9 ]
     │
 370 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:404:9 ]
     │
 404 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:422:9 ]
     │
 422 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:442:9 ]
     │
 442 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:462:9 ]
     │
 462 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:476:9 ]
     │
 476 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:490:9 ]
     │
 490 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:507:9 ]
     │
 507 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:511:9 ]
     │
 511 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:540:9 ]
     │
 540 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:591:23 ]
     │
 591 │               inspect((point.x(), point.y()), content="(32768, 0)")
     │                       ───────────┬──────────  
     │                                  ╰──────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:609:23 ]
     │
 609 │               inspect((point.x(), point.y().abs() < 1.0e-9), content="(65536, true)")
     │                       ──────────────────┬──────────────────  
     │                                         ╰──────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\lower_wbtest.mbt:630:29 ]
     │
 630 │       Err(error) => inspect(error.context(), content="Some(svg-numeric-derived)")
     │                             ───────┬───────  
     │                                    ╰───────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\parse_wbtest.mbt:77:33 ]
    │
 77 │     Ok((x, y, w, h)) => inspect((x, y, w, h), content="(10, 20, 200, 150)")
    │                                 ──────┬─────  
    │                                       ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\parse_wbtest.mbt:89:24 ]
    │
 89 │     Ok(arr) => inspect(arr, content="[1, 2, 3]")
    │                        ─┬─  
    │                         ╰─── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\parse_wbtest.mbt:113:27 ]
     │
 113 │     Ok(values) => inspect(values, content="[1, 2, 3]")
     │                           ───┬──  
     │                              ╰──── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\parse_wbtest.mbt:130:27 ]
     │
 130 │     Ok(values) => inspect(values, content="[-65536, 0, 65536]")
     │                           ───┬──  
     │                              ╰──── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\parse_wbtest.mbt:134:27 ]
     │
 134 │     Ok(bounds) => inspect(bounds, content="(-65536, -65536, 65536, 65536)")
     │                           ───┬──  
     │                              ╰──── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\path_data.mbt:274:28 ]
     │
 274 │   if v >= 97 && v <= 122 { Char::from_int(v - 32) } else { c }
     │                            ───────┬──────  
     │                                   ╰──────── Warning (deprecated): Use `Int::unsafe_to_char` instead, and use `Int::to_char` for safe conversion
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\path_data_wbtest.mbt:71:19 ]
    │
 71 │           inspect((start.x(), start.y(), end.x(), end.y()), content="(0, -10, 5, -3)")
    │                   ────────────────────┬───────────────────  
    │                                       ╰───────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\path_data_wbtest.mbt:206:19 ]
     │
 206 │           inspect((cp1.x(), cp1.y(), cp2.x(), cp2.y(), endpoint.x(), endpoint.y()), content="(17, 18, 17, 18, 19, 20)")
     │                   ────────────────────────────────┬───────────────────────────────  
     │                                                   ╰───────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\path_data_wbtest.mbt:207:19 ]
     │
 207 │           inspect((control.x(), control.y(), quad_endpoint.x(), quad_endpoint.y()), content="(25, 26, 25, 26)")
     │                   ────────────────────────────────┬───────────────────────────────  
     │                                                   ╰───────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\path_data_wbtest.mbt:221:62 ]
     │
 221 │         Some(@math.PathCommand::LineTo(endpoint)) => inspect((endpoint.x(), endpoint.y()), content="(5, 0)")
     │                                                              ──────────────┬─────────────  
     │                                                                            ╰─────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\path_data_wbtest.mbt:230:19 ]
     │
 230 │           inspect((cp1.x(), cp1.y(), cp2.x(), cp2.y(), endpoint.x(), endpoint.y()), content="(0, 0, 1, 0, 2, 0)")
     │                   ────────────────────────────────┬───────────────────────────────  
     │                                                   ╰───────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\portable_qualification_wbtest.mbt:111:9 ]
     │
 111 │         (corner_r.to_int(), corner_g.to_int(), corner_b.to_int(), corner_a.to_int()),
     │         ──────────────────────────────────────┬─────────────────────────────────────  
     │                                               ╰─────────────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\portable_qualification_wbtest.mbt:136:15 ]
     │
 136 │       inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(0, 0, 255, 255)")
     │               ────────────────────────┬───────────────────────  
     │                                       ╰───────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\portable_qualification_wbtest.mbt:151:19 ]
     │
 151 │           inspect((fill.color_a, stroke.color_a), content="(0.5, 0.5)")
     │                   ───────────────┬──────────────  
     │                                  ╰──────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\portable_qualification_wbtest.mbt:166:9 ]
     │
 166 │         (stroke_r.to_int(), stroke_g.to_int(), stroke_b.to_int(), stroke_a.to_int()),
     │         ──────────────────────────────────────┬─────────────────────────────────────  
     │                                               ╰─────────────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\portable_qualification_wbtest.mbt:192:15 ]
     │
 192 │       inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(128, 128, 255, 255)")
     │               ────────────────────────┬───────────────────────  
     │                                       ╰───────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\portable_qualification_wbtest.mbt:207:19 ]
     │
 207 │           inspect((group, element), content="(0.5, 0.5)")
     │                   ────────┬───────  
     │                           ╰───────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\portable_qualification_wbtest.mbt:250:9 ]
     │
 250 │ ╭─▶         (
     ┆ ┆   
 255 │ ├─▶         ),
     │ │                
     │ ╰──────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\portable_qualification_wbtest.mbt:336:9 ]
     │
 336 │         (corner_r.to_int(), corner_g.to_int(), corner_b.to_int(), corner_a.to_int()),
     │         ──────────────────────────────────────┬─────────────────────────────────────  
     │                                               ╰─────────────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0004]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene.mbt:100:8 ]
     │
 100 │ struct PaintContext {
     │        ──────┬─────  
     │              ╰─────── Warning (missing_priv): The type 'PaintContext' does not occur in public signature of current package, consider marking it as `priv`.
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:19:15 ]
    │
 19 │       inspect(root.height, content="Some(20)")
    │               ─────┬─────  
    │                    ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:21:39 ]
    │
 21 │         Some((x, y, w, h)) => inspect((x, y, w, h), content="(0, 0, 100, 50)")
    │                                       ──────┬─────  
    │                                             ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:43:27 ]
    │
 43 │                   inspect((x, y, w, h), content="(1, 2, 3, 4)")
    │                           ──────┬─────  
    │                                 ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:62:19 ]
    │
 62 │           inspect((x, y, w, h, rx, ry), content="(1, 2, 3, 4, 0, 0)")
    │                   ──────────┬─────────  
    │                             ╰─────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:67:19 ]
    │
 67 │           inspect(paint.stroke, content="None")
    │                   ──────┬─────  
    │                         ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:83:19 ]
    │
 83 │           inspect(paint.fill, content="None")
    │                   ─────┬────  
    │                        ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:85:40 ]
    │
 85 │             Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
    │                                        ────┬────  
    │                                            ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:122:23 ]
     │
 122 │               inspect((p2.x(), p2.y()), content="(10, 10)")
     │                       ────────┬───────  
     │                               ╰───────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:154:23 ]
     │
 154 │               inspect((x, y, width, height), content="(1, 2, 3, 4)")
     │                       ──────────┬──────────  
     │                                 ╰──────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:212:44 ]
     │
 212 │                 Some((r, g, b)) => inspect((r, g, b), content="(1, 0, 0)")
     │                                            ────┬────  
     │                                                ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:234:44 ]
     │
 234 │                 Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
     │                                            ────┬────  
     │                                                ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:282:44 ]
     │
 282 │                 Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
     │                                            ────┬────  
     │                                                ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:302:54 ]
     │
 302 │             Rect(paint, _, _, _, _, _, _) => inspect(paint.fill, content="None")
     │                                                      ─────┬────  
     │                                                           ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:350:44 ]
     │
 350 │                 Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
     │                                            ────┬────  
     │                                                ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:372:15 ]
     │
 372 │       inspect(root.view_box, content="Some((0, 0, 65536, 65536))")
     │               ──────┬──────  
     │                     ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:376:19 ]
     │
 376 │           inspect((x, y, width, height), content="(-65536, -65536, 65536, 65536)")
     │                   ──────────┬──────────  
     │                             ╰──────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:377:19 ]
     │
 377 │           inspect(paint.stroke_dash, content="[1, 65536]")
     │                   ────────┬────────  
     │                           ╰────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:378:19 ]
     │
 378 │           inspect((paint.fill_opacity, paint.stroke_opacity, paint.stroke_width, paint.stroke_miterlimit, paint.stroke_dashoffset), content="(65536, 65536, 65536, 65536, 65536)")
     │                   ────────────────────────────────────────────────────────┬───────────────────────────────────────────────────────  
     │                                                                           ╰───────────────────────────────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:426:15 ]
     │
 426 │       inspect(root.height, content="None")
     │               ─────┬─────  
     │                    ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:430:54 ]
     │
 430 │             Rect(paint, _, _, _, _, _, _) => inspect(paint.fill, content="Some((0, 0, 1))")
     │                                                      ─────┬────  
     │                                                           ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:461:29 ]
     │
 461 │       Err(error) => inspect(error.operation(), content="Some(svg)")
     │                             ────────┬────────  
     │                                     ╰────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\scene_wbtest.mbt:467:65 ]
     │
 467 │         Group(_, _, [Rect(paint, _, _, _, _, _, _)]) => inspect(paint.fill, content="Some((0, 0, 1))")
     │                                                                 ─────┬────  
     │                                                                      ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:40:22 ]
    │
 40 │     Ok(m) => inspect((tx(m), ty(m)), content="(5, 0)")
    │                      ───────┬──────  
    │                             ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:52:22 ]
    │
 52 │     Ok(m) => inspect((m.a(), m.d()), content="(2, 3)")
    │                      ───────┬──────  
    │                             ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:60:22 ]
    │
 60 │     Ok(m) => inspect((m.a(), m.b(), m.c(), m.d(), tx(m), ty(m)), content="(1, 2, 3, 4, 5, 6)")
    │                      ─────────────────────┬────────────────────  
    │                                           ╰────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:76:15 ]
    │
 76 │       inspect((p.x(), p.y()), content="(12, 0)")
    │               ───────┬──────  
    │                      ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:109:15 ]
     │
 109 │       inspect((p.x().abs() < 1.0e-9, (p.y() - 1.0).abs() < 1.0e-9), content="(true, true)")
     │               ──────────────────────────┬─────────────────────────  
     │                                         ╰─────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:125:15 ]
     │
 125 │       inspect(((q.x() - 1.0).abs() < 1.0e-9, (q.y() - 2.0).abs() < 1.0e-9), content="(true, true)")
     │               ──────────────────────────────┬─────────────────────────────  
     │                                             ╰─────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:164:22 ]
     │
 164 │     Ok(m) => inspect((m.a(), m.d(), tx(m), ty(m)), content="(1, 1, 65536, -65536)")
     │                      ──────────────┬─────────────  
     │                                    ╰─────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:187:15 ]
     │
 187 │       inspect((point.x().abs() < 1.0e-9, (point.y() - 1.0).abs() < 1.0e-9), content="(true, true)")
     │               ──────────────────────────────┬─────────────────────────────  
     │                                             ╰─────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:203:15 ]
     │
 203 │       inspect((point.x(), point.y()), content="(65536, 0)")
     │               ───────────┬──────────  
     │                          ╰──────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:239:29 ]
     │
 239 │       Err(error) => inspect(error.context(), content="Some(svg-numeric-derived)")
     │                             ───────┬───────  
     │                                    ╰───────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-c5e95ef\modules\mb-svg\svg\transform_wbtest.mbt:243:22 ]
     │
 243 │     Ok(m) => inspect((m.a(), m.d()), content="(0, 0)")
     │                      ───────┬──────  
     │                             ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.70 ms ±  76.64 µs     1.62 ms …   1.82 ms  in 10 ×     63 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 127.43 µs ±   8.42 µs   120.81 µs … 148.21 µs  in 10 ×    822 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 914.27 µs ±  53.71 µs   849.50 µs …   1.03 ms  in 10 ×    117 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 1
- UTC start: `2026-07-25T20:08:56.2160897Z`
- UTC end: `2026-07-25T20:09:00.1521366Z`
- Exit status: `0`
- Output SHA-256: `eddb715f0a14cf98daf7748591b3f201420de430e47e8bd13d99e0a3d059a86e`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.760000000 | 0.129160000 | 1.590000000 | 1.920000000 | 10 | 56 |
| transform-composition/50-segment | 0.144430000 | 0.011270000 | 0.128570000 | 0.166590000 | 10 | 667 |
| parse-to-lower/50-rect | 0.879560000 | 0.036760000 | 0.853510000 | 0.954720000 | 10 | 108 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.76 ms ± 129.16 µs     1.59 ms …   1.92 ms  in 10 ×     56 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 144.43 µs ±  11.27 µs   128.57 µs … 166.59 µs  in 10 ×    667 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 879.56 µs ±  36.76 µs   853.51 µs … 954.72 µs  in 10 ×    108 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 2
- UTC start: `2026-07-25T20:09:00.1545008Z`
- UTC end: `2026-07-25T20:09:04.1451449Z`
- Exit status: `0`
- Output SHA-256: `7dd53503905802fc60809f0eeb148797d2e6826526d4b80b1cd8fd61a4feabd6`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.660000000 | 0.113030000 | 1.570000000 | 1.920000000 | 10 | 52 |
| transform-composition/50-segment | 0.127600000 | 0.006810000 | 0.121650000 | 0.141150000 | 10 | 824 |
| parse-to-lower/50-rect | 0.912420000 | 0.097360000 | 0.839210000 | 1.110000000 | 10 | 118 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.66 ms ± 113.03 µs     1.57 ms …   1.92 ms  in 10 ×     52 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 127.60 µs ±   6.81 µs   121.65 µs … 141.15 µs  in 10 ×    824 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 912.42 µs ±  97.36 µs   839.21 µs …   1.11 ms  in 10 ×    118 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 3
- UTC start: `2026-07-25T20:09:04.1478724Z`
- UTC end: `2026-07-25T20:09:07.8491581Z`
- Exit status: `0`
- Output SHA-256: `74cd02ce9201eec5b943c244bf3c03b35d346ddca3e58fd9bff2f500da8cabf2`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.750000000 | 0.155730000 | 1.560000000 | 2.010000000 | 10 | 48 |
| transform-composition/50-segment | 0.123900000 | 0.003320000 | 0.119990000 | 0.128180000 | 10 | 785 |
| parse-to-lower/50-rect | 0.863090000 | 0.015840000 | 0.844390000 | 0.896890000 | 10 | 94 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.75 ms ± 155.73 µs     1.56 ms …   2.01 ms  in 10 ×     48 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 123.90 µs ±   3.32 µs   119.99 µs … 128.18 µs  in 10 ×    785 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 863.09 µs ±  15.84 µs   844.39 µs … 896.89 µs  in 10 ×     94 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 4
- UTC start: `2026-07-25T20:09:07.8521233Z`
- UTC end: `2026-07-25T20:09:11.6297503Z`
- Exit status: `0`
- Output SHA-256: `f0dc3e53430c27231d48801e05e565909e73332abb20323b0050b2091d9c6610`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.590000000 | 0.074180000 | 1.540000000 | 1.740000000 | 10 | 50 |
| transform-composition/50-segment | 0.135620000 | 0.007110000 | 0.124550000 | 0.146510000 | 10 | 776 |
| parse-to-lower/50-rect | 0.884560000 | 0.060140000 | 0.841990000 | 0.994640000 | 10 | 108 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.59 ms ±  74.18 µs     1.54 ms …   1.74 ms  in 10 ×     50 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 135.62 µs ±   7.11 µs   124.55 µs … 146.51 µs  in 10 ×    776 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 884.56 µs ±  60.14 µs   841.99 µs … 994.64 µs  in 10 ×    108 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 5
- UTC start: `2026-07-25T20:09:11.6363282Z`
- UTC end: `2026-07-25T20:09:15.3815751Z`
- Exit status: `0`
- Output SHA-256: `d36d9c443bc267a8517c40441bdbb77d09c6db849de3805be85cbce51fa33265`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.670000000 | 0.063960000 | 1.600000000 | 1.780000000 | 10 | 53 |
| transform-composition/50-segment | 0.128890000 | 0.006580000 | 0.122870000 | 0.142330000 | 10 | 656 |
| parse-to-lower/50-rect | 0.915040000 | 0.097010000 | 0.841160000 | 1.130000000 | 10 | 106 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.67 ms ±  63.96 µs     1.60 ms …   1.78 ms  in 10 ×     53 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 128.89 µs ±   6.58 µs   122.87 µs … 142.33 µs  in 10 ×    656 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 915.04 µs ±  97.01 µs   841.16 µs …   1.13 ms  in 10 ×    106 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 6
- UTC start: `2026-07-25T20:09:15.3827708Z`
- UTC end: `2026-07-25T20:09:19.4774776Z`
- Exit status: `0`
- Output SHA-256: `8758571725ba6817fb330fde413fad1a91fcdc6ceb68c40bee9af6b1a91275ad`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.630000000 | 0.071420000 | 1.550000000 | 1.750000000 | 10 | 65 |
| transform-composition/50-segment | 0.131800000 | 0.012930000 | 0.121990000 | 0.166560000 | 10 | 517 |
| parse-to-lower/50-rect | 1.010000000 | 0.177830000 | 0.840160000 | 1.280000000 | 10 | 113 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.63 ms ±  71.42 µs     1.55 ms …   1.75 ms  in 10 ×     65 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 131.80 µs ±  12.93 µs   121.99 µs … 166.56 µs  in 10 ×    517 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
   1.01 ms ± 177.83 µs   840.16 µs …   1.28 ms  in 10 ×    113 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 7
- UTC start: `2026-07-25T20:09:19.4792045Z`
- UTC end: `2026-07-25T20:09:23.6988624Z`
- Exit status: `0`
- Output SHA-256: `03228bb11356147d641d4cee8d26816d39cffbfcdc10d6ec74c95639ae490873`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.680000000 | 0.146130000 | 1.550000000 | 1.930000000 | 10 | 62 |
| transform-composition/50-segment | 0.135340000 | 0.010180000 | 0.126650000 | 0.157740000 | 10 | 810 |
| parse-to-lower/50-rect | 1.010000000 | 0.145150000 | 0.856970000 | 1.300000000 | 10 | 112 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.68 ms ± 146.13 µs     1.55 ms …   1.93 ms  in 10 ×     62 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 135.34 µs ±  10.18 µs   126.65 µs … 157.74 µs  in 10 ×    810 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
   1.01 ms ± 145.15 µs   856.97 µs …   1.30 ms  in 10 ×    112 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

## Native-host-specific seven-capture summary

| Workload | Arithmetic mean (ms) | Median (ms) | Sample standard deviation (ms) | Minimum (ms) | Maximum (ms) | Coefficient of variation |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.677142857 | 1.670000000 | 0.061023025 | 1.590000000 | 1.760000000 | 0.036385108 |
| transform-composition/50-segment | 0.132511429 | 0.131800000 | 0.006728250 | 0.123900000 | 0.144430000 | 0.050774866 |
| parse-to-lower/50-rect | 0.924952857 | 0.912420000 | 0.060883054 | 0.863090000 | 1.010000000 | 0.065822873 |

## Read-only audit

Run `powershell.exe -NoProfile -File scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 -Audit` or `pwsh -NoProfile -File scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 -Audit` from a clean checkout. Audit reads this Markdown and current fixed inputs only; it does not run MoonBit, write Markdown, or make a timing decision.

<!-- SVG-BASELINE-DATA
{
    "schema_version":  1,
    "claim":  "native-host observation only; no threshold, ranking, regression conclusion, CI gate, cross-target comparison, or performance claim",
    "identity":  {
                     "git_commit":  "c5e95efa46e6cad35e33515dbff3322abfef9da0",
                     "worktree":  "(clean)"
                 },
    "execution":  {
                      "command":  "moon bench modules/mb-svg/svg --release --target native --frozen",
                      "working_directory":  ".",
                      "target":  "native",
                      "release":  true,
                      "frozen":  true,
                      "output_encoding":  "normalized UTF-8 without BOM"
                  },
    "source":  {
                   "svg_bench_sha256":  "64dce536ca6f67b41bc6a3f80819583903b15caea97389cd9094ee4f46e6cfd3",
                   "moon_pkg_sha256":  "72d5d68152a6938e869db7362a9397e1d4dfd1c61e668b0fd3d165523440e672",
                   "combined_sha256":  "b795c4dc89793a681ac5d59b498da59e69180f9fb270bc6261af7bea9721db1f"
               },
    "workloads":  [
                      {
                          "name":  "path-parse/1000-line-to",
                          "corpus_sha256":  "e97e1c8a8e29fdb3e84c309e421de34d41cbab7583cf1e88cf94a67af51eb259",
                          "correctness_sha256":  "0c7d3af32d324a136215c1158c4aab127d11e160f4b9239991114a0303762f22"
                      },
                      {
                          "name":  "transform-composition/50-segment",
                          "corpus_sha256":  "c0ed3307e143d7cb20fd90e531e6208a14bbe2e42ce2816a0579d04cbd320840",
                          "correctness_sha256":  "ec32349185e19b24757e391c72ac5fa8709f889847a0035b7257fc3e0ba483ff"
                      },
                      {
                          "name":  "parse-to-lower/50-rect",
                          "corpus_sha256":  "db053c95e904e016041f8b2f4a5e6471ed4bf1b144cfd0fc99c44d7d670cdddc",
                          "correctness_sha256":  "e76479b6744a5f062c21d7e5502971a45388346767e9d91aea0119c4340c18e5"
                      }
                  ],
    "toolchain":  {
                      "raw":  {
                                  "moon":  "moon 0.1.20260713 (75c7e1f 2026-07-13) ~\\.moon\\bin\\moon.exe\r\nmoonc v0.10.4+2cc641edf (2026-07-15) D:\\AI-Data\\moonbit\\bin\\moonc.exe\r\nmoonrun 0.1.20260713 (75c7e1f 2026-07-13) D:\\AI-Data\\moonbit\\bin\\moonrun.exe\r\n\r\nFeature flags enabled: rr_moon_mod,rr_moon_pkg",
                                  "moonc":  "v0.10.4+2cc641edf (2026-07-15)",
                                  "moonrun":  "moonrun 0.1.20260713 (75c7e1f 2026-07-13)"
                              },
                      "policy_expected":  {
                                              "moon":  "0.1.20260713 (75c7e1f 2026-07-13)",
                                              "moonc":  "v0.10.4+2cc641edf (2026-07-15)",
                                              "moonrun":  "0.1.20260713 (75c7e1f 2026-07-13)"
                                          }
                  },
    "host":  {
                 "powershell":  "5.1.22621.6931",
                 "dotnet_runtime":  "4.0.30319.42000",
                 "os":  {
                            "value":  "Microsoft Windows 11 企业版 | version=10.0.22631 | build=22631 | architecture=64 位",
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
                                             "value":  "电源方案 GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (平衡)",
                                             "attempted":  "powercfg /GETACTIVESCHEME"
                                         }
             },
    "aggregates":  [
                       {
                           "name":  "path-parse/1000-line-to",
                           "values":  {
                                          "mean_ms":  1.677142857,
                                          "median_ms":  1.67,
                                          "sample_standard_deviation_ms":  0.061023025,
                                          "minimum_ms":  1.59,
                                          "maximum_ms":  1.76,
                                          "coefficient_of_variation":  0.036385108
                                      }
                       },
                       {
                           "name":  "transform-composition/50-segment",
                           "values":  {
                                          "mean_ms":  0.13251142899999999,
                                          "median_ms":  0.1318,
                                          "sample_standard_deviation_ms":  0.00672825,
                                          "minimum_ms":  0.1239,
                                          "maximum_ms":  0.14443,
                                          "coefficient_of_variation":  0.050774866
                                      }
                       },
                       {
                           "name":  "parse-to-lower/50-rect",
                           "values":  {
                                          "mean_ms":  0.924952857,
                                          "median_ms":  0.91242,
                                          "sample_standard_deviation_ms":  0.060883054,
                                          "minimum_ms":  0.86309,
                                          "maximum_ms":  1.01,
                                          "coefficient_of_variation":  0.065822873
                                      }
                       }
                   ],
    "runs":  [
                 {
                     "id":  "warmup",
                     "label":  "warmup",
                     "started_utc":  "2026-07-25T20:08:46.5949739Z",
                     "ended_utc":  "2026-07-25T20:08:56.1176460Z",
                     "exit_code":  0,
                     "output_sha256":  "d78bfba73286c07ee00a035fcb2070345920e5898ba334ea2e96fc0d2d3299ca",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.7,
                                           "sigma_ms":  0.07664,
                                           "min_ms":  1.62,
                                           "max_ms":  1.82,
                                           "batch_size":  10,
                                           "runs":  63
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.12743,
                                           "sigma_ms":  0.00842,
                                           "min_ms":  0.12081,
                                           "max_ms":  0.14821,
                                           "batch_size":  10,
                                           "runs":  822
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.91427,
                                           "sigma_ms":  0.05371,
                                           "min_ms":  0.8495,
                                           "max_ms":  1.03,
                                           "batch_size":  10,
                                           "runs":  117
                                       }
                                   ]
                 },
                 {
                     "id":  "1",
                     "label":  "capture 1",
                     "started_utc":  "2026-07-25T20:08:56.2160897Z",
                     "ended_utc":  "2026-07-25T20:09:00.1521366Z",
                     "exit_code":  0,
                     "output_sha256":  "eddb715f0a14cf98daf7748591b3f201420de430e47e8bd13d99e0a3d059a86e",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.76,
                                           "sigma_ms":  0.12916,
                                           "min_ms":  1.59,
                                           "max_ms":  1.92,
                                           "batch_size":  10,
                                           "runs":  56
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.14443,
                                           "sigma_ms":  0.01127,
                                           "min_ms":  0.12857,
                                           "max_ms":  0.16659,
                                           "batch_size":  10,
                                           "runs":  667
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.87956,
                                           "sigma_ms":  0.03676,
                                           "min_ms":  0.85351,
                                           "max_ms":  0.95472,
                                           "batch_size":  10,
                                           "runs":  108
                                       }
                                   ]
                 },
                 {
                     "id":  "2",
                     "label":  "capture 2",
                     "started_utc":  "2026-07-25T20:09:00.1545008Z",
                     "ended_utc":  "2026-07-25T20:09:04.1451449Z",
                     "exit_code":  0,
                     "output_sha256":  "7dd53503905802fc60809f0eeb148797d2e6826526d4b80b1cd8fd61a4feabd6",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.66,
                                           "sigma_ms":  0.11303,
                                           "min_ms":  1.57,
                                           "max_ms":  1.92,
                                           "batch_size":  10,
                                           "runs":  52
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.1276,
                                           "sigma_ms":  0.00681,
                                           "min_ms":  0.12165,
                                           "max_ms":  0.14115,
                                           "batch_size":  10,
                                           "runs":  824
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.91242,
                                           "sigma_ms":  0.09736,
                                           "min_ms":  0.83921,
                                           "max_ms":  1.11,
                                           "batch_size":  10,
                                           "runs":  118
                                       }
                                   ]
                 },
                 {
                     "id":  "3",
                     "label":  "capture 3",
                     "started_utc":  "2026-07-25T20:09:04.1478724Z",
                     "ended_utc":  "2026-07-25T20:09:07.8491581Z",
                     "exit_code":  0,
                     "output_sha256":  "74cd02ce9201eec5b943c244bf3c03b35d346ddca3e58fd9bff2f500da8cabf2",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.75,
                                           "sigma_ms":  0.15573,
                                           "min_ms":  1.56,
                                           "max_ms":  2.01,
                                           "batch_size":  10,
                                           "runs":  48
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.1239,
                                           "sigma_ms":  0.00332,
                                           "min_ms":  0.11999,
                                           "max_ms":  0.12818,
                                           "batch_size":  10,
                                           "runs":  785
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.86309,
                                           "sigma_ms":  0.01584,
                                           "min_ms":  0.84439,
                                           "max_ms":  0.89689,
                                           "batch_size":  10,
                                           "runs":  94
                                       }
                                   ]
                 },
                 {
                     "id":  "4",
                     "label":  "capture 4",
                     "started_utc":  "2026-07-25T20:09:07.8521233Z",
                     "ended_utc":  "2026-07-25T20:09:11.6297503Z",
                     "exit_code":  0,
                     "output_sha256":  "f0dc3e53430c27231d48801e05e565909e73332abb20323b0050b2091d9c6610",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.59,
                                           "sigma_ms":  0.07418,
                                           "min_ms":  1.54,
                                           "max_ms":  1.74,
                                           "batch_size":  10,
                                           "runs":  50
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.13562,
                                           "sigma_ms":  0.00711,
                                           "min_ms":  0.12455,
                                           "max_ms":  0.14651,
                                           "batch_size":  10,
                                           "runs":  776
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.88456,
                                           "sigma_ms":  0.06014,
                                           "min_ms":  0.84199,
                                           "max_ms":  0.99464,
                                           "batch_size":  10,
                                           "runs":  108
                                       }
                                   ]
                 },
                 {
                     "id":  "5",
                     "label":  "capture 5",
                     "started_utc":  "2026-07-25T20:09:11.6363282Z",
                     "ended_utc":  "2026-07-25T20:09:15.3815751Z",
                     "exit_code":  0,
                     "output_sha256":  "d36d9c443bc267a8517c40441bdbb77d09c6db849de3805be85cbce51fa33265",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.67,
                                           "sigma_ms":  0.06396,
                                           "min_ms":  1.6,
                                           "max_ms":  1.78,
                                           "batch_size":  10,
                                           "runs":  53
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.12889,
                                           "sigma_ms":  0.00658,
                                           "min_ms":  0.12287,
                                           "max_ms":  0.14233,
                                           "batch_size":  10,
                                           "runs":  656
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.91504,
                                           "sigma_ms":  0.09701,
                                           "min_ms":  0.84116,
                                           "max_ms":  1.13,
                                           "batch_size":  10,
                                           "runs":  106
                                       }
                                   ]
                 },
                 {
                     "id":  "6",
                     "label":  "capture 6",
                     "started_utc":  "2026-07-25T20:09:15.3827708Z",
                     "ended_utc":  "2026-07-25T20:09:19.4774776Z",
                     "exit_code":  0,
                     "output_sha256":  "8758571725ba6817fb330fde413fad1a91fcdc6ceb68c40bee9af6b1a91275ad",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.63,
                                           "sigma_ms":  0.07142,
                                           "min_ms":  1.55,
                                           "max_ms":  1.75,
                                           "batch_size":  10,
                                           "runs":  65
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.1318,
                                           "sigma_ms":  0.01293,
                                           "min_ms":  0.12199,
                                           "max_ms":  0.16656,
                                           "batch_size":  10,
                                           "runs":  517
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  1.01,
                                           "sigma_ms":  0.17783,
                                           "min_ms":  0.84016,
                                           "max_ms":  1.28,
                                           "batch_size":  10,
                                           "runs":  113
                                       }
                                   ]
                 },
                 {
                     "id":  "7",
                     "label":  "capture 7",
                     "started_utc":  "2026-07-25T20:09:19.4792045Z",
                     "ended_utc":  "2026-07-25T20:09:23.6988624Z",
                     "exit_code":  0,
                     "output_sha256":  "03228bb11356147d641d4cee8d26816d39cffbfcdc10d6ec74c95639ae490873",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.68,
                                           "sigma_ms":  0.14613,
                                           "min_ms":  1.55,
                                           "max_ms":  1.93,
                                           "batch_size":  10,
                                           "runs":  62
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.13534,
                                           "sigma_ms":  0.01018,
                                           "min_ms":  0.12665,
                                           "max_ms":  0.15774,
                                           "batch_size":  10,
                                           "runs":  810
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  1.01,
                                           "sigma_ms":  0.14515,
                                           "min_ms":  0.85697,
                                           "max_ms":  1.3,
                                           "batch_size":  10,
                                           "runs":  112
                                       }
                                   ]
                 }
             ]
}
-->
