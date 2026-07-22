# Phase 53: GrayAlpha16 Model and Checked Storage - Pattern Map

**Mapped:** 2026-07-23  
**Files analyzed:** 3 planned modifications; 4 supporting analogs  
**Analogs found:** 3 / 3

## Scope Decision

`53-CONTEXT.md` is the controlling artifact; no Phase 53 `RESEARCH.md` exists. The current code already has the generic packed-U16 storage/view path and the explicit fail-closed GrayAlpha operation boundary. Therefore, this phase should modify only the descriptor model and its model/storage regressions—**not** `owned_image.mbt`, `views.mbt`, `ops/`, or any codec files.

The worktree contains an unrelated untracked `.planning/tmp-phase53-research-plan.json`; it is outside this mapping and must be preserved.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/model/descriptor.mbt` | model / validation | transform | same file: `ImageFormat::graya8()` and `validate_gray_alpha_identity()` | exact |
| `modules/mb-image/model/model_test.mbt` | public black-box test | transform | same file: existing GrayAlpha8 descriptor and rejection matrix | exact |
| `modules/mb-image/storage/storage_test.mbt` | public black-box storage test | file-I/O / transform | same file: Gray16 component-byte test plus GrayAlpha8 two-channel test | exact-composite |

## Pattern Assignments

### `modules/mb-image/model/descriptor.mbt` (model / validation)

**Primary analog:** `modules/mb-image/model/descriptor.mbt:79-86` (`ImageFormat::graya8`)

Add `ImageFormat::graya16()` immediately beside `graya8()`, preserving the direct value-constructor factory style. Copy the two-channel packed/little-endian metadata, changing only `ComponentType::U8` to `ComponentType::U16`.

**Factory pattern** (`descriptor.mbt:79-86`):

```moonbit
pub fn ImageFormat::graya8() -> ImageFormat {
  {
    component_value: ComponentType::U8,
    channels_value: ChannelOrder::GrayAlpha,
    layout_value: PlaneLayout::Packed,
    endianness_value: Endianness::Little,
  }
}
```

**Two-component layout is already centralized** (`descriptor.mbt:119-125`):

```moonbit
pub fn ImageFormat::channel_count(self : ImageFormat) -> UInt64 {
  match self.channels_value {
    ChannelOrder::Gray => 1UL
    ChannelOrder::GrayAlpha => 2UL
    ChannelOrder::Rgb => 3UL
    ChannelOrder::Rgba => 4UL
  }
}
```

Do not add a second layout, plane-count, or backing-storage branch. The existing `GrayAlpha => 2UL` drives packed row shape and view channel bounds for both U8 and U16 identities.

**Admission analog:** `modules/mb-image/model/descriptor.mbt:455-505` (`validate_alpha_identity`, `validate_gray_alpha_identity`)

Preserve the straight-alpha requirement and all metadata/layout checks. Widen only the component predicate from the current U8-only rule to the two explicitly supported components (`U8` or `U16`); do not normalize or admit F32, planar, big-endian, non-sRGB, non-builtin-profile, or non-top-left variants.

```moonbit
fn validate_alpha_identity(
  format : ImageFormat,
  metadata : ImageMetadata,
) -> Result[Unit, @error.CoreError] {
  let valid = match format.channels() {
    ChannelOrder::Rgba => metadata.alpha() is Some(_)
    ChannelOrder::GrayAlpha => metadata.alpha() is Some(@color.AlphaMode::Straight)
    _ => metadata.alpha() is None
  }
  // Existing typed InvalidEncoding "image-alpha-mode" failure follows.
}

