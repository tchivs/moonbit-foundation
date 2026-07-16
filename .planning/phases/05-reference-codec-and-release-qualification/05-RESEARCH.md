# Phase 5: Reference Codec and Release Qualification - Research

**Researched:** 2026-07-17
**Domain:** bounded streaming PPM P6 codec, evidence, benchmarks, and MoonBit release qualification
**Confidence:** HIGH for local architecture and pinned-tool behavior; MEDIUM for current official web documentation

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Strict PPM P6 subset

- **D-01:** Implement PPM P6 as a focused portable package under `mb-image`, conforming to the existing prefix/Reader/Writer codec contracts rather than introducing a parallel API.
- **D-02:** The accepted subset is binary P6 with positive decimal width/height, `maxval` exactly `255`, and exactly `width * height * 3` RGB bytes. Decoded output is packed tight encoded-sRGB `Rgb8`, TopLeft, built-in sRGB, no alpha.
- **D-03:** Header parsing accepts ASCII whitespace and `#` comments only where the documented PPM grammar permits them. Numeric tokens are ASCII decimal only: no sign, leading plus, hexadecimal, locale digits, empty token, or overflow.
- **D-04:** Enforce explicit header byte, token byte, comment byte/count, width, height, pixel, payload, allocation, and work limits. A header that exceeds any declared limit fails before image allocation or payload work.
- **D-05:** Decode consumes exactly one image and then probes one byte for EOF. Truncated payload and trailing bytes are structured failures. This strict single-image subset deliberately rejects concatenated PPM streams.
- **D-06:** The encoder emits one canonical form: `P6\n<width> <height>\n255\n` followed by tightly packed logical RGB bytes, with no comments, padding, profile payload, alpha, or orientation ambiguity.
- **D-07:** Encoding accepts only supported packed TopLeft encoded-sRGB `Rgb8`. Other formats/layouts/orientations/profiles requiring interpretation fail with `CapabilityUnavailable`; callers must invoke explicit Phase 4 operations first.

### Streaming, budgets, and diagnostics

- **D-08:** Decode parses incrementally through `Reader`, never requiring `Seeker`, filesystem access, or whole-input buffering. Payload is copied directly into one owned image through its callback-scoped mutable seam.
- **D-09:** All arithmetic uses checked full-width operations. Descriptor validation and combined allocation/pixel/work charging occur once before payload mutation. Parser work and output work have explicit charges; failures preserve the documented budget state.
- **D-10:** Short progress, zero progress, EOS, malformed header, invalid token, unsupported maxval, overflow, budget rejection, truncated payload, and trailing data produce stable structured errors/diagnostics with bounded context, never prose-only classification.
- **D-11:** Encode streams header and rows through `Writer`/`write_all`, handles partial progress, and never exposes row padding. Writer failure and no-progress retain exact completed-count diagnostics.

### Evidence and examples

- **D-12:** Register provenance for a minimal official-spec-derived corpus plus clearly labeled project-derived adversarial cases. Generated MoonBit tables must be deterministic, package-local, consumer-linked, formatter-clean, and reproducible with `-Check`.
- **D-13:** Conformance covers canonical decode/encode, decode-encode canonicalization, encode-decode semantic identity, chunk-boundary independence, short-progress I/O, and metamorphic transform pipelines. Fuzzing infrastructure is not required for v0.1.
- **D-14:** Provide two executable public examples: a portable in-memory stream→image→transform→stream example on all four targets, and a Native CLI-shaped adapter that receives explicit Reader/Writer/options rather than opening ambient paths itself.
- **D-15:** Examples use only public APIs and perform a meaningful Phase 4 transform before encoding. They are qualified as standalone consumers so private/package-internal imports fail closed.

### Documentation and benchmark evidence

