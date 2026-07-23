# Phase 80: Resumable Indexed Low-Bit Qualification - Research

**Researched:** 2026-07-24  
**Domain:** bounded caller-buffered Type-3 low-bit PNG encoding and portable qualification  
**Confidence:** HIGH for repository seams and test contracts; MEDIUM for the recommended new public spelling

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Thin public adapter
- **D-01:** Add one additive `PngChunkEncoder` indexed low-bit factory taking the same `PngIndexedImage`, finite `PngIndexedBitDepth`, limits, budget, and diagnostics inputs as the eager low-bit route. It delegates to Phase 79's selector-aware private machine constructor; `new_indexed8` remains unchanged. — **Reversibility:** costly — its public lease lifecycle becomes a consumer contract.
- **D-02:** Do not duplicate traversal, framing, or CRC state. Eager and caller-buffered low-bit outputs must use one profile-aware machine and identical preflight facts.

### Caller-owned lifecycle
- **D-03:** For every depth, prove zero-capacity, one-byte, and ragged leases are eager-byte-identical; only accepted bytes advance progress/CRC; lease tails keep sentinels; success and error terminals stay sticky. Include a released-lease failure without later-lease mutation.
- **D-04:** Retain atomic selected-depth preflight: rejected construction exposes no lease and changes no budget state. Keep all Phase 79 eager and fixed Indexed8 chunk behavior frozen.

### Qualification evidence
- **D-05:** Reuse independent Type-3 wire/CRC and public RGB8/RGBA8 decode assertions, not production packing helpers. Run the ordinary frozen PNG package command on wasm, wasm-gc, js, and native. No wrappers, copied source trees, or release automation.

### the agent's Discretion
- Follow the closest existing chunk-constructor spelling and capability-error vocabulary.
- Reuse existing hostile-drain helpers rather than creating a second transport-test harness.

### Deferred Ideas (OUT OF SCOPE)

Indexed Adam7, compression/filter strategy choices, generic model widening, quantization, source packing models, staging buffers, FFI, wrappers, copied source trees, and release automation remain out of scope.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Prefer the codebase knowledge graph for code discovery; only fall back to text search for non-code files, literal/config searches, or insufficient graph results. The graph has no indexed entry for this v019 worktree, so this research used the permitted source fallback. [VERIFIED: AGENTS.md; codebase-memory MCP response]
- Keep core algorithms and shared data models in MoonBit; keep native/FFI concerns small, isolated, documented, and replaceable. [VERIFIED: AGENTS.md]
- Preserve acyclic public package dependencies, SemVer API discipline, deterministic GUI-free public operations, and RFC governance for architectural changes. [VERIFIED: AGENTS.md]
- Preserve portable capability boundaries and conformance evidence for js, wasm, wasm-gc, and native. [VERIFIED: AGENTS.md; modules/mb-image/moon.mod.json]
- This artifact is created within the active GSD planning workflow; no implementation, release, or unrelated planning artifact is in scope. [VERIFIED: AGENTS.md; task assignment]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| INDEXLOW-04 | Caller-buffered low-bit Indexed output reuses the bounded eager machine and remains byte-identical under hostile capacities, preserves lease ownership, and retains sticky terminals. | Add a thin `new_indexed` factory over `new_with_indexed_profile`, then reuse the packed-gray/Indexed8 hostile-drain and released-lease proofs for One, Two, and Four. [VERIFIED: modules/mb-image/png/stream_encode.mbt; modules/mb-image/png/stream_encode_test.mbt] |
| INDEXLOW-05 | Independent low-bit wire/decode vectors, hostile lifecycle proof, Indexed8 and legacy compatibility, and the ordinary PNG package pass cover wasm, wasm-gc, js, and native. | Retain Phase 79's independent eager Type-3 vectors and public decode tests, assert stream output equals that eager oracle, freeze `new_indexed8`, and run the ordinary all-target command. [VERIFIED: 79-VERIFICATION.md; modules/mb-image/png/{encode_test,stream_encode_test}.mbt; modules/mb-image/moon.mod.json] |
</phase_requirements>

