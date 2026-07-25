# Phase 94: SVG Benchmark Evidence - Research

**Researched:** 2026-07-26
**Domain:** MoonBit `@bench.T` correctness-gated SVG benchmarks and native-release evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Workload correctness
- **D-01:** Keep exactly three accurately named workload families: path parse, transform composition, and parse-to-lower. Each gets deterministic pre-benchmark assertions for command/count, affine, or drawing-operation facts, so timing can never mask a broken workload. — **Reversibility:** costly — workload identity and correctness digest form the baseline comparison contract.
- **D-02:** Use existing MoonBit `*_bench.mbt` / `@bench.T` conventions and test-local deterministic builders; do not add a benchmark framework or external package.

### Target policy
- **D-03:** Build and run correctness gates on js, wasm, wasm-gc, and native. Record no cross-target timing table, ranking, or claimed performance comparison; only native release captures are baseline evidence.

### Native baseline record
- **D-04:** Store a documented native release baseline with exact command, corpus + correctness digests, MoonBit toolchain and host facts, warmup protocol, and seven individual captures plus summary. Capture the environment honestly; a missing host fact must be marked unavailable rather than invented. — **Reversibility:** costly — the baseline becomes the durable like-for-like comparison point.

### the agent's Discretion
Choose the benchmark document location, command formatting, digest procedure, host facts available on the current machine, and stable correctness assertions, provided the three workloads remain fixed and the record remains reproducible.

### Deferred Ideas (OUT OF SCOPE)

None — performance thresholds, host fleet comparison, CI performance gating, native acceleration, and new SVG functionality are outside v0.30.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SVGPR-04 | Maintainers can run three accurately named, correctness-gated `mb-svg` workloads and compare a documented native release baseline without treating cross-target timings as comparable performance. | Fixed three-workload gates, four-target execution commands, and a native-only seven-capture record are specified below. [VERIFIED: local repository + MoonBit CLI] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Prefer the codebase knowledge-graph tools for code discovery; this environment exposes no graph MCP tool and no project graph file, so the source-file fallback was used. [VERIFIED: AGENTS.md + `.planning/graphs/graph.json` absence]
- Keep core algorithms and shared data models in MoonBit; native is the primary target, with portability enforced through capability boundaries and conformance tests. [VERIFIED: AGENTS.md]
- Preserve public-package modularity, documented compatibility rules, deterministic GUI-free automation, and evidence-based performance claims. [VERIFIED: AGENTS.md]
- Use the established GSD workflow for repository changes; this research artifact is the requested Phase 94 planning output and product code was not changed. [VERIFIED: AGENTS.md + local git status]

## Summary

Phase 94 should evolve the existing `modules/mb-svg/svg/svg_bench.mbt` into three self-validating MoonBit benchmark tests: `path-parse/1000-line-to`, `transform-composition/50-segment`, and `parse-to-lower/50-rect`. Each deterministic corpus is constructed before `b.bench`; its invariant is evaluated once before the timed closure; the closure then executes precisely the named public operation and sinks the result with `b.keep`. This follows the currently installed MoonBit benchmark interface, whose runner chooses an iteration count and prints mean, standard deviation, range, batch count, and run count. [CITED: https://docs.moonbitlang.com/en/latest/language/benchmarks.html] [VERIFIED: local `modules/mb-svg/svg/svg_bench.mbt` + `moon bench`]

The portable qualification command must remain a functional pass/fail check even though the MoonBit runner prints timings for every target. `moon bench modules/mb-svg/svg --target all --frozen` expands to wasm, wasm-gc, js, and native; on this machine it ran all three workloads successfully on each target. Do not copy those printed numbers into the baseline or a comparison table. The only retained performance evidence is seven separate native release invocations after one untimed native-release warmup. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] [VERIFIED: local MoonBit CLI execution]

