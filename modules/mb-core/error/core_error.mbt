///|
/// Stable, backend-neutral failure category.
pub(all) enum ErrorCategory {
  InvalidInput
  Data
  State
  Resource
  Capability
  Host
} derive(Eq)

///|
/// Stable, backend-neutral failure code.
pub(all) enum ErrorCode {
  InvalidRange
  InvalidEncoding
  ArithmeticOverflow
  ArithmeticUnderflow
  InvalidAlignment
  InvalidOffset
  NarrowingFailed
  InvalidDimensions
  AllocationFailed
  BudgetExceeded
  UnexpectedEndOfStream
  NoProgress
  CapabilityUnavailable
  HostOperationFailed
} derive(Eq)

///|
/// A structured portable error. Its representation is private so callers use
/// typed accessors rather than depending on layout or rendered prose.
pub struct CoreError {
  priv category_value : ErrorCategory
  priv code_value : ErrorCode
  priv operation_value : String?
  priv requested_value : UInt64?
  priv completed_value : UInt64?
  priv range_start_value : UInt64?
  priv range_end_value : UInt64?
  priv source_offset_value : UInt64?
  priv limit_value : UInt64?
  priv context_value : String?
}

///|
/// Construct a portable error from typed context fields.
pub fn CoreError::new(
  category : ErrorCategory,
  code : ErrorCode,
  operation? : String,
  requested? : UInt64,
  completed? : UInt64,
  range_start? : UInt64,
  range_end? : UInt64,
  source_offset? : UInt64,
  limit? : UInt64,
  context? : String,
) -> CoreError {
  {
    category_value: category,
    code_value: code,
    operation_value: operation,
    requested_value: requested,
    completed_value: completed,
    range_start_value: range_start,
    range_end_value: range_end,
    source_offset_value: source_offset,
    limit_value: limit,
    context_value: context.map(bound_context),
  }
}

///|
/// Map a foreign host failure without publishing foreign exception text,
/// platform status numbers, paths, clocks, or other ambient details.
pub fn map_host_failure(
  operation : String,
  _foreign_detail : String,
) -> CoreError {
  CoreError::new(
    ErrorCategory::Host,
    ErrorCode::HostOperationFailed,
    operation=bound_context(operation),
  )
}

///|
pub fn CoreError::category(self : CoreError) -> ErrorCategory {
  self.category_value
}

///|
pub fn CoreError::code(self : CoreError) -> ErrorCode {
  self.code_value
}

///|
pub fn CoreError::operation(self : CoreError) -> String? {
  self.operation_value
}

///|
pub fn CoreError::requested(self : CoreError) -> UInt64? {
  self.requested_value
}

///|
pub fn CoreError::completed(self : CoreError) -> UInt64? {
  self.completed_value
}

///|
pub fn CoreError::range_start(self : CoreError) -> UInt64? {
  self.range_start_value
}

///|
pub fn CoreError::range_end(self : CoreError) -> UInt64? {
  self.range_end_value
}

///|
pub fn CoreError::source_offset(self : CoreError) -> UInt64? {
  self.source_offset_value
}

///|
pub fn CoreError::limit(self : CoreError) -> UInt64? {
  self.limit_value
}

///|
pub fn CoreError::context(self : CoreError) -> String? {
  self.context_value
}

///|
fn bound_context(value : String) -> String {
  if value.length() <= 96 {
    value
  } else {
    value[:96].to_owned()
  }
}

///|
fn escape_field(value : String) -> String {
  value
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\n", new="\\n")
  .replace_all(old="\r", new="\\r")
  .replace_all(old="\t", new="\\t")
  .replace_all(old="\"", new="\\\"")
  .replace_all(old="|", new="\\|")
  .replace_all(old="=", new="\\=")
}

///|
fn ErrorCategory::token(self : ErrorCategory) -> String {
  match self {
    InvalidInput => "invalid-input"
    Data => "data"
    State => "state"
    Resource => "resource"
    Capability => "capability"
    Host => "host"
  }
}

///|
fn ErrorCode::token(self : ErrorCode) -> String {
  match self {
    InvalidRange => "invalid-range"
    InvalidEncoding => "invalid-encoding"
    ArithmeticOverflow => "arithmetic-overflow"
    ArithmeticUnderflow => "arithmetic-underflow"
    InvalidAlignment => "invalid-alignment"
    InvalidOffset => "invalid-offset"
    NarrowingFailed => "narrowing-failed"
    InvalidDimensions => "invalid-dimensions"
    AllocationFailed => "allocation-failed"
    BudgetExceeded => "budget-exceeded"
    UnexpectedEndOfStream => "unexpected-end-of-stream"
    NoProgress => "no-progress"
    CapabilityUnavailable => "capability-unavailable"
    HostOperationFailed => "host-operation-failed"
  }
}

///|
fn append_string_field(
  result : String,
  name : String,
  value : String?,
) -> String {
  match value {
    None => result
    Some(value) => result + "|" + name + "=\"" + escape_field(value) + "\""
  }
}

///|
fn append_uint64_field(
  result : String,
  name : String,
  value : UInt64?,
) -> String {
  match value {
    None => result
    Some(value) => result + "|" + name + "=" + value.to_string()
  }
}

///|
/// Render an error canonically. Field order and escaping are part of the
/// candidate public contract.
pub fn render_error(error : CoreError) -> String {
  let mut result = "error|category=" +
    error.category_value.token() +
    "|code=" +
    error.code_value.token()
  result = append_string_field(result, "operation", error.operation_value)
  result = append_uint64_field(result, "requested", error.requested_value)
  result = append_uint64_field(result, "completed", error.completed_value)
  match (error.range_start_value, error.range_end_value) {
    (Some(start), Some(end)) =>
      result = result + "|range=" + start.to_string() + ".." + end.to_string()
    _ => ()
  }
  result = append_uint64_field(
    result,
    "source_offset",
    error.source_offset_value,
  )
  result = append_uint64_field(result, "limit", error.limit_value)
  result = append_string_field(result, "context", error.context_value)
  result
}
