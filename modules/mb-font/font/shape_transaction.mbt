///|
/// Request-scoped read authority for one shaping continuation.
///
/// The representation and constructor are private. A scope may nominally
/// escape through the generic callback result, but every alias observes the
/// same active cell and becomes unusable when the callback exits.
pub struct FontShapeScope {
  priv font : Font
  priv mut active : Bool
  priv font_charge : @budget.ResourceCharge
}

///|
priv struct FontShapeTransactionProbes {
  post_structure : () -> Unit
  post_capability : () -> Unit
  post_complete_staging : () -> Unit
  before_final_guard : () -> Unit
}

///|
fn font_shape_transaction_noop_probes() -> FontShapeTransactionProbes {
  FontShapeTransactionProbes::{
    post_structure: fn() { () },
    post_capability: fn() { () },
    post_complete_staging: fn() { () },
    before_final_guard: fn() { () },
  }
}

///|
fn font_shape_scope_closed_error() -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation="font-shape-scope",
    context="font-shape-scope-closed",
  )
}

///|
fn FontShapeScope::require_active(
  self : FontShapeScope,
) -> Result[Unit, @error.CoreError] {
  if !self.active {
    return Err(font_shape_scope_closed_error())
  }
  self.font.require_revision("font-shape-scope")
}

///|
fn FontShapeScope::close(self : FontShapeScope) -> Unit {
  self.active = false
}

///|
/// Read stable design-unit metadata while the request scope remains active.
pub fn FontShapeScope::units_per_em(
  self : FontShapeScope,
) -> Result[UInt64, @error.CoreError] {
  match self.require_active() {
    Err(error) => Err(error)
    Ok(_) => Ok(self.font.units_per_em_value)
  }
}

///|
/// Stage one request under retained-font authority and publish only after a
/// checked combined charge, complete hierarchy preflight, and final revision
/// guard.
pub fn[T] Font::with_shape_transaction(
  self : Font,
  budget : @budget.Budget,
  body : (FontShapeScope) -> Result[
    (T, @budget.ResourceCharge),
    @error.CoreError,
  ],
) -> Result[T, @error.CoreError] {
  self.with_shape_transaction_probes(
    budget,
    @budget.ResourceCharge::none(),
    font_shape_transaction_noop_probes(),
    body,
  )
}

///|
fn[T] Font::with_shape_transaction_probes(
  self : Font,
  budget : @budget.Budget,
  font_charge : @budget.ResourceCharge,
  probes : FontShapeTransactionProbes,
  body : (FontShapeScope) -> Result[
    (T, @budget.ResourceCharge),
    @error.CoreError,
  ],
) -> Result[T, @error.CoreError] {
  match self.require_revision("font-shape-transaction") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let scope = FontShapeScope::{ font: self, active: true, font_charge }
  defer scope.close()
  (probes.post_structure)()
  match self.require_revision("font-shape-transaction") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  (probes.post_capability)()
  match self.require_revision("font-shape-transaction") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let (value, text_charge) = match body(scope) {
    Err(error) => return Err(error)
    Ok(staged) => staged
  }
  (probes.post_complete_staging)()
  match self.require_revision("font-shape-transaction") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let combined = match scope.font_charge.checked_add(text_charge) {
    Err(error) => return Err(error)
    Ok(charge) => charge
  }
  match budget.preflight(combined) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  (probes.before_final_guard)()
  match self.require_revision("font-shape-transaction") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match budget.charge(combined) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok(value)
}
