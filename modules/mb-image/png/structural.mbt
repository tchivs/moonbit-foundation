///|
priv enum PngChunkState {
  BeforeIhdr
  BeforeIdat
  InIdat
  AfterIdat
  Finished
} derive(Eq)

///|
priv enum PngTransparency {
  Opaque
  Grayscale(Byte)
  Grayscale16(Byte, Byte)
  Rgb(Byte, Byte, Byte)
  Rgb16(Byte, Byte, Byte, Byte, Byte, Byte)
  Indexed(Bytes)
}

///| The only colour declaration that Phase 23 can expose without transforming
/// samples is an authenticated sRGB intent. All other recognised declarations
/// remain an explicit capability boundary.
priv enum PngColourDeclaration {
  Default
  Srgb(Byte)
  NonSrgb
}

///|
priv struct PngColourFacts {
  saw_srgb : Bool
  srgb_intent : Byte?
  saw_gamma : Bool
  gamma_is_srgb : Bool
  saw_chrm : Bool
  chrm_is_srgb : Bool
  saw_iccp : Bool
}

///|
fn _png_new_colour_facts() -> PngColourFacts {
  { saw_srgb: false, srgb_intent: None, saw_gamma: false, gamma_is_srgb: false, saw_chrm: false, chrm_is_srgb: false, saw_iccp: false }
}

///|
fn _png_is_recognised_colour(kind : Array[Byte]) -> Bool {
  _png_type_is(kind, b's', b'R', b'G', b'B') ||
  _png_type_is(kind, b'g', b'A', b'M', b'A') ||
  _png_type_is(kind, b'c', b'H', b'R', b'M') ||
  _png_type_is(kind, b'i', b'C', b'C', b'P')
}

///|
fn _png_require_colour_before_palette_or_idat(
  saw_palette : Bool,
) -> Result[Unit, @error.CoreError] {
  if saw_palette { Err(_png_error("png-colour-order")) } else { Ok(()) }
}

///|
fn _png_u32_at(payload : Array[Byte], offset : Int) -> UInt64 {
  (payload[offset].to_int().to_uint64() << 24) |
  (payload[offset + 1].to_int().to_uint64() << 16) |
  (payload[offset + 2].to_int().to_uint64() << 8) |
  payload[offset + 3].to_int().to_uint64()
}

///|
fn _png_validate_srgb_payload(payload : Array[Byte]) -> Result[Byte, @error.CoreError] {
  if payload.length() != 1 { return Err(_png_error("png-srgb-length")) }
  if payload[0].to_int() > 3 { return Err(_png_error("png-srgb-intent")) }
  Ok(payload[0])
}

///|
fn _png_validate_gamma_payload(payload : Array[Byte]) -> Result[Bool, @error.CoreError] {
  if payload.length() != 4 { return Err(_png_error("png-gama-length")) }
  let gamma = _png_u32_at(payload, 0)
  if gamma == 0UL { return Err(_png_error("png-gama-zero")) }
  Ok(gamma == 45455UL)
}

///|
fn _png_validate_chrm_payload(payload : Array[Byte]) -> Result[Bool, @error.CoreError] {
  if payload.length() != 32 { return Err(_png_error("png-chrm-length")) }
  let expected = [31270UL, 32900UL, 64000UL, 33000UL, 30000UL, 60000UL, 15000UL, 6000UL]
  for index = 0; index < 8; index = index + 1 {
    if _png_u32_at(payload, index * 4) != expected[index] { return Ok(false) }
  }
  Ok(true)
}

///|
fn _png_is_iccp_name_byte(byte : Byte) -> Bool {
  let value = byte.to_int()
  (value >= 32 && value <= 126) || (value >= 161 && value <= 255)
}

///| This test-facing helper uses an already bounded payload. The decoder's
/// streaming path below performs the same grammar checks without retaining it.
fn _png_validate_iccp_payload(payload : Bytes) -> Result[Unit, @error.CoreError] {
  let mut index = 0
  let mut last_space = false
  while index < payload.length() && payload[index] != b'\x00' {
    let byte = payload[index]
    if !_png_is_iccp_name_byte(byte) || (index == 0 && byte == b' ') || (byte == b' ' && last_space) || index >= 79 {
      return Err(_png_error("png-iccp-name"))
    }
    last_space = byte == b' '
    index = index + 1
  }
  if index == 0 || index == payload.length() || last_space { return Err(_png_error("png-iccp-name")) }
  if index + 2 >= payload.length() { return Err(_png_error("png-iccp-envelope")) }
  if payload[index + 1] != b'\x00' { return Err(_png_error("png-iccp-method")) }
  Ok(())
}

///|
fn _png_colour_declaration(facts : PngColourFacts) -> Result[PngColourDeclaration, @error.CoreError] {
  if facts.saw_iccp { return Ok(PngColourDeclaration::NonSrgb) }
  if facts.saw_srgb {
    if (facts.saw_gamma && !facts.gamma_is_srgb) || (facts.saw_chrm && !facts.chrm_is_srgb) {
      return Err(_png_error("png-srgb-legacy-conflict"))
    }
    return Ok(PngColourDeclaration::Srgb(facts.srgb_intent.unwrap()))
  }
  if facts.saw_gamma || facts.saw_chrm { Ok(PngColourDeclaration::NonSrgb) } else { Ok(PngColourDeclaration::Default) }
}

///|
fn _png_private_budget(length : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=length,
      allocations=1UL,
      allocation_size=length,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
}

///|
fn _png_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="png-decode",
    context~,
  )
}

///|
fn _png_limit(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="png-decode",
    requested~,
    limit~,
    context~,
  )
}

///|
fn _png_read_one(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Byte, UInt64), @error.CoreError] {
  let next = match @checked.checked_add(consumed, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if next > limits.max_input_bytes() {
    return Err(_png_limit("input-bytes", next, limits.max_input_bytes()))
  }
  match
    scratch.with_mut(0UL, 1UL, fn(lease) { @io.read_exact(reader, lease) }) {
    Ok(_) => Ok((scratch.view().get(0UL).unwrap(), next))
    Err(error) => Err(error)
  }
}

///|
fn _png_read_u32(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(UInt64, UInt64), @error.CoreError] {
  let mut value = 0UL
  let mut cursor = consumed
  for index = 0; index < 4; index = index + 1 {
    let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    value = (value << 8) | byte.to_int().to_uint64()
    cursor = next
  }
  Ok((value, cursor))
}

///|
fn _png_read_type(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Array[Byte], UInt64), @error.CoreError] {
  let bytes : Array[Byte] = []
  let mut cursor = consumed
  for index = 0; index < 4; index = index + 1 {
    let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    bytes.push(byte)
    cursor = next
  }
  Ok((bytes, cursor))
}

