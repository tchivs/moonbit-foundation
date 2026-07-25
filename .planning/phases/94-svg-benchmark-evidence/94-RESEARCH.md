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
| SHA-256 (`Get-FileHash`) | Windows PowerShell built-in | Identifies the benchmark source, fixture corpus, and complete command-output capture. | The repository already records fixture SHA-256 values and uses `Get-FileHash` for benchmark evidence. [VERIFIED: `fixtures/manifest.json` + `scripts/benchmarks/Invoke-PpmBenchmarks.ps1`] |

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
| `path-parse/1000-line-to` | Existing deterministic `M0 0` plus 1,000 generated implicit `L` commands. [VERIFIED: local `svg_bench.mbt`] | Require `Ok`; require exactly 1,001 path commands; require command 0 is `MoveTo(0,0)` and command 1,000 is `LineTo(99,99)`. [VERIFIED: builder arithmetic + local `path_data_wbtest.mbt` API] | `parse_path_data(corpus)` sunk with `b.keep`. [VERIFIED: local `svg_bench.mbt`] | SHA-256 of UTF-8 corpus bytes. [VERIFIED: repository fixture digest practice] | SHA-256 of canonical text `ok|commands=1001|first=M(0,0)|last=L(99,99)`. [ASSUMED] |
| `transform-composition/50-segment` | Existing deterministic 10 repeats of five transform functions. [VERIFIED: local `svg_bench.mbt`] | Require `Ok`; require the six affine components are finite and within the documented numeric envelope; require the affine applies a fixed probe point to precomputed expected coordinates within the existing `1e-9` tolerance. Freeze the six expected values in the source once derived from the current fixed corpus—do not derive the expected value by reparsing at runtime. [VERIFIED: local `transform.mbt` + `transform_wbtest.mbt`] | `parse_transform(corpus)` sunk with `b.keep`. [VERIFIED: local `svg_bench.mbt`] | SHA-256 of UTF-8 corpus bytes. [VERIFIED: repository fixture digest practice] | SHA-256 of canonical text containing all six expected affine components and probe-point result in a locale-invariant format. [ASSUMED] |
| `parse-to-lower/50-rect` | Existing deterministic `<svg>` with 50 generated red unit rectangles. [VERIFIED: local `svg_bench.mbt`] | Require `parse_svg` yields `Ok`; require the lowered list has exactly 50 operations and every index is `Fill`; require no transform/layer/stroke operation appears. [VERIFIED: local `lower.mbt` + `portable_qualification_wbtest.mbt`] | `parse_svg`, then `lower_to_drawing_list`, with the list sunk through `b.keep`. [VERIFIED: local `svg_bench.mbt`] | SHA-256 of UTF-8 corpus bytes. [VERIFIED: repository fixture digest practice] | SHA-256 of canonical text `ok|ops=50|all=Fill`. [ASSUMED] |

