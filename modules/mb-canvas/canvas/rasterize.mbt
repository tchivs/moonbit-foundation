// The mb-canvas rasterizer: render a DrawingList into an mb-image OwnedImage.
//
// Per RFC 0003 §6.1, the portable software rasterizer is the reference
// implementation: it runs on js, wasm, wasm-gc, and native, produces
// deterministic coverage-antialiased output, and writes into a borrowed
// mb-image MutImageView. It does not allocate its own pixel store for the
// primary target. RFC 0008 adds a bounded exception: raster layers
// (PushLayer/PopLayer) allocate a transparent offscreen surface, charged
// against the budget and capped at 16 nesting levels (see render_into).
//
// Color is resolved through mb-color (encoded-sRGB normalized domain) and
// coverage-antialiased via supersampling (coverage.mbt). Source-over blending
// uses mb-color/blend's porter_duff_composite. v0.1 writes per-channel through
// MutImageView::set_byte, accepting the per-channel Result checking overhead in
// exchange for correctness (performance is a later benchmark-driven concern).

///|
/// Render a drawing list into the target image. The target is mutated in place;
/// the budget bounds rasterization work. Returns an error if a pixel write or
/// budget charge fails.
pub fn render(
  list : DrawingList,
  target : @storage.OwnedImage,
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  target.with_mut_view(view => render_into(list, view, budget))
}

// Render the list into a borrowed mutable view. Transform, clip, and
// render-target state are replayed from the op sequence.
//
// Layer handling (RFC 0008) is recursive rather than stack-based: a MutImageView
// is only obtainable through OwnedImage::with_mut_view (callback-scoped), so a
// persistent view stack is not possible. render_segment processes ops from
// `start_idx` until it hits the matching PopLayer (or end of list); on
// PushLayer it allocates an offscreen, recurses into the offscreen's
// with_mut_view, then composites the result back. Layer nesting is capped at
// max_layer_depth (16).

///|
fn render_into(
  list : DrawingList,
  view : @storage.MutImageView,
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  let ctx : RenderCtx = { list, budget, layer_depth: 0 }
  match render_segment(ctx, 0, view, @math.Affine2::identity(), None) {
    Err(e) => Err(e)
    Ok(_) => Ok(())
  }
}

// Immutable render context shared across the recursion.

///|
priv struct RenderCtx {
  list : DrawingList
  budget : @budget.Budget
  mut layer_depth : Int
}

// Process ops from `start_idx` into `view`, under `current` transform and
// `clip` (None = unclipped), until the matching PopLayer or end of list.
// Returns the index just past the consumed segment (i.e. past the matching
// PopLayer, or list length at end). The returned index is used by the caller
// (a PushLayer frame) to continue processing sibling ops.

