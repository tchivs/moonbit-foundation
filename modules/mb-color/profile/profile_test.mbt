///|
fn profile_budget(
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
fn valid_tag(value : String) -> @profile.ProfileFormatTag {
  @profile.ProfileFormatTag::new(value).unwrap()
}

///|
test "builtin sRGB identity is direct and has no opaque payload" {
  let identity = @profile.ProfileIdentity::builtin_srgb()
  inspect(identity.is_builtin_srgb(), content="true")
  inspect(identity.opaque_profile() is None, content="true")
}

///|
test "profile format tags preserve accepted spelling and canonical icc" {
  inspect(@profile.ProfileFormatTag::icc().value(), content="icc")
  for
    spelling in [
      "a", "ICC", "ICC-v4.4_test+1", "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
    ] {
    let tag = valid_tag(spelling)
    inspect(tag.value() == spelling, content="true")
  }
}

///|
test "profile format tags reject empty invalid ASCII and overlong spellings" {
  for
    spelling in [
      "", "-icc", "contains space", "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz", "iccé",
    ] {
    match @profile.ProfileFormatTag::new(spelling) {
      Err(error) => {
        inspect(
          error.category() == @error.ErrorCategory::InvalidInput,
          content="true",
        )
        inspect(
          error.code() == @error.ErrorCode::InvalidEncoding,
          content="true",
        )
        inspect(error.context() == Some("profile-format-tag"), content="true")
      }
      Ok(_) => fail("invalid profile tag must reject")
    }
  }
}

///|
#warnings("-35")
test "empty and exact-limit opaque payloads round-trip exactly" {
  let empty_limits = @profile.ProfileLimits::new(0UL)
  inspect(empty_limits.max_payload_bytes(), content="0")
  let empty = match
    @profile.OpaqueProfile::from_bytes(
      @profile.ProfileFormatTag::icc(),
      b"",
      empty_limits,
      profile_budget(0UL, 1UL, 0UL),
    ) {
    Ok(profile) => profile
    Err(_) => fail("empty opaque payload within limits must succeed")
  }
  inspect(empty.length(), content="0")
  inspect(empty.view().length(), content="0")

  let source = b"\x00\x01\x7f\xff"
  let exact = match
    @profile.OpaqueProfile::from_bytes(
      valid_tag("ICC-v4.4_test+1"),
      source,
      @profile.ProfileLimits::new(4UL),
      profile_budget(4UL, 1UL, 4UL),
    ) {
    Ok(profile) => profile
    Err(_) => fail("exact-limit opaque payload must succeed")
  }
  inspect(exact.tag().value(), content="ICC-v4.4_test+1")
  inspect(exact.length(), content="4")
  for index = 0; index < 4; index = index + 1 {
    inspect(
      exact.view().get(index.to_uint64()).unwrap() == source[index],
      content="true",
    )
  }
  let identity = @profile.ProfileIdentity::opaque(exact)
  inspect(identity.is_builtin_srgb(), content="false")
  inspect(identity.opaque_profile().unwrap().length(), content="4")
}

///|
test "one-over-limit rejects before consuming budget" {
  let budget = profile_budget(5UL, 1UL, 5UL)
  match
    @profile.OpaqueProfile::from_bytes(
      @profile.ProfileFormatTag::icc(),
      b"abcde",
      @profile.ProfileLimits::new(4UL),
      budget,
    ) {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
      inspect(error.requested() == Some(5UL), content="true")
      inspect(error.limit() == Some(4UL), content="true")
      inspect(error.context() == Some("profile-payload"), content="true")
    }
    Ok(_) => fail("one-over-limit payload must reject")
  }
  inspect(budget.remaining().bytes(), content="5")
  inspect(budget.remaining().allocations(), content="1")
}

///|
test "each independent storage budget dimension rejects atomically" {
  let cases : Array[(@budget.Budget, String)] = [
    (profile_budget(3UL, 1UL, 4UL), "bytes"),
    (profile_budget(4UL, 0UL, 4UL), "allocations"),
    (profile_budget(4UL, 1UL, 3UL), "allocation_size"),
  ]
  for case in cases {
    let (budget, dimension) = case
    let before = budget.remaining()
    match
      @profile.OpaqueProfile::from_bytes(
        @profile.ProfileFormatTag::icc(),
        b"data",
        @profile.ProfileLimits::new(4UL),
        budget,
      ) {
      Err(error) => {
        inspect(
          error.code() == @error.ErrorCode::BudgetExceeded,
          content="true",
        )
        inspect(error.context() == Some(dimension), content="true")
      }
      Ok(_) => fail("insufficient storage budget must reject")
    }
    let after = budget.remaining()
    inspect(after.bytes() == before.bytes(), content="true")
    inspect(after.allocations() == before.allocations(), content="true")
  }
}