Use SHA-256 in the record rather than adding a MoonBit cryptography dependency or timing a digest function. The digest proves the fixed corpus/assertion contract; it is calculated by the capture procedure outside the benchmark timing closure. [VERIFIED: 94-CONTEXT.md D-02 + existing fixture policy]

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
| Benchmark identity | Git commit SHA; `svg_bench.mbt` SHA-256; `moon.pkg` SHA-256; combined source SHA-256; three names in fixed order; corpus and correctness SHA-256 per workload. [VERIFIED: local PPM baseline provenance pattern] |
| Exact execution | Repository-relative working directory; exact native command above; `--release`, `--target native`, and `--frozen`; output capture encoding as UTF-8; no hidden environment-variable substitutions. [VERIFIED: local MoonBit CLI help + toolchain policy] |
| Toolchain facts | Full first line from `moon --version`, `moonc -v`, and `moonrun --version`; include toolchain policy expected values and mark any mismatch as `MISMATCH`, not baseline evidence. [VERIFIED: `policy/foundation.json` + `docs/policies/toolchain.md` + local CLI] |
| Host facts | OS caption/version/build/architecture; CPU name; physical-core count; logical-processor count; total physical memory; active power scheme; PowerShell version; current UTC timestamp. Capture each as returned, or literal `unavailable` with the attempted command. [VERIFIED: local PowerShell probes + existing PPM harness] |
| Reproducibility controls | Record dirty-worktree state, commit SHA, `--frozen`, target, release optimization, one warmup, seven captures, and a SHA-256 for each complete captured stdout/stderr file. [VERIFIED: `docs/policies/toolchain.md` + local PPM harness] |
| Warmup | One successful native-release command using the exact command; record UTC start/end and output SHA-256, but label it `untimed / excluded from summary`. [VERIFIED: local PPM harness] |
| Seven captures | Capture 1 through 7 separately; for each preserve UTC start/end, exit code, 3/3 result, full runner summaries for the three named workloads, and the full-output SHA-256. [VERIFIED: local MoonBit benchmark output + PPM baseline pattern] |
| Transparent summary | Per workload, list all seven native runner means plus arithmetic mean, median, sample standard deviation, minimum, maximum, and coefficient of variation; label every value native-host-specific. [VERIFIED: local PPM baseline aggregation pattern] |
| Comparison rule | Compare only when workload order/names, source/corpus/correctness digests, command flags, target, release mode, toolchain identity, and host fingerprint facts all match; otherwise report `not comparable` without inferring regression. [ASSUMED] |

### Current capture-host fact availability

| Field | Capture command | Observed value on this research host | Baseline rule |
|-------|-----------------|--------------------------------------|---------------|
| MoonBit toolchain | `moon --version` | `moon 0.1.20260713 (75c7e1f 2026-07-13)`, `moonc v0.10.4+2cc641edf (2026-07-15)`, `moonrun 0.1.20260713 (75c7e1f 2026-07-13)`. [VERIFIED: local `moon --version`] | Preserve the full raw lines and compare them to the exact policy pin. [VERIFIED: `policy/foundation.json`] |
| OS | `Get-CimInstance Win32_OperatingSystem` | `Microsoft Windows 11 企业版`, version/build `10.0.22631` / `22631`, 64-bit. [VERIFIED: local PowerShell probe] | Record raw caption/version/build/architecture; do not translate the localized caption. [VERIFIED: 94-CONTEXT.md D-04] |
| CPU | `Get-CimInstance Win32_Processor \| Select-Object -First 1` | `Intel(R) Xeon(R) Platinum 8378C CPU @ 2.80GHz`, 4 physical cores, 8 logical processors. [VERIFIED: local PowerShell probe] | Record returned values; do not infer clock governor or CPU affinity if no probe produced it. [VERIFIED: 94-CONTEXT.md D-04] |
| Memory | `Get-CimInstance Win32_ComputerSystem` | `34,358,808,576` bytes installed physical memory. [VERIFIED: local PowerShell probe] | Record integer bytes, not a rounded marketing unit. [VERIFIED: local PPM harness] |
| Power plan | `powercfg /GETACTIVESCHEME` | GUID `381b4222-f694-41f0-9685-ff5bb260df2e`, localized name `平衡`. [VERIFIED: local PowerShell probe] | Record raw command output; if unavailable, write `unavailable (command failed)` rather than guessing. [VERIFIED: 94-CONTEXT.md D-04] |
| Git identity and dirtiness | `git rev-parse HEAD`; `git status --short` | Commit `af1f1aa8644a64ffe67d7befc95b4287bb3a8f5d`; the worktree currently contains unrelated untracked paths and an untracked `svg_bench.mbt`. [VERIFIED: local git probe] | A baseline may be captured only from a clean worktree or must reproduce the full status verbatim and be marked non-comparable to clean captures. [ASSUMED] |

### Anti-Patterns to Avoid

