# Phase 2: Bounded Core Primitives - Research

**Researched:** 2026-07-16
**Domain:** Portable MoonBit safety primitives for untrusted binary data
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

<!-- DATA_A7K4M2Q9_START -->
### Checked numeric and range semantics
- **D-01:** All caller-controlled overflow, underflow, invalid alignment, invalid dimension, invalid offset/range, and narrowing failures return structured checked results before any access, allocation, or work. Public checked operations never silently wrap, saturate, or panic.
- **D-02:** Ranges are half-open `[start, end)` and canonicalized from checked `start + length`. Empty ranges and zero-length operations are valid. Dimensions and logical sizes are non-negative; alignment must be a non-zero power of two.
- **D-03:** Cross-backend behavior is defined by explicit-width logical quantities and checked conversion into backend allocation/index types. A failed conversion is an error, never a truncation.

### Owned bytes and validated views
- **D-04:** Public storage and view representations are opaque. Immutable and mutable views retain their backing storage and carry a validated start/length window so a view cannot outlive or escape its allocation.
- **D-05:** Subviews are zero-copy when valid, use the same half-open semantics as ranges, and fail before access when the requested window is invalid.
- **D-06:** v0.1 does not expose APIs that manufacture simultaneous overlapping mutable aliases. Mutable access is exclusive by construction, with explicit non-overlapping split operations allowed only when disjointness is validated. Immutable aliases may coexist.
- **D-07:** Owned storage construction distinguishes allocation failure or budget rejection from range errors. Conversion from immutable external bytes may copy unless ownership is explicitly transferred through a documented API.

### Stream outcomes, bounded I/O, and seeking
- **D-08:** Reader and writer contracts explicitly distinguish successful progress, end-of-stream, and failure. Partial progress is normal and observable; a failure may report already completed progress without losing it.
- **D-09:** Exact helpers repeatedly consume partial progress, reject no-progress loops, and report unexpected end-of-stream with requested and completed counts. Zero-length operations succeed immediately without touching the backend.
- **D-10:** Seeking is a separate capability, not a mandatory method on every reader or writer. Origins and positions use checked arithmetic; unsupported seeking is represented by capability absence rather than a routine runtime failure.
- **D-11:** Bounded sub-readers and in-memory readers/writers enforce their own logical window regardless of underlying seekability. They never read, write, or seek outside the declared window and do not require filesystem access or full-input buffering.

### Errors and diagnostics
- **D-12:** Machine-readable failures use stable category/code pairs with typed context fields and optional source offsets. Human-readable text is deterministically rendered from structured data; consumers must not parse prose to recover semantics.
- **D-13:** Error and diagnostic rendering has a fixed field order, stable escaping, locale-independent numeric formatting, and no ambient path, clock, or backend exception text. Non-fatal diagnostics preserve encounter order.
- **D-14:** Backend/host failures are mapped at the adapter boundary into portable codes plus bounded context; foreign exception names and platform-specific numeric codes are not public portable semantics.

### Resource budgets and host capabilities
- **D-15:** Limits cover bytes, allocation count/size, dimensions/pixels, nesting depth, and abstract work units. Budget charges occur before prohibited allocation or work, and rejected charges do not partially consume allowance.
- **D-16:** Nested operations use shared hierarchical budget state so child scopes cannot reset or bypass a parent's remaining allowance. Enter/leave operations for nesting are balanced and deterministic on all exit paths.
- **D-17:** Host access is exposed through small, independently optional capability interfaces such as files/resources, logging/diagnostics, clock, cancellation, and resource resolution. There is no ambient fallback and no mandatory all-capabilities singleton.
- **D-18:** Phase 2 supplies portable in-memory implementations and contract/conformance doubles. Concrete native adapters remain isolated leaf packages and are implemented only where needed by a later phase or separately accepted scope.
<!-- DATA_A7K4M2Q9_END -->

### the agent's Discretion

<!-- DATA_R5N8C3V1_START -->
- Exact MoonBit type names, package decomposition, internal representation, and error-code spelling are left to research and planning, provided the public behavior above remains explicit, acyclic, portable, and machine-testable.
- The planner may split delivery into independently verifiable packages/waves and may add property/adversarial tests beyond the minimum acceptance matrix.
<!-- DATA_R5N8C3V1_END -->

