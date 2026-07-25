// Checked package-private SVG geometry facts shared by parser preflight and
// total lowering. Source admission remains in the parsers; these facts admit
// every derived scalar before it can become a usable geometry result.

fn geometry_add(a : Double, b : Double) -> Result[Double, @error.CoreError] {
  admit_derived(a + b)
}

fn geometry_sub(a : Double, b : Double) -> Result[Double, @error.CoreError] {
  admit_derived(a - b)
}

fn geometry_mul(a : Double, b : Double) -> Result[Double, @error.CoreError] {
  admit_derived(a * b)
}

fn geometry_div(a : Double, b : Double) -> Result[Double, @error.CoreError] {
  admit_derived(a / b)
}

fn geometry_product_sum(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
) -> Result[Double, @error.CoreError] {
  let left = match geometry_mul(a, b) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let right = match geometry_mul(c, d) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  geometry_add(left, right)
}

fn checked_compose_affine(
  current : @math.Affine2,
  other : @math.Affine2,
) -> Result[@math.Affine2, @error.CoreError] {
  let a = match geometry_product_sum(other.a(), current.a(), other.c(), current.b()) { Ok(value) => value; Err(error) => return Err(error) }
  let b = match geometry_product_sum(other.b(), current.a(), other.d(), current.b()) { Ok(value) => value; Err(error) => return Err(error) }
  let c = match geometry_product_sum(other.a(), current.c(), other.c(), current.d()) { Ok(value) => value; Err(error) => return Err(error) }
  let d = match geometry_product_sum(other.b(), current.c(), other.d(), current.d()) { Ok(value) => value; Err(error) => return Err(error) }
  let tx_base = match geometry_product_sum(other.a(), current.tx(), other.c(), current.ty()) { Ok(value) => value; Err(error) => return Err(error) }
  let ty_base = match geometry_product_sum(other.b(), current.tx(), other.d(), current.ty()) { Ok(value) => value; Err(error) => return Err(error) }
  let tx = match geometry_add(tx_base, other.tx()) { Ok(value) => value; Err(error) => return Err(error) }
  let ty = match geometry_add(ty_base, other.ty()) { Ok(value) => value; Err(error) => return Err(error) }
  Ok(@math.Affine2::new(a, b, c, d, tx, ty))
}

fn checked_viewbox_transform(root : SvgRoot) -> Result[@math.Affine2, @error.CoreError] {
  let par = root.preserve_aspect_ratio
  match (root.view_box, root.width, root.height) {
    (Some((vbx, vby, vbw, vbh)), Some(vpw), Some(vph)) =>
      if vbw <= 0.0 || vbh <= 0.0 || vpw <= 0.0 || vph <= 0.0 {
        Ok(@math.Affine2::identity())
      } else {
        let sx = match geometry_div(vpw, vbw) { Ok(value) => value; Err(error) => return Err(error) }
        let sy = match geometry_div(vph, vbh) { Ok(value) => value; Err(error) => return Err(error) }
        if par.none {
          let tx = match geometry_mul(-vbx, sx) { Ok(value) => value; Err(error) => return Err(error) }
          let ty = match geometry_mul(-vby, sy) { Ok(value) => value; Err(error) => return Err(error) }
          Ok(@math.Affine2::new(sx, 0.0, 0.0, sy, tx, ty))
        } else {
          let scale = if par.meet { if sx < sy { sx } else { sy } } else if sx > sy { sx } else { sy }
          let width_scaled = match geometry_mul(vbw, scale) { Ok(value) => value; Err(error) => return Err(error) }
          let height_scaled = match geometry_mul(vbh, scale) { Ok(value) => value; Err(error) => return Err(error) }
          let diff_x = match geometry_sub(vpw, width_scaled) { Ok(value) => value; Err(error) => return Err(error) }
          let diff_y = match geometry_sub(vph, height_scaled) { Ok(value) => value; Err(error) => return Err(error) }
          let offset_x_product = match geometry_mul(par.align_x.to_double(), diff_x) { Ok(value) => value; Err(error) => return Err(error) }
          let offset_y_product = match geometry_mul(par.align_y.to_double(), diff_y) { Ok(value) => value; Err(error) => return Err(error) }
          let offset_x = match geometry_div(offset_x_product, 2.0) { Ok(value) => value; Err(error) => return Err(error) }
          let offset_y = match geometry_div(offset_y_product, 2.0) { Ok(value) => value; Err(error) => return Err(error) }
          let vbx_scaled = match geometry_mul(vbx, scale) { Ok(value) => value; Err(error) => return Err(error) }
          let vby_scaled = match geometry_mul(vby, scale) { Ok(value) => value; Err(error) => return Err(error) }
          let tx = match geometry_sub(offset_x, vbx_scaled) { Ok(value) => value; Err(error) => return Err(error) }
          let ty = match geometry_sub(offset_y, vby_scaled) { Ok(value) => value; Err(error) => return Err(error) }
          Ok(@math.Affine2::new(scale, 0.0, 0.0, scale, tx, ty))
        }
      }
    _ => Ok(@math.Affine2::identity())
  }
}