fn validate_gray_alpha_identity(
  format : ImageFormat,
  metadata : ImageMetadata,
) -> Result[Unit, @error.CoreError] {
  if format.channels() != ChannelOrder::GrayAlpha {
    return Ok(())
  }
  let valid = format.component() == ComponentType::U8 &&
    format.layout() == PlaneLayout::Packed &&
    format.endianness() == Endianness::Little &&
    metadata.space() == @color.ColorSpaceIdentity::Srgb &&
    metadata.transfer() == @color.TransferIdentity::EncodedSrgb &&
    metadata.profile().is_builtin_srgb() &&
    metadata.orientation() == Orientation::TopLeft
  // Existing typed InvalidEncoding "image-gray-alpha-identity" failure follows.
}
```

**Validation ordering to retain** (`descriptor.mbt:599-626`):

```moonbit
let expected_plane_count = if format.layout() == PlaneLayout::Packed {
  1UL
} else {
  format.channel_count()
}
// ... reject image-plane-count ...
match validate_alpha_identity(format, metadata) {
  Err(error) => return Err(error)
  Ok(_) => ()
}
match validate_gray_alpha_identity(format, metadata) {
  Err(error) => return Err(error)
  Ok(_) => ()
}
for plane in planes {
  match validate_plane_shape(width, height, format, plane) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
}
```

Keep this fail-closed sequence. It means malformed GrayAlpha16 metadata is rejected through the current typed descriptor boundary before any owned-storage allocation is possible.

**Compatibility guard; no change expected:** `modules/mb-image/model/descriptor.mbt:730-745`

```moonbit
match self.format_value.channels() {
  ChannelOrder::Rgb => self.metadata_value.alpha() is None
  ChannelOrder::Rgba => self.metadata_value.alpha() is Some(_)
  ChannelOrder::Gray => false
  ChannelOrder::GrayAlpha => false
}
```

Leave this as-is. A valid GrayAlpha16 descriptor must remain unsupported by reference operations, just as GrayAlpha8 does.

---

### `modules/mb-image/model/model_test.mbt` (public black-box test / transform)

**Primary analog:** `modules/mb-image/model/model_test.mbt:235-347` (GrayAlpha8 valid descriptor and invalid-identity matrix)

Reuse the local public metadata helper rather than constructing metadata ad hoc.

**Metadata and typed-rejection helpers** (`model_test.mbt:33-56`):

```moonbit
fn image_metadata(
  alpha : @color.AlphaMode?,
  orientation : @model.Orientation,
) -> @model.ImageMetadata {
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    alpha,
    @profile.ProfileIdentity::builtin_srgb(),
    orientation,
    empty_opaque_metadata(),
  )
}

