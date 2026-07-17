# Phase 5: Reference Codec and Release Qualification - Context

**Gathered:** 2026-07-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the completed `mb-core`, `mb-color`, and `mb-image` public contracts as independently consumable v0.1 release candidates. Phase 5 adds one strict bounded PPM P6 reference codec, public end-to-end examples, conformance/adversarial/property evidence, reproducible benchmark records, and dry-run release qualification in dependency order. It does not add production codec breadth, network publishing, a global codec registry, ambient filesystem policy, GUI behavior, or new graphics features.
</domain>

<decisions>
## Implementation Decisions

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

### Agent Discretion

- Exact package/type names, bounded parser state representation, fixture case IDs, benchmark workload sizes, report file formats, isolated-consumer mechanics supported by the pinned toolchain, and plan decomposition.
</decisions>

<code_context>
## Existing Code and Reuse

- Reuse `mb-core/io` Reader/Writer, exact helpers, bounded streams, memory doubles; `mb-core/checked`, `budget`, `bytes`, `error`, and diagnostics.
- Reuse `mb-image/codec` prefix/options/results contracts, `model` descriptors, `storage` atomic owned-image factory and mutable lease gates, `ops` transforms, and metadata dispositions.
- Reuse the deterministic fixture-generator patterns and exact policy/read-only qualification already established in Phases 3 and 4.
- Preserve the rootless package DAG and four-target policy. A concrete PPM package may depend on codec/model/storage/metadata and core I/O/safety packages, but never on host/filesystem/global registry state.
- Release qualification extends existing `policy/foundation.json`, root quality scripts, module READMEs/changelogs, and release ledgers rather than creating an unrelated release system.
</code_context>

<specifics>
## Adversarial Classes

- Magic mismatch; whitespace/comment boundaries split across every byte; header/token/comment limits; zero/overflow dimensions; maxval 0/1/254/256/65535; one-byte-short payload; extra byte; concatenated image; zero-progress Reader/Writer; allocation/work rejection; reordered chunk sizes.
- Canonical RGB fixtures include 1x1 endpoints, 1xN/Nx1, padded source views for encode, a small orientation/flip pipeline, and deterministic round-trip digests.
- Clean-consumer checks must prove module independence and catch accidental `moon.work` substitution or undeclared transitive imports.
</specifics>

<deferred>
## Deferred Ideas

- Real registry publication, signed artifacts/releases, production codec libraries, wider PPM variants, and benchmark claims remain outside v0.1 qualification.
</deferred>

---

*Phase: 05-reference-codec-and-release-qualification*
*Context gathered: 2026-07-17*
