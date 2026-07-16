///|
/// The complete portable resource limit set. Consumable limits are bytes,
/// allocation count, pixels, and work. Allocation size and dimensions are
/// per-operation ceilings; depth is a balanced shared nesting ceiling.
pub struct ResourceLimits {
  priv bytes_value : UInt64
  priv allocations_value : UInt64
  priv allocation_size_value : UInt64
  priv width_value : UInt64
  priv height_value : UInt64
  priv pixels_value : UInt64
  priv depth_value : UInt64
  priv work_value : UInt64
}

///|
pub fn ResourceLimits::new(
  bytes~ : UInt64,
  allocations~ : UInt64,
  allocation_size~ : UInt64,
  width~ : UInt64,
  height~ : UInt64,
  pixels~ : UInt64,
  depth~ : UInt64,
  work~ : UInt64,
) -> ResourceLimits {
  {
    bytes_value: bytes,
    allocations_value: allocations,
    allocation_size_value: allocation_size,
    width_value: width,
    height_value: height,
    pixels_value: pixels,
    depth_value: depth,
    work_value: work,
  }
}

///|
pub fn ResourceLimits::bytes(self : ResourceLimits) -> UInt64 {
  self.bytes_value
}

///|
pub fn ResourceLimits::allocations(self : ResourceLimits) -> UInt64 {
  self.allocations_value
}

///|
pub fn ResourceLimits::allocation_size(self : ResourceLimits) -> UInt64 {
  self.allocation_size_value
}

///|
pub fn ResourceLimits::width(self : ResourceLimits) -> UInt64 {
  self.width_value
}

///|
pub fn ResourceLimits::height(self : ResourceLimits) -> UInt64 {
  self.height_value
}

///|
pub fn ResourceLimits::pixels(self : ResourceLimits) -> UInt64 {
  self.pixels_value
}

///|
pub fn ResourceLimits::depth(self : ResourceLimits) -> UInt64 {
  self.depth_value
}

///|
pub fn ResourceLimits::work(self : ResourceLimits) -> UInt64 {
  self.work_value
}

///|
/// A complete pre-work charge. All fields are validated before any consumable
/// counter changes.
pub struct ResourceCharge {
  priv bytes_value : UInt64
  priv allocations_value : UInt64
  priv allocation_size_value : UInt64
  priv width_value : UInt64
  priv height_value : UInt64
  priv pixels_value : UInt64
  priv work_value : UInt64
}

///|
pub fn ResourceCharge::new(
  bytes~ : UInt64,
  allocations~ : UInt64,
  allocation_size~ : UInt64,
  width~ : UInt64,
  height~ : UInt64,
  pixels~ : UInt64,
  work~ : UInt64,
) -> ResourceCharge {
  {
    bytes_value: bytes,
    allocations_value: allocations,
    allocation_size_value: allocation_size,
    width_value: width,
    height_value: height,
    pixels_value: pixels,
    work_value: work,
  }
}

///|
pub fn ResourceCharge::none() -> ResourceCharge {
  ResourceCharge::new(
    bytes=0UL,
    allocations=0UL,
    allocation_size=0UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work=0UL,
  )
}

///|
pub fn ResourceCharge::bytes(bytes : UInt64) -> ResourceCharge {
  ResourceCharge::new(
    bytes~,
    allocations=0UL,
    allocation_size=0UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work=0UL,
  )
}

///|
struct BudgetWindow {
  mut bytes_remaining : UInt64
  mut allocations_remaining : UInt64
  allocation_size_limit : UInt64
  width_limit : UInt64
  height_limit : UInt64
  mut pixels_remaining : UInt64
  depth_limit : UInt64
  mut depth_used : UInt64
  mut work_remaining : UInt64
}

///|
fn BudgetWindow::new(limits : ResourceLimits) -> BudgetWindow {
  {
    bytes_remaining: limits.bytes_value,
    allocations_remaining: limits.allocations_value,
    allocation_size_limit: limits.allocation_size_value,
    width_limit: limits.width_value,
    height_limit: limits.height_value,
    pixels_remaining: limits.pixels_value,
    depth_limit: limits.depth_value,
    depth_used: 0UL,
    work_remaining: limits.work_value,
  }
}

///|
fn budget_exceeded(
  operation : String,
  dimension : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation~,
    requested~,
    limit~,
    context=dimension,
  )
}

///|
fn BudgetWindow::preflight_charge(
  self : BudgetWindow,
  charge : ResourceCharge,
) -> Result[Unit, @error.CoreError] {
  if @checked.checked_sub(self.bytes_remaining, charge.bytes_value) is Err(_) {
    return Err(
      budget_exceeded(
        "budget_charge",
        "bytes",
        charge.bytes_value,
        self.bytes_remaining,
      ),
    )
  }
  if @checked.checked_sub(self.allocations_remaining, charge.allocations_value)
    is Err(_) {
    return Err(
      budget_exceeded(
        "budget_charge",
        "allocations",
        charge.allocations_value,
        self.allocations_remaining,
      ),
    )
  }
  if charge.allocation_size_value > self.allocation_size_limit {
    return Err(
      budget_exceeded(
        "budget_charge",
        "allocation_size",
        charge.allocation_size_value,
        self.allocation_size_limit,
      ),
    )
  }
  if charge.width_value > self.width_limit {
    return Err(
      budget_exceeded(
        "budget_charge",
        "width",
        charge.width_value,
        self.width_limit,
      ),
    )
  }
  if charge.height_value > self.height_limit {
    return Err(
      budget_exceeded(
        "budget_charge",
        "height",
        charge.height_value,
        self.height_limit,
      ),
    )
  }
  if @checked.checked_sub(self.pixels_remaining, charge.pixels_value) is Err(_) {
    return Err(
      budget_exceeded(
        "budget_charge",
        "pixels",
        charge.pixels_value,
        self.pixels_remaining,
      ),
    )
  }
  if @checked.checked_sub(self.work_remaining, charge.work_value) is Err(_) {
    return Err(
      budget_exceeded(
        "budget_charge",
        "work",
        charge.work_value,
        self.work_remaining,
      ),
    )
  }
  Ok(())
}

