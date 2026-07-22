///|
fn image_model_error(
  code : @error.ErrorCode,
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    code,
    operation="image_descriptor",
    requested~,
    limit~,
    context~,
  )
}

///|
pub(all) enum ComponentType {
  U8
  U16
  F32
} derive(Eq)

///|
pub(all) enum ChannelOrder {
  Gray
  GrayAlpha
  Rgb
  Rgba
} derive(Eq)

///|
pub(all) enum PlaneLayout {
  Packed
  Planar
} derive(Eq)

///|
pub(all) enum Endianness {
  Little
  Big
} derive(Eq)

///|
pub struct ImageFormat {
  priv component_value : ComponentType
  priv channels_value : ChannelOrder
  priv layout_value : PlaneLayout
  priv endianness_value : Endianness
}

///|
pub fn ImageFormat::new(
  component : ComponentType,
  channels : ChannelOrder,
  layout : PlaneLayout,
  endianness : Endianness,
) -> Result[ImageFormat, @error.CoreError] {
  Ok({
    component_value: component,
    channels_value: channels,
    layout_value: layout,
    endianness_value: endianness,
  })
}

///|
pub fn ImageFormat::rgb8() -> ImageFormat {
  {
    component_value: ComponentType::U8,
    channels_value: ChannelOrder::Rgb,
    layout_value: PlaneLayout::Packed,
    endianness_value: Endianness::Little,
  }
}

///|
pub fn ImageFormat::graya8() -> ImageFormat {
  {
    component_value: ComponentType::U8,
    channels_value: ChannelOrder::GrayAlpha,
    layout_value: PlaneLayout::Packed,
    endianness_value: Endianness::Little,
  }
}

///|
pub fn ImageFormat::rgba8() -> ImageFormat {
  {
    component_value: ComponentType::U8,
    channels_value: ChannelOrder::Rgba,
    layout_value: PlaneLayout::Packed,
    endianness_value: Endianness::Little,
  }
}

///|
pub fn ImageFormat::component(self : ImageFormat) -> ComponentType {
  self.component_value
}

///|
pub fn ImageFormat::channels(self : ImageFormat) -> ChannelOrder {
  self.channels_value
}

///|
pub fn ImageFormat::layout(self : ImageFormat) -> PlaneLayout {
  self.layout_value
}

///|
pub fn ImageFormat::endianness(self : ImageFormat) -> Endianness {
  self.endianness_value
}

///|
pub fn ImageFormat::channel_count(self : ImageFormat) -> UInt64 {
  match self.channels_value {
    ChannelOrder::Gray => 1UL
    ChannelOrder::GrayAlpha => 2UL
    ChannelOrder::Rgb => 3UL
    ChannelOrder::Rgba => 4UL
  }
}

///|
pub fn ImageFormat::bytes_per_component(self : ImageFormat) -> UInt64 {
  match self.component_value {
    ComponentType::U8 => 1UL
    ComponentType::U16 => 2UL
    ComponentType::F32 => 4UL
  }
}

///|
pub struct PlaneDescriptor {
  priv range_value : @checked.CheckedRange
  priv row_stride_value : UInt64
  priv row_bytes_value : UInt64
  priv subsample_x_value : UInt64
  priv subsample_y_value : UInt64
  priv extent_width_value : UInt64
  priv extent_height_value : UInt64
}

///|
pub fn PlaneDescriptor::new(
  start : UInt64,
  length : UInt64,
  row_stride : UInt64,
  row_bytes : UInt64,
  subsample_x : UInt64,
  subsample_y : UInt64,
  extent_width : UInt64,
  extent_height : UInt64,
) -> Result[PlaneDescriptor, @error.CoreError] {
  if subsample_x == 0UL || subsample_y == 0UL {
    return Err(
      image_model_error(
        @error.ErrorCode::InvalidDimensions,
        "plane-subsampling",
        0UL,
        1UL,
      ),
    )
  }
  if extent_width == 0UL || extent_height == 0UL || row_bytes == 0UL {
    return Err(
      image_model_error(
        @error.ErrorCode::InvalidDimensions,
        "plane-extent",
        0UL,
        1UL,
      ),
    )
  }
  if row_stride < row_bytes {
    return Err(
      image_model_error(
        @error.ErrorCode::InvalidRange,
        "plane-row-stride",
        row_stride,
        row_bytes,
      ),
    )
  }
  let preceding_rows = match
    @checked.checked_mul(extent_height - 1UL, row_stride) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let required_length = match @checked.checked_add(preceding_rows, row_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if length < required_length {
    return Err(
      image_model_error(
        @error.ErrorCode::InvalidRange,
        "plane-length",
        length,
        required_length,
      ),
    )
  }
  let range = match @checked.CheckedRange::from_start_length(start, length) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    range_value: range,
    row_stride_value: row_stride,
    row_bytes_value: row_bytes,
    subsample_x_value: subsample_x,
    subsample_y_value: subsample_y,
    extent_width_value: extent_width,
    extent_height_value: extent_height,
  })
}

