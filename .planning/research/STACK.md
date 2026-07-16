# MoonBit Native Foundation: Toolchain and Repository Stack

**Research date:** 2026-07-16  
**Scope:** v0.1 Foundation (`mb-core`, `mb-color`, `mb-image`)  
**Recommendation confidence:** High for toolchain/build/test mechanics; medium for registry namespace and long-term compatibility floor because those are governance decisions not yet made.

## Executive recommendation

Build MNF as a **Moon workspace containing three independently publishable MoonBit modules from day one**, not as one module containing all three libraries. Use the current Native backend as the default, but require portable modules to pass `wasm`, `wasm-gc`, `js`, and `native` checks/tests. Keep LLVM outside the required matrix because it is not included by `--target all` and remains experimental in the current toolchain documentation.

Pin the initial developer and CI baseline to the versions verified locally on 2026-07-16:

| Component | Verified version | Policy |
|---|---:|---|
| `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Exact CI pin for the v0.1 development line |
| `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | Record in CI logs; comes with the pinned toolchain |
| `moonrun` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Record in CI logs; comes with the pinned toolchain |

Do not declare these permanent minimum supported versions yet. Put them in a root toolchain policy document and CI configuration, then declare a public compatibility floor only when the first release candidate is tested. MoonBit is pre-1.0 and its FFI ownership defaults are explicitly in transition, so silently following `latest` would make reproducibility and ABI review unreliable.

## Repository and workspace model

Use this layout:

```text
moonbit-foundation/
├── moon.work
├── modules/
│   ├── core/
│   │   ├── moon.mod.json
│   │   └── src/.../moon.pkg
│   ├── color/
│   │   ├── moon.mod.json
│   │   └── src/.../moon.pkg
│   └── image/
│       ├── moon.mod.json
│       └── src/.../moon.pkg
├── docs/
├── fixtures/
└── .github/workflows/
```

`moon.work` should list `modules/core`, `modules/color`, and `modules/image`. A MoonBit **module is the publication and versioning unit**, while a package is a namespace/compilation unit inside a module. A workspace lets root-level `moon check`, `moon test`, `moon info`, and `moon clean` operate across members; publication remains module-specific with `moon -C modules/core publish`. Workspace dependencies resolve locally, and `moon work sync` aligns member dependency versions before release.

Recommended eventual registry identities are `<owner>/mnf-core`, `<owner>/mnf-color`, and `<owner>/mnf-image`. The `<owner>` value must remain a placeholder until the mooncakes.io organization/username is decided because published module names must start with the owning username. Each module may contain focused subpackages (for example checked arithmetic, streams, color conversions, pixel storage, codecs), but adding subpackages must not turn one module into a catch-all.

Keep `moon.mod.json` for v0.1 manifests and use the current `moon.pkg` DSL for package files. The docs describe a newer `moon.mod` syntax, but the official project/publishing tour still generates `moon.mod.json`, while local `moon` advertises rollout feature flags for the new module/package formats. JSON at the publication boundary is therefore the lower-risk choice until the new module format is no longer rollout-sensitive. This is a repository-format choice only; it does not prevent later mechanical migration.

### Alternatives rejected

- **One module with `core`, `color`, and `image` packages:** rejected because module-level versioning and `moon publish` would couple all releases and prevent consumers from selecting independent module lifecycles.
- **Three repositories immediately:** rejected because v0.1 requires frequent cross-contract changes; `moon.work` gives local coordination without sacrificing publication boundaries.
- **Path dependencies in `moon.mod.json`:** rejected for new work; official guidance recommends workspace resolution, and the new `moon.mod` syntax deprecates local dependency configuration.
- **Adopt `moon.mod` immediately:** deferred until its rollout status is stable across the declared compatibility floor.

Sources: [Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html), [Module Configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html), [Use and publish packages](https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html).

## Targets and portability

Set `"preferred-target": "native"` in all three module manifests to make the primary developer path explicit. Declare support rather than inheriting it accidentally:

- `mnf-core`: `"supported-targets": "+js+wasm+wasm-gc+native"` for portable data and algorithms; native host adapters belong in separate native-only packages.
- `mnf-color`: the same four-target set.
- `mnf-image`: the same four-target set for image models, transforms, and pure reference codecs; any system codec adapter is a separate package with `"supported-targets": "native"`.