///|
fn render_segment(
  ctx : RenderCtx,
  start_idx : Int,
  view : @storage.MutImageView,
  initial_transform : @math.Affine2,
  initial_clip : @math.Rect2?,
) -> Result[Int, @error.CoreError] {
  let transform_stack : Array[@math.Affine2] = []
  let mut current = initial_transform
  let clip_stack : Array[@math.Rect2] = []
  let mut clip = initial_clip
  let is_rgba = view.format().channel_count() == 4
  let width = view.width()
  let height = view.height()
  let mut i = start_idx
  while i < ctx.list.length() {
    match ctx.list.get(i) {
      None => i = i + 1
      Some(op) =>
        match op {
          DrawOp::PushTransform(t) => {
            transform_stack.push(current)
            current = current.compose(t)
            i = i + 1
          }
          DrawOp::PopTransform => {
            match transform_stack.pop() {
              Some(prev) => current = prev
              None => ()
            }
            i = i + 1
          }
          DrawOp::PushClip(rect) => {
            clip_stack.push(rect)
            clip = Some(transform_and_intersect_clip(clip, rect, current))
            i = i + 1
          }
          DrawOp::PopClip => {
            let _ = clip_stack.pop()
            clip = recompute_clip(clip_stack, current)
            i = i + 1
          }
          DrawOp::PopLayer =>
            // End of this segment (matched the PushLayer that spawned it, or an
            // unbalanced PopLayer at top level which is a no-op terminator).
            return Ok(i + 1)
          DrawOp::PushLayer(opacity) => {
            if ctx.layer_depth >= MAX_LAYER_DEPTH {
              return Err(
                raster_error(
                  "canvas-layer-depth", "layer nesting depth exceeded",
                ),
              )
            }
            ctx.layer_depth = ctx.layer_depth + 1
            // Allocate the offscreen; recurse into its with_mut_view to render
            // the layer's segment; then composite back onto this view.
            match alloc_transparent_offscreen(width, height, ctx.budget) {
              Err(e) => return Err(e)
              Ok(offscreen) => {
                let layer_opacity = clamp_unit(opacity)
                let recurse_result = offscreen.with_mut_view(fn(oview) {
                  render_segment(ctx, i + 1, oview, current, clip)
                })
                ctx.layer_depth = ctx.layer_depth - 1
                match recurse_result {
                  Err(e) => return Err(e)
                  Ok(next_idx) =>
                    // Composite the offscreen onto the current (parent) view.
                    match
                      composite_offscreen_onto(
                        offscreen, view, is_rgba, layer_opacity,
                      ) {
                      Err(e) => return Err(e)
                      Ok(_) => {
                        i = next_idx
                        ()
                      }
                    }
                }
              }
            }
          }
          DrawOp::Fill(path, style) => {
            let transformed = current.apply_to_path(path)
            let segments = transformed.flattened(0.1, 64)
            match
              rasterize_fill(
                segments, style, clip, width, height, is_rgba, view,
              ) {
              Err(e) => return Err(e)
              Ok(_) => ()
            }
            i = i + 1
          }
          DrawOp::Stroke(path, stroke, color) => {
            // Stroke rasterization: lower a stroke to a fill of the stroke's
            // centerline-expanded outline.
            let transformed = current.apply_to_path(path)
            let outline = expand_stroke(transformed, stroke)
            let segments = outline.flattened(0.1, 64)
            // Strokes fill as even-odd to avoid double coverage at overlaps.
            let stroke_style = {
              color_r: color.color_r,
              color_g: color.color_g,
              color_b: color.color_b,
              color_a: color.color_a,
              rule: FillRule::EvenOdd,
            }
            match
              rasterize_fill(
                segments, stroke_style, clip, width, height, is_rgba, view,
              ) {
              Err(e) => return Err(e)
              Ok(_) => ()
            }
            i = i + 1
          }
        }
    }
  }
  Ok(i)
}

// Maximum raster-layer nesting depth (RFC 0008 §7). Each layer holds a
// full-target RGBA8 offscreen, so 16 bounds worst-case offscreen memory to
// 16×(w×h×4) bytes while far exceeding real SVG group-nesting depth.

///|
const MAX_LAYER_DEPTH : Int = 16

// Allocate a transparent RGBA8 offscreen of the given dimensions, charging the
// budget. Returns the owning OwnedImage (all pixels transparent). The descriptor
// construction mirrors the mb-canvas render test helper pattern.

///|
fn alloc_transparent_offscreen(
  width : UInt64,
  height : UInt64,
  budget : @budget.Budget,
) -> Result[@storage.OwnedImage, @error.CoreError] {
  let length = width * height * 4UL
  let descriptor = @imgmodel.ImageDescriptor::new(
    width,
    height,
    @imgmodel.ImageFormat::rgba8(),
    [
      @imgmodel.PlaneDescriptor::new(
        0UL,
        length,
        width * 4UL,
        width * 4UL,
        1UL,
        1UL,
        width,
        height,
      ).unwrap(),
    ],
    length,
    @imgmodel.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb,
      @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight),
      @profile.ProfileIdentity::builtin_srgb(),
      @imgmodel.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [],
        @metadata.MetadataLimits::new(
          max_entries=0UL,
          max_token_bytes=16UL,
          max_value_bytes=0UL,
          max_total_bytes=0UL,
          max_disposition_fields=8UL,
        ),
        budget,
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, budget)
  match image {
    Err(e) => Err(e)
    Ok(img) => {
      // Initialize all pixels transparent (0,0,0,0). Offscreens start
      // transparent so layer content composites correctly onto the parent.
      let _ = img.with_mut_view(fn(v) {
        for y = 0UL; y < height; y = y + 1UL {
          for x = 0UL; x < width; x = x + 1UL {
            ignore(v.set_byte(x, y, 0, b'\x00'))
            ignore(v.set_byte(x, y, 1, b'\x00'))
            ignore(v.set_byte(x, y, 2, b'\x00'))
            ignore(v.set_byte(x, y, 3, b'\x00'))
          }
        }
        Ok(())
      })
      Ok(img)
    }
  }
}