///|
pub fn PlaneDescriptor::range(self : PlaneDescriptor) -> @checked.CheckedRange {
  self.range_value
}

///|
pub fn PlaneDescriptor::row_stride(self : PlaneDescriptor) -> UInt64 {
  self.row_stride_value
}

///|
pub fn PlaneDescriptor::row_bytes(self : PlaneDescriptor) -> UInt64 {
  self.row_bytes_value
}

///|
pub fn PlaneDescriptor::subsample_x(self : PlaneDescriptor) -> UInt64 {
  self.subsample_x_value
}

///|
pub fn PlaneDescriptor::subsample_y(self : PlaneDescriptor) -> UInt64 {
  self.subsample_y_value
}

///|
pub fn PlaneDescriptor::extent_width(self : PlaneDescriptor) -> UInt64 {
  self.extent_width_value
}

///|
pub fn PlaneDescriptor::extent_height(self : PlaneDescriptor) -> UInt64 {
  self.extent_height_value
}

///|
pub(all) enum Orientation {
  TopLeft
  TopRight
  BottomRight
  BottomLeft
  LeftTop
  RightTop
  RightBottom
  LeftBottom
} derive(Eq)

///|
pub fn Orientation::code(self : Orientation) -> Int {
  match self {
    TopLeft => 1
    TopRight => 2
    BottomRight => 3
    BottomLeft => 4
    LeftTop => 5
    RightTop => 6
    RightBottom => 7
    LeftBottom => 8
  }
}

///|
fn Orientation::swaps_axes(self : Orientation) -> Bool {
  match self {
    LeftTop | RightTop | RightBottom | LeftBottom => true
    _ => false
  }
}

///|
pub fn Orientation::display_width(
  self : Orientation,
  stored_width : UInt64,
  stored_height : UInt64,
) -> UInt64 {
  if self.swaps_axes() {
    stored_height
  } else {
    stored_width
  }
}

///|
pub fn Orientation::display_height(
  self : Orientation,
  stored_width : UInt64,
  stored_height : UInt64,
) -> UInt64 {
  if self.swaps_axes() {
    stored_width
  } else {
    stored_height
  }
}

///|
pub struct Rect {
  priv x_value : UInt64
  priv y_value : UInt64
  priv width_value : UInt64
  priv height_value : UInt64
  priv right_value : UInt64
  priv bottom_value : UInt64
}

///|
pub fn Rect::new(
  x : UInt64,
  y : UInt64,
  width : UInt64,
  height : UInt64,
) -> Result[Rect, @error.CoreError] {
  let right = match @checked.checked_add(x, width) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let bottom = match @checked.checked_add(y, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    x_value: x,
    y_value: y,
    width_value: width,
    height_value: height,
    right_value: right,
    bottom_value: bottom,
  })
}

///|
pub fn Rect::x(self : Rect) -> UInt64 {
  self.x_value
}

///|
pub fn Rect::y(self : Rect) -> UInt64 {
  self.y_value
}

///|
pub fn Rect::width(self : Rect) -> UInt64 {
  self.width_value
}

///|
pub fn Rect::height(self : Rect) -> UInt64 {
  self.height_value
}

///|
pub fn Rect::right(self : Rect) -> UInt64 {
  self.right_value
}

///|
pub fn Rect::bottom(self : Rect) -> UInt64 {
  self.bottom_value
}

///|
pub fn Rect::is_empty(self : Rect) -> Bool {
  self.width_value == 0UL || self.height_value == 0UL
}

