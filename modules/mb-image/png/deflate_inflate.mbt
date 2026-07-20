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
  let code_tree = match _png_huffman_new(code_lengths, false) {
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
  let literal_tree = match _png_huffman_new(literals, true) { Err(error) => return Err(error); Ok(value) => value }
  let distance_tree = match _png_huffman_new(distances, false) { Err(error) => return Err(error); Ok(value) => value }
  Ok((literal_tree, distance_tree))
}

///|
fn _png_inflate_zlib(input : Bytes, maximum : UInt64) -> Result[Array[Byte], @error.CoreError] {
  if input.length() < 6 { return Err(_png_error("zlib-truncated")) }
  let cmf = input[0].to_int()
  let flg = input[1].to_int()
  if (cmf & 15) != 8 || (cmf >> 4) > 7 || ((cmf << 8) + flg) % 31 != 0 { return Err(_png_error("zlib-header")) }
  if (flg & 32) != 0 { return Err(_png_error("zlib-fdict")) }
  let bits = _png_deflate_bits_new(input, 2)
  let output : Array[Byte] = []
  let history = Array::make(32768, b'\x00')
  let mut history_size = 0
  let mut history_pos = 0
  let mut adler = 1UL
  let emit = fn(byte : Byte) -> Result[Unit, @error.CoreError] {
    if output.length().to_uint64() >= maximum { return Err(_png_limit("output-bytes", output.length().to_uint64() + 1UL, maximum)) }
    output.push(byte)
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
  if bits.offset + 4 != input.length() { return Err(_png_error("zlib-trailing")) }
  let expected = (input[bits.offset].to_int().to_uint64() << 24) | (input[bits.offset + 1].to_int().to_uint64() << 16) | (input[bits.offset + 2].to_int().to_uint64() << 8) | input[bits.offset + 3].to_int().to_uint64()
  if expected != adler { return Err(_png_error("zlib-adler")) }
  Ok(output)
}