- **D-16:** Every candidate module has runnable API documentation, examples, exact target/support matrix, compatibility status, changelog, fixture provenance links, and explicit deferred scope. Documentation must not claim stable APIs or production codec coverage.
- **D-17:** Benchmark evidence is a reproducible harness plus checked baseline record containing exact toolchain, commit, target, optimization mode, OS/runtime/hardware, corpus digests, warmup/repetition counts, raw samples, aggregate/variance, correctness checks, and timestamp.
- **D-18:** Benchmark thresholds detect catastrophic regression only; noisy hosted results are informational and never marketing claims. Research/planning chooses conservative workloads and tolerance rules that are runnable on this machine and portable where meaningful.

### Independent release qualification

- **D-19:** Qualify modules independently in topological order `mb-core` → `mb-color` → `mb-image`. Each module must pass its own format/check/test/docs/interface/package-content/target matrix without importing unrelated higher layers.
- **D-20:** Build package artifacts/dry-run publication contents and verify exact manifests, semantic versions, compatibility status, licenses, provenance, checksums, dependency constraints, and absence of workspace-only/path substitutions.
- **D-21:** Create clean temporary external consumer fixtures outside workspace resolution for each module and for the full stack. Prefer locally packed artifacts or an isolated registry/cache mechanism supported by the pinned toolchain; do not publish to a real registry during qualification.
- **D-22:** If the pinned MoonBit toolchain cannot install local packed artifacts without workspace substitution, research must select the strongest deterministic dry-run proof: inspect exact pack contents plus copy artifacts/modules into an isolated consumer root with workspace disabled. The limitation must be recorded, not hidden.
- **D-23:** Release qualification is read-only with respect to tracked source after generation checks and produces machine-readable reports/digests. Publishing remains an explicit later human action.
- **D-24:** The phase closes only after two complete Required runs from a clean committed baseline and independent phase verification maps WORK-06 and QUAL-01..06 to executable evidence.

### Scope exclusions

- **D-25:** Defer PNG/JPEG/WebP, 16-bit PPM, ASCII P3, multi-image PPM, arbitrary maxval scaling, animation, filesystem codecs, registries, network publishing, signed releases, performance marketing, LLVM claims, and v2 graphics/document modules.

### the agent's Discretion

- Exact package/type names, bounded parser state representation, fixture case IDs, benchmark workload sizes, report file formats, isolated-consumer mechanics supported by the pinned toolchain, and plan decomposition.

### Deferred Ideas (OUT OF SCOPE)

- Real registry publication, signed artifacts/releases, production codec libraries, wider PPM variants, and benchmark claims remain outside v0.1 qualification.
</user_constraints>

## Summary

