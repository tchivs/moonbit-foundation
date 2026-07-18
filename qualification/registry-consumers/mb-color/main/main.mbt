///|
fn main {
  let sum = @checked.checked_add(127UL, 1UL).unwrap()
  let encoded = @quantize.quantize_encoded_srgb(
    @model.EncodedSrgbComponent::new(0.5).unwrap(),
  )
  let alpha = @quantize.quantize_alpha(
    @model.NormalizedAlpha::new(0.5).unwrap(),
  )
  let roundtrip = @quantize.quantize_encoded_srgb(
    @quantize.dequantize_encoded_srgb(encoded),
  )
  if sum == 128UL && encoded.value().to_uint64() == 128UL &&
    alpha.value().to_uint64() == 128UL &&
    roundtrip.value().to_uint64() == 128UL {
    println("consumer=mb-color sum=128 encoded=128 alpha=128 roundtrip=128")
  } else {
    println("consumer=mb-color status=failed")
  }
}
