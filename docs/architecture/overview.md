<!-- generated-by: gsd-doc-writer -->
# Architecture

## System overview

MoonBit Native Foundation is a layered workspace of portable, bounded
infrastructure modules. Document and scene inputs are parsed into typed data,
graphics modules turn geometry into pixels, and foundation modules provide
storage, color, I/O, diagnostics, and resource-budget contracts. The workspace
contains no service process or ambient runtime: examples call public module
APIs directly and produce deterministic in-memory or file-oriented results.

## Component diagram

```text
SVG document
     |
     v
  mb-svg  -------->  mb-canvas  -------->  mb-image
     |                    |                  |
     +--------------------+------------------+
                          v                  v
                       mb-color          mb-core
```

The arrows represent public dependency direction. `mb-svg` owns parsing and
scene lowering, `mb-canvas` owns geometry-to-raster execution, `mb-image` owns
pixel storage and codecs, `mb-color` owns color semantics, and `mb-core` owns
checked arithmetic, budgets, bytes, I/O, errors, and host capabilities.

## Data flow

1. A consumer creates bounded input, output, and resource limits from
   `mb-core` contracts.
2. A format module such as `mb-svg` or `mb-image/png` validates the input and
   constructs a typed scene, image, or resumable codec state.
3. `mb-svg` lowers a scene tree to a `DrawingList`; `mb-canvas` evaluates that
   list against a mutable `mb-image` surface using coverage-aware rasterization.
4. Image codecs and caller-buffered machines expose only accepted progress and
   sticky terminal outcomes, leaving rejected caller buffers unchanged.
5. The consumer reads an immutable image view, encoded bytes, or structured
   diagnostics without depending on a GUI or host-global state.

## Key abstractions

| Abstraction | Location | Responsibility |
| --- | --- | --- |
| `OwnedImage` | `modules/mb-image/storage/owned_image.mbt` | Owns validated image storage and exposes immutable or scoped mutable views. |
| `ImageView` / `MutImageView` | `modules/mb-image/storage/views.mbt` | Provides checked pixel/component access and disjoint mutable leases. |
| `DrawingList` | `modules/mb-canvas/canvas/draw_list.mbt` | Records deterministic fill, stroke, transform, and clip operations. |
| `CanvasPath` | `modules/mb-canvas/canvas/path_builder.mbt` | Builds line, Bézier, rectangle, arc, and closed path geometry. |
| `render` | `modules/mb-canvas/canvas/rasterize.mbt` | Rasterizes a drawing list into an `mb-image` surface. |
| `SceneNode` | `modules/mb-svg/svg/scene.mbt` | Represents the bounded SVG scene tree and its inherited paint state. |
| `parse_svg` / `lower_to_drawing_list` | `modules/mb-svg/svg/scene.mbt`, `modules/mb-svg/svg/lower.mbt` | Separates document parsing from canvas execution. |
| `CodecLimits` | `modules/mb-image/codec/contracts.mbt` | Bounds probe, input, output, geometry, pixel, and work consumption. |

## Directory structure rationale

```text
modules/       Independently publishable MoonBit modules.
examples/      Public consumers used for end-to-end behavior checks.
fixtures/      Versioned conformance inputs and expected evidence.
benchmarks/    Reproducible benchmark workloads and baselines.
scripts/       PowerShell quality, fixture, benchmark, and compatibility tools.
qualification/ Generated or reviewed quality evidence.
policy/        Machine-readable governance and compatibility policy.
docs/rfcs/     Architecture and module charters.
docs/policies/ API, target, toolchain, licensing, and publication rules.
```

The module boundaries are intentional: a consumer can use core safety or image
storage without importing document parsing or rasterization.
