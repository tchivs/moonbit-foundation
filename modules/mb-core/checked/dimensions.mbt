///|
fn dimensions_error(width : UInt64, height : UInt64) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidDimensions,
    operation="dimensions_pixel_count",
    requested=height,
    limit=if width == 0UL { uint64_max } else { uint64_max / width },
  )
}

///|
/// Compute a logical pixel count only after the multiplication guard. Zero on
/// either axis remains a valid canonical empty size.
fn checked_pixel_count(
  width : UInt64,
  height : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match checked_mul(width, height) {
    Ok(count) => Ok(count)
    Err(_) => Err(dimensions_error(width, height))
  }
}

///|
/// Opaque dimensions with a prevalidated logical pixel count.
pub struct Dimensions {
  priv width_value : UInt64
  priv height_value : UInt64
  priv pixel_count_value : UInt64
}

///|
pub fn Dimensions::new(
  width : UInt64,
  height : UInt64,
) -> Result[Dimensions, @error.CoreError] {
  match checked_pixel_count(width, height) {
    Err(error) => Err(error)
    Ok(pixel_count) =>
      Ok({
        width_value: width,
        height_value: height,
        pixel_count_value: pixel_count,
      })
  }
}

///|
pub fn Dimensions::width(self : Dimensions) -> UInt64 {
  self.width_value
}

///|
pub fn Dimensions::height(self : Dimensions) -> UInt64 {
  self.height_value
}

///|
pub fn Dimensions::pixel_count(self : Dimensions) -> UInt64 {
  self.pixel_count_value
}

///|
/// Compute physical storage size through checked logical multiplication and the
/// package's sole backend narrowing function.
pub fn Dimensions::allocation_size(
  self : Dimensions,
  bytes_per_pixel : UInt64,
) -> Result[Int, @error.CoreError] {
  checked_allocation_size(self.pixel_count_value, bytes_per_pixel)
}
