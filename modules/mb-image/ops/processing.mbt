///|
priv struct ProcessingBuiltinAllocator {}

///|
impl @bytes.Allocator for ProcessingBuiltinAllocator with fn approve(_self, _requested) {
  Ok(())
}

///|
fn processing_error(category : @error.ErrorCategory, code : @error.ErrorCode, operation : String, context : String) -> @error.CoreError {
  @error.CoreError::new(category, code, operation~, context~)
}

///|
fn processing_supported(source : @storage.ImageView) -> Bool {
  source.format().component() == @model.ComponentType::U8 &&
  source.format().layout() == @model.PlaneLayout::Packed &&
  source.format().channels() == @model.ChannelOrder::Rgba &&
  source.metadata().space() == @color.ColorSpaceIdentity::Srgb &&
  source.metadata().transfer() == @color.TransferIdentity::EncodedSrgb &&
  source.metadata().alpha() == Some(@color.AlphaMode::Straight)
}

///|
fn processing_disposition() -> @metadata.MetadataDisposition {
  let limits = @metadata.MetadataLimits::new(
    max_entries=0UL, max_token_bytes=16UL, max_value_bytes=0UL,
    max_total_bytes=0UL, max_disposition_fields=5UL,
  )
  @metadata.MetadataDisposition::new(
    [
      @metadata.DispositionField::new("alpha", limits).unwrap(),
      @metadata.DispositionField::new("opaque", limits).unwrap(),
      @metadata.DispositionField::new("orientation", limits).unwrap(),
      @metadata.DispositionField::new("profile", limits).unwrap(),
    ],
    [@metadata.DispositionField::new("color", limits).unwrap()], [], false, limits,
  ).unwrap()
}

///|
fn processing_descriptor(source : @storage.ImageView, operation : String) -> Result[(@model.ImageDescriptor, UInt64), @error.CoreError] {
  if source.is_empty() {
    return Err(processing_error(@error.ErrorCategory::InvalidInput, @error.ErrorCode::InvalidDimensions, operation, "empty-operation-source"))
  }
  let pixels = match @checked.checked_mul(source.width(), source.height()) { Ok(v) => v
    Err(e) => return Err(e) }
  let length = match @checked.checked_mul(pixels, 4UL) { Ok(v) => v
    Err(e) => return Err(e) }
  let row = match @checked.checked_mul(source.width(), 4UL) { Ok(v) => v
    Err(e) => return Err(e) }
  let plane = match @model.PlaneDescriptor::new(0UL, length, row, row, 1UL, 1UL, source.width(), source.height()) { Ok(v) => v
    Err(e) => return Err(e) }
  match @model.ImageDescriptor::new(source.width(), source.height(), @model.ImageFormat::rgba8(), [plane], length, source.metadata()) {
    Ok(v) => Ok((v, pixels))
    Err(e) => Err(e)
  }
}

///|
fn preflight_processing_budget(budget : @budget.Budget, descriptor : @model.ImageDescriptor, work : UInt64, operation : String) -> Result[Unit, @error.CoreError] {
  let remaining = budget.remaining()
  let length = descriptor.storage_length()
  if remaining.bytes() < length || remaining.allocations() < 1UL || remaining.allocation_size() < length || remaining.width() < descriptor.width() || remaining.height() < descriptor.height() || remaining.pixels() < descriptor.pixel_count() || remaining.work() < work {
    Err(processing_error(@error.ErrorCategory::Resource, @error.ErrorCode::BudgetExceeded, operation, operation + "-output-budget"))
  } else { Ok(()) }
}

