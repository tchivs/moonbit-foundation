///|
/// A bounded semantic outline/profile classification for one collection face.
pub(all) enum FontFaceProfile {
  StaticGlyf
  Cff
  Cff2
  Variable
  OtherUnsupported
} derive(Eq)

///|
/// Structural collection signature status. Presence never implies trust.
pub(all) enum FontCollectionDsigStatus {
  Absent
  PresentUnverified
} derive(Eq)

///|
/// An opaque, revision-guarded identity for one admitted font collection.
#warnings("-7")
pub struct FontCollection {
  priv source : @bytes.ByteView
  priv opening_revision : UInt64
  priv faces : Array[CollectionFaceFacts]
  priv protected_ranges : Array[CollectionProtectedRange]
  priv dsig_status_value : FontCollectionDsigStatus
}

///|
fn font_collection_revision_error(operation : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation~,
    context="font-collection-source-revision-drift",
  )
}

///|
fn font_collection_index_error(
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="font-collection-query",
    requested~,
    limit~,
    context="font-collection-face-index",
  )
}

///|
fn FontCollection::require_revision(
  self : FontCollection,
  operation : String,
) -> Result[Unit, @error.CoreError] {
  if self.source.mutation_revision() != self.opening_revision {
    Err(font_collection_revision_error(operation))
  } else {
    Ok(())
  }
}

///|
/// Admit one raw TTC collection without selecting a face into `Font`.
pub fn FontCollection::open(
  source : @bytes.ByteView,
  limits : FontCollectionLimits,
  budget : @budget.Budget,
) -> Result[FontCollection, @error.CoreError] {
  let opening_revision = source.mutation_revision()
  let facts = match font_collection_parse(source, limits, budget) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if source.mutation_revision() != opening_revision {
    return Err(font_collection_revision_error("font-collection-open"))
  }
  match budget.charge(facts.charge) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  Ok({
    source,
    opening_revision,
    faces: facts.faces,
    protected_ranges: facts.protected_ranges,
    dsig_status_value: facts.dsig_status,
  })
}

///|
/// Return the exact admitted face count after checking source identity.
pub fn FontCollection::face_count(
  self : FontCollection,
) -> Result[UInt64, @error.CoreError] {
  match self.require_revision("font-collection-query") {
    Err(error) => Err(error)
    Ok(_) => Ok(self.faces.length().to_uint64())
  }
}

///|
/// Return the closed semantic profile for one zero-based face.
pub fn FontCollection::face_profile(
  self : FontCollection,
  index : UInt64,
) -> Result[FontFaceProfile, @error.CoreError] {
  match self.require_revision("font-collection-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = self.faces.length().to_uint64()
  if index >= count {
    return Err(font_collection_index_error(index, count))
  }
  let narrowed = match @checked.checked_narrow_int(index) {
    Ok(value) => value
    Err(_) => return Err(font_collection_index_error(index, count))
  }
  Ok(self.faces[narrowed].profile)
}

///|
/// Report absent versus structurally present-but-unverified collection DSIG.
pub fn FontCollection::dsig_status(
  self : FontCollection,
) -> Result[FontCollectionDsigStatus, @error.CoreError] {
  match self.require_revision("font-collection-query") {
    Err(error) => Err(error)
    Ok(_) => Ok(self.dsig_status_value)
  }
}
