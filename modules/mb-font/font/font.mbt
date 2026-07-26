///|
/// An atomically admitted font over retained caller-provided bytes.
///
/// The representation is private. Queries added by the admission tracer guard
/// the retained source revision before returning immutable admitted facts.
pub struct Font {
  priv source : @bytes.ByteView
  priv opening_revision : UInt64
  priv units_per_em_value : UInt64
}
