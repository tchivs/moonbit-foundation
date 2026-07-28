///|
priv enum Type2FrameKind {
  Root
  Local
  Global
}

///|
priv struct Type2Frame {
  kind : Type2FrameKind
  source : @bytes.ByteView
  mut cursor : UInt64
  tail_call : Bool
}

///|
priv enum Type2Step {
  Continue(Type2Frame)
  FramesManaged
  Terminate
}

///|
priv struct Type2ExecutionLedger {
  mut executed_bytes : UInt64
  mut work : UInt64
  mut calls : UInt64
  mut returns : UInt64
  mut operators : UInt64
  mut numbers : UInt64
  mut mask_bytes : UInt64
}

///|
/// Private ticket for the fixed byte/work unit carried by one Type 2
/// instruction. All limits and deferred budget authority are checked before
/// the instruction is observed; accepting the ticket only advances ledgers.
priv struct Type2InstructionCharge {
  executed_bytes : UInt64
  work : UInt64
  authority_work : UInt64?
}

///|
/// Deferred caller/ancestor work authority shared by one staged Type 2
/// transaction. Preflight advances this private ledger without committing the
/// public budget; the admission transaction still performs the sole commit.
priv struct Type2WorkAuthority {
  budget : @budget.Budget
  mut work : UInt64
  limit : UInt64
  context : String
}

///|
fn Type2WorkAuthority::new(
  budget : @budget.Budget,
  work : UInt64,
  limit : UInt64,
  context : String,
) -> Type2WorkAuthority {
  { budget, work, limit, context }
}

///|
fn Type2WorkAuthority::requested(
  self : Type2WorkAuthority,
  amount : UInt64,
) -> Result[UInt64, @error.CoreError] {
  type2_checked_counter_add(self.work, amount, self.limit, self.context)
}

///|
fn Type2WorkAuthority::preflight_additional(
  self : Type2WorkAuthority,
  amount : UInt64,
) -> Result[Unit, @error.CoreError] {
  match self.preflight(amount) {
    Err(error) => Err(error)
    Ok(_) => Ok(())
  }
}

///|
fn Type2WorkAuthority::preflight(
  self : Type2WorkAuthority,
  amount : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let requested = match self.requested(amount) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match self.budget.preflight(
    @budget.ResourceCharge::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=requested,
    ),
  ) {
    Err(error) => Err(error)
    Ok(_) => Ok(requested)
  }
}

///|
fn Type2WorkAuthority::accept_preflighted(
  self : Type2WorkAuthority,
  requested : UInt64,
) -> Unit {
  self.work = requested
}

///|
fn Type2WorkAuthority::charge(
  self : Type2WorkAuthority,
  amount : UInt64,
) -> Result[Unit, @error.CoreError] {
  let requested = match self.preflight(amount) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  self.accept_preflighted(requested)
  Ok(())
}

///|
priv struct Type2VmResult {
  width : Type2Fixed?
  stems : UInt64
  terminated : Bool
  ledger : Type2ExecutionLedger
  geometry_operators : UInt64
  geometry : Type2GeometryFacts
}

///|
priv struct Type2StagedCharge {
  resource : @budget.ResourceCharge
  bytes : UInt64
  allocations : UInt64
  allocation_size : UInt64
  work : UInt64
  bounds_slots : UInt64
  executed_bytes : UInt64
  calls : UInt64
  returns : UInt64
  operators : UInt64
  numbers : UInt64
  mask_bytes : UInt64
  geometry_operators : UInt64
  points : UInt64
  contours : UInt64
  commands : UInt64
}

///|
priv struct Type2AllGlyphResult {
  bounds : Array[GlyphBoundsFacts?]
  path_command_counts : Array[UInt64]
  path_work : Array[UInt64]
  charge : Type2StagedCharge
}

///|
priv struct Type2Vm {
  stack : Array[Type2Fixed]
  transient : Array[Type2Fixed]
  transient_initialized : Array[Bool]
  frames : Array[Type2Frame]
  local_subrs : CffIndex
  global_subrs : CffIndex
  default_width : Type2Fixed
  nominal_width : Type2Fixed
  mut width : Type2Fixed?
  mut width_resolved : Bool
  mut stems : UInt64
  mut geometry_started : Bool
  mut geometry_operators : UInt64
  geometry : Type2BoundsSink
  prng : Type2Prng
  limits : Type2Limits
  ledger : Type2ExecutionLedger
  work_authority : Type2WorkAuthority?
}

///|
fn type2_resource_error(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="font-cff-type2",
    requested~,
    limit~,
    context~,
  )
}

///|
fn type2_capability_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation="font-cff-type2",
    context~,
  )
}

///|
fn type2_state_error() -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation="font-cff-type2",
    context="font-cff-type2-source-revision-drift",
  )
}

///|
fn type2_require_revision(
  source : @bytes.ByteView,
  opening_revision : UInt64,
) -> Result[Unit, @error.CoreError] {
  if source.mutation_revision() != opening_revision {
    Err(type2_state_error())
  } else {
    Ok(())
  }
}

///|
fn type2_checked_counter_add(
  current : UInt64,
  amount : UInt64,
  limit : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  let requested = match @checked.checked_add(current, amount) {
    Err(_) => return Err(type2_resource_error(context, current, limit))
    Ok(value) => value
  }
  if requested > limit {
    Err(type2_resource_error(context, requested, limit))
  } else {
    Ok(requested)
  }
}

