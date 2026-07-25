# mb-svg native release baseline

**Scope:** A native-host observation for like-for-like reproduction only. It makes no cross-target comparison, threshold, ranking, CI gate, regression conclusion, or marketing claim.

## Comparison identity

- Git commit: `967bd9102f2d3ad29efebd9eebe47fc2fa2b6634`
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
- UTC start: `2026-07-25T20:11:32.6842637Z`
- UTC end: `2026-07-25T20:11:43.5716746Z`
- Exit status: `0`
- Output SHA-256: `7ba8cae90ee33a68d684be501625ba65e69597fc9859fe358cf73f9a422e3184`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.770000000 | 0.162700000 | 1.620000000 | 2.130000000 | 10 | 60 |
| transform-composition/50-segment | 0.128490000 | 0.005350000 | 0.124640000 | 0.139630000 | 10 | 688 |
| parse-to-lower/50-rect | 0.918960000 | 0.051220000 | 0.866250000 | 1.020000000 | 10 | 112 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-canvas\canvas\stroke.mbt:319:23 ]
     │
 319 │     let (tx, ty) = if not(pl.closed) && (i == 0 || i == n - 1) {
     │                       ─┬─  
     │                        ╰─── Warning (deprecated): Use !expr instead
─────╯
Warning: [0001]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-core\math\bezier.mbt:57:4 ]
    │
 57 │ fn bezier2_derivative(p0 : Point2, p1 : Point2, p2 : Point2, t : Double) -> Vector2 {
    │    ─────────┬────────  
    │             ╰────────── Warning (unused_value): Unused function 'bezier2_derivative'
────╯
Warning: [0001]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-core\math\bezier.mbt:68:4 ]
    │
 68 │ fn bezier3_derivative(
    │    ─────────┬────────  
    │             ╰────────── Warning (unused_value): Unused function 'bezier3_derivative'
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-core\text\xml_escape.mbt:131:26 ]
     │
 131 │       let inner = entity.substring(start=2, end=entity.length() - 1)
     │                          ────┬────  
     │                              ╰────── Warning (deprecated): Use `str[:]` or `str[:].to_string()` instead
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-core\text\xml_escape.mbt:136:31 ]
     │
 136 │           let hex_str = inner.substring(start=1)
     │                               ────┬────  
     │                                   ╰────── Warning (deprecated): Use `str[:]` or `str[:].to_string()` instead
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\color.mbt:244:19 ]
     │
 244 │     result.push(p.to_string())
     │                   ────┬────  
     │                       ╰────── Warning (deprecated): Use `to_owned` to allocate an owned String from a StringView; use `Show::to_string` or format strings for display
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\length.mbt:29:16 ]
    │
 29 │       return t.substring(end=t.length() - sf.length())
    │                ────┬────  
    │                    ╰────── Warning (deprecated): Use `str[:]` or `str[:].to_string()` instead
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:13:9 ]
    │
 13 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:32:9 ]
    │
 32 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:48:9 ]
    │
 48 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:55:9 ]
    │
 55 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:70:9 ]
    │
 70 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:88:9 ]
    │
 88 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:92:9 ]
    │
 92 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:96:9 ]
    │
 96 │         other => inspect("other", content="other")
    │         ──┬──  
    │           ╰──── Warning (unused_value): Unused variable 'other'
