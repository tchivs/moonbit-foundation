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
  let row_bytes = if transport.source_channels == 1UL {
    match _png_grayscale_row_bytes(transport.width, transport.bit_depth) { Err(error) => return Err(error); Ok(value) => value }
  } else { match @checked.checked_mul(transport.width, transport.source_channels) { Err(error) => return Err(error); Ok(value) => value } }
  let expected = match @checked.checked_mul(row_bytes + 1UL, transport.height) { Err(error) => return Err(error); Ok(value) => value }
  let mut emitted = 0UL
  let mut row = 0UL
  let mut column = 0UL
  let mut filter = 0
  let emit = fn(byte : Byte) -> Result[Unit, @error.CoreError] {
    if emitted >= maximum { return Err(_png_limit("output-bytes", emitted + 1UL, maximum)) }
    if emitted >= expected { return Err(_png_error("png-filtered-size")) }
    if column == 0UL {
      filter = byte.to_int()
      if filter > 4 { return Err(_png_error("png-filter")) }
      column = 1UL
    } else {
      let pixel_column = column - 1UL
      if transport.indexed {
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
      if column == row_bytes + 1UL { column = 0UL; row = row + 1UL }
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
  if emitted != expected || column != 0UL || row != transport.height { return Err(_png_error("png-filtered-size")) }
  bits.source.finish()
}
