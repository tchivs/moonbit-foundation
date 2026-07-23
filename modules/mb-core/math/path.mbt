// 2D path geometry for MoonBit Native Foundation.
//
// A typed path command list consumed by mb-canvas (rasterization input),
// mb-svg (path data expansion), and mb-font (glyph outline representation).
// This is format-neutral geometry: it does not parse SVG path syntax or
// font glyph data; it is the shared output type that parsers produce and
// rasterizers consume.
//
// All operations are pure functions, deterministic across every target.

///|
/// A single path command in a 2D vector path.
pub(all) enum PathCommand {
  /// Move to a point, starting a new subpath.
  MoveTo(Point2)
  /// Draw a line to a point.
  LineTo(Point2)
  /// Draw a quadratic Bézier curve to `end` using `control`.
  QuadTo(Point2, Point2)
  /// Draw a cubic Bézier curve to `end` using two control points.
  CubicTo(Point2, Point2, Point2)
  /// Close the current subpath by drawing a line to the last MoveTo point.
  Close
}

///|
/// A 2D vector path: an ordered list of path commands.
///
/// The path is append-only and value-typed. It is the shared input type
/// for rasterization (mb-canvas), font outlines (mb-font), and SVG path
/// expansion (mb-svg).
pub struct Path2 {
  commands : Array[PathCommand]
}

///|
/// Construct an empty path.
pub fn Path2::new() -> Path2 {
  { commands: [] }
}

///|
/// The number of commands in this path.
pub fn Path2::length(self : Path2) -> Int {
  self.commands.length()
}

///|
/// Append a command to this path.
pub fn Path2::push(self : Path2, command : PathCommand) -> Unit {
  self.commands.push(command)
}

///|
/// Get the command at `index`.
pub fn Path2::get(self : Path2, index : Int) -> PathCommand? {
  if index >= 0 && index < self.commands.length() {
    Some(self.commands[index])
  } else {
    None
  }
}

///|
/// Iterate over all commands. The callback receives each command in order.
pub fn Path2::each(self : Path2, f : (PathCommand) -> Unit) -> Unit {
  for i = 0; i < self.commands.length(); i = i + 1 {
    f(self.commands[i])
  }
}

///|
/// Compute the bounding box of this path by evaluating all command
/// endpoints and Bézier control points. Returns `None` if the path is
/// empty or contains only Close commands.
pub fn Path2::bounds(self : Path2) -> Rect2? {
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = 0.0
  let mut max_y = 0.0
  let mut has_point = false
  for i = 0; i < self.commands.length(); i = i + 1 {
    match self.commands[i] {
      MoveTo(p) => {
        if !has_point {
          min_x = p.x()
          min_y = p.y()
          max_x = p.x()
          max_y = p.y()
          has_point = true
        } else {
          if p.x() < min_x {
            min_x = p.x()
          }
          if p.x() > max_x {
            max_x = p.x()
          }
          if p.y() < min_y {
            min_y = p.y()
          }
          if p.y() > max_y {
            max_y = p.y()
          }
        }
      }
      LineTo(p) => {
        if !has_point {
          min_x = p.x()
          min_y = p.y()
          max_x = p.x()
          max_y = p.y()
          has_point = true
        } else {
          if p.x() < min_x {
            min_x = p.x()
          }
          if p.x() > max_x {
            max_x = p.x()
          }
          if p.y() < min_y {
            min_y = p.y()
          }
          if p.y() > max_y {
            max_y = p.y()
          }
        }
      }
      QuadTo(control, end) => {
        for p in [control, end] {
          if !has_point {
            min_x = p.x()
            min_y = p.y()
            max_x = p.x()
            max_y = p.y()
            has_point = true
          } else {
            if p.x() < min_x {
              min_x = p.x()
            }
            if p.x() > max_x {
              max_x = p.x()
            }
            if p.y() < min_y {
              min_y = p.y()
            }
            if p.y() > max_y {
              max_y = p.y()
            }
          }
        }
      }
      CubicTo(c1, c2, end) => {
        for p in [c1, c2, end] {
          if !has_point {
            min_x = p.x()
            min_y = p.y()
            max_x = p.x()
            max_y = p.y()
            has_point = true
          } else {
            if p.x() < min_x {
              min_x = p.x()
            }
            if p.x() > max_x {
              max_x = p.x()
            }
            if p.y() < min_y {
              min_y = p.y()
            }
            if p.y() > max_y {
              max_y = p.y()
            }
          }
        }
      }
      Close => {
        let _ = i // no-op
      }
    }
  }
  if has_point {
    Some(Rect2::new(min_x, min_y, max_x - min_x, max_y - min_y))
  } else {
    None
  }
}

///|
/// Apply this affine transform to every control and endpoint in `path`,
/// producing a new path with the same command structure.
///
/// `Close` commands are preserved unchanged. The original path is not mutated.
/// This is the shared primitive for SVG/canvas coordinate transforms and
/// font outline placement.
pub fn Affine2::apply_to_path(self : Affine2, path : Path2) -> Path2 {
  let result = Path2::new()
  path.each(fn(cmd) {
    match cmd {
      MoveTo(p) => result.push(MoveTo(self.apply(p)))
      LineTo(p) => result.push(LineTo(self.apply(p)))
      QuadTo(control, end) =>
        result.push(QuadTo(self.apply(control), self.apply(end)))
      CubicTo(c1, c2, end) =>
        result.push(CubicTo(self.apply(c1), self.apply(c2), self.apply(end)))
      Close => result.push(Close)
    }
  })
  result
}

///|
/// Flatten this path into line segments by approximating all Bézier curves
/// with the given tolerance and maximum subdivision depth.
///
/// - `tolerance`: maximum deviation of control points from the chord.
/// - `max_depth`: maximum subdivision recursion depth.
///
/// Returns the flattened segments. The result is empty if the path contains
/// no geometry (only Close commands). Each subpath starts at the last MoveTo
/// point; Close commands emit a segment back to the subpath start.
pub fn Path2::flattened(self : Path2, tolerance : Double, max_depth : Int) -> Array[LineSegment] {
  let segments : Array[LineSegment] = []
  let mut subpath_start = Point2::origin()
  let mut current = Point2::origin()
  let mut has_current = false
  self.each(fn(cmd) {
    match cmd {
      MoveTo(p) => {
        if has_current && (p.x() != current.x() || p.y() != current.y()) {
          // Implicit close not emitted; MoveTo starts a new subpath.
          let _ = current
        }
        subpath_start = p
        current = p
        has_current = true
      }
      LineTo(p) => {
        if has_current {
          segments.push({ start_value: current, end_value: p })
        }
        current = p
      }
      QuadTo(control, end) => {
        if has_current {
          match bezier2_flatten(current, control, end, tolerance, max_depth) {
            Ok(curve_segments) => {
              for seg in curve_segments {
                segments.push(seg)
              }
            }
            Err(_) => {
              // On failure, emit a straight line as fallback.
              segments.push({ start_value: current, end_value: end })
            }
          }
        }
        current = end
      }
      CubicTo(c1, c2, end) => {
        if has_current {
          match bezier3_flatten(current, c1, c2, end, tolerance, max_depth) {
            Ok(curve_segments) => {
              for seg in curve_segments {
                segments.push(seg)
              }
            }
            Err(_) => {
              segments.push({ start_value: current, end_value: end })
            }
          }
        }
        current = end
      }
      Close => {
        if has_current && (current.x() != subpath_start.x() || current.y() != subpath_start.y()) {
          segments.push({ start_value: current, end_value: subpath_start })
          current = subpath_start
        }
      }
    }
  })
  segments
}
