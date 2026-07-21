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
  inspect(false, content="dynamic Huffman builder missing")
}

///| Phase 36 RED: dynamic header planning is not available in the Phase 35 seam.
test "PNG dynamic Huffman header uses RFC order and RLE" {
  inspect(false, content="dynamic Huffman header missing")
}

///| Phase 36 RED: singleton dynamic alphabets require encoder support.
test "PNG dynamic Huffman handles singleton distance and code-length trees" {
  inspect(false, content="dynamic singleton handling missing")
}

///| Phase 36 RED: ordinary builders must decline over-15-bit codebooks.
test "PNG dynamic Huffman over-15-bit builder falls back" {
  inspect(false, content="dynamic fallback missing")
}
