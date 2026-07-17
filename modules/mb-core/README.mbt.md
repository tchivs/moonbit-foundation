---
moonbit:
  import:
    - path: moonbit-foundation/mb-core/error
      alias: error
    - path: moonbit-foundation/mb-core/checked
      alias: checked
    - path: moonbit-foundation/mb-core/budget
      alias: budget
    - path: moonbit-foundation/mb-core/bytes
      alias: bytes
    - path: moonbit-foundation/mb-core/io
      alias: io
    - path: moonbit-foundation/mb-core/host
      alias: host
---

# mb-core

Portable safety and capability foundations for MoonBit Native Foundation.

`mb-core` is an independently versioned candidate module. Its public package
spine is deliberately acyclic and ordered as `error -> checked -> budget ->
bytes -> io -> host`. No API is stable yet; candidate changes require migration
notes.

Public publication remains blocked until ownership of the intended
`moonbit-foundation` mooncakes.io namespace is verified. The module already uses
its final intended name so consumers do not inherit a later rename.

## 0.1.0 candidate contract

| Field | Exact value |
| --- | --- |
| Module | `moonbit-foundation/mb-core` |
| Version/status | `0.1.0` candidate; no stable API or public release is claimed |
| License | Apache-2.0 ([repository license](../../LICENSE)) |
| Repository metadata | `https://github.com/moonbit-foundation/moonbit-foundation` |
| Direct module dependencies | none |
| Required targets | `+js+wasm+wasm-gc+native` |

The runnable examples in this document import the six public packages directly;
`moon check README.mbt.md --frozen --target <target>` checks them on each required
target. Candidate compatibility means every public change requires migration
notes. It does not establish the stable Semantic Versioning gate.

## Checked failures and deterministic diagnostics

Caller-controlled arithmetic, ranges, offsets, dimensions, and backend
narrowing return structured failures before access, allocation, or work. Error
category/code pairs are machine-readable; canonical text has fixed ordering and
escaping.

```mbt check
///|
test "checked underflow and offset failure are structured" {
  let underflow = @checked.checked_sub(8UL, 9UL).unwrap_err()
  inspect(
    underflow.code() == @error.ErrorCode::ArithmeticUnderflow,
    content="true",
  )
  let offset = @checked.CheckedOffset::new(0UL).retreat(1UL).unwrap_err()
  inspect(offset.code() == @error.ErrorCode::InvalidOffset, content="true")
}

///|
test "diagnostics render deterministically in encounter order" {
  let diagnostics = @error.Diagnostics::new()
  diagnostics.push(
    @error.Diagnostic::new(
      @error.DiagnosticSeverity::Warning,
      @error.CoreError::new(
        @error.ErrorCategory::Data,
        @error.ErrorCode::InvalidEncoding,
        operation="header",
      ),
    ),
  )
  inspect(diagnostics.length(), content="1")
  inspect(
    diagnostics.render(),
    content="warning|category=data|code=invalid-encoding|operation=\"header\"",
  )
}
```

## Budgets, owned bytes, views, and mutable leases

Resource charges are preflighted atomically across shared hierarchical limits.
Owned storage retains validated zero-copy immutable views. Mutable access is a
callback-scoped runtime lease; checked splitting consumes the parent and creates
only disjoint child leases.

```mbt check
///|
fn example_limits(bytes : UInt64) -> @budget.ResourceLimits {
  @budget.ResourceLimits::new(
    bytes~,
    allocations=4UL,
    allocation_size=bytes,
    width=16UL,
    height=16UL,
    pixels=256UL,
    depth=4UL,
    work=32UL,
  )
}

///|
struct ReadmeRejectingAllocator {}

///|
impl @bytes.Allocator for ReadmeRejectingAllocator with fn approve(
  _self,
  requested,
) {
  Err(
    @error.CoreError::new(
      @error.ErrorCategory::Resource,
      @error.ErrorCode::AllocationFailed,
      operation="readme_allocator",
      requested~,
    ),
  )
}

///|
test "budget thresholds reject before allocation" {
  let budget = @budget.Budget::new(example_limits(4UL))
  let owned = @bytes.OwnedBytes::new(4UL, budget).unwrap()
  inspect(owned.length(), content="4")
  inspect(
    @bytes.OwnedBytes::new(1UL, budget).unwrap_err().code() ==
    @error.ErrorCode::BudgetExceeded,
    content="true",
  )
}

///|
test "views and split mutable leases stay inside validated windows" {
  let budget = @budget.Budget::new(example_limits(4UL))
  let owned = @bytes.OwnedBytes::from_bytes(b"abcd", budget).unwrap()
  inspect(owned.view().subview(1UL, 2UL).unwrap().length(), content="2")
  owned
  .with_mut(0UL, 4UL, fn(parent) {
    let (left, right) = parent.split_mut(2UL).unwrap()
    left.set(0UL, b'A').unwrap()
    right.set(0UL, b'C').unwrap()
    inspect(parent.get(0UL) is Err(_), content="true")
    Ok(())
  })
  .unwrap()
  inspect(owned.view().get(0UL).unwrap() == b'A', content="true")
  inspect(owned.view().get(2UL).unwrap() == b'C', content="true")
  owned
  .with_mut(0UL, 4UL, fn(lease) {
    lease.set(3UL, b'D')
  })
  .unwrap()
  inspect(owned.view().get(3UL).unwrap() == b'D', content="true")
}

///|
test "injected allocator rejection is recoverable and does not charge" {
  let budget = @budget.Budget::new(example_limits(4UL))
  let allocator = ReadmeRejectingAllocator::{  } as &@bytes.Allocator
  let error =
    @bytes.OwnedBytes::new_with_allocator(4UL, budget, allocator).unwrap_err()
  inspect(error.code() == @error.ErrorCode::AllocationFailed, content="true")
  inspect(budget.remaining().bytes(), content="4")
}
```