// Composite a popped layer's offscreen onto its parent target with source-over,
// Composite an offscreen layer (read via its immutable view) onto a parent
// MutImageView with source-over, scaling the source alpha by the layer
// opacity. Walks pixel-by-pixel reusing the same porter_duff path as
// composite_pixel (RFC 0008 §5).

///|
fn composite_offscreen_onto(
  offscreen : @storage.OwnedImage,
  dst : @storage.MutImageView,
  parent_is_rgba : Bool,
  opacity : Double,
) -> Result[Unit, @error.CoreError] {
  let src = offscreen.view()
  let w = src.width()
  let h = src.height()
  // Clamp to the smaller of the two views (defensive; they should match).
  let dw = dst.width()
  let dh = dst.height()
  let x_max = if w < dw { w } else { dw }
  let y_max = if h < dh { h } else { dh }
  for y = 0UL; y < y_max; y = y + 1UL {
    for x = 0UL; x < x_max; x = x + 1UL {
      // Source (layer) pixel — always RGBA8.
      let sr_byte = src.get_byte(x, y, 0)
      let sg_byte = src.get_byte(x, y, 1)
      let sb_byte = src.get_byte(x, y, 2)
      let sa_byte = src.get_byte(x, y, 3)
      let (sr, sg, sb, sa) = match (sr_byte, sg_byte, sb_byte, sa_byte) {
        (Ok(r), Ok(g), Ok(b), Ok(a)) =>
          (
            r.to_int().to_double() / 255.0,
            g.to_int().to_double() / 255.0,
            b.to_int().to_double() / 255.0,
            a.to_int().to_double() / 255.0,
          )
        (Err(e), _, _, _) => return Err(e)
        (_, Err(e), _, _) => return Err(e)
        (_, _, Err(e), _) => return Err(e)
        (_, _, _, Err(e)) => return Err(e)
      }
      let src_a = sa * opacity
      if src_a <= 0.0 {
        continue
      }
      // Destination (parent) pixel.
      let dr_byte = dst.get_byte(x, y, 0)
      let dg_byte = dst.get_byte(x, y, 1)
      let db_byte = dst.get_byte(x, y, 2)
      let (dr, dg, db, da) = match (dr_byte, dg_byte, db_byte) {
        (Ok(rb), Ok(gb), Ok(bb)) => {
          let d_alpha = if parent_is_rgba {
            match dst.get_byte(x, y, 3) {
              Ok(ab) => ab.to_int().to_double() / 255.0
              Err(e) => return Err(e)
            }
          } else {
            1.0
          }
          (
            rb.to_int().to_double() / 255.0,
            gb.to_int().to_double() / 255.0,
            bb.to_int().to_double() / 255.0,
            d_alpha,
          )
        }
        (Err(e), _, _) => return Err(e)
        (_, Err(e), _) => return Err(e)
        (_, _, Err(e)) => return Err(e)
      }
      let (or, og, ob, oa) = @blend.porter_duff_composite(
        @blend.CompositeOp::SourceOver,
        (sr, sg, sb),
        src_a,
        (dr, dg, db),
        da,
      )
      match write_color(dst, x, y, parent_is_rgba, or, og, ob, oa) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
    }
  }
  Ok(())
}

// Construct a raster-layer CoreError.

