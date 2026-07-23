// The mb-canvas drawing list — a portable, pure-data, append-only sequence of
// draw operations over path geometry, style, and transform/clip state.
//
// Per RFC 0003 §5, the drawing list is the primary public contract: it is
// deterministic, serializable, inspectable, and buildable by CLI, Agent, and
// MCP consumers without any render. State changes (transform, clip) are recorded
// as operations in the list, not as ambient mutable context, preserving value
// semantics and replay determinism.

///|
/// A single operation recorded in a drawing list. This is the internal
/// representation; callers build lists through `DrawingList` methods.
pub(all) enum DrawOp {
  // Fill a path with a fill style under the transform/clip state at this point.
  Fill(@math.Path2, FillStyle)
  // Stroke a path with a stroke style and color under the current state.
  Stroke(@math.Path2, StrokeStyle, FillStyle)
  // Push an affine transform onto the transform stack (composed with current).
  PushTransform(@math.Affine2)
  // Pop the most recent transform.
  PopTransform
  // Push a clip rectangle (intersected with the current clip) in user space.
  PushClip(@math.Rect2)
  // Pop the most recent clip.
  PopClip
}

///|
/// An append-only drawing list. State changes are recorded as operations and
/// replayed in order during rasterization.
pub struct DrawingList {
  ops : Array[DrawOp]
}

///|
/// Construct an empty drawing list.
pub fn DrawingList::new() -> DrawingList {
  { ops: [] }
}

///|
/// Append a fill operation. The path is borrowed by reference into the op; the
/// caller may continue mutating the source path after this call since the op
/// holds the path value.
pub fn DrawingList::push_fill(
  self : DrawingList,
  path : @math.Path2,
  style : FillStyle,
) -> Unit {
  self.ops.push(DrawOp::Fill(path, style))
}

///|
/// Append a stroke operation. `color_style` carries the stroke color (its
/// `rule` field is unused for strokes — strokes are always filled as closed
/// outlines and use EvenOdd to avoid double-coverage at overlaps).
pub fn DrawingList::push_stroke(
  self : DrawingList,
  path : @math.Path2,
  stroke : StrokeStyle,
  color_style : FillStyle,
) -> Unit {
  self.ops.push(DrawOp::Stroke(path, stroke, color_style))
}

///|
/// Push a transform onto the transform stack. The transform is composed with
/// the current transform, so subsequent draws are affected by the full chain.
pub fn DrawingList::push_transform(
  self : DrawingList,
  transform : @math.Affine2,
) -> Unit {
  self.ops.push(DrawOp::PushTransform(transform))
}

///|
/// Pop the most recent transform. It is the caller's responsibility to keep
/// push/pop balanced; an unbalanced pop is a no-op at rasterization time.
pub fn DrawingList::pop_transform(self : DrawingList) -> Unit {
  self.ops.push(DrawOp::PopTransform)
}

///|
/// Push a clip rectangle in user space. The rectangle is intersected with the
/// current clip; subsequent draws are confined to the intersection until popped.
pub fn DrawingList::push_clip(self : DrawingList, clip : @math.Rect2) -> Unit {
  self.ops.push(DrawOp::PushClip(clip))
}

///|
/// Pop the most recent clip. Unbalanced pops are no-ops at rasterization time.
pub fn DrawingList::pop_clip(self : DrawingList) -> Unit {
  self.ops.push(DrawOp::PopClip)
}

///|
/// The number of operations recorded in this list.
pub fn DrawingList::length(self : DrawingList) -> Int {
  self.ops.length()
}

///|
/// Read the operation at `index`, or `None` if out of range.
pub fn DrawingList::get(self : DrawingList, index : Int) -> DrawOp? {
  self.ops.get(index)
}
