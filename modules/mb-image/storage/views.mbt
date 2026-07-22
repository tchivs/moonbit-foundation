///|
fn storage_error(
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  operation : String,
  context : String,
) -> @error.CoreError {
  @error.CoreError::new(category, code, operation~, context~)
}

///|
fn require_packed_u8_view(
  format : @model.ImageFormat,
  operation : String,
  context : String,
) -> Result[Unit, @error.CoreError] {
  if format.layout() == @model.PlaneLayout::Packed &&
    format.component() == @model.ComponentType::U8 {
    Ok(())
  } else {
    Err(
      storage_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        operation,
        context,
      ),
    )
  }
}

///|
fn require_packed_u8_or_u16_view(
  format : @model.ImageFormat,
  operation : String,
  context : String,
) -> Result[Unit, @error.CoreError] {
  if format.layout() == @model.PlaneLayout::Packed &&
    (format.component() == @model.ComponentType::U8 ||
      format.component() == @model.ComponentType::U16) {
    Ok(())
  } else {
    Err(
      storage_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        operation,
        context,
      ),
    )
  }
}

///|
fn checked_offset(
  origin : UInt64,
  y : UInt64,
  stride : UInt64,
  x : UInt64,
  pixel_bytes : UInt64,
  channel : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let row = match @checked.checked_mul(y, stride) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let column = match @checked.checked_mul(x, pixel_bytes) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let after_row = match @checked.checked_add(origin, row) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let after_column = match @checked.checked_add(after_row, column) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  @checked.checked_add(after_column, channel)
}

///|
/// A retained immutable logical image window. Empty views are represented by
/// the one backing-free canonical state and never access storage.
pub struct ImageView {
  priv backing : @bytes.ByteView?
  priv width_value : UInt64
  priv height_value : UInt64
  priv format_value : @model.ImageFormat
  priv metadata_value : @model.ImageMetadata
  priv origin : UInt64
  priv row_stride_value : UInt64
  priv row_bytes_value : UInt64
}

///|
fn ImageView::from_owned(
  descriptor : @model.ImageDescriptor,
  backing : @bytes.ByteView,
) -> ImageView {
  let plane = descriptor.plane(0).unwrap()
  {
    backing: Some(backing),
    width_value: descriptor.width(),
    height_value: descriptor.height(),
    format_value: descriptor.format(),
    metadata_value: descriptor.metadata(),
    origin: plane.range().start(),
    row_stride_value: plane.row_stride(),
    row_bytes_value: plane.row_bytes(),
  }
}

///|
fn ImageView::canonical_empty(self : ImageView) -> ImageView {
  {
    backing: None,
    width_value: 0UL,
    height_value: 0UL,
    format_value: self.format_value,
    metadata_value: self.metadata_value,
    origin: 0UL,
    row_stride_value: 0UL,
    row_bytes_value: 0UL,
  }
}

///|
pub fn ImageView::width(self : ImageView) -> UInt64 {
  self.width_value
}

///|
pub fn ImageView::height(self : ImageView) -> UInt64 {
  self.height_value
}

///|
pub fn ImageView::format(self : ImageView) -> @model.ImageFormat {
  self.format_value
}

///|
pub fn ImageView::metadata(self : ImageView) -> @model.ImageMetadata {
  self.metadata_value
}

///|
pub fn ImageView::row_stride(self : ImageView) -> UInt64 {
  self.row_stride_value
}

///|
pub fn ImageView::row_bytes(self : ImageView) -> UInt64 {
  self.row_bytes_value
}

///|
pub fn ImageView::is_empty(self : ImageView) -> Bool {
  self.width_value == 0UL || self.height_value == 0UL
}

///|
pub fn ImageView::storage_length(self : ImageView) -> UInt64 {
  match self.backing {
    Some(value) => value.length()
    None => 0UL
  }
}