///|
fn load_linear_premultiplied(view : @storage.ImageView, x : UInt64, y : UInt64) -> Result[@alpha.PremultipliedNormalizedSrgba, @error.CoreError] {
  let r = match view.get_byte(x, y, 0UL) { Ok(v) => v
    Err(e) => return Err(e) }
  let g = match view.get_byte(x, y, 1UL) { Ok(v) => v
    Err(e) => return Err(e) }
  let b = match view.get_byte(x, y, 2UL) { Ok(v) => v
    Err(e) => return Err(e) }
  let a = match view.get_byte(x, y, 3UL) { Ok(v) => v
    Err(e) => return Err(e) }
  let alpha = @quantize.dequantize_alpha(@color.EncodedAlpha8::from_byte(a))
  let straight = @alpha.StraightNormalizedSrgba::linear(
    @transfer.decode_srgb(@quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(r))),
    @transfer.decode_srgb(@quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(g))),
    @transfer.decode_srgb(@quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(b))),
    alpha,
  )
  @alpha.premultiply_normalized(straight)
}

///|
fn load_linear_premultiplied_rgb8(
  view : @storage.ImageView,
  x : UInt64,
  y : UInt64,
) -> Result[@alpha.PremultipliedNormalizedSrgba, @error.CoreError] {
  let r = match view.get_byte(x, y, 0UL) { Ok(v) => v
    Err(e) => return Err(e) }
  let g = match view.get_byte(x, y, 1UL) { Ok(v) => v
    Err(e) => return Err(e) }
  let b = match view.get_byte(x, y, 2UL) { Ok(v) => v
    Err(e) => return Err(e) }
  @alpha.premultiply_normalized(
    @alpha.StraightNormalizedSrgba::linear(
      @transfer.decode_srgb(@quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(r))),
      @transfer.decode_srgb(@quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(g))),
      @transfer.decode_srgb(@quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(b))),
      @color.NormalizedAlpha::new(1.0).unwrap(),
    ),
  )
}

///|
fn store_linear_premultiplied(view : @storage.MutImageView, x : UInt64, y : UInt64, value : @alpha.PremultipliedNormalizedSrgba) -> Result[Unit, @error.CoreError] {
  let alpha_byte = @quantize.quantize_alpha(value.alpha()).value()
  if alpha_byte == b'\x00' {
    for channel = 0UL; channel < 4UL; channel = channel + 1UL {
      match view.set_byte(x, y, channel, b'\x00') { Ok(_) => ()
        Err(e) => return Err(e) }
    }
    return Ok(())
  }
  let straight = match @alpha.unpremultiply_normalized(value) { Ok(v) => v
    Err(e) => return Err(e) }
  let (r, g, b) = straight.linear_rgb().unwrap()
  let bytes = [
    @quantize.quantize_encoded_srgb(@transfer.encode_srgb(r)).value(),
    @quantize.quantize_encoded_srgb(@transfer.encode_srgb(g)).value(),
    @quantize.quantize_encoded_srgb(@transfer.encode_srgb(b)).value(),
    alpha_byte,
  ]
  for channel = 0UL; channel < 4UL; channel = channel + 1UL {
    match view.set_byte(x, y, channel, bytes[channel.to_int()]) { Ok(_) => ()
      Err(e) => return Err(e) }
  }
  Ok(())
}

///|
fn store_linear_premultiplied_rgb8(
  view : @storage.MutImageView,
  x : UInt64,
  y : UInt64,
  value : @alpha.PremultipliedNormalizedSrgba,
) -> Result[Unit, @error.CoreError] {
  let (r, g, b) = value.linear_rgb().unwrap()
  let bytes = [
    @quantize.quantize_encoded_srgb(@transfer.encode_srgb(r)).value(),
    @quantize.quantize_encoded_srgb(@transfer.encode_srgb(g)).value(),
    @quantize.quantize_encoded_srgb(@transfer.encode_srgb(b)).value(),
  ]
  for channel = 0UL; channel < 3UL; channel = channel + 1UL {
    match view.set_byte(x, y, channel, bytes[channel.to_int()]) { Ok(_) => ()
      Err(e) => return Err(e) }
  }
  Ok(())
}

