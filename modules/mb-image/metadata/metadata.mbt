///|
fn metadata_error(
  code : @error.ErrorCode,
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  let category = match code {
    @error.ErrorCode::BudgetExceeded => @error.ErrorCategory::Resource
    _ => @error.ErrorCategory::InvalidInput
  }
  @error.CoreError::new(
    category,
    code,
    operation="metadata",
    requested~,
    limit~,
    context~,
  )
}

///|
fn invalid_metadata_index(
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  metadata_error(
    @error.ErrorCode::InvalidRange,
    "metadata-index",
    requested,
    limit,
  )
}

///|
fn is_ascii_alphanumeric(code : Int) -> Bool {
  (code >= 65 && code <= 90) ||
  (code >= 97 && code <= 122) ||
  (code >= 48 && code <= 57)
}

///|
fn valid_token(value : String, maximum : UInt64) -> Bool {
  let units = value.code_units()
  if units.length() == 0 || units.length().to_uint64() > maximum {
    return false
  }
  if !is_ascii_alphanumeric(units[0].to_int()) {
    return false
  }
  for index = 1; index < units.length(); index = index + 1 {
    let code = units[index].to_int()
    if !(is_ascii_alphanumeric(code) ||
      code == 46 ||
      code == 95 ||
      code == 43 ||
      code == 45) {
      return false
    }
  }
  true
}

///|
fn compare_strings(left : String, right : String) -> Int {
  let left_units = left.code_units()
  let right_units = right.code_units()
  let common = if left_units.length() < right_units.length() {
    left_units.length()
  } else {
    right_units.length()
  }
  for index = 0; index < common; index = index + 1 {
    let left_code = left_units[index].to_int()
    let right_code = right_units[index].to_int()
    if left_code < right_code {
      return -1
    }
    if left_code > right_code {
      return 1
    }
  }
  if left_units.length() < right_units.length() {
    -1
  } else if left_units.length() > right_units.length() {
    1
  } else {
    0
  }
}

///|
fn compare_keys(
  left_namespace : String,
  left_key : String,
  left_tag : String,
  right_namespace : String,
  right_key : String,
  right_tag : String,
) -> Int {
  let namespace_order = compare_strings(left_namespace, right_namespace)
  if namespace_order != 0 {
    return namespace_order
  }
  let key_order = compare_strings(left_key, right_key)
  if key_order != 0 {
    return key_order
  }
  compare_strings(left_tag, right_tag)
}

///|
pub struct MetadataLimits {
  priv max_entries_value : UInt64
  priv max_token_bytes_value : UInt64
  priv max_value_bytes_value : UInt64
  priv max_total_bytes_value : UInt64
  priv max_disposition_fields_value : UInt64
}

///|
pub fn MetadataLimits::new(
  max_entries~ : UInt64,
  max_token_bytes~ : UInt64,
  max_value_bytes~ : UInt64,
  max_total_bytes~ : UInt64,
  max_disposition_fields~ : UInt64,
) -> MetadataLimits {
  {
    max_entries_value: max_entries,
    max_token_bytes_value: max_token_bytes,
    max_value_bytes_value: max_value_bytes,
    max_total_bytes_value: max_total_bytes,
    max_disposition_fields_value: max_disposition_fields,
  }
}

///|
pub fn MetadataLimits::max_entries(self : MetadataLimits) -> UInt64 {
  self.max_entries_value
}

///|
pub fn MetadataLimits::max_token_bytes(self : MetadataLimits) -> UInt64 {
  self.max_token_bytes_value
}

///|
pub fn MetadataLimits::max_value_bytes(self : MetadataLimits) -> UInt64 {
  self.max_value_bytes_value
}

///|
pub fn MetadataLimits::max_total_bytes(self : MetadataLimits) -> UInt64 {
  self.max_total_bytes_value
}

///|
pub fn MetadataLimits::max_disposition_fields(self : MetadataLimits) -> UInt64 {
  self.max_disposition_fields_value
}

