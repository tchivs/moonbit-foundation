# Technology Stack

**Project:** MoonBit Native Foundation — v0.30 SVG Production Readiness
**Researched:** 2026-07-25
**Confidence:** MEDIUM — the installed pinned toolchain and current repository were exercised directly; official MoonBit documentation corroborates the public command/API surface. The research-provider confidence seam classified the web lookup as LOW, so version-sensitive details must remain pinned and rechecked in CI.

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why |
|---|---:|---|---|
| MoonBit `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Build, test, and native performance measurement | This is the repository's installed and already-pinned development toolchain. Do not introduce Criterion, a host-language runner, or FFI timing; MoonBit's own harness is portable and exercises the code actually shipped. |
| `moonbitlang/core/bench` (`@bench`) | bundled with pinned toolchain | Bench test blocks, monotonic timing, statistical summaries | Use the official `test (b : @bench.T)` form, `b.bench`, and `b.keep`. It supplies automatic batch sizing and ten samples by default. The existing `svg_bench.mbt` is the right package-local home. |
| `tchivs/mb-core/text` | workspace `0.1.0` | Controlled decimal grammar and structured `CoreError` results | Add a *new*, explicitly finite SVG-facing parser here rather than adding a parser dependency or silently changing the existing general `parse_double` contract. `mb-svg` already depends on this package. |
| MoonBit `Double` built-ins | bundled with pinned toolchain | Portable non-finite detection | `Double::is_nan()` and `Double::is_inf()` are available on the installed core interface for every supported target. Define `is_finite(v) = !v.is_nan() && !v.is_inf()` once at the parsing boundary. |

### Database

No database, cache server, or telemetry product belongs in v0.30. Benchmark fixtures and baseline metadata are version-controlled repository artifacts, not mutable production data.

### Infrastructure

| Technology | Version | Purpose | Why |
|---|---:|---|---|
| Versioned SVG fixture corpus | repository `fixtures/` | Fixed, reviewable benchmark inputs | A literal corpus avoids measuring `StringBuilder` construction, random generation, file-system timing, or host state. Include workload ID, input bytes/digest, SVG feature profile, expected parse/lower outcome, and declared size. |
| `moon bench` | bundled with pinned toolchain | Native timing gate / baseline capture | The CLI supports `--target`, `--frozen`, path/package selection, and `--no-parallelize`. Native-only measurements are comparable; portable-target runs validate execution but must not share a native performance threshold. |
| `moon test --target all` | bundled with pinned toolchain | Semantic portability verification | `--target all` covers `wasm`, `wasm-gc`, `js`, and `native` (not LLVM). The numeric rejection suite must pass on all four supported production targets. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| `@bench.T::bench` | bundled | Timed named cases | Every reported SVG parsing/lowering workload. Create inputs and expected checksums outside the timed closure; sink the parse/lower result with `b.keep`. |
| `@bench.T::keep` | bundled | Prevent dead-code elimination | Every pure benchmark result. Replace the current package-local `keep` no-op; that helper does not create an observable use and therefore is not a valid optimization barrier. |
| `@bench.single_bench` + `Summary::to_json()` | bundled | Optional local raw diagnostic export | Use only for an explicitly experimental developer script. MoonBit documents `Summary` stability as not guaranteed, so do not make its JSON schema a release artifact or CI contract. |
| `@text.parse_double` | existing workspace API | General decimal conversion after SVG lexical admission | Do not accept its `Ok` result as sufficient for SVG. The new finite wrapper must bound the exponent before conversion and reject a NaN or infinity result after conversion. |
| `@error.CoreError` | existing workspace API | Deterministic failure representation | Use a stable SVG-specific operation/context such as `svg-parse-number` plus a machine-distinguishable cause (`exponent-too-long`, `exponent-out-of-range`, `non-finite`). Do not substitute zero or retain a partially parsed geometry value. |

## Required Package and Target Policy

`modules/mb-svg/svg/moon.pkg` already declares the correct portable surface:

```moonbit
supported_targets = "+js+wasm+wasm-gc+native"
```

Keep v0.30 implementation in ordinary MoonBit source and leave that target set unchanged. `supported-targets` is metadata, while per-file `targets` is the mechanism for genuine backend-specific source. Neither a native-only numeric fast path nor a native FFI parser is justified: parsing a hostile SVG must have the same accept/reject semantics on JavaScript, Wasm, Wasm-GC, and native.

The package already compiles the benchmark form successfully with the current toolchain. If a package needs an explicit declaration for benchmark-only code, follow the current MoonBit convention rather than placing `bench` in production imports:

```moonbit
import {
  "moonbitlang/core/bench",
} for "test"
```

Only add that block if `moon check`/`moon bench` needs it after the benchmark is revised; do not add an application dependency merely for test harness symbols. The prelude exposes the `Double` methods, so v0.30 needs no new runtime import for `is_nan`/`is_inf`.

## Numeric-Safety Contract

### Recommended new API

Add an opt-in helper in `mb-core/text`, for example `parse_finite_double`, and migrate all SVG numeric ingress points to it: `parse_length`, `parse_number_list`, path-data token reading, transform arguments, viewBox values, geometry attributes, opacity/stroke values, and numeric colour components where SVG geometry can receive them.

The helper must have a deliberately narrow contract:

1. Trim only the allowed surrounding SVG whitespace and admit the existing signed decimal/exponent grammar.
2. Bound exponent syntax before doing numeric work: cap digit count and reject an exponent whose magnitude is outside a documented safe range. This avoids an adversarial exponent driving the current repeated-`pow10` loop for millions of iterations.
3. Delegate ordinary conversion to the existing deterministic parser.
4. Reject `NaN`, positive infinity, and negative infinity using `Double::is_nan()` / `Double::is_inf()`; a syntactically valid but non-finite result is an error, never a sentinel.
5. Require every transform constructor and each composed `Affine2` to have six finite components. Validate derived values such as degrees-to-radians and `sin`/`cos` outputs too, because finite source values can overflow during multiplication or produce a non-finite intermediate.

This must be additive: preserve the existing general `@text.parse_double` API for other formats until its compatibility policy is separately decided. SVG calls the stricter finite API explicitly. That avoids accidentally changing a general parser's documented acceptance behavior while closing SVG's trust boundary.

### Checked Parsing Is Not Integer Casting

Never use `Double::to_int`, `to_uint`, or a clamp as the validity check. The installed core tests document saturation-like behavior for infinite conversion on some backends. SVG values must be rejected before they reach an affine matrix, path, canvas command, or allocation calculation. Rejecting is the fail-closed behavior; coercion changes drawing semantics and can conceal malformed/untrusted input.

## Benchmark Workload Contract

Adopt three immutable workload classes, each represented by a literal fixture and a stable ID in its benchmark name:

| ID class | Timed operation | Required workload metadata | Outcome oracle outside timing |
|---|---|---|---|
| `svg-path-*` | `parse_path_data` | command count, bytes, command mix, numeric-token count | parsed command count / terminal point |
| `svg-transform-*` | `parse_transform` | transform count, mix, numeric-token count, bytes | six affine components are finite and match a known transform |
| `svg-document-*` | `parse_svg` then `lower_to_drawing_list` | elements, nesting depth, path/shape mix, bytes, feature profile | scene/lowering succeeds and has the expected operation summary |

Use benchmark source like this (the exact workload identifier and fixture helper are project decisions):

```moonbit
test "svg-path-linear-1000-v1" (b : @bench.T) {
  let input = fixture_svg_path_linear_1000() // setup is not timed
  b.bench(name="parse_path_data", fn() {
    b.keep(parse_path_data(input))
  })
}
```

For a `Result` pipeline, preserve the error/value as the kept value or match it and keep the resulting drawing list. Do not use a local `fn keep[T](_) { () }`: it cannot guarantee the computation remains observable. Do not use `Summary` JSON as the durable baseline format; retain the toolchain version, command line, target, CPU/OS runner identity, fixture digest, and the console summary in a human-reviewed artifact instead.

### Commands

```powershell
# One reproducible native timing run. Pin target, avoid dependency mutation,
# and serialize cases so the shared runner does not add parallel contention.
moon -C modules/mb-svg bench svg --target native --frozen --no-parallelize

