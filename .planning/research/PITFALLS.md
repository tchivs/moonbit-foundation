# MoonBit Native Foundation: Pitfalls and Failure Modes

**Research date:** 2026-07-16  
**Scope:** MNF architecture, with concrete gates for v0.1 Foundation (`mb-core`, `mb-color`, `mb-image`)  
**Confidence:** High for the v0.1 risks and controls; medium for later PDF/SVG/font details because their implementation designs are intentionally deferred.

## Executive assessment

MNF's largest risk is not failure to implement enough features. It is publishing the wrong foundational contracts and then forcing every later module either to preserve them or to fork them. The v0.1 milestone should therefore optimize for **bounded behavior, explicit representation, target conformance, and reversible APIs**, not breadth or headline benchmark numbers.

The release must be stopped if any of these are true:

- dimensions, strides, offsets, decompressed sizes, or allocation sizes can be computed without checked arithmetic;
- image storage does not state channel order, alpha convention, color space, endianness, ownership, and row-stride rules;
- an FFI function lacks an explicit ownership/lifetime contract and a backend-specific test;
- a package is called portable without executing the same conformance vectors on every claimed target;
- parser defaults allow unbounded allocation, decompression, nesting, object count, or work;
- a stable module is released without a compatibility policy and an independently usable dependency surface.

## Risk map

| Priority | Failure mode | Earliest prevention point | Primary phase |
|---|---|---|---|
| Critical | Unchecked size, stride, and offset arithmetic | `mb-core` API design | Program 1: Foundation |
| Critical | Unbounded processing of hostile formats | Bounded stream/limit contracts | Program 1, enforced in Programs 2-3 |
| High | Toolchain and FFI semantic drift | Reproducible workspace/CI | Program 1 |
| High | Incorrect alpha, transfer, or color-space semantics | `mb-color`/`mb-image` contracts | Program 1 |
| High | Native/Wasm/JS behavioral divergence | Cross-target conformance harness | Program 1 and every later program |
| High | FFI ownership and lifetime bugs | Native adapter policy | Program 1 and Program 4 |
| High | Wrong publication granularity | Repository and release design | Program 1 |
| Medium | Governance and versioning gridlock | RFC and stability policy | Program 1, then continuous |
| Medium | Misleading performance claims | Benchmark policy | Program 1, then continuous |
| Medium | Premature ecosystem breadth | Milestone scope gates | Every program |

## 1. Toolchain and public-API drift

### Failure mode

MNF follows the newest MoonBit toolchain implicitly, uses compiler/runtime behavior as if it were a stable language contract, or exposes representations whose ABI is still unstable. A routine toolchain update then changes FFI ownership behavior, generated C assumptions, warning policy, manifest behavior, or backend results. Consumers cannot reproduce releases, and maintainers either freeze indefinitely or break downstream code unexpectedly.