## Summary

Phase 79 already supplies the only implementation substrate Phase 80 needs: `PngEncodeMachine::new_with_indexed_profile` accepts the immutable source and selected private wire profile, performs selected-depth preflight and the sole budget charge, and constructs the existing acknowledged frame machine. The fixed-Eight `new_with_indexed` wrapper remains the path used by `PngChunkEncoder::new_indexed8`; it must not be modified. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt; 79-VERIFICATION.md]

The production change is therefore one direct, additive adapter. It must select One/Two/Four exactly as eager `PngEncoder::encode_indexed` does, call the profile-aware constructor, and wrap the result in the established `Active(machine)` state. The existing `pull` implementation already makes lease writes acknowledgement-safe: it calls `present`, writes the lease byte, then calls `acknowledge`; `Finished` and `Failed(error)` return zero writes before touching a later lease. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt]

**Primary recommendation:** Add `PngChunkEncoder::new_indexed(source, bit_depth, limits, budget, diagnostics)` as a direct profile-aware machine adapter, then prove it with the existing hostile-lease patterns and the ordinary four-target package gate. The spelling is a project-local recommendation, not an existing API. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Public selected-depth chunk construction | API / Backend | — | The factory accepts the source and resource policy, performs no output itself, and returns the existing active encoder state. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |
| Selected-depth frame admission | API / Backend | — | The private profile constructor delegates to preflight, which checks palette capacity, packed sizes, limits, and the single budget charge before machine construction. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt] |
| Caller-owned output, CRC, and terminal state | API / Backend | Caller / Client buffer | `pull` owns the `present -> destination.set -> acknowledge` sequence and sticky `Active`/`Finished`/`Failed` state; the caller owns each lease. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |
| Portable PNG evidence | CI / Static | API / Backend | `mb-image` declares all four required targets and the project convention uses the ordinary PNG package command. [VERIFIED: modules/mb-image/moon.mod.json; 80-CONTEXT.md] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Build and execute the existing portable PNG package. | The pinned local toolchain is installed; Phase 80 needs no new dependency. [VERIFIED: local `moon --version`] |
| Existing `mb-image/png` package | repository source | Public factory, selected-depth machine, lease lifecycle, and qualification tests. | The required profile, preflight, and state machine already exist locally; a new encoder would violate locked scope. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt; 80-CONTEXT.md] |

### Supporting

| Component | Purpose | When to Use |
|---|---|---|
| `PngIndexedImage` and `PngIndexedBitDepth` | Immutable canonical source and finite One/Two/Four selection. | Accept exactly these types in the new low-bit chunk constructor; do not widen generic image APIs. [VERIFIED: modules/mb-image/png/png.mbt; 80-CONTEXT.md] |
| `PngEncodeMachine::new_with_indexed_profile` | Shared preflight, framing, direct packing, CRC, and byte state. | Call once from the new adapter after mapping the public selector. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |
| Existing hostile-drain and test-local PNG oracles | Lease ownership/terminal proof and independent Type-3 wire/decode evidence. | Extend the present packed-gray and Indexed8 patterns; retain eager vector/decode oracles rather than calling production packing helpers. [VERIFIED: modules/mb-image/png/{encode_test,stream_encode_test}.mbt; 79-VERIFICATION.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| One `new_indexed` adapter over the existing profile machine | A second low-bit traversal, framing, CRC, or chunk transport | Rejected: it would create divergent preflight and acknowledgement semantics and directly violates D-02. [VERIFIED: 80-CONTEXT.md] |
| Selector-bearing low-bit factory plus frozen `new_indexed8` | Replacing `new_indexed8` with a generalized API | Rejected: Phase 79 explicitly retains the fixed-Eight wrapper as the compatibility route. [VERIFIED: 79-VERIFICATION.md; 80-CONTEXT.md] |
| Existing hostile helpers and schedules | A new transport-test harness | Rejected: the established helpers already test zero/one/ragged capacities, sentinels, progress, and sticky terminals. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt; 80-CONTEXT.md] |

