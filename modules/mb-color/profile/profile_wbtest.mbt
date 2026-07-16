///|
fn internal_budget(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
}

///|
test "tag and caller-limit rejection precede owned-byte charging" {
  let invalid_tag_budget = internal_budget(1UL, 1UL, 1UL)
  inspect(ProfileFormatTag::new("-icc") is Err(_), content="true")
  inspect(invalid_tag_budget.remaining().bytes(), content="1")
  inspect(invalid_tag_budget.remaining().allocations(), content="1")

  let oversize_budget = internal_budget(5UL, 1UL, 5UL)
  let tag = ProfileFormatTag::icc()
  inspect(
    OpaqueProfile::from_bytes(
      tag,
      b"abcde",
      ProfileLimits::new(4UL),
      oversize_budget,
    )
    is Err(_),
    content="true",
  )
  inspect(oversize_budget.remaining().bytes(), content="5")
  inspect(oversize_budget.remaining().allocations(), content="1")
}

///|
test "owned profile storage is independent from the immutable source" {
  let source = b"abc"
  let profile = OpaqueProfile::from_bytes(
    ProfileFormatTag::icc(),
    source,
    ProfileLimits::new(3UL),
    internal_budget(3UL, 1UL, 3UL),
  ).unwrap()
  inspect(
    profile.owner.with_mut(0UL, 3UL, fn(lease) { lease.set(0UL, b'z') })
    is Ok(_),
    content="true",
  )
  inspect(source[0] == b'a', content="true")
  inspect(profile.view().get(0UL).unwrap() == b'z', content="true")
}

///|
test "icc-tagged arbitrary bytes remain opaque without header inspection" {
  for payload in [b"x", b"\x00\x00\x00\x84mntr"] {
    let length = payload.length().to_uint64()
    let profile = OpaqueProfile::from_bytes(
      ProfileFormatTag::icc(),
      payload,
      ProfileLimits::new(length),
      internal_budget(length, 1UL, length),
    ).unwrap()
    inspect(profile.length() == length, content="true")
    for index = 0; index < payload.length(); index = index + 1 {
      inspect(
        profile.view().get(index.to_uint64()).unwrap() == payload[index],
        content="true",
      )
    }
  }
}

///|
test "generated profile payload and budget evidence is complete" {
  let mut empty_count = 0
  let mut exact_limit_count = 0
  let mut one_over_limit_count = 0
  let mut opaque_icc_shaped_count = 0
  for case in generated_profile_payload_cases() {
    let (id, payload, maximum, should_succeed) = case
    match id {
      "empty" => empty_count = empty_count + 1
      "exact-limit" => exact_limit_count = exact_limit_count + 1
      "one-over-limit" => one_over_limit_count = one_over_limit_count + 1
      "opaque-icc-shaped" =>
        opaque_icc_shaped_count = opaque_icc_shaped_count + 1
      _ => fail("unexpected generated profile payload case")
    }
    let length = payload.length().to_uint64()
    let budget = internal_budget(length, 1UL, length)
    let before = budget.remaining()
    match
      OpaqueProfile::from_bytes(
        ProfileFormatTag::icc(),
        payload,
        ProfileLimits::new(maximum),
        budget,
      ) {
      Ok(profile) => {
        inspect(should_succeed, content="true")
        inspect(profile.length() == length, content="true")
        for index = 0; index < payload.length(); index = index + 1 {
          inspect(
            profile.view().get(index.to_uint64()).unwrap() == payload[index],
            content="true",
          )
        }
      }
      Err(error) => {
        inspect(should_succeed, content="false")
        inspect(
          error.code() == @error.ErrorCode::BudgetExceeded,
          content="true",
        )
        inspect(error.context() == Some("profile-payload"), content="true")
        let after = budget.remaining()
        inspect(after.bytes() == before.bytes(), content="true")
        inspect(after.allocations() == before.allocations(), content="true")
        inspect(
          after.allocation_size() == before.allocation_size(),
          content="true",
        )
      }
    }
  }
  inspect(generated_profile_payload_cases().length(), content="4")
  inspect(empty_count, content="1")
  inspect(exact_limit_count, content="1")
  inspect(one_over_limit_count, content="1")
  inspect(opaque_icc_shaped_count, content="1")

  let budget_cases = generated_profile_budget_rejection_cases()
  inspect(budget_cases.length(), content="7")
  let mut empty_allocations_count = 0
  let mut exact_limit_bytes_count = 0
  let mut exact_limit_allocations_count = 0
  let mut exact_limit_allocation_size_count = 0
  let mut opaque_icc_shaped_bytes_count = 0
  let mut opaque_icc_shaped_allocations_count = 0
  let mut opaque_icc_shaped_allocation_size_count = 0
  for case in budget_cases {
    let (id, payload, maximum, bytes, allocations, allocation_size, dimension) = case
    match id {
      "empty/a" => empty_allocations_count = empty_allocations_count + 1
      "exact-limit/b" => exact_limit_bytes_count = exact_limit_bytes_count + 1
      "exact-limit/a" =>
        exact_limit_allocations_count = exact_limit_allocations_count + 1
      "exact-limit/s" =>
        exact_limit_allocation_size_count = exact_limit_allocation_size_count +
          1
      "opaque-icc-shaped/b" =>
        opaque_icc_shaped_bytes_count = opaque_icc_shaped_bytes_count + 1
      "opaque-icc-shaped/a" =>
        opaque_icc_shaped_allocations_count = opaque_icc_shaped_allocations_count +
          1
      "opaque-icc-shaped/s" =>
        opaque_icc_shaped_allocation_size_count = opaque_icc_shaped_allocation_size_count +
          1
      _ => fail("unexpected generated profile budget case")
    }
    let budget = internal_budget(bytes, allocations, allocation_size)
    let before = budget.remaining()
    match
      OpaqueProfile::from_bytes(
        ProfileFormatTag::icc(),
        payload,
        ProfileLimits::new(maximum),
        budget,
      ) {
      Err(error) => {
        inspect(
          error.code() == @error.ErrorCode::BudgetExceeded,
          content="true",
        )
        inspect(error.context() == Some(dimension), content="true")
      }
      Ok(_) => fail("generated underfunded profile budget must reject")
    }
    let after = budget.remaining()
    inspect(after.bytes() == before.bytes(), content="true")
    inspect(after.allocations() == before.allocations(), content="true")
    inspect(after.allocation_size() == before.allocation_size(), content="true")
  }
  inspect(empty_allocations_count, content="1")
  inspect(exact_limit_bytes_count, content="1")
  inspect(exact_limit_allocations_count, content="1")
  inspect(exact_limit_allocation_size_count, content="1")
  inspect(opaque_icc_shaped_bytes_count, content="1")
  inspect(opaque_icc_shaped_allocations_count, content="1")
  inspect(opaque_icc_shaped_allocation_size_count, content="1")
}
