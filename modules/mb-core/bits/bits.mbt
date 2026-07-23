// Portable bit-level reader and writer for MoonBit Native Foundation.
//
// Consumed by font (CFF Type 2 charstring decoding, OpenType table parsing),
// PNG (DEFLATE bit-stream decode), and PDF (content-stream tokenization).
// Both reader and writer operate on byte arrays with a bit-granular cursor,
// supporting MSB-first (big-endian bit order) which is the convention used
// by DEFLATE (RFC 1951) and most binary formats.
//
// All operations are deterministic across every target. Bounds are checked:
// reading past the end of the source fails with a structured error rather
// than silently wrapping or returning garbage.

///|
/// A big-endian (MSB-first) bit reader over a byte slice.
///
/// The cursor tracks both the current byte index and the bit position within
/// that byte (0 = most-significant bit). Reading N bits consumes from the
/// most-significant available bit downward.
pub struct BitReader {
  source : Array[Byte]
  mut bit_position : Int
}

///|
/// Construct a bit reader over a byte slice.
pub fn BitReader::new(source : Array[Byte]) -> BitReader {
  { source, bit_position: 0 }
}

///|
/// The total number of bits available in the source.
pub fn BitReader::total_bits(self : BitReader) -> Int {
  self.source.length() * 8
}

///|
/// The current bit position (number of bits consumed so far).
pub fn BitReader::position(self : BitReader) -> Int {
  self.bit_position
}

///|
/// The number of bits remaining.
pub fn BitReader::remaining(self : BitReader) -> Int {
  self.total_bits() - self.bit_position
}

///|
/// Read `count` bits (1-32) as an unsigned integer, MSB-first.
///
/// Returns `Err` if `count` is outside [1, 32] or if there are not enough
/// bits remaining. The reader advances by `count` bits.
pub fn BitReader::read_bits(self : BitReader, count : Int) -> Result[Int, @error.CoreError] {
  if count < 1 || count > 32 {
    return Err(@error.CoreError::new(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::InvalidRange,
      operation="bit-reader-read",
      context="bit-reader-read-invalid-count",
    ))
  }
  if self.bit_position + count > self.total_bits() {
    return Err(@error.CoreError::new(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::UnexpectedEndOfStream,
      operation="bit-reader-read",
      context="bit-reader-read-end-of-stream",
    ))
  }
  let mut result = 0
  for _i = 0; _i < count; _i = _i + 1 {
    let byte_index = self.bit_position / 8
    let bit_index = self.bit_position % 8
    // MSB-first: bit 0 of a byte is the most significant (0x80).
    let bit = (self.source[byte_index].to_int() >> (7 - bit_index)) & 1
    result = (result << 1) | bit
    self.bit_position = self.bit_position + 1
  }
  Ok(result)
}

///|
/// Read a single bit (0 or 1).
pub fn BitReader::read_bit(self : BitReader) -> Result[Int, @error.CoreError] {
  self.read_bits(1)
}

///|
/// Skip (align) to the next byte boundary. If already byte-aligned, this is
/// a no-op. Returns the number of bits skipped.
pub fn BitReader::align_to_byte(self : BitReader) -> Int {
  let remainder = self.bit_position % 8
  if remainder != 0 {
    self.bit_position = self.bit_position + (8 - remainder)
    8 - remainder
  } else {
    0
  }
}

///|
/// A big-endian (MSB-first) bit writer into a growable byte array.
///
/// Bits are packed from the most-significant bit of each byte downward. The
/// output is accessible via `bytes()` once writing is complete.
pub struct BitWriter {
  output : Array[Byte]
  mut bit_position : Int
}

///|
/// Construct an empty bit writer.
pub fn BitWriter::new() -> BitWriter {
  { output: [], bit_position: 0 }
}

///|
/// The current bit position (number of bits written so far).
pub fn BitWriter::position(self : BitWriter) -> Int {
  self.bit_position
}

///|
/// Write `value` using `count` bits (1-32), MSB-first.
///
/// Returns `Err` if `count` is outside [1, 32] or if `value` requires more
/// than `count` bits (i.e., `value >= 2^count`).
pub fn BitWriter::write_bits(
  self : BitWriter,
  value : Int,
  count : Int,
) -> Result[Unit, @error.CoreError] {
  if count < 1 || count > 32 {
    return Err(@error.CoreError::new(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::InvalidRange,
      operation="bit-writer-write",
      context="bit-writer-write-invalid-count",
    ))
  }
  // Check that value fits in count bits.
  let max_value = 1 << count
  if value < 0 || value >= max_value {
    // For count=32 the shift would overflow, but 32-bit values that are
    // non-negative always fit since Int is 32-bit.
    if count != 32 && value >= max_value {
      return Err(@error.CoreError::new(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        operation="bit-writer-write",
        context="bit-writer-write-value-overflow",
      ))
    }
  }
  for i = count - 1; i >= 0; i = i - 1 {
    let bit = (value >> i) & 1
    let byte_index = self.bit_position / 8
    let bit_index = self.bit_position % 8
    // Ensure the output array is large enough.
    while self.output.length() <= byte_index {
      self.output.push(b'\x00')
    }
    // MSB-first: bit 0 of a byte is the most significant (0x80).
    if bit == 1 {
      self.output[byte_index] = self.output[byte_index] | (0x80 >> bit_index).to_byte()
    }
    self.bit_position = self.bit_position + 1
  }
  Ok(())
}

///|
/// Write a single bit (0 or 1).
pub fn BitWriter::write_bit(self : BitWriter, value : Int) -> Result[Unit, @error.CoreError] {
  self.write_bits(value, 1)
}

///|
/// Pad the remaining bits in the current partial byte with zeros and return
/// the completed byte array. If already byte-aligned, returns the output as-is.
pub fn BitWriter::flush(self : BitWriter) -> Array[Byte] {
  // No explicit padding needed: unwritten bits in the last byte are already 0
  // because the output array is zero-initialized on push.
  self.output
}