────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:113:9 ]
     │
 113 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:117:9 ]
     │
 117 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:121:9 ]
     │
 121 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:125:9 ]
     │
 125 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:129:9 ]
     │
 129 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:148:9 ]
     │
 148 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:164:9 ]
     │
 164 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:168:9 ]
     │
 168 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:200:9 ]
     │
 200 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:215:9 ]
     │
 215 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:220:9 ]
     │
 220 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:243:9 ]
     │
 243 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:264:9 ]
     │
 264 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:279:9 ]
     │
 279 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:294:9 ]
     │
 294 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:309:9 ]
     │
 309 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:323:9 ]
     │
 323 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:345:9 ]
     │
 345 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:349:9 ]
     │
 349 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:370:9 ]
     │
 370 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:404:9 ]
     │
 404 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:422:9 ]
     │
 422 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:442:9 ]
     │
 442 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:462:9 ]
     │
 462 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:476:9 ]
     │
 476 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:490:9 ]
     │
 490 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:507:9 ]
     │
 507 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:511:9 ]
     │
 511 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0002]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:540:9 ]
     │
 540 │         other => inspect("other", content="other")
     │         ──┬──  
     │           ╰──── Warning (unused_value): Unused variable 'other'
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:591:23 ]
     │
 591 │               inspect((point.x(), point.y()), content="(32768, 0)")
     │                       ───────────┬──────────  
     │                                  ╰──────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:609:23 ]
     │
 609 │               inspect((point.x(), point.y().abs() < 1.0e-9), content="(65536, true)")
     │                       ──────────────────┬──────────────────  
     │                                         ╰──────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\lower_wbtest.mbt:630:29 ]
     │
 630 │       Err(error) => inspect(error.context(), content="Some(svg-numeric-derived)")
     │                             ───────┬───────  
     │                                    ╰───────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\parse_wbtest.mbt:77:33 ]
    │
 77 │     Ok((x, y, w, h)) => inspect((x, y, w, h), content="(10, 20, 200, 150)")
    │                                 ──────┬─────  
    │                                       ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\parse_wbtest.mbt:89:24 ]
    │
 89 │     Ok(arr) => inspect(arr, content="[1, 2, 3]")
    │                        ─┬─  
    │                         ╰─── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\parse_wbtest.mbt:113:27 ]
     │
 113 │     Ok(values) => inspect(values, content="[1, 2, 3]")
     │                           ───┬──  
     │                              ╰──── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\parse_wbtest.mbt:130:27 ]
     │
 130 │     Ok(values) => inspect(values, content="[-65536, 0, 65536]")
     │                           ───┬──  
     │                              ╰──── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\parse_wbtest.mbt:134:27 ]
     │
 134 │     Ok(bounds) => inspect(bounds, content="(-65536, -65536, 65536, 65536)")
     │                           ───┬──  
     │                              ╰──── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\path_data.mbt:274:28 ]
     │
 274 │   if v >= 97 && v <= 122 { Char::from_int(v - 32) } else { c }
     │                            ───────┬──────  
     │                                   ╰──────── Warning (deprecated): Use `Int::unsafe_to_char` instead, and use `Int::to_char` for safe conversion
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\path_data_wbtest.mbt:71:19 ]
    │
 71 │           inspect((start.x(), start.y(), end.x(), end.y()), content="(0, -10, 5, -3)")
    │                   ────────────────────┬───────────────────  
    │                                       ╰───────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\path_data_wbtest.mbt:206:19 ]
     │
 206 │           inspect((cp1.x(), cp1.y(), cp2.x(), cp2.y(), endpoint.x(), endpoint.y()), content="(17, 18, 17, 18, 19, 20)")
     │                   ────────────────────────────────┬───────────────────────────────  
     │                                                   ╰───────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\path_data_wbtest.mbt:207:19 ]
     │
 207 │           inspect((control.x(), control.y(), quad_endpoint.x(), quad_endpoint.y()), content="(25, 26, 25, 26)")
     │                   ────────────────────────────────┬───────────────────────────────  
     │                                                   ╰───────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\path_data_wbtest.mbt:221:62 ]
     │
 221 │         Some(@math.PathCommand::LineTo(endpoint)) => inspect((endpoint.x(), endpoint.y()), content="(5, 0)")
     │                                                              ──────────────┬─────────────  
     │                                                                            ╰─────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\path_data_wbtest.mbt:230:19 ]
     │
 230 │           inspect((cp1.x(), cp1.y(), cp2.x(), cp2.y(), endpoint.x(), endpoint.y()), content="(0, 0, 1, 0, 2, 0)")
     │                   ────────────────────────────────┬───────────────────────────────  
     │                                                   ╰───────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\portable_qualification_wbtest.mbt:111:9 ]
     │
 111 │         (corner_r.to_int(), corner_g.to_int(), corner_b.to_int(), corner_a.to_int()),
     │         ──────────────────────────────────────┬─────────────────────────────────────  
     │                                               ╰─────────────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\portable_qualification_wbtest.mbt:136:15 ]
     │
 136 │       inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(0, 0, 255, 255)")
     │               ────────────────────────┬───────────────────────  
     │                                       ╰───────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\portable_qualification_wbtest.mbt:151:19 ]
     │
 151 │           inspect((fill.color_a, stroke.color_a), content="(0.5, 0.5)")
     │                   ───────────────┬──────────────  
     │                                  ╰──────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\portable_qualification_wbtest.mbt:166:9 ]
     │
 166 │         (stroke_r.to_int(), stroke_g.to_int(), stroke_b.to_int(), stroke_a.to_int()),
     │         ──────────────────────────────────────┬─────────────────────────────────────  
     │                                               ╰─────────────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\portable_qualification_wbtest.mbt:192:15 ]
     │
 192 │       inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(128, 128, 255, 255)")
     │               ────────────────────────┬───────────────────────  
     │                                       ╰───────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\portable_qualification_wbtest.mbt:207:19 ]
     │
 207 │           inspect((group, element), content="(0.5, 0.5)")
     │                   ────────┬───────  
     │                           ╰───────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\portable_qualification_wbtest.mbt:250:9 ]
     │
 250 │ ╭─▶         (
     ┆ ┆   
 255 │ ├─▶         ),
     │ │                
     │ ╰──────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\portable_qualification_wbtest.mbt:336:9 ]
     │
 336 │         (corner_r.to_int(), corner_g.to_int(), corner_b.to_int(), corner_a.to_int()),
     │         ──────────────────────────────────────┬─────────────────────────────────────  
     │                                               ╰─────────────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0004]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene.mbt:100:8 ]
     │
 100 │ struct PaintContext {
     │        ──────┬─────  
     │              ╰─────── Warning (missing_priv): The type 'PaintContext' does not occur in public signature of current package, consider marking it as `priv`.
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:19:15 ]
    │
 19 │       inspect(root.height, content="Some(20)")
    │               ─────┬─────  
    │                    ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:21:39 ]
    │
 21 │         Some((x, y, w, h)) => inspect((x, y, w, h), content="(0, 0, 100, 50)")
    │                                       ──────┬─────  
    │                                             ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:43:27 ]
    │
 43 │                   inspect((x, y, w, h), content="(1, 2, 3, 4)")
    │                           ──────┬─────  
    │                                 ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:62:19 ]
    │
 62 │           inspect((x, y, w, h, rx, ry), content="(1, 2, 3, 4, 0, 0)")
    │                   ──────────┬─────────  
    │                             ╰─────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:67:19 ]
    │
 67 │           inspect(paint.stroke, content="None")
    │                   ──────┬─────  
    │                         ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:83:19 ]
    │
 83 │           inspect(paint.fill, content="None")
    │                   ─────┬────  
    │                        ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:85:40 ]
    │
 85 │             Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
    │                                        ────┬────  
    │                                            ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:122:23 ]
     │
 122 │               inspect((p2.x(), p2.y()), content="(10, 10)")
     │                       ────────┬───────  
     │                               ╰───────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:154:23 ]
     │
 154 │               inspect((x, y, width, height), content="(1, 2, 3, 4)")
     │                       ──────────┬──────────  
     │                                 ╰──────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:212:44 ]
     │
 212 │                 Some((r, g, b)) => inspect((r, g, b), content="(1, 0, 0)")
     │                                            ────┬────  
     │                                                ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:234:44 ]
     │
 234 │                 Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
     │                                            ────┬────  
     │                                                ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:282:44 ]
     │
 282 │                 Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
     │                                            ────┬────  
     │                                                ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:302:54 ]
     │
 302 │             Rect(paint, _, _, _, _, _, _) => inspect(paint.fill, content="None")
     │                                                      ─────┬────  
     │                                                           ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:350:44 ]
     │
 350 │                 Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
     │                                            ────┬────  
     │                                                ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:372:15 ]
     │
 372 │       inspect(root.view_box, content="Some((0, 0, 65536, 65536))")
     │               ──────┬──────  
     │                     ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:376:19 ]
     │
 376 │           inspect((x, y, width, height), content="(-65536, -65536, 65536, 65536)")
     │                   ──────────┬──────────  
     │                             ╰──────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:377:19 ]
     │
 377 │           inspect(paint.stroke_dash, content="[1, 65536]")
     │                   ────────┬────────  
     │                           ╰────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:378:19 ]
     │
 378 │           inspect((paint.fill_opacity, paint.stroke_opacity, paint.stroke_width, paint.stroke_miterlimit, paint.stroke_dashoffset), content="(65536, 65536, 65536, 65536, 65536)")
     │                   ────────────────────────────────────────────────────────┬───────────────────────────────────────────────────────  
     │                                                                           ╰───────────────────────────────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:426:15 ]
     │
 426 │       inspect(root.height, content="None")
     │               ─────┬─────  
     │                    ╰─────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:430:54 ]
     │
 430 │             Rect(paint, _, _, _, _, _, _) => inspect(paint.fill, content="Some((0, 0, 1))")
     │                                                      ─────┬────  
     │                                                           ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:461:29 ]
     │
 461 │       Err(error) => inspect(error.operation(), content="Some(svg)")
     │                             ────────┬────────  
     │                                     ╰────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\scene_wbtest.mbt:467:65 ]
     │
 467 │         Group(_, _, [Rect(paint, _, _, _, _, _, _)]) => inspect(paint.fill, content="Some((0, 0, 1))")
     │                                                                 ─────┬────  
     │                                                                      ╰────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:40:22 ]
    │
 40 │     Ok(m) => inspect((tx(m), ty(m)), content="(5, 0)")
    │                      ───────┬──────  
    │                             ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:52:22 ]
    │
 52 │     Ok(m) => inspect((m.a(), m.d()), content="(2, 3)")
    │                      ───────┬──────  
    │                             ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:60:22 ]
    │
 60 │     Ok(m) => inspect((m.a(), m.b(), m.c(), m.d(), tx(m), ty(m)), content="(1, 2, 3, 4, 5, 6)")
    │                      ─────────────────────┬────────────────────  
    │                                           ╰────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
    ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:76:15 ]
    │
 76 │       inspect((p.x(), p.y()), content="(12, 0)")
    │               ───────┬──────  
    │                      ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:109:15 ]
     │
 109 │       inspect((p.x().abs() < 1.0e-9, (p.y() - 1.0).abs() < 1.0e-9), content="(true, true)")
     │               ──────────────────────────┬─────────────────────────  
     │                                         ╰─────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:125:15 ]
     │
 125 │       inspect(((q.x() - 1.0).abs() < 1.0e-9, (q.y() - 2.0).abs() < 1.0e-9), content="(true, true)")
     │               ──────────────────────────────┬─────────────────────────────  
     │                                             ╰─────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:164:22 ]
     │
 164 │     Ok(m) => inspect((m.a(), m.d(), tx(m), ty(m)), content="(1, 1, 65536, -65536)")
     │                      ──────────────┬─────────────  
     │                                    ╰─────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:187:15 ]
     │
 187 │       inspect((point.x().abs() < 1.0e-9, (point.y() - 1.0).abs() < 1.0e-9), content="(true, true)")
     │               ──────────────────────────────┬─────────────────────────────  
     │                                             ╰─────────────────────────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:203:15 ]
     │
 203 │       inspect((point.x(), point.y()), content="(65536, 0)")
     │               ───────────┬──────────  
     │                          ╰──────────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:239:29 ]
     │
 239 │       Err(error) => inspect(error.context(), content="Some(svg-numeric-derived)")
     │                             ───────┬───────  
     │                                    ╰───────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
