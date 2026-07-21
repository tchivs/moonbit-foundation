///|
fn _png_adler_step(adler : UInt64, byte : Byte) -> UInt64 {
  let a = adler & 65535UL
  let b = adler >> 16
  let next_a = (a + byte.to_int().to_uint64()) % 65521UL
  (((b + next_a) % 65521UL) << 16) | next_a
}

///|
fn _png_bits_value(bits : PngDeflateBits, count : Int) -> Result[Int, @error.CoreError] {
  bits.read(count)
}

///|
fn _png_length(symbol : Int, bits : PngDeflateBits) -> Result[Int, @error.CoreError] {
  let bases = [3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258]
  let extra = [0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0]
  let index = symbol - 257
  if index < 0 || index >= bases.length() { return Err(_png_error("deflate-reserved-length")) }
  let value = match _png_bits_value(bits, extra[index]) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(bases[index] + value)
}

///|
fn _png_distance(symbol : Int, bits : PngDeflateBits) -> Result[Int, @error.CoreError] {
  let bases = [1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577]
  let extra = [0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13]
  if symbol < 0 || symbol >= bases.length() { return Err(_png_error("deflate-reserved-distance")) }
  let value = match _png_bits_value(bits, extra[symbol]) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(bases[symbol] + value)
}

///|
fn _png_dynamic_trees(bits : PngDeflateBits) -> Result[(PngHuffman, PngHuffman), @error.CoreError] {
  let hlit = match bits.read(5) { Err(error) => return Err(error); Ok(value) => value + 257 }
  let hdist = match bits.read(5) { Err(error) => return Err(error); Ok(value) => value + 1 }
  let hclen = match bits.read(4) { Err(error) => return Err(error); Ok(value) => value + 4 }
  let order = [16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15]
  let code_lengths = Array::make(19, 0)
  for index = 0; index < hclen; index = index + 1 {
    code_lengths[order[index]] = match bits.read(3) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  let code_tree = match _png_huffman_new(code_lengths, false, false) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let all = Array::make(hlit + hdist, 0)
  let mut cursor = 0
  while cursor < all.length() {
    let symbol = match code_tree.symbol(bits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if symbol <= 15 {
      all[cursor] = symbol
      cursor = cursor + 1
    } else {
      let mut count = 0
      let mut value = 0
      if symbol == 16 {
        if cursor == 0 { return Err(_png_error("deflate-repeat-first")) }
        count = match bits.read(2) { Err(error) => return Err(error); Ok(value) => value + 3 }
        value = all[cursor - 1]
      } else if symbol == 17 {
        count = match bits.read(3) { Err(error) => return Err(error); Ok(value) => value + 3 }
      } else if symbol == 18 {
        count = match bits.read(7) { Err(error) => return Err(error); Ok(value) => value + 11 }
      } else { return Err(_png_error("deflate-code-length-symbol")) }
      if cursor + count > all.length() { return Err(_png_error("deflate-repeat-overrun")) }
      for repeat = 0; repeat < count; repeat = repeat + 1 {
        all[cursor] = value
        cursor = cursor + 1
      }
    }
  }
  let literals : Array[Int] = []
  let distances : Array[Int] = []
  for index = 0; index < hlit; index = index + 1 { literals.push(all[index]) }
  for index = 0; index < hdist; index = index + 1 { distances.push(all[hlit + index]) }
  let literal_tree = match _png_huffman_new(literals, true, false) { Err(error) => return Err(error); Ok(value) => value }
  let distance_tree = match _png_huffman_new(distances, false, true) { Err(error) => return Err(error); Ok(value) => value }
  Ok((literal_tree, distance_tree))
}

///|
fn _png_inflate_zlib_to_raster(
  source : PngIdatSource,
  maximum : UInt64,
  view : @storage.MutImageView,
  transport : PngStreamTransport,
  index_rows : Option[PngPackedRows],
  packed_rows : Option[PngPackedRows],
) -> Result[UInt64, @error.CoreError] {
  let cmf = match source.next_byte() { Err(error) => return Err(error); Ok(value) => value.to_int() }
  let flg = match source.next_byte() { Err(error) => return Err(error); Ok(value) => value.to_int() }
  if (cmf & 15) != 8 || (cmf >> 4) > 7 || ((cmf << 8) + flg) % 31 != 0 { return Err(_png_error("zlib-header")) }
  if (flg & 32) != 0 { return Err(_png_error("zlib-fdict")) }
  let bits = _png_deflate_bits_new(source)
  let history = Array::make(32768, b'\x00')
  let mut history_size = 0
  let mut history_pos = 0
  let mut adler = 1UL
  let row_bytes = match _png_source_row_bytes(transport.width, transport.source_channels, transport.bit_depth) { Err(error) => return Err(error); Ok(value) => value }
  let passes = if transport.interlaced {
    match _png_adam7_passes(transport.width, transport.height, transport.source_channels, transport.bit_depth) { Err(error) => return Err(error); Ok(value) => value }
  } else { [] }
  let mut expected = if transport.interlaced { 0UL } else { match @checked.checked_mul(row_bytes + 1UL, transport.height) { Err(error) => return Err(error); Ok(value) => value } }
  if transport.interlaced {
    for pass in passes {
      if pass.width > 0UL && pass.height > 0UL {
        let size = match @checked.checked_mul(pass.row_bytes + 1UL, pass.height) { Err(error) => return Err(error); Ok(value) => value }
        expected = match @checked.checked_add(expected, size) { Err(error) => return Err(error); Ok(value) => value }
      }
    }
  }
  let mut emitted = 0UL
  let mut row = 0UL
  let mut column = 0UL
  let mut filter = 0
  let mut pass_index = 0
  let mut pass_row = 0UL
  if transport.interlaced {
    while pass_index < passes.length() && (passes[pass_index].width == 0UL || passes[pass_index].height == 0UL) { pass_index = pass_index + 1 }
  }
  let emit = fn(byte : Byte) -> Result[Unit, @error.CoreError] {
    if emitted >= maximum { return Err(_png_limit("output-bytes", emitted + 1UL, maximum)) }
    if emitted >= expected { return Err(_png_error("png-filtered-size")) }
    if column == 0UL {
      filter = byte.to_int()
      if filter > 4 { return Err(_png_error("png-filter")) }
      column = 1UL
    } else {
      let pixel_column = column - 1UL
      if transport.interlaced {
        if pass_index >= passes.length() { return Err(_png_error("png-filtered-size")) }
        let pass = passes[pass_index]
        let rows = match packed_rows { Some(value) => value; None => return Err(_png_error("png-packed-rows")) }
        match rows.reconstruct(pixel_column, pass_row, transport.source_bytes_per_pixel, filter, byte.to_int()) { Err(error) => return Err(error); Ok(_) => () }
        if pixel_column + 1UL == pass.row_bytes {
          match _png_write_adam7_row(view, rows, pass, pass_row, transport) { Err(error) => return Err(error); Ok(_) => () }
          rows.finish_row()
        }
      } else if transport.indexed {
        let rows = match index_rows {
          Some(value) => value
          None => return Err(_png_error("png-index-rows"))
        }
        match rows.reconstruct(pixel_column, row, 1UL, filter, byte.to_int()) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if pixel_column + 1UL == row_bytes {
          match _png_write_packed_indexed_row(view, rows, row, transport.width, transport.bit_depth, transport.palette, transport.palette_entries, transport.transparency) { Err(error) => return Err(error); Ok(_) => () }
          rows.finish_row()
        }
      } else if transport.bit_depth == 16 {
        let rows = match packed_rows { Some(value) => value; None => return Err(_png_error("png-packed-rows")) }
        match rows.reconstruct(pixel_column, row, transport.source_bytes_per_pixel, filter, byte.to_int()) { Err(error) => return Err(error); Ok(_) => () }
        if pixel_column + 1UL == row_bytes {
          if transport.source_channels == 1UL {
            match _png_write_16bit_grayscale_row(view, rows, row, transport.width, transport.transparency) { Err(error) => return Err(error); Ok(_) => () }
          } else if transport.source_channels == 2UL {
            match _png_write_16bit_grayscale_alpha_row(view, rows, row, transport.width) { Err(error) => return Err(error); Ok(_) => () }
          } else if transport.source_channels == 3UL {
            match _png_write_16bit_rgb_row(view, rows, row, transport.width, transport.transparency) { Err(error) => return Err(error); Ok(_) => () }
          } else {
            match _png_write_16bit_rgba_row(view, rows, row, transport.width) { Err(error) => return Err(error); Ok(_) => () }
          }
          rows.finish_row()
        }
      } else if transport.source_channels == 1UL || transport.source_channels == 2UL {
        let rows = match packed_rows { Some(value) => value; None => return Err(_png_error("png-packed-rows")) }
        match rows.reconstruct(pixel_column, row, transport.source_channels, filter, byte.to_int()) { Err(error) => return Err(error); Ok(_) => () }
        if pixel_column + 1UL == row_bytes {
          if transport.source_channels == 2UL {
            match _png_write_grayscale_alpha_row(view, rows, row, transport.width) { Err(error) => return Err(error); Ok(_) => () }
          } else {
            match _png_write_packed_grayscale_row(view, rows, row, transport.width, transport.bit_depth, transport.transparency) { Err(error) => return Err(error); Ok(_) => () }
          }
          rows.finish_row()
        }
      } else {
        let x = pixel_column / transport.source_channels
        let channel = pixel_column % transport.source_channels
        let left = if pixel_column >= transport.source_channels { match view.get_byte(x - 1UL, row, channel) { Err(error) => return Err(error); Ok(value) => value.to_int() } } else { 0 }
        let above = if row > 0UL { match view.get_byte(x, row - 1UL, channel) { Err(error) => return Err(error); Ok(value) => value.to_int() } } else { 0 }
        let upper_left = if row > 0UL && pixel_column >= transport.source_channels { match view.get_byte(x - 1UL, row - 1UL, channel) { Err(error) => return Err(error); Ok(value) => value.to_int() } } else { 0 }
        let raw = byte.to_int()
        let value = if filter == 0 { raw } else if filter == 1 { raw + left } else if filter == 2 { raw + above } else if filter == 3 { raw + ((left + above) / 2) } else { raw + _png_paeth(left, above, upper_left) }
        if transport.source_channels != 1UL {
          match view.set_byte(x, row, channel, value.to_byte()) { Err(error) => return Err(error); Ok(_) => () }
          if channel == 2UL {
            match transport.transparency {
              PngTransparency::Rgb(red, green, blue) => {
                let alpha = if view.get_byte(x, row, 0UL).unwrap() == red && view.get_byte(x, row, 1UL).unwrap() == green && value.to_byte() == blue { b'\x00' } else { b'\xff' }
                match view.set_byte(x, row, 3UL, alpha) { Err(error) => return Err(error); Ok(_) => () }
              }
              _ => ()
            }
          }
        }
      }
      column = column + 1UL
      if transport.interlaced {
        if pass_index >= passes.length() { return Err(_png_error("png-filtered-size")) }
        if column == passes[pass_index].row_bytes + 1UL {
          column = 0UL
          pass_row = pass_row + 1UL
          if pass_row == passes[pass_index].height {
            pass_index = pass_index + 1
            pass_row = 0UL
            while pass_index < passes.length() && (passes[pass_index].width == 0UL || passes[pass_index].height == 0UL) { pass_index = pass_index + 1 }
            if pass_index < passes.length() {
              let rows = match packed_rows { Some(value) => value; None => return Err(_png_error("png-packed-rows")) }
              match rows.reset() { Err(error) => return Err(error); Ok(_) => () }
            }
          }
        }
      } else if column == row_bytes + 1UL { column = 0UL; row = row + 1UL }
    }
    emitted = emitted + 1UL
    history[history_pos] = byte
    history_pos = (history_pos + 1) % 32768
    if history_size < 32768 { history_size = history_size + 1 }
    adler = _png_adler_step(adler, byte)
    Ok(())
  }
  let mut final_block = 0
  while final_block == 0 {
    final_block = match bits.read(1) { Err(error) => return Err(error); Ok(value) => value }
    let block_type = match bits.read(2) { Err(error) => return Err(error); Ok(value) => value }
    if block_type == 0 {
      bits.align()
      let low = match bits.read_aligned_byte() { Err(error) => return Err(error); Ok(value) => value.to_int() }
      let high = match bits.read_aligned_byte() { Err(error) => return Err(error); Ok(value) => value.to_int() }
      let nlow = match bits.read_aligned_byte() { Err(error) => return Err(error); Ok(value) => value.to_int() }
      let nhigh = match bits.read_aligned_byte() { Err(error) => return Err(error); Ok(value) => value.to_int() }
      let length = low | (high << 8)
      if (length ^ (nlow | (nhigh << 8))) != 65535 { return Err(_png_error("deflate-stored-length")) }
      for index = 0; index < length; index = index + 1 {
        let byte = match bits.read_aligned_byte() { Err(error) => return Err(error); Ok(value) => value }
        match emit(byte) { Err(error) => return Err(error); Ok(_) => () }
      }
    } else {
      let (literal_tree, distance_tree) = if block_type == 1 { (_png_fixed_literal_tree(), _png_fixed_distance_tree()) } else if block_type == 2 { match _png_dynamic_trees(bits) { Err(error) => return Err(error); Ok(value) => value } } else { return Err(_png_error("deflate-reserved-block")) }
      let mut finished = false
      while !finished {
        let symbol = match literal_tree.symbol(bits) { Err(error) => return Err(error); Ok(value) => value }
        if symbol < 256 { match emit(symbol.to_byte()) { Err(error) => return Err(error); Ok(_) => () } }
        else if symbol == 256 { finished = true }
        else {
          let length = match _png_length(symbol, bits) { Err(error) => return Err(error); Ok(value) => value }
          let distance_symbol = match distance_tree.symbol(bits) { Err(error) => return Err(error); Ok(value) => value }
          let distance = match _png_distance(distance_symbol, bits) { Err(error) => return Err(error); Ok(value) => value }
          if distance > history_size { return Err(_png_error("deflate-distance")) }
          for index = 0; index < length; index = index + 1 {
            let position = (history_pos - distance + 32768) % 32768
            match emit(history[position]) { Err(error) => return Err(error); Ok(_) => () }
          }
        }
      }
    }
  }
  bits.align()
  let a = match bits.source.next_byte() { Err(error) => return Err(error); Ok(value) => value.to_int().to_uint64() }
  let b = match bits.source.next_byte() { Err(error) => return Err(error); Ok(value) => value.to_int().to_uint64() }
  let c = match bits.source.next_byte() { Err(error) => return Err(error); Ok(value) => value.to_int().to_uint64() }
  let d = match bits.source.next_byte() { Err(error) => return Err(error); Ok(value) => value.to_int().to_uint64() }
  let expected_adler = (a << 24) | (b << 16) | (c << 8) | d
  if expected_adler != adler { return Err(_png_error("zlib-adler")) }
  let complete_rows = if transport.interlaced {
    pass_index == passes.length() && pass_row == 0UL
  } else {
    row == transport.height
  }
  if emitted != expected || column != 0UL || !complete_rows { return Err(_png_error("png-filtered-size")) }
  bits.source.finish()
}

///| Private continuation phases for a zlib/DEFLATE stream.  The synchronous
/// helper above remains the compatibility reference while the byte-fed PNG
/// machine is migrated; this state never stores compressed input wholesale.
priv enum PngInflatePhase {
  ZlibCmf
  ZlibFlg(Int)
  BlockFinal
  BlockType(Int)
  StoredLengthLow(Int)
  StoredLengthHigh(Int, Int)
  StoredNLengthLow(Int, Int)
  StoredNLengthHigh(Int, Int, Int)
  StoredBody(Int, Int)
  Symbols(PngHuffman, PngHuffman, Int)
  LengthExtra(PngHuffman, PngHuffman, Int, Int, Int)
  DistanceSymbol(PngHuffman, PngHuffman, Int, Int)
  DistanceExtra(Int, Int, Int, Int)
  Copy(Int, Int, Int)
  Trailer(Array[Byte])
  Complete
}

///| A bounded, byte-fed zlib continuation.  It owns all token state needed to
/// resume after a pause, including the 32 KiB history and Adler accumulator.
/// Output delivery is intentionally separate from input ownership; the PNG
/// machine will connect this to its private raster sink as its framing path is
/// completed.
priv struct PngInflateState {
  bits : PngInflateBits
  cursor : PngHuffmanCursor
  history : Array[Byte]
  maximum : UInt64
  mut history_size : Int
  mut history_pos : Int
  mut adler : UInt64
  mut emitted : UInt64
  mut phase : PngInflatePhase
}

///|
fn PngInflateState::new(maximum : UInt64) -> PngInflateState {
  {
    bits: PngInflateBits::new(),
    cursor: PngHuffmanCursor::new(),
    history: Array::make(32768, b'\x00'),
    maximum,
    history_size: 0,
    history_pos: 0,
    adler: 1UL,
    emitted: 0UL,
    phase: PngInflatePhase::ZlibCmf,
  }
}

///|
fn PngInflateState::emitted_bytes(self : PngInflateState) -> UInt64 { self.emitted }

///|
fn PngInflateState::complete(self : PngInflateState) -> Bool {
  match self.phase { PngInflatePhase::Complete => true; _ => false }
}

///|
fn _png_inflate_length_base(symbol : Int) -> Result[(Int, Int), @error.CoreError] {
  let bases = [3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258]
  let extra = [0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0]
  let index = symbol - 257
  if index < 0 || index >= bases.length() { return Err(_png_error("deflate-reserved-length")) }
  Ok((bases[index], extra[index]))
}

///|
fn _png_inflate_distance_base(symbol : Int) -> Result[(Int, Int), @error.CoreError] {
  let bases = [1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577]
  let extra = [0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13]
  if symbol < 0 || symbol >= bases.length() { return Err(_png_error("deflate-reserved-distance")) }
  Ok((bases[symbol], extra[symbol]))
}

///|
fn PngInflateState::emit(self : PngInflateState, byte : Byte) -> Result[Unit, @error.CoreError] {
  if self.emitted >= self.maximum {
    return Err(_png_limit("output-bytes", self.emitted + 1UL, self.maximum))
  }
  self.history[self.history_pos] = byte
  self.history_pos = (self.history_pos + 1) % 32768
  if self.history_size < 32768 { self.history_size = self.history_size + 1 }
  self.adler = _png_adler_step(self.adler, byte)
  self.emitted = self.emitted + 1UL
  Ok(())
}

///| Supplies one already-authenticated IDAT payload byte.  `drive` consumes as
/// many retained bit/token transitions as possible and stops only at the next
/// byte boundary, so no caller buffer is ever retained or replayed.
fn PngInflateState::accept(self : PngInflateState, byte : Byte) -> Result[Unit, @error.CoreError] {
  if self.complete() { return Err(_png_error("zlib-trailing")) }
  match self.bits.supply(byte) { Err(error) => return Err(error); Ok(_) => () }
  self.drive()
}

///|
fn PngInflateState::drive(self : PngInflateState) -> Result[Unit, @error.CoreError] {
  let mut running = true
  while running {
    match self.phase {
      PngInflatePhase::ZlibCmf => match self.bits.read(8) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(cmf)) => self.phase = PngInflatePhase::ZlibFlg(cmf)
      }
      PngInflatePhase::ZlibFlg(cmf) => match self.bits.read(8) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(flg)) => {
          if (cmf & 15) != 8 || (cmf >> 4) > 7 || ((cmf << 8) + flg) % 31 != 0 { return Err(_png_error("zlib-header")) }
          if (flg & 32) != 0 { return Err(_png_error("zlib-fdict")) }
          self.phase = PngInflatePhase::BlockFinal
        }
      }
      PngInflatePhase::BlockFinal => match self.bits.read(1) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(final_block)) => self.phase = PngInflatePhase::BlockType(final_block)
      }
      PngInflatePhase::BlockType(final_block) => match self.bits.read(2) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(block_type)) => {
          if block_type == 0 {
            self.bits.align()
            self.phase = PngInflatePhase::StoredLengthLow(final_block)
          } else if block_type == 1 {
            self.phase = PngInflatePhase::Symbols(_png_fixed_literal_tree(), _png_fixed_distance_tree(), final_block)
          } else if block_type == 2 {
            // Dynamic-tree continuation is added alongside the raster wiring;
            // fail closed instead of accidentally restarting a partial tree.
            return Err(_png_error("deflate-dynamic-continuation"))
          } else { return Err(_png_error("deflate-reserved-block")) }
        }
      }
      PngInflatePhase::StoredLengthLow(final_block) => match self.bits.read(8) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(low)) => self.phase = PngInflatePhase::StoredLengthHigh(low, final_block)
      }
      PngInflatePhase::StoredLengthHigh(low, final_block) => match self.bits.read(8) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(high)) => self.phase = PngInflatePhase::StoredNLengthLow(low | (high << 8), final_block)
      }
      PngInflatePhase::StoredNLengthLow(length, final_block) => match self.bits.read(8) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(low)) => self.phase = PngInflatePhase::StoredNLengthHigh(length, low, final_block)
      }
      PngInflatePhase::StoredNLengthHigh(length, low, final_block) => match self.bits.read(8) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(high)) => {
          if (length ^ (low | (high << 8))) != 65535 { return Err(_png_error("deflate-stored-length")) }
          self.phase = if length == 0 { if final_block == 1 { PngInflatePhase::Trailer([]) } else { PngInflatePhase::BlockFinal } } else { PngInflatePhase::StoredBody(length, final_block) }
        }
      }
      PngInflatePhase::StoredBody(remaining, final_block) => match self.bits.read(8) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(value)) => {
          match self.emit(value.to_byte()) { Err(error) => return Err(error); Ok(_) => () }
          self.phase = if remaining == 1 { if final_block == 1 { PngInflatePhase::Trailer([]) } else { PngInflatePhase::BlockFinal } } else { PngInflatePhase::StoredBody(remaining - 1, final_block) }
        }
      }
      PngInflatePhase::Symbols(literals, distances, final_block) => match self.cursor.symbol(literals, self.bits) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(symbol)) => {
          if symbol < 256 {
            match self.emit(symbol.to_byte()) { Err(error) => return Err(error); Ok(_) => () }
          } else if symbol == 256 { self.bits.align(); self.phase = if final_block == 1 { PngInflatePhase::Trailer([]) } else { PngInflatePhase::BlockFinal } }
          else {
            let (base, extra) = match _png_inflate_length_base(symbol) { Err(error) => return Err(error); Ok(value) => value }
            self.phase = PngInflatePhase::LengthExtra(literals, distances, base, extra, final_block)
          }
        }
      }
      PngInflatePhase::LengthExtra(literals, distances, base, extra, final_block) => match self.bits.read(extra) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(value)) => self.phase = PngInflatePhase::DistanceSymbol(literals, distances, base + value, final_block)
      }
      PngInflatePhase::DistanceSymbol(literals, distances, length, final_block) => match self.cursor.symbol(distances, self.bits) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(symbol)) => {
          let (base, extra) = match _png_inflate_distance_base(symbol) { Err(error) => return Err(error); Ok(value) => value }
          self.phase = PngInflatePhase::DistanceExtra(length, base, extra, final_block)
        }
      }
      PngInflatePhase::DistanceExtra(length, base, extra, final_block) => match self.bits.read(extra) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(value)) => {
          let distance = base + value
          if distance > self.history_size { return Err(_png_error("deflate-distance")) }
          self.phase = PngInflatePhase::Copy(length, distance, final_block)
        }
      }
      PngInflatePhase::Copy(remaining, distance, final_block) => {
        let position = (self.history_pos - distance + 32768) % 32768
        match self.emit(self.history[position]) { Err(error) => return Err(error); Ok(_) => () }
        self.phase = if remaining == 1 { PngInflatePhase::Symbols(_png_fixed_literal_tree(), _png_fixed_distance_tree(), final_block) } else { PngInflatePhase::Copy(remaining - 1, distance, final_block) }
      }
      PngInflatePhase::Trailer(bytes) => match self.bits.read(8) {
        Err(error) => return Err(error)
        Ok(PngInflateRead::NeedInput) => return Ok(())
        Ok(PngInflateRead::Value(value)) => {
          bytes.push(value.to_byte())
          if bytes.length() == 4 {
            let expected = (bytes[0].to_int().to_uint64() << 24) | (bytes[1].to_int().to_uint64() << 16) | (bytes[2].to_int().to_uint64() << 8) | bytes[3].to_int().to_uint64()
            if expected != self.adler { return Err(_png_error("zlib-adler")) }
            self.phase = PngInflatePhase::Complete
          }
        }
      }
      PngInflatePhase::Complete => running = false
    }
  }
  Ok(())
}