///|
pub struct ImageMetadata {
  priv space_value : @color.ColorSpaceIdentity
  priv transfer_value : @color.TransferIdentity
  priv alpha_value : @color.AlphaMode?
  priv profile_value : @profile.ProfileIdentity
  priv orientation_value : Orientation
  priv opaque_value : @metadata.OpaqueMetadata
}

///|
pub fn ImageMetadata::new(
  space : @color.ColorSpaceIdentity,
  transfer : @color.TransferIdentity,
  alpha : @color.AlphaMode?,
  profile : @profile.ProfileIdentity,
  orientation : Orientation,
  opaque_metadata : @metadata.OpaqueMetadata,
) -> ImageMetadata {
  {
    space_value: space,
    transfer_value: transfer,
    alpha_value: alpha,
    profile_value: profile,
    orientation_value: orientation,
    opaque_value: opaque_metadata,
  }
}

///|
pub fn ImageMetadata::space(self : ImageMetadata) -> @color.ColorSpaceIdentity {
  self.space_value
}

///|
pub fn ImageMetadata::transfer(self : ImageMetadata) -> @color.TransferIdentity {
  self.transfer_value
}

///|
pub fn ImageMetadata::alpha(self : ImageMetadata) -> @color.AlphaMode? {
  self.alpha_value
}

///|
pub fn ImageMetadata::profile(self : ImageMetadata) -> @profile.ProfileIdentity {
  self.profile_value
}

///|
pub fn ImageMetadata::orientation(self : ImageMetadata) -> Orientation {
  self.orientation_value
}

///|
pub fn ImageMetadata::opaque_metadata(
  self : ImageMetadata,
) -> @metadata.OpaqueMetadata {
  self.opaque_value
}

///|
fn ceil_div(value : UInt64, divisor : UInt64) -> UInt64 {
  value / divisor + (if value % divisor == 0UL { 0UL } else { 1UL })
}

///|
fn validate_alpha_identity(
  format : ImageFormat,
  metadata : ImageMetadata,
) -> Result[Unit, @error.CoreError] {
  let valid = match format.channels() {
    ChannelOrder::Rgba => metadata.alpha() is Some(_)
    ChannelOrder::GrayAlpha => metadata.alpha() is Some(@color.AlphaMode::Straight)
    _ => metadata.alpha() is None
  }
  if valid {
    Ok(())
  } else {
    Err(
      image_model_error(
        @error.ErrorCode::InvalidEncoding,
        "image-alpha-mode",
        format.channel_count(),
        format.channel_count(),
      ),
    )
  }
}

///|
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
  if valid {
    Ok(())
  } else {
    Err(
      image_model_error(
        @error.ErrorCode::InvalidEncoding,
        "image-gray-alpha-identity",
        format.channel_count(),
        format.channel_count(),
      ),
    )
  }
}

///|
fn validate_plane_shape(
  width : UInt64,
  height : UInt64,
  format : ImageFormat,
  plane : PlaneDescriptor,
) -> Result[Unit, @error.CoreError] {
  if format.layout() == PlaneLayout::Packed &&
    (plane.subsample_x() != 1UL || plane.subsample_y() != 1UL) {
    return Err(
      image_model_error(
        @error.ErrorCode::InvalidDimensions,
        "image-packed-subsampling",
        plane.subsample_x(),
        1UL,
      ),
    )
  }
  let expected_width = ceil_div(width, plane.subsample_x())
  let expected_height = ceil_div(height, plane.subsample_y())
  if plane.extent_width() != expected_width ||
    plane.extent_height() != expected_height {
    return Err(
      image_model_error(
        @error.ErrorCode::InvalidDimensions,
        "image-plane-extent",
        plane.extent_width(),
        expected_width,
      ),
    )
  }
  let components = if format.layout() == PlaneLayout::Packed {
    format.channel_count()
  } else {
    1UL
  }
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
  if plane.row_bytes() != expected_row_bytes {
    Err(
      image_model_error(
        @error.ErrorCode::InvalidRange,
        "image-row-bytes",
        plane.row_bytes(),
        expected_row_bytes,
      ),
    )
  } else {
    Ok(())
  }
}

///|
pub struct ImageDescriptor {
  priv dimensions_value : @checked.Dimensions
  priv format_value : ImageFormat
  priv planes_value : Array[PlaneDescriptor]
  priv storage_length_value : UInt64
  priv metadata_value : ImageMetadata
}