Phase 5 should add one `ppm` package beneath `mb-image`, implemented as a forward-only finite-state parser over the existing `Reader`, followed by a strict payload phase and an explicit one-byte EOF probe. The official Netpbm specification supports the locked binary layout and documents a minimal single-image, `maxval=255` subset. It also exposes an important naming constraint: full PPM permits multiple images and defines BT.709-like sample semantics, while sRGB is a common variation. Therefore documentation should call this the **MNF strict PPM P6/sRGB subset**, not claim full colorimetric PPM conformance. [CITED: https://netpbm.sourceforge.net/doc/ppm.html] [CITED: https://netpbm.sourceforge.net/doc/pbm.html]

The existing code already supplies the hard parts that must remain authoritative: checked arithmetic, atomic hierarchical budget charges, callback-scoped mutable image access, exact partial-progress I/O, stable errors/diagnostics, and codec results. The new codec should compose these rather than duplicate them. The parser may retain only bounded scalar state and one-byte input progress; after the header is completely validated, construct a tight `Rgb8` descriptor, allocate once through `OwnedImage::new_operation`, fill directly through `with_mut_view`, and then probe EOF.

The pinned toolchain can reproducibly create and list package ZIPs, but it cannot qualify unpublished dependency resolution from those ZIPs. Local experiments found that `moon install` accepts local paths only for `is-main` packages, rejects library ZIPs, and isolated `mb-color`/`mb-image` fail because `moonbit-foundation/*` is not in the registry. `moon publish --dry-run` exists but still requires `~/.moon/credentials.json`. The strongest honest v0.1 proof is therefore: deterministic package-list/ZIP/hash inspection; isolated no-`moon.work` consumer checks for `mb-core`; isolated copied-module/public-consumer checks plus exact dependency-manifest inspection for downstream modules; and an explicit machine-readable `registry_resolution: blocked_unpublished_namespace` result. Never mutate manifests to path dependencies to make the gate pass.

**Primary recommendation:** plan horizontally in this order: PPM package and parser → canonical encode/evidence → public examples/docs → benchmark harness → topological release qualification/reporting → two clean Required runs.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| P6 probe/header state machine | `mb-image/ppm` portable package | `mb-core/io`, checked/error | The codec owns grammar; core owns progress and safety contracts. |
| Image allocation and payload fill | `mb-image/storage` public seam | `mb-image/ppm` | Descriptor-derived atomic allocation remains centralized in storage. |
| Canonical encoding | `mb-image/ppm` portable package | codec + core Writer | Codec owns P6 bytes; Writer owns partial-progress behavior. |
| Corpus and metamorphic evidence | repository fixtures + package-local generated table | PPM package tests | Provenance stays repository-wide while portable tests avoid filesystem I/O. |
| Examples | standalone public-consumer packages | README literate tests | Examples must prove only public APIs are needed. |
| Benchmarks | repository qualification tooling | public codec/ops APIs | Benchmark policy is release evidence, not public runtime behavior. |
| Packaging and release reports | root PowerShell qualification tooling | `moon package`, policy JSON | Cross-module ordering and artifact inspection belong outside portable packages. |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| WORK-06 | Qualify each module independently and in dependency order without unrelated layers. | Topological module commands, isolated no-workspace checks, closed package lists, and explicit unresolved-registry limitation. |
| QUAL-01 | Strict bounded public PPM P6 decode/encode with structured failures. | State machine, pre-allocation validation, atomic charge, exact payload, EOF probe, canonical writer. |
| QUAL-02 | Native CLI-shaped and portable in-memory public examples. | Adapter packages receive Reader/Writer; portable example uses memory streams and a Phase 4 transform. |
| QUAL-03 | Black-box, invariant, conformance, adversarial, property/metamorphic evidence. | Generated corpus, chunk schedules, short-progress doubles, canonicalization and transform relations. |
| QUAL-04 | Runnable docs, examples, matrices, changelogs, fixture provenance. | Existing literate README and root quality patterns extended with exact release-candidate claims. |
| QUAL-05 | Reproducible benchmark baselines with environment, raw samples, variance, correctness. | Official `moon bench`, repeated release/native runs, captured summaries, digests, checked JSON record. |
| QUAL-06 | Package contents, external resolution, targets, independence, metadata, provenance, order. | `moon package --frozen --list`, deterministic ZIP/hash checks, isolated checks, and fail-closed report schema. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Use MoonBit for core algorithms and keep portable packages free of ambient host/filesystem state.
- Preserve the acyclic rootless package DAG and exact declared dependencies.
- Use graph discovery before text search when graph tools are available; this session had no callable code graph and used focused source reads.
- Prefer black-box public tests, white-box invariant tests, deterministic generated evidence, and exact four-target qualification.
- Keep FFI out of this phase; the codec is portable on `js`, `wasm`, `wasm-gc`, and `native`.
- Enter changes through GSD workflows; this research is a `gsd-phase-researcher` artifact.

## Standard Stack

| Component | Verified version/source | Purpose | Required use |
|---|---|---|---|
| `moon` | `0.1.20260713 (75c7e1f)` [VERIFIED: local CLI] | build, test, docs, benchmark, package | Pin exactly; always use `--frozen`; record full version output. |
| `moonc` | `v0.10.4+2cc641edf` [VERIFIED: project policy] | compilation | Record identity in qualification/benchmark reports. |
| `mb-core/io` | current Phase 2 public contract [VERIFIED: local source] | Reader/Writer, `read_exact`, `write_all`, memory/short-progress doubles | Do not introduce a second stream abstraction. |
| `mb-core/checked`, `budget`, `error` | current Phase 2 public contracts [VERIFIED: local source] | overflow, atomic charges, stable failures | All parser sizes and charges flow through these packages. |
| `mb-image/model`, `storage`, `codec`, `ops` | current Phase 4 public contracts [VERIFIED: local source] | descriptor, owned image, codec traits/results, meaningful transform | PPM is a focused adapter over these APIs. |
| Netpbm PPM/PBM specs | updated 2025-11-07 [CITED: https://netpbm.sourceforge.net/doc/ppm.html] | grammar and minimal subset | Cite in fixture provenance and subset documentation. |

No external package is needed or allowed. There is no package-legitimacy audit because the phase installs no dependency.

## Architecture Patterns

### Data flow

```text
prefix -> probe(P6/NeedMore/NoMatch)
Reader -> bounded byte pull -> header state machine
       -> checked dimensions/payload -> limits + one atomic image charge
       -> OwnedImage.with_mut_view -> exact raster fill
       -> one-byte EOF probe -> DecodeResult

ImageView -> capability validation -> canonical header -> write_all
          -> logical RGB rows only -> EncodeResult

Public examples -> decode -> Phase 4 transform -> encode
Release tool -> module matrix -> package list/ZIP/hash -> isolated checks -> JSON report
```

### Recommended project structure

```text
modules/mb-image/ppm/                 # concrete portable ImageDecoder/ImageEncoder
modules/mb-image/examples/portable/   # all-target in-memory public consumer
modules/mb-image/examples/native_cli/ # native adapter, injected streams only
fixtures/ppm/                         # generated corpus description/cases
scripts/fixtures/Generate-PpmVectors.ps1
benchmarks/                           # public-API benchmark package and checked baseline
scripts/quality/Invoke-ReleaseQualification.ps1
release/qualification/                # schema + checked v0.1 report/baseline
```

Package names may change, but keep examples out of the PPM implementation package and do not add a root facade.

### Pattern 1: explicit parser transitions

Use closed states such as `MagicP`, `Magic6`, `BeforeWidth`, `Width`, `BeforeHeight`, `Height`, `BeforeMaxval`, `Maxval`, `RasterSeparator`, `Payload`, `RequireEof`, `Done`. A transition consumes exactly one byte or returns an I/O outcome. Count total header bytes on every pre-payload byte, token bytes on every digit, and comment bytes/count independently. Comments are valid only before the whitespace byte that ends the header; once that delimiter is consumed, every byte is raster data. [CITED: https://netpbm.sourceforge.net/doc/pbm.html]

Numeric accumulation must be `value = checked_add(checked_mul(value, 10), digit)`. Reject non-ASCII digits, signs, empty tokens, zero dimensions, and any token/limit overflow immediately. Do not parse to `Int` or use locale/string conversion.

### Pattern 2: validate, charge, allocate, mutate

After maxval and the one raster separator byte:

1. Require `maxval == 255`.
2. Compute `pixels = checked_mul(width, height)` and `payload = checked_mul(pixels, 3)`.
3. Check codec width/height/pixel/input/output/work limits.
4. Build tight packed `Rgb8`, TopLeft, sRGB/no-alpha metadata and descriptor.
5. Call `OwnedImage::new_operation(descriptor, budget, allocator, parser_work + payload_work)` exactly once.
6. Fill inside `with_mut_view`; release/invalidate the lease on every result.
7. Probe exactly one additional byte and require EOS.

If parser work must be charged before the final allocation, use one precomputed upper-bound charge included in the single operation charge; do not incrementally consume the authoritative budget on malformed headers because D-09 requires documented failure-state preservation.

### Pattern 3: canonical encoder

Validate the complete image capability before the first write. Build the small header in bounded owned bytes, then call `write_all` for it and for each logical row subview. Never write `row_stride` bytes. Accumulate `bytes_written` with checked addition and propagate the exact `write_all` completed count on failure. The output is byte-canonical, so repeated encode and decode→encode comparisons use exact bytes/digests.

### Pattern 4: evidence as generated case tables

Keep official-spec-derived structural cases separate from project-derived adversarial cases. Generate a compact MoonBit table consumed by PPM white-box/black-box tests, and make the root generator `-Check` compare exact bytes. Add chunk schedules `[1]`, `[2,1,...]`, header-boundary splits, payload-boundary splits, and deterministic pseudo-random schedules generated from fixed case IDs. The parser result/error code, bytes read, budget delta, diagnostic code/context, and canonical digest are expected fields.

Metamorphic relations:

- `encode(decode(canonical)) == canonical`.
- `decode(encode(image))` has identical logical RGB bytes and descriptor identity.
- Every chunk schedule yields the same result/error and byte count.
- `decode -> flip_horizontal -> flip_horizontal -> encode` equals canonicalized source.
- `decode -> apply_orientation(TopLeft) -> encode` preserves canonical output.
- Appending one byte changes success into the stable trailing-data error.

### Pattern 5: release qualification as data

Produce one deterministic JSON report per module with command, exit code, target, manifest fields, ordered package entries, artifact path, SHA-256, dependency requirements, policy label, and isolated-consumer result. Sort keys/arrays canonically. The runner must snapshot tracked diff before generation checks and confirm no tracked changes afterward.

Pinned-tool observations [VERIFIED: local CLI experiments]:

- `moon package --frozen --list` succeeded for all modules and wrote ZIPs under root `_build/publish`.
- Repacking `mb-core` produced the same SHA-256 (`00f423be76e8c60951965bb92929de814c310113bb739afa2fc24707bddd017d`).
- Package commands warn that `repository` is absent; add canonical repository/description metadata before the release gate.
- `moon publish --frozen --dry-run` fails before packaging without `C:\Users\Admin\.moon\credentials.json`; record this as `blocked_missing_credentials`, never request credentials in Required CI.
- `moon install <library.zip>` rejects the ZIP as not being a module; `moon install <module-path>` rejects libraries without `is-main`.
- A no-workspace isolated `mb-core` check succeeds; isolated `mb-color` and `mb-image` fail because their unpublished dependencies cannot resolve from the registry.

Therefore downstream `registry dependency resolution` cannot honestly pass before namespace verification/publication. QUAL-06 should report the blocked state while still proving exact dependency constraints, packaged contents, no path substitutions, public-consumer compilation against isolated copied sources, and module independence. Publication remains blocked by policy.

## Public Examples

- **Portable example:** a non-root example package imports only public core/image packages, creates `MemoryReader` over canonical PPM bytes, decodes, performs `flip_horizontal` or `resize_nearest`, writes through `MemoryWriter`, and verifies output digest. Check/test on all four targets.
- **Native CLI-shaped example:** expose a function taking `&Reader`, `&Writer`, limits, budget, diagnostics, and selected transform. A tiny native `is-main` wrapper may use explicit host adapters later, but Phase 5 qualification should test the injected function with memory/short-progress doubles. Do not open paths, read argv/environment, or choose codecs inside the library adapter.
- Copy each example fixture into a temporary isolated module outside the repository, with no `moon.work`, and import only public packages. For downstream unpublished dependencies, use an isolated copied source set and mark that this is source isolation rather than registry resolution.

## Benchmark Methodology

Use official `@bench.T` blocks with `b.keep(...)`, `moon bench --release --target native --frozen`, and named workloads. The official harness reports mean, standard deviation, min/max, batch size, and run count; `single_bench` can serialize summary JSON but its `Summary` schema is explicitly not stable. [CITED: https://docs.moonbitlang.com/en/latest/language/benchmarks.html]

Recommended workloads: canonical decode and encode for 64×64, 256×256, and 1024×1024 RGB; one adversarial bounded-header reject; and a full decode→flip→encode pipeline. Before timing, verify expected output SHA-256 and pixel/byte counts. Use one warm-up invocation plus 7 captured benchmark invocations; treat each invocation's mean as a raw sample and preserve the complete raw console/JSON summary. Record median, mean, standard deviation, coefficient of variation, min/max, toolchain identities, git commit, target, release mode, Windows version, CPU model/logical cores, memory, corpus digests, timestamp, and correctness digests.

Set a catastrophic-regression gate only after the baseline exists: recommended `current median <= max(4 × baseline median, baseline median + 5 ms)` and require correctness first. This is deliberately loose, local-machine-only, and not a performance claim. Hosted runners collect informational records without gating.

## Don't Hand-Roll

| Problem | Do not build | Use instead | Reason |
|---|---|---|---|
| Stream progress | ad hoc loops treating zero as EOS | `read_exact`, `write_all`, Reader/Writer outcomes | Existing code preserves partial counts and detects no-progress. |
| Overflow/narrowing | unchecked multiplication or `UInt64 -> Int` | `mb-core/checked` | Header and payload sizes are untrusted. |
| Allocation accounting | separate caller-supplied width/pixels/bytes | descriptor + `OwnedImage::new_operation` | Prevents forged or double charges. |
| Mutable storage | exposed backing array | `with_mut_view` | Lease invalidation and bounds are already enforced. |
| Codec selection | registry/autodetection | explicit `PpmDecoder`/`PpmEncoder` | Registry scope is explicitly deferred. |
| Statistics engine | custom timing math inside portable codec | MoonBit `@bench` plus checked report tool | Keeps runtime API deterministic and evidence reproducible. |
| Local registry emulation | path-dependency manifest rewrites | package inspection + isolated-source proof + blocked status | Rewrites would hide the exact limitation QUAL-06 must reveal. |

## Common Pitfalls

1. **Treating the first raster byte as whitespace/comment:** only one header-delimiting whitespace byte follows maxval; after it, `#`, LF, or space may be legitimate pixel data.
2. **Claiming true PPM colorimetry:** the locked decoder emits encoded sRGB, while the Netpbm spec calls sRGB a common variation. Name the subset precisely.
3. **Allocating before all limits pass:** width and height alone are insufficient; pixel, payload, input/output, allocation, work, token/comment/header limits must all pass first.
4. **Incrementally charging malformed headers:** this can make budget state depend on chunking. Use deterministic preflight/one charge per D-09.
5. **Whole-input buffering:** violates the Reader-only contract and makes header attacks allocate before validation.
6. **Assuming one `read` fills the destination:** tests must split every header boundary and payload byte and include zero progress/EOS/failure.
7. **Leaking padding on encode:** write exact logical row bytes, not storage length or stride.
8. **Calling `publish --dry-run` CI-safe:** the pinned command still reads credentials.
9. **Using `moon.work` as external-consumer proof:** workspace resolution ignores registry versions and can conceal undeclared/unpublished dependencies. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html]
10. **Benchmarking without correctness or environment:** a fast wrong codec or an unrepeatable number is not release evidence.

## Environment Availability

| Dependency | Available | Verified version/result | Fallback |
|---|---:|---|---|
| PowerShell | yes | 7+ required by existing scripts [VERIFIED: local quality code] | none |
| `moon` | yes | `0.1.20260713 (75c7e1f)` | exact pin required |
| `moon package` | yes | `--frozen`, `--list`, `--dry-run`; actual package succeeds | none |
| `moon publish --dry-run` | command yes, usable no | blocked by missing credentials | record blocked; do not publish |
| local library artifact install | no | ZIP and non-main module rejected | isolated-source proof + artifact inspection |
| intended registry namespace/modules | no | isolated downstream resolution reports module not found | explicit blocked report until namespace/publication |
| external codec library | not needed | none installed/recommended | pure MoonBit implementation |

## Security Domain

This is untrusted binary parsing, so ASVS V5 input validation is applicable by analogy; authentication, sessions, access control, and cryptography are not. Required controls are closed ASCII grammar, checked arithmetic, explicit resource ceilings, bounded diagnostics, exact state transitions, fail-before-allocation behavior, no filesystem/network capability, and adversarial short-progress/truncation/trailing-data tests. Threats include allocation/work exhaustion, integer overflow, parser differential behavior across chunks, infinite loops on zero progress, and data disclosure through encoded row padding.

## State of the Art and Tool Limitations

| Topic | Current verified behavior | Planning impact |
|---|---|---|
| PPM | Official full format is wider than locked subset; official minimal subset matches canonical `P6/255/single image` bytes. | Document an intentional strict sRGB variation. |
| MoonBit package contents | `moon package --frozen --list` is the official inspection seam. | Compare ordered closed allowlist and ZIP contents/hashes. |
| Workspace resolution | Workspace members override registry resolution and ignore member dependency version for local source. | Never count workspace build as clean registry resolution. |
| Publish dry-run | Pinned CLI supports it but requires login credentials. | Keep outside Required or report blocked without secrets. |
| Local artifact consumption | Pinned CLI has no verified library ZIP install workflow. | Use D-22 fallback and preserve limitation in report. |
| Benchmarks | Built-in harness provides statistical summaries; raw individual timing arrays are not a stable API. | Capture repeated run summaries as raw samples. |

## Assumptions Log

No `[ASSUMED]` claims are used. Conservative workload sizes and the loose benchmark threshold are explicit research recommendations to validate during implementation, not external facts.

## Open Questions

1. **Exact stable error-code mapping:** use only the existing closed `CoreError` codes; planner should assign malformed token, unsupported maxval, trailing data, and limit cases consistently and test the matrix.
2. **Report path/schema names:** choose one checked JSON schema and keep current-machine baseline data separate from portable conformance evidence.
3. **Future real registry qualification:** remains blocked by namespace verification and publication policy; Phase 5 must close with an explicit blocked sub-result, not fabricate a pass.

## Sources

### Primary and authoritative

- Netpbm PPM specification — raw P6 grammar, sample order, minimal subset, multi-image/full-format scope, sRGB variation: https://netpbm.sourceforge.net/doc/ppm.html
- Netpbm PBM specification — exact comment placement and whitespace set inherited by PPM: https://netpbm.sourceforge.net/doc/pbm.html
- MoonBit command manual — `moon package`, `publish`, `bench`, `--frozen`, `--list`: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html
- MoonBit module configuration — dependency, metadata, include/exclude, package-list, supported-target semantics: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
- MoonBit workspace support — local member resolution and module-only publish behavior: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html
- MoonBit benchmark guide — `@bench.T`, `keep`, statistics, unstable JSON summary: https://docs.moonbitlang.com/en/latest/language/benchmarks.html
- Local pinned CLI/source/policy experiments on 2026-07-17 [VERIFIED: local repository and executable].

## Metadata

**Confidence breakdown:**
- Parser architecture: HIGH — derived from locked context and exact local public interfaces; grammar cross-checked against official Netpbm specifications.
- Release mechanics: HIGH for observed pinned CLI behavior; MEDIUM for future registry behavior because the namespace is intentionally unpublished.
- Benchmark method: MEDIUM — official harness verified, but workload/tolerance require the first checked baseline.
- Qualification integration: HIGH — existing Required lane, policy, fixture, interface, package, and read-only mechanisms were inspected locally.

**Research date:** 2026-07-17
**Valid until:** 2026-08-16 for stable format/architecture findings; rerun CLI probes if the pinned toolchain changes.