**Primary recommendation:** Keep the benchmark source local to `mb-svg`, add pre-timing `abort`-based correctness guards and the explicit `moonbitlang/core/bench` import, and publish one Markdown baseline at `docs/benchmarks/mb-svg-native-release-baseline.md` that preserves seven complete native-release command outputs plus the immutable provenance needed for like-for-like comparison. [VERIFIED: local benchmark source + local MoonBit warnings]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Deterministic corpus construction and pre-timing validation | API / Backend | — | The MoonBit benchmark test owns its input and semantic gate, preventing a benchmark runner from timing a broken workload. [VERIFIED: local `svg_bench.mbt` + `ppm_bench.mbt`] |
| SVG path/transform/parse-to-lower execution | API / Backend | — | `mb-svg` exposes `parse_path_data`, `parse_transform`, `parse_svg`, and `lower_to_drawing_list` as MoonBit library operations. [VERIFIED: local `path_data.mbt`, `transform.mbt`, and `lower.mbt`] |
| Portable runnable qualification | API / Backend | Build tooling | `moon bench --target all` builds and runs the package per selected target; the benchmark gates are executable tests. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] [VERIFIED: local MoonBit CLI execution] |
| Native release baseline evidence | Build tooling | Documentation | The command runner emits timing summaries; a versioned Markdown document owns the human-reviewable command, provenance, captures, and comparison rule. [VERIFIED: local `benchmarks/ppm/phase-11-resize-composite-baseline.md`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| MoonBit `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Compile, run, and record benchmark identity. | These exact toolchain identities are the repository’s canonical development pin. [VERIFIED: `policy/foundation.json` + local `moon --version`] |
| `moonbitlang/core/bench` | bundled with pinned MoonBit toolchain | Provides `@bench.T`, `bench`, and `keep`; add it as an explicit package import. | The current benchmark uses `@bench.T`; the compiler warns that implicit core-package use is deprecated. [CITED: https://docs.moonbitlang.com/en/latest/language/benchmarks.html] [VERIFIED: local `moon bench` output] |
| SHA-256 (`[Security.Cryptography.SHA256]::Create().ComputeHash()`) | .NET API present in Windows PowerShell 5.1 and PowerShell 7 | Identifies the benchmark source, fixture corpus, and complete command-output capture. | Render the returned bytes through `[BitConverter]::ToString(...).Replace('-', '').ToLowerInvariant()`; this exact route was verified on local Windows PowerShell 5.1, where `ToHexString` and `SHA256.HashData` are absent. [VERIFIED: local Windows PowerShell 5.1 probe] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `moon test` | pinned MoonBit toolchain | Runs the package’s ordinary regression tests on every declared portable target. | Run after benchmark changes as a separate regression check; it is not a substitute for executing the benchmark-local gates. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] [VERIFIED: local `moon test modules/mb-svg/svg --target all --frozen`] |
| PowerShell CIM cmdlets | installed Windows PowerShell capability | Collects OS, CPU, logical-core, and physical-memory facts for the baseline. | Use only facts returned by the capture host; represent unavailable facts literally as `unavailable`. [VERIFIED: local host-fact probe + existing PPM harness] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Built-in `@bench.T` tests | External benchmark framework | Rejected by locked D-02; it would add a package and a second execution convention without improving the required evidence. [VERIFIED: 94-CONTEXT.md] |
| Versioned Markdown baseline | PPM’s JSON schema/harness | Do not reuse the PPM schema: it hard-codes eight workloads and threshold-based catastrophic-regression policy, both outside Phase 94 scope. [VERIFIED: `release/qualification/benchmark-schema.json` + `scripts/benchmarks/Invoke-PpmBenchmarks.ps1`] |
| Native-only retained captures | Cross-target comparison table | Rejected by locked D-03 and SVGPR-04 because target runtime and code-generation differences make those raw values non-comparable performance evidence. [VERIFIED: 94-CONTEXT.md + `.planning/REQUIREMENTS.md`] |

**Installation:** No package installation. `moonbitlang/core/bench` is provided by the pinned toolchain. [VERIFIED: local toolchain policy]

## Package Legitimacy Audit

No external package is installed in this phase; the package-legitimacy gate is not applicable. [VERIFIED: 94-CONTEXT.md D-02]

## Architecture Patterns

### System Architecture Diagram

```text
Deterministic local builders
        |
        v
pre-timing correctness gate ----failure----> benchmark command fails; no timing evidence
        |
        v
`b.bench(fn() { b.keep(public_operation(corpus)) })`
        |
        +--> `moon bench ... --target all --frozen`
        |        |
        |        +--> wasm / wasm-gc / js / native: runnable qualification only
        |
        +--> `moon bench ... --release --target native --frozen`
                 |
                 v
         warmup (discarded) -> seven separately captured outputs -> Markdown baseline
                 |                                              |
                 +---------------- provenance + SHA-256 -------+
```

The benchmark runner is a tool boundary, not the correctness authority: every workload asserts its expected semantic facts before timing begins. [VERIFIED: local `benchmarks/ppm/ppm_bench.mbt` pattern]

### Recommended Project Structure

```text
modules/mb-svg/svg/
├── moon.pkg                              # explicit `moonbitlang/core/bench` import
└── svg_bench.mbt                         # builders, pre-timing guards, and three workloads
docs/benchmarks/
└── mb-svg-native-release-baseline.md     # immutable native release evidence
fixtures/svg/
└── cases.json                            # existing SVG corpus provenance/digest reference
```

### Pattern 1: Build once, verify once, time only the named operation

**What:** Construct a fixed input outside `b.bench`, execute a deterministic assertion against the same public API once, then place only the measured operation inside the closure. [CITED: https://docs.moonbitlang.com/en/latest/language/benchmarks.html] [VERIFIED: local `benchmarks/ppm/ppm_bench.mbt`]

**When to use:** Every Phase 94 workload. [VERIFIED: 94-CONTEXT.md D-01]

**Example:**

```moonbit
// Source: local `benchmarks/ppm/ppm_bench.mbt` guard pattern
fn require_benchmark(condition : Bool, label : String) -> Unit {
  if !condition { abort("benchmark correctness failed: \{label}") }
}

test "bench path-parse/1000-line-to" (b : @bench.T) {
  let corpus = build_path_parse_corpus()
  match parse_path_data(corpus) {
    Ok(path) => require_benchmark(path.to_path2().length() == 1001, "path-command-count")
    Err(_) => abort("benchmark correctness failed: path-parse")
  }
  b.bench(fn() { b.keep(parse_path_data(corpus)) })
}
```

### Correctness gates for the fixed workloads

| Workload | Corpus ownership | Required pre-timing facts | Timed closure | Corpus digest | Correctness digest |
|----------|------------------|---------------------------|---------------|---------------|--------------------|
| `path-parse/1000-line-to` | Existing deterministic `M0 0` plus 1,000 generated implicit `L` commands. [VERIFIED: local `svg_bench.mbt`] | Require `Ok`; require exactly 1,001 path commands; require command 0 is `MoveTo(0,0)` and command 1,000 is `LineTo(99,99)`. [VERIFIED: builder arithmetic + local `path_data_wbtest.mbt` API] | `parse_path_data(corpus)` sunk with `b.keep`. [VERIFIED: local `svg_bench.mbt`] | `e97e1c8a8e29fdb3e84c309e421de34d41cbab7583cf1e88cf94a67af51eb259`. [VERIFIED: local deterministic UTF-8 calculation] | `0c7d3af32d324a136215c1158c4aab127d11e160f4b9239991114a0303762f22`. [VERIFIED: local canonical UTF-8 calculation] |
| `transform-composition/50-segment` | **Required fixed corpus:** 10 concatenated repeats of exactly `translate(1,1) scale(2) rotate(15) skewX(5) skewY(3)`—five transform functions per repeat. The pre-phase source includes an extra `matrix(...)` call (60 functions), so it must not be retained under the `50-segment` identity. [VERIFIED: local `svg_bench.mbt` + locked workload name] | Require `Ok`; require all six finite/in-envelope components and probe `(1.25,-2.5)` to equal the frozen values below within `1.0e-9`; never derive the expected values by reparsing at runtime. [VERIFIED: local `transform.mbt`, `affine.mbt`, and deterministic native-equivalent calculation] | `parse_transform(corpus)` sunk with `b.keep`. [VERIFIED: local `svg_bench.mbt`] | `c0ed3307e143d7cb20fd90e531e6208a14bbe2e42ce2816a0579d04cbd320840`. [VERIFIED: local deterministic UTF-8 calculation] | `ec32349185e19b24757e391c72ac5fa8709f889847a0035b7257fc3e0ba483ff`. [VERIFIED: local canonical UTF-8 calculation] |
| `parse-to-lower/50-rect` | Existing deterministic `<svg>` with 50 generated red unit rectangles. [VERIFIED: local `svg_bench.mbt`] | Require `parse_svg` yields `Ok`; require the lowered list has exactly 50 operations and every index is `Fill`; require no transform/layer/stroke operation appears. [VERIFIED: local `lower.mbt` + `portable_qualification_wbtest.mbt`] | `parse_svg`, then `lower_to_drawing_list`, with the list sunk through `b.keep`. [VERIFIED: local `svg_bench.mbt`] | `db053c95e904e016041f8b2f4a5e6471ed4bf1b144cfd0fc99c44d7d670cdddc`. [VERIFIED: local deterministic UTF-8 calculation] | `e76479b6744a5f062c21d7e5502971a45388346767e9d91aea0119c4340c18e5`. [VERIFIED: local canonical UTF-8 calculation] |

Use SHA-256 in the record rather than adding a MoonBit cryptography dependency or timing a digest function. The digest proves the fixed corpus/assertion contract; it is calculated by the capture procedure outside the benchmark timing closure. [VERIFIED: 94-CONTEXT.md D-02 + existing fixture policy]

### Frozen canonical digest representations

Every corpus and correctness digest is lower-case SHA-256 over the exact UTF-8 bytes **without a BOM and without a trailing newline**. `v1` is part of the correctness text; it is not a formatting note. The capture helper must construct these ASCII texts as literals and hash them, rather than formatting runtime doubles or serializing a data structure. [VERIFIED: local deterministic calculation + D-01/D-04]

| Workload | Frozen canonical correctness text |
|----------|-----------------------------------|
| `path-parse/1000-line-to` | `v1|ok|commands=1001|first=M(0,0)|last=L(99,99)` |
| `transform-composition/50-segment` | `v1|ok|a=-764.5825470346006|b=981.6717123516748|c=-550.8736348781798|d=-664.151879387284|tx=-1060.1606213143448|ty=997.9648720635827|probe_x=1.25|probe_y=-2.5|out_x=-638.704717912146|out_y=3885.434210971386|tolerance=1e-9` |
| `parse-to-lower/50-rect` | `v1|ok|ops=50|all=Fill` |

The transform gate must paste these source literals: affine `(a,b,c,d,tx,ty) = (-764.5825470346006, 981.6717123516748, -550.8736348781798, -664.151879387284, -1060.1606213143448, 997.9648720635827)` and probe `(1.25,-2.5) -> (-638.704717912146,3885.434210971386)`, each checked with absolute tolerance `1.0e-9`. They were calculated by applying the checked parser's `Affine2::compose` order to the exact ten five-function repeats; the test's expected vector is deliberately static. [VERIFIED: local `svg_bench.mbt`, `transform.mbt`, `affine.mbt`, and deterministic calculation]

### Pattern 2: Four-target run qualification, native-only retained evidence

**What:** Use the all-target benchmark command to prove the three gates build and run, then use a distinct native release command for retained captures. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] [VERIFIED: local MoonBit CLI execution]

**Commands and observed behavior:**

```powershell
# Four-target functional qualification; inspect only exit status and 3/3 pass result per target.
moon bench modules/mb-svg/svg --target all --frozen

# Separate full package regression check after benchmark edits.
moon test modules/mb-svg/svg --target all --frozen

# Exact command for the native release warmup and every retained capture.
moon bench modules/mb-svg/svg --release --target native --frozen
```

`--target all` is documented to expand to `wasm`, `wasm-gc`, `js`, and `native`, not `llvm`. Locally, both all-target commands completed successfully; the bench command emitted a timing summary for each workload/target and the test command reported 125 passing ordinary tests per target. Do not retain, aggregate, rank, or compare the all-target timing lines. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] [VERIFIED: local MoonBit CLI execution]

### Native-release baseline document schema

Create `docs/benchmarks/mb-svg-native-release-baseline.md`. It is a baseline evidence document, not an automated gate, a performance threshold, or a release authority. [VERIFIED: 94-CONTEXT.md deferred scope + local Phase 11 baseline pattern]

| Section / field | Required content |
|-----------------|------------------|
| Scope statement | Exact non-claim: native-host observation for like-for-like reproduction only; no cross-target comparison, threshold, ranking, or marketing claim. [VERIFIED: 94-CONTEXT.md] |
| Benchmark identity | Git commit SHA; `svg_bench.mbt` and `moon.pkg` file-byte SHA-256 values; and a combined-source SHA-256 over the no-BOM/no-newline UTF-8 text `v1|svg_bench.mbt=<digest>|moon.pkg=<digest>` in that exact order. List the three names in fixed order and the frozen corpus/correctness SHA-256 per workload. [VERIFIED: local PPM provenance pattern + Phase 94 canonical representation] |
| Exact execution | Repository-relative working directory; exact native command above; `--release`, `--target native`, and `--frozen`; output capture encoding as UTF-8; no hidden environment-variable substitutions. [VERIFIED: local MoonBit CLI help + toolchain policy] |
| Toolchain facts | Full first line from `moon --version`, `moonc -v`, and `moonrun --version`; include toolchain policy expected values and mark any mismatch as `MISMATCH`, not baseline evidence. [VERIFIED: `policy/foundation.json` + `docs/policies/toolchain.md` + local CLI] |
| Host facts | OS caption/version/build/architecture; CPU name; physical-core count; logical-processor count; total physical memory; active power scheme; PowerShell version; current UTC timestamp. Capture each as returned, or literal `unavailable` with the attempted command. [VERIFIED: local PowerShell probes + existing PPM harness] |
| Reproducibility controls | **Preflight requires a clean worktree**: `git status --porcelain=v1 --untracked-files=all` must return no bytes before the warmup. Otherwise stop without writing a baseline. Record the clean preflight result verbatim as `(clean)`, commit SHA, `--frozen`, target, release optimization, one warmup, seven captures, and a SHA-256 for each complete retained merged-output text. This prevents a dirty observation from being mislabeled comparable to a clean baseline. [VERIFIED: D-04 + local git/PPM provenance patterns] |
| Warmup | One successful native-release command using the exact command; record UTC start/end and output SHA-256, but label it `untimed / excluded from summary`. [VERIFIED: local PPM harness] |
| Seven captures | Capture 1 through 7 separately; for each preserve UTC start/end, exit code, 3/3 result, full runner summaries for the three named workloads, and the full-output SHA-256. [VERIFIED: local MoonBit benchmark output + PPM baseline pattern] |
| Transparent summary | Per workload, list all seven native runner means plus arithmetic mean, median, sample standard deviation, minimum, maximum, and coefficient of variation; label every value native-host-specific. The audit recomputes all seven aggregates from the seven retained outputs instead of trusting the rendered table. [VERIFIED: local PPM aggregation pattern + D-04] |
| Audit | The helper's audit path recomputes the two source-file digests, combined-source digest, all three corpus digests, all three canonical-correctness digests, all eight output digests (warmup plus captures 1–7), parses the retained capture summaries, and recomputes every seven-capture aggregate. It fails on any mismatch, missing capture, nonzero exit status, wrong workload order, or worktree state other than `(clean)`. [VERIFIED: D-01/D-04 + Phase 94 capture design] |
| Comparison rule | A record is comparable only when workload order/names, source/corpus/correctness digests, command flags, target, release mode, toolchain identity, and recorded host facts exactly match; otherwise the document says `not comparable` and makes no regression inference. [VERIFIED: D-03/D-04 comparison scope] |

### Current capture-host fact availability

| Field | Capture command | Observed value on this research host | Baseline rule |
|-------|-----------------|--------------------------------------|---------------|
| MoonBit toolchain | `moon --version` | `moon 0.1.20260713 (75c7e1f 2026-07-13)`, `moonc v0.10.4+2cc641edf (2026-07-15)`, `moonrun 0.1.20260713 (75c7e1f 2026-07-13)`. [VERIFIED: local `moon --version`] | Preserve the full raw lines and compare them to the exact policy pin. [VERIFIED: `policy/foundation.json`] |
| OS | `Get-CimInstance Win32_OperatingSystem` | `Microsoft Windows 11 企业版`, version/build `10.0.22631` / `22631`, 64-bit. [VERIFIED: local PowerShell probe] | Record raw caption/version/build/architecture; do not translate the localized caption. [VERIFIED: 94-CONTEXT.md D-04] |
| CPU | `Get-CimInstance Win32_Processor \| Select-Object -First 1` | `Intel(R) Xeon(R) Platinum 8378C CPU @ 2.80GHz`, 4 physical cores, 8 logical processors. [VERIFIED: local PowerShell probe] | Record returned values; do not infer clock governor or CPU affinity if no probe produced it. [VERIFIED: 94-CONTEXT.md D-04] |
| Memory | `Get-CimInstance Win32_ComputerSystem` | `34,358,808,576` bytes installed physical memory. [VERIFIED: local PowerShell probe] | Record integer bytes, not a rounded marketing unit. [VERIFIED: local PPM harness] |
| Power plan | `powercfg /GETACTIVESCHEME` | GUID `381b4222-f694-41f0-9685-ff5bb260df2e`, localized name `平衡`. [VERIFIED: local PowerShell probe] | Record raw command output; if unavailable, write `unavailable (command failed)` rather than guessing. [VERIFIED: 94-CONTEXT.md D-04] |
| Git identity and cleanliness | `git rev-parse HEAD`; `git status --porcelain=v1 --untracked-files=all` | This research host is not a capture candidate while other Phase 94 work is present. [VERIFIED: local git probe] | Require the porcelain output to be empty before the warmup; otherwise fail the preflight and write no baseline. The record stores literal `(clean)` only after that check passes. [VERIFIED: D-04 + selected Phase 94 clean-preflight policy] |

### Anti-Patterns to Avoid

- **Timing before the semantic gate:** A `Result` that is merely sunk can benchmark repeated parse errors; use a one-time `Ok`/operation-shape assertion before `b.bench`. [VERIFIED: local `svg_bench.mbt` + 94-CONTEXT.md D-01]
- **Capturing the all-target output as performance evidence:** `moon bench --target all` produces numbers, but D-03 prohibits treating them as comparable timings. Retain only target pass/fail qualification. [VERIFIED: 94-CONTEXT.md D-03 + local CLI execution]
- **Reusing the PPM JSON release harness:** Its fixed workload cardinality and threshold policy would silently expand scope into performance gating. [VERIFIED: `release/qualification/benchmark-schema.json`]
- **Digesting only the current `svg_bench.mbt`:** An import or `moon.pkg` change can alter compilation semantics. Digest both files and identify the git commit. [VERIFIED: existing PPM source-digest practice]
- **Hashing with PowerShell 7-only APIs:** `[Convert]::ToHexString` and static `SHA256.HashData` are unavailable on Windows PowerShell 5.1. Use `[Security.Cryptography.SHA256]::Create().ComputeHash(...)`, render with `[BitConverter]::ToString(...).Replace('-', '').ToLowerInvariant()`, and dispose the instance. [VERIFIED: Windows PowerShell/.NET Framework compatibility requirement + local PPM helper inspection]
- **Accepting a dirty baseline:** A verbatim dirty status can describe an observation, but it cannot be like-for-like clean baseline evidence. Phase 94 selects the stricter clean preflight: do not capture at all unless the complete porcelain output is empty. [VERIFIED: D-04 + selected Phase 94 policy]
- **Inventing host facts:** Use exact probe output or `unavailable`; localized Windows display names are valid captured facts and should not be translated or normalized into guessed values. [VERIFIED: local host-fact probe + 94-CONTEXT.md D-04]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Benchmark execution/statistics | Custom timer, ad-hoc iteration loop, or third-party runner | MoonBit `@bench.T::bench` and `b.keep` | MoonBit selects iteration counts and provides the mean/range statistical output already required for reproducible captures. [CITED: https://docs.moonbitlang.com/en/latest/language/benchmarks.html] |
| Cross-target qualification | Target-specific scripts | `moon bench ... --target all --frozen` | The pinned CLI expands the project’s four declared portable targets consistently. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |
| Corpus identity | A new fixture framework or runtime hash library | Test-local deterministic builders plus PowerShell SHA-256 recorded outside timing | Locked D-02 disallows a benchmark framework/package, and the corpus is intentionally generated in the local test. [VERIFIED: 94-CONTEXT.md + local PPM pattern] |

**Key insight:** The benchmark itself is the right place to enforce semantic validity, while the evidence document is the right place to preserve immutable provenance and host-dependent observations. [VERIFIED: 94-CONTEXT.md D-01 through D-04]

## Common Pitfalls

### Pitfall 1: A benchmark name is not a correctness contract

**What goes wrong:** The current parse-to-lower closure converts parse errors into `keep(())`, so a regression could report a fast result rather than fail. [VERIFIED: local `svg_bench.mbt`]

**Why it happens:** The runner judges execution completion, not whether a `Result` represented the intended SVG behavior. [VERIFIED: local benchmark source]

**How to avoid:** Match and abort on `Err`, inspect the real public result before timing, and keep the timed closure free of assertion work. [VERIFIED: local PPM guard pattern]

**Warning signs:** An `Err(_) => keep(())` branch, a missing operation-count assertion, or a correctness digest absent from the baseline. [VERIFIED: local source + D-01]

### Pitfall 2: Comparing unlike native measurements

**What goes wrong:** A changed corpus, toolchain, release flag, target, host, or worktree makes a numeric delta ambiguous. [VERIFIED: toolchain policy + D-04]

**Why it happens:** The runner adapts iteration count and target runtimes/code generation differ; host conditions also affect wall-clock results. [CITED: https://docs.moonbitlang.com/en/latest/language/benchmarks.html] [ASSUMED]

**How to avoid:** Require exact matching identity facts before comparison and otherwise label the records not comparable. [ASSUMED]

**Warning signs:** Missing source/corpus digest, a toolchain mismatch, non-native target, a non-release invocation, fewer than seven retained captures, or unrecorded host state. [VERIFIED: D-04 + local PPM evidence shape]

### Pitfall 3: Treating `--target all` timing output as data

**What goes wrong:** A convenient all-target command yields a table-like set of values that invites an invalid ranking. [VERIFIED: local `moon bench --target all` output]

**How to avoid:** Record only the four target labels and their 3/3 pass status for qualification; omit all timing numbers from the Phase 94 baseline document. [VERIFIED: D-03]

## Code Examples

### Native evidence capture protocol

```powershell
# Preconditions: the pinned toolchain passes policy and this must emit no output.
if ((& git status --porcelain=v1 --untracked-files=all).Count -ne 0) {
  throw 'Refusing SVG baseline capture: worktree is not clean.'
}

# Windows PowerShell 5.1 and PowerShell 7-safe lower-case SHA-256. Do not use
# [Convert]::ToHexString or [Security.Cryptography.SHA256]::HashData.
function Get-Sha256Bytes([byte[]] $bytes) {
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

# Hash every retained text field as UTF-8 without a BOM and normalize a captured
# output to LF plus one final LF before both storing and hashing it.
$utf8 = New-Object Text.UTF8Encoding($false)
$command = 'moon bench modules/mb-svg/svg --release --target native --frozen'

# Run the literal command once as an excluded warmup, then seven separate captures.
# Embed each normalized complete merged stdout/stderr text in the Markdown record.
# An audit re-extracts those eight blocks, recomputes each output digest, reparses
# the three ordered summaries, and recomputes the three seven-sample aggregates.
```

**Chosen minimal helper:** implement one self-contained `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1`, with an optional `-Audit` mode but no caller-supplied command, source path, output path, threshold, or comparison decision. It resolves the repository root from `$PSScriptRoot`, invokes the literal command through `& moon` with fixed arguments, captures merged stdout/stderr, renders `docs/benchmarks/mb-svg-native-release-baseline.md`, and immediately audits the rendered record. `-Audit` reads only the checked-in Markdown record and current fixed inputs; it does not rerun benchmarks. This is smaller and safer than adapting the PPM JSON harness because Phase 94 has three workloads, Markdown evidence, no threshold, and no CI gate. [VERIFIED: D-02/D-04 + local PPM harness scope]

The capture script must not add threshold enforcement, CI gating, a hidden command override, or cross-host comparison; Phase 94 needs reproducible evidence only. [VERIFIED: deferred scope in 94-CONTEXT.md]

### Whole-package portability regression command

```powershell
moon test modules/mb-svg/svg --target all --frozen
```

This validates existing SVG behavior across the same four targets; it complements but does not replace the benchmark-local functional qualification. [VERIFIED: Phase 93 verification + local CLI execution]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Implicit `@bench.T` core-package use | Explicit `moonbitlang/core/bench` package import | Current compiler emits a `core_package_not_imported` deprecation warning. [VERIFIED: local `moon bench` output] | Add the import while touching benchmark configuration so the suite has no implicit-core dependency. |
| Benchmark closures that only sink `Result` values | One-time semantic gate followed by a narrow timed closure | Phase 94 locked D-01. [VERIFIED: 94-CONTEXT.md] | Fast failures cannot become timing evidence. |

**Deprecated/outdated:**

- Implicit core `bench` import: the current compiler warns it is deprecated; declare it explicitly in `moon.pkg`. [VERIFIED: local `moon bench` output]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A3 | The runner/host relationship explains why target and host values are not generally comparable. | Pitfall 2 | The policy already prohibits cross-target claims; this rationale should not be treated as a quantified performance result. |

## Open Questions (Resolved)

1. **Frozen transform oracle and digest:** resolved with ten five-function repeats (not the source's pre-phase six-function list), affine `(-764.5825470346006, 981.6717123516748, -550.8736348781798, -664.151879387284, -1060.1606213143448, 997.9648720635827)`, probe `(1.25,-2.5)`, expected point `(-638.704717912146,3885.434210971386)`, tolerance `1.0e-9`, and the exact `v1` canonical text/digest listed above. [VERIFIED: local transform/affine implementation and deterministic calculation]

2. **Capture automation:** resolved in favor of the narrow self-contained PowerShell helper described above, including immediate audit. It writes one Markdown baseline and does not import a package, alter CI, or reuse the PPM threshold schema. [VERIFIED: D-02/D-04 + local PPM harness scope]

3. **Hashing and reproducibility:** resolved with PowerShell 5.1-safe `SHA256::Create().ComputeHash()` plus `BitConverter` hex rendering; every digest is lower-case SHA-256 of its stated no-BOM UTF-8 or file-byte representation. Capture requires a clean preflight and audit recomputes all input/output digests and all seven-capture aggregates from the retained Markdown outputs. [VERIFIED: D-04 + selected Phase 94 capture protocol]

## Environment Availability

| Dependency | Required By | Available | Version / fact | Fallback |
|------------|-------------|-----------|----------------|----------|
| `moon` | Four-target and native-release benchmark commands | ✓ | `0.1.20260713` (`75c7e1f`) | — [VERIFIED: local `moon --version`] |
| `moonc` | Native compilation identity | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local `moon --version`] |
| `moonrun` | Runtime identity | ✓ | `0.1.20260713` (`75c7e1f`) | — [VERIFIED: local `moon --version`] |
| PowerShell `Get-CimInstance` / .NET SHA-256 | Host facts and SHA-256 capture records | ✓ | Returned OS/CPU/memory data; .NET hash route also executed successfully under local Windows PowerShell 5.1 | Write `unavailable` plus attempted command if a host probe is absent; the hash route has no fallback. [VERIFIED: local probes] |

**Missing dependencies with no fallback:** None. [VERIFIED: local probes]

**Missing dependencies with fallback:** None. [VERIFIED: local probes]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 94 adds no identity boundary. [VERIFIED: Phase 94 scope] |
| V3 Session Management | No | Phase 94 adds no session state. [VERIFIED: Phase 94 scope] |
| V4 Access Control | No | Phase 94 adds no authorization path. [VERIFIED: Phase 94 scope] |
| V5 Input Validation | Yes | Deterministic, source-controlled benchmark inputs are checked through the existing public SVG parser before timing; do not add a bypass. [VERIFIED: D-01 + local SVG APIs] |
| V6 Cryptography | No | Use platform SHA-256 only to identify evidence; do not implement cryptography in MoonBit for this phase. Use the Windows PowerShell 5.1-safe `SHA256::Create().ComputeHash()`/`BitConverter` route. [VERIFIED: D-02 + local Windows PowerShell 5.1 probe] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampered benchmark corpus or source after baseline capture | Tampering | Record commit and SHA-256 for `svg_bench.mbt`, `moon.pkg`, each corpus, each correctness contract, and complete command outputs. [VERIFIED: local fixture/PPM evidence practices] |
| Misrepresented host/toolchain fact | Repudiation | Record raw command output or literal `unavailable`, never inferred substitutions. [VERIFIED: D-04] |
| A parse failure represented as a benchmark success | Integrity | Abort in the pre-timing semantic gate. [VERIFIED: D-01 + local PPM guard pattern] |

## Recommended Plan Decomposition

1. **Benchmark correctness and portable execution** — Update only `modules/mb-svg/svg/svg_bench.mbt` and `moon.pkg`: explicit bench import, shared `require_benchmark`, fixed corpus builders, three pre-timing gates, `b.keep`, and stable names. Verify with `moon bench modules/mb-svg/svg --target all --frozen` (all four targets, 3/3) and `moon test modules/mb-svg/svg --target all --frozen`. [VERIFIED: local source + CLI]
2. **Evidence capture mechanism** — Add either a narrowly scoped PowerShell capture helper or a documented manual protocol; it must compute the source/corpus/correctness SHA-256 values, capture one warmup and seven native release outputs, collect facts truthfully, and avoid thresholds/CI gating. Verify against a deliberately missing/altered fact only if a helper is implemented. [ASSUMED]
3. **Native-release baseline artifact** — Add `docs/benchmarks/mb-svg-native-release-baseline.md`, populate it from an actual native release capture set, and review that all three workload sections have seven complete samples and no cross-target values. Verify the recorded command independently once and recompute every digest. [VERIFIED: D-04 + local Phase 11 baseline]

## Sources

### Primary (HIGH confidence)

- Local MoonBit `moon --version`, `moon bench --help`, and `moon test --help` — installed command flags and pinned toolchain identity. [VERIFIED: local MoonBit CLI]
- Local executions of all-target SVG bench/test and native release bench — actual current target coverage, runner output shape, and pass counts. [VERIFIED: local MoonBit CLI execution]
- `modules/mb-svg/svg/svg_bench.mbt`, `path_data.mbt`, `transform.mbt`, `lower.mbt`, and Phase 93 verification — workload behavior and assertion seams. [VERIFIED: local repository]
- `docs/rfcs/0002-mb-svg.md` §11.4 — declared path expansion, transform composition, and full parse/lower performance-sensitive workloads require deterministic benchmarks and reproducible baselines. [VERIFIED: local repository]
- `docs/policies/toolchain.md`, `policy/foundation.json`, `fixtures/manifest.json`, and Phase 11/PPM baseline artifacts — policy and established evidence practices. [VERIFIED: local repository]

### Secondary (MEDIUM confidence)

- [MoonBit benchmark documentation](https://docs.moonbitlang.com/en/latest/language/benchmarks.html) — `@bench.T`, automatic iteration selection, output form, and `b.keep`. [CITED: https://docs.moonbitlang.com/en/latest/language/benchmarks.html]
- [MoonBit package target documentation](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — `--target all` target expansion and package target behavior. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]
- [MoonBit CLI command documentation](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — current `moon bench` and `moon test` flags. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]

### Tertiary (LOW confidence)

- Conservative identity-matching rule and canonical correctness-digest text form; these are implementation recommendations requiring maintainer confirmation before becoming a durable evidence contract. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — toolchain/version/CLI behavior was read locally and cross-checked with official MoonBit documentation. [VERIFIED: local CLI + official docs]
- Architecture: HIGH — based on locked Phase 94 decisions and inspected local SVG/PPM patterns. [VERIFIED: 94-CONTEXT.md + local repository]
- Pitfalls: HIGH for current closure/CLI/policy observations; MEDIUM for general comparability rationale, which is explicitly marked assumed. [VERIFIED: local source + policy] [ASSUMED]

**Research date:** 2026-07-26
**Valid until:** 2026-08-02 — MoonBit command behavior is fast-moving; re-run `moon bench --help` before implementation if the toolchain pin changes. [ASSUMED]