///|
pub fn ImageDescriptor::new(
  width : UInt64,
  height : UInt64,
  format : ImageFormat,
  planes : Array[PlaneDescriptor],
  storage_length : UInt64,
  metadata : ImageMetadata,
) -> Result[ImageDescriptor, @error.CoreError] {
  if width == 0UL || height == 0UL {
    return Err(
      image_model_error(
        @error.ErrorCode::InvalidDimensions,
        "image-dimensions",
        0UL,
        1UL,
      ),
    )
  }
  let dimensions = match @checked.Dimensions::new(width, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let expected_plane_count = if format.layout() == PlaneLayout::Packed {
    1UL
  } else {
    format.channel_count()
  }
  if planes.length().to_uint64() != expected_plane_count {
    return Err(
      image_model_error(
        @error.ErrorCode::InvalidEncoding,
        "image-plane-count",
        planes.length().to_uint64(),
        expected_plane_count,
      ),
    )
  }
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
    if plane.range().end() > storage_length {
      return Err(
        image_model_error(
          @error.ErrorCode::InvalidRange,
          "image-plane-storage",
          plane.range().end(),
          storage_length,
        ),
      )
    }
  }
  for left = 0; left < planes.length(); left = left + 1 {
    for right = left + 1; right < planes.length(); right = right + 1 {
      if planes[left].range().overlaps(planes[right].range()) {
        return Err(
          image_model_error(
            @error.ErrorCode::InvalidRange,
            "image-plane-overlap",
            right.to_uint64(),
            planes.length().to_uint64(),
          ),
        )
      }
    }
  }
  Ok({
    dimensions_value: dimensions,
    format_value: format,
    planes_value: planes.copy(),
    storage_length_value: storage_length,
    metadata_value: metadata,
  })
}

///|
pub fn ImageDescriptor::width(self : ImageDescriptor) -> UInt64 {
  self.dimensions_value.width()
}

///|
pub fn ImageDescriptor::height(self : ImageDescriptor) -> UInt64 {
  self.dimensions_value.height()
}

///|
pub fn ImageDescriptor::pixel_count(self : ImageDescriptor) -> UInt64 {
  self.dimensions_value.pixel_count()
}

///|
pub fn ImageDescriptor::format(self : ImageDescriptor) -> ImageFormat {
  self.format_value
}

///|
pub fn ImageDescriptor::plane_count(self : ImageDescriptor) -> Int {
  self.planes_value.length()
}

///|
pub fn ImageDescriptor::plane(
  self : ImageDescriptor,
  index : Int,
) -> Result[PlaneDescriptor, @error.CoreError] {
  if index < 0 || index >= self.planes_value.length() {
    Err(
      image_model_error(
        @error.ErrorCode::InvalidRange,
        "image-plane-index",
        if index < 0 {
          0UL
        } else {
          index.to_uint64()
        },
        self.planes_value.length().to_uint64(),
      ),
    )
  } else {
    Ok(self.planes_value[index])
  }
}

///|
pub fn ImageDescriptor::storage_length(self : ImageDescriptor) -> UInt64 {
  self.storage_length_value
}

///|
pub fn ImageDescriptor::metadata(self : ImageDescriptor) -> ImageMetadata {
  self.metadata_value
}

///|
pub fn ImageDescriptor::display_width(self : ImageDescriptor) -> UInt64 {
  self.metadata_value.orientation().display_width(self.width(), self.height())
}

///|
pub fn ImageDescriptor::display_height(self : ImageDescriptor) -> UInt64 {
  self.metadata_value.orientation().display_height(self.width(), self.height())
}

///|
pub fn ImageDescriptor::supports_reference_operations(
  self : ImageDescriptor,
) -> Bool {
  if self.format_value.component() != ComponentType::U8 ||
    self.format_value.layout() != PlaneLayout::Packed ||
    self.metadata_value.space() != @color.ColorSpaceIdentity::Srgb ||
    self.metadata_value.transfer() != @color.TransferIdentity::EncodedSrgb {
    return false
  }
  match self.format_value.channels() {
    ChannelOrder::Rgb => self.metadata_value.alpha() is None
    ChannelOrder::Rgba => self.metadata_value.alpha() is Some(_)
    ChannelOrder::Gray => false
    ChannelOrder::GrayAlpha => false
  }
}