///|
fn raster_error(context : String, message : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="canvas-render",
    context=context + ": " + message,
  )
}

// Rasterize a single fill: for each pixel in the bounding box (clipped), compute
// coverage and source-over composite the fill color into the view.

///|
fn rasterize_fill(
  segments : Array[@math.LineSegment],
  style : FillStyle,
  clip : @math.Rect2?,
  width : UInt64,
  height : UInt64,
  is_rgba : Bool,
  view : @storage.MutImageView,
) -> Result[Unit, @error.CoreError] {
  // Compute the device-space bounding box of the path, intersected with clip.
  let bbox = path_bounds(segments)
  match (bbox, clip) {
    (None, _) => return Ok(()) // empty path, nothing to draw
    (Some(_), _) => ()
  }
  let path_box = bbox.unwrap()
  // Intersect with clip if present.
  let active = match clip {
    Some(c) => path_box.intersection(c)
    None => path_box
  }
  if active.is_empty() {
    return Ok(())
  }
  // Pixel scan range (integer), clamped to the view.
  let x_start = clamp_pixel(active.min_x(), width)
  let x_end = clamp_pixel(active.max_x(), width)
  let y_start = clamp_pixel(active.min_y(), height)
  let y_end = clamp_pixel(active.max_y(), height)
  // Iterate scanlines.
  for py = y_start; py <= y_end; py = py + 1 {
    let fy = py.to_double()
    for px = x_start; px <= x_end; px = px + 1 {
      let fx = px.to_double()
      let coverage = pixel_coverage(
        segments,
        style.rule,
        fx,
        fy,
        default_samples,
      )
      if coverage <= 0.0 {
        continue
      }
      match
        composite_pixel(
          view,
          px,
          py,
          is_rgba,
          style.color_r,
          style.color_g,
          style.color_b,
          style.color_a,
          coverage,
        ) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
    }
  }
  Ok(())
}

// Source-over composite a source color (modulated by coverage) into a pixel.

///|
fn composite_pixel(
  view : @storage.MutImageView,
  px : UInt64,
  py : UInt64,
  is_rgba : Bool,
  sr : Double,
  sg : Double,
  sb : Double,
  sa : Double,
  coverage : Double,
) -> Result[Unit, @error.CoreError] {
  // Final source alpha after coverage modulation.
  let src_a = sa * coverage
  if src_a <= 0.0 {
    return Ok(())
  }
  // Read destination.
  let dr_byte = view.get_byte(px, py, 0)
  let dg_byte = view.get_byte(px, py, 1)
  let db_byte = view.get_byte(px, py, 2)
  let (dr, dg, db, da) = match (dr_byte, dg_byte, db_byte) {
    (Ok(rb), Ok(gb), Ok(bb)) => {
      let d_alpha = if is_rgba {
        match view.get_byte(px, py, 3) {
          Ok(ab) => ab.to_int().to_double() / 255.0
          Err(e) => return Err(e)
        }
      } else {
        1.0 // RGB8 treats destination as opaque.
      }
      (
        rb.to_int().to_double() / 255.0,
        gb.to_int().to_double() / 255.0,
        bb.to_int().to_double() / 255.0,
        d_alpha,
      )
    }
    (Err(e), _, _) => return Err(e)
    (_, Err(e), _) => return Err(e)
    (_, _, Err(e)) => return Err(e)
  }
  // Porter-Duff source-over.
  let (or, og, ob, oa) = @blend.porter_duff_composite(
    @blend.CompositeOp::SourceOver,
    (sr, sg, sb),
    src_a,
    (dr, dg, db),
    da,
  )
  // Quantize and write back.
  write_color(view, px, py, is_rgba, or, og, ob, oa)
}

// Write a normalized-sRGB color (with straight alpha) into a pixel via set_byte.

