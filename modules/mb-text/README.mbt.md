---
moonbit:
  import:
    - path: tchivs/mb-core/budget
      alias: budget
    - path: tchivs/mb-core/error
      alias: error
    - path: tchivs/mb-font/font
      alias: font
    - path: tchivs/mb-text/text
      alias: text
---

# mb-text

`tchivs/mb-text` is the candidate, format-neutral text-shaping contract for
MoonBit Native Foundation. It owns explicit scalar, script, language,
direction, feature, limit, cluster, and positioned-run policy while
`tchivs/mb-font` retains font bytes and the sole guarded commit authority.
The direct module DAG is `mb-text -> mb-font -> mb-core`, with the additional
direct `mb-text -> mb-core` edge for shared budgets, errors, bytes, and checked
arithmetic.

## 0.1.0 candidate contract

| Field | Exact value |
| --- | --- |
| Public package | `tchivs/mb-text/text` |
| Version/status | `0.1.0` candidate; unpublished |
| Required targets | `js`, `wasm`, `wasm-gc`, and `native` |
| Preferred target | `native` |
| Direct module dependencies | `tchivs/mb-core@0.1.0`, `tchivs/mb-font@0.1.0` |
| Public operation | exactly `@text.shape(font, scalars, options, limits, budget)` |

Phase 108 demonstrates that this contract builds and its boundary tests run on
all four targets. It does **not** claim semantic target equivalence or release
qualification: Phase 113 retains that qualification authority. It also does
not open the nonempty real-font route; those requests remain fail-closed until
selected layout authority is admitted by later phases.

## Closed inputs and exact limits

Input is one ordered `Array[Int]` of Unicode scalar values. The complete array
is validated and copied before font authority is entered; clusters therefore
refer to zero-based scalar indices, never UTF-8 bytes, grapheme boundaries,
caret positions, bidi levels, or fallback spans.

- `ScriptTag` and `LanguageTag` are checked four-byte values.
- `LanguageChoice` is exactly `Default | Exact(LanguageTag)`.
- `Direction` is exactly `LeftToRight | RightToLeft`; there is no inference.
- `FeaturePolicy` exposes only caller choices for `liga` and `kern`. Required
  LangSys behavior and supported `rlig` behavior are not disableable.
- `ShapeLimits::new(max_input_scalars~, max_output_glyphs~)` requires both
  nonzero values. Its only accessors are `max_input_scalars()` and
  `max_output_glyphs()`; there is no default or alternate limit group.

```mbt check
///|
fn readme_options(direction : @text.Direction) -> @text.ShapingOptions {
  let script = match @text.ScriptTag::new(b"latn") {
    Ok(value) => value
    Err(_) => fail("the exact latn tag must be valid")
  }
  @text.ShapingOptions::new(
    script,
    @text.LanguageChoice::Default,
    direction,
    @text.FeaturePolicy::new(liga=true, kern=true),
  )
}

///|
fn readme_limits() -> @text.ShapeLimits {
  match
    @text.ShapeLimits::new(
      max_input_scalars=16UL,
      max_output_glyphs=16UL,
    ) {
    Ok(value) => value
    Err(_) => fail("nonzero shaping limits must be valid")
  }
}

///|
test "closed options and exact two-field limits are values" {
  let options = readme_options(@text.Direction::LeftToRight)
  inspect(options.direction() == @text.Direction::LeftToRight, content="true")
  inspect(options.features().liga(), content="true")
  inspect(options.features().kern(), content="true")
  inspect(readme_limits().max_input_scalars(), content="16")
  inspect(readme_limits().max_output_glyphs(), content="16")
}
```

## Empty success and public nonempty boundary

A valid empty request still validates every public value, snapshots the input,
guards the retained font, reads stable `units_per_em`, preflights, and performs
one combined caller/ancestor commit. Its exact text-side charge is `work=1`
with every other dimension zero. An exact work budget succeeds once; a
one-short budget fails without mutation or run publication.

The following literate functions are compile-checked against the real public
surface. Callers supply one already admitted static `Font`; no hidden fixture,
host lookup, or ambient state is involved.

```mbt check
///|
fn readme_shape_budget(work : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn readme_empty_shape(
  font : @font.Font,
) -> Result[@text.ShapedRun, @error.CoreError] {
  let scalars : Array[Int] = []
  @text.shape(
    font,
    scalars,
    readme_options(@text.Direction::LeftToRight),
    readme_limits(),
    readme_shape_budget(1UL),
  )
}

///|
fn readme_nonempty_fail_closed(
  font : @font.Font,
) -> Result[@text.ShapedRun, @error.CoreError] {
  @text.shape(
    font,
    [0x0041],
    readme_options(@text.Direction::LeftToRight),
    readme_limits(),
    readme_shape_budget(8UL),
  )
}
```

For Phase 108, `readme_empty_shape` returns an empty immutable run when the
font remains valid. `readme_nonempty_fail_closed` returns
`Capability`/`CapabilityUnavailable`, operation `text-shape`, context
`layout-unavailable`, and consumes no budget. This is the public capability
boundary, not a placeholder success path.

## Immutable run and direction semantics

`ShapedRun` exposes only `units_per_em`, explicit direction, checked
`total_advance`, `len`, and checked indexed `glyph_at`. Each returned
`PositionedGlyph` is a value containing a same-Font opaque `GlyphId`, a scalar
index cluster, and signed `Int64` advance, `x_offset`, and `y_offset`. No
backing array, raw source bytes, table fact, lookup index, mutation probe,
transaction handle, or commit capability is public.

Shaping is staged in logical input order. LTR publishes logical pen order. RTL
negates checked advances and reverses only the final positioned records;
signed design-space offsets and scalar clusters stay attached unchanged. A
ligature uses the minimum scalar index of its consumed inputs.

## Transaction, errors, and execution model

One synchronous request stages an immutable run and charge, then
`Font::with_shape_transaction` composes font/text charges, preflights the
complete budget hierarchy, performs the final retained-source guard, and makes
one combined commit. There is no partial publication, second charge,
persistent prepared transaction, or asynchronous continuation. No cache is
created or retained. Sharing
one retained `Font` or `Budget` across concurrent mutation is outside this
contract; revision guards make observed drift fail closed.

Observable precedence is:

1. caller validation — `InvalidInput`;
2. entry or named revision drift — `State`;
3. selected structural failure — `Data`;
4. selected semantic rejection — `Capability`;
5. shaping limits or budget preflight — `Resource`;
6. final revision drift — `State` before the sole commit.

`CoreError` category, code, operation, and context values are stable contract
facts. A nominal `FontShapeScope` can escape through generic `T`, but it has no
usable post-callback authority: later operations return `State` /
`InvalidRange`, operation `font-shape-scope`, context
`font-shape-scope-closed`. This is runtime invalidation, not a static lifetime
claim.

## Deliberate boundary

Phase 108 adds no GSUB, GPOS, GDEF, or legacy `kern` parser/executor to
`mb-text`. It performs no normalization, bidi analysis, segmentation,
fallback, host font lookup, filesystem/network I/O, external API or SDK call,
native FFI, registry integration, or persistent caching. The approved no UI
determination is exact: there is no frontend, visual, screenshot, responsive
layout, registry widget, or accessibility widget artifact.

Later phases may add selected format authority behind this unchanged public
boundary. Phase 113 alone owns licensed-font oracle evidence and semantic
four-target qualification.
