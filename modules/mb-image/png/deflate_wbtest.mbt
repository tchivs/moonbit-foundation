///|
test "PNG Huffman builder rejects every incomplete alphabet except RFC distance singleton" {
  let code_lengths = _png_huffman_new([1], false, false).unwrap_err()
  inspect(code_lengths.context() == Some("deflate-incomplete-tree"), content="true")

  let literals = Array::make(257, 0)
  literals[256] = 1
  let literal_tree = _png_huffman_new(literals, true, false).unwrap_err()
  inspect(literal_tree.context() == Some("deflate-incomplete-tree"), content="true")

  let distance = _png_huffman_new([2], false, true).unwrap_err()
  inspect(distance.context() == Some("deflate-incomplete-tree"), content="true")
  inspect(_png_huffman_new([1], false, true) is Ok(_), content="true")
}
///| Phase 36 RED: dynamic code construction is not available in the Phase 35 seam.
test "PNG dynamic Huffman builder is canonical and bounded" {
  let tree = _png_huffman_from_frequencies([5UL, 5UL, 2UL], false, false, true).unwrap()
  inspect(tree.lengths[0] > 0 && tree.lengths[1] > 0 && tree.lengths[2] > 0, content="true")
  inspect(tree.codes[0] != tree.codes[1] && tree.codes[1] != tree.codes[2], content="true")
  for length in tree.lengths { inspect(length <= 15, content="true") }
}

///| Phase 36 RED: dynamic header planning is not available in the Phase 35 seam.
test "PNG dynamic Huffman header uses RFC order and RLE" {
  let (symbols, extras, bits, count) = _png_dynamic_rle([3,3,3,3,0,0,0,0,0,0,0,0,0,0,0])
  inspect(count == 3UL, content="true")
  inspect(symbols[0] == 3 && symbols[1] == 16 && extras[1] == 0UL && bits[1] == 2UL, content="true")
  inspect(symbols[2] == 18 && extras[2] == 0UL && bits[2] == 7UL, content="true")
}

///| Phase 36 RED: singleton dynamic alphabets require encoder support.
test "PNG dynamic Huffman handles singleton distance and code-length trees" {
  let distance = _png_huffman_from_frequencies([1UL], false, true, false).unwrap()
  inspect(distance.lengths == [1], content="true")
  // A complete non-distance alphabet needs the deterministic second leaf.
  let frequencies = [1UL, 1UL]
  let code_lengths = _png_huffman_from_frequencies(frequencies, false, false, true).unwrap()
  inspect(code_lengths.lengths[0] == 1 && code_lengths.lengths[1] == 1, content="true")
}

///| Phase 36 RED: ordinary builders must decline over-15-bit codebooks.
test "PNG dynamic Huffman over-15-bit builder falls back" {
  let frequencies = Array::make(20, 0UL)
  frequencies[0] = 1UL
  frequencies[1] = 1UL
  for index = 2; index < frequencies.length(); index = index + 1 {
    frequencies[index] = frequencies[index - 1] + frequencies[index - 2]
  }
  inspect(_png_huffman_from_frequencies(frequencies, false, false, true) is None, content="true")
}
