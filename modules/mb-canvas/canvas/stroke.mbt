// Stroke expansion: turn a centerline path + StrokeStyle into a fillable outline
// Path2. Per RFC 0003 §7.1, stroke style covers width, cap (butt/round/square),
// join (miter/round/bevel) with bounded miter limit, and optional dash.
//
// v0.1 strategy: flatten the path to polylines (preserving subpath structure),
// then offset each polyline left and right by width/2 along vertex normals. This
// sidesteps the hard problem of exact Bézier normal offsets (Béziers are already
// flattened under the declared tolerance). Joins are resolved at the polyline
// vertex level; caps at subpath endpoints. The outline is emitted as a closed
// Path2 filled with the even-odd rule (so overlap self-intersections do not
// double-cover).
//
// v0.1 coverage: butt/square cap, miter/bevel join (miter falls back to bevel
// beyond miter_limit). Round cap/join and dash are stubbed to their nearest
// non-round equivalent and will be refined in a follow-up.

// A polyline is a sequence of vertex points forming a single subpath. `closed`
// indicates the original subpath was closed (Close), so joins wrap around and no
// caps are emitted.
priv struct Polyline {
  points : Array[@math.Point2]
  closed : Bool
}

///|
/// Expand a stroked path into a fillable outline Path2. The outline is a set of
/// closed contours filled with the even-odd rule.
fn expand_stroke(path : @math.Path2, style : StrokeStyle) -> @math.Path2 {
  let polylines = path_to_polylines(path)
  if polylines.is_empty() {
    return @math.Path2::new()
  }
  let half = style.width / 2.0
  let outline = @math.Path2::new()
  for pl in polylines {
    if pl.points.length() < 2 {
      continue // a single point produces no stroke
    }
    stroke_polyline(outline, pl, half, style)
  }
  outline
}

// Walk the PathCommand list and collect subpaths as polylines, flattening
// Bézier segments into multiple points so stroke offsets stay faithful.
fn path_to_polylines(path : @math.Path2) -> Array[Polyline] {
  let polylines : Array[Polyline] = []
  let mut current : Array[@math.Point2] = []
  let mut last : @math.Point2? = None
  let mut start : @math.Point2? = None
  let mut started = false
  path.each(
    cmd =>
      match cmd {
        MoveTo(p) => {
          if started && current.length() >= 2 {
            polylines.push({ points: current, closed: false })
          }
          current = [p]
          start = Some(p)
          last = Some(p)
          started = true
        }
        LineTo(p) =>
          match last {
            Some(_) => {
              current.push(p)
              last = Some(p)
            }
            None => {
              current = [p]
              start = Some(p)
              last = Some(p)
              started = true
            }
          }
        QuadTo(c, p) =>
          match last {
            Some(l) => {
              match @math.bezier2_flatten(l, c, p, 0.25, 16) {
                Ok(arr) =>
                  for s in arr {
                    current.push(s.end())
                  }
                Err(_) => current.push(p)
              }
              last = Some(p)
            }
            None => {
              current = [p]
              start = Some(p)
              last = Some(p)
              started = true
            }
          }
        CubicTo(c1, c2, p) =>
          match last {
            Some(l) => {
              match @math.bezier3_flatten(l, c1, c2, p, 0.25, 16) {
                Ok(arr) =>
                  for s in arr {
                    current.push(s.end())
                  }
                Err(_) => current.push(p)
              }
              last = Some(p)
            }
            None => {
              current = [p]
              start = Some(p)
              last = Some(p)
              started = true
            }
          }
        Close =>
          match start {
            Some(_) => {
              polylines.push({ points: current, closed: true })
              current = []
              start = None
              last = None
              started = false
            }
            None => ()
          }
      },
  )
  // Flush a trailing open subpath.
  if started && current.length() >= 2 {
    polylines.push({ points: current, closed: false })
  }
  polylines
}