///|
priv struct RawMetadataEntry {
  namespace : String
  key : String
  tag : String
  value : Bytes
}

///|
fn RawMetadataEntry::compare(
  self : RawMetadataEntry,
  other : RawMetadataEntry,
) -> Int {
  compare_keys(
    self.namespace,
    self.key,
    self.tag,
    other.namespace,
    other.key,
    other.tag,
  )
}

///|
fn canonicalize_raw_entries(
  source : Array[(String, String, String, Bytes)],
  limits : MetadataLimits,
) -> Result[(Array[RawMetadataEntry], UInt64), @error.CoreError] {
  let count = source.length().to_uint64()
  if count > limits.max_entries() {
    return Err(
      metadata_error(
        @error.ErrorCode::BudgetExceeded,
        "metadata-entry-count",
        count,
        limits.max_entries(),
      ),
    )
  }
  let entries : Array[RawMetadataEntry] = []
  let mut total = 0UL
  for item in source {
    let (namespace, key, tag, value) = item
    for token in [namespace, key, tag] {
      let length = token.length().to_uint64()
      if !valid_token(token, limits.max_token_bytes()) {
        return Err(
          metadata_error(
            @error.ErrorCode::InvalidEncoding,
            "metadata-token",
            length,
            limits.max_token_bytes(),
          ),
        )
      }
      if length > limits.max_total_bytes() - total {
        return Err(
          metadata_error(
            @error.ErrorCode::BudgetExceeded,
            "metadata-total",
            total + length,
            limits.max_total_bytes(),
          ),
        )
      }
      total = total + length
    }
    let value_length = value.length().to_uint64()
    if value_length > limits.max_value_bytes() {
      return Err(
        metadata_error(
          @error.ErrorCode::BudgetExceeded,
          "metadata-value",
          value_length,
          limits.max_value_bytes(),
        ),
      )
    }
    if value_length > limits.max_total_bytes() - total {
      return Err(
        metadata_error(
          @error.ErrorCode::BudgetExceeded,
          "metadata-total",
          limits.max_total_bytes(),
          limits.max_total_bytes(),
        ),
      )
    }
    total = total + value_length
    entries.push({ namespace, key, tag, value })
  }
  for index = 1; index < entries.length(); index = index + 1 {
    let current = entries[index]
    let mut insertion = index
    while insertion > 0 && current.compare(entries[insertion - 1]) < 0 {
      entries[insertion] = entries[insertion - 1]
      insertion = insertion - 1
    }
    entries[insertion] = current
  }
  for index = 1; index < entries.length(); index = index + 1 {
    if entries[index - 1].compare(entries[index]) == 0 {
      return Err(
        metadata_error(
          @error.ErrorCode::InvalidEncoding,
          "metadata-duplicate",
          index.to_uint64(),
          limits.max_entries(),
        ),
      )
    }
  }
  Ok((entries, total))
}

///|
pub struct MetadataEntry {
  priv namespace_value : String
  priv key_value : String
  priv tag_value : String
  priv value_view : @bytes.ByteView
}

///|
pub fn MetadataEntry::namespace(self : MetadataEntry) -> String {
  self.namespace_value
}

///|
pub fn MetadataEntry::key(self : MetadataEntry) -> String {
  self.key_value
}

///|
pub fn MetadataEntry::tag(self : MetadataEntry) -> String {
  self.tag_value
}

///|
pub fn MetadataEntry::canonical_key(self : MetadataEntry) -> String {
  self.namespace_value + ":" + self.key_value + ":" + self.tag_value
}

///|
pub fn MetadataEntry::value(self : MetadataEntry) -> @bytes.ByteView {
  self.value_view
}

///|
pub struct OpaqueMetadata {
  priv entries_value : Array[MetadataEntry]
  priv owner : @bytes.OwnedBytes
}

