///|
fn type2_fixture_index(objects : Array[Bytes]) -> CffIndex {
  let data : Array[Byte] = []
  let offsets : Array[UInt64] = [1UL]
  let mut next = 1UL
  for object in objects {
    for byte in object {
      data.push(byte)
      next = next + 1UL
    }
    offsets.push(next)
  }
  let view = font_wb_view(Bytes::from_array(data))
  {
    count: objects.length().to_uint64(),
    off_size: 1UL,
    offsets,
    object_data: view,
    encoded_length: view.length(),
  }
}

///|
fn type2_fixture_run(
  root : Bytes,
  local_objects : Array[Bytes],
  global_objects : Array[Bytes],
  limits : Type2Limits,
) -> Result[Type2VmResult, @error.CoreError] {
  let root_view = font_wb_view(root)
  type2_execute_program(
    root_view,
    type2_fixture_index(local_objects),
    type2_fixture_index(global_objects),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    limits,
    root_view.mutation_revision(),
  )
}

///|
test "Type 2 subroutine bias thresholds are count-derived" {
  inspect(type2_subr_bias(0UL), content="107")
  inspect(type2_subr_bias(1239UL), content="107")
  inspect(type2_subr_bias(1240UL), content="1131")
  inspect(type2_subr_bias(33899UL), content="1131")
  inspect(type2_subr_bias(33900UL), content="32768")
  inspect(type2_subr_bias(65536UL), content="32768")
}

///|
test "Type 2 local and global frames share the operand stack without host recursion" {
  // root -> local[0] -> global[0] -> return -> return -> root endchar
  let local_to_global = type2_fixture_run(
    b"\x20\x0a\x0e",
    [b"\x20\x1d\x0b"],
    [b"\x92\x0b"],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(local_to_global.width.unwrap().raw, content="458752")
  inspect(local_to_global.ledger.calls, content="2")
  inspect(local_to_global.ledger.returns, content="2")

  // root -> global[0] -> local[0] -> return -> return -> root endchar
  let global_to_local = type2_fixture_run(
    b"\x20\x1d\x0e",
    [b"\x93\x0b"],
    [b"\x20\x0a\x0b"],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(global_to_local.width.unwrap().raw, content="524288")
  inspect(global_to_local.ledger.calls, content="2")
  inspect(global_to_local.ledger.returns, content="2")
}

///|
test "Type 2 invalid subr and recursive frame exhaustion are deterministic" {
  let invalid = type2_fixture_run(
    b"\x20\x0a\x0e",
    [],
    [],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap_err()
  inspect(invalid.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    invalid.context() == Some("font-cff-type2-local-subr-index"),
    content="true",
  )

  let recursive = type2_fixture_run(
    b"\x20\x0a\x0e",
    [b"\x20\x0a\x0b"],
    [],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap_err()
  inspect(recursive.category() == @error.ErrorCategory::Resource, content="true")
  inspect(
    recursive.context() == Some("font-cff-type2-frame-depth"),
    content="true",
  )
}

///|
test "Type 2 endchar terminates root and only an all-tail subroutine chain" {
  inspect(type2_vm_wb_run(b"\x0e") is Ok(_), content="true")

  let tail = type2_fixture_run(
    b"\x20\x0a",
    [b"\x0e"],
    [],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(tail.terminated, content="true")

  let nested_tail = type2_fixture_run(
    b"\x20\x0a",
    [b"\x20\x1d"],
    [b"\x0e"],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(nested_tail.terminated, content="true")

  type2_vm_wb_assert_data(type2_vm_wb_run(b""))
  type2_vm_wb_assert_data(type2_vm_wb_run(b"\x0b"))
  type2_vm_wb_assert_data(type2_vm_wb_run(b"\x0e\x0e"))
  let non_tail = type2_fixture_run(
    b"\x20\x0a\x8b\x0c\x12\x0e",
    [b"\x0e"],
    [],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap_err()
  inspect(non_tail.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    non_tail.context() == Some("font-cff-type2-non-tail-endchar"),
    content="true",
  )
  type2_vm_wb_assert_data(
    type2_fixture_run(
      b"\x20\x0a",
      [b"\x0e\x8b"],
      [],
      type2_vm_wb_limits(65535UL, 65535UL),
    ),
  )
  type2_vm_wb_assert_data(
    type2_fixture_run(
      b"\x20\x0a\x0e",
      [b"\x92"],
      [],
      type2_vm_wb_limits(65535UL, 65535UL),
    ),
  )
  type2_vm_wb_assert_data(
    type2_fixture_run(
      b"\x20\x0a\x0e",
      [b"\x0b\x8b"],
      [],
      type2_vm_wb_limits(65535UL, 65535UL),
    ),
  )
}

///|
test "Type 2 capability and reserved operator classes are closed" {
  let dotsection = type2_vm_wb_run(b"\x0c\x00\x0e").unwrap()
  inspect(dotsection.terminated, content="true")

  for source in [
    b"\x8b\x8b\x8b\x8b\x0e", // deprecated seac endchar
    b"\x0f", // CFF2 vsindex
    b"\x10", // CFF2 blend
  ] {
    let error = type2_vm_wb_run(source).unwrap_err()
    inspect(
      error.category() == @error.ErrorCategory::Capability,
      content="true",
    )
  }

  for source in [b"\x00", b"\x02", b"\x0c\x01"] {
    type2_vm_wb_assert_data(type2_vm_wb_run(source))
  }
}

///|
test "Type 2 error precedence is State then Resource then Capability then Data" {
  let owner = font_wb_owner(b"\x00")
  let opening_revision = owner.view().mutation_revision()
  font_wb_mutate_one_byte(owner, 0UL)
  let view = owner.view()
  let state = type2_execute_program(
    view,
    type2_vm_wb_empty_index(view),
    type2_vm_wb_empty_index(view),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    type2_vm_wb_limits(1UL, 1UL),
    opening_revision,
  ).unwrap_err()
  inspect(state.category() == @error.ErrorCategory::State, content="true")

  let resource_before_capability = type2_vm_wb_run_with(
    b"\x8b\x8b\x8b\x8b\x0e",
    0L,
    0L,
    0L,
    type2_vm_wb_limits(65535UL, 4UL),
  ).unwrap_err()
  inspect(
    resource_before_capability.category() == @error.ErrorCategory::Resource,
    content="true",
  )

  let capability = type2_vm_wb_run(b"\x8b\x8b\x8b\x8b\x0e").unwrap_err()
  inspect(
    capability.category() == @error.ErrorCategory::Capability,
    content="true",
  )

  let data = type2_vm_wb_run(b"\x00").unwrap_err()
  inspect(data.category() == @error.ErrorCategory::Data, content="true")
}