# Compile the benchmark harness without timing it.
moon -C modules/mb-svg bench svg --target native --frozen --build-only

# Verify numeric rejection and regular SVG behavior on all production targets.
moon -C modules/mb-svg test svg --target all --frozen
```

The first command was exercised against the current unmodified package: all three existing cases passed on native. Those timing values are intentionally not a baseline, because the current cases synthesize their inputs and use the ineffective local sink. Establish the first accepted baseline only after fixed fixtures and `b.keep` land, on a declared runner.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|---|---|---|---|
| Benchmark runner | `moon bench` + `@bench.T` | Criterion, Hyperfine, custom C/JS driver | It would measure a wrapper or introduce FFI and target drift instead of the package's public MoonBit behavior. |
| Benchmark input | Checked-in literals / fixture loader outside closure | Build strings or randomized documents in the test | Construction cost and nondeterminism pollute the parser/lowering measurement. |
| Optimization barrier | `b.keep(value)` | Local no-op `keep`, `ignore`, or output printing | The official benchmark API specifically provides `keep`; no-op sinks can be removed and printing distorts timing. |
| Raw statistics | Console summary plus versioned run metadata | Commit `Summary.to_json()` schema | Official docs say `Summary` stability is not guaranteed. |
| Numeric policy | Central bounded `parse_finite_double` used by SVG | Per-caller `is_nan` checks | Per-caller checks inevitably miss one ingress path and cannot bound pre-conversion exponent work. |
| Numeric policy | Reject non-finite values | Clamp, substitute zero, or permit an infinity matrix | These conceal invalid SVG and allow impossible geometry to escape into canvas/lowering. |
| Portability | MoonBit `Double` + all-target conformance tests | Native `strtod`, locale parser, or C math helper | Violates the project’s portable MoonBit-first constraint and risks different acceptance semantics by target. |

## Installation

No package installation is required. The pinned MoonBit toolchain already provides `@bench` and `Double` classification methods.

```powershell
# Inspect exact tool versions recorded with every baseline run.
moon version --all --json
```

## Sources

- [MoonBit: Writing Benchmarks](https://docs.moonbitlang.com/en/latest/language/benchmarks.html) — official documentation for `@bench.T`, `bench`, `keep`, automatic batching, and the explicitly unstable `Summary` JSON surface. Provider confidence: LOW; cross-checked against the installed `moonbitlang/core/bench` source and interface.
- [MoonBit command-line help](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — official `moon bench` command, target, frozen, build-only, and no-parallelize options. Provider confidence: LOW; direct package build and native run succeeded locally.
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — official import and target-set semantics, including `--target all`. Provider confidence: LOW; cross-checked with `modules/mb-svg/svg/moon.pkg` and installed core package manifests.
- Installed pinned toolchain: `moon version --all --json`, `D:/AI-Data/moonbit/lib/core/bench/`, and `D:/AI-Data/moonbit/lib/core/builtin/pkg.generated.mbti` — direct local evidence for `Bench::keep`, `Double::is_nan`, and `Double::is_inf`.
- Current repository: `modules/mb-svg/svg/svg_bench.mbt`, `length.mbt`, `path_data.mbt`, `transform.mbt`, `modules/mb-core/text/number_parse.mbt`, and `modules/mb-svg/svg/moon.pkg` — direct local evidence for existing seams and the exponent/finite-value gap.