Package-level `supported-targets` narrows the module declaration by intersection. Use package metadata for capability boundaries, and use per-file `targets` only when a package truly needs backend-specific source files. Omitting `supported-targets` means all backends, which is too permissive for MNF's explicit portability promise.

Required PR validation:

```powershell
moon fmt --check
moon check --target all --deny-warn --frozen
moon test --target all --frozen
moon info --frozen
```

`--target all` currently expands to `wasm`, `wasm-gc`, `js`, and `native`, explicitly excluding LLVM. Add LLVM only as a non-blocking experimental job after it can build meaningful MNF packages; do not advertise LLVM support based on a successful type-check alone.

Sources: [MoonBit documentation target overview](https://docs.moonbitlang.com/en/latest/), [Package Configuration: supported targets](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html), [Module Configuration: preferred and supported targets](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html).

## Native FFI and host adapters

Use C FFI only in packages whose names make the host boundary obvious, such as a future `io/native` or codec-specific `codec/png/native`. Portable public types must not expose C pointers, `#external` types, C struct layout, or foreign-library error codes.

Native adapters should follow these mandatory rules:

1. Declare the package as native-only and list C wrapper files with `native-stub` in `moon.pkg`.
2. Keep `extern "C"` declarations and their stubs together in the adapter package.
3. Annotate reference-counted arguments explicitly with `#borrow` or `#owned`; do not depend on the current default because the official FFI docs state that the default is migrating from owned to borrowed.
4. Document ownership, cleanup, callback lifetime, thread affinity, error mapping, integer-width conversion, and buffer-length validation next to every boundary.
5. Use `moonbit_make_external_object` only for native resources whose finalizer semantics are appropriate; the finalizer releases the external resource and must not drop the MoonBit object itself.
6. Avoid exposing payload-bearing MoonBit struct/enum layouts to C because the documented C representation is unstable. Prefer scalars, `Bytes`, opaque abstract types, and narrow wrapper functions.
7. Require sanitizer-backed C compilation in a dedicated Linux CI job once the first stub lands; until then the main matrix remains pure MoonBit.

MoonBit currently uses reference counting for C/native and Wasm backends, while Wasm GC and JavaScript reuse their host GC. That makes cross-backend conformance tests essential: portable behavior cannot be inferred from native success.

### Alternatives rejected

- **Wrap mature C libraries as the core implementation:** rejected because it violates MNF's MoonBit-native purpose and contaminates portable packages.
- **Ban all C:** rejected because OS integration and mature codecs may require narrow adapters.
- **Rely on implicit FFI ownership convention:** rejected because the documented default is changing and mistakes produce leaks or memory errors.

Sources: [MoonBit FFI](https://docs.moonbitlang.com/en/latest/language/ffi.html), [MoonBit attributes: borrow and owned](https://docs.moonbitlang.com/en/stable/language/attributes.html), [Package Configuration: native stubs and link options](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html).

## Testing, documentation, and benchmarks

Use MoonBit's built-in test modes as separate evidence layers:

- `*_test.mbt` black-box tests validate only the public API and are mandatory for every public package.
- `*_wbtest.mbt` and inline tests cover internal invariants, parsers, checked arithmetic, and representation logic.
- Snapshot tests are appropriate for structured diagnostics and small deterministic textual forms. Binary image expectations should use checked fixture bytes or digests plus semantic assertions, not opaque snapshots alone.
- Literate `.mbt.md` and `mbt check` examples should be used for public API documentation; document tests are black-box tests.
- Conformance fixtures and adversarial limit tests live in repository-level `fixtures/`, with provenance/license metadata; packages should consume them through test helpers rather than embed large duplicated data.

Run branch coverage on the native target initially:

```powershell
moon test --target native --enable-coverage --frozen
moon coverage report -f cobertura
```

Coverage is a diagnostic and trend signal, not the acceptance definition. For parsing and conversion code, require boundary, property/metamorphic, known-vector, differential, and resource-limit tests even when line/branch coverage is high.

Use built-in benchmark blocks (`test (b : @bench.T)`) and execute performance gates with `moon bench --target native --release --frozen`. CI should compile benchmarks on every PR but run comparative measurements on a pinned runner or scheduled dedicated host; shared hosted runners are too noisy for regression thresholds. Every result must record toolchain version, target, optimization mode, OS/architecture, input corpus, and iteration statistics.

Sources: [Writing Tests](https://docs.moonbitlang.com/en/stable/language/tests.html), [Comments and Documentation](https://docs.moonbitlang.com/en/latest/language/docs.html), [Measuring code coverage](https://docs.moonbitlang.com/en/stable/toolchain/moon/coverage.html), [Writing Benchmarks](https://docs.moonbitlang.com/en/latest/language/benchmarks.html).

## CI and release pipeline

Use GitHub Actions with a pinned MoonBit toolchain, but treat the setup action as third-party infrastructure. The official MoonBit curated list points to `hustcer/setup-moonbit`; pin its full commit SHA in production workflows, pass the exact toolchain version `0.1.20260713+75c7e1f` if accepted by the action, and print `moon version`, `moonc -v`, and `moonrun --version` at the start of every job. Verify the exact accepted version syntax during CI implementation; if the action cannot install the exact build, use the official installer in a cacheable bootstrap job and fail when the resulting version differs from the policy file.

Recommended jobs:

1. **quality:** `moon fmt --check`, `moon check --target all --deny-warn --frozen`, `moon info --frozen`.
2. **test matrix:** Ubuntu, Windows, and macOS for `native`; Ubuntu for `wasm`, `wasm-gc`, and `js`. Promote all OS/target combinations only when backend behavior or native stubs justify the cost.
3. **coverage:** native/Linux Cobertura artifact and trend reporting.
4. **package dry run:** per member, `moon -C modules/<name> package --frozen --list`; inspect that fixtures, generated artifacts, credentials, and unrelated modules are excluded.
5. **bench build:** `moon bench --target native --release --build-only --frozen`; scheduled benchmarks run separately.

Publication should be a protected, tag-driven, manual-approval workflow. Before publishing a module: ensure the module's SemVer increased, changelog exists, workspace dependency versions are aligned with `moon work sync`, the repository tag identifies the module and version (for example `mnf-core-v0.1.0`), package dry-run passes, and then execute `moon -C modules/core publish --frozen`. Never run publication from pull-request code or expose mooncakes credentials to forked workflows.

Moon's package manager follows Semantic Versioning and minimal version selection. Therefore each module must declare the lowest dependency version it actually supports and test against that resolved graph; do not use unconstrained/latest dependencies in release manifests.

Sources: [official MoonBit curated tooling list](https://github.com/moonbitlang/awesome-moonbit), [Moon command reference](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html), [Use and publish packages](https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html), [official download instructions](https://www.moonbitlang.com/download/).

## Dependency policy

Keep the v0.1 dependency graph intentionally small:

```text
mnf-core
└── moonbitlang/core only

mnf-color
├── mnf-core
└── moonbitlang/core

mnf-image
├── mnf-core
├── mnf-color
└── moonbitlang/core
```

Prefer the standard library before adding ecosystem modules. Any new external dependency requires a short decision record covering license, supported targets, maintenance status, transitive graph, native code, and whether MNF can expose it without leaking its API. Import core packages explicitly in `moon.pkg` where required; current documentation warns that ordinary aliases such as `@json` and `@test` should import their corresponding `moonbitlang/core/...` packages rather than relying on implicit availability (the prelude is the exception).

## Immediate implementation checklist

1. Decide the mooncakes.io owner/namespace before creating publishable module names.
2. Add a checked-in toolchain policy containing the exact three verified versions above.
3. Initialize `moon.work` with three module members and JSON module manifests.
4. Set Native as preferred; declare exact four-backend support for portable packages and native-only support for adapters.
5. Establish root commands for format, check, test, info, coverage, package dry-run, and benchmark build.
6. Add black-box API tests before stabilizing any public type; use white-box tests for invariants.
7. Keep FFI absent from the first portable contracts. The first native stub must trigger a separate adapter package and FFI review checklist.
8. Re-evaluate the compatibility floor and `moon.mod` format at the v0.1 release candidate, not opportunistically mid-phase.

## Confidence and watch items

| Topic | Confidence | Watch item |
|---|---|---|
| Workspace and publication unit | High | Workspace commands are current and locally present |
| Four required production targets | High | `--target all` behavior is explicitly documented and locally exposed |
| Native FFI rules | High | Ownership default is actively migrating; explicit annotations are mandatory |
| `moon.mod.json` over `moon.mod` | Medium | Revisit after rollout flags disappear and compatibility floor is chosen |
| Exact CI installation method | Medium | Third-party action must be SHA-pinned and exact-version syntax verified during workflow implementation |
| Registry module names | Low until governance decision | mooncakes owner/organization is unresolved |