///|
/// Return the revision of the retained owned backing. It advances for every
/// successful callback-scoped source mutation and is stable for immutable reads.
pub fn ImageView::mutation_revision(self : ImageView) -> UInt64 {
  match self.backing {
    Some(value) => value.mutation_revision()
    None => 0UL
  }
}

///|
pub fn ImageView::get_byte(
  self : ImageView,
  x : UInt64,
  y : UInt64,
  channel : UInt64,
) -> Result[Byte, @error.CoreError] {
  match
    require_packed_u8_view(
      self.format_value,
      "image-view-get",
      "packed-u8-byte-access-required",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let channel_count = self.format_value.channel_count()
  if self.is_empty() ||
    x >= self.width_value ||
    y >= self.height_value ||
    channel >= channel_count {
    return Err(
      storage_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        "image-view-get",
        "view-range",
      ),
    )
  }
  let offset = match
    checked_offset(
      self.origin,
      y,
      self.row_stride_value,
      x,
      self.format_value.bytes_per_component() * channel_count,
      channel * self.format_value.bytes_per_component(),
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match self.backing {
    Some(value) => value.get(offset)
    None =>
      Err(
        storage_error(
          @error.ErrorCategory::State,
          @error.ErrorCode::InvalidRange,
          "image-view-get",
          "empty-view",
        ),
      )
  }
}

///|
/// Read one storage-order byte from a packed U8 or U16 component. This is
/// deliberately separate from `get_byte`, whose public contract remains U8.
pub fn ImageView::get_component_byte(
  self : ImageView,
  x : UInt64,
  y : UInt64,
  channel : UInt64,
  component_byte : UInt64,
) -> Result[Byte, @error.CoreError] {
  match
    require_packed_u8_or_u16_view(
      self.format_value,
      "image-view-get-component-byte",
      "packed-u8-or-u16-component-byte-access-required",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let channel_count = self.format_value.channel_count()
  let bytes_per_component = self.format_value.bytes_per_component()
  if self.is_empty() ||
    x >= self.width_value ||
    y >= self.height_value ||
    channel >= channel_count ||
    component_byte >= bytes_per_component {
    return Err(
      storage_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        "image-view-get-component-byte",
        "component-byte-range",
      ),
    )
  }
  let offset = match
    checked_offset(
      self.origin,
      y,
      self.row_stride_value,
      x,
      bytes_per_component * channel_count,
      channel * bytes_per_component + component_byte,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match self.backing {
    Some(value) => value.get(offset)
    None =>
      Err(
        storage_error(
          @error.ErrorCategory::State,
          @error.ErrorCode::InvalidRange,
          "image-view-get-component-byte",
          "empty-view",
        ),
      )
  }
}

///|
pub fn ImageView::crop(
  self : ImageView,
  rect : @model.Rect,
) -> Result[ImageView, @error.CoreError] {
  if rect.right() > self.width_value || rect.bottom() > self.height_value {
    return Err(
      storage_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        "image-view-crop",
        "crop-range",
      ),
    )
  }
  if rect.is_empty() {
    return Ok(self.canonical_empty())
  }
  if self.format_value.layout() != @model.PlaneLayout::Packed {
    return Err(
      storage_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        "image-view-crop",
        "planar-crop",
      ),
    )
  }
  let pixel_bytes = self.format_value.bytes_per_component() *
    self.format_value.channel_count()
  let origin = match
    checked_offset(
      self.origin,
      rect.y(),
      self.row_stride_value,
      rect.x(),
      pixel_bytes,
      0UL,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let row_bytes = match @checked.checked_mul(rect.width(), pixel_bytes) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    backing: self.backing,
    width_value: rect.width(),
    height_value: rect.height(),
    format_value: self.format_value,
    metadata_value: self.metadata_value,
    origin,
    row_stride_value: self.row_stride_value,
    row_bytes_value: row_bytes,
  })
}