fn checked_transform_point(
  transform : @math.Affine2,
  point : @math.Point2,
) -> Result[@math.Point2, @error.CoreError] {
  let x_linear = match geometry_product_sum(transform.a(), point.x(), transform.c(), point.y()) { Ok(value) => value; Err(error) => return Err(error) }
  let y_linear = match geometry_product_sum(transform.b(), point.x(), transform.d(), point.y()) { Ok(value) => value; Err(error) => return Err(error) }
  let x = match geometry_add(x_linear, transform.tx()) { Ok(value) => value; Err(error) => return Err(error) }
  let y = match geometry_add(y_linear, transform.ty()) { Ok(value) => value; Err(error) => return Err(error) }
  Ok(@math.Point2::new(x, y))
}

fn checked_path_points(
  path : @math.Path2,
  transform : @math.Affine2,
) -> Result[Unit, @error.CoreError] {
  for i = 0; i < path.length(); i = i + 1 {
    match path.get(i) {
      Some(@math.PathCommand::MoveTo(point)) | Some(@math.PathCommand::LineTo(point)) =>
        match checked_transform_point(transform, point) { Ok(_) => (); Err(error) => return Err(error) }
      Some(@math.PathCommand::QuadTo(control, endpoint)) => {
        match checked_transform_point(transform, control) { Ok(_) => (); Err(error) => return Err(error) }
        match checked_transform_point(transform, endpoint) { Ok(_) => (); Err(error) => return Err(error) }
      }
      Some(@math.PathCommand::CubicTo(control1, control2, endpoint)) => {
        match checked_transform_point(transform, control1) { Ok(_) => (); Err(error) => return Err(error) }
        match checked_transform_point(transform, control2) { Ok(_) => (); Err(error) => return Err(error) }
        match checked_transform_point(transform, endpoint) { Ok(_) => (); Err(error) => return Err(error) }
      }
      Some(@math.PathCommand::Close) | None => ()
    }
  }
  Ok(())
}

