///|
fn processing_pipeline_limits(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  width : UInt64,
  height : UInt64,
  pixels : UInt64,
  depth : UInt64,
  work : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes~, allocations~, allocation_size~, width~, height~, pixels~, depth~, work~,
  ))
}

///|
fn processing_pipeline_unchanged(
  before : @budget.ResourceLimits,
  after : @budget.ResourceLimits,
) -> Bool {
  before.bytes() == after.bytes() &&
  before.allocations() == after.allocations() &&
  before.allocation_size() == after.allocation_size() &&
  before.width() == after.width() &&
  before.height() == after.height() &&
  before.pixels() == after.pixels() &&
  before.depth() == after.depth() &&
  before.work() == after.work()
}

///|
fn processing_pipeline_rgb_image(
  width : UInt64,
  height : UInt64,
  pixels : Array[Byte],
) -> @storage.OwnedImage {
  let length = width * height * 3UL
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    None,
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    @metadata.OpaqueMetadata::from_entries(
      [],
      @metadata.MetadataLimits::new(
        max_entries=0UL,
        max_token_bytes=16UL,
        max_value_bytes=0UL,
        max_total_bytes=0UL,
        max_disposition_fields=8UL,
      ),
      processing_pipeline_limits(0UL, 1UL, 0UL, 16UL, 16UL, 256UL, 0UL, 0UL),
    ).unwrap(),
  )
  let descriptor = @model.ImageDescriptor::new(
    width,
    height,
    @model.ImageFormat::rgb8(),
    [@model.PlaneDescriptor::new(
      0UL, length, width * 3UL, width * 3UL, 1UL, 1UL, width, height,
    ).unwrap()],
    length,
    metadata,
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    processing_pipeline_limits(length, 1UL, length, width, height, width * height, 0UL, 0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    let mut index = 0
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for channel = 0UL; channel < 3UL; channel = channel + 1UL {
          view.set_byte(x, y, channel, pixels[index]).unwrap()
          index = index + 1
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
test "processing pipeline insufficient resource leaves budget unchanged" {
  let foreground = processing_pipeline_rgb_image(1UL, 1UL, [
    b'\x0c', b'\x22', b'\x38',
  ])
  let destination = processing_pipeline_rgb_image(2UL, 1UL, [
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06',
  ])
  let resized = resize_nearest(
    foreground.view(),
    2UL,
    1UL,
    processing_pipeline_limits(6UL, 1UL, 6UL, 2UL, 1UL, 2UL, 0UL, 6UL),
  ).unwrap()
  let source_rgba = rgb8_to_straight_rgba8(
    resized.image().view(),
    processing_pipeline_limits(8UL, 1UL, 8UL, 2UL, 1UL, 2UL, 0UL, 8UL),
  ).unwrap()
  let destination_rgba = rgb8_to_straight_rgba8(
    destination.view(),
    processing_pipeline_limits(8UL, 1UL, 8UL, 2UL, 1UL, 2UL, 0UL, 8UL),
  ).unwrap()
  let budget = processing_pipeline_limits(8UL, 1UL, 8UL, 2UL, 1UL, 2UL, 0UL, 1UL)
  let before = budget.remaining()
  match composite_source_over(source_rgba.image().view(), destination_rgba.image().view(), budget) {
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::Resource, content="true")
      inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
      inspect(error.operation() == Some("image-composite-source-over"), content="true")
      inspect(error.context() == Some("image-composite-source-over-output-budget"), content="true")
    }
    Ok(_) => fail("insufficient composite work must reject")
  }
  inspect(processing_pipeline_unchanged(before, budget.remaining()), content="true")
}
