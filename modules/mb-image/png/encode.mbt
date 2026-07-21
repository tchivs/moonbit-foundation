///|
fn _png_encode_error(
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  context : String,
  requested? : UInt64,
  completed? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    category, code, operation="png-encode", requested?, completed?, limit?, context~,
  )
}

///|
fn _png_encode_capability(context : String) -> @error.CoreError {
  @codec.capability_unavailable("png-encode", context)
}

///|
fn _png_encode_limit(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> Result[Unit, @error.CoreError] {
  if requested > limit {
    Err(_png_encode_error(
      @error.ErrorCategory::Resource, @error.ErrorCode::BudgetExceeded,
      context, requested~, limit~, 
    ))
  } else {
    Ok(())
  }
}

///|
fn _png_encode_u32(value : UInt64) -> Result[UInt64, @error.CoreError] {
  if value == 0UL || value > 4294967295UL {
    Err(_png_encode_capability("png-u32-dimensions"))
  } else {
    Ok(value)
  }
}

///|
/// Validate every semantic and physical property before pixels are read or the
/// caller budget is charged. The canonical layout contains no padding rows.
fn _png_encode_source(source : @storage.ImageView) -> Result[UInt64, @error.CoreError] {
  if source.is_empty() {
    return Err(_png_encode_capability("empty-image"))
  }
  match _png_encode_u32(source.width()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match _png_encode_u32(source.height()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let format = source.format()
  let metadata = source.metadata()
  if format.component() != @model.ComponentType::U8 {
    return Err(_png_encode_capability("component-u8-required"))
  }
  if format.layout() != @model.PlaneLayout::Packed {
    return Err(_png_encode_capability("packed-required"))
  }
  if metadata.space() != @color.ColorSpaceIdentity::Srgb ||
    metadata.transfer() != @color.TransferIdentity::EncodedSrgb ||
    !metadata.profile().is_builtin_srgb() {
    return Err(_png_encode_capability("builtin-encoded-srgb-required"))
  }
  if metadata.orientation() != @model.Orientation::TopLeft {
    return Err(_png_encode_capability("top-left-required"))
  }
  if metadata.opaque_metadata().length() != 0 {
    return Err(_png_encode_capability("opaque-metadata-unsupported"))
  }
  let channels = match format.channels() {
    @model.ChannelOrder::Rgb =>
      if metadata.alpha() is Some(_) {
        return Err(_png_encode_capability("rgb-alpha-unsupported"))
      } else {
        3UL
      }
    @model.ChannelOrder::Rgba =>
      match metadata.alpha() {
        Some(@color.AlphaMode::Straight) => 4UL
        _ => return Err(_png_encode_capability("straight-rgba-required"))
      }
    _ => return Err(_png_encode_capability("rgb-or-rgba-required"))
  }
  let row_bytes = match @checked.checked_mul(source.width(), channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if source.row_bytes() != row_bytes || source.row_stride() != row_bytes {
    return Err(_png_encode_capability("tightly-packed-rows-required"))
  }
  Ok(channels)
}

///|
priv struct PngEncodePreflight {
  channels : UInt64
  row_bytes : UInt64
  scanlines : UInt64
  blocks : UInt64
  idat_length : UInt64
  total_length : UInt64
  disposition : @metadata.MetadataDisposition
}

///|
/// The one authoritative, atomic admission path for eager and future stream
/// callers. All fallible arithmetic and disposition construction happen before
/// the single resource charge.
fn _png_encode_preflight(
  source : @storage.ImageView,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngEncodePreflight, @error.CoreError] {
  let channels = match _png_encode_source(source) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let pixels = match @checked.checked_mul(source.width(), source.height()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let row_bytes = match @checked.checked_mul(source.width(), channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let scanline_width = match @checked.checked_add(row_bytes, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let scanlines = match @checked.checked_mul(scanline_width, source.height()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let blocks = match @checked.checked_add((scanlines - 1UL) / 65535UL, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let payload_and_adler = match @checked.checked_add(scanlines, 6UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let block_headers = match @checked.checked_mul(blocks, 5UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let idat_length = match @checked.checked_add(payload_and_adler, block_headers) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let total_length = match @checked.checked_add(idat_length, 57UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for item in [
    ("width", source.width(), limits.max_width()),
    ("height", source.height(), limits.max_height()),
    ("pixels", pixels, limits.max_pixels()),
    ("output-bytes", total_length, limits.max_output_bytes()),
    ("work", total_length, limits.max_work()),
  ] {
    let (context, requested, limit) = item
    match _png_encode_limit(context, requested, limit) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  let disposition = match _png_empty_disposition() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match budget.charge(@budget.ResourceCharge::new(
    bytes=0UL, allocations=0UL, allocation_size=0UL, width=source.width(),
    height=source.height(), pixels=0UL, work=total_length,
  )) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok({ channels, row_bytes, scanlines, blocks, idat_length, total_length, disposition })
}

///|
pub impl @codec.ImageEncoder for PngEncoder with fn encode(
  _self,
  source,
  writer,
  _options,
  limits,
  budget,
  _diagnostics,
) {
  let machine = match PngEncodeMachine::new(source, limits, budget, _diagnostics) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  while true {
    let byte = match machine.present() {
      Err(error) => return Err(error)
      Ok(None) => break
      Ok(Some(value)) => value
    }
    let owner = match @bytes.OwnedBytes::from_bytes(
      Bytes::from_array([byte]), _png_private_budget(1UL),
    ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match @io.write_all(writer, owner.view()) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    match machine.acknowledge(byte) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  Ok(@codec.EncodeResult::new(machine.disposition(), machine.completed()))
}
