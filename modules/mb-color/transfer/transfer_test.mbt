///|
fn require_linear(_value : @model.LinearSrgbComponent) -> Unit {
  ()
}

///|
fn require_encoded(_value : @model.EncodedSrgbComponent) -> Unit {
  ()
}

///|
fn encoded(value : Double) -> @model.EncodedSrgbComponent {
  @model.EncodedSrgbComponent::new(value).unwrap()
}

///|
fn linear(value : Double) -> @model.LinearSrgbComponent {
  @model.LinearSrgbComponent::new(value).unwrap()
}

///|
fn close(actual : Double, expected : Double, tolerance : Double) -> Bool {
  (actual - expected).abs() <= tolerance
}

///|
test "transfer preserves encoded and linear component identity" {
  let decoded = @transfer.decode_srgb(encoded(0.5))
  let encoded_again = @transfer.encode_srgb(linear(0.5))
  require_linear(decoded)
  require_encoded(encoded_again)
  inspect(
    decoded.transfer() == @model.TransferIdentity::LinearSrgb,
    content="true",
  )
  inspect(
    encoded_again.transfer() == @model.TransferIdentity::EncodedSrgb,
    content="true",
  )
}

///|
test "transfer exposes locked operation tolerances" {
  inspect(@transfer.decode_absolute_tolerance() == 1.0e-12, content="true")
  inspect(@transfer.encode_absolute_tolerance() == 1.0e-12, content="true")
  inspect(@transfer.roundtrip_absolute_tolerance() == 2.0e-12, content="true")
}

///|
test "transfer maps endpoints and stays finite and normalized" {
  for value in [0.0, 0.0031308, 0.04045, 0.5, 1.0] {
    let decoded = @transfer.decode_srgb(encoded(value)).value()
    let encoded_again = @transfer.encode_srgb(linear(value)).value()
    inspect(!decoded.is_nan() && !decoded.is_inf(), content="true")
    inspect(!encoded_again.is_nan() && !encoded_again.is_inf(), content="true")
    inspect(decoded >= 0.0 && decoded <= 1.0, content="true")
    inspect(encoded_again >= 0.0 && encoded_again <= 1.0, content="true")
  }
  inspect(@transfer.decode_srgb(encoded(0.0)).value() == 0.0, content="true")
  inspect(@transfer.decode_srgb(encoded(1.0)).value() == 1.0, content="true")
  inspect(@transfer.encode_srgb(linear(0.0)).value() == 0.0, content="true")
  inspect(
    close(
      @transfer.encode_srgb(linear(1.0)).value(),
      1.0,
      @transfer.encode_absolute_tolerance(),
    ),
    content="true",
  )
}

///|
test "transfer is monotonic on ordered encoded and linear grids" {
  let grid = [0.0, 0.001, 0.0031308, 0.01, 0.04045, 0.25, 0.5, 0.75, 1.0]
  let mut previous_decoded = -1.0
  let mut previous_encoded = -1.0
  for value in grid {
    let decoded = @transfer.decode_srgb(encoded(value)).value()
    let encoded_value = @transfer.encode_srgb(linear(value)).value()
    inspect(decoded >= previous_decoded, content="true")
    inspect(encoded_value >= previous_encoded, content="true")
    previous_decoded = decoded
    previous_encoded = encoded_value
  }
}

///|
test "transfer round trips away from rounded branch discontinuities" {
  for value in [0.0, 0.001, 0.02, 0.1, 0.25, 0.5, 0.75, 1.0] {
    let roundtrip = @transfer.encode_srgb(@transfer.decode_srgb(encoded(value)))
    inspect(
      close(
        roundtrip.value(),
        value,
        @transfer.roundtrip_absolute_tolerance(),
      ),
      content="true",
    )
  }
  for value in [0.0, 0.001, 0.01, 0.1, 0.25, 0.5, 0.75, 1.0] {
    let roundtrip = @transfer.decode_srgb(@transfer.encode_srgb(linear(value)))
    inspect(
      close(
        roundtrip.value(),
        value,
        @transfer.roundtrip_absolute_tolerance(),
      ),
      content="true",
    )
  }
}