### Deferred Ideas (OUT OF SCOPE)

<!-- DATA_T9P2L6H4_START -->
- Concrete native filesystem, clock, process, or networking adapters beyond the minimum contract surface are deferred until a consuming phase needs them.
- Image-specific layout/stride rules and detailed pixel-limit policy belong to Phase 4; Phase 2 supplies only generic checked dimensions and budget counters.
- Codec-specific decompression ratios, registry behavior, and PPM subset rules belong to Phase 5.
<!-- DATA_T9P2L6H4_END -->
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CORE-01 | Checked addition, multiplication, alignment, casts, ranges, offsets, dimensions, and allocation sizes with structured overflow failure. | Use `UInt64` logical quantities, precondition-based checked arithmetic, opaque validated value types, and checked `UInt64 -> Int` narrowing. [VERIFIED: pinned local MoonBit core and repository requirements] |
| CORE-02 | Owned byte storage and validated immutable/mutable views that cannot access outside their range. | Wrap `Bytes`/`FixedArray[Byte]` and validated windows behind abstract public types; expose one mutable lease and validated disjoint splitting only. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html] |
| CORE-03 | Backend-neutral I/O distinguishing exact, partial, end-of-stream, and failed operations. | Use open, object-safe traits plus explicit progress/EOS/failure outcome enums; exact helpers loop with a no-progress guard. [CITED: https://docs.moonbitlang.com/en/latest/language/methods.html] |
| CORE-04 | Bounded sub-readers and in-memory reader/writer implementations without filesystem or whole-input buffering. | Implement cursor + checked window wrappers over validated byte views; cap every operation by destination/source and logical remaining lengths. [VERIFIED: RFC 0001 and Phase 2 context] |
| CORE-05 | Optional seeking rather than universal seek support. | Define `Seeker` independently from `Reader`/`Writer`; accept `&Seeker` only on APIs that require it. [CITED: https://docs.moonbitlang.com/en/latest/language/methods.html] |
| CORE-06 | Stable machine-readable errors/diagnostics plus deterministic rendering. | Use public code/category enums, opaque error records with typed accessors, bounded context, and a canonical renderer independent of `Debug` output. [VERIFIED: repository policy and pinned compiler diagnostics behavior] |
| CORE-07 | Pre-work budgets for bytes, allocations, dimensions/pixels, nesting, and work. | Use one shared mutable ledger, atomic preflight/commit charges, child handles that share state, and `defer` for balanced depth. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html] |
| CORE-08 | Explicit host capabilities rather than ambient process state. | Define small open traits per capability and portable fakes; do not define a global environment or aggregate singleton. [VERIFIED: RFC 0001 and Phase 2 context] |
</phase_requirements>

## Summary

Phase 2 should be planned as a dependency-ordered contract spine, not as one large root package. The pinned compiler uses 32-bit `Int`, exposes 64-bit `UInt64`, and demonstrates wrapping integer behavior in its installed core tests; conversion methods such as `UInt64::to_int` are available but are not checked-result APIs. Therefore every public size, position, count, budget, and offset should use `UInt64` logically and narrow to `Int` only after comparing against the backend index ceiling. [VERIFIED: `moon 0.1.20260713`, installed `moonbitlang/core` interfaces and tests]

MoonBit already supplies the raw mechanisms needed: abstract types by default, readonly/open visibility, object-safe trait objects, immutable `Bytes`/`BytesView`, mutable `FixedArray[Byte]`/`MutArrayView[Byte]`, `Result`, explicit error effects, and `defer`. Those built-ins are mechanisms, not the MNF contract: raw indexing, slicing, allocation, numeric conversion, and unsafe byte functions may panic, truncate, wrap, or permit alias patterns that violate the locked decisions. Wrap them behind opaque types and checked constructors, and never expose the backing container or a raw mutable view. [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html] [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html]

The highest-risk design seam is mutable ownership. MoonBit is not a borrow-checker language, so the public API must manufacture at most one runtime-validated mutable lease for a backing store, reject a second overlapping lease, and invalidate a lease after its scoped operation; a split operation may replace one lease with two disjoint child leases after checked partitioning. This is an inference from the locked exclusivity rule and the language's reference-backed mutable view model, and it needs an early executable spike before the public API is frozen. [VERIFIED: pinned local core `MutArrayView` interface] [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html]

**Primary recommendation:** plan six ordered packages/waves: `error` -> `checked` -> `budget` -> `bytes` -> `io` -> `host`, with in-memory/fake implementations and adversarial four-target tests landing beside each contract rather than at the end. [VERIFIED: repository architecture and dependency policy]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Checked quantities/ranges | `mb-core/checked` foundation | `mb-core/error` | Owns canonical logical widths and validation before any upper-layer work. [VERIFIED: RFC 0001] |
| Error/diagnostic vocabulary | `mb-core/error` foundation | Host adapter boundary | Lowest dependency because every other package emits it; adapters map foreign failures into it. [VERIFIED: RFC 0001] |
| Shared resource accounting | `mb-core/budget` foundation | Call-site algorithms | The ledger owns atomic charging; callers decide semantic work-unit costs. [VERIFIED: Phase 2 context] |
| Owned bytes/views | `mb-core/bytes` foundation | Standard-library containers | MNF owns validation and alias policy while built-ins provide storage. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html] |
| Streams/seeking/in-memory I/O | `mb-core/io` foundation | `mb-core/bytes`, `mb-core/budget` | Stream contracts consume validated views and budgets without host access. [VERIFIED: RFC 0001] |
| Files/logging/clock/cancellation/resolution | Composition-root supplied capabilities | `mb-core/host` contracts | Applications/adapters supply them; portable algorithms only consume explicit interfaces. [VERIFIED: RFC 0001] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| MoonBit toolchain | `moon 0.1.20260713`, `moonc v0.10.4`, `moonrun 0.1.20260713` | Build and validate all packages | Exact repository baseline; verified locally on 2026-07-16. [VERIFIED: local commands and `policy/toolchain.json`] |
| `moonbitlang/core` built-ins | Toolchain-bundled | `UInt64`, `Result`, traits, `Bytes`, `FixedArray`, views, `defer` | Already installed, portable, and coupled to the pinned compiler; no external dependency is needed. [VERIFIED: `C:/Users/Admin/.moon/lib/core`] |
| Moon built-in test modes | Toolchain-bundled | Public black-box, internal white-box, snapshots, docs | Matches the repository's established quality policy. [CITED: https://docs.moonbitlang.com/en/stable/language/tests.html] |

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Root quality workflow | Repository-owned | Format/check/test/docs/package/DAG gates | Every plan exit and phase gate. [VERIFIED: `scripts/quality.ps1`] |
| Installed core source/interfaces | Toolchain-bundled | Resolve exact API behavior during implementation | Prefer over memory when an API signature or conversion behavior is uncertain. [VERIFIED: local toolchain] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `UInt64` logical quantities | `Int` everywhere | Simpler indexing, but 32-bit backend index capacity would become public semantics and arithmetic wraps before validation. Reject. [VERIFIED: pinned local interfaces/tests] |
| Open traits + trait objects | One concrete stream record with callbacks | Avoids dynamic traits but makes capability composition and downstream implementations more awkward. Object-safe traits are directly supported. [CITED: https://docs.moonbitlang.com/en/latest/language/methods.html] |
| Opaque MNF byte wrappers | Expose `BytesView`/`MutArrayView` directly | Less code, but cannot enforce MNF's structured range failures or mutable lease policy. Reject. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html] |
| Separate capability traits | One `Host` mega-interface | Fewer parameters, but creates mandatory unrelated capabilities and a service-locator shape. Reject by D-17. [VERIFIED: Phase 2 context] |

**Installation:** none. External packages are neither expected nor recommended. [VERIFIED: repository dependency policy]

## Architecture Patterns

### System Architecture Diagram

```text
untrusted counts / bytes / caller options
                 |
                 v
       checked logical quantities -----> structured CoreError
                 |
                 v
     shared budget atomic precharge ----> LimitExceeded (no charge)
                 |
                 v
 opaque owned storage + validated views
                 |
                 v
 Reader / Writer outcomes -- capability present? --yes--> independent Seeker
        |                              |
        |                              no
        v                              v
 bounded/in-memory adapters       non-seeking path
                 |
                 v
 deterministic diagnostics + explicit optional host capabilities
```

### Recommended Project Structure

```text
modules/mb-core/
├── error/                  # categories, codes, typed context, diagnostics, rendering
├── checked/                # Size, Offset, Range, Dimensions, checked arithmetic/narrowing
├── budget/                 # limits, shared ledger, child/depth scopes, charges
├── bytes/                  # OwnedBytes, ByteView, MutByteLease, validated split/subview
├── io/                     # Reader/Writer/Seeker, outcomes, exact helpers, bounded memory I/O
├── host/                   # small open capability traits and portable test doubles
└── README.mbt.md           # candidate public examples and contract summary
```

Package imports must follow the order above; `error` imports no MNF package, and no portable package imports a future native adapter. Every public package retains `+js+wasm+wasm-gc+native`. [VERIFIED: RFC 0001 and `docs/policies/targets.md`]

### Pattern 1: Precondition-Based Checked Arithmetic

Perform checks in a form that cannot itself overflow; only execute the operator after the guard. [CITED: https://cwe.mitre.org/data/definitions/190.html]

```moonbit
pub fn checked_add(a : UInt64, b : UInt64) -> Result[UInt64, CoreError] {
  if a > @uint64.MAX_VALUE - b {
    Err(CoreError::overflow(operation="add", left=a, right=b))
  } else {
    Ok(a + b)
  }
}

pub fn checked_mul(a : UInt64, b : UInt64) -> Result[UInt64, CoreError] {
  if b != 0UL && a > @uint64.MAX_VALUE / b {
    Err(CoreError::overflow(operation="multiply", left=a, right=b))
  } else {
    Ok(a * b)
  }
}
```

Alignment must first validate `alignment != 0` and `alignment & (alignment - 1) == 0`, then use checked addition with `alignment - 1`. Narrowing to `Int` must compare against `@int.MAX_VALUE.to_uint64()` before `to_int()`. [VERIFIED: pinned local core constants and conversion interfaces]

### Pattern 2: Validated Window, Then Access

Construct all windows from `(start, length)` by checked addition; store backing, start, and length in an abstract type. Subview validation is relative to the current window, not the whole backing store. Built-in `get_view` can be used only after MNF validation, never as the public failure contract. [VERIFIED: pinned local `BytesView` and `MutArrayView` interfaces]

For mutable storage, use a shared lease record (`active`, window, backing identity). A scoped mutable operation acquires one lease; every mutation rechecks that it is active; cleanup invalidates it. `split_mut(at)` consumes/deactivates the parent logical lease and returns two child lease records only after checked disjoint partitioning. [INFERENCE: D-06 plus MoonBit mutable-view semantics]

### Pattern 3: Explicit Stream Outcome State Machine

Use different constructors for progress, EOS, and failure; do not encode EOS as `Ok(0)`. Failure context includes completed progress. Exact helpers terminate on progress, EOS, failure, or explicit no-progress error, and return immediately for a zero-length request before invoking the trait object. [VERIFIED: Phase 2 context]

```moonbit
pub(all) enum ReadOutcome {
  Progress(UInt64)
  EndOfStream
  Failed(CoreError, completed~ : UInt64)
}

pub(open) trait Reader {
  read(Self, MutByteLease) -> ReadOutcome
}
```

Keep `Seeker` separate and object-safe. Positions and origin-relative deltas must be converted through checked arithmetic before cursor mutation. [CITED: https://docs.moonbitlang.com/en/latest/language/methods.html]

### Pattern 4: Atomic Shared Budget Ledger

A charge request contains all dimensions it intends to consume. First validate every remaining counter; only if all pass, subtract all counters. Child scopes retain the same ledger object and may narrow limits but never reset them. Enter depth before work and use `defer` to guarantee leave on return/error/break paths. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html]

### Pattern 5: Stable Structured Failure, Canonical Rendering

Expose `ErrorCategory` and `ErrorCode` as public enums. Keep `CoreError` opaque with typed accessors for operation, requested/completed counts, range, source offset, limit, and bounded backend context. Render fields in one documented order with explicit escaping and ASCII numeric conversion. Do not use derived `Debug` or backend exception strings as the stable display contract. [VERIFIED: D-12 through D-14]

### Anti-Patterns to Avoid

- **Check after arithmetic/access:** the wrap or out-of-range action has already happened; validate operands first. [CITED: https://cwe.mitre.org/data/definitions/190.html]
- **Raw `Int` for public sizes:** leaks a 32-bit allocation/index type into logical semantics. [VERIFIED: pinned local core]
- **Expose backing arrays or raw mutable views:** bypasses lease, range, and structured-error invariants. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html]
- **`Ok(0)` means EOS:** creates no-progress infinite loops and loses state-machine clarity. [VERIFIED: D-08/D-09]
- **Charge counters one at a time:** a later rejection partially consumes budget. [VERIFIED: D-15]
- **Child budget copies:** reset/bypass parent allowance. Children share a ledger. [VERIFIED: D-16]
- **Global host singleton/default clock/logger/filesystem:** violates portability, determinism, testing, and D-17. [VERIFIED: RFC 0001]
- **Stable prose derived from `Debug`:** compiler/library representation changes would silently break consumers. [VERIFIED: D-12/D-13]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Raw storage allocation | Custom allocator or memory manager in MoonBit | Built-in `Bytes`/`FixedArray[Byte]` behind budgeted constructors | Runtime owns memory safety and cross-target representation. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html] |
| Dynamic interface dispatch | Bespoke tagged callback tables | Object-safe `pub(open) trait` and `&Trait` | Native language mechanism, downstream-implementable, type checked. [CITED: https://docs.moonbitlang.com/en/latest/language/methods.html] |
| Cleanup on every control path | Repeated manual leave/invalidate calls | `defer` around the scoped body | Runs on normal return, error, break, and continue. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html] |
| Error carrier mechanics | String-only errors or ad-hoc JSON maps | `Result`/typed records/enums plus one canonical renderer | Preserves machine semantics without parsing prose. [CITED: https://docs.moonbitlang.com/en/stable/language/error-handling.html] |
| Mutable byte primitive | Reimplement byte arrays | `FixedArray[Byte]` internally plus MNF lease wrapper | Built-in portable storage; MNF adds policy rather than memory representation. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html] |

**Key insight:** this phase should hand-roll the MNF safety policy and state machines, not storage, polymorphism, cleanup, or error-effect machinery already owned by MoonBit. [VERIFIED: local toolchain and locked decisions]

## Common Pitfalls

### Pitfall 1: Backend Narrowing Hidden Inside Allocation or Indexing
**What goes wrong:** a valid `UInt64` logical length truncates when converted to `Int`, so validation and actual access disagree.  
**Why it happens:** `UInt64::to_int` exists as a plain conversion while backend containers take `Int`. [VERIFIED: pinned local interfaces]  
**How to avoid:** centralize a checked narrowing function and forbid direct `.to_int()` in byte/I/O/budget packages except inside that implementation.  
**Warning signs:** raw casts near `Bytes::new`, slice endpoints, cursors, or loop bounds.

### Pitfall 2: Mutable Lease Copies Mistaken for Linear Ownership
**What goes wrong:** a copied handle or second constructor creates overlapping mutation windows.  
**Why it happens:** MoonBit mutable views are reference-backed; the language does not provide Rust-style static borrowing. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html]  
**How to avoid:** track one shared runtime lease identity, never expose the backing store, validate active state per operation, and test acquire/acquire, split/split, use-after-scope, and overlap rejection.  
**Warning signs:** public functions returning raw `MutArrayView`, `FixedArray`, or multiple views without lease state.