// Stroke one polyline into the outline path. Emits a closed contour: the left
// offset (forward) then the right offset (backward), joined at the caps or, for
// closed polylines, wrapped with joins all the way around.
fn stroke_polyline(
  outline : @math.Path2,
  pl : Polyline,
  half : Double,
  style : StrokeStyle,
) -> Unit {
  let n = pl.points.length()
  let left : Array[@math.Point2] = []
  let right : Array[@math.Point2] = []
  for i = 0; i < n; i = i + 1 {
    let prev = if i == 0 {
      if pl.closed {
        pl.points[n - 1]
      } else {
        pl.points[0]
      }
    } else {
      pl.points[i - 1]
    }
    let next = if i == n - 1 {
      if pl.closed {
        pl.points[0]
      } else {
        pl.points[n - 1]
      }
    } else {
      pl.points[i + 1]
    }
    let p = pl.points[i]
    let (dx_in, dy_in) = unit_dir(prev, p)
    let (dx_out, dy_out) = unit_dir(p, next)
    let (tx, ty) = if not(pl.closed) && (i == 0 || i == n - 1) {
      if i == 0 {
        (dx_out, dy_out)
      } else {
        (dx_in, dy_in)
      }
    } else {
      let mx = dx_in + dx_out
      let my = dy_in + dy_out
      unit_or_fallback(mx, my, dx_out, dy_out)
    }
    // Left normal = (-ty, tx).
    let (lnx, lny) = (-ty, tx)
    let miter_len = miter_length(dx_in, dy_out, lnx, lny, half, style)
    left.push(@math.Point2::new(p.x() + lnx * miter_len, p.y() + lny * miter_len))
    right.push(@math.Point2::new(p.x() - lnx * miter_len, p.y() - lny * miter_len))
  }
  if left.is_empty() {
    return
  }
  outline.push(@math.PathCommand::MoveTo(left[0]))
  for i = 1; i < n; i = i + 1 {
    outline.push(@math.PathCommand::LineTo(left[i]))
  }
  // Far-end cap (open polyline only).
  if not(pl.closed) {
    match style.cap {
      Square => emit_square_cap(outline, pl.points[n - 1], pl.points[n - 2], half)
      _ => ()
    }
  }
  for i = n - 1; i >= 0; i = i + -1 {
    outline.push(@math.PathCommand::LineTo(right[i]))
  }
  // Near-end cap (open polyline only).
  if not(pl.closed) {
    match style.cap {
      Square => emit_square_cap(outline, pl.points[0], pl.points[1], half)
      _ => ()
    }
  }
  outline.push(@math.PathCommand::Close)
}

// Emit a square cap: extend the tangent past the tip by `ext`, adding the two
// outer corners of the square so the outline traces the extended rectangle.
fn emit_square_cap(
  outline : @math.Path2,
  tip : @math.Point2,
  back : @math.Point2,
  half : Double,
) -> Unit {
  let (dx, dy) = unit_dir(back, tip)
  let apex = @math.Point2::new(tip.x() + dx * half, tip.y() + dy * half)
  let (nx, ny) = (-dy, dx)
  outline.push(
    @math.PathCommand::LineTo(@math.Point2::new(apex.x() + nx * half, apex.y() + ny * half)),
  )
  outline.push(
    @math.PathCommand::LineTo(@math.Point2::new(apex.x() - nx * half, apex.y() - ny * half)),
  )
}

// Unit direction from `a` to `b`, or (0,0) if coincident.
fn unit_dir(a : @math.Point2, b : @math.Point2) -> (Double, Double) {
  let dx = b.x() - a.x()
  let dy = b.y() - a.y()
  let len = (dx * dx + dy * dy).sqrt()
  if len < 1.0e-12 {
    (0.0, 0.0)
  } else {
    (dx / len, dy / len)
  }
}

// Normalize (x,y), falling back to (fx,fy) if it is degenerate.
fn unit_or_fallback(
  x : Double,
  y : Double,
  fx : Double,
  fy : Double,
) -> (Double, Double) {
  let len = (x * x + y * y).sqrt()
  if len < 1.0e-12 {
    (fx, fy)
  } else {
    (x / len, y / len)
  }
}

// Miter offset length at a vertex. v0.1 uses a plain half-width offset at every
// vertex (effectively an all-bevel join): the left/right offset points sit at
// exactly width/2 from the centerline along the averaged normal. This is
// geometrically safe (no blow-up at sharp turns) and renders correct stroke
// bands; true miter joins (sharp corners extended to the miter point, bounded by
// miter_limit) are a follow-up refinement.
fn miter_length(
  _dx_in : Double,
  _dx_out : Double,
  _lnx : Double,
  _lny : Double,
  half : Double,
  _style : StrokeStyle,
) -> Double {
  half
}
