///|
fn orientation_metadata(
  orientation : @model.Orientation,
) -> @model.ImageMetadata {
  let opaque = @metadata.OpaqueMetadata::from_entries(
    [("test", "orientation", "raw", b"kept")],
    @metadata.MetadataLimits::new(
      max_entries=1UL,
      max_token_bytes=16UL,
      max_value_bytes=4UL,
      max_total_bytes=32UL,
      max_disposition_fields=8UL,
    ),
    wb_operation_limits(4UL, 0UL),
  ).unwrap()
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    None,
    @profile.ProfileIdentity::builtin_srgb(),
    orientation,
    opaque,
  )
}

///|
fn orientation_source(orientation : @model.Orientation) -> @storage.OwnedImage {
  let width = 3UL
  let height = 2UL
  let row_bytes = 9UL
  let descriptor = @model.ImageDescriptor::new(
    width,
    height,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(
        0UL, 18UL, row_bytes, row_bytes, 1UL, 1UL, width, height,
      ).unwrap(),
    ],
    18UL,
    orientation_metadata(orientation),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    wb_operation_limits(18UL, 0UL),
  ).unwrap()
  image
  .with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for channel = 0UL; channel < 3UL; channel = channel + 1UL {
          match
            view.set_byte(
              x,
              y,
              channel,
              ((y * width + x) * 3UL + channel + 1UL).to_byte(),
            ) {
            Err(error) => return Err(error)
            Ok(_) => ()
          }
        }
      }
    }
    Ok(())
  })
  .unwrap()
  image
}

///|
test "all eight orientations match the independent generated oracle" {
  for item in generated_orientation_vectors() {
    let (orientation, output_width, output_height, mappings) = item
    let source = orientation_source(orientation)
    let budget = wb_operation_limits(18UL, 18UL)
    let result = apply_orientation(source.view(), budget).unwrap()
    let output = result.image()
    inspect(output.descriptor().width() == output_width, content="true")
    inspect(output.descriptor().height() == output_height, content="true")
    inspect(
      output.metadata().orientation() == @model.Orientation::TopLeft,
      content="true",
    )
    inspect(output.metadata().opaque_metadata().length(), content="1")
    inspect(result.disposition().preserved_length(), content="4")
    inspect(result.disposition().transformed_length(), content="1")
    inspect(result.disposition().discarded_length(), content="0")
    inspect(result.disposition().is_lossy(), content="false")
    inspect(
      result.disposition().transformed(0).unwrap().value(),
      content="orientation",
    )
    for mapping in mappings {
      let (source_x, source_y, destination_x, destination_y) = mapping
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        inspect(
          output.view().get_byte(destination_x, destination_y, channel).unwrap() ==
          source.view().get_byte(source_x, source_y, channel).unwrap(),
          content="true",
        )
      }
    }
    inspect(budget.remaining().bytes(), content="0")
    inspect(budget.remaining().allocations(), content="0")
    inspect(budget.remaining().work(), content="0")
    inspect(budget.remaining().pixels(), content="58")
  }
}

///|
test "orientation failures leave every consumable counter unchanged" {
  let source = orientation_source(@model.Orientation::RightTop)
  let insufficient = wb_operation_limits(18UL, 17UL)
  let before = insufficient.remaining()
  inspect(
    apply_orientation(source.view(), insufficient) is Err(_),
    content="true",
  )
  let after = insufficient.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.work() == before.work(), content="true")

  let unsupported = unsupported_image(
    @model.ComponentType::U16,
    @model.ChannelOrder::Rgb,
    @model.PlaneLayout::Packed,
  )
  let unsupported_budget = wb_operation_limits(18UL, 18UL)
  let unsupported_before = unsupported_budget.remaining()
  inspect(
    apply_orientation(unsupported.view(), unsupported_budget) is Err(_),
    content="true",
  )
  let unsupported_after = unsupported_budget.remaining()
  inspect(
    unsupported_after.bytes() == unsupported_before.bytes(),
    content="true",
  )
  inspect(
    unsupported_after.allocations() == unsupported_before.allocations(),
    content="true",
  )
  inspect(
    unsupported_after.pixels() == unsupported_before.pixels(),
    content="true",
  )
  inspect(unsupported_after.work() == unsupported_before.work(), content="true")
}