///|
/// Runtime-validated mutable image authority over one callback-scoped byte
/// lease. Logical descendants carry no independent backing authority.
pub struct MutImageView {
  priv lease : @bytes.MutByteLease
  priv width_value : UInt64
  priv height_value : UInt64
  priv format_value : @model.ImageFormat
  priv metadata_value : @model.ImageMetadata
  priv origin : UInt64
  priv row_stride_value : UInt64
  priv row_bytes_value : UInt64
}

///|
fn MutImageView::from_owned(
  descriptor : @model.ImageDescriptor,
  lease : @bytes.MutByteLease,
) -> MutImageView {
  let plane = descriptor.plane(0).unwrap()
  {
    lease,
    width_value: descriptor.width(),
    height_value: descriptor.height(),
    format_value: descriptor.format(),
    metadata_value: descriptor.metadata(),
    origin: plane.range().start(),
    row_stride_value: plane.row_stride(),
    row_bytes_value: plane.row_bytes(),
  }
}

///|
pub fn MutImageView::width(self : MutImageView) -> UInt64 {
  self.width_value
}

///|
pub fn MutImageView::height(self : MutImageView) -> UInt64 {
  self.height_value
}

///|
pub fn MutImageView::format(self : MutImageView) -> @model.ImageFormat {
  self.format_value
}

///|
pub fn MutImageView::metadata(self : MutImageView) -> @model.ImageMetadata {
  self.metadata_value
}

///|
fn MutImageView::validated_offset(
  self : MutImageView,
  x : UInt64,
  y : UInt64,
  channel : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match
    require_packed_u8_view(
      self.format_value,
      "mut-image-view-access",
      "packed-u8-mut-access-required",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let channel_count = self.format_value.channel_count()
  if self.width_value == 0UL ||
    self.height_value == 0UL ||
    x >= self.width_value ||
    y >= self.height_value ||
    channel >= channel_count {
    return Err(
      storage_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        "mut-image-view-access",
        "view-range",
      ),
    )
  }
  checked_offset(
    self.origin,
    y,
    self.row_stride_value,
    x,
    self.format_value.bytes_per_component() * channel_count,
    channel * self.format_value.bytes_per_component(),
  )
}

///|
pub fn MutImageView::get_byte(
  self : MutImageView,
  x : UInt64,
  y : UInt64,
  channel : UInt64,
) -> Result[Byte, @error.CoreError] {
  match self.validated_offset(x, y, channel) {
    Ok(offset) => self.lease.get(offset)
    Err(error) => Err(error)
  }
}

///|
pub fn MutImageView::set_byte(
  self : MutImageView,
  x : UInt64,
  y : UInt64,
  channel : UInt64,
  value : Byte,
) -> Result[Unit, @error.CoreError] {
  match self.validated_offset(x, y, channel) {
    Ok(offset) => self.lease.set(offset, value)
    Err(error) => Err(error)
  }
}

///|
fn MutImageView::validated_component_offset(
  self : MutImageView,
  x : UInt64,
  y : UInt64,
  channel : UInt64,
  component_byte : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match
    require_packed_u8_or_u16_view(
      self.format_value,
      "mut-image-view-component-byte-access",
      "packed-u8-or-u16-component-byte-access-required",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let channel_count = self.format_value.channel_count()
  let bytes_per_component = self.format_value.bytes_per_component()
  if self.width_value == 0UL ||
    self.height_value == 0UL ||
    x >= self.width_value ||
    y >= self.height_value ||
    channel >= channel_count ||
    component_byte >= bytes_per_component {
    return Err(
      storage_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        "mut-image-view-component-byte-access",
        "component-byte-range",
      ),
    )
  }
  checked_offset(
    self.origin,
    y,
    self.row_stride_value,
    x,
    bytes_per_component * channel_count,
    channel * bytes_per_component + component_byte,
  )
}

///|
pub fn MutImageView::get_component_byte(
  self : MutImageView,
  x : UInt64,
  y : UInt64,
  channel : UInt64,
  component_byte : UInt64,
) -> Result[Byte, @error.CoreError] {
  match self.validated_component_offset(x, y, channel, component_byte) {
    Ok(offset) => self.lease.get(offset)
    Err(error) => Err(error)
  }
}

