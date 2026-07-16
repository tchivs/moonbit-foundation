///|
test "normalized validator rejects special values before closed-range acceptance" {
  let nan = 0.0 / 0.0
  let infinity = 1.0 / 0.0
  let neg_infinity = -1.0 / 0.0
  inspect(
    validate_normalized(nan, "probe") is Err(_),
    content="true",
  )
  inspect(validate_normalized(infinity, "probe") is Err(_), content="true")
  inspect(
    validate_normalized(neg_infinity, "probe") is Err(_),
    content="true",
  )
  inspect(validate_normalized(-0.1, "probe") is Err(_), content="true")
  inspect(validate_normalized(1.1, "probe") is Err(_), content="true")
  inspect(validate_normalized(0.0, "probe") is Ok(_), content="true")
  inspect(validate_normalized(1.0, "probe") is Ok(_), content="true")
}

///|
test "encoded validator rejects full-width overflow before byte conversion" {
  inspect(validate_encoded8(0UL, "probe") is Ok(_), content="true")
  inspect(validate_encoded8(255UL, "probe") is Ok(_), content="true")
  inspect(validate_encoded8(256UL, "probe") is Err(_), content="true")
  inspect(
    validate_encoded8(18446744073709551615UL, "probe") is Err(_),
    content="true",
  )
}

///|
test "validation errors use stable bounded structured context" {
  let nan = 0.0 / 0.0
  match validate_normalized(nan, "encoded-srgb-component") {
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::InvalidInput, content="true")
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
      inspect(error.context() == Some("encoded-srgb-component"), content="true")
    }
    Ok(_) => fail("NaN must not enter normalized state")
  }
}