Warning: [0020]
     ╭─[ D:\source\moonbit-foundation-phase94-02-capture-967bd91\modules\mb-svg\svg\transform_wbtest.mbt:243:22 ]
     │
 243 │     Ok(m) => inspect((m.a(), m.d()), content="(0, 0)")
     │                      ───────┬──────  
     │                             ╰──────── Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md
─────╯
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.77 ms ± 162.70 µs     1.62 ms …   2.13 ms  in 10 ×     60 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 128.49 µs ±   5.35 µs   124.64 µs … 139.63 µs  in 10 ×    688 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 918.96 µs ±  51.22 µs   866.25 µs …   1.02 ms  in 10 ×    112 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 1
- UTC start: `2026-07-25T20:11:43.6338213Z`
- UTC end: `2026-07-25T20:11:47.7926826Z`
- Exit status: `0`
- Output SHA-256: `77f886459b74e3c7cc60e71204f99fc192174d8ebf94337ac5e22b254f3cee0a`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.760000000 | 0.156830000 | 1.650000000 | 2.160000000 | 10 | 61 |
| transform-composition/50-segment | 0.132130000 | 0.007650000 | 0.121880000 | 0.148130000 | 10 | 725 |
| parse-to-lower/50-rect | 0.956440000 | 0.127010000 | 0.859900000 | 1.170000000 | 10 | 118 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.76 ms ± 156.83 µs     1.65 ms …   2.16 ms  in 10 ×     61 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 132.13 µs ±   7.65 µs   121.88 µs … 148.13 µs  in 10 ×    725 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 956.44 µs ± 127.01 µs   859.90 µs …   1.17 ms  in 10 ×    118 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 2
- UTC start: `2026-07-25T20:11:47.7944659Z`
- UTC end: `2026-07-25T20:11:51.6058253Z`
- Exit status: `0`
- Output SHA-256: `25d50fa40dea28014b57af4237375988a5a0b62949db7f95004e9ea343ff3ace`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.630000000 | 0.140980000 | 1.550000000 | 1.950000000 | 10 | 52 |
| transform-composition/50-segment | 0.132780000 | 0.010190000 | 0.119720000 | 0.153120000 | 10 | 803 |
| parse-to-lower/50-rect | 0.895800000 | 0.082960000 | 0.844980000 | 1.100000000 | 10 | 102 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.63 ms ± 140.98 µs     1.55 ms …   1.95 ms  in 10 ×     52 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 132.78 µs ±  10.19 µs   119.72 µs … 153.12 µs  in 10 ×    803 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 895.80 µs ±  82.96 µs   844.98 µs …   1.10 ms  in 10 ×    102 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 3
- UTC start: `2026-07-25T20:11:51.6081694Z`
- UTC end: `2026-07-25T20:11:55.7063290Z`
- Exit status: `0`
- Output SHA-256: `b3e543bef9028220aa6385ea2bb5a2344553475dd5ea2cac4e00894fa238d224`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.650000000 | 0.067370000 | 1.570000000 | 1.740000000 | 10 | 63 |
| transform-composition/50-segment | 0.136700000 | 0.009290000 | 0.130400000 | 0.152420000 | 10 | 736 |
| parse-to-lower/50-rect | 0.929030000 | 0.049310000 | 0.869620000 | 1.010000000 | 10 | 117 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.65 ms ±  67.37 µs     1.57 ms …   1.74 ms  in 10 ×     63 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 136.70 µs ±   9.29 µs   130.40 µs … 152.42 µs  in 10 ×    736 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 929.03 µs ±  49.31 µs   869.62 µs …   1.01 ms  in 10 ×    117 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 4
- UTC start: `2026-07-25T20:11:55.7086567Z`
- UTC end: `2026-07-25T20:11:59.9728775Z`
- Exit status: `0`
- Output SHA-256: `3bf22da9cd5ab25bebd0a473c71d4f951f0f4f8fa30322ec9785d006fb276028`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.790000000 | 0.127390000 | 1.610000000 | 1.980000000 | 10 | 63 |
| transform-composition/50-segment | 0.128540000 | 0.006320000 | 0.121300000 | 0.141140000 | 10 | 825 |
| parse-to-lower/50-rect | 0.960050000 | 0.162320000 | 0.850120000 | 1.300000000 | 10 | 119 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.79 ms ± 127.39 µs     1.61 ms …   1.98 ms  in 10 ×     63 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 128.54 µs ±   6.32 µs   121.30 µs … 141.14 µs  in 10 ×    825 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 960.05 µs ± 162.32 µs   850.12 µs …   1.30 ms  in 10 ×    119 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 5
- UTC start: `2026-07-25T20:11:59.9798451Z`
- UTC end: `2026-07-25T20:12:03.8949789Z`
- Exit status: `0`
- Output SHA-256: `84043a9caec404fb96afd9d5b33e9987610a0edb3f1f4bf9f12cfa4873930473`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.840000000 | 0.216600000 | 1.570000000 | 2.240000000 | 10 | 52 |
| transform-composition/50-segment | 0.135580000 | 0.015390000 | 0.123550000 | 0.178170000 | 10 | 727 |
| parse-to-lower/50-rect | 0.898310000 | 0.062410000 | 0.843280000 | 1.030000000 | 10 | 109 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.84 ms ± 216.60 µs     1.57 ms …   2.24 ms  in 10 ×     52 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 135.58 µs ±  15.39 µs   123.55 µs … 178.17 µs  in 10 ×    727 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 898.31 µs ±  62.41 µs   843.28 µs …   1.03 ms  in 10 ×    109 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 6
- UTC start: `2026-07-25T20:12:03.8961655Z`
- UTC end: `2026-07-25T20:12:07.7348248Z`
- Exit status: `0`
- Output SHA-256: `b474880d12f55f8874a880e4777b8a9410878da7f7e8e5c587d96d5fc76e6cb8`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.750000000 | 0.230670000 | 1.570000000 | 2.230000000 | 10 | 56 |
| transform-composition/50-segment | 0.129370000 | 0.010800000 | 0.122050000 | 0.151400000 | 10 | 600 |
| parse-to-lower/50-rect | 0.964400000 | 0.183950000 | 0.855800000 | 1.330000000 | 10 | 110 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.75 ms ± 230.67 µs     1.57 ms …   2.23 ms  in 10 ×     56 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 129.37 µs ±  10.80 µs   122.05 µs … 151.40 µs  in 10 ×    600 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 964.40 µs ± 183.95 µs   855.80 µs …   1.33 ms  in 10 ×    110 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