///|
fn Type2Vm::charge_bytes(
  self : Type2Vm,
  amount : UInt64,
) -> Result[Unit, @error.CoreError] {
  let requested = match
    type2_checked_counter_add(
      self.ledger.executed_bytes,
      amount,
      self.limits.max_executed_bytes,
      "font-cff-type2-executed-bytes",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  self.ledger.executed_bytes = requested
  Ok(())
}

///|
fn Type2Vm::charge_work(
  self : Type2Vm,
  amount : UInt64,
) -> Result[Unit, @error.CoreError] {
  let requested = match
    type2_checked_counter_add(
      self.ledger.work,
      amount,
      self.limits.max_work,
      "font-cff-type2-work",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match self.work_authority {
    Some(authority) =>
      match authority.charge(amount) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
    None => ()
  }
  self.ledger.work = requested
  Ok(())
}

///|
fn Type2Vm::preflight_instruction(
  self : Type2Vm,
) -> Result[Type2InstructionCharge, @error.CoreError] {
  // Preserve byte-before-work Resource precedence while authorizing the work
  // unit before the instruction is observed.
  let executed_bytes = match
    type2_checked_counter_add(
      self.ledger.executed_bytes,
      1UL,
      self.limits.max_executed_bytes,
      "font-cff-type2-executed-bytes",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = match
    type2_checked_counter_add(
      self.ledger.work,
      1UL,
      self.limits.max_work,
      "font-cff-type2-work",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let authority_work = match self.work_authority {
    Some(authority) =>
      match authority.preflight(1UL) {
        Err(error) => return Err(error)
        Ok(value) => Some(value)
      }
    None => None
  }
  Ok({ executed_bytes, work, authority_work })
}

///|
fn Type2Vm::accept_preflighted_instruction(
  self : Type2Vm,
  charge : Type2InstructionCharge,
) -> Unit {
  self.ledger.executed_bytes = charge.executed_bytes
  self.ledger.work = charge.work
  match self.work_authority {
    Some(authority) =>
      match charge.authority_work {
        Some(requested) => authority.accept_preflighted(requested)
        None => ()
      }
    None => ()
  }
}

///|
fn Type2Vm::require_stack(
  self : Type2Vm,
  count : Int,
) -> Result[Unit, @error.CoreError] {
  if count < 0 || self.stack.length() < count {
    Err(type2_data_error("font-cff-type2-stack-underflow"))
  } else {
    Ok(())
  }
}

///|
fn Type2Vm::require_stack_space(
  self : Type2Vm,
  count : UInt64,
) -> Result[Unit, @error.CoreError] {
  let requested = match
    @checked.checked_add(self.stack.length().to_uint64(), count) {
    Err(_) =>
      return Err(
        type2_resource_error(
          "font-cff-type2-operand-stack",
          self.stack.length().to_uint64(),
          self.limits.max_operand_stack,
        ),
      )
    Ok(value) => value
  }
  if requested > self.limits.max_operand_stack {
    Err(
      type2_resource_error(
        "font-cff-type2-operand-stack",
        requested,
        self.limits.max_operand_stack,
      ),
    )
  } else {
    Ok(())
  }
}

///|
fn Type2Vm::push(
  self : Type2Vm,
  value : Type2Fixed,
) -> Result[Unit, @error.CoreError] {
  match self.require_stack_space(1UL) {
    Err(error) => Err(error)
    Ok(_) => {
      self.stack.push(value)
      Ok(())
    }
  }
}

///|
fn Type2Vm::clear_stack(self : Type2Vm) -> Unit {
  while self.stack.length() > 0 {
    ignore(self.stack.pop())
  }
}

///|
fn Type2Vm::remove_stack_first(self : Type2Vm) -> Type2Fixed {
  let first = self.stack[0]
  for index = 1; index < self.stack.length(); index = index + 1 {
    self.stack[index - 1] = self.stack[index]
  }
  ignore(self.stack.pop())
  first
}

///|
fn type2_fixed_exact_int(
  value : Type2Fixed,
  context : String,
) -> Result[Int, @error.CoreError] {
  if value.raw % 65536L != 0L {
    return Err(type2_data_error(context))
  }
  let integer = value.raw / 65536L
  if integer < -2147483647L || integer > 2147483647L {
    Err(type2_data_error(context))
  } else {
    Ok(integer.to_int())
  }
}

///|
fn Type2Vm::resolve_width(
  self : Type2Vm,
  has_explicit_width : Bool,
) -> Result[Unit, @error.CoreError] {
  if self.width_resolved {
    if has_explicit_width {
      return Err(type2_data_error("font-cff-type2-width-duplicate"))
    }
    return Ok(())
  }
  if has_explicit_width {
    let delta = self.remove_stack_first()
    self.width = Some(
      match type2_fixed_add(self.nominal_width, delta) {
        Err(_) => return Err(type2_data_error("font-cff-type2-width"))
        Ok(value) => value
      },
    )
  } else {
    self.width = Some(self.default_width)
  }
  self.width_resolved = true
  Ok(())
}

///|
fn Type2Vm::binary_arithmetic(
  self : Type2Vm,
  operator : UInt64,
) -> Result[Unit, @error.CoreError] {
  match self.require_stack(2) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = self.stack.length()
  let left = self.stack[count - 2]
  let right = self.stack[count - 1]
  let result = match operator {
    10UL =>
      match type2_fixed_add(left, right) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
    11UL =>
      match type2_fixed_sub(left, right) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
    12UL =>
      match type2_fixed_div(left, right) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
    24UL =>
      match type2_fixed_mul(left, right) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
    _ => return Err(type2_data_error("font-cff-type2-operator"))
  }
  ignore(self.stack.pop())
  ignore(self.stack.pop())
  self.stack.push(result)
  Ok(())
}

///|
fn Type2Vm::binary_logic(
  self : Type2Vm,
  operator : UInt64,
) -> Result[Unit, @error.CoreError] {
  match self.require_stack(2) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = self.stack.length()
  let left = self.stack[count - 2]
  let right = self.stack[count - 1]
  let truth = match operator {
    3UL => left.raw != 0L && right.raw != 0L
    4UL => left.raw != 0L || right.raw != 0L
    15UL => left.raw == right.raw
    _ => return Err(type2_data_error("font-cff-type2-operator"))
  }
  ignore(self.stack.pop())
  ignore(self.stack.pop())
  self.stack.push({ raw: if truth { 65536L } else { 0L } })
  Ok(())
}

///|
fn Type2Vm::unary_operator(
  self : Type2Vm,
  operator : UInt64,
) -> Result[Unit, @error.CoreError] {
  match self.require_stack(1) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let index = self.stack.length() - 1
  let operand = self.stack[index]
  let result = match operator {
    5UL => Ok({ raw: if operand.raw == 0L { 65536L } else { 0L } })
    9UL => type2_fixed_abs(operand)
    14UL => type2_fixed_neg(operand)
    26UL => type2_fixed_sqrt(operand)
    _ => Err(type2_data_error("font-cff-type2-operator"))
  }
  self.stack[index] = match result {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(())
}

///|
fn Type2Vm::execute_put(self : Type2Vm) -> Result[Unit, @error.CoreError] {
  match self.require_stack(2) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = self.stack.length()
  let value = self.stack[count - 2]
  let transient_index = match
    type2_fixed_exact_int(
      self.stack[count - 1],
      "font-cff-type2-transient-index",
    ) {
    Err(error) => return Err(error)
    Ok(index) => index
  }
  if transient_index < 0 ||
    transient_index >= self.limits.max_transient.to_int() {
    return Err(type2_data_error("font-cff-type2-transient-index"))
  }
  ignore(self.stack.pop())
  ignore(self.stack.pop())
  self.transient[transient_index] = value
  self.transient_initialized[transient_index] = true
  Ok(())
}

///|
fn Type2Vm::execute_get(self : Type2Vm) -> Result[Unit, @error.CoreError] {
  match self.require_stack(1) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let top = self.stack.length() - 1
  let transient_index = match
    type2_fixed_exact_int(self.stack[top], "font-cff-type2-transient-index") {
    Err(error) => return Err(error)
    Ok(index) => index
  }
  if transient_index < 0 ||
    transient_index >= self.limits.max_transient.to_int() {
    return Err(type2_data_error("font-cff-type2-transient-index"))
  }
  if !self.transient_initialized[transient_index] {
    return Err(type2_data_error("font-cff-type2-transient-uninitialized"))
  }
  self.stack[top] = self.transient[transient_index]
  Ok(())
}

///|
fn Type2Vm::execute_ifelse(self : Type2Vm) -> Result[Unit, @error.CoreError] {
  match self.require_stack(4) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = self.stack.length()
  let first = self.stack[count - 4]
  let second = self.stack[count - 3]
  let selector_left = self.stack[count - 2]
  let selector_right = self.stack[count - 1]
  let selected = if selector_left.raw <= selector_right.raw {
    first
  } else {
    second
  }
  for _index = 0; _index < 4; _index = _index + 1 {
    ignore(self.stack.pop())
  }
  self.stack.push(selected)
  Ok(())
}

///|
fn Type2Vm::execute_index(self : Type2Vm) -> Result[Unit, @error.CoreError] {
  match self.require_stack(2) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = self.stack.length()
  let operand = match
    type2_fixed_exact_int(self.stack[count - 1], "font-cff-type2-index") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if operand < 0 || operand >= count - 1 {
    return Err(type2_data_error("font-cff-type2-index"))
  }
  let selected = self.stack[count - 2 - operand]
  // Consuming the index and pushing one value preserves capacity.
  self.stack[count - 1] = selected
  Ok(())
}

///|
fn Type2Vm::execute_roll(self : Type2Vm) -> Result[Unit, @error.CoreError] {
  match self.require_stack(3) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = self.stack.length()
  let n = match
    type2_fixed_exact_int(self.stack[count - 2], "font-cff-type2-roll") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let j = match
    type2_fixed_exact_int(self.stack[count - 1], "font-cff-type2-roll") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if n <= 0 || n > count - 2 {
    return Err(type2_data_error("font-cff-type2-roll"))
  }
  let start = count - 2 - n
  let normalized = (j % n + n) % n
  if normalized != 0 {
    // Rotate right in place with three reversals. The operand stack has fixed
    // capacity, so roll never allocates in proportion to operator count.
    let end = count - 2
    let mut left = start
    let mut right = end - 1
    while left < right {
      let value = self.stack[left]
      self.stack[left] = self.stack[right]
      self.stack[right] = value
      left = left + 1
      right = right - 1
    }
    left = start
    right = start + normalized - 1
    while left < right {
      let value = self.stack[left]
      self.stack[left] = self.stack[right]
      self.stack[right] = value
      left = left + 1
      right = right - 1
    }
    left = start + normalized
    right = end - 1
    while left < right {
      let value = self.stack[left]
      self.stack[left] = self.stack[right]
      self.stack[right] = value
      left = left + 1
      right = right - 1
    }
  }
  ignore(self.stack.pop())
  ignore(self.stack.pop())
  Ok(())
}

///|
fn type2_flex_add(
  left : Type2Fixed,
  right : Type2Fixed,
) -> Result[Type2Fixed, @error.CoreError] {
  match type2_fixed_add(left, right) {
    Err(_) => Err(type2_data_error("font-cff-type2-coordinate"))
    Ok(value) => Ok(value)
  }
}

///|
fn Type2Vm::execute_flex(
  self : Type2Vm,
  operator : UInt64,
) -> Result[Unit, @error.CoreError] {
  if !self.width_resolved {
    return Err(type2_data_error("font-cff-type2-geometry-order"))
  }
  let expected = match operator {
    34UL => 7
    35UL => 13
    36UL => 9
    37UL => 11
    _ => return Err(type2_data_error("font-cff-type2-operator"))
  }
  if self.stack.length() != expected {
    return Err(type2_data_error("font-cff-type2-flex-arity"))
  }
  match self.geometry.preflight_segments(6UL, 2UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let zero : Type2Fixed = { raw: 0L }
  let curves : Result[Unit, @error.CoreError] = match operator {
    34UL => {
      match self.geometry.cubic_relative_unchecked(
        self.stack[0],
        zero,
        self.stack[1],
        self.stack[2],
        self.stack[3],
        zero,
      ) {
        Err(error) => Err(error)
        Ok(_) => {
          let opposite = match type2_fixed_neg(self.stack[2]) {
            Err(_) => return Err(type2_data_error("font-cff-type2-coordinate"))
            Ok(value) => value
          }
          self.geometry.cubic_relative_unchecked(
            self.stack[4],
            zero,
            self.stack[5],
            opposite,
            self.stack[6],
            zero,
          )
        }
      }
    }
    35UL => {
      match self.geometry.cubic_relative_unchecked(
        self.stack[0],
        self.stack[1],
        self.stack[2],
        self.stack[3],
        self.stack[4],
        self.stack[5],
      ) {
        Err(error) => Err(error)
        Ok(_) =>
          self.geometry.cubic_relative_unchecked(
            self.stack[6],
            self.stack[7],
            self.stack[8],
            self.stack[9],
            self.stack[10],
            self.stack[11],
          )
      }
    }
    36UL => {
      let dy = match type2_flex_add(self.stack[1], self.stack[3]) {
        Err(error) => return Err(error)
        Ok(value) =>
          match type2_flex_add(value, self.stack[7]) {
            Err(error) => return Err(error)
            Ok(result) =>
              match type2_fixed_neg(result) {
                Err(_) =>
                  return Err(type2_data_error("font-cff-type2-coordinate"))
                Ok(negated) => negated
              }
          }
      }
      match self.geometry.cubic_relative_unchecked(
        self.stack[0],
        self.stack[1],
        self.stack[2],
        self.stack[3],
        self.stack[4],
        zero,
      ) {
        Err(error) => Err(error)
        Ok(_) =>
          self.geometry.cubic_relative_unchecked(
            self.stack[5],
            zero,
            self.stack[6],
            self.stack[7],
            self.stack[8],
            dy,
          )
      }
    }
    37UL => {
      let mut sum_x = zero
      let mut sum_y = zero
      let mut index = 0
      while index < 10 {
        sum_x = match type2_flex_add(sum_x, self.stack[index]) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        sum_y = match type2_flex_add(sum_y, self.stack[index + 1]) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        index = index + 2
      }
      let abs_x = match type2_fixed_abs(sum_x) {
        Err(_) => return Err(type2_data_error("font-cff-type2-coordinate"))
        Ok(value) => value
      }
      let abs_y = match type2_fixed_abs(sum_y) {
        Err(_) => return Err(type2_data_error("font-cff-type2-coordinate"))
        Ok(value) => value
      }
      let (dx6, dy6) = if abs_x.raw > abs_y.raw {
        (
          self.stack[10],
          match type2_fixed_neg(sum_y) {
            Err(_) => return Err(type2_data_error("font-cff-type2-coordinate"))
            Ok(value) => value
          },
        )
      } else {
        (
          match type2_fixed_neg(sum_x) {
            Err(_) => return Err(type2_data_error("font-cff-type2-coordinate"))
            Ok(value) => value
          },
          self.stack[10],
        )
      }
      match self.geometry.cubic_relative_unchecked(
        self.stack[0],
        self.stack[1],
        self.stack[2],
        self.stack[3],
        self.stack[4],
        self.stack[5],
      ) {
        Err(error) => Err(error)
        Ok(_) =>
          self.geometry.cubic_relative_unchecked(
            self.stack[6],
            self.stack[7],
            self.stack[8],
            self.stack[9],
            dx6,
            dy6,
          )
      }
    }
    _ => Err(type2_data_error("font-cff-type2-operator"))
  }
  match curves {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  self.geometry_started = true
  self.geometry_operators = self.geometry_operators + 1UL
  self.clear_stack()
  Ok(())
}

///|
fn Type2Vm::execute_escaped(
  self : Type2Vm,
  operator : UInt64,
) -> Result[Unit, @error.CoreError] {
  match operator {
    0UL => Ok(()) // dotsection
    3UL | 4UL | 15UL => self.binary_logic(operator)
    5UL | 9UL | 14UL | 26UL => self.unary_operator(operator)
    10UL | 11UL | 12UL | 24UL => self.binary_arithmetic(operator)
    18UL => {
      match self.require_stack(1) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      ignore(self.stack.pop())
      Ok(())
    }
    20UL => self.execute_put()
    21UL => self.execute_get()
    22UL => self.execute_ifelse()
    23UL => {
      match self.require_stack_space(1UL) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      self.stack.push(self.prng.next())
      Ok(())
    }
    27UL => {
      match self.require_stack(1) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      match self.require_stack_space(1UL) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      self.stack.push(self.stack[self.stack.length() - 1])
      Ok(())
    }
    28UL => {
      match self.require_stack(2) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      let count = self.stack.length()
      let top = self.stack[count - 1]
      self.stack[count - 1] = self.stack[count - 2]
      self.stack[count - 2] = top
      Ok(())
    }
    29UL => self.execute_index()
    30UL => self.execute_roll()
    34UL | 35UL | 36UL | 37UL => self.execute_flex(operator)
    _ => Err(type2_data_error("font-cff-type2-reserved-operator"))
  }
}

///|
fn Type2Vm::execute_stem(self : Type2Vm) -> Result[Unit, @error.CoreError] {
  let has_width = !self.width_resolved && self.stack.length() % 2 == 1
  match self.resolve_width(has_width) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if self.geometry_started ||
    self.stack.length() < 2 ||
    self.stack.length() % 2 != 0 {
    return Err(type2_data_error("font-cff-type2-stem-arity"))
  }
  let added = (self.stack.length() / 2).to_uint64()
  let requested = match @checked.checked_add(self.stems, added) {
    Err(_) =>
      return Err(
        type2_resource_error(
          "font-cff-type2-stems",
          self.stems,
          self.limits.max_stems,
        ),
      )
    Ok(value) => value
  }
  if requested > self.limits.max_stems {
    return Err(
      type2_resource_error(
        "font-cff-type2-stems",
        requested,
        self.limits.max_stems,
      ),
    )
  }
  self.stems = requested
  self.clear_stack()
  Ok(())
}

///|
fn Type2Vm::execute_moveto(
  self : Type2Vm,
  operator : UInt64,
) -> Result[Unit, @error.CoreError] {
  let arity = if operator == 21UL { 2 } else { 1 }
  let has_width = !self.width_resolved && self.stack.length() == arity + 1
  match self.resolve_width(has_width) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if self.stack.length() != arity {
    return Err(type2_data_error("font-cff-type2-moveto-arity"))
  }
  let zero : Type2Fixed = { raw: 0L }
  let (dx, dy) = match operator {
    4UL => (zero, self.stack[0])
    21UL => (self.stack[0], self.stack[1])
    22UL => (self.stack[0], zero)
    _ => return Err(type2_data_error("font-cff-type2-operator"))
  }
  match self.geometry.move_relative(dx, dy) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  self.geometry_started = true
  self.geometry_operators = self.geometry_operators + 1UL
  self.clear_stack()
  Ok(())
}

///|
fn Type2Vm::execute_geometry(
  self : Type2Vm,
  operator : UInt64,
) -> Result[Unit, @error.CoreError] {
  if !self.width_resolved {
    return Err(type2_data_error("font-cff-type2-geometry-order"))
  }
  let count = self.stack.length()
  let valid = match operator {
    5UL => count >= 2 && count % 2 == 0
    6UL | 7UL => count >= 1
    8UL => count >= 6 && count % 6 == 0
    24UL => count >= 8 && (count - 2) % 6 == 0
    25UL => count >= 8 && (count - 6) % 2 == 0
    26UL | 27UL | 30UL | 31UL =>
      count >= 4 && (count % 4 == 0 || count % 4 == 1)
    _ => false
  }
  if !valid {
    return Err(type2_data_error("font-cff-type2-geometry-arity"))
  }
  let (line_count, curve_count) = match operator {
    5UL => (count / 2, 0)
    6UL | 7UL => (count, 0)
    8UL => (0, count / 6)
    24UL => (1, (count - 2) / 6)
    25UL => ((count - 6) / 2, 1)
    26UL | 27UL | 30UL | 31UL => (0, count / 4)
    _ => (0, 0)
  }
  match
    self.geometry.preflight_segments(
      line_count.to_uint64() + curve_count.to_uint64() * 3UL,
      line_count.to_uint64() + curve_count.to_uint64(),
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let zero : Type2Fixed = { raw: 0L }
  match operator {
    5UL => {
      let mut index = 0
      while index < count {
        match
          self.geometry.line_relative_unchecked(
            self.stack[index],
            self.stack[index + 1],
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        index = index + 2
      }
    }
    6UL | 7UL => {
      let mut horizontal = operator == 6UL
      for delta in self.stack {
        let result = if horizontal {
          self.geometry.line_relative_unchecked(delta, zero)
        } else {
          self.geometry.line_relative_unchecked(zero, delta)
        }
        match result {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        horizontal = !horizontal
      }
    }
    8UL => {
      let mut index = 0
      while index < count {
        match
          self.geometry.cubic_relative_unchecked(
            self.stack[index],
            self.stack[index + 1],
            self.stack[index + 2],
            self.stack[index + 3],
            self.stack[index + 4],
            self.stack[index + 5],
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        index = index + 6
      }
    }
    24UL => {
      let curve_end = count - 2
      let mut index = 0
      while index < curve_end {
        match
          self.geometry.cubic_relative_unchecked(
            self.stack[index],
            self.stack[index + 1],
            self.stack[index + 2],
            self.stack[index + 3],
            self.stack[index + 4],
            self.stack[index + 5],
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        index = index + 6
      }
      match
        self.geometry.line_relative_unchecked(
          self.stack[curve_end],
          self.stack[curve_end + 1],
        ) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
    }
    25UL => {
      let curve_start = count - 6
      let mut index = 0
      while index < curve_start {
        match
          self.geometry.line_relative_unchecked(
            self.stack[index],
            self.stack[index + 1],
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        index = index + 2
      }
      match
        self.geometry.cubic_relative_unchecked(
          self.stack[curve_start],
          self.stack[curve_start + 1],
          self.stack[curve_start + 2],
          self.stack[curve_start + 3],
          self.stack[curve_start + 4],
          self.stack[curve_start + 5],
        ) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
    }
    26UL => {
      let mut index = 0
      let mut first_dx = zero
      if count % 4 == 1 {
        first_dx = self.stack[0]
        index = 1
      }
      while index < count {
        match
          self.geometry.cubic_relative_unchecked(
            first_dx,
            self.stack[index],
            self.stack[index + 1],
            self.stack[index + 2],
            zero,
            self.stack[index + 3],
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        first_dx = zero
        index = index + 4
      }
    }
    27UL => {
      let mut index = 0
      let mut first_dy = zero
      if count % 4 == 1 {
        first_dy = self.stack[0]
        index = 1
      }
      while index < count {
        match
          self.geometry.cubic_relative_unchecked(
            self.stack[index],
            first_dy,
            self.stack[index + 1],
            self.stack[index + 2],
            self.stack[index + 3],
            zero,
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        first_dy = zero
        index = index + 4
      }
    }
    30UL | 31UL => {
      let mut index = 0
      let mut horizontal = operator == 31UL
      while index < count {
        let remaining = count - index
        let optional = remaining == 5
        let result = if horizontal {
          self.geometry.cubic_relative_unchecked(
            self.stack[index],
            zero,
            self.stack[index + 1],
            self.stack[index + 2],
            if optional {
              self.stack[index + 4]
            } else {
              zero
            },
            self.stack[index + 3],
          )
        } else {
          self.geometry.cubic_relative_unchecked(
            zero,
            self.stack[index],
            self.stack[index + 1],
            self.stack[index + 2],
            self.stack[index + 3],
            if optional {
              self.stack[index + 4]
            } else {
              zero
            },
          )
        }
        match result {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        index = index + (if optional { 5 } else { 4 })
        horizontal = !horizontal
      }
    }
    _ => return Err(type2_data_error("font-cff-type2-operator"))
  }
  self.geometry_started = true
  self.geometry_operators = self.geometry_operators + 1UL
  self.clear_stack()
  Ok(())
}

///|
fn Type2Vm::execute_endchar(self : Type2Vm) -> Result[Unit, @error.CoreError] {
  if !self.width_resolved {
    if self.stack.length() == 4 || self.stack.length() == 5 {
      return Err(type2_capability_error("font-cff-type2-seac"))
    }
    let has_width = self.stack.length() == 1
    match self.resolve_width(has_width) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  if self.stack.length() == 4 {
    return Err(type2_capability_error("font-cff-type2-seac"))
  }
  if self.stack.length() != 0 {
    return Err(type2_data_error("font-cff-type2-endchar-arity"))
  }
  match self.geometry.close() {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok(())
}

///|
fn type2_subr_bias(count : UInt64) -> UInt64 {
  if count < 1240UL {
    107UL
  } else if count < 33900UL {
    1131UL
  } else {
    32768UL
  }
}

///|
fn Type2Vm::execute_mask(
  self : Type2Vm,
  frame : Type2Frame,
) -> Result[Unit, @error.CoreError] {
  if self.geometry_started {
    return Err(type2_data_error("font-cff-type2-hint-order"))
  }
  let has_width = !self.width_resolved && self.stack.length() % 2 == 1
  match self.resolve_width(has_width) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if self.stack.length() % 2 != 0 {
    return Err(type2_data_error("font-cff-type2-stem-arity"))
  }
  let additional = (self.stack.length() / 2).to_uint64()
  let requested_stems = match @checked.checked_add(self.stems, additional) {
    Err(_) =>
      return Err(
        type2_resource_error(
          "font-cff-type2-stems",
          self.stems,
          self.limits.max_stems,
        ),
      )
    Ok(value) => value
  }
  if requested_stems > self.limits.max_stems {
    return Err(
      type2_resource_error(
        "font-cff-type2-stems",
        requested_stems,
        self.limits.max_stems,
      ),
    )
  }
  if requested_stems == 0UL {
    return Err(type2_data_error("font-cff-type2-mask-without-stems"))
  }
  let mask_bytes = (requested_stems + 7UL) / 8UL
  match self.charge_bytes(mask_bytes) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let terminal = match @checked.checked_add(frame.cursor, mask_bytes) {
    Err(_) => return Err(type2_data_error("font-cff-type2-mask-truncated"))
    Ok(value) => value
  }
  if terminal > frame.source.length() {
    return Err(type2_data_error("font-cff-type2-mask-truncated"))
  }
  self.stems = requested_stems
  self.clear_stack()
  frame.cursor = terminal
  self.ledger.mask_bytes = self.ledger.mask_bytes + mask_bytes
  Ok(())
}

///|
fn Type2Vm::execute_call(
  self : Type2Vm,
  caller : Type2Frame,
  global : Bool,
) -> Result[Unit, @error.CoreError] {
  match self.require_stack(1) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let top = self.stack.length() - 1
  let operand = match
    type2_fixed_exact_int(self.stack[top], "font-cff-type2-subr-index") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let index = if global { self.global_subrs } else { self.local_subrs }
  let biased = operand + type2_subr_bias(index.count).to_int()
  let context = if global {
    "font-cff-type2-global-subr-index"
  } else {
    "font-cff-type2-local-subr-index"
  }
  if biased < 0 || biased.to_uint64() >= index.count {
    return Err(type2_data_error(context))
  }
  let requested_depth = self.frames.length().to_uint64() + 1UL
  if requested_depth > self.limits.max_frames {
    return Err(
      type2_resource_error(
        "font-cff-type2-frame-depth",
        requested_depth,
        self.limits.max_frames,
      ),
    )
  }
  let requested_calls = match
    type2_checked_counter_add(
      self.ledger.calls,
      1UL,
      self.limits.max_calls,
      "font-cff-type2-calls",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  // Calls carry a named work unit in addition to operator dispatch.
  match self.charge_work(1UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let object = match cff_index_object(index, biased.to_uint64(), context) {
    Err(_) => return Err(type2_data_error(context))
    Ok(value) => value
  }
  ignore(self.stack.pop())
  self.ledger.calls = requested_calls
  let tail_call = caller.cursor == caller.source.length()
  self.frames.push(caller)
  self.frames.push({
    kind: if global {
      Global
    } else {
      Local
    },
    source: object.view,
    cursor: 0UL,
    tail_call,
  })
  Ok(())
}

///|
fn Type2Vm::execute_return(
  self : Type2Vm,
  frame : Type2Frame,
) -> Result[Unit, @error.CoreError] {
  match frame.kind {
    Root => return Err(type2_data_error("font-cff-type2-root-return"))
    Local | Global => ()
  }
  if frame.cursor != frame.source.length() {
    return Err(type2_data_error("font-cff-type2-subr-trailing-bytes"))
  }
  match self.charge_work(1UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  self.ledger.returns = self.ledger.returns + 1UL
  Ok(())
}

///|
fn Type2Vm::validate_endchar_frame(
  self : Type2Vm,
  frame : Type2Frame,
) -> Result[Unit, @error.CoreError] {
  if frame.cursor != frame.source.length() {
    return Err(type2_data_error("font-cff-type2-trailing-bytes"))
  }
  match frame.kind {
    Root => Ok(())
    Local | Global => {
      if !frame.tail_call {
        return Err(type2_data_error("font-cff-type2-non-tail-endchar"))
      }
      for caller in self.frames {
        if !caller.tail_call || caller.cursor != caller.source.length() {
          return Err(type2_data_error("font-cff-type2-non-tail-endchar"))
        }
      }
      Ok(())
    }
  }
}

///|
fn type2_error_with_revision(
  root : @bytes.ByteView,
  opening_revision : UInt64,
  error : @error.CoreError,
) -> @error.CoreError {
  match type2_require_revision(root, opening_revision) {
    Err(state) => state
    Ok(_) => error
  }
}

///|
fn type2_number_encoded_width(first : UInt64) -> UInt64 {
  if first == 28UL {
    3UL
  } else if first == 255UL {
    5UL
  } else if first >= 247UL && first <= 254UL {
    2UL
  } else {
    1UL
  }
}

///|
fn Type2Vm::new(
  root : @bytes.ByteView,
  local_subrs : CffIndex,
  global_subrs : CffIndex,
  default_width : Type2Fixed,
  nominal_width : Type2Fixed,
  seed : Type2Fixed,
  matrix : Type2Matrix,
  limits : Type2Limits,
  path_sink? : Type2PathSink? = None,
  work_authority? : Type2WorkAuthority? = None,
) -> Type2Vm {
  let stack : Array[Type2Fixed] = Array::new(
    capacity=limits.max_operand_stack.to_int(),
  )
  let frames : Array[Type2Frame] = Array::new(
    capacity=limits.frame_capacity,
  )
  frames.push({ kind: Root, source: root, cursor: 0UL, tail_call: true })
  {
    stack,
    transient: Array::make(limits.max_transient.to_int(), { raw: 0L }),
    transient_initialized: Array::make(limits.max_transient.to_int(), false),
    frames,
    local_subrs,
    global_subrs,
    default_width,
    nominal_width,
    width: None,
    width_resolved: false,
    stems: 0UL,
    geometry_started: false,
    geometry_operators: 0UL,
    geometry: Type2BoundsSink::new_with_path(
      matrix,
      limits,
      path_sink,
      work_authority~,
    ),
    prng: Type2Prng::new(seed),
    limits,
    ledger: {
      executed_bytes: 0UL,
      work: 0UL,
      calls: 0UL,
      returns: 0UL,
      operators: 0UL,
      numbers: 0UL,
      mask_bytes: 0UL,
    },
    work_authority,
  }
}

///|
fn type2_execute_program(
  root : @bytes.ByteView,
  local_subrs : CffIndex,
  global_subrs : CffIndex,
  default_width : Type2Fixed,
  nominal_width : Type2Fixed,
  seed : Type2Fixed,
  limits : Type2Limits,
  opening_revision : UInt64,
) -> Result[Type2VmResult, @error.CoreError] {
  type2_execute_program_with_matrix(
    root,
    local_subrs,
    global_subrs,
    default_width,
    nominal_width,
    seed,
    type2_identity_matrix(),
    limits,
    opening_revision,
  )
}

///|
fn type2_execute_program_with_matrix(
  root : @bytes.ByteView,
  local_subrs : CffIndex,
  global_subrs : CffIndex,
  default_width : Type2Fixed,
  nominal_width : Type2Fixed,
  seed : Type2Fixed,
  matrix : Type2Matrix,
  limits : Type2Limits,
  opening_revision : UInt64,
) -> Result[Type2VmResult, @error.CoreError] {
  type2_execute_program_with_matrix_and_read_probe(
    root,
    local_subrs,
    global_subrs,
    default_width,
    nominal_width,
    seed,
    matrix,
    limits,
    opening_revision,
    true,
    fn() { () },
  )
}

///|
fn type2_execute_program_with_matrix_unretained(
  root : @bytes.ByteView,
  local_subrs : CffIndex,
  global_subrs : CffIndex,
  default_width : Type2Fixed,
  nominal_width : Type2Fixed,
  seed : Type2Fixed,
  matrix : Type2Matrix,
  limits : Type2Limits,
  opening_revision : UInt64,
  read_probe? : () -> Unit = fn() { () },
  work_authority? : Type2WorkAuthority? = None,
) -> Result[Type2VmResult, @error.CoreError] {
  type2_execute_program_with_matrix_and_read_probe(
    root,
    local_subrs,
    global_subrs,
    default_width,
    nominal_width,
    seed,
    matrix,
    limits,
    opening_revision,
    false,
    read_probe,
    work_authority~,
  )
}

///|
fn type2_execute_program_with_matrix_and_read_probe(
  root : @bytes.ByteView,
  local_subrs : CffIndex,
  global_subrs : CffIndex,
  default_width : Type2Fixed,
  nominal_width : Type2Fixed,
  seed : Type2Fixed,
  matrix : Type2Matrix,
  limits : Type2Limits,
  opening_revision : UInt64,
  retain_bounds : Bool,
  read_probe : () -> Unit,
  path_sink? : Type2PathSink? = None,
  work_authority? : Type2WorkAuthority? = None,
) -> Result[Type2VmResult, @error.CoreError] {
  match type2_require_revision(root, opening_revision) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let vm = Type2Vm::new(
    root,
    local_subrs,
    global_subrs,
    default_width,
    nominal_width,
    seed,
    matrix,
    limits,
    path_sink~,
    work_authority~,
  )
  while vm.frames.length() > 0 {
    match type2_require_revision(root, opening_revision) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let frame = vm.frames.pop().unwrap()
    if frame.cursor >= frame.source.length() {
      return Err(
        type2_error_with_revision(
          root,
          opening_revision,
          type2_data_error("font-cff-type2-unexpected-eof"),
        ),
      )
    }
    let instruction_charge = match vm.preflight_instruction() {
      Err(error) =>
        return Err(type2_error_with_revision(root, opening_revision, error))
      Ok(value) => value
    }
    read_probe()
    let operator_offset = frame.cursor
    let first = match frame.source.get(operator_offset) {
      Err(_) =>
        return Err(
          type2_error_with_revision(
            root,
            opening_revision,
            type2_data_error("font-cff-type2-byte"),
          ),
        )
      Ok(value) => value.to_uint64()
    }
    vm.accept_preflighted_instruction(instruction_charge)
    let result : Result[Type2Step, @error.CoreError] = {
            frame.cursor = frame.cursor + 1UL
            if first == 28UL ||
              first == 255UL ||
              (first >= 32UL && first <= 254UL) {
              let width = type2_number_encoded_width(first)
              if width > 1UL {
                match vm.charge_bytes(width - 1UL) {
                  Err(error) => Err(error)
                  Ok(_) => {
                    let decoded = match
                      type2_decode_number(frame.source, operator_offset) {
                      Err(error) =>
                        return Err(
                          type2_error_with_revision(
                            root,
                            opening_revision,
                            error,
                          ),
                        )
                      Ok(value) => value
                    }
                    match vm.push(decoded.0) {
                      Err(error) => Err(error)
                      Ok(_) => {
                        frame.cursor = decoded.1
                        vm.ledger.numbers = vm.ledger.numbers + 1UL
                        Ok(Continue(frame))
                      }
                    }
                  }
                }
              } else {
                let decoded = match
                  type2_decode_number(frame.source, operator_offset) {
                  Err(error) =>
                    return Err(
                      type2_error_with_revision(
                        root,
                        opening_revision,
                        error,
                      ),
                    )
                  Ok(value) => value
                }
                match vm.push(decoded.0) {
                  Err(error) => Err(error)
                  Ok(_) => {
                    frame.cursor = decoded.1
                    vm.ledger.numbers = vm.ledger.numbers + 1UL
                    Ok(Continue(frame))
                  }
                }
              }
            } else {
              vm.ledger.operators = vm.ledger.operators + 1UL
              if first == 10UL || first == 29UL {
                match vm.execute_call(frame, first == 29UL) {
                  Err(error) => Err(error)
                  Ok(_) => Ok(FramesManaged)
                }
              } else if first == 11UL {
                match vm.execute_return(frame) {
                  Err(error) => Err(error)
                  Ok(_) => Ok(FramesManaged)
                }
              } else {
                let operator_result = if first == 12UL {
                  match vm.charge_bytes(1UL) {
                    Err(error) => Err(error)
                    Ok(_) => {
                      let escaped = match frame.source.get(frame.cursor) {
                        Err(_) =>
                          return Err(
                            type2_error_with_revision(
                              root,
                              opening_revision,
                              type2_data_error(
                                "font-cff-type2-escape-truncated",
                              ),
                            ),
                          )
                        Ok(value) => value.to_uint64()
                      }
                      frame.cursor = frame.cursor + 1UL
                      vm.execute_escaped(escaped)
                    }
                  }
                } else {
                  match first {
                    1UL | 3UL | 18UL | 23UL => vm.execute_stem()
                    19UL | 20UL => vm.execute_mask(frame)
                    4UL | 21UL | 22UL => vm.execute_moveto(first)
                    5UL
                    | 6UL
                    | 7UL
                    | 8UL
                    | 24UL
                    | 25UL
                    | 26UL
                    | 27UL
                    | 30UL
                    | 31UL => vm.execute_geometry(first)
                    14UL => vm.execute_endchar()
                    15UL | 16UL =>
                      Err(
                        type2_capability_error("font-cff-type2-cff2-operator"),
                      )
                    _ =>
                      Err(type2_data_error("font-cff-type2-reserved-operator"))
                  }
                }
                match operator_result {
                  Err(error) => Err(error)
                  Ok(_) =>
                    if first == 14UL {
                      match vm.validate_endchar_frame(frame) {
                        Err(error) => Err(error)
                        Ok(_) => Ok(Terminate)
                      }
                    } else {
                      Ok(Continue(frame))
                    }
                }
              }
            }
    }
    match result {
      Err(error) =>
        return Err(type2_error_with_revision(root, opening_revision, error))
      Ok(Terminate) =>
        match type2_require_revision(root, opening_revision) {
          Err(error) => return Err(error)
          Ok(_) => {
            let geometry = match vm.geometry.facts(retain_bounds) {
              Err(error) =>
                return Err(
                  type2_error_with_revision(root, opening_revision, error),
                )
              Ok(value) => value
            }
            return Ok({
              width: vm.width,
              stems: vm.stems,
              terminated: true,
              ledger: vm.ledger,
              geometry_operators: vm.geometry_operators,
              geometry,
            })
          }
        }
      Ok(Continue(next)) => vm.frames.push(next)
      Ok(FramesManaged) => ()
    }
  }
  Err(
    type2_error_with_revision(
      root,
      opening_revision,
      type2_data_error("font-cff-type2-unexpected-eof"),
    ),
  )
}

///|
fn type2_execute_glyph(
  descriptor : CffGlyphDescriptor,
  global_subrs : CffIndex,
  units_per_em : UInt64,
  limits : Type2Limits,
  opening_revision : UInt64,
  read_probe? : () -> Unit = fn() { () },
  work_authority? : Type2WorkAuthority? = None,
) -> Result[Type2VmResult, @error.CoreError] {
  type2_execute_glyph_with_path_capacity(
    descriptor,
    global_subrs,
    units_per_em,
    limits,
    opening_revision,
    None,
    read_probe~,
    work_authority~,
  )
}

///|
fn type2_execute_glyph_with_path_capacity(
  descriptor : CffGlyphDescriptor,
  global_subrs : CffIndex,
  units_per_em : UInt64,
  limits : Type2Limits,
  opening_revision : UInt64,
  path_capacity : Int?,
  read_probe? : () -> Unit = fn() { () },
  work_authority? : Type2WorkAuthority? = None,
) -> Result[Type2VmResult, @error.CoreError] {
  let default_width = match
    cff_number_to_type2_fixed(
      descriptor.environment.private_dict.default_width_x,
      "font-cff-type2-default-width",
    ) {
    Err(_) => return Err(type2_data_error("font-cff-type2-default-width"))
    Ok(value) => value
  }
  let nominal_width = match
    cff_number_to_type2_fixed(
      descriptor.environment.private_dict.nominal_width_x,
      "font-cff-type2-nominal-width",
    ) {
    Err(_) => return Err(type2_data_error("font-cff-type2-nominal-width"))
    Ok(value) => value
  }
  let matrix = match
    type2_matrix_compose(
      descriptor.environment.top_font_matrix,
      descriptor.environment.fd_font_matrix,
      units_per_em,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match path_capacity {
    None =>
      type2_execute_program_with_matrix_unretained(
        descriptor.charstring.view,
        descriptor.environment.local_subrs,
        global_subrs,
        default_width,
        nominal_width,
        descriptor.environment.private_dict.initial_random_seed,
        matrix,
        limits,
        opening_revision,
        read_probe~,
        work_authority~,
      )
    Some(capacity) =>
      match Type2PathSink::new(capacity, matrix) {
        Err(error) => Err(error)
        Ok(path_sink) =>
          type2_execute_program_with_matrix_and_read_probe(
            descriptor.charstring.view,
            descriptor.environment.local_subrs,
            global_subrs,
            default_width,
            nominal_width,
            descriptor.environment.private_dict.initial_random_seed,
            matrix,
            limits,
            opening_revision,
            false,
            read_probe,
            path_sink=Some(path_sink),
            work_authority~,
          )
      }
  }
}

///|
fn type2_stage_checked_add(
  current : UInt64,
  amount : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  type2_checked_counter_add(current, amount, 18446744073709551615UL, context)
}

///|
fn type2_stage_error_with_revision(
  authority : @bytes.ByteView,
  opening_revision : UInt64,
  error : @error.CoreError,
) -> @error.CoreError {
  match type2_require_revision(authority, opening_revision) {
    Err(state) => state
    Ok(_) => error
  }
}

///|
#warnings("-1")
fn type2_stage_all_glyphs_unchecked_with_probe(
  descriptors : Array[CffGlyphDescriptor],
  global_subrs : CffIndex,
  units_per_em : UInt64,
  limits : Type2Limits,
  budget : @budget.Budget,
  authority : @bytes.ByteView,
  opening_revision : UInt64,
  visit_probe : (UInt64) -> Unit,
  read_probe? : () -> Unit = fn() { () },
  prior_work? : UInt64 = 0UL,
) -> Result[Type2AllGlyphResult, @error.CoreError] {
  match type2_require_revision(authority, opening_revision) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let bounds_slots = descriptors.length().to_uint64()
  let bounds_bytes = match @checked.checked_mul(bounds_slots, 24UL) {
    Err(_) =>
      return Err(
        type2_stage_error_with_revision(
          authority,
          opening_revision,
          type2_resource_error(
            "font-cff-type2-bounds-bytes",
            bounds_slots,
            18446744073709551615UL,
          ),
        ),
      )
    Ok(value) => value
  }
  let path_count_bytes = match @checked.checked_mul(bounds_slots, 8UL) {
    Err(_) =>
      return Err(
        type2_stage_error_with_revision(
          authority,
          opening_revision,
          type2_resource_error(
            "font-cff-type2-path-count-bytes",
            bounds_slots,
            18446744073709551615UL,
          ),
        ),
      )
    Ok(value) => value
  }
  let path_work_bytes = match @checked.checked_mul(bounds_slots, 8UL) {
    Err(_) =>
      return Err(
        type2_stage_error_with_revision(
          authority,
          opening_revision,
          type2_resource_error(
            "font-cff-type2-path-work-bytes",
            bounds_slots,
            18446744073709551615UL,
          ),
        ),
      )
    Ok(value) => value
  }
  let bytes = match
    @checked.checked_add(
      bounds_bytes,
      match @checked.checked_add(path_count_bytes, path_work_bytes) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let scratch_allocations = match
    @checked.checked_mul(bounds_slots, limits.scratch_allocations) {
    Err(_) =>
      return Err(
        type2_stage_error_with_revision(
          authority,
          opening_revision,
          type2_resource_error(
            "font-cff-type2-allocations",
            bounds_slots,
            18446744073709551615UL,
          ),
        ),
      )
    Ok(value) => value
  }
  let base_allocations = match
    @checked.checked_add(
      scratch_allocations,
      if bounds_slots == 0UL { 0UL } else { 3UL },
    ) {
    Err(_) =>
      return Err(
        type2_stage_error_with_revision(
          authority,
          opening_revision,
          type2_resource_error(
            "font-cff-type2-allocations",
            scratch_allocations,
            18446744073709551615UL,
          ),
        ),
      )
    Ok(value) => value
  }
  let path_allocation_size = if path_count_bytes > path_work_bytes {
    path_count_bytes
  } else {
    path_work_bytes
  }
  let retained_allocation_size = if bounds_bytes > path_allocation_size {
    bounds_bytes
  } else {
    path_allocation_size
  }
  let allocation_size = if retained_allocation_size >
    limits.scratch_allocation_size {
    retained_allocation_size
  } else {
    limits.scratch_allocation_size
  }
  // Preflight every fixed-capacity scratch array and the preallocated outer
  // retained-bounds array before constructing either. Individual non-empty
  // GlyphBoundsFacts objects are preflighted cumulatively below, immediately
  // before their allocation.
  let fixed_authority = @budget.ResourceCharge::new(
    bytes~,
    allocations=base_allocations,
    allocation_size~,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work=0UL,
  )
  match budget.preflight(fixed_authority) {
    Err(error) =>
      return Err(
        type2_stage_error_with_revision(authority, opening_revision, error),
      )
    Ok(_) => ()
  }
  let deferred_work = Type2WorkAuthority::new(
    budget,
    prior_work,
    limits.max_work,
    "font-cff-type2-aggregate-work",
  )

  let bounds : Array[GlyphBoundsFacts?] = Array::new(
    capacity=descriptors.length(),
  )
  let path_command_counts : Array[UInt64] = Array::new(
    capacity=descriptors.length(),
  )
  let path_work : Array[UInt64] = Array::new(
    capacity=descriptors.length(),
  )
  let mut allocations = base_allocations
  let mut executed_bytes = 0UL
  let mut work = 0UL
  let mut calls = 0UL
  let mut returns = 0UL
  let mut operators = 0UL
  let mut numbers = 0UL
  let mut mask_bytes = 0UL
  let mut geometry_operators = 0UL
  let mut points = 0UL
  let mut contours = 0UL
  let mut commands = 0UL
  for index = 0; index < descriptors.length(); index = index + 1 {
    match type2_require_revision(authority, opening_revision) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let descriptor = descriptors[index]
    let expected_gid = index.to_uint64()
    if descriptor.gid != expected_gid {
      return Err(
        type2_stage_error_with_revision(
          authority,
          opening_revision,
          type2_data_error("font-cff-type2-gid-order"),
        ),
      )
    }
    match deferred_work.preflight_additional(1UL) {
      Err(error) =>
        return Err(
          type2_stage_error_with_revision(authority, opening_revision, error),
        )
      Ok(_) => ()
    }
    visit_probe(descriptor.gid)
    let result = match
      type2_execute_glyph(
        descriptor,
        global_subrs,
        units_per_em,
        limits,
        opening_revision,
        read_probe~,
        work_authority=Some(deferred_work),
      ) {
      Err(error) =>
        return Err(
          type2_stage_error_with_revision(authority, opening_revision, error),
        )
      Ok(value) => value
    }
    executed_bytes = match
      type2_stage_checked_add(
        executed_bytes,
        result.ledger.executed_bytes,
        "font-cff-type2-aggregate-executed-bytes",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    calls = match
      type2_stage_checked_add(
        calls,
        result.ledger.calls,
        "font-cff-type2-aggregate-calls",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    returns = match
      type2_stage_checked_add(
        returns,
        result.ledger.returns,
        "font-cff-type2-aggregate-returns",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    operators = match
      type2_stage_checked_add(
        operators,
        result.ledger.operators,
        "font-cff-type2-aggregate-operators",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    numbers = match
      type2_stage_checked_add(
        numbers,
        result.ledger.numbers,
        "font-cff-type2-aggregate-numbers",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    mask_bytes = match
      type2_stage_checked_add(
        mask_bytes,
        result.ledger.mask_bytes,
        "font-cff-type2-aggregate-mask-bytes",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    geometry_operators = match
      type2_stage_checked_add(
        geometry_operators,
        result.geometry_operators,
        "font-cff-type2-aggregate-geometry-operators",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    points = match
      type2_stage_checked_add(
        points,
        result.geometry.points,
        "font-cff-type2-aggregate-points",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    contours = match
      type2_stage_checked_add(
        contours,
        result.geometry.contours,
        "font-cff-type2-aggregate-contours",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    commands = match
      type2_stage_checked_add(
        commands,
        result.geometry.commands,
        "font-cff-type2-aggregate-commands",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    path_command_counts.push(result.geometry.path_commands)
    let geometry_work = match
      type2_stage_checked_add(
        result.geometry.points,
        result.geometry.commands,
        "font-cff-type2-geometry-work",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let glyph_work = match
      type2_stage_checked_add(
        result.ledger.work,
        geometry_work,
        "font-cff-type2-glyph-work",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let path_geometry_work = match
      type2_stage_checked_add(
        result.geometry.points,
        result.geometry.path_commands,
        "font-cff-type2-path-work",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let outline_work = match
      type2_stage_checked_add(
        result.ledger.work,
        path_geometry_work,
        "font-cff-type2-path-work",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    path_work.push(outline_work)
    work = match
      type2_checked_counter_add(
        work,
        glyph_work,
        limits.max_work,
        "font-cff-type2-aggregate-work",
      ) {
      Err(error) =>
        return Err(
          type2_stage_error_with_revision(authority, opening_revision, error),
        )
      Ok(value) => value
    }
    if result.geometry.has_segments {
      let next_allocations = match
        type2_stage_checked_add(
          allocations,
          1UL,
          "font-cff-type2-allocations",
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let retained_bound_authority = @budget.ResourceCharge::new(
        bytes~,
        allocations=next_allocations,
        allocation_size~,
        width=0UL,
        height=0UL,
        pixels=0UL,
        work=0UL,
      )
      match budget.preflight(retained_bound_authority) {
        Err(error) =>
          return Err(
            type2_stage_error_with_revision(authority, opening_revision, error),
          )
        Ok(_) => ()
      }
      allocations = next_allocations
      bounds.push(
        Some({
          x_min: result.geometry.bound_x_min,
          y_min: result.geometry.bound_y_min,
          x_max: result.geometry.bound_x_max,
          y_max: result.geometry.bound_y_max,
        }),
      )
    } else {
      bounds.push(None)
    }
  }
  match type2_require_revision(authority, opening_revision) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let resource = @budget.ResourceCharge::new(
    bytes~,
    allocations~,
    allocation_size~,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work~,
  )
  match budget.preflight(resource) {
    Err(error) =>
      return Err(
        type2_stage_error_with_revision(authority, opening_revision, error),
      )
    Ok(_) => ()
  }
  match type2_require_revision(authority, opening_revision) {
    Err(error) => return Err(error)
    Ok(_) =>
      Ok({
        bounds,
        path_command_counts,
        path_work,
        charge: {
          resource,
          bytes,
          allocations,
          allocation_size,
          work,
          bounds_slots,
          executed_bytes,
          calls,
          returns,
          operators,
          numbers,
          mask_bytes,
          geometry_operators,
          points,
          contours,
          commands,
        },
      })
  }
}

///|
fn type2_stage_all_glyphs_with_probe(
  descriptors : Array[CffGlyphDescriptor],
  global_subrs : CffIndex,
  units_per_em : UInt64,
  limits : Type2Limits,
  budget : @budget.Budget,
  authority : @bytes.ByteView,
  opening_revision : UInt64,
  visit_probe : (UInt64) -> Unit,
  read_probe? : () -> Unit = fn() { () },
  prior_work? : UInt64 = 0UL,
) -> Result[Type2AllGlyphResult, @error.CoreError] {
  match
    type2_stage_all_glyphs_unchecked_with_probe(
      descriptors,
      global_subrs,
      units_per_em,
      limits,
      budget,
      authority,
      opening_revision,
      visit_probe,
      read_probe~,
      prior_work~,
    ) {
    Err(error) =>
      Err(type2_stage_error_with_revision(authority, opening_revision, error))
    Ok(value) => Ok(value)
  }
}

///|
fn type2_stage_all_glyphs(
  descriptors : Array[CffGlyphDescriptor],
  global_subrs : CffIndex,
  units_per_em : UInt64,
  limits : Type2Limits,
  budget : @budget.Budget,
  authority : @bytes.ByteView,
  opening_revision : UInt64,
) -> Result[Type2AllGlyphResult, @error.CoreError] {
  type2_stage_all_glyphs_with_probe(
    descriptors,
    global_subrs,
    units_per_em,
    limits,
    budget,
    authority,
    opening_revision,
    fn(_) { () },
  )
}