### Pitfall 3: Exact I/O Spins on No Progress
**What goes wrong:** a backend repeatedly reports neither progress nor EOS/failure.  
**Why it happens:** ambiguous count-only return values.  
**How to avoid:** outcome enums must make no-progress invalid; exact loops fail deterministically after one no-progress outcome.  
**Warning signs:** `while completed < requested` with no state transition assertion.

### Pitfall 4: Budget Rejection Mutates State
**What goes wrong:** bytes are deducted before allocation count or work units reject, making retries nondeterministic.  
**Why it happens:** incremental counter updates.  
**How to avoid:** calculate and validate the complete charge, then commit once.  
**Warning signs:** assignments to remaining fields before all guards have passed.

### Pitfall 5: Built-In Allocation Cannot Reliably Surface Physical OOM
**What goes wrong:** `Bytes::new`/`FixedArray::make` do not return a recoverable allocation error, so physical runtime OOM cannot be confused with a guaranteed structured result. [VERIFIED: pinned local interfaces]  
**Why it happens:** the built-in allocation signatures return containers directly.  
**How to avoid:** guarantee structured range and budget rejection before allocation; include an injectable allocator/test double or adapter mapping seam that can produce `AllocationFailed`, and document that unrecoverable runtime OOM is outside the portable language guarantee unless the backend exposes recovery.  
**Warning signs:** tests claim to induce real OOM or code catches a non-existent allocation effect.

