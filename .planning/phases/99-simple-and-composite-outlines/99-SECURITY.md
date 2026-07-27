---
phase: 99
slug: simple-and-composite-outlines
status: verified
register_authored_at_plan_time: true
threats_total: 21
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-07-27
verified: 2026-07-27
---

# Phase 99 — Security

> ASVS L1 verification of the threat registers authored in Plans 99-01, 99-02, and 99-03.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Untrusted `glyf` bytes → private decoder | Packed counts, flags, coordinates, instructions, and offsets control reads, loops, arithmetic, and allocation. | Hostile font bytes and table-local offsets |
| Caller identity and authority → `Font::outline` | A `GlyphId` and caller-owned `Budget` enter retained font state. | Opaque identity and resource ceilings |
| Mutable retained source → public `Path2` | Backing bytes can change between admission and result publication. | Revisioned bytes and decoded geometry |
| Composite records → graph and placement engine | References, arguments, transforms, nesting, and flags control traversal and Q15 placement. | Component descriptors and glyph graph |
| Private Q15 geometry → public path | Point numbering, ordering, transforms, and rounding determine published commands. | Checked fixed-point points and contours |
| Hostile generated fonts → four runtimes | Malformed structures must have identical failure and no-partial-publication behavior. | Generated fixtures and structured errors |
| Private implementation → public interface/policy/docs | Internal parser, graph, Q15, and deferred capabilities must not become compatibility promises. | Generated interface and publication metadata |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|-----------|----------|-----------|----------|-------------|-------------------------|--------|
| T-99-01-01 | Tampering | Simple decoder | high | mitigate | Admitted glyph windows, strict endpoint/flag/delta/instruction framing, checked Q15 arithmetic, and malformed-stream tests. | closed |
| T-99-01-02 | Denial of Service | Repeats, contours, instructions, allocations | high | mitigate | `maxp`, `FontLimits`, work and caller Budget checks; review fixes `e491dfd9`, `4e8d12c5`, and `18180593` close allocation-count and allocation-size gaps; exact/one-short tests pass. | closed |
| T-99-01-03 | Tampering | Retained source mutation | high | mitigate | Pre/post revision guards cover successful, failed, and empty outline paths; mutation tests pass. | closed |
| T-99-01-04 | Spoofing | Opaque `GlyphId` reuse | high | mitigate | Every query validates receiving-font identity and range before reading `glyf`; foreign/out-of-range tests pass. | closed |
| T-99-01-05 | Tampering | Partial geometry publication | high | mitigate | Points, contours, and commands stay private until validation and post-read guard complete; failure matrices publish no `Path2`. | closed |
| T-99-01-06 | Repudiation | Error taxonomy | medium | mitigate | Public tests freeze `InvalidInput`, `Data`, `Capability`, `Resource`, and `State` facts. | closed |
| T-99-01-SC | Tampering | Dependency/interface baseline | low | accept | No install or dependency expansion; frozen toolchain and exact Phase 98 interface baseline constrain drift. | closed |
| T-99-02-01 | Denial of Service | Composite graph traversal | high | mitigate | Precharged iterative tri-color traversal, explicit stack, component/depth/work ceilings, cycle tests, and exact/one-short Budget tests. | closed |
| T-99-02-02 | Tampering | F2DOT14 transform and attachment math | high | mitigate | Checked signed Int64 Q15, exact matrix order, transform-before-translation, and overflow/cross-term tests. | closed |
| T-99-02-03 | Tampering | Component point references | high | mitigate | Encoded real points remain separate from implied commands; real, phantom, and invalid indices have distinct tested outcomes. | closed |
| T-99-02-04 | Tampering | Descriptor flags and `USE_MY_METRICS` | high | mitigate | Reserved/contradictory flags and transform/offset combinations are validated; review fixes `320d1a00`, `5bc3f34b`, and `f1b4ee68` cover specification edge cases. | closed |
| T-99-02-05 | Tampering | Partial composite publication | high | mitigate | Graph, placements, points, and commands accumulate privately and publish only after validation and revision guard. | closed |
| T-99-02-06 | Repudiation | Cycle versus nesting taxonomy | medium | mitigate | Full reachable structural traversal makes cycle/Data precede deeper-acyclic/Capability; public and white-box tests pass. | closed |
| T-99-02-SC | Tampering | Generated fixture oracle | low | accept | Pure MoonBit checksum-correct builders are independent of production decoding and add no dependency. | closed |
| T-99-03-01 | Tampering | Four-target hostile execution | high | mitigate | The same 92-test font package passes on native, JS, Wasm, and Wasm-GC after final review fixes. | closed |
| T-99-03-02 | Denial of Service | Four-target limits, work, and Budget | high | mitigate | Exact-fit/one-short allocation-count and allocation-size cases, failure-work charging, and empty/simple/composite paths pass on all targets. | closed |
| T-99-03-03 | Tampering | Generated interface drift | high | mitigate | Fresh `moon info`, exact semantic baseline, and interface policy gate pass. | closed |
| T-99-03-04 | Elevation of Privilege | Private/deferred API publication | high | mitigate | Fail-closed policy rejects parser, graph, Q15, nested, hint, raster, host, file, and FFI symbols; synthetic rejects pass. | closed |
| T-99-03-05 | Spoofing | Documentation overclaim | medium | mitigate | Executable API names and bilingual delivered/excluded scope pass four-target README checks. | closed |
| T-99-03-06 | Repudiation | Structured failure collapse | medium | mitigate | Tests and docs preserve distinct failure categories and never represent an error as empty success. | closed |
| T-99-03-SC | Tampering | Package/dependency supply chain | low | mitigate | Frozen commands, exact policy, sole `mb-core` dependency, and four supported targets are verified. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-99-01 | T-99-01-SC | Generated fixtures and the frozen existing dependency boundary introduce no new third-party runtime or install surface. | Phase 99 plan decision | 2026-07-27 |
| AR-99-02 | T-99-02-SC | Independent pure-MoonBit fixture builders are retained as a low-risk test oracle with checksum/open validation. | Phase 99 plan decision | 2026-07-27 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-27 | 21 | 21 | 0 | Codex GSD ASVS L1 |

Evidence includes the final clean `99-REVIEW.md`, `99-REVIEW-FIX.md`, four-target 92/92 font tests, four-target literate README checks, exact foundation policy, JSON parsing, and `git diff --check`.

---

## Sign-Off

- [x] All threats have a disposition
- [x] Accepted risks are documented
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-27
