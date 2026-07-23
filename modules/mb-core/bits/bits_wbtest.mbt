// White-box tests for bit-level reader and writer.

///|
test "bit reader reads individual bits MSB-first" {
  // Byte 0xB0 = 10110000
  let reader = BitReader::new([(0xb0).to_byte()])
  inspect(reader.read_bit().unwrap(), content="1") // bit 7 = 1
  inspect(reader.read_bit().unwrap(), content="0") // bit 6 = 0
  inspect(reader.read_bit().unwrap(), content="1") // bit 5 = 1
  inspect(reader.read_bit().unwrap(), content="1") // bit 4 = 1
  inspect(reader.read_bit().unwrap(), content="0") // bit 3 = 0
  inspect(reader.read_bit().unwrap(), content="0") // bit 2 = 0
  inspect(reader.read_bit().unwrap(), content="0") // bit 1 = 0
  inspect(reader.read_bit().unwrap(), content="0") // bit 0 = 0
  // Now at end: next read fails.
  match reader.read_bit() {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("bit-reader-read-end-of-stream"), content="true")
  }
}

///|
test "bit reader reads multi-bit values MSB-first" {
  // Byte 0x6E = 01101110
  let reader = BitReader::new([(0x6e).to_byte()])
  // Read 3 bits: 011 = 3
  inspect(reader.read_bits(3).unwrap(), content="3")
  // Read 5 bits: 01110 = 14
  inspect(reader.read_bits(5).unwrap(), content="14")
}

///|
test "bit reader reads across byte boundaries" {
  // Two bytes: 0xFF 0x00 = 11111111 00000000
  let reader = BitReader::new([(0xff).to_byte(), (0x00).to_byte()])
  // Read 12 bits: 111111110000 = 0xFF0 = 4080
  inspect(reader.read_bits(12).unwrap(), content="4080")
}

///|
test "bit reader tracks position and remaining" {
  let reader = BitReader::new([(0x00).to_byte(), (0x00).to_byte()])
  inspect(reader.total_bits(), content="16")
  inspect(reader.remaining(), content="16")
  inspect(reader.position(), content="0")
  ignore(reader.read_bits(4))
  inspect(reader.position(), content="4")
  inspect(reader.remaining(), content="12")
}

///|
test "bit reader aligns to byte boundary" {
  let reader = BitReader::new([(0x00).to_byte(), (0x00).to_byte(), (0x00).to_byte()])
  ignore(reader.read_bits(3))
  inspect(reader.position(), content="3")
  let skipped = reader.align_to_byte()
  inspect(skipped, content="5")
  inspect(reader.position(), content="8")
  // Already aligned: no-op.
  let skipped2 = reader.align_to_byte()
  inspect(skipped2, content="0")
}

///|
test "bit reader rejects invalid count" {
  let reader = BitReader::new([(0x00).to_byte()])
  match reader.read_bits(0) {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("bit-reader-read-invalid-count"), content="true")
  }
  match reader.read_bits(33) {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("bit-reader-read-invalid-count"), content="true")
  }
}

///|
test "bit writer writes individual bits MSB-first" {
  let writer = BitWriter::new()
  ignore(writer.write_bit(1))
  ignore(writer.write_bit(0))
  ignore(writer.write_bit(1))
  ignore(writer.write_bit(1))
  ignore(writer.write_bit(0))
  ignore(writer.write_bit(0))
  ignore(writer.write_bit(0))
  ignore(writer.write_bit(0))
  let bytes = writer.flush()
  inspect(bytes.length(), content="1")
  inspect(bytes[0] == (0xb0).to_byte(), content="true")
}

///|
test "bit writer writes multi-bit values MSB-first" {
  let writer = BitWriter::new()
  // Write 3 bits: 011 = 3
  ignore(writer.write_bits(3, 3))
  // Write 5 bits: 01110 = 14
  ignore(writer.write_bits(14, 5))
  let bytes = writer.flush()
  inspect(bytes.length(), content="1")
  inspect(bytes[0] == (0x6e).to_byte(), content="true")
}

///|
test "bit writer writes across byte boundaries" {
  let writer = BitWriter::new()
  // Write 12 bits: 0xFF0 = 4080
  ignore(writer.write_bits(4080, 12))
  let bytes = writer.flush()
  inspect(bytes.length(), content="2")
  inspect(bytes[0] == (0xff).to_byte(), content="true")
  inspect(bytes[1] == (0x00).to_byte(), content="true")
}

///|
test "bit writer rejects value overflow" {
  let writer = BitWriter::new()
  // 3 bits can hold 0-7; 8 is too large.
  match writer.write_bits(8, 3) {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("bit-writer-write-value-overflow"), content="true")
  }
}

///|
test "bit writer rejects invalid count" {
  let writer = BitWriter::new()
  match writer.write_bits(0, 0) {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("bit-writer-write-invalid-count"), content="true")
  }
  match writer.write_bits(0, 33) {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("bit-writer-write-invalid-count"), content="true")
  }
}

///|
test "bit reader and writer are inverses for round-trip" {
  let original = [1, 0, 255, 7, 42, 3]
  // Write original values with varying bit widths.
  let writer = BitWriter::new()
  ignore(writer.write_bits(original[0], 3)) // 1 in 3 bits
  ignore(writer.write_bits(original[1], 1)) // 0 in 1 bit
  ignore(writer.write_bits(original[2], 8)) // 255 in 8 bits
  ignore(writer.write_bits(original[3], 4)) // 7 in 4 bits
  ignore(writer.write_bits(original[4], 6)) // 42 in 6 bits
  ignore(writer.write_bits(original[5], 3)) // 3 in 3 bits
  // Total: 3+1+8+4+6+3 = 25 bits = 4 bytes (padded)
  let encoded = writer.flush()
  // Read back.
  let reader = BitReader::new(encoded)
  inspect(reader.read_bits(3).unwrap(), content="1")
  inspect(reader.read_bits(1).unwrap(), content="0")
  inspect(reader.read_bits(8).unwrap(), content="255")
  inspect(reader.read_bits(4).unwrap(), content="7")
  inspect(reader.read_bits(6).unwrap(), content="42")
  inspect(reader.read_bits(3).unwrap(), content="3")
}