### Pitfall 6: Error Rendering Leaks Ambient Data
**What goes wrong:** paths, locale, clocks, exception class names, or platform codes make output nondeterministic and may disclose host details.  
**How to avoid:** bound and normalize adapter context, use portable codes, fixed ordering and escaping, and compare snapshots on all targets. [VERIFIED: D-12 through D-14]  
**Warning signs:** `to_string()` of foreign errors or direct `Debug` output in public diagnostics.

## Code Examples

### Balanced Nested Budget Scope

```moonbit
fn with_nested_budget[T](budget : Budget, body : (BudgetScope) -> T raise?) -> T raise? {
  let scope = budget.enter_depth()
  defer scope.leave()
  body(scope)
}
```

The `defer` cleanup rule is documented by MoonBit; the concrete budget API is the recommended MNF shape. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html]

### Checked Half-Open Range

```moonbit
pub fn Range::from_start_length(
  start : UInt64,
  length : UInt64,
) -> Result[Range, CoreError] {
  match checked_add(start, length) {
    Err(error) => Err(error.with_operation("range"))
    Ok(end) => Ok(Range::{ start, end })
  }
}
```

An empty range is represented by `start == end`; all subrange calculations repeat the same checked relative-window rule. [VERIFIED: D-02/D-05]

## State of the Art