### Capture 7
- UTC start: `2026-07-25T20:12:07.7377571Z`
- UTC end: `2026-07-25T20:12:11.4775773Z`
- Exit status: `0`
- Output SHA-256: `ce85905fde08271155e6717d91d4534852a586c66544f25869711a713c296479`
- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`

| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.760000000 | 0.202920000 | 1.550000000 | 2.110000000 | 10 | 55 |
| transform-composition/50-segment | 0.131060000 | 0.005800000 | 0.124590000 | 0.142530000 | 10 | 543 |
| parse-to-lower/50-rect | 0.937120000 | 0.085300000 | 0.886180000 | 1.130000000 | 10 | 105 |

<details>
<summary>Complete normalized UTF-8 merged stdout/stderr</summary>

```text
[tchivs/mb-svg] bench svg/svg_bench.mbt:64 ("bench path-parse/1000-line-to") ok
time (mean ± σ)         range (min … max) 
   1.76 ms ± 202.92 µs     1.55 ms …   2.11 ms  in 10 ×     55 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:89 ("bench transform-composition/50-segment") ok
time (mean ± σ)         range (min … max) 
 131.06 µs ±   5.80 µs   124.59 µs … 142.53 µs  in 10 ×    543 runs
[tchivs/mb-svg] bench svg/svg_bench.mbt:121 ("bench parse-to-lower/50-rect") ok
time (mean ± σ)         range (min … max) 
 937.12 µs ±  85.30 µs   886.18 µs …   1.13 ms  in 10 ×    105 runs