///|
fn allocate_processing(source : @storage.ImageView, budget : @budget.Budget, work : UInt64, operation : String) -> Result[(@storage.OwnedImage, @metadata.MetadataDisposition), @error.CoreError] {
  if !processing_supported(source) {
    return Err(processing_error(@error.ErrorCategory::Capability, @error.ErrorCode::CapabilityUnavailable, operation, operation + "-format"))
  }
  let (descriptor, _) = match processing_descriptor(source, operation) { Ok(v) => v
    Err(e) => return Err(e) }
  match preflight_processing_budget(budget, descriptor, work, operation) { Ok(_) => ()
    Err(e) => return Err(e) }
  match @storage.OwnedImage::new_operation(descriptor, budget, ProcessingBuiltinAllocator::{  } as &@bytes.Allocator, work) {
    Ok(output) => Ok((output, processing_disposition()))
    Err(e) => Err(e)
  }
}

///|
pub fn composite_source_over(source : @storage.ImageView, destination : @storage.ImageView, budget : @budget.Budget) -> Result[ImageOperationResult, @error.CoreError] {
  let operation = "image-composite-source-over"
  if !processing_supported(source) || !processing_supported(destination) {
    return Err(processing_error(@error.ErrorCategory::Capability, @error.ErrorCode::CapabilityUnavailable, operation, operation + "-format"))
  }
  if source.width() != destination.width() || source.height() != destination.height() {
    return Err(processing_error(@error.ErrorCategory::InvalidInput, @error.ErrorCode::InvalidDimensions, operation, "image-composite-source-over-dimensions"))
  }
  let sm = source.metadata(); let dm = destination.metadata()
  if !sm.profile().is_builtin_srgb() || !dm.profile().is_builtin_srgb() || sm.orientation() != dm.orientation() || sm.opaque_metadata().length() != 0 || dm.opaque_metadata().length() != 0 {
    return Err(processing_error(@error.ErrorCategory::InvalidInput, @error.ErrorCode::InvalidRange, operation, "image-composite-source-over-metadata"))
  }
  let work = match @checked.checked_mul(source.width(), source.height()) { Ok(v) => v
    Err(e) => return Err(e) }
  let (output, disposition) = match allocate_processing(source, budget, work, operation) { Ok(v) => v
    Err(e) => return Err(e) }
  match output.with_mut_view(fn(out) {
    for y = 0UL; y < source.height(); y = y + 1UL {
      for x = 0UL; x < source.width(); x = x + 1UL {
        let s = load_linear_premultiplied(source, x, y).unwrap()
        let d = load_linear_premultiplied(destination, x, y).unwrap()
        let (sr, sg, sb) = s.linear_rgb().unwrap(); let (dr, dg, db) = d.linear_rgb().unwrap()
        let sa = s.alpha().value(); let da = d.alpha().value(); let factor = 1.0 - sa
        let value = @alpha.PremultipliedNormalizedSrgba::linear(
          @color.LinearSrgbComponent::new(sr.value() + dr.value() * factor).unwrap(),
          @color.LinearSrgbComponent::new(sg.value() + dg.value() * factor).unwrap(),
          @color.LinearSrgbComponent::new(sb.value() + db.value() * factor).unwrap(),
          @color.NormalizedAlpha::new(sa + da * factor).unwrap(),
        ).unwrap()
        match store_linear_premultiplied(out, x, y, value) { Ok(_) => ()
          Err(e) => return Err(e) }
      }
    }; Ok(())
  }) { Ok(_) => Ok({ image_value: output, disposition_value: disposition })
    Err(e) => Err(e) }
}