fn checked_rect_path(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rx_in : Double,
  ry_in : Double,
) -> Result[@math.Path2, @error.CoreError] {
  let p = @math.Path2::new()
  if rx_in <= 0.0 && ry_in <= 0.0 {
    let x1 = x + w
    let y1 = y + h
    p.push(@math.PathCommand::MoveTo(@math.Point2::new(x, y)))
    p.push(@math.PathCommand::LineTo(@math.Point2::new(x1, y)))
    p.push(@math.PathCommand::LineTo(@math.Point2::new(x1, y1)))
    p.push(@math.PathCommand::LineTo(@math.Point2::new(x, y1)))
    p.push(@math.PathCommand::Close)
    return Ok(p)
  }
  let rx0 = if rx_in <= 0.0 { ry_in } else { rx_in }
  let ry0 = if ry_in <= 0.0 { rx_in } else { ry_in }
  let max_rx = match geometry_div(w, 2.0) { Ok(value) => value; Err(error) => return Err(error) }
  let max_ry = match geometry_div(h, 2.0) { Ok(value) => value; Err(error) => return Err(error) }
  let mut rx = if rx0 > max_rx { max_rx } else { rx0 }
  let mut ry = if ry0 > max_ry { max_ry } else { ry0 }
  if rx > 0.0 {
    let ratio = match geometry_div(max_rx, rx) { Ok(value) => value; Err(error) => return Err(error) }
    if ratio < 1.0 { ry = match geometry_mul(ry, ratio) { Ok(value) => value; Err(error) => return Err(error) } }
    let ratio_y = match geometry_div(max_ry, ry) { Ok(value) => value; Err(error) => return Err(error) }
    if ratio_y < 1.0 { rx = match geometry_mul(rx, ratio_y) { Ok(value) => value; Err(error) => return Err(error) } }
  }
  let kx = match geometry_mul(rx, 0.5522847498307936) { Ok(value) => value; Err(error) => return Err(error) }
  let ky = match geometry_mul(ry, 0.5522847498307936) { Ok(value) => value; Err(error) => return Err(error) }
  let x1 = x + w
  let y1 = y + h
  let x_rx = x + rx
  let x1_rx = x1 - rx
  let y1_ry = y1 - ry
  let y_ky = y + ky
  let x1_kx = x1 - kx
  let y1_ky = y1 - ky
  let x0_kx = x + kx
  let y0_ry = y + ry
  p.push(@math.PathCommand::MoveTo(@math.Point2::new(x_rx, y)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x1_rx, y)))
  p.push(@math.PathCommand::CubicTo(@math.Point2::new(x1_kx, y), @math.Point2::new(x1, y_ky), @math.Point2::new(x1, y0_ry)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x1, y1_ry)))
  p.push(@math.PathCommand::CubicTo(@math.Point2::new(x1, y1_ky), @math.Point2::new(x1_kx, y1), @math.Point2::new(x1_rx, y1)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x_rx, y1)))
  p.push(@math.PathCommand::CubicTo(@math.Point2::new(x0_kx, y1), @math.Point2::new(x, y1_ky), @math.Point2::new(x, y1_ry)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x, y0_ry)))
  p.push(@math.PathCommand::CubicTo(@math.Point2::new(x, y_ky), @math.Point2::new(x0_kx, y), @math.Point2::new(x_rx, y)))
  p.push(@math.PathCommand::Close)
  Ok(p)
}

fn checked_circle_path(
  cx : Double,
  cy : Double,
  r : Double,
) -> Result[@math.Path2, @error.CoreError] {
  checked_ellipse_path(cx, cy, r, r)
}

fn checked_ellipse_path(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
) -> Result[@math.Path2, @error.CoreError] {
  let p = @math.Path2::new()
  let step = match geometry_div(6.283185307179586, 32.0) { Ok(value) => value; Err(error) => return Err(error) }
  for i = 0; i < 32; i = i + 1 {
    let angle = match geometry_mul(step, i.to_double()) { Ok(value) => value; Err(error) => return Err(error) }
    let cos_angle = match admit_derived(@math.cos(angle)) { Ok(value) => value; Err(error) => return Err(error) }
    let sin_angle = match admit_derived(@math.sin(angle)) { Ok(value) => value; Err(error) => return Err(error) }
    let x_delta = match geometry_mul(rx, cos_angle) { Ok(value) => value; Err(error) => return Err(error) }
    let y_delta = match geometry_mul(ry, sin_angle) { Ok(value) => value; Err(error) => return Err(error) }
    let x = cx + x_delta
    let y = cy + y_delta
    let point = @math.Point2::new(x, y)
    if i == 0 {
      p.push(@math.PathCommand::MoveTo(point))
    } else {
      p.push(@math.PathCommand::LineTo(point))
    }
  }
  p.push(@math.PathCommand::Close)
  Ok(p)
}

fn checked_line_path(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Result[@math.Path2, @error.CoreError] {
  let p = @math.Path2::new()
  p.push(@math.PathCommand::MoveTo(@math.Point2::new(x1, y1)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x2, y2)))
  Ok(p)
}

fn checked_polyline_path(
  points : Array[@math.Point2],
) -> Result[@math.Path2, @error.CoreError] {
  let p = @math.Path2::new()
  for i = 0; i < points.length(); i = i + 1 {
    if i == 0 {
      p.push(@math.PathCommand::MoveTo(points[i]))
    } else {
      p.push(@math.PathCommand::LineTo(points[i]))
    }
  }
  Ok(p)
}

fn checked_polygon_path(
  points : Array[@math.Point2],
) -> Result[@math.Path2, @error.CoreError] {
  let p = match checked_polyline_path(points) { Ok(value) => value; Err(error) => return Err(error) }
  p.push(@math.PathCommand::Close)
  Ok(p)
}

fn checked_canvas_path(
  path : @canvas.CanvasPath,
) -> Result[@math.Path2, @error.CoreError] {
  let path2 = path.to_path2()
  Ok(path2)
}