Total tests: 3, passed: 3, failed: 0.
```
</details>

## Native-host-specific seven-capture summary

| Workload | Arithmetic mean (ms) | Median (ms) | Sample standard deviation (ms) | Minimum (ms) | Maximum (ms) | Coefficient of variation |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| path-parse/1000-line-to | 1.740000000 | 1.760000000 | 0.074833148 | 1.630000000 | 1.840000000 | 0.043007556 |
| transform-composition/50-segment | 0.132308571 | 0.132130000 | 0.003017650 | 0.128540000 | 0.136700000 | 0.022807672 |
| parse-to-lower/50-rect | 0.934450000 | 0.937120000 | 0.028496637 | 0.895800000 | 0.964400000 | 0.030495625 |

## Read-only audit

Run `powershell.exe -NoProfile -File scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 -Audit` or `pwsh -NoProfile -File scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 -Audit` from a clean checkout. Audit reads this Markdown and current fixed inputs only; it does not run MoonBit, write Markdown, or make a timing decision.

<!-- SVG-BASELINE-DATA
{
    "schema_version":  1,
    "claim":  "native-host observation only; no threshold, ranking, regression conclusion, CI gate, cross-target comparison, or performance claim",
    "identity":  {
                     "git_commit":  "967bd9102f2d3ad29efebd9eebe47fc2fa2b6634",
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
                                             "value":  "\u7535\u6E90\u65B9\u6848 GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (\u5E73\u8861)",
                                             "attempted":  "powercfg /GETACTIVESCHEME"
                                         }
             },
    "aggregates":  [
                       {
                           "name":  "path-parse/1000-line-to",
                           "values":  {
                                          "mean_ms":  1.74,
                                          "median_ms":  1.76,
                                          "sample_standard_deviation_ms":  0.074833148,
                                          "minimum_ms":  1.63,
                                          "maximum_ms":  1.84,
                                          "coefficient_of_variation":  0.043007556
                                      }
                       },
                       {
                           "name":  "transform-composition/50-segment",
                           "values":  {
                                          "mean_ms":  0.132308571,
                                          "median_ms":  0.13213,
                                          "sample_standard_deviation_ms":  0.00301765,
                                          "minimum_ms":  0.12854,
                                          "maximum_ms":  0.1367,
                                          "coefficient_of_variation":  0.022807672
                                      }
                       },
                       {
                           "name":  "parse-to-lower/50-rect",
                           "values":  {
                                          "mean_ms":  0.93445,
                                          "median_ms":  0.93712,
                                          "sample_standard_deviation_ms":  0.028496637,
                                          "minimum_ms":  0.8958,
                                          "maximum_ms":  0.9644,
                                          "coefficient_of_variation":  0.030495625
                                      }
                       }
                   ],
    "runs":  [
                 {
                     "id":  "warmup",
                     "label":  "warmup",
                     "started_utc":  "2026-07-25T20:11:32.6842637Z",
                     "ended_utc":  "2026-07-25T20:11:43.5716746Z",
                     "exit_code":  0,
                     "output_sha256":  "7ba8cae90ee33a68d684be501625ba65e69597fc9859fe358cf73f9a422e3184",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.77,
                                           "sigma_ms":  0.1627,
                                           "min_ms":  1.62,
                                           "max_ms":  2.13,
                                           "batch_size":  10,
                                           "runs":  60
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.12849,
                                           "sigma_ms":  0.00535,
                                           "min_ms":  0.12464,
                                           "max_ms":  0.13963,
                                           "batch_size":  10,
                                           "runs":  688
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.91896,
                                           "sigma_ms":  0.05122,
                                           "min_ms":  0.86625,
                                           "max_ms":  1.02,
                                           "batch_size":  10,
                                           "runs":  112
                                       }
                                   ]
                 },
                 {
                     "id":  "1",
                     "label":  "capture 1",
                     "started_utc":  "2026-07-25T20:11:43.6338213Z",
                     "ended_utc":  "2026-07-25T20:11:47.7926826Z",
                     "exit_code":  0,
                     "output_sha256":  "77f886459b74e3c7cc60e71204f99fc192174d8ebf94337ac5e22b254f3cee0a",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.76,
                                           "sigma_ms":  0.15683,
                                           "min_ms":  1.65,
                                           "max_ms":  2.16,
                                           "batch_size":  10,
                                           "runs":  61
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.13213,
                                           "sigma_ms":  0.00765,
                                           "min_ms":  0.12188,
                                           "max_ms":  0.14813,
                                           "batch_size":  10,
                                           "runs":  725
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.95644,
                                           "sigma_ms":  0.12701,
                                           "min_ms":  0.8599,
                                           "max_ms":  1.17,
                                           "batch_size":  10,
                                           "runs":  118
                                       }
                                   ]
                 },
                 {
                     "id":  "2",
                     "label":  "capture 2",
                     "started_utc":  "2026-07-25T20:11:47.7944659Z",
                     "ended_utc":  "2026-07-25T20:11:51.6058253Z",
                     "exit_code":  0,
                     "output_sha256":  "25d50fa40dea28014b57af4237375988a5a0b62949db7f95004e9ea343ff3ace",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.63,
                                           "sigma_ms":  0.14098,
                                           "min_ms":  1.55,
                                           "max_ms":  1.95,
                                           "batch_size":  10,
                                           "runs":  52
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.13278,
                                           "sigma_ms":  0.01019,
                                           "min_ms":  0.11972,
                                           "max_ms":  0.15312,
                                           "batch_size":  10,
                                           "runs":  803
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.8958,
                                           "sigma_ms":  0.08296,
                                           "min_ms":  0.84498,
                                           "max_ms":  1.1,
                                           "batch_size":  10,
                                           "runs":  102
                                       }
                                   ]
                 },
                 {
                     "id":  "3",
                     "label":  "capture 3",
                     "started_utc":  "2026-07-25T20:11:51.6081694Z",
                     "ended_utc":  "2026-07-25T20:11:55.7063290Z",
                     "exit_code":  0,
                     "output_sha256":  "b3e543bef9028220aa6385ea2bb5a2344553475dd5ea2cac4e00894fa238d224",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.65,
                                           "sigma_ms":  0.06737,
                                           "min_ms":  1.57,
                                           "max_ms":  1.74,
                                           "batch_size":  10,
                                           "runs":  63
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.1367,
                                           "sigma_ms":  0.00929,
                                           "min_ms":  0.1304,
                                           "max_ms":  0.15242,
                                           "batch_size":  10,
                                           "runs":  736
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.92903,
                                           "sigma_ms":  0.04931,
                                           "min_ms":  0.86962,
                                           "max_ms":  1.01,
                                           "batch_size":  10,
                                           "runs":  117
                                       }
                                   ]
                 },
                 {
                     "id":  "4",
                     "label":  "capture 4",
                     "started_utc":  "2026-07-25T20:11:55.7086567Z",
                     "ended_utc":  "2026-07-25T20:11:59.9728775Z",
                     "exit_code":  0,
                     "output_sha256":  "3bf22da9cd5ab25bebd0a473c71d4f951f0f4f8fa30322ec9785d006fb276028",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.79,
                                           "sigma_ms":  0.12739,
                                           "min_ms":  1.61,
                                           "max_ms":  1.98,
                                           "batch_size":  10,
                                           "runs":  63
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.12854,
                                           "sigma_ms":  0.00632,
                                           "min_ms":  0.1213,
                                           "max_ms":  0.14114,
                                           "batch_size":  10,
                                           "runs":  825
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.96005,
                                           "sigma_ms":  0.16232,
                                           "min_ms":  0.85012,
                                           "max_ms":  1.3,
                                           "batch_size":  10,
                                           "runs":  119
                                       }
                                   ]
                 },
                 {
                     "id":  "5",
                     "label":  "capture 5",
                     "started_utc":  "2026-07-25T20:11:59.9798451Z",
                     "ended_utc":  "2026-07-25T20:12:03.8949789Z",
                     "exit_code":  0,
                     "output_sha256":  "84043a9caec404fb96afd9d5b33e9987610a0edb3f1f4bf9f12cfa4873930473",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.84,
                                           "sigma_ms":  0.2166,
                                           "min_ms":  1.57,
                                           "max_ms":  2.24,
                                           "batch_size":  10,
                                           "runs":  52
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.13558,
                                           "sigma_ms":  0.01539,
                                           "min_ms":  0.12355,
                                           "max_ms":  0.17817,
                                           "batch_size":  10,
                                           "runs":  727
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.89831,
                                           "sigma_ms":  0.06241,
                                           "min_ms":  0.84328,
                                           "max_ms":  1.03,
                                           "batch_size":  10,
                                           "runs":  109
                                       }
                                   ]
                 },
                 {
                     "id":  "6",
                     "label":  "capture 6",
                     "started_utc":  "2026-07-25T20:12:03.8961655Z",
                     "ended_utc":  "2026-07-25T20:12:07.7348248Z",
                     "exit_code":  0,
                     "output_sha256":  "b474880d12f55f8874a880e4777b8a9410878da7f7e8e5c587d96d5fc76e6cb8",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.75,
                                           "sigma_ms":  0.23067,
                                           "min_ms":  1.57,
                                           "max_ms":  2.23,
                                           "batch_size":  10,
                                           "runs":  56
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.12937,
                                           "sigma_ms":  0.0108,
                                           "min_ms":  0.12205,
                                           "max_ms":  0.1514,
                                           "batch_size":  10,
                                           "runs":  600
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.9644,
                                           "sigma_ms":  0.18395,
                                           "min_ms":  0.8558,
                                           "max_ms":  1.33,
                                           "batch_size":  10,
                                           "runs":  110
                                       }
                                   ]
                 },
                 {
                     "id":  "7",
                     "label":  "capture 7",
                     "started_utc":  "2026-07-25T20:12:07.7377571Z",
                     "ended_utc":  "2026-07-25T20:12:11.4775773Z",
                     "exit_code":  0,
                     "output_sha256":  "ce85905fde08271155e6717d91d4534852a586c66544f25869711a713c296479",
                     "summaries":  [
                                       {
                                           "name":  "path-parse/1000-line-to",
                                           "mean_ms":  1.76,
                                           "sigma_ms":  0.20292,
                                           "min_ms":  1.55,
                                           "max_ms":  2.11,
                                           "batch_size":  10,
                                           "runs":  55
                                       },
                                       {
                                           "name":  "transform-composition/50-segment",
                                           "mean_ms":  0.13106,
                                           "sigma_ms":  0.0058,
                                           "min_ms":  0.12459,
                                           "max_ms":  0.14253,
                                           "batch_size":  10,
                                           "runs":  543
                                       },
                                       {
                                           "name":  "parse-to-lower/50-rect",
                                           "mean_ms":  0.93712,
                                           "sigma_ms":  0.0853,
                                           "min_ms":  0.88618,
                                           "max_ms":  1.13,
                                           "batch_size":  10,
                                           "runs":  105
                                       }
                                   ]
                 }
             ]
}
-->