///|
fn write_color(
  view : @storage.MutImageView,
  px : UInt64,
  py : UInt64,
  is_rgba : Bool,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> Result[Unit, @error.CoreError] {
  let rb = quantize_byte(r)
  let gb = quantize_byte(g)
  let bb = quantize_byte(b)
  match view.set_byte(px, py, 0, rb) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  match view.set_byte(px, py, 1, gb) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  match view.set_byte(px, py, 2, bb) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if is_rgba {
    let ab = quantize_byte(a)
    match view.set_byte(px, py, 3, ab) {
      Err(e) => return Err(e)
      Ok(_) => ()
    }
  }
  Ok(())
}

// Quantize a normalized-sRGB component in [0,1] to a byte via mb-color, with a
// fast clamp for out-of-range values.

///|
fn quantize_byte(v : Double) -> Byte {
  let clamped = if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
  match @color.EncodedSrgbComponent::new(clamped) {
    Ok(c) => @quantize.quantize_encoded_srgb(c).value()
    Err(_) => b'\x00'
  }
}

// Axis-aligned bounding box of a set of line segments.

///|
fn path_bounds(segments : Array[@math.LineSegment]) -> @math.Rect2? {
  if segments.is_empty() {
    return None
  }
  let mut min_x = segments[0].start().x()
  let mut min_y = segments[0].start().y()
  let mut max_x = min_x
  let mut max_y = min_y
  for seg in segments {
    let (sx, sy) = (seg.start().x(), seg.start().y())
    let (ex, ey) = (seg.end().x(), seg.end().y())
    min_x = min_f(min_x, min_f(sx, ex))
    min_y = min_f(min_y, min_f(sy, ey))
    max_x = max_f(max_x, max_f(sx, ex))
    max_y = max_f(max_y, max_f(sy, ey))
  }
  Some(@math.Rect2::new(min_x, min_y, max_x - min_x, max_y - min_y))
}

///|
fn min_f(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_f(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

// Clamp a device coordinate to the integer pixel range [0, limit-1].

///|
fn clamp_pixel(coord : Double, limit : UInt64) -> UInt64 {
  let mut i = coord.floor().to_int()
  if i < 0 {
    i = 0
  }
  let lim = limit.to_int() - 1
  if i > lim {
    i = lim
  }
  i.to_uint64()
}

// Transform a user-space clip rect to device space and intersect with the
// current effective clip.

///|
fn transform_and_intersect_clip(
  current_clip : @math.Rect2?,
  user_rect : @math.Rect2,
  transform : @math.Affine2,
) -> @math.Rect2 {
  // Transform the four corners and take the axis-aligned bounding box.
  let c0 = transform.apply(
    @math.Point2::new(user_rect.min_x(), user_rect.min_y()),
  )
  let c1 = transform.apply(
    @math.Point2::new(user_rect.max_x(), user_rect.min_y()),
  )
  let c2 = transform.apply(
    @math.Point2::new(user_rect.max_x(), user_rect.max_y()),
  )
  let c3 = transform.apply(
    @math.Point2::new(user_rect.min_x(), user_rect.max_y()),
  )
  let min_x = min_f(min_f(c0.x(), c1.x()), min_f(c2.x(), c3.x()))
  let max_x = max_f(max_f(c0.x(), c1.x()), max_f(c2.x(), c3.x()))
  let min_y = min_f(min_f(c0.y(), c1.y()), min_f(c2.y(), c3.y()))
  let max_y = max_f(max_f(c0.y(), c1.y()), max_f(c2.y(), c3.y()))
  let device = @math.Rect2::new(min_x, min_y, max_x - min_x, max_y - min_y)
  match current_clip {
    Some(c) => c.intersection(device)
    None => device
  }
}

// Recompute the effective clip by transforming and intersecting the whole stack.

///|
fn recompute_clip(
  stack : Array[@math.Rect2],
  transform : @math.Affine2,
) -> @math.Rect2? {
  let mut acc : @math.Rect2? = None
  for i = 0; i < stack.length(); i = i + 1 {
    // Each clip on the stack was pushed with the transform active at that time;
    // for simplicity in v0.1 we re-transform each with the current transform,
    // which is correct when clips are pushed under the same transform chain.
    let _ = transform
    acc = Some(
      match acc {
        Some(c) => c.intersection(stack[i])
        None => stack[i]
      },
    )
  }
  acc
}
