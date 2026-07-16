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