This is an immediate risk, not a hypothetical one. The current MoonBit FFI documentation says that C and Wasm use reference counting, Wasm-GC and JavaScript reuse host GC, payload-carrying `struct`/`enum` layout is currently unstable, and the default FFI parameter convention is migrating from `#owned` to `#borrow`. Those facts make an unpinned `latest` build and representation-dependent ABI unsafe foundations. [MoonBit FFI documentation](https://docs.moonbitlang.com/en/latest/language/ffi.html)

### Detection signals

- CI starts failing after a toolchain update with no MNF source change.
- Generated public API output changes between toolchain versions.
- Native tests pass while one of `wasm`, `wasm-gc`, or `js` changes results.
- FFI declarations rely on an omitted ownership annotation or compiler default.
- Native adapters pass MoonBit `struct` or `enum` payload layouts directly across the C ABI.
- contributors cannot identify the exact compiler/runtime used to produce a published artifact.

### Prevention

1. Pin exact `moon`, `moonc`, and `moonrun` versions in required CI and record them in release provenance.
2. Add a non-blocking forward-compatibility job for the selected newer toolchain; promote it only after API snapshots and all target tests pass.
3. Require `#borrow`/`#owned` to be explicit on every reference-counted FFI parameter even if a compiler default exists.
4. Use opaque handles and explicit C-compatible scalar/buffer boundaries; never make an unstable MoonBit aggregate layout part of a native ABI.
5. Snapshot documented public APIs and classify diffs before upgrading the compatibility floor.
6. Treat toolchain-floor changes as reviewed compatibility changes, not dependency housekeeping.

### Phase mapping

- **Program 1:** mandatory toolchain policy, API snapshots, explicit FFI lint/review, and upgrade playbook.
- **Programs 2-4:** each new backend-sensitive capability proves compatibility before the pinned floor moves.

## 2. Package granularity and dependency collapse

### Failure mode

The repository becomes either a monolith, where a user needing checked arithmetic pulls image and color code, or a cloud of tiny modules with synchronized releases and circular conceptual dependencies. A physical folder is mistaken for a release boundary. Codec, host adapter, and convenience APIs creep into core modules, making target support and SemVer promises impossible to state independently.

MoonBit distinguishes a project/module from packages inside it, and a module is the unit published to mooncakes.io. Workspaces coordinate multiple modules, but publication remains member-specific. Version selection relies on each module declaring dependency requirements and following Semantic Versioning. [MoonBit packages](https://docs.moonbitlang.com/en/latest/language/packages.html), [workspace support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html), [package publication](https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html)

### Detection signals

- adding a codec requires a release of `mb-core` despite no core contract change;
- `mb-core` imports color/image/domain concepts or contains platform codec glue;
- applications import an umbrella package because individual contracts are not usable;
- most releases bump all modules together, or workspace members frequently contain stale dependency versions;
- a dependency graph contains cycles, optional dependencies masquerading as required ones, or duplicate primitive types;
- a module has no single dominant responsibility describable in one sentence.

### Prevention

1. Make publication, target support, compatibility, and ownership the tests for a module boundary; use packages for cohesive internal subdivision.
2. Keep `mb-core`, `mb-color`, and `mb-image` independently publishable workspace members with acyclic dependencies (`core <- color <- image`, with image also using core).
3. Put codecs and host adapters in opt-in packages/modules so the image model stays portable and lightweight.
4. Run a dependency-boundary test in CI and fail on forbidden imports or cycles.
5. Maintain a small integration fixture that consumes each module alone from its public API.
6. Require an RFC before creating a new top-level module; a new directory alone is not sufficient justification.

### Phase mapping

- **Program 1:** settle the three foundation publication boundaries and release them independently.
- **Programs 2-3:** validate proposed modules against actual dependency pressure before publication.
- **Program 4:** GPU/AI/MCP stay optional adapters and cannot become transitive requirements of lower layers.

## 3. C FFI ownership, lifetime, and thread bugs

### Failure mode

A native adapter leaks, double-frees, retains borrowed memory, drops owned memory twice, invokes callbacks on an unsupported thread, or allows a native library to outlive MoonBit storage. The code often appears correct in short tests and fails under errors, cancellation, asynchronous callbacks, or repeated creation/destruction.

MoonBit's documented owned calling convention makes the callee responsible for dropping parameters; storing a reference requires incrementing it, and external object finalization is C-backend-specific. External types represent pointers but do not receive automatic reference counting. The ongoing move toward borrowed defaults raises the cost of relying on inference. [MoonBit FFI lifetime and calling conventions](https://docs.moonbitlang.com/en/latest/language/ffi.html), [MoonBit ownership attributes](https://docs.moonbitlang.com/en/stable/language/attributes.html)

### Detection signals

- process memory or native handle counts grow during create/use/drop loops;
- crashes appear only on error paths, shutdown, callback, or cancellation;
- a C function stores `Bytes`, `String`, `FixedArray`, or abstract data without an explicit retain/release pair;
- an `#external` value has no documented destructor owner;
- FFI tests exercise return values but not lifetime, repetition, failure injection, or concurrency;
- native code receives a pointer into movable/temporary storage beyond the call duration.

### Prevention

1. Every adapter gets an ownership table covering parameters, return values, retained state, finalizer, callback thread, and error cleanup.
2. Wrap foreign resources in one opaque owner with idempotent close semantics; distinguish borrowed views from owned buffers in names and types.
3. Keep FFI calls leaf-like and small; copy at uncertain lifetime boundaries rather than exposing long-lived raw pointers.
4. Add stress tests for repeated allocation/release, injected native failures, callback teardown, cancellation, and process exit.
5. Run native sanitizers or leak tooling on C stubs when the build permits it, while retaining MoonBit-level lifecycle tests as the required gate.
6. Never claim a portable package based on a native adapter; split portable contracts from the adapter package.

### Phase mapping

- **Program 1:** define the FFI contract template and prove it with any initial file/codec adapter.
- **Programs 2-3:** apply it to font, image, and document integrations.
- **Program 4:** re-audit thread/device/callback lifetimes for GPU and AI runtimes.

## 4. Image and color correctness that looks visually plausible

### Failure mode

Pixels look acceptable in one viewer but are mathematically wrong. Typical causes are treating encoded sRGB samples as linear light, applying transfer functions to alpha, mixing straight and premultiplied alpha, ignoring profile precedence, losing precision during repeated conversions, silently swapping channel order, or assuming all untagged images have the same color meaning. Visual spot checks miss these errors, and downstream compositing bakes them into every later graphics and PDF API.

The PNG Third Edition states that alpha is a linear fraction of opacity and is not gamma-corrected. It also defines precedence among color signaling (`cICP`, `iCCP`, `sRGB`, then `cHRM`/`gAMA`). These are examples of semantics that must be represented explicitly rather than inferred from an `RGBA` label. [W3C PNG Third Edition, color spaces and alpha](https://www.w3.org/TR/png-3/)

### Detection signals

- compositing produces dark or bright fringes around translucent edges;
- encode/decode or straight/premultiplied round trips drift more than declared tolerances;
- the same fixture differs from a trusted reference implementation or across targets;
- API names say `RGBA8` without defining byte order, transfer function, alpha representation, or color space;
- ICC/sRGB/gamma metadata is discarded or contradictory metadata is accepted without a defined precedence/error;
- tests compare screenshots by eye or exact bytes where a numeric/colorimetric tolerance is required.

### Prevention

1. Make channel order, component encoding, bit depth, transfer function, alpha mode, color-space identity, and endianness explicit in the type/descriptor contract.
2. Define CPU reference operations in linear-light terms where appropriate and specify exactly when encode/decode transfer functions occur.
3. Keep alpha separate from color transfer; add canonical tests for transparent colors, zero alpha, full alpha, and premultiply/unpremultiply edge cases.
4. Use standards-derived vectors plus differential tests against at least two mature implementations when licensing permits.
5. Test invariants and error bounds: identity, monotonicity, neutral-axis preservation, round trips, clipping, NaN/non-finite handling, and multiple bit depths.
6. Preserve unknown or unsupported metadata deliberately, or emit a structured diagnostic; never silently reinterpret it.

### Phase mapping

- **Program 1:** blocking for `mb-color` and `mb-image`; publish no stable image representation without these contracts.
- **Programs 2-3:** canvas blending, SVG paint, PDF color, and rendering reuse the same conformance suite.
- **Program 4:** accelerated paths must match CPU reference semantics within declared tolerances.

## 5. Untrusted-format parsing and asymmetric resource use

### Failure mode

A small input triggers huge allocation, decompression, recursion, object creation, reference resolution, CPU work, or repeated seeks. The parser may be memory-safe yet still be an effective denial-of-service primitive. Later SVG, font, and PDF work magnifies this risk through nested structures, filters, object graphs, and external resources.

OWASP explicitly recommends size limits that account for the result after decompression and identifies parser exploits and decompression bombs as file-processing threats. [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html), [OWASP malicious-file testing](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/10-Business_Logic_Testing/09-Test_Upload_of_Malicious_Files)

### Detection signals

- a parse API has no `Limits`/budget parameter and defaults to available memory;
- compressed size is checked but expanded bytes, pixels, nodes, objects, nesting, or work are not;
- malformed input causes panic/process termination rather than a structured failure;
- parsing requires buffering the whole file even when streaming is possible;
- cancellation is checked only between files, not during long decode/resolve loops;
- corpus tests contain malformed syntax but no resource-exhaustion fixtures.

### Prevention

1. Define a shared, safe-by-default resource-budget model in `mb-core`: input bytes, output bytes, allocation total, dimensions, object/node count, nesting/recursion, decompressed bytes, work units, seeks, and optional deadline/cancellation.
2. Charge budgets monotonically before allocation or work; do not refund them in a way that enables repeated amplification.
3. Separate syntax parsing from resource fetching, decompression, rendering, and filesystem/network access.
4. Return structured limit-exceeded errors that identify the budget, never partial success that downstream code mistakes for a complete document.
5. Add adversarial fixtures for truncation, cycles, deeply nested input, high compression ratio, repeated references, duplicate metadata, and pathological dimensions.
6. Fuzz when the toolchain permits, but do not wait for fuzzing: property, mutation, corpus, differential, and strict budget tests are v0.1 requirements.

### Phase mapping

- **Program 1:** bounded readers/writers and the common budget/error contract.
- **Program 2:** mandatory for SVG and font parsing before feature completeness.
- **Program 3:** mandatory for every PDF/filter/image codec path, with parser and renderer budgets tested separately.

## 6. Integer, stride, plane, and size overflow

### Failure mode

`width * bytes_per_pixel`, `stride * height`, plane offsets, chunk lengths, decompressed lengths, or FFI narrowing wrap or truncate. The result can under-allocate storage, accept overlapping planes, read beyond input, loop indefinitely, or bypass a resource limit. Signed/unsigned conversion and negative stride add further ambiguity.

MITRE classifies overflow in allocation, copying, offset, and concatenation calculations as security-critical; its examples include oversized image dimensions leading to incorrect allocation and downstream memory corruption or denial of service. [CWE-190: Integer Overflow or Wraparound](https://cwe.mitre.org/data/definitions/190.html)

### Detection signals

- raw `+` or `*` combines any untrusted dimension, length, stride, offset, count, or element size;
- size validation occurs after allocation or after narrowing to a C integer type;
- tests cover maximum individual fields but not their products/sums;
- image views allow `offset + (height - 1) * stride + row_bytes` without one canonical checked validator;
- negative dimensions/strides or zero-sized images have undocumented semantics;
- native and Wasm builds use different integer widths or casts at boundaries without explicit range checks.

### Prevention

1. Put checked add, multiply, align, cast, range, and slice computations in `mb-core`; format code must not reimplement them casually.
2. Validate in a wide, non-negative size domain before narrowing; check both arithmetic representability and configured resource budgets.
3. Centralize image-layout validation, including zero dimensions, row bytes, stride sign/policy, plane count, last reachable byte, overlap, alignment, and total allocation.
4. Test boundary neighborhoods, not just maxima: `max-1`, `max`, `max+1`, products near overflow, and mixed zero/huge fields.
5. Check all values again at FFI boundaries against the exact C ABI type and library limit.
6. Make invalid layout construction impossible through public constructors; do not rely on codec authors to remember every invariant.

### Phase mapping

- **Program 1:** critical exit gate for `mb-core` and `mb-image`.
- **Programs 2-4:** reuse the same helpers for path counts, glyph tables, object offsets, texture sizes, and tensor shapes.

## 7. Cross-target semantic divergence

### Failure mode

Code compiles on every target but does not mean the same thing. Native becomes the de facto specification while JS/Wasm receive different overflow, floating-point edge, ownership, scheduling, filesystem, or error behavior. Golden files are produced by one backend and merely consumed by the others, so shared bugs or nondeterminism go unnoticed.

MoonBit currently targets `wasm`, `wasm-gc`, `js`, and `native`; memory management differs across those families, so target support has to be demonstrated rather than inferred from shared source. [MoonBit backend overview](https://docs.moonbitlang.com/en/latest/), [MoonBit FFI documentation](https://docs.moonbitlang.com/en/latest/language/ffi.html)

### Detection signals

- CI runs `check` on portable targets but tests only Native;
- serialization, error variants, hashes, or rendered pixels differ by target without a documented allowance;
- core packages use host filesystem, wall clock, locale, environment, or global mutable state directly;
- tests depend on map iteration order, platform paths, native endianness, or unspecified floating-point formatting;
- backend-specific files contain algorithm logic rather than narrow capability adapters;
- a bug fix is guarded by a target conditional instead of correcting the shared contract.

### Prevention

1. Run identical conformance vectors and public examples on every claimed target; compiling is not target support.
2. Define canonical byte order, numeric conversions, serialization, error taxonomy, and deterministic ordering in lower-layer contracts.
3. Inject filesystem, clock, randomness, cancellation, and host capabilities through explicit adapters.
4. Compare target-produced normalized artifacts against a checked-in normative fixture, and add cross-target differential jobs.
5. Separate exact invariants from tolerance-based floating-point/rendering comparisons; record the tolerance rationale.
6. Downgrade a package's advertised target matrix immediately when conformance cannot be maintained.

### Phase mapping

- **Program 1:** establish the harness and use `mb-core`, `mb-color`, and `mb-image` as proof.
- **Programs 2-4:** every new module declares its target matrix and earns each target independently.

## 8. Benchmark misuse and performance theater

### Failure mode

MNF optimizes toy loops, compares unlike workloads, reports the best run, hides allocation or conversion costs, or changes correctness for a headline speedup. A benchmark becomes an API-design driver before representative consumers exist. Results are not reproducible because hardware, toolchain, build mode, inputs, warmup, repetition, and variance are absent.

Established benchmark rules emphasize that a result is an observation under stated conditions and that reporting must be meaningful, comparable, and reproducible. [SPEC CPU 2026 run rules](https://www.spec.org/cpu2026/docs/runrules.html), [IETF RFC 8239 benchmarking methodology](https://www.rfc-editor.org/info/rfc8239/)

### Detection signals

- a PR claims “faster” without raw data, baseline commit, environment, or correctness comparison;
- only minimum/best time is reported, with no repetitions or dispersion;
- benchmark setup excludes costs that the public API necessarily imposes;
- fixtures are tiny, compress unusually well, or represent only one pixel format;
- results from different targets, hardware, toolchains, or build modes appear in one ranking;
- microbenchmark gains increase allocations, memory footprint, tail latency, or output error elsewhere.

### Prevention

1. Version the benchmark corpus and record toolchain, commit, target, build flags, CPU/OS, workload parameters, repetitions, warmup policy, and raw samples.
2. Report median plus dispersion/percentiles and allocation/peak-memory data where relevant; never publish only the best run.
3. Pair every performance test with a correctness oracle and resource-limit assertion.
4. Maintain separate microbenchmarks, representative pipelines, and adversarial/worst-case workloads; do not generalize across them.
5. Compare only like-for-like semantics, including color conversion, validation, allocation ownership, and output quality.
6. Treat early v0.1 measurements as baselines for regression detection, not competitive marketing claims.

### Phase mapping

- **Program 1:** define the benchmark manifest and baseline a few core operations only.
- **Programs 2-3:** add end-to-end rendering/document workloads after real pipelines exist.
- **Program 4:** require CPU reference correctness before claiming accelerator wins.

## 9. Governance, stability labels, and versioning deadlock

### Failure mode

Everything remains “experimental” forever, or draft APIs become stable by widespread use without an explicit decision. Conversely, maintainers use a major-version bump to excuse avoidable churn. Cross-module releases become inconsistent, RFC decisions have no owner, and downstream users cannot tell whether a behavior is guaranteed or incidental.

MoonBit publication uses `MAJOR.MINOR.PATCH`, and its minimal version selection assumes that modules declare their requirements and follow Semantic Versioning. Breaking a low-level module therefore has dependency-graph consequences beyond one repository. [MoonBit package publication and SemVer](https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html), [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)

### Detection signals

- there is no named decision maker or deadline for moving RFC 0001 from Draft;
- “stable,” “experimental,” and “internal” are not machine- or documentation-visible;
- public symbols disappear or change semantics without an API-diff review and migration note;
- modules publish incompatible dependency ranges or require lockstep upgrades without stated reason;
- rejected designs and compatibility decisions are discussed repeatedly because no decision record exists;
- convenience APIs grow faster than tested primitive contracts.

### Prevention

1. Define RFC states, required reviewers, decision authority, response windows, and an appeal/revision path before accepting RFC 0001.
2. Give every public API an explicit stability class; stable API changes require an API diff, SemVer classification, migration note, and downstream fixture test.
3. Keep module changelogs and compatibility floors independent, with a release manifest recording the tested set.
4. Establish a short deprecation policy and a security exception path; do not promise indefinite compatibility before community validation.
5. Record rejected alternatives and rationale in RFCs so implementation cannot silently reopen architecture.
6. Publish compatibility tests as reusable artifacts where practical, so alternate implementations can validate the contract.

### Phase mapping

- **Program 1:** blocking governance deliverable and release policy.
- **Programs 2-4:** RFC gate for new top-level modules and any breaking lower-layer boundary.

## 10. Premature breadth and foundation-by-checklist

### Failure mode

The project tries to demonstrate canvas, SVG, fonts, PDF, GPU, AI, and MCP before proving the three foundation contracts. Each module exists, but none is dependable. Thin wrappers create impressive demos while forcing unstable pixel, stream, color, and error types into public use. Maintainer attention fragments, and defects in the lowest layer multiply across every downstream prototype.

### Detection signals

- roadmap progress is measured by package count, format count, or demo count rather than exit criteria;
- Program 2 implementation lands while v0.1 still has unresolved ownership, layout, or target-conformance questions;
- the same primitive is duplicated because the foundation API is not ready;
- more than one reference codec is pursued before the codec boundary and limits are validated;
- GPU/AI work changes `mb-image` storage semantics instead of adapting to a CPU reference model;
- documentation promises future modules as if they were committed compatibility contracts.

### Prevention

1. Enforce the RFC's v0.1 exit condition: coherent models, bounded operations, target-aware CI, conformance fixtures, docs, and reproducible baselines—not skeletons.
2. Use one minimal reference codec/fixture adapter to test the image boundary; defer format breadth.
3. Require at least two small independent consumer examples for a candidate stable primitive before freezing it.
4. Keep later module documents as boundary proposals until foundation contracts are validated in use.
5. Set explicit work-in-progress limits and stop new-module work when critical foundation defects remain.
6. Prefer deleting or redesigning an experimental API over preserving it merely because a demo already uses it.

### Phase mapping

- **Program 1:** strict scope limited to RFC/process, repository contract, `mb-core`, `mb-color`, and `mb-image`.
- **Program 2:** starts only after Foundation exit gates pass; delivers one headless reference pipeline before breadth.
- **Program 3:** starts only after graphics contracts survive real fixtures.
- **Program 4:** remains optional and cannot redefine lower layers without an RFC.

## Required phase gates

### Program 1: Foundation

- Exact required toolchain pin plus forward-compatibility lane.
- Public API snapshot and stability classification.
- Checked arithmetic and canonical image-layout constructor tests.
- Shared resource-budget and structured limit-error contracts.
- Explicit image/color representation and standards-derived conformance vectors.
- Identical tests on every advertised target, not check-only jobs.
- FFI ownership table and lifecycle stress test for every native stub.
- Independently consumable workspace modules with an acyclic dependency check.
- Benchmark manifest and raw baseline data; no comparative marketing claim.
- Accepted RFC/governance and release/compatibility policy.

### Program 2: Graphics

- Foundation gates remain green against the current supported toolchain floor.
- Canvas/SVG/font/text parsers and rasterizers inherit budgets and structured errors.
- Headless CPU reference rendering provides the semantic oracle.
- Golden/differential fixtures cover alpha, color, clipping, transforms, text boundaries, and hostile nesting.
- No window system, GPU, filesystem, or network dependency leaks into portable contracts.

### Program 3: Documents

- Parser, decompressor, resolver, and renderer have separate enforceable budgets.
- Offset/xref/object/stream arithmetic uses shared checked helpers.
- Generation-only use does not pull parsing/rendering dependencies.
- Adversarial, corpus, differential, and cancellation tests are release gates.
- Representative end-to-end benchmarks report memory and tail behavior as well as throughput.

### Program 4: Advanced

- CPU reference behavior remains normative for GPU/AI accelerated operations.
- Device/model/native resources have explicit owner, thread, cancellation, and teardown contracts.
- GPU, AI, MCP, and Wasm optimization remain optional modules/adapters.
- Acceleration or integration cannot change a lower-layer stable contract without a new RFC and migration plan.

## Practical review checklist

Before accepting any new primitive or module, reviewers should be able to answer:

1. What exact representation and invariants are public?
2. Which inputs control allocation, offsets, recursion, decompression, or work, and where are they checked?
3. Who owns each buffer/resource across every FFI call and failure path?
4. Which targets run the same behavioral tests, and what differences are explicitly allowed?
5. What standard, fixture, property, or independent implementation is the correctness oracle?
6. Can a consumer use this module without unrelated formats, host runtimes, or future layers?
7. What API stability class applies, and what would a breaking change require?
8. Is a performance result reproducible, representative, and paired with correctness/resource evidence?
9. Which roadmap exit criterion does this work satisfy?
10. What is deliberately deferred so the current contract can be validated first?

If any answer is “implicit,” “platform-dependent,” or “we will add limits/tests later,” the API is not ready to become a foundation contract.