fn rejects_invalid_graya(
  format : @model.ImageFormat,
  planes : Array[@model.PlaneDescriptor],
  metadata : @model.ImageMetadata,
) -> Bool {
  match @model.ImageDescriptor::new(1UL, 1UL, format, planes, 4UL, metadata) {
    Err(error) => error.code() == @error.ErrorCode::InvalidEncoding
    Ok(_) => false
  }
}
```

**Valid-descriptor assertion shape** (`model_test.mbt:235-262`):

```moonbit
let descriptor = @model.ImageDescriptor::new(
  2UL,
  1UL,
  @model.ImageFormat::graya8(),
  [@model.PlaneDescriptor::new(
    0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL,
  ).unwrap()],
  4UL,
  image_metadata(
    Some(@color.AlphaMode::Straight),
    @model.Orientation::TopLeft,
  ),
).unwrap()
inspect(descriptor.format().channel_count(), content="2")
inspect(descriptor.plane_count(), content="1")
inspect(descriptor.supports_reference_operations(), content="false")
```

Mirror this with `graya16()`: use a two-pixel, one-plane descriptor with `row_stride`, `row_bytes`, and storage length of `8UL`; assert `U16`, `GrayAlpha`, packed/little-endian, two channels, one plane, `8` row bytes, explicit straight alpha, builtin sRGB, top-left metadata, and `supports_reference_operations() == false`.

**Negative matrix pattern** (`model_test.mbt:265-347`):

```moonbit
inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, missing_alpha), content="true")
inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, premultiplied), content="true")
// Explicit representation variants then use ImageFormat::new(... GrayAlpha ...).
inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, linear), content="true")
inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, non_builtin), content="true")
inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, rotated), content="true")
```

Update this matrix deliberately: the current explicit U16 GrayAlpha rejection is no longer valid once `graya16()` is admitted. Retain every legacy GrayAlpha8 rejection, add the valid GrayAlpha16 case, and replace that old rejection with malformed GrayAlpha16 cases (for example F32, planar, big-endian, missing/opaque alpha, premultiplied alpha, non-encoded/unknown colour metadata, non-builtin profile, and non-top-left orientation). Assert the established `InvalidEncoding` boundary—not a new error type. Keep the existing Gray/RGB/RGBA controls intact.

No `model_wbtest.mbt` edit is implied: its generated-case-ID check (`model_wbtest.mbt:219-221`) asserts behavioral test ownership and contains no format enumeration to widen.

---

### `modules/mb-image/storage/storage_test.mbt` (public black-box storage test / checked packed byte access)

**Composite analog:** `modules/mb-image/storage/storage_test.mbt:82-120`, `151-194`

Create a `graya16_descriptor()` helper by combining the existing Gray16 descriptor's U16 packed shape with the GrayAlpha8 descriptor's straight-alpha metadata. Reuse `packed_descriptor().metadata().opaque_metadata()` exactly as the GrayAlpha8 helper does.

**U16 descriptor helper** (`storage_test.mbt:82-98`):

```moonbit
fn gray16_descriptor() -> @model.ImageDescriptor {
  @model.ImageDescriptor::new(
    2UL,
    1UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16,
      @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed,
      @model.Endianness::Little,
    ).unwrap(),
    [@model.PlaneDescriptor::new(
      0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL,
    ).unwrap()],
    4UL,
    packed_descriptor().metadata(),
  ).unwrap()
}
```

**Straight-alpha metadata helper** (`storage_test.mbt:101-120`):

```moonbit
let metadata = @model.ImageMetadata::new(
  @color.ColorSpaceIdentity::Srgb,
  @color.TransferIdentity::EncodedSrgb,
  Some(@color.AlphaMode::Straight),
  @profile.ProfileIdentity::builtin_srgb(),
  @model.Orientation::TopLeft,
  packed_descriptor().metadata().opaque_metadata(),
)
```

For a two-pixel U16 GrayAlpha image, use one packed plane with `row_stride=8UL`, `row_bytes=8UL`, `extent_width=2UL`, `extent_height=1UL`, and `storage_length=8UL`.

**Checked U16 byte-access pattern** (`storage_test.mbt:151-176`):

```moonbit
image.with_mut_view(fn(view) {
  view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
  view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
  view.set_component_byte(1UL, 0UL, 0UL, 0UL, b'\xcd').unwrap()
  view.set_component_byte(1UL, 0UL, 0UL, 1UL, b'\xab').unwrap()
  Ok(())
}).unwrap()
let view = image.view()
inspect(view.get_component_byte(0UL, 0UL, 0UL, 0UL).unwrap(), content="b'\\x34'")
inspect(view.get_component_byte(0UL, 0UL, 0UL, 1UL).unwrap(), content="b'\\x12'")
inspect(view.get_component_byte(0UL, 0UL, 0UL, 2UL) is Err(_), content="true")
inspect(view.get_byte(0UL, 0UL, 0UL) is Err(_), content="true")
```

Mirror it for GrayAlpha16 with non-symmetric values in **both channels**. At one pixel, write/read gray byte indices `0,1` (for example `0x34,0x12`) and alpha byte indices `0,1` (for example `0xcd,0xab`); at a second pixel use a different pair if retaining the two-pixel shape. Assert the exact four independent reads, reject channel `2UL`, reject component byte `2UL`, and retain the U16 `get_byte` rejection. This proves the generic offset formula does not swap Gray/alpha components or U16 byte positions.

**Existing two-component U8 control** (`storage_test.mbt:179-194`):

```moonbit
image.with_mut_view(fn(view) {
  view.set_byte(0UL, 0UL, 0UL, b'\x13').unwrap()
  view.set_byte(0UL, 0UL, 1UL, b'\xe7').unwrap()
  Ok(())
}).unwrap()
inspect(view.get_byte(0UL, 0UL, 0UL).unwrap(), content="b'\\x13'")
inspect(view.get_byte(0UL, 0UL, 1UL).unwrap(), content="b'\\xE7'")
inspect(view.get_byte(0UL, 0UL, 2UL) is Err(_), content="true")
```

Keep this GrayAlpha8 regression unchanged; it is the direct legacy control required by D-04.

## Shared Patterns

### Descriptor-driven storage, no new representation

**Sources:** `modules/mb-image/model/descriptor.mbt:538-564`, `modules/mb-image/storage/owned_image.mbt:18-35`, `modules/mb-image/storage/views.mbt:238-295`, `modules/mb-image/storage/views.mbt:477-548`  
**Apply to:** the Phase 53 GrayAlpha16 descriptor and storage regression

`validate_plane_shape()` derives packed row bytes from `bytes_per_component() * channel_count()`. `OwnedImage::new()` allocates exactly `descriptor.storage_length()`, while the existing component-byte API bounds-checks channel and intra-component byte before calculating an offset:

```moonbit
let component_bytes = match
  @checked.checked_mul(format.bytes_per_component(), components) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let expected_row_bytes = match
  @checked.checked_mul(expected_width, component_bytes) {
  Err(error) => return Err(error)
  Ok(value) => value
}