///|
fn _png_is_ascii_letter(byte : Byte) -> Bool {
  let value = byte.to_int()
  (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

///|
fn _png_is_uppercase_ascii(byte : Byte) -> Bool {
  let value = byte.to_int()
  value >= 65 && value <= 90
}

///|
fn _png_validate_type_form(
  kind : Array[Byte],
) -> Result[Unit, @error.CoreError] {
  if kind.length() != 4 ||
    !_png_is_ascii_letter(kind[0]) ||
    !_png_is_ascii_letter(kind[1]) ||
    !_png_is_ascii_letter(kind[2]) ||
    !_png_is_ascii_letter(kind[3]) {
    return Err(_png_error("png-chunk-type"))
  }
  if !_png_is_uppercase_ascii(kind[2]) {
    return Err(_png_error("png-reserved-bit"))
  }
  Ok(())
}

///|
fn _png_type_is(
  kind : Array[Byte],
  a : Byte,
  b : Byte,
  c : Byte,
  d : Byte,
) -> Bool {
  kind[0] == a && kind[1] == b && kind[2] == c && kind[3] == d
}

///|
fn _png_is_known_semantic(kind : Array[Byte]) -> Bool {
  _png_type_is(kind, b'P', b'L', b'T', b'E') ||
  _png_type_is(kind, b't', b'R', b'N', b'S') ||
  _png_type_is(kind, b'c', b'H', b'R', b'M') ||
  _png_type_is(kind, b'g', b'A', b'M', b'A') ||
  _png_type_is(kind, b'i', b'C', b'C', b'P') ||
  _png_type_is(kind, b's', b'B', b'I', b'T') ||
  _png_type_is(kind, b's', b'R', b'G', b'B') ||
  _png_type_is(kind, b'c', b'I', b'C', b'P') ||
  _png_type_is(kind, b'm', b'D', b'C', b'v') ||
  _png_type_is(kind, b'c', b'L', b'L', b'i') ||
  _png_type_is(kind, b'a', b'c', b'T', b'L') ||
  _png_type_is(kind, b'f', b'c', b'T', b'L') ||
  _png_type_is(kind, b'f', b'd', b'A', b'T')
}

///|
fn _png_is_critical(kind : Array[Byte]) -> Bool {
  _png_is_uppercase_ascii(kind[0])
}

///|
fn _png_crc_step(crc : UInt64, byte : Byte) -> UInt64 {
  let mut value = crc ^ byte.to_int().to_uint64()
  let mut index = 0
  while index < 8 {
    value = if (value & 1UL) == 1UL {
      (value >> 1) ^ 3988292384UL
    } else {
      value >> 1
    }
    index = index + 1
  }
  value
}

///|
fn _png_crc32(value : Bytes) -> UInt64 {
  let mut crc = 4294967295UL
  let mut index = 0
  while index < value.length() {
    crc = _png_crc_step(crc, value[index])
    index = index + 1
  }
  crc ^ 4294967295UL
}

///|
fn _png_crc_for_type(kind : Array[Byte]) -> UInt64 {
  let mut crc = 4294967295UL
  for byte in kind {
    crc = _png_crc_step(crc, byte)
  }
  crc
}

///|
fn _png_limit_value(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> Result[Unit, @error.CoreError] {
  if requested > limit {
    Err(_png_limit(context, requested, limit))
  } else {
    Ok(())
  }
}

///| Computes the encoded byte width of a grayscale scanline, including only
/// the bytes required by its packed samples.
fn _png_grayscale_row_bytes(
  width : UInt64,
  bit_depth : Int,
) -> Result[UInt64, @error.CoreError] {
  let bits = match @checked.checked_mul(width, bit_depth.to_uint64()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let rounded = match @checked.checked_add(bits, 7UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(rounded / 8UL)
}

///| The filter byte distance is an encoded-source fact, never an exposed RGB8
/// channel count.  Sixteen-bit samples retain their big-endian byte pairs.
fn _png_source_bytes_per_pixel(
  source_channels : UInt64,
  bit_depth : Int,
) -> Result[UInt64, @error.CoreError] {
  if bit_depth == 16 {
    @checked.checked_mul(source_channels, 2UL)
  } else {
    Ok(source_channels)
  }
}

///| Computes an encoded source row before RGB8/RGBA8 expansion.
fn _png_source_row_bytes(
  width : UInt64,
  source_channels : UInt64,
  bit_depth : Int,
) -> Result[UInt64, @error.CoreError] {
  if source_channels == 1UL && bit_depth < 8 {
    _png_grayscale_row_bytes(width, bit_depth)
  } else {
    let bytes_per_pixel = match _png_source_bytes_per_pixel(source_channels, bit_depth) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    @checked.checked_mul(width, bytes_per_pixel)
  }
}

///| Adam7 geometry is kept in one private representation so the structural
/// preflight, inflater, and scatter writers cannot drift from one another.
priv struct PngAdam7Pass {
  x : UInt64
  y : UInt64
  dx : UInt64
  dy : UInt64
  width : UInt64
  height : UInt64
  row_bytes : UInt64
}

///|
fn _png_adam7_dimension(size : UInt64, start : UInt64, stride : UInt64) -> Result[UInt64, @error.CoreError] {
  if size <= start { return Ok(0UL) }
  let remaining = match @checked.checked_add(size - start, stride - 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(remaining / stride)
}

///|
fn _png_adam7_passes(
  width : UInt64,
  height : UInt64,
  source_channels : UInt64,
  bit_depth : Int,
) -> Result[Array[PngAdam7Pass], @error.CoreError] {
  let result : Array[PngAdam7Pass] = []
  for item in [(0UL, 0UL, 8UL, 8UL), (4UL, 0UL, 8UL, 8UL), (0UL, 4UL, 4UL, 8UL), (2UL, 0UL, 4UL, 4UL), (0UL, 2UL, 2UL, 4UL), (1UL, 0UL, 2UL, 2UL), (0UL, 1UL, 1UL, 2UL)] {
    let (x, y, dx, dy) = item
    let pass_width = match _png_adam7_dimension(width, x, dx) { Err(error) => return Err(error); Ok(value) => value }
    let pass_height = match _png_adam7_dimension(height, y, dy) { Err(error) => return Err(error); Ok(value) => value }
    let row_bytes = match _png_source_row_bytes(pass_width, source_channels, bit_depth) { Err(error) => return Err(error); Ok(value) => value }
    result.push({ x, y, dx, dy, width: pass_width, height: pass_height, row_bytes })
  }
  Ok(result)
}

///| Reserves the completed image and exactly two reusable maximum-width source
/// rows, while charging the precise sum of nonempty filtered Adam7 rows.
fn _png_adam7_decode_budget(
  width : UInt64,
  height : UInt64,
  source_channels : UInt64,
  bit_depth : Int,
  channels : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[@budget.Budget, @error.CoreError] {
  let pixels = match @checked.checked_mul(width, height) { Err(error) => return Err(error); Ok(value) => value }
  let image_bytes = match @checked.checked_mul(pixels, channels) { Err(error) => return Err(error); Ok(value) => value }
  let passes = match _png_adam7_passes(width, height, source_channels, bit_depth) { Err(error) => return Err(error); Ok(value) => value }
  let mut maximum_row = 0UL
  let mut filtered = 0UL
  for pass in passes {
    if pass.width > 0UL && pass.height > 0UL {
      if pass.row_bytes > maximum_row { maximum_row = pass.row_bytes }
      let per_row = match @checked.checked_add(pass.row_bytes, 1UL) { Err(error) => return Err(error); Ok(value) => value }
      let bytes = match @checked.checked_mul(per_row, pass.height) { Err(error) => return Err(error); Ok(value) => value }
      filtered = match @checked.checked_add(filtered, bytes) { Err(error) => return Err(error); Ok(value) => value }
    }
  }
  let rows = match @checked.checked_mul(maximum_row, 2UL) { Err(error) => return Err(error); Ok(value) => value }
  let bytes = match @checked.checked_add(image_bytes, rows) { Err(error) => return Err(error); Ok(value) => value }
  let work = match @checked.checked_add(image_bytes, filtered) { Err(error) => return Err(error); Ok(value) => value }
  let allocation_size = if image_bytes > maximum_row { image_bytes } else { maximum_row }
  for item in [("image-bytes", image_bytes, limits.max_output_bytes()), ("output-bytes", filtered, limits.max_output_bytes()), ("work", work, limits.max_work())] {
    let (context, requested, limit) = item
    match _png_limit_value(context, requested, limit) { Err(error) => return Err(error); Ok(_) => () }
  }
  budget.child(@budget.ResourceLimits::new(bytes~, allocations=3UL, allocation_size~, width~, height~, pixels~, depth=0UL, work=limits.max_work()))
}

///| Sixteen-bit decode reserves the expanded image and exactly
/// two encoded source rows.  The source bytes are filtered before high-byte mapping.
fn _png_16bit_decode_budget(
  width : UInt64,
  height : UInt64,
  source_bytes_per_pixel : UInt64,
  channels : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[@budget.Budget, @error.CoreError] {
  let pixels = match @checked.checked_mul(width, height) { Err(error) => return Err(error); Ok(value) => value }
  let image_bytes = match @checked.checked_mul(pixels, channels) { Err(error) => return Err(error); Ok(value) => value }
  let row_bytes = match @checked.checked_mul(width, source_bytes_per_pixel) { Err(error) => return Err(error); Ok(value) => value }
  let rows = match @checked.checked_mul(row_bytes, 2UL) { Err(error) => return Err(error); Ok(value) => value }
  let bytes = match @checked.checked_add(image_bytes, rows) { Err(error) => return Err(error); Ok(value) => value }
  let allocation_size = if image_bytes > row_bytes { image_bytes } else { row_bytes }
  let filtered_row = match @checked.checked_add(row_bytes, 1UL) { Err(error) => return Err(error); Ok(value) => value }
  let filtered = match @checked.checked_mul(filtered_row, height) { Err(error) => return Err(error); Ok(value) => value }
  let work = match @checked.checked_add(image_bytes, filtered) { Err(error) => return Err(error); Ok(value) => value }
  for item in [("image-bytes", image_bytes, limits.max_output_bytes()), ("output-bytes", filtered, limits.max_output_bytes()), ("work", work, limits.max_work())] {
    let (context, requested, limit) = item
    match _png_limit_value(context, requested, limit) { Err(error) => return Err(error); Ok(_) => () }
  }
  budget.child(@budget.ResourceLimits::new(
    bytes~, allocations=3UL, allocation_size~,
    width~, height~, pixels~, depth=0UL, work=limits.max_work(),
  ))
}

///| A grayscale image owns its expanded image and precisely two packed rows.
fn _png_grayscale_decode_budget(
  width : UInt64,
  height : UInt64,
  bit_depth : Int,
  channels : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[@budget.Budget, @error.CoreError] {
  let pixels = match @checked.checked_mul(width, height) { Err(error) => return Err(error); Ok(value) => value }
  let image_bytes = match @checked.checked_mul(pixels, channels) { Err(error) => return Err(error); Ok(value) => value }
  let row_bytes = match _png_grayscale_row_bytes(width, bit_depth) { Err(error) => return Err(error); Ok(value) => value }
  let rows = match @checked.checked_mul(row_bytes, 2UL) { Err(error) => return Err(error); Ok(value) => value }
  let bytes = match @checked.checked_add(image_bytes, rows) { Err(error) => return Err(error); Ok(value) => value }
  let filtered_row = match @checked.checked_add(row_bytes, 1UL) { Err(error) => return Err(error); Ok(value) => value }
  let filtered = match @checked.checked_mul(filtered_row, height) { Err(error) => return Err(error); Ok(value) => value }
  let work = match @checked.checked_add(image_bytes, filtered) { Err(error) => return Err(error); Ok(value) => value }
  for item in [("image-bytes", image_bytes, limits.max_output_bytes()), ("output-bytes", filtered, limits.max_output_bytes()), ("work", work, limits.max_work())] {
    let (context, requested, limit) = item
    match _png_limit_value(context, requested, limit) { Err(error) => return Err(error); Ok(_) => () }
  }
  budget.child(@budget.ResourceLimits::new(
    bytes~, allocations=3UL, allocation_size=image_bytes,
    width~, height~, pixels~, depth=0UL, work=limits.max_work(),
  ))
}

///|
fn _png_preflight_ihdr(
  ihdr : Array[Byte],
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  let width = (ihdr[0].to_int().to_uint64() << 24) |
    (ihdr[1].to_int().to_uint64() << 16) |
    (ihdr[2].to_int().to_uint64() << 8) |
    ihdr[3].to_int().to_uint64()
  let height = (ihdr[4].to_int().to_uint64() << 24) |
    (ihdr[5].to_int().to_uint64() << 16) |
    (ihdr[6].to_int().to_uint64() << 8) |
    ihdr[7].to_int().to_uint64()
  if width == 0UL || height == 0UL {
    return Err(_png_error("png-dimensions"))
  }
  let bit_depth = ihdr[8].to_int()
  let source_channels = if ihdr[9] == 0 {
    if bit_depth != 1 && bit_depth != 2 && bit_depth != 4 && bit_depth != 8 && bit_depth != 16 {
      return Err(_png_error("png-bit-depth"))
    }
    1UL
  } else if ihdr[9] == 2 {
    if bit_depth != 8 && bit_depth != 16 { return Err(_png_error("png-bit-depth")) }
    3UL
  } else if ihdr[9] == 3 {
    if bit_depth != 1 && bit_depth != 2 && bit_depth != 4 && bit_depth != 8 {
      return Err(_png_error("png-bit-depth"))
    }
    1UL
  } else if ihdr[9] == 4 {
    if bit_depth != 8 && bit_depth != 16 { return Err(_png_error("png-bit-depth")) }
    2UL
  } else if ihdr[9] == 6 {
    if bit_depth != 8 && bit_depth != 16 { return Err(_png_error("png-bit-depth")) }
    4UL
  } else {
    return Err(_png_error("png-colour-type"))
  }
  if ihdr[10] != 0 || ihdr[11] != 0 || (ihdr[12] != 0 && ihdr[12] != 1) {
    return Err(_png_error("png-ihdr-method"))
  }
  let pixels = match @checked.checked_mul(width, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  // PNG grayscale-alpha retains two filtered source bytes but is exposed as RGBA8.
  let output_channels = if ihdr[9] == 4 || ihdr[9] == 6 { 4UL } else { 3UL }
  let image_bytes = match @checked.checked_mul(pixels, output_channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if ihdr[12] == 1 {
    match _png_adam7_decode_budget(width, height, source_channels, bit_depth, output_channels, limits, budget) {
      Err(error) => return Err(error)
      Ok(_) => return Ok(())
    }
  }
  let row_bytes = match _png_source_row_bytes(width, source_channels, bit_depth) { Err(error) => return Err(error); Ok(value) => value }
  let filtered_row = match @checked.checked_add(row_bytes, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let filtered_output = match @checked.checked_mul(filtered_row, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = match @checked.checked_add(filtered_output, image_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for
    item in [
      ("width", width, limits.max_width()),
      ("height", height, limits.max_height()),
      ("pixels", pixels, limits.max_pixels()),
      ("image-bytes", image_bytes, limits.max_output_bytes()),
      ("output-bytes", filtered_output, limits.max_output_bytes()),
      ("work", work, limits.max_work()),
    ] {
    let (context, requested, limit) = item
    match _png_limit_value(context, requested, limit) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  match
    budget.child(
      @budget.ResourceLimits::new(
        bytes=image_bytes,
        allocations=1UL,
        allocation_size=image_bytes,
        width~,
        height~,
        pixels~,
        depth=0UL,
        work~,
      ),
    ) {
    Ok(_) => Ok(())
    Err(error) => Err(error)
  }
}

///|
fn _png_indexed_decode_budget(
  width : UInt64,
  height : UInt64,
  bit_depth : Int,
  channels : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[@budget.Budget, @error.CoreError] {
  let pixels = match @checked.checked_mul(width, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let image_bytes = match @checked.checked_mul(pixels, channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let row_bytes = match _png_grayscale_row_bytes(width, bit_depth) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let index_rows = match @checked.checked_mul(row_bytes, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let bytes = match @checked.checked_add(image_bytes, index_rows) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let filtered_row = match @checked.checked_add(row_bytes, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let filtered = match @checked.checked_mul(filtered_row, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = match @checked.checked_add(image_bytes, filtered) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for item in [("image-bytes", image_bytes, limits.max_output_bytes()), ("output-bytes", filtered, limits.max_output_bytes()), ("work", work, limits.max_work())] {
    let (context, requested, limit) = item
    match _png_limit_value(context, requested, limit) { Err(error) => return Err(error); Ok(_) => () }
  }
  budget.child(@budget.ResourceLimits::new(
    bytes~, allocations=3UL, allocation_size=image_bytes,
    width~, height~, pixels~, depth=0UL, work=limits.max_work(),
  ))
}

///| The transparent profiles retain the encoded row width while reserving RGBA8.
fn _png_transparent_decode_budget(
  width : UInt64,
  height : UInt64,
  source_channels : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[@budget.Budget, @error.CoreError] {
  let pixels = match @checked.checked_mul(width, height) { Err(error) => return Err(error); Ok(value) => value }
  let image_bytes = match @checked.checked_mul(pixels, 4UL) { Err(error) => return Err(error); Ok(value) => value }
  let row_bytes = match @checked.checked_mul(width, source_channels) { Err(error) => return Err(error); Ok(value) => value }
  let filtered = match @checked.checked_mul(row_bytes + 1UL, height) { Err(error) => return Err(error); Ok(value) => value }
  let work = match @checked.checked_add(image_bytes, filtered) { Err(error) => return Err(error); Ok(value) => value }
  for item in [("image-bytes", image_bytes, limits.max_output_bytes()), ("output-bytes", filtered, limits.max_output_bytes()), ("work", work, limits.max_work())] {
    let (context, requested, limit) = item
    match _png_limit_value(context, requested, limit) { Err(error) => return Err(error); Ok(_) => () }
  }
  budget.child(@budget.ResourceLimits::new(
    bytes=image_bytes, allocations=1UL, allocation_size=image_bytes,
    width~, height~, pixels~, depth=0UL, work=limits.max_work(),
  ))
}

///| Native-alpha grayscale retains two source bytes per pixel and two filter rows.
fn _png_grayscale_alpha_decode_budget(
  width : UInt64,
  height : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[@budget.Budget, @error.CoreError] {
  let pixels = match @checked.checked_mul(width, height) { Err(error) => return Err(error); Ok(value) => value }
  let image_bytes = match @checked.checked_mul(pixels, 4UL) { Err(error) => return Err(error); Ok(value) => value }
  let row_bytes = match @checked.checked_mul(width, 2UL) { Err(error) => return Err(error); Ok(value) => value }
  let rows = match @checked.checked_mul(row_bytes, 2UL) { Err(error) => return Err(error); Ok(value) => value }
  let bytes = match @checked.checked_add(image_bytes, rows) { Err(error) => return Err(error); Ok(value) => value }
  let filtered = match @checked.checked_mul(row_bytes + 1UL, height) { Err(error) => return Err(error); Ok(value) => value }
  let work = match @checked.checked_add(image_bytes, filtered) { Err(error) => return Err(error); Ok(value) => value }
  for item in [("image-bytes", image_bytes, limits.max_output_bytes()), ("output-bytes", filtered, limits.max_output_bytes()), ("work", work, limits.max_work())] {
    let (context, requested, limit) = item
    match _png_limit_value(context, requested, limit) { Err(error) => return Err(error); Ok(_) => () }
  }
  budget.child(@budget.ResourceLimits::new(
    bytes~, allocations=3UL, allocation_size=image_bytes,
    width~, height~, pixels~, depth=0UL, work=limits.max_work(),
  ))
}

///|
fn _png_read_payload_and_crc(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  length : UInt64,
  kind : Array[Byte],
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Array[Byte], UInt64), @error.CoreError] {
  let data : Array[Byte] = []
  let capture_payload = _png_type_is(kind, b'I', b'H', b'D', b'R') ||
    _png_type_is(kind, b'P', b'L', b'T', b'E') ||
    _png_type_is(kind, b't', b'R', b'N', b'S')
  let mut crc = _png_crc_for_type(kind)
  let mut cursor = consumed
  let mut index = 0UL
  while index < length {
    let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if capture_payload {
      data.push(byte)
    }
    crc = _png_crc_step(crc, byte)
    cursor = next
    index = index + 1UL
  }
  let (stored, next) = match _png_read_u32(reader, scratch, cursor, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if (crc ^ 4294967295UL) != stored {
    return Err(_png_error("png-crc"))
  }
  Ok((data, next))
}

///|
///| Reads a recognised colour chunk exactly once through the CRC path. iCCP
/// profile bytes are discarded after envelope validation; only grammar facts
/// are retained for Phase 24's explicit capability boundary.
fn _png_read_colour_chunk(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  length : UInt64,
  kind : Array[Byte],
  consumed : UInt64,
  limits : @codec.CodecLimits,
  facts : PngColourFacts,
) -> Result[(PngColourFacts, UInt64), @error.CoreError] {
  let is_srgb = _png_type_is(kind, b's', b'R', b'G', b'B')
  let is_gamma = _png_type_is(kind, b'g', b'A', b'M', b'A')
  let is_chrm = _png_type_is(kind, b'c', b'H', b'R', b'M')
  let payload : Array[Byte] = []
  let mut cursor = consumed
  let mut crc = _png_crc_for_type(kind)
  let mut index = 0UL
  let mut name_length = 0UL
  let mut saw_nul = false
  let mut last_space = false
  let mut saw_method = false
  let mut profile_bytes = 0UL
  while index < length {
    let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    crc = _png_crc_step(crc, byte)
    cursor = next
    if is_srgb || is_gamma || is_chrm {
      payload.push(byte)
    } else if !saw_nul {
      if byte == b'\x00' {
        if name_length == 0UL || last_space { return Err(_png_error("png-iccp-name")) }
        saw_nul = true
      } else {
        if !_png_is_iccp_name_byte(byte) || name_length >= 79UL || (name_length == 0UL && byte == b' ') || (byte == b' ' && last_space) {
          return Err(_png_error("png-iccp-name"))
        }
        name_length = name_length + 1UL
        last_space = byte == b' '
      }
    } else if !saw_method {
      if byte != b'\x00' { return Err(_png_error("png-iccp-method")) }
      saw_method = true
    } else {
      profile_bytes = profile_bytes + 1UL
    }
    index = index + 1UL
  }
  let (stored_crc, next) = match _png_read_u32(reader, scratch, cursor, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if (crc ^ 4294967295UL) != stored_crc { return Err(_png_error("png-crc")) }
  if is_srgb {
    if facts.saw_srgb { return Err(_png_error("png-srgb-duplicate")) }
    let intent = match _png_validate_srgb_payload(payload) { Err(error) => return Err(error); Ok(value) => value }
    return Ok(({ saw_srgb: true, srgb_intent: Some(intent), saw_gamma: facts.saw_gamma, gamma_is_srgb: facts.gamma_is_srgb, saw_chrm: facts.saw_chrm, chrm_is_srgb: facts.chrm_is_srgb, saw_iccp: facts.saw_iccp }, next))
  }
  if is_gamma {
    if facts.saw_gamma { return Err(_png_error("png-gama-duplicate")) }
    let standard = match _png_validate_gamma_payload(payload) { Err(error) => return Err(error); Ok(value) => value }
    return Ok(({ saw_srgb: facts.saw_srgb, srgb_intent: facts.srgb_intent, saw_gamma: true, gamma_is_srgb: standard, saw_chrm: facts.saw_chrm, chrm_is_srgb: facts.chrm_is_srgb, saw_iccp: facts.saw_iccp }, next))
  }
  if is_chrm {
    if facts.saw_chrm { return Err(_png_error("png-chrm-duplicate")) }
    let standard = match _png_validate_chrm_payload(payload) { Err(error) => return Err(error); Ok(value) => value }
    return Ok(({ saw_srgb: facts.saw_srgb, srgb_intent: facts.srgb_intent, saw_gamma: facts.saw_gamma, gamma_is_srgb: facts.gamma_is_srgb, saw_chrm: true, chrm_is_srgb: standard, saw_iccp: facts.saw_iccp }, next))
  }
  if facts.saw_iccp { return Err(_png_error("png-iccp-duplicate")) }
  if !saw_nul || !saw_method { return Err(_png_error("png-iccp-envelope")) }
  if profile_bytes == 0UL { return Err(_png_error("png-iccp-data")) }
  Ok(({ saw_srgb: facts.saw_srgb, srgb_intent: facts.srgb_intent, saw_gamma: facts.saw_gamma, gamma_is_srgb: facts.gamma_is_srgb, saw_chrm: facts.saw_chrm, chrm_is_srgb: facts.chrm_is_srgb, saw_iccp: true }, next))
}

///|
fn _png_require_eof(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[Unit, @error.CoreError] {
  match scratch.with_mut(0UL, 1UL, fn(lease) { @io.read_exact(reader, lease) }) {
    Err(error) =>
      if error.code() == @error.ErrorCode::UnexpectedEndOfStream {
        Ok(())
      } else {
        Err(error)
      }
    Ok(_) => {
      let next = match @checked.checked_add(consumed, 1UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if next > limits.max_input_bytes() {
        Err(_png_limit("input-bytes", next, limits.max_input_bytes()))
      } else {
        Err(_png_error("png-trailing-data"))
      }
    }
  }
}

///|
fn _png_validate_transport(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  let scratch = match @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let signature = [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n']
  let mut consumed = 0UL
  for expected in signature {
    let (actual, next) = match
      _png_read_one(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if actual != expected {
      return Err(_png_error("png-signature"))
    }
    consumed = next
  }
  let mut state = PngChunkState::BeforeIhdr
  while true {
    let (length, after_length) = match
      _png_read_u32(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if length > 2147483647UL {
      return Err(_png_error("png-chunk-length"))
    }
    let (kind, after_type) = match
      _png_read_type(reader, scratch, after_length, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match _png_validate_type_form(kind) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let (payload, next) = match
      _png_read_payload_and_crc(
        reader, scratch, length, kind, after_type, limits,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    consumed = next
    let is_ihdr = _png_type_is(kind, b'I', b'H', b'D', b'R')
    let is_idat = _png_type_is(kind, b'I', b'D', b'A', b'T')
    let is_iend = _png_type_is(kind, b'I', b'E', b'N', b'D')
    if is_ihdr {
      if state != PngChunkState::BeforeIhdr {
        return Err(_png_error("png-ihdr-order"))
      }
      if length != 13UL {
        return Err(_png_error("png-ihdr-length"))
      }
      match _png_preflight_ihdr(payload, limits, budget) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      state = PngChunkState::BeforeIdat
    } else {
      if state == PngChunkState::BeforeIhdr {
        return Err(_png_error("png-ihdr-first"))
      }
      if is_iend {
        if state != PngChunkState::InIdat && state != PngChunkState::AfterIdat {
          return Err(_png_error("png-iend-order"))
        }
        if length != 0UL {
          return Err(_png_error("png-iend-length"))
        }
        state = PngChunkState::Finished
        return _png_require_eof(reader, scratch, consumed, limits)
      } else if is_idat {
        if state == PngChunkState::AfterIdat {
          return Err(_png_error("png-idat-contiguous"))
        }
        if state != PngChunkState::BeforeIdat && state != PngChunkState::InIdat {
          return Err(_png_error("png-idat-order"))
        }
        state = PngChunkState::InIdat
      } else {
        if _png_is_known_semantic(kind) {
          return Err(_png_error("png-semantic-chunk"))
        }
        if _png_is_critical(kind) {
          return Err(_png_error("png-unknown-critical"))
        }
        if options.preserve_opaque_metadata() {
          return Err(
            @codec.capability_unavailable(
              "png-decode", "opaque-metadata-preservation",
            ),
          )
        }
        if state == PngChunkState::InIdat {
          state = PngChunkState::AfterIdat
        }
      }
    }
  } nobreak {
    Ok(())
  }
}

///| 
/// Private decode transport.  It deliberately keeps the framing checks in this
/// package: callers never observe a compressed stream or an image before the
/// physical PNG stream (including IEND and EOF) has been authenticated.
priv struct PngTransport {
  width : UInt64
  height : UInt64
  bit_depth : Int
  source_channels : UInt64
  source_bytes_per_pixel : UInt64
  channels : UInt64
  indexed : Bool
  palette : Bytes
  palette_entries : UInt64
  transparency : PngTransparency
  idat : Bytes
  consumed : UInt64
}

///|
fn _png_read_transport(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngTransport, @error.CoreError] {
  let scratch = match @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let signature = [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n']
  let mut consumed = 0UL
  for expected in signature {
    let (actual, next) = match _png_read_one(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if actual != expected { return Err(_png_error("png-signature")) }
    consumed = next
  }
  let mut state = PngChunkState::BeforeIhdr
  let mut width = 0UL
  let mut height = 0UL
  let mut source_channels = 0UL
  let mut channels = 0UL
  let idat : Array[Byte] = []
  while true {
    let (length, after_length) = match _png_read_u32(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if length > 2147483647UL { return Err(_png_error("png-chunk-length")) }
    let (kind, after_type) = match _png_read_type(reader, scratch, after_length, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match _png_validate_type_form(kind) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let is_ihdr = _png_type_is(kind, b'I', b'H', b'D', b'R')
    let is_idat = _png_type_is(kind, b'I', b'D', b'A', b'T')
    let is_iend = _png_type_is(kind, b'I', b'E', b'N', b'D')
    let payload : Array[Byte] = []
    let mut crc = _png_crc_for_type(kind)
    let mut cursor = after_type
    let mut index = 0UL
    while index < length {
      let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if is_ihdr || is_idat { payload.push(byte) }
      crc = _png_crc_step(crc, byte)
      cursor = next
      index = index + 1UL
    }
    let (stored_crc, next) = match _png_read_u32(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if (crc ^ 4294967295UL) != stored_crc { return Err(_png_error("png-crc")) }
    consumed = next
    if is_ihdr {
      if state != PngChunkState::BeforeIhdr { return Err(_png_error("png-ihdr-order")) }
      if length != 13UL { return Err(_png_error("png-ihdr-length")) }
      match _png_preflight_ihdr(payload, limits, budget) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      width = (payload[0].to_int().to_uint64() << 24) | (payload[1].to_int().to_uint64() << 16) | (payload[2].to_int().to_uint64() << 8) | payload[3].to_int().to_uint64()
      height = (payload[4].to_int().to_uint64() << 24) | (payload[5].to_int().to_uint64() << 16) | (payload[6].to_int().to_uint64() << 8) | payload[7].to_int().to_uint64()
      source_channels = if payload[9] == 0 || payload[9] == 3 { 1UL } else if payload[9] == 2 { 3UL } else if payload[9] == 4 { 2UL } else { 4UL }
      channels = if payload[9] == 4 || payload[9] == 6 { 4UL } else { 3UL }
      state = PngChunkState::BeforeIdat
    } else {
      if state == PngChunkState::BeforeIhdr { return Err(_png_error("png-ihdr-first")) }
      if is_iend {
        if state != PngChunkState::InIdat && state != PngChunkState::AfterIdat { return Err(_png_error("png-iend-order")) }
        if length != 0UL { return Err(_png_error("png-iend-length")) }
        match _png_require_eof(reader, scratch, consumed, limits) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        return Ok({ width, height, bit_depth: 8, source_channels, source_bytes_per_pixel: source_channels, channels, indexed: false, palette: b"", palette_entries: 0UL, transparency: PngTransparency::Opaque, idat: Bytes::from_array(idat), consumed })
      } else if is_idat {
        if state == PngChunkState::AfterIdat { return Err(_png_error("png-idat-contiguous")) }
        if state != PngChunkState::BeforeIdat && state != PngChunkState::InIdat { return Err(_png_error("png-idat-order")) }
        for byte in payload { idat.push(byte) }
        state = PngChunkState::InIdat
      } else {
        if _png_is_known_semantic(kind) { return Err(_png_error("png-semantic-chunk")) }
        if _png_is_critical(kind) { return Err(_png_error("png-unknown-critical")) }
        if options.preserve_opaque_metadata() { return Err(@codec.capability_unavailable("png-decode", "opaque-metadata-preservation")) }
        if state == PngChunkState::InIdat { state = PngChunkState::AfterIdat }
      }
    }
  } nobreak { Err(_png_error("png-finished")) }
}

///|
/// The active decoder uses this forward-only IDAT reader.  It never owns an
/// IDAT payload: bytes are CRC-authenticated as they are handed to DEFLATE.
priv struct PngIdatSource {
  reader : &@io.Reader
  scratch : @bytes.OwnedBytes
  limits : @codec.CodecLimits
  options : @codec.DecodeOptions
  mut consumed : UInt64
  mut remaining : UInt64
  mut crc : UInt64
  mut crc_pending : Bool
}

///|
priv struct PngStreamTransport {
  width : UInt64
  height : UInt64
  bit_depth : Int
  source_channels : UInt64
  source_bytes_per_pixel : UInt64
  channels : UInt64
  indexed : Bool
  palette : Bytes
  palette_entries : UInt64
  transparency : PngTransparency
  interlaced : Bool
  srgb_intent : Byte?
  metadata_budget : @budget.Budget?
  budget : @budget.Budget
  source : PngIdatSource
}

///|
fn _png_output_budget_for(
  ihdr : Array[Byte],
  indexed : Bool,
  channels : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[@budget.Budget, @error.CoreError] {
  let width = _png_u32_at(ihdr, 0)
  let height = _png_u32_at(ihdr, 4)
  let source_channels = if ihdr[9] == 0 || ihdr[9] == 3 { 1UL } else if ihdr[9] == 2 { 3UL } else if ihdr[9] == 4 { 2UL } else { 4UL }
  let source_bytes_per_pixel = match _png_source_bytes_per_pixel(source_channels, ihdr[8].to_int()) { Err(error) => return Err(error); Ok(value) => value }
  if ihdr[12] == 1 {
    _png_adam7_decode_budget(width, height, source_channels, ihdr[8].to_int(), channels, limits, budget)
  } else if ihdr[8] == b'\x10' && (ihdr[9] == 0 || ihdr[9] == 2 || ihdr[9] == 4 || ihdr[9] == 6) {
    _png_16bit_decode_budget(width, height, source_bytes_per_pixel, channels, limits, budget)
  } else if indexed {
    _png_indexed_decode_budget(width, height, ihdr[8].to_int(), channels, limits, budget)
  } else if ihdr[9] == 0 {
    _png_grayscale_decode_budget(width, height, ihdr[8].to_int(), channels, limits, budget)
  } else if ihdr[9] == 4 {
    _png_grayscale_alpha_decode_budget(width, height, limits, budget)
  } else if channels == 4UL && ihdr[9] != 6 {
    _png_transparent_decode_budget(width, height, if ihdr[9] == 0 { 1UL } else { 3UL }, limits, budget)
  } else {
    Ok(budget)
  }
}

///| A valid sRGB chunk owns exactly one metadata byte. The metadata is built
/// before any raster allocation, preserving failure atomicity while the
/// profile-specific raster preflight retains its own allocation envelope.
fn _png_srgb_budget(
  ihdr : Array[Byte],
  indexed : Bool,
  channels : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[(@budget.Budget, @budget.Budget), @error.CoreError] {
  let metadata = match budget.child(@budget.ResourceLimits::new(
    bytes=1UL, allocations=1UL, allocation_size=1UL, width=0UL,
    height=0UL, pixels=0UL, depth=0UL, work=0UL,
  )) { Err(error) => return Err(error); Ok(value) => value }
  let raster = match _png_output_budget_for(ihdr, indexed, channels, limits, budget) { Err(error) => return Err(error); Ok(value) => value }
  Ok((metadata, raster))
}

///|
fn _png_read_stream_transport(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngStreamTransport, @error.CoreError] {
  let scratch = match @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let signature = [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n']
  let mut consumed = 0UL
  for expected in signature {
    let (actual, next) = match _png_read_one(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if actual != expected { return Err(_png_error("png-signature")) }
    consumed = next
  }
  let (ihdr_length, after_length) = match _png_read_u32(reader, scratch, consumed, limits) { Err(error) => return Err(error); Ok(value) => value }
  let (ihdr_kind, after_type) = match _png_read_type(reader, scratch, after_length, limits) { Err(error) => return Err(error); Ok(value) => value }
  if !_png_type_is(ihdr_kind, b'I', b'H', b'D', b'R') { return Err(_png_error("png-ihdr-first")) }
  if ihdr_length != 13UL { return Err(_png_error("png-ihdr-length")) }
  let (ihdr, after_ihdr) = match _png_read_payload_and_crc(reader, scratch, ihdr_length, ihdr_kind, after_type, limits) { Err(error) => return Err(error); Ok(value) => value }
  match _png_preflight_ihdr(ihdr, limits, budget) { Err(error) => return Err(error); Ok(_) => () }
  consumed = after_ihdr
  let indexed = ihdr[9] == 3
  let palette : Array[Byte] = []
  let mut palette_entries = 0UL
  let mut saw_palette = false
  let mut transparency = PngTransparency::Opaque
  let mut saw_transparency = false
  let mut colour_facts = _png_new_colour_facts()
  while true {
    let (length, next_length) = match _png_read_u32(reader, scratch, consumed, limits) { Err(error) => return Err(error); Ok(value) => value }
    if length > 2147483647UL { return Err(_png_error("png-chunk-length")) }
    let (kind, next_type) = match _png_read_type(reader, scratch, next_length, limits) { Err(error) => return Err(error); Ok(value) => value }
    match _png_validate_type_form(kind) { Err(error) => return Err(error); Ok(_) => () }
    if _png_is_recognised_colour(kind) {
      match _png_require_colour_before_palette_or_idat(saw_palette) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      let (next_facts, next) = match _png_read_colour_chunk(reader, scratch, length, kind, next_type, limits, colour_facts) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      colour_facts = next_facts
      consumed = next
      continue
    }
    if _png_type_is(kind, b'I', b'D', b'A', b'T') {
      if indexed && !saw_palette { return Err(_png_error("png-plte-required")) }
      let channels = match transparency { PngTransparency::Opaque => if ihdr[9] == 4 || ihdr[9] == 6 { 4UL } else { 3UL }; _ => 4UL }
      let source_channels = if ihdr[9] == 0 || ihdr[9] == 3 { 1UL } else if ihdr[9] == 2 { 3UL } else if ihdr[9] == 4 { 2UL } else { 4UL }
      let source_bytes_per_pixel = match _png_source_bytes_per_pixel(source_channels, ihdr[8].to_int()) { Err(error) => return Err(error); Ok(value) => value }
      let declaration = match _png_colour_declaration(colour_facts) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if declaration is PngColourDeclaration::NonSrgb {
        return Err(@codec.capability_unavailable("png-decode", "png-colour-transform-unavailable"))
      }
      let output_budget = match _png_output_budget_for(
        ihdr, indexed, channels, limits, budget,
      ) { Err(error) => return Err(error); Ok(value) => value }
      let (result_budget, metadata_budget, srgb_intent) = match declaration {
        PngColourDeclaration::Srgb(intent) => match _png_srgb_budget(ihdr, indexed, channels, limits, budget) {
          Err(error) => return Err(error)
          Ok((metadata, raster)) => (raster, Some(metadata), Some(intent))
        }
        _ => (output_budget, None, None)
      }
      return Ok({
        width: (ihdr[0].to_int().to_uint64() << 24) | (ihdr[1].to_int().to_uint64() << 16) | (ihdr[2].to_int().to_uint64() << 8) | ihdr[3].to_int().to_uint64(),
        height: (ihdr[4].to_int().to_uint64() << 24) | (ihdr[5].to_int().to_uint64() << 16) | (ihdr[6].to_int().to_uint64() << 8) | ihdr[7].to_int().to_uint64(),
        bit_depth: ihdr[8].to_int(),
        source_channels,
        source_bytes_per_pixel,
        channels,
        indexed,
        palette: Bytes::from_array(palette),
        palette_entries,
        transparency,
        interlaced: ihdr[12] == 1,
        srgb_intent,
        metadata_budget,
        budget: result_budget,
        source: { reader, scratch, limits, options, consumed: next_type, remaining: length, crc: _png_crc_for_type(kind), crc_pending: true },
      })
    }
    if _png_type_is(kind, b't', b'R', b'N', b'S') {
      if saw_transparency { return Err(_png_error("png-trns-order")) }
      let (payload, next) = match _png_read_payload_and_crc(reader, scratch, length, kind, next_type, limits) { Err(error) => return Err(error); Ok(value) => value }
      if ihdr[9] == 0 {
        if length != 2UL { return Err(_png_error("png-trns-length")) }
        if ihdr[8] == b'\x10' {
          transparency = PngTransparency::Grayscale16(payload[0], payload[1])
        } else {
          if payload[0] != b'\x00' { return Err(_png_error("png-trns-sample")) }
          let mask = if ihdr[8] == b'\x01' { 1 } else if ihdr[8] == b'\x02' { 3 } else if ihdr[8] == b'\x04' { 15 } else { 255 }
          if payload[1].to_int() > mask { return Err(_png_error("png-trns-sample")) }
          transparency = PngTransparency::Grayscale(payload[1])
        }
      } else if ihdr[9] == 2 {
        if length != 6UL { return Err(_png_error("png-trns-length")) }
        if ihdr[8] == b'\x10' {
          transparency = PngTransparency::Rgb16(payload[0], payload[1], payload[2], payload[3], payload[4], payload[5])
        } else {
          if payload[0] != b'\x00' || payload[2] != b'\x00' || payload[4] != b'\x00' { return Err(_png_error("png-trns-sample")) }
          transparency = PngTransparency::Rgb(payload[1], payload[3], payload[5])
        }
      } else if ihdr[9] == 3 {
        if !saw_palette { return Err(_png_error("png-trns-order")) }
        if length > palette_entries { return Err(_png_error("png-trns-length")) }
        transparency = PngTransparency::Indexed(Bytes::from_array(payload))
      } else { return Err(_png_error("png-semantic-chunk")) }
      saw_transparency = true
      consumed = next
      continue
    }
    if _png_type_is(kind, b'P', b'L', b'T', b'E') {
      if !indexed { return Err(_png_error("png-semantic-chunk")) }
      if saw_palette { return Err(_png_error("png-plte-order")) }
      if length < 3UL || length > 768UL || length % 3UL != 0UL {
        return Err(_png_error("png-plte-length"))
      }
      let maximum_entries = if ihdr[8] == b'\x01' { 2UL } else if ihdr[8] == b'\x02' { 4UL } else if ihdr[8] == b'\x04' { 16UL } else { 256UL }
      if length / 3UL > maximum_entries { return Err(_png_error("png-plte-length")) }
      let (payload, next) = match _png_read_payload_and_crc(reader, scratch, length, kind, next_type, limits) { Err(error) => return Err(error); Ok(value) => value }
      for byte in payload { palette.push(byte) }
      palette_entries = length / 3UL
      saw_palette = true
      consumed = next
      continue
    }
    if _png_type_is(kind, b'I', b'E', b'N', b'D') { return Err(_png_error("png-iend-order")) }
    if _png_is_known_semantic(kind) { return Err(_png_error("png-semantic-chunk")) }
    if _png_is_critical(kind) { return Err(_png_error("png-unknown-critical")) }
    if options.preserve_opaque_metadata() { return Err(@codec.capability_unavailable("png-decode", "opaque-metadata-preservation")) }
    let (_, next) = match _png_read_payload_and_crc(reader, scratch, length, kind, next_type, limits) { Err(error) => return Err(error); Ok(value) => value }
    consumed = next
  } nobreak { Err(_png_error("png-idat-order")) }
}

///|
fn PngIdatSource::next_byte(self : PngIdatSource) -> Result[Byte, @error.CoreError] {
  if self.remaining == 0UL && self.crc_pending {
    let (stored, after_crc) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    if (self.crc ^ 4294967295UL) != stored { return Err(_png_error("png-crc")) }
    self.consumed = after_crc
    self.crc_pending = false
  }
  while self.remaining == 0UL {
    let (length, after_length) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    if length > 2147483647UL { return Err(_png_error("png-chunk-length")) }
    let (kind, after_type) = match _png_read_type(self.reader, self.scratch, after_length, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    match _png_validate_type_form(kind) { Err(error) => return Err(error); Ok(_) => () }
    if !_png_type_is(kind, b'I', b'D', b'A', b'T') {
      if _png_type_is(kind, b'P', b'L', b'T', b'E') { return Err(_png_error("png-plte-order")) }
      if _png_is_recognised_colour(kind) { return Err(_png_error("png-colour-order")) }
      return Err(_png_error("zlib-truncated"))
    }
    self.consumed = after_type
    self.remaining = length
    self.crc = _png_crc_for_type(kind)
    self.crc_pending = true
    if self.remaining == 0UL {
      let (stored, after_crc) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
      if (self.crc ^ 4294967295UL) != stored { return Err(_png_error("png-crc")) }
      self.consumed = after_crc
      self.crc_pending = false
    }
  }
  let (byte, next) = match _png_read_one(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
  self.consumed = next
  self.remaining = self.remaining - 1UL
  self.crc = _png_crc_step(self.crc, byte)
  Ok(byte)
}

///|
fn PngIdatSource::finish(self : PngIdatSource) -> Result[UInt64, @error.CoreError] {
  if self.remaining != 0UL { return Err(_png_error("zlib-trailing")) }
  if self.crc_pending {
    let (stored, after_crc) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    if (self.crc ^ 4294967295UL) != stored { return Err(_png_error("png-crc")) }
    self.consumed = after_crc
    self.crc_pending = false
  }
  while true {
    let (length, after_length) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    if length > 2147483647UL { return Err(_png_error("png-chunk-length")) }
    let (kind, after_type) = match _png_read_type(self.reader, self.scratch, after_length, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    match _png_validate_type_form(kind) { Err(error) => return Err(error); Ok(_) => () }
    if _png_type_is(kind, b'I', b'D', b'A', b'T') { return Err(_png_error("png-idat-contiguous")) }
    if _png_type_is(kind, b'I', b'E', b'N', b'D') {
      if length != 0UL { return Err(_png_error("png-iend-length")) }
      let (_, next) = match _png_read_payload_and_crc(self.reader, self.scratch, length, kind, after_type, self.limits) { Err(error) => return Err(error); Ok(value) => value }
      match _png_require_eof(self.reader, self.scratch, next, self.limits) { Err(error) => return Err(error); Ok(_) => return Ok(next) }
    }
    if _png_type_is(kind, b't', b'R', b'N', b'S') { return Err(_png_error("png-trns-order")) }
    if _png_type_is(kind, b'P', b'L', b'T', b'E') { return Err(_png_error("png-plte-order")) }
    if _png_is_recognised_colour(kind) { return Err(_png_error("png-colour-order")) }
    if _png_is_known_semantic(kind) { return Err(_png_error("png-semantic-chunk")) }
    if _png_is_critical(kind) { return Err(_png_error("png-unknown-critical")) }
    if self.options.preserve_opaque_metadata() { return Err(@codec.capability_unavailable("png-decode", "opaque-metadata-preservation")) }
    let (_, next) = match _png_read_payload_and_crc(self.reader, self.scratch, length, kind, after_type, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    self.consumed = next
  } nobreak { Err(_png_error("png-finished")) }
}