**Installation:** None — this phase installs no external package. [VERIFIED: 80-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
PngIndexedImage + PngIndexedBitDepth
                 |
                 v
PngChunkEncoder::new_indexed  [thin public adapter]
                 |
        One / Two / Four -> PngIndexedWireProfile
                 |
                 v
PngEncodeMachine::new_with_indexed_profile
                 |
        checked selected-depth preflight
        limits -> one budget charge -> Active machine
                 |
                 v
caller lease -> pull() -> present() -> lease.set(byte) -> acknowledge(byte)
                                           |                    |
                                           |                    +-> commits cursor / CRC / progress
                                           v
                                  NeedOutput / Finished / Failed (sticky)
```

`new_indexed8` must continue to take its fixed-Eight wrapper branch, while the new adapter alone enters the One/Two/Four profile selection branch. [VERIFIED: modules/mb-image/png/stream_encode.mbt; 79-VERIFICATION.md]

### Recommended Project Structure

```text
modules/mb-image/png/
├── stream_encode.mbt       # one additive selector-bearing chunk factory
├── stream_encode_test.mbt  # hostile schedules, sentinels, sticky terminals, and chunk parity
└── encode_test.mbt         # retained independent eager Type-3 wire/CRC and RGB8/RGBA8 decode oracles
```

The plan should not modify the fixed Indexed8 factory, the eager low-bit implementation, source model, or test infrastructure outside these seams. [VERIFIED: 80-CONTEXT.md; 79-01-SUMMARY.md]

### Pattern 1: Thin selected-profile factory

**What:** Mirror the eager low-bit selector mapping, call the private profile-aware machine constructor, return errors unchanged, and initialize `PngChunkEncoderState::Active(machine)` with `total_written: 0UL`. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt]

**When to use:** Use only for the new Type-3/1, /2, and /4 caller-buffered entry. Keep `new_indexed8` calling `new_with_indexed`. [VERIFIED: 80-CONTEXT.md; modules/mb-image/png/stream_encode.mbt]

**Recommended implementation shape:**

```moonbit
// The `new_indexed` spelling is the Phase 80 recommendation. [ASSUMED]
pub fn PngChunkEncoder::new_indexed(
  source : PngIndexedImage,
  bit_depth : PngIndexedBitDepth,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  let wire_profile = match bit_depth {
    PngIndexedBitDepth::One => PngIndexedWireProfile::One
    PngIndexedBitDepth::Two => PngIndexedWireProfile::Two
    PngIndexedBitDepth::Four => PngIndexedWireProfile::Four
  }
  let machine = match PngEncodeMachine::new_with_indexed_profile(
    source, wire_profile, limits, budget, diagnostics,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}
```

The shape is derived from the existing `new_indexed8` error/Active pattern and the eager `encode_indexed` selector mapping. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt]

### Pattern 2: Hostile drain as a lifecycle proof

**What:** For a fresh encoder and each selected depth, first pass a zero-capacity `Z`-filled lease; then drain with `[0, 1]`, `[1]`, and `[0, 1, 3, 2, 5]`. At every pull collect only `written()` bytes, require `total_written == prior_collected + written`, and require every unused lease byte to remain `Z`. At completion compare collected bytes with the eager selected-depth bytes and verify a fresh later lease gets zero-write `Finished` without mutation. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt; 80-CONTEXT.md]

**When to use:** Reuse the existing packed-gray hostile-drain structure and Indexed8 terminal checks; parameterize source/depth/factory rather than making another byte-transport implementation. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt; 80-CONTEXT.md]

### Pattern 3: Independent observable wire and decode proof

**What:** Keep the Phase 79 literal Type-3 scanline/CRC assertions as the wire oracle and public RGB8/RGBA8 decode assertions as the observable decoder oracle. The chunk test establishes that its output is exactly those eager bytes; it must not calculate expected bytes through `scanline_byte`, preflight, or another production helper. [VERIFIED: modules/mb-image/png/encode_test.mbt; 79-VERIFICATION.md; 80-CONTEXT.md]

**When to use:** Cover opaque RGB8 and partial-alpha RGBA8 outputs across the selected depths, including odd-width tails already represented by the eager vectors. [VERIFIED: 79-VERIFICATION.md; 80-CONTEXT.md]

### Anti-Patterns to Avoid

- **Second encoder or transport loop:** It risks different framing, CRC timing, resource admission, or terminal behavior; use the existing machine and `pull`. [VERIFIED: 80-CONTEXT.md; modules/mb-image/png/stream_encode.mbt]
- **Routing selected depths through `new_with_indexed`:** That wrapper always selects Eight, so it silently breaks low-bit IHDR/packing parity. [VERIFIED: modules/mb-image/png/stream_encode.mbt]
- **Changing `new_indexed8` to delegate through the new selector:** It risks changing the frozen Indexed8 public route; leave its fixed wrapper untouched. [VERIFIED: 79-VERIFICATION.md; 80-CONTEXT.md]
- **Testing only successful full-size leases or decoder round trips:** That misses accepted-only progress, tail ownership, sticky failure, byte framing, and CRC regressions. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt; 79-VERIFICATION.md]
- **Adding strategies, Adam7, a generic model, staging, FFI, wrappers, copied trees, or release scripts:** All are explicitly deferred. [VERIFIED: 80-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Low-bit selected preflight and frame facts | A chunk-specific packed-size, PLTE/tRNS, IDAT, limit, or budget calculator | `PngEncodeMachine::new_with_indexed_profile` | It already selects checked packed-row facts and performs the one atomic budget charge. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt] |
| Resumable traversal, CRC, and terminal state | A second indexed output cursor/state machine | Existing `PngEncodeMachine` plus `PngChunkEncoder::pull` | Pending bytes become committed only after caller-lease acceptance; this protects progress and CRC timing together. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |
| Hostile-buffer harness | New scheduling/lease ownership framework | Existing packed-gray and Indexed8 drain/released-lease patterns | They already contain the exact capacity schedules, sentinel checks, and terminal assertions needed by D-03. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt] |
| PNG wire oracle | Expected bytes computed using production packing/framing code | Existing literal eager vectors, test-local CRC parser, and public decoder assertions | Independent evidence catches mutually compatible encoder/decoder mistakes. [VERIFIED: modules/mb-image/png/encode_test.mbt; 79-VERIFICATION.md] |

**Key insight:** Phase 80 correctness is the invariant `preflight -> Active -> lease.set -> acknowledge`, not just a decodable PNG. Delegating to the existing profile machine preserves byte identity, exact admission facts, and accepted-only commits as one contract. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt]

## Common Pitfalls

### Pitfall 1: Mapping the public selector to the fixed-Eight wrapper

**What goes wrong:** The new factory produces an Indexed8 frame or fixed-eight sizes for a One/Two/Four request. [VERIFIED: modules/mb-image/png/stream_encode.mbt]

**Why it happens:** `new_with_indexed` is intentionally a compatibility wrapper around `PngIndexedWireProfile::Eight`. [VERIFIED: modules/mb-image/png/stream_encode.mbt]

**How to avoid:** Match `PngIndexedBitDepth` to One/Two/Four and call `new_with_indexed_profile`; add eager-byte parity for every depth. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt]

**Warning signs:** A low-bit chunk output has IHDR depth 8, an Indexed8-sized IDAT, or fails the Phase 79 eager comparison. [VERIFIED: 79-VERIFICATION.md]

### Pitfall 2: Weak hostile-lease proof

**What goes wrong:** A test may pass under a normal buffer but fail on zero capacity, tail preservation, or repeated terminal pulls. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt]

**Why it happens:** Full-buffer drains do not exercise the pending-byte acknowledgement boundary or untouched bytes after completion. [VERIFIED: modules/mb-image/png/stream_encode.mbt]

**How to avoid:** Run all three locked schedules for each depth and check zero-capacity NeedOutput, accepted-only counters, every sentinel tail, eager parity, and a later zero-write Finished pull. [VERIFIED: 80-CONTEXT.md; modules/mb-image/png/stream_encode_test.mbt]

**Warning signs:** `total_written` differs from collected bytes, a `Z` tail changes, or a repeated Finished pull changes a fresh lease. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt]

### Pitfall 3: Non-sticky error after a released lease

**What goes wrong:** A failed first lease leaves a machine that can mutate the next caller lease or reports a different terminal error. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt]

**Why it happens:** Testing only an error outcome does not prove that `Failed(error)` is replayed before any later destination write. [VERIFIED: modules/mb-image/png/stream_encode.mbt]

**How to avoid:** Release a one-byte first lease, record the failed result, then pull into a new `Z`-filled lease and require zero written, unchanged total, equal error, and unchanged sentinels for every selected depth. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt; 80-CONTEXT.md]

**Warning signs:** Any byte changes in the later owner or `replay_error` is not equal to `first_error`. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt]

### Pitfall 4: Replacing independent qualification with parity alone

**What goes wrong:** Chunk output can equal an eager output that has a shared packing or framing defect. [VERIFIED: 79-VERIFICATION.md]

**Why it happens:** Equality proves one-machine reuse, not external Type-3 correctness. [VERIFIED: 80-CONTEXT.md]

**How to avoid:** Keep Phase 79's literal Stored scanline and test-local CRC evidence plus public RGB8/RGBA8 decode evidence in the ordinary package run. [VERIFIED: modules/mb-image/png/encode_test.mbt; 79-VERIFICATION.md]

**Warning signs:** Tests only assert `chunk == eager` and do not retain literal vectors, chunk-order/CRC checks, or public decode assertions. [VERIFIED: 80-CONTEXT.md]

## Code Examples

### Per-depth released-lease terminal proof

```moonbit
// Reuse the existing Indexed8/packed-gray test sequence. [VERIFIED: codebase inspection]
let released = png_chunk_test_owner(1UL, fill=b'Z')
let first = released.with_mut(0UL, 1UL, fn(lease) {
  lease.release()
  Ok(encoder.pull(lease))
}).unwrap()
let later = png_chunk_test_owner(1UL, fill=b'Z')
let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
// Assert both calls are zero-write Failed(same error), both totals are unchanged,
// and both owners still contain b'Z'. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt]
```

### Required portable gate

```powershell
moon -C modules/mb-image test png --target all --frozen
```

The local CLI documents `all` as wasm, wasm-gc, js, and native and documents `--frozen` as no dependency synchronization. A research-time invocation did not complete before the 64-second timeout because `_build/.moon-lock` was live; it is not pass evidence and must be rerun as the Phase 80 gate. [VERIFIED: local `moon test --help`; research-time command result]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Indexed8 caller-buffered route only | Profile-aware indexed machine with public eager One/Two/Four selection | Phase 79 | Phase 80 can add one low-bit chunk adapter without changing Indexed8 compatibility wrappers. [VERIFIED: 79-01-SUMMARY.md; modules/mb-image/png/{encode,stream_encode}.mbt] |
| Low-bit eager wire/decoder evidence only | Eager evidence plus caller-buffered lifecycle and four-target qualification | Phase 80 scope | Completes INDEXLOW-04 and INDEXLOW-05 without broadening the wire feature set. [VERIFIED: REQUIREMENTS.md; ROADMAP.md; 80-CONTEXT.md] |

**Deprecated/outdated:** No existing Phase 80 API is deprecated. `new_indexed8` remains the fixed Indexed8 compatibility API. [VERIFIED: 79-VERIFICATION.md; 80-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The additive public name should be `PngChunkEncoder::new_indexed`. | Summary / Pattern 1 | The name could diverge from the project's preferred public spelling, requiring a small API rename before implementation. |

## Open Questions

1. **No blocking technical question remains.**
   - What we know: The private selected-profile constructor, public selector, eager oracle, hostile test patterns, and four-target command all exist. [VERIFIED: modules/mb-image/png/{png,encode,stream_encode,encode_test,stream_encode_test}.mbt; local `moon test --help`]
   - What's unclear: Only the discretionary public factory spelling is not already present. [VERIFIED: 80-CONTEXT.md]
   - Recommendation: Use `new_indexed` to mirror eager `encode_indexed`; preserve `new_indexed8` unchanged. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` / `moonc` / `moonrun` | Build and four-target PNG test | ✓ | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `mb-image` four-target declaration | INDEXLOW-05 portability | ✓ | `+js+wasm+wasm-gc+native` | — [VERIFIED: modules/mb-image/moon.mod.json] |

**Missing dependencies with no fallback:** None. [VERIFIED: local toolchain; modules/mb-image/moon.mod.json]

**Missing dependencies with fallback:** None. [VERIFIED: local toolchain; modules/mb-image/moon.mod.json]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity boundary is introduced. [VERIFIED: 80-CONTEXT.md] |
| V3 Session Management | no | The sticky encoder terminal is not an authentication session. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |
| V4 Access Control | no | No authorization decision is introduced. [VERIFIED: 80-CONTEXT.md] |
| V5 Input Validation | yes | Preserve finite depth selection, `PngIndexedImage` validation, checked selected-depth preflight, limits, and atomic budget admission before lease exposure. [VERIFIED: modules/mb-image/png/{png,encode,stream_encode}.mbt] |
| V6 Cryptography | no | PNG CRC/Adler are file-integrity checks, not security cryptography. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |

### Known Threat Patterns for bounded indexed PNG encoding

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Palette/depth or size request causes an invalid or under-accounted frame | Tampering / Denial of service | Delegate to selected-profile preflight, which checks capacity and checked sizes before its sole charge. [VERIFIED: modules/mb-image/png/encode.mbt] |
| Unaccepted or released caller lease corrupts state | Tampering | Commit only after `destination.set`; cache `Failed(error)` and prove zero-write replay on a fresh sentinel lease. [VERIFIED: modules/mb-image/png/{stream_encode,stream_encode_test}.mbt] |
| Shared encoder/decoder defect evades a round trip | Tampering | Keep literal Type-3 wire/CRC vectors and public decoder assertions independent of production packing. [VERIFIED: modules/mb-image/png/encode_test.mbt; 79-VERIFICATION.md] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/stream_encode.mbt` — current chunk factories, selected-profile indexed machine construction, `pull`, acknowledgement ordering, and terminal state. [VERIFIED: codebase inspection]
- `modules/mb-image/png/encode.mbt` and `png.mbt` — public selector, fixed-Eight wrappers, selected-depth preflight, and immutable indexed source contract. [VERIFIED: codebase inspection]
- `modules/mb-image/png/stream_encode_test.mbt` and `encode_test.mbt` — hostile lease schedules, sentinels, released leases, literal wire/CRC helpers, and public decode oracles. [VERIFIED: codebase inspection]
- `80-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `79-CONTEXT.md`, `79-01-SUMMARY.md`, and `79-VERIFICATION.md` — locked boundary, acceptance requirements, completed machine facts, compatibility requirements, and prior verification. [VERIFIED: repository planning artifacts]
- `modules/mb-image/moon.mod.json` and local `moon --version` / `moon test --help` — portability declaration, installed versions, and test command options. [VERIFIED: local repository and toolchain]

### Secondary (MEDIUM confidence)

- None — this phase makes no external library or format-policy decision; all implementation facts are constrained by the present repository. [VERIFIED: 80-CONTEXT.md]

### Tertiary (LOW confidence)

- Recommended additive public spelling `PngChunkEncoder::new_indexed`; it is marked `[ASSUMED]` until implementation locks the API. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no dependency selection is required; local toolchain and module targets were inspected. [VERIFIED: local toolchain; modules/mb-image/moon.mod.json]
- Architecture: HIGH — the exact profile-machine and lease/terminal paths were inspected directly. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt]
- Pitfalls: HIGH — each follows a currently executable preflight, lease, sentinel, or terminal pattern. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt; 79-VERIFICATION.md]

**Research date:** 2026-07-24  
**Valid until:** implementation start, or until the Phase 79 PNG seams change. [VERIFIED: codebase inspection]