///|
pub fn grayscale(source : @storage.ImageView, budget : @budget.Budget) -> Result[ImageOperationResult, @error.CoreError] {
  let operation = "image-grayscale"
  let work = match @checked.checked_mul(source.width(), source.height()) { Ok(v) => v
    Err(e) => return Err(e) }
  let (output, disposition) = match allocate_processing(source, budget, work, operation) { Ok(v) => v
    Err(e) => return Err(e) }
  match output.with_mut_view(fn(out) {
    for y = 0UL; y < source.height(); y = y + 1UL { for x = 0UL; x < source.width(); x = x + 1UL {
      let value = load_linear_premultiplied(source, x, y).unwrap(); let (r,g,b) = value.linear_rgb().unwrap()
      let l = r.value() * 0.2126 + g.value() * 0.7152 + b.value() * 0.0722
      let gray = @alpha.PremultipliedNormalizedSrgba::linear(@color.LinearSrgbComponent::new(l).unwrap(), @color.LinearSrgbComponent::new(l).unwrap(), @color.LinearSrgbComponent::new(l).unwrap(), value.alpha()).unwrap()
      match store_linear_premultiplied(out, x, y, gray) { Ok(_) => ()
        Err(e) => return Err(e) }
    }}; Ok(())
  }) { Ok(_) => Ok({ image_value: output, disposition_value: disposition })
    Err(e) => Err(e) }
}

///|
pub fn box_blur(source : @storage.ImageView, radius : UInt64, budget : @budget.Budget) -> Result[ImageOperationResult, @error.CoreError] {
  let operation = "image-box-blur"
  let twice = match @checked.checked_add(radius, radius) { Ok(v) => v
    Err(e) => return Err(e) }
  let diameter = match @checked.checked_add(twice, 1UL) { Ok(v) => v
    Err(e) => return Err(e) }
  let window = match @checked.checked_mul(diameter, diameter) { Ok(v) => v
    Err(e) => return Err(e) }
  let pixels = match @checked.checked_mul(source.width(), source.height()) { Ok(v) => v
    Err(e) => return Err(e) }
  let work = match @checked.checked_mul(pixels, window) { Ok(v) => v
    Err(e) => return Err(e) }
  let (output, disposition) = match allocate_processing(source, budget, work, operation) { Ok(v) => v
    Err(e) => return Err(e) }
  match output.with_mut_view(fn(out) {
    for y = 0UL; y < source.height(); y = y + 1UL { for x = 0UL; x < source.width(); x = x + 1UL {
      let mut rr = 0.0; let mut gg = 0.0; let mut bb = 0.0; let mut aa = 0.0
      for dy = 0UL; dy < diameter; dy = dy + 1UL { for dx = 0UL; dx < diameter; dx = dx + 1UL {
        let sy = if dy < radius { if y < radius - dy { 0UL } else { y - (radius - dy) } } else {
          match @checked.checked_add(y, dy - radius) {
            Ok(q) => if q >= source.height() { source.height() - 1UL } else { q }
            Err(_) => source.height() - 1UL
          }
        }
        let sx = if dx < radius { if x < radius - dx { 0UL } else { x - (radius - dx) } } else {
          match @checked.checked_add(x, dx - radius) {
            Ok(q) => if q >= source.width() { source.width() - 1UL } else { q }
            Err(_) => source.width() - 1UL
          }
        }
        let v = load_linear_premultiplied(source, sx, sy).unwrap(); let (r,g,b) = v.linear_rgb().unwrap(); rr = rr + r.value(); gg = gg + g.value(); bb = bb + b.value(); aa = aa + v.alpha().value()
      }}
      let value = @alpha.PremultipliedNormalizedSrgba::linear(@color.LinearSrgbComponent::new(rr / window.to_double()).unwrap(), @color.LinearSrgbComponent::new(gg / window.to_double()).unwrap(), @color.LinearSrgbComponent::new(bb / window.to_double()).unwrap(), @color.NormalizedAlpha::new(aa / window.to_double()).unwrap()).unwrap()
      match store_linear_premultiplied(out, x, y, value) { Ok(_) => ()
        Err(e) => return Err(e) }
    }}; Ok(())
  }) { Ok(_) => Ok({ image_value: output, disposition_value: disposition })
    Err(e) => Err(e) }
}