///|
pub fn OpaqueMetadata::from_entries(
  source : Array[(String, String, String, Bytes)],
  limits : MetadataLimits,
  budget : @budget.Budget,
) -> Result[OpaqueMetadata, @error.CoreError] {
  let (raw_entries, _) = match canonicalize_raw_entries(source, limits) {
    Err(error) => return Err(error)
    Ok(result) => result
  }
  let mut value_bytes = 0UL
  for entry in raw_entries {
    let length = entry.value.length().to_uint64()
    if length > limits.max_total_bytes() - value_bytes {
      return Err(
        metadata_error(
          @error.ErrorCode::BudgetExceeded,
          "metadata-total",
          limits.max_total_bytes(),
          limits.max_total_bytes(),
        ),
      )
    }
    value_bytes = value_bytes + length
  }
  let owner = match @bytes.OwnedBytes::new(value_bytes, budget) {
    Err(error) => return Err(error)
    Ok(owner) => owner
  }
  let copied = owner.with_mut(0UL, value_bytes, fn(lease) {
    let mut offset = 0UL
    for entry in raw_entries {
      for index = 0; index < entry.value.length(); index = index + 1 {
        match lease.set(offset, entry.value[index]) {
          Err(error) => return Err(error)
          Ok(_) => offset = offset + 1UL
        }
      }
    }
    Ok(())
  })
  match copied {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let entries : Array[MetadataEntry] = []
  let mut offset = 0UL
  for entry in raw_entries {
    let length = entry.value.length().to_uint64()
    let view = owner.view().subview(offset, length).unwrap()
    entries.push({
      namespace_value: entry.namespace,
      key_value: entry.key,
      tag_value: entry.tag,
      value_view: view,
    })
    offset = offset + length
  }
  Ok({ entries_value: entries, owner })
}

///|
pub fn OpaqueMetadata::length(self : OpaqueMetadata) -> Int {
  self.entries_value.length()
}

///|
pub fn OpaqueMetadata::storage_length(self : OpaqueMetadata) -> UInt64 {
  self.owner.length()
}

///|
pub fn OpaqueMetadata::entry(
  self : OpaqueMetadata,
  index : Int,
) -> Result[MetadataEntry, @error.CoreError] {
  if index < 0 || index >= self.entries_value.length() {
    Err(
      invalid_metadata_index(
        if index < 0 {
          0UL
        } else {
          index.to_uint64()
        },
        self.entries_value.length().to_uint64(),
      ),
    )
  } else {
    Ok(self.entries_value[index])
  }
}

///|
pub struct DispositionField {
  priv value_value : String
}

///|
pub fn DispositionField::new(
  value : String,
  limits : MetadataLimits,
) -> Result[DispositionField, @error.CoreError] {
  if valid_token(value, limits.max_token_bytes()) {
    Ok({ value_value: value })
  } else {
    Err(
      metadata_error(
        @error.ErrorCode::InvalidEncoding,
        "disposition-field",
        value.length().to_uint64(),
        limits.max_token_bytes(),
      ),
    )
  }
}

///|
pub fn DispositionField::value(self : DispositionField) -> String {
  self.value_value
}

///|
fn sort_fields(fields : Array[DispositionField]) -> Array[DispositionField] {
  let sorted = fields.copy()
  for index = 1; index < sorted.length(); index = index + 1 {
    let current = sorted[index]
    let mut insertion = index
    while insertion > 0 &&
          compare_strings(current.value(), sorted[insertion - 1].value()) < 0 {
      sorted[insertion] = sorted[insertion - 1]
      insertion = insertion - 1
    }
    sorted[insertion] = current
  }
  sorted
}

///|
fn fields_have_duplicates(fields : Array[DispositionField]) -> Bool {
  for index = 1; index < fields.length(); index = index + 1 {
    if fields[index - 1].value() == fields[index].value() {
      return true
    }
  }
  false
}

///|
fn contains_field(fields : Array[DispositionField], value : String) -> Bool {
  for field in fields {
    if field.value() == value {
      return true
    }
  }
  false
}

///|
pub struct MetadataDisposition {
  priv preserved_value : Array[DispositionField]
  priv transformed_value : Array[DispositionField]
  priv discarded_value : Array[DispositionField]
  priv lossy_value : Bool
}

///|
pub fn MetadataDisposition::new(
  preserved : Array[DispositionField],
  transformed : Array[DispositionField],
  discarded : Array[DispositionField],
  lossy : Bool,
  limits : MetadataLimits,
) -> Result[MetadataDisposition, @error.CoreError] {
  let count = preserved.length().to_uint64() +
    transformed.length().to_uint64() +
    discarded.length().to_uint64()
  if count > limits.max_disposition_fields() {
    return Err(
      metadata_error(
        @error.ErrorCode::BudgetExceeded,
        "disposition-count",
        count,
        limits.max_disposition_fields(),
      ),
    )
  }
  let preserved_sorted = sort_fields(preserved)
  let transformed_sorted = sort_fields(transformed)
  let discarded_sorted = sort_fields(discarded)
  if fields_have_duplicates(preserved_sorted) ||
    fields_have_duplicates(transformed_sorted) ||
    fields_have_duplicates(discarded_sorted) {
    return Err(
      metadata_error(
        @error.ErrorCode::InvalidEncoding,
        "disposition-duplicate",
        count,
        limits.max_disposition_fields(),
      ),
    )
  }
  for field in preserved_sorted {
    if contains_field(transformed_sorted, field.value()) ||
      contains_field(discarded_sorted, field.value()) {
      return Err(
        metadata_error(
          @error.ErrorCode::InvalidEncoding,
          "disposition-duplicate",
          count,
          limits.max_disposition_fields(),
        ),
      )
    }
  }
  for field in transformed_sorted {
    if contains_field(discarded_sorted, field.value()) {
      return Err(
        metadata_error(
          @error.ErrorCode::InvalidEncoding,
          "disposition-duplicate",
          count,
          limits.max_disposition_fields(),
        ),
      )
    }
  }
  Ok({
    preserved_value: preserved_sorted,
    transformed_value: transformed_sorted,
    discarded_value: discarded_sorted,
    lossy_value: lossy,
  })
}

///|
pub fn MetadataDisposition::preserved_length(self : MetadataDisposition) -> Int {
  self.preserved_value.length()
}

///|
pub fn MetadataDisposition::transformed_length(
  self : MetadataDisposition,
) -> Int {
  self.transformed_value.length()
}

///|
pub fn MetadataDisposition::discarded_length(self : MetadataDisposition) -> Int {
  self.discarded_value.length()
}

///|
fn disposition_field_at(
  fields : Array[DispositionField],
  index : Int,
) -> Result[DispositionField, @error.CoreError] {
  if index < 0 || index >= fields.length() {
    Err(
      invalid_metadata_index(
        if index < 0 {
          0UL
        } else {
          index.to_uint64()
        },
        fields.length().to_uint64(),
      ),
    )
  } else {
    Ok(fields[index])
  }
}

///|
pub fn MetadataDisposition::preserved(
  self : MetadataDisposition,
  index : Int,
) -> Result[DispositionField, @error.CoreError] {
  disposition_field_at(self.preserved_value, index)
}

///|
pub fn MetadataDisposition::transformed(
  self : MetadataDisposition,
  index : Int,
) -> Result[DispositionField, @error.CoreError] {
  disposition_field_at(self.transformed_value, index)
}

///|
pub fn MetadataDisposition::discarded(
  self : MetadataDisposition,
  index : Int,
) -> Result[DispositionField, @error.CoreError] {
  disposition_field_at(self.discarded_value, index)
}

///|
pub fn MetadataDisposition::is_lossy(self : MetadataDisposition) -> Bool {
  self.lossy_value
}