///|
/// Write one storage-order byte to a packed U8 or U16 component inside the
/// callback-scoped mutable authority.
pub fn MutImageView::set_component_byte(
  self : MutImageView,
  x : UInt64,
  y : UInt64,
  channel : UInt64,
  component_byte : UInt64,
  value : Byte,
) -> Result[Unit, @error.CoreError] {
  match self.validated_component_offset(x, y, channel, component_byte) {
    Ok(offset) => self.lease.set(offset, value)
    Err(error) => Err(error)
  }
}

///|
pub fn MutImageView::crop(
  self : MutImageView,
  rect : @model.Rect,
) -> Result[MutImageView, @error.CoreError] {
  match
    require_packed_u8_view(
      self.format_value,
      "mut-image-view-crop",
      "planar-mut-crop",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if rect.is_empty() {
    return Err(
      storage_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidDimensions,
        "mut-image-view-crop",
        "empty-mutable-crop",
      ),
    )
  }
  if rect.right() > self.width_value || rect.bottom() > self.height_value {
    return Err(
      storage_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        "mut-image-view-crop",
        "crop-range",
      ),
    )
  }
  let pixel_bytes = self.format_value.bytes_per_component() *
    self.format_value.channel_count()
  let origin = match
    checked_offset(
      self.origin,
      rect.y(),
      self.row_stride_value,
      rect.x(),
      pixel_bytes,
      0UL,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let row_bytes = match @checked.checked_mul(rect.width(), pixel_bytes) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    lease: self.lease,
    width_value: rect.width(),
    height_value: rect.height(),
    format_value: self.format_value,
    metadata_value: self.metadata_value,
    origin,
    row_stride_value: self.row_stride_value,
    row_bytes_value: row_bytes,
  })
}

///|
fn mutable_rows_disjoint(
  left : MutImageView,
  right : MutImageView,
) -> Result[Bool, @error.CoreError] {
  for left_y = 0UL; left_y < left.height_value; left_y = left_y + 1UL {
    let left_start = match
      checked_offset(left.origin, left_y, left.row_stride_value, 0UL, 0UL, 0UL) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let left_end = match
      @checked.checked_add(left_start, left.row_bytes_value) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    for right_y = 0UL; right_y < right.height_value; right_y = right_y + 1UL {
      let right_start = match
        checked_offset(
          right.origin,
          right_y,
          right.row_stride_value,
          0UL,
          0UL,
          0UL,
        ) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let right_end = match
        @checked.checked_add(right_start, right.row_bytes_value) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if left_start < right_end && right_start < left_end {
        return Ok(false)
      }
    }
  }
  Ok(true)
}

///|
/// Create two logical descendants only after both their half-open rectangles
/// and every addressed row-byte interval have been proven disjoint.
pub fn MutImageView::split_disjoint(
  self : MutImageView,
  left_rect : @model.Rect,
  right_rect : @model.Rect,
) -> Result[(MutImageView, MutImageView), @error.CoreError] {
  let logical_overlap = left_rect.x() < right_rect.right() &&
    right_rect.x() < left_rect.right() &&
    left_rect.y() < right_rect.bottom() &&
    right_rect.y() < left_rect.bottom()
  if logical_overlap {
    return Err(
      storage_error(
        @error.ErrorCategory::State,
        @error.ErrorCode::InvalidRange,
        "mut-image-view-split",
        "overlapping-mutable-crops",
      ),
    )
  }
  let left = match self.crop(left_rect) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let right = match self.crop(right_rect) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match mutable_rows_disjoint(left, right) {
    Err(error) => Err(error)
    Ok(false) =>
      Err(
        storage_error(
          @error.ErrorCategory::State,
          @error.ErrorCode::InvalidRange,
          "mut-image-view-split",
          "overlapping-byte-ranges",
        ),
      )
    Ok(true) => Ok((left, right))
  }
}