// In ImageView::get_component_byte and MutImageView::validated_component_offset:
let channel_count = self.format_value.channel_count()
let bytes_per_component = self.format_value.bytes_per_component()
if self.is_empty() || x >= self.width_value || y >= self.height_value ||
  channel >= channel_count || component_byte >= bytes_per_component {
  return Err(/* existing InvalidRange component-byte-range */)
}
```

Do not alter `OwnedImage`, `ImageView`, or `MutImageView`: the required four-byte U16 GrayAlpha pixel layout follows from the accepted descriptor (`2 components * 2 bytes`) and these existing generic functions.

### Fail-closed operation compatibility

**Sources:** `modules/mb-image/model/descriptor.mbt:730-745`, `modules/mb-image/ops/copy_flip.mbt:50-69`  
**Apply to:** model regression only; no ops source change

```moonbit
if format.component() != @model.ComponentType::U8 ||
  format.layout() != @model.PlaneLayout::Packed ||
  metadata.space() != @color.ColorSpaceIdentity::Srgb ||
  metadata.transfer() != @color.TransferIdentity::EncodedSrgb {
  return false
}
// GrayAlpha => false
```

The U16 gate rejects GrayAlpha16 before the channel match; the explicit `GrayAlpha => false` remains the semantic guard for GrayAlpha8. Do not add operation support or modify operation tests in this phase.

### Public test conventions

**Sources:** `modules/mb-image/model/model_test.mbt:33-56`, `modules/mb-image/storage/storage_test.mbt:2-15`  
**Apply to:** all added coverage

Use black-box `@model`/`@storage` imports, existing constructor helpers, `unwrap()` for the accepted canonical case, and `inspect(...)` for exact observable values. Reuse `storage_budget(8UL)` for the new two-pixel GrayAlpha16 owned image; do not introduce fixtures, FFI, or target-specific branches.

## No Analog Found

None. The required public factory, descriptor admission, packed-U16 component access, two-channel straight-alpha metadata, and legacy fail-closed compatibility all have direct current analogs.

## Implementation Boundaries

- Do not modify `modules/mb-image/storage/owned_image.mbt` or `views.mbt`; their generic U8/U16 checked access is the behavior being reused and tested.
- Do not modify `modules/mb-image/ops/*`; both reference and copy/flip boundaries already reject GrayAlpha/U16 inputs.
- Do not modify `modules/mb-image/png/*`, release, FFI, target-specific, or copied-source files; Type-4/16 PNG behavior starts in Phase 54.
- Preserve the existing Gray8, Gray16, GrayAlpha8, RGB8, and RGBA8 model/storage tests verbatim; add GrayAlpha16 assertions alongside them.

## Metadata

**Analog search scope:** `modules/mb-image/model`, `modules/mb-image/storage`, `modules/mb-image/ops`, plus archived Phases 47 and 50  
**Files scanned:** 11 source/test/artifact files  
**Pattern extraction date:** 2026-07-23