| Old/unsafe approach | Current recommended approach | Evidence | Impact |
|---------------------|------------------------------|----------|--------|
| Treat `Int` arithmetic as checked | Guard `UInt64` operations before applying wrapping operators | Pinned core overflow tests and CWE-190. [VERIFIED: local toolchain] | Prevents wrap-before-allocation/access. |
| Public mutable container slices | Abstract wrappers plus runtime lease state | Current MoonBit exposes `MutArrayView`, while abstract types are the encapsulation mechanism. [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html] | Enforces MNF alias policy. |
| One stream trait with mandatory seek | Separate object-safe `Reader`, `Writer`, `Seeker` traits | Current trait objects support capability-specific runtime polymorphism. [CITED: https://docs.moonbitlang.com/en/latest/language/methods.html] | Non-seekable streams are normal, not failures. |
| Ambient/global services | Explicit small capability objects | Accepted RFC 0001. [VERIFIED: repository] | Portable deterministic composition. |

**Deprecated/outdated:** do not migrate this phase opportunistically to rollout-sensitive `moon.mod`/`moon.pkg` manifest formats; preserve checked `moon.mod.json` plus the repository's canonical `moon.pkg` syntax until the compatibility-floor decision. [VERIFIED: pinned toolchain feature flags and `.planning/research/STACK.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All implementation recommendations are derived from locked context, accepted repository contracts, official MoonBit documentation, pinned installed core source/interfaces, or explicitly labeled inference. No training-only claim is used. [VERIFIED: research source audit]

## Open Questions (RESOLVED)

1. **Resolved: use a runtime-validated callback-scoped mutable lease, confirmed by an early four-target compile/test spike.**
   - What we know: raw mutable views cannot enforce D-06, and abstract wrapper state can enforce runtime leases. [VERIFIED: pinned core and D-06]
   - What's unclear: whether the best v0.1 surface is callback-scoped leasing, explicit acquire/release, or mutation methods directly on owned storage.
   - Resolution: the bytes plan begins with a package-local compile/test spike, then ships callback-scoped `MutByteLease` acquisition with shared active-state validation, deterministic invalidation, and checked disjoint splitting. If the pinned compiler rejects the exact callback shape, the spike may select an equivalent scoped mutation surface, but the runtime exclusivity/invalidation behavior remains locked and raw mutable views remain private. [INFERENCE: D-06 plus pinned MoonBit mutable-view semantics]

2. **Resolved: physical built-in OOM remains unrecoverable; explicit budget and injected allocator rejection are the testable structured paths.**
   - What we know: standard constructors return containers directly, while D-07 requires allocation failure to be distinguishable. [VERIFIED: pinned interfaces and D-07]
   - What's unclear: no portable catchable OOM effect was found in the pinned public API.
   - Resolution: expose `AllocationFailed` only through an injected allocator/adapter seam and deterministic test doubles; guarantee structured checked-range and budget rejection before allocation; explicitly document that built-in runtime physical OOM is not a portable catchable result. [VERIFIED: pinned allocation signatures; D-07]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | build/check/test/docs | yes | `0.1.20260713 (75c7e1f)` | none required [VERIFIED: local command] |
| `moonc` | compiler behavior | yes | `v0.10.4+2cc641edf` | none required [VERIFIED: local command] |
| `moonrun` | test execution | yes | `0.1.20260713 (75c7e1f)` | none required [VERIFIED: local command] |
| `moonbitlang/core` | standard containers/types | yes | toolchain-bundled | pinned installed source/interfaces [VERIFIED: local filesystem] |

The existing workspace baseline passes `moon check --target all --deny-warn --frozen` and `moon test --target all --frozen` with 3/3 tests on each required target. [VERIFIED: local execution 2026-07-16]

**Missing dependencies with no fallback:** none.  
**Missing dependencies with fallback:** Context7 was unavailable; official MoonBit docs plus pinned installed source/interfaces supplied the authoritative fallback. [VERIFIED: research session]

## Project Constraints (from AGENTS.md)

- Implement core algorithms and shared models in MoonBit; no foreign-stack core. [VERIFIED: AGENTS.md]
- Keep Native primary while portable packages deliberately support `js`, `wasm`, `wasm-gc`, and `native`. [VERIFIED: AGENTS.md]
- Keep any future FFI small, isolated, documented, replaceable, and outside this phase's portable packages. [VERIFIED: AGENTS.md]
- Maintain acyclic explicit package dependencies and independent module lifecycles. [VERIFIED: AGENTS.md]
- Keep candidate API status; public changes require migration notes and stable APIs later follow SemVer. [VERIFIED: AGENTS.md]
- Make operations deterministic, headless, and usable by CLI, Agent, MCP, and Wasm consumers without ambient state. [VERIFIED: AGENTS.md]
- Benchmark claims require declared reproducible workloads; this phase should not add marketing performance claims. [VERIFIED: AGENTS.md]
- New modules or breaking architectural boundaries require RFCs; Phase 2 must stay inside accepted RFC 0001. [VERIFIED: AGENTS.md]
- Public black-box tests, internal invariant tests, documentation examples, and declared-target checks are mandatory. [VERIFIED: AGENTS.md]
- Use the existing root quality workflow; do not bypass GSD for implementation edits. [VERIFIED: AGENTS.md]
- Prefer the codebase knowledge graph for code discovery; its current index contains documentation structure but no MoonBit symbols, so pinned local source inspection was the necessary fallback. [VERIFIED: graph queries in this session]

## Security Domain

### Applicable ASVS Categories

This is a portable library rather than a web application. ASVS is used only as the configured checklist vocabulary; CWE entries better describe the concrete library threats. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identity or authentication scope. [VERIFIED: Phase boundary] |
| V3 Session Management | no | No sessions or persistent principals. [VERIFIED: Phase boundary] |
| V4 Access Control | no | Capability presence controls available host behavior, not user authorization. [VERIFIED: D-17] |
| V5 Input Validation | yes | Checked numeric/range constructors, validated views, explicit stream outcomes, adapter mapping, and adversarial tests. [VERIFIED: CORE-01..07] |
| V6 Cryptography | no | No cryptographic primitive or protocol in scope. [VERIFIED: Phase boundary] |

### Known Threat Patterns for Portable Binary Libraries

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Integer overflow/truncation (CWE-190) | Tampering / Denial of Service | Precondition-based checked arithmetic and narrowing before allocation/access. [CITED: https://cwe.mitre.org/data/definitions/190.html] |
| Out-of-bounds read (CWE-125) | Information Disclosure / DoS | Opaque validated half-open windows; no raw unchecked access in public APIs. [CITED: https://cwe.mitre.org/data/definitions/125.html] |
| Out-of-bounds write (CWE-787) | Tampering / DoS | Exclusive validated mutable leases and checked destinations. [CITED: https://cwe.mitre.org/data/definitions/787.html] |
| Uncontrolled resource consumption (CWE-400) | Denial of Service | Shared bytes/allocation/dimension/depth/work budget, precharged before work. [CITED: https://cwe.mitre.org/data/definitions/400.html] |
| Allocation without limits (CWE-770) | Denial of Service | Allocation count/size limits and atomic rejection without partial consumption. [CITED: https://cwe.mitre.org/data/definitions/770.html] |
| Infinite exact-I/O loop | Denial of Service | Explicit EOS/failure/progress outcomes and deterministic no-progress rejection. [VERIFIED: D-08/D-09] |
| Ambient capability escalation | Elevation of Privilege / Information Disclosure | No fallback globals; composition root supplies only required capability objects. [VERIFIED: D-17] |
| Diagnostic host-data leakage | Information Disclosure | Bounded portable adapter context and deterministic renderer excluding paths/backend exceptions. [VERIFIED: D-13/D-14] |

## Sources

### Primary (HIGH confidence)

- Pinned local `moon 0.1.20260713`, `moonc v0.10.4`, `moonrun 0.1.20260713` and `C:/Users/Admin/.moon/lib/core` — exact integer, container, view, trait, and conversion interfaces plus overflow tests.
- `docs/rfcs/0001-moonbit-native-foundation.md`, Phase 2 context, requirements, target/API policies — accepted project boundary and locked behavior.
- [MoonBit fundamentals](https://docs.moonbitlang.com/en/stable/language/fundamentals.html) — numeric widths, byte containers/views, and `defer`.
- [MoonBit packages/access control](https://docs.moonbitlang.com/en/latest/language/packages.html) — abstract/readonly/public types and trait visibility.
- [MoonBit methods and traits](https://docs.moonbitlang.com/en/latest/language/methods.html) — open traits and object-safe trait objects.
- [MoonBit error handling](https://docs.moonbitlang.com/en/stable/language/error-handling.html) — typed errors, `Result`, and explicit effects.
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) and [workspace support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html) — supported targets, reachable dependency checks, and root commands.
- [MoonBit tests](https://docs.moonbitlang.com/en/stable/language/tests.html) — built-in test modes.
- MITRE CWE-190, CWE-125, CWE-787, CWE-400, CWE-770 — authoritative weakness definitions and mitigations.

### Secondary (MEDIUM confidence)

- [Official mooncakes `moonbitlang/core`](https://mooncakes.io/docs/moonbitlang/core/) — current published standard-library documentation, cross-checked against the newer pinned local bundle.
- [OWASP ASVS project](https://owasp.org/www-project-application-security-verification-standard/) — checklist category vocabulary only; concrete controls are library-domain CWE mitigations.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — exact local versions and bundled interfaces executed/inspected.
- Architecture: HIGH — constrained by accepted RFC, locked context, and official language mechanisms.
- Pitfalls: HIGH — derived from pinned wrapping/conversion/view behavior plus authoritative CWE categories.

**Research date:** 2026-07-16  
**Valid until:** 2026-08-15, or immediately if the pinned MoonBit toolchain changes.
