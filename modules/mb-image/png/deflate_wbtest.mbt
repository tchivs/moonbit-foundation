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