- **Timing before the semantic gate:** A `Result` that is merely sunk can benchmark repeated parse errors; use a one-time `Ok`/operation-shape assertion before `b.bench`. [VERIFIED: local `svg_bench.mbt` + 94-CONTEXT.md D-01]
- **Capturing the all-target output as performance evidence:** `moon bench --target all` produces numbers, but D-03 prohibits treating them as comparable timings. Retain only target pass/fail qualification. [VERIFIED: 94-CONTEXT.md D-03 + local CLI execution]
- **Reusing the PPM JSON release harness:** Its fixed workload cardinality and threshold policy would silently expand scope into performance gating. [VERIFIED: `release/qualification/benchmark-schema.json`]
- **Digesting only the current `svg_bench.mbt`:** An import or `moon.pkg` change can alter compilation semantics. Digest both files and identify the git commit. [VERIFIED: existing PPM source-digest practice]
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
# Preconditions: clean or explicitly recorded worktree; pinned toolchain passes policy.
$command = 'moon bench modules/mb-svg/svg --release --target native --frozen'

# 1. Run once, save the complete output and its SHA-256, label it excluded warmup.
# 2. Run the exact same command seven separate times.
# 3. Save each complete output as UTF-8; record its SHA-256 and the three summaries.
# 4. Derive summary statistics only from the seven retained native captures.
```

The capture script, if one is added, must not add threshold enforcement, CI gating, or cross-host comparison; Phase 94 needs a reproducible record only. [VERIFIED: deferred scope in 94-CONTEXT.md]

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
| A1 | Canonical text hashed for the three correctness digests is the appropriate durable representation. | Correctness gates | A future baseline may need a revised digest encoding; document any such revision as a new workload identity. |
| A2 | All identity fields must match before two native records are comparable. | Baseline schema / Pitfall 2 | This is conservative and may reject useful informal comparisons, but it avoids a false regression claim. |
| A3 | The runner/host relationship explains why target and host values are not generally comparable. | Pitfall 2 | The policy already prohibits cross-target claims; this rationale should not be treated as a quantified performance result. |

## Open Questions

1. **Exact frozen affine constants for the current 50-segment corpus**
   - What we know: `parse_transform` returns six public affine components and existing tests use `1e-9` tolerance for trigonometric results. [VERIFIED: local `transform.mbt` + `transform_wbtest.mbt`]
   - What's unclear: The current benchmark has no frozen expected vector for its complex repeated transform list. [VERIFIED: local `svg_bench.mbt`]
   - Recommendation: In the implementation task, compute the constants once from the fixed literal with the pinned toolchain, write them as explicit literals with the existing tolerance, then include those literals in the correctness-digest text. Do not calculate an expected value through the benchmarked parser. [ASSUMED]

2. **Capture automation form**
   - What we know: A Markdown document is required; no threshold or CI gate is in scope. [VERIFIED: D-04 + deferred ideas]
   - What's unclear: Whether maintainers prefer a small PowerShell capture helper or a manually executed documented protocol. [VERIFIED: 94-CONTEXT.md discretion]
   - Recommendation: Plan a minimal helper only if it writes complete capture files and the document; otherwise use an explicit copy/paste protocol. In either form, preserve the exact baseline schema above. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version / fact | Fallback |
|------------|-------------|-----------|----------------|----------|
| `moon` | Four-target and native-release benchmark commands | ✓ | `0.1.20260713` (`75c7e1f`) | — [VERIFIED: local `moon --version`] |
| `moonc` | Native compilation identity | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local `moon --version`] |
| `moonrun` | Runtime identity | ✓ | `0.1.20260713` (`75c7e1f`) | — [VERIFIED: local `moon --version`] |
| PowerShell `Get-CimInstance` / `Get-FileHash` | Host facts and SHA-256 capture records | ✓ | Returned OS/CPU/memory data on this host | Write `unavailable` plus attempted command if absent on a future host. [VERIFIED: local probes] |

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
| V6 Cryptography | No | Use platform SHA-256 only to identify evidence; do not implement cryptography in MoonBit for this phase. [VERIFIED: D-02 + existing `Get-FileHash` use] |

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
