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
// Coverage: butt/square/round cap, miter/bevel join (miter extends to the join
// intersection and falls back to bevel beyond miter_limit), and dash patterns
// (alternating on/off lengths, repeating). Round join is approximated as bevel
// in this revision (the miter/bevel offset path is used; true round joins would
// insert arc points at each corner and are a follow-up refinement).

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
    if style.dash.is_empty() {
      stroke_polyline(outline, pl, half, style)
    } else {
      // Dash pattern: split the centerline into on-segments and stroke each.
      for sub in apply_dash(pl, style.dash) {
        if sub.points.length() >= 2 {
          stroke_polyline(outline, sub, half, style)
        }
      }
    }
  }
  outline
}

// Split a polyline into "on" sub-polylines according to a dash pattern. The
// pattern is alternating on/off lengths; the first entry is "on". The pattern
// repeats and wraps if the polyline is longer than one cycle. Off segments and
// the gaps they create are dropped; only on segments produce output polylines.
fn apply_dash(pl : Polyline, dash : Array[Double]) -> Array[Polyline] {
  let result : Array[Polyline] = []
  if dash.is_empty() || pl.points.length() < 2 {
    result.push(pl)
    return result
  }
  let mut seg_idx = 0 // index into pl.points for the current centerline segment
  // Walk the centerline accumulating distance; toggle on/off at pattern boundaries.
  let mut remaining = dash[0] // distance left in the current dash entry
  let mut on = true // dash[0] is "on"
  let mut dash_idx = 0
  let mut current_run : Array[@math.Point2] = []
  let p0 = pl.points[0]
  current_run.push(p0)
  let mut cur_x = p0.x()
  let mut cur_y = p0.y()
  while seg_idx < pl.points.length() - 1 {
    let p_next = pl.points[seg_idx + 1]
    let dx = p_next.x() - cur_x
    let dy = p_next.y() - cur_y
    let seg_len = (dx * dx + dy * dy).sqrt()
    if seg_len < 1.0e-12 {
      // Degenerate skip.
      seg_idx += 1
      cur_x = p_next.x()
      cur_y = p_next.y()
      continue
    }
    let ux = dx / seg_len
    let uy = dy / seg_len
    if seg_len <= remaining {
      // Whole remaining centerline segment fits in the current dash entry.
      if on {
        current_run.push(p_next)
      }
      remaining -= seg_len
      cur_x = p_next.x()
      cur_y = p_next.y()
      seg_idx += 1
    } else {
      // The dash boundary falls inside this centerline segment.
      let cut_x = cur_x + ux * remaining
      let cut_y = cur_y + uy * remaining
      let cut_pt = @math.Point2::new(cut_x, cut_y)
      if on {
        current_run.push(cut_pt)
        // End of an "on" run.
        if current_run.length() >= 2 {
          result.push({ points: current_run, closed: false })
        }
        current_run = []
      }
      // Advance past the cut, toggle dash entry.
      cur_x = cut_x
      cur_y = cut_y
      remaining = 0.0
      // Move to next dash entry (toggle on/off), wrapping the pattern.
      dash_idx = (dash_idx + 1) % dash.length()
      remaining = dash[dash_idx]
      on = (dash_idx % 2 == 0)
      if on {
        // Start a new "on" run at the cut point.
        current_run = [cut_pt]
      }
      // Do not advance seg_idx; the rest of this centerline segment is processed
      // in the next iteration against the new dash entry.
    }
    if remaining <= 1.0e-12 {
      // Dash entry exhausted exactly at a vertex.
      if on {
        if current_run.length() >= 2 {
          result.push({ points: current_run, closed: false })
        }
        current_run = []
      }
      dash_idx = (dash_idx + 1) % dash.length()
      remaining = dash[dash_idx]
      on = (dash_idx % 2 == 0)
      if on {
        current_run = [@math.Point2::new(cur_x, cur_y)]
      }
    }
  }
  // Flush a trailing "on" run.
  if on && current_run.length() >= 2 {
    result.push({ points: current_run, closed: false })
  }
  result
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
    let miter_len = miter_length(dx_in, dy_in, dx_out, dy_out, lnx, lny, half, style)
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
  if !pl.closed {
    match style.cap {
      Square => emit_square_cap(outline, pl.points[n - 1], pl.points[n - 2], half)
      Round => emit_round_cap(outline, left[n - 1], right[n - 1], pl.points[n - 1], pl.points[n - 2], half)
      Butt => ()
    }
  }
  for i = n - 1; i >= 0; i = i + -1 {
    outline.push(@math.PathCommand::LineTo(right[i]))
  }
  // Near-end cap (open polyline only).
  if !pl.closed {
    match style.cap {
      Square => emit_square_cap(outline, pl.points[0], pl.points[1], half)
      Round => emit_round_cap(outline, right[0], left[0], pl.points[0], pl.points[1], half)
      Butt => ()
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

// Emit a round (semicircle) cap connecting `from_pt` to `to_pt` around `center`,
// bulging in the tangent direction (from `center` toward `back` reversed — i.e.
// the cap protrudes past the endpoint). Approximated by two cubic Bézier arcs
// (one per quarter turn), using the standard κ ≈ 0.5523 control-distance.
fn emit_round_cap(
  outline : @math.Path2,
  from_pt : @math.Point2,
  to_pt : @math.Point2,
  center : @math.Point2,
  back : @math.Point2,
  half : Double,
) -> Unit {
  // Tangent direction at the endpoint: from `back` toward `center` (forward).
  let (tx, ty) = unit_dir(back, center)
  // The two cap-edge points are `from_pt` and `to_pt`, each at distance `half`
  // perpendicular to the tangent from `center`. The semicircle bulges forward
  // (past the endpoint) and sweeps from from_pt around to to_pt.
  // We approximate the semicircle with two cubic Bézier quarter-arcs through
  // an intermediate point at center + tangent*half (the forward pole).
  let fwd = @math.Point2::new(center.x() + tx * half, center.y() + ty * half)
  let kappa = 0.5522847498307936 * half
  // Tangent control offsets at each quarter boundary (perpendicular to the
  // local radius direction).
  // Arc 1: from_pt → fwd. At from_pt the tangent is +tangent; at fwd it is
  // rotated 90° toward to_pt.
  let from_t = @math.Point2::new(from_pt.x() + tx * kappa, from_pt.y() + ty * kappa)
  // At fwd, the incoming tangent is perpendicular to (fwd - from_pt) direction,
  // which is the normal pointing from from_pt to fwd. Approximate by the normal
  // of the forward direction pointing toward to_pt.
  let (fnx, fny) = (-ty, tx) // left normal of tangent
  // Determine which side to_pt is on, to orient the arc.
  let side = (to_pt.x() - center.x()) * fnx + (to_pt.y() - center.y()) * fny
  let (snx, sny) = if side >= 0.0 {
    (fnx, fny)
  } else {
    (-fnx, -fny)
  }
  let fwd_in = @math.Point2::new(fwd.x() - snx * kappa, fwd.y() - sny * kappa)
  outline.push(@math.PathCommand::CubicTo(from_t, fwd_in, fwd))
  // Arc 2: fwd → to_pt. At fwd the outgoing tangent is +normal(snx,sny); at
  // to_pt it is -tangent.
  let fwd_out = @math.Point2::new(fwd.x() + snx * kappa, fwd.y() + sny * kappa)
  let to_t = @math.Point2::new(to_pt.x() - tx * kappa, to_pt.y() - ty * kappa)
  outline.push(@math.PathCommand::CubicTo(fwd_out, to_t, to_pt))
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

// Miter offset length at a vertex. For a straight-through vertex (collinear
// in/out tangents) this is exactly `half`. At a corner the two offset lines
// meet further out: m = half / sin(θ/2) where θ is the angle between the
// ingoing and outgoing tangents. When m exceeds miter_limit * half the join
// falls back to a bevel (plain half-width offset). Non-miter joins (round,
// bevel) always use a plain half offset — round inserts arc points elsewhere,
// bevel leaves the corner chamfered.
fn miter_length(
  dx_in : Double,
  dy_in : Double,
  dx_out : Double,
  dy_out : Double,
  _lnx : Double,
  _lny : Double,
  half : Double,
  style : StrokeStyle,
) -> Double {
  // Only the Miter join computes an extended offset; round/bevel use plain half.
  match style.join {
    Miter => ()
    _ => return half
  }
  let in_len = (dx_in * dx_in + dy_in * dy_in).sqrt()
  let out_len = (dx_out * dx_out + dy_out * dy_out).sqrt()
  // Degenerate tangent (coincident points) → plain offset.
  if in_len < 1.0e-12 || out_len < 1.0e-12 {
    return half
  }
  // cos(θ) between the ingoing and outgoing unit tangents.
  let cos_theta = (dx_in * dx_out + dy_in * dy_out) / (in_len * out_len)
  // sin(θ/2) = sqrt((1 - cos θ) / 2). Clamp cos_theta to [-1,1] for safety.
  let c = if cos_theta > 1.0 {
    1.0
  } else if cos_theta < -1.0 {
    -1.0
  } else {
    cos_theta
  }
  let sin_half = ((1.0 - c) / 2.0).sqrt()
  // Near-straight (θ ≈ 0): sin(θ/2) ≈ 0, miter ≈ half. Avoid division blow-up.
  if sin_half < 1.0e-12 {
    return half
  }
  let miter = half / sin_half
  // Beyond the miter limit, fall back to bevel (plain half offset).
  let limit = half * style.miter_limit
  if miter > limit {
    half
  } else {
    miter
  }
}