///|
fn BudgetWindow::commit_charge(
  self : BudgetWindow,
  charge : ResourceCharge,
) -> Unit {
  self.bytes_remaining = self.bytes_remaining - charge.bytes_value
  self.allocations_remaining = self.allocations_remaining -
    charge.allocations_value
  self.pixels_remaining = self.pixels_remaining - charge.pixels_value
  self.work_remaining = self.work_remaining - charge.work_value
}

///|
/// An opaque hierarchical handle. Every window in the chain is shared by
/// reference, so descendants consume both their narrowed allowance and every
/// ancestor allowance.
pub struct Budget {
  priv windows : Array[BudgetWindow]
}

///|
pub fn Budget::new(limits : ResourceLimits) -> Budget {
  { windows: [BudgetWindow::new(limits)] }
}

///|
fn Budget::current_window(self : Budget) -> BudgetWindow {
  self.windows[self.windows.length() - 1]
}

///|
pub fn Budget::remaining(self : Budget) -> ResourceLimits {
  let window = self.current_window()
  ResourceLimits::new(
    bytes=window.bytes_remaining,
    allocations=window.allocations_remaining,
    allocation_size=window.allocation_size_limit,
    width=window.width_limit,
    height=window.height_limit,
    pixels=window.pixels_remaining,
    depth=window.depth_limit - window.depth_used,
    work=window.work_remaining,
  )
}

///|
pub fn Budget::current_depth(self : Budget) -> UInt64 {
  self.current_window().depth_used
}

///|
/// Preflight the full charge against every ancestor before committing any
/// counter in any window.
pub fn Budget::charge(
  self : Budget,
  charge : ResourceCharge,
) -> Result[Unit, @error.CoreError] {
  for window in self.windows {
    match window.preflight_charge(charge) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  for window in self.windows {
    window.commit_charge(charge)
  }
  Ok(())
}

///|
fn child_limit_error(
  requested : UInt64,
  limit : UInt64,
  dimension : String,
) -> Result[Budget, @error.CoreError] {
  Err(budget_exceeded("budget_child", dimension, requested, limit))
}

///|
/// Create a child that shares every ancestor window and adds one strictly
/// non-expanding local window.
pub fn Budget::child(
  self : Budget,
  limits : ResourceLimits,
) -> Result[Budget, @error.CoreError] {
  let parent = self.remaining()
  if limits.bytes_value > parent.bytes_value {
    return child_limit_error(limits.bytes_value, parent.bytes_value, "bytes")
  }
  if limits.allocations_value > parent.allocations_value {
    return child_limit_error(
      limits.allocations_value,
      parent.allocations_value,
      "allocations",
    )
  }
  if limits.allocation_size_value > parent.allocation_size_value {
    return child_limit_error(
      limits.allocation_size_value,
      parent.allocation_size_value,
      "allocation_size",
    )
  }
  if limits.width_value > parent.width_value {
    return child_limit_error(limits.width_value, parent.width_value, "width")
  }
  if limits.height_value > parent.height_value {
    return child_limit_error(limits.height_value, parent.height_value, "height")
  }
  if limits.pixels_value > parent.pixels_value {
    return child_limit_error(limits.pixels_value, parent.pixels_value, "pixels")
  }
  if limits.depth_value > parent.depth_value {
    return child_limit_error(limits.depth_value, parent.depth_value, "depth")
  }
  if limits.work_value > parent.work_value {
    return child_limit_error(limits.work_value, parent.work_value, "work")
  }
  let windows = self.windows.copy()
  windows.push(BudgetWindow::new(limits))
  Ok(Budget::{ windows, })
}

///|
/// A balanced, idempotently releasable depth lease.
pub struct BudgetScope {
  priv budget_value : Budget
  priv mut active : Bool
}

///|
pub fn BudgetScope::budget(self : BudgetScope) -> Budget {
  self.budget_value
}

///|
pub fn BudgetScope::leave(self : BudgetScope) -> Unit {
  if self.active {
    self.active = false
    for window in self.budget_value.windows {
      window.depth_used = window.depth_used - 1UL
    }
  }
}

///|
pub fn Budget::enter_depth(
  self : Budget,
) -> Result[BudgetScope, @error.CoreError] {
  for window in self.windows {
    if window.depth_used >= window.depth_limit {
      return Err(
        budget_exceeded(
          "budget_enter_depth",
          "depth",
          1UL,
          window.depth_limit - window.depth_used,
        ),
      )
    }
  }
  for window in self.windows {
    window.depth_used = window.depth_used + 1UL
  }
  Ok({ budget_value: self, active: true })
}

///|
/// Run a body inside one balanced depth level. `defer` releases the scope for
/// both successful and error results, including an early return from the body.
pub fn[T] with_depth(
  budget : Budget,
  body : (BudgetScope) -> Result[T, @error.CoreError],
) -> Result[T, @error.CoreError] {
  match budget.enter_depth() {
    Err(error) => Err(error)
    Ok(scope) => {
      defer scope.leave()
      body(scope)
    }
  }
}