Budget rejection and injected allocator rejection are portable structured
results. Built-in physical runtime OOM is unrecoverable on the pinned portable
toolchain and is not claimed as a catchable `CoreError`.

## Partial-to-exact bounded I/O and separate seeking

Readers and writers expose explicit progress, end-of-stream, and failure states.
Exact helpers accumulate partial progress, preserve completed counts, and reject
no-progress loops. Seeking is an independent capability implemented only by
types that support it; bounded wrappers remain non-seeking.

```mbt check
///|
struct ReadmePartialReader {
  mut step : Int
}

///|
impl @io.Reader for ReadmePartialReader with fn read(self, destination) {
  if self.step < 2 {
    ignore(destination.set(0UL, (self.step + 1).to_byte()))
    self.step = self.step + 1
    @io.ReadOutcome::Progress(1UL)
  } else {
    @io.ReadOutcome::EndOfStream
  }
}

///|
test "exact read accumulates partial progress" {
  let budget = @budget.Budget::new(example_limits(2UL))
  let destination = @bytes.OwnedBytes::new(2UL, budget).unwrap()
  let reader = ReadmePartialReader::{ step: 0 }
  let completed =
    destination
    .with_mut(0UL, 2UL, fn(lease) {
      @io.read_exact(reader as &@io.Reader, lease)
    })
    .unwrap()
  inspect(completed, content="2")
}

///|
test "bounded I/O does not imply seeking" {
  let source_budget = @budget.Budget::new(example_limits(4UL))
  let source = @bytes.OwnedBytes::from_bytes(b"abcd", source_budget).unwrap()
  let memory = @io.MemoryReader::new(source.view())
  let bounded = @io.BoundedReader::new(memory as &@io.Reader, 2UL)
  let destination_budget = @budget.Budget::new(example_limits(2UL))
  let destination = @bytes.OwnedBytes::new(2UL, destination_budget).unwrap()
  destination
  .with_mut(0UL, 2UL, fn(lease) {
    @io.read_exact(bounded as &@io.Reader, lease)
  })
  .unwrap()
  inspect(memory.seek(@io.SeekOrigin::Start, 0L).unwrap(), content="0")
}
```

## Explicit host capabilities

Portable algorithms receive only the individual host capabilities they need.
There is no ambient fallback, native adapter, global environment, or mandatory
all-capabilities singleton in the portable package graph.

```mbt check
///|
test "host fakes are individually injected" {
  let files = @host.FakeFileCapability::new("asset.bin", b"file")
  let resources = @host.FakeResourceResolver::new("logo", b"resource")
  let clock = @host.FakeClock::new(40UL)
  let cancellation = @host.FakeCancellation::new(false)
  inspect(files.read("asset.bin").unwrap() == b"file", content="true")
  inspect(resources.resolve("logo").unwrap() == b"resource", content="true")
  clock.advance(2UL).unwrap()
  inspect(clock.now_millis().unwrap(), content="42")
  inspect(cancellation.is_cancelled(), content="false")
}
```

## Supported targets and boundaries

Every public package declares the same required support set:

| Target | Status |
| --- | --- |
| `js` | Required |
| `wasm` | Required |
| `wasm-gc` | Required |
| `native` | Required and preferred |

Native-only host adapters, when introduced, remain isolated leaf packages and
cannot narrow portable packages. `mb-core` does not own color, image, SVG, font,
PDF, GUI, codec policy, filesystem policy, or application concepts. Those
layers compose these contracts without reversing the dependency spine.

Core algorithms and shared data models remain MoonBit-native. The module keeps
its own version and changelog lifecycle rather than releasing in lockstep with
`mb-color` or `mb-image`.

## Candidate evidence and deferred scope

The exact public package DAG, semantic interfaces, publication inventory, and
target declarations are machine-compared with `policy/foundation.json`. The
[0.1.0 candidate changelog](CHANGELOG.md) records this unpublished candidate.
Generated fixtures used by dependent color/image conformance are listed in
[`fixtures/manifest.json`](../../fixtures/manifest.json); `mb-core` itself ships
no runtime fixture loader and requires no filesystem state.

Deferred scope includes color and image semantics, concrete codecs, GUI/network
policy, native system adapters, registry publication, and a permanent minimum
toolchain floor. LLVM is experimental and is not part of the support matrix.

## Publication source contract

The records below are the exact pre-publication source intent for the `0.1.0`
candidate. The install command becomes usable only after registry publication;
it is not evidence that Mooncakes currently renders or resolves this module.
Package imports are listed in policy order, and the shared support, security,
changelog, compatibility, migration, and RFC routes remain explicit.

<!-- mnf-publication-source:v1 -->
01|install|moon add moonbit-foundation/mb-core@0.1.0
02|imports|moonbit-foundation/mb-core/error,moonbit-foundation/mb-core/checked,moonbit-foundation/mb-core/budget,moonbit-foundation/mb-core/bytes,moonbit-foundation/mb-core/io,moonbit-foundation/mb-core/host
03|status|candidate
04|targets|js,wasm,wasm-gc,native
05|toolchain|moon=0.1.20260713;moonc=0.10.4;moonrun=0.1.20260713
06|class|exact
07|support|docs/support.md
08|security|SECURITY.md
09|changelog|CHANGELOG.md
10|migration|not-required
11|rfc|not-required
12|impacts|none
13|registry-source|moon.mod.json
14|registry-render|unknown;proof=PROV-05;phase=8
15|ambiguity|none
<!-- /mnf-publication-source -->
