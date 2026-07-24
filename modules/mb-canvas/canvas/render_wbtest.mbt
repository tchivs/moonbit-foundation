// End-to-end white-box tests for the render API: build a DrawingList, render it
// into an mb-image OwnedImage, and assert pixels. The image-construction helper
// mirrors mb-image/ops's white-box helper pattern.

fn render_wb_budget(bytes : UInt64, work : UInt64) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes~, allocations=1UL, allocation_size=bytes, width=16UL, height=16UL,
    pixels=256UL, depth=0UL, work~,
  ))
}

// A solid RGBA8 test image of the given size filled with (r,g,b,a) bytes.
fn render_wb_solid(
  width : UInt64,
  height : UInt64,
  r : Byte,
  g : Byte,
  b : Byte,
  a : Byte,
) -> @storage.OwnedImage {
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
        render_wb_budget(0UL, 0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, render_wb_budget(length, 0UL)).unwrap()
  let _ = image.with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        ignore(view.set_byte(x, y, 0, r))
        ignore(view.set_byte(x, y, 1, g))
        ignore(view.set_byte(x, y, 2, b))
        ignore(view.set_byte(x, y, 3, a))
      }
    }
    Ok(())
  })
  image
}

// Read the 4 channels of a pixel from an owned image's immutable view.
fn render_wb_pixel(
  image : @storage.OwnedImage,
  x : UInt64,
  y : UInt64,
) -> (Byte, Byte, Byte, Byte) {
  let view = image.view()
  let r = view.get_byte(x, y, 0).unwrap()
  let g = view.get_byte(x, y, 1).unwrap()
  let b = view.get_byte(x, y, 2).unwrap()
  let a = view.get_byte(x, y, 3).unwrap()
  (r, g, b, a)
}

///|
test "render fills an opaque red rectangle into a transparent RGBA8 image" {
  // 8x8 transparent image.
  let image = render_wb_solid(8UL, 8UL, b'\x00', b'\x00', b'\x00', b'\x00')
  // Fill a rectangle covering pixels [2,6)×[2,6) with opaque red.
  let path = @math.Path2::new()
  path.push(@math.PathCommand::MoveTo(@math.Point2::new(2.0, 2.0)))
  path.push(@math.PathCommand::LineTo(@math.Point2::new(6.0, 2.0)))
  path.push(@math.PathCommand::LineTo(@math.Point2::new(6.0, 6.0)))
  path.push(@math.PathCommand::LineTo(@math.Point2::new(2.0, 6.0)))
  path.push(@math.PathCommand::Close)
  let list = DrawingList::new()
  list.push_fill(path, FillStyle::new(1.0, 0.0, 0.0))
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true") // fail: render errored
    Ok(_) => ()
  }
  // Interior pixel (4,4) should be opaque red (255,0,0,255).
  let (r, g, b, a) = render_wb_pixel(image, 4UL, 4UL)
  inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(255, 0, 0, 255)")
  // Exterior pixel (0,0) should remain transparent.
  let (r0, g0, b0, a0) = render_wb_pixel(image, 0UL, 0UL)
  inspect((r0.to_int(), g0.to_int(), b0.to_int(), a0.to_int()), content="(0, 0, 0, 0)")
}

///|
test "render leaves pixels outside the path untouched" {
  let image = render_wb_solid(8UL, 8UL, b'\x10', b'\x20', b'\x30', b'\xff')
  // A small rectangle in the center.
  let path = CanvasPath::new()
  path.rect(3.0, 3.0, 2.0, 2.0)
  let list = DrawingList::new()
  list.push_fill(path.to_path2(), FillStyle::new(0.0, 1.0, 0.0))
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  // Corner (0,0) keeps its original color.
  let (r, g, b, a) = render_wb_pixel(image, 0UL, 0UL)
  inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(16, 32, 48, 255)")
  // Center (4,4) is inside the 2x2 rect → green.
  let (r2, g2, b2, _) = render_wb_pixel(image, 4UL, 4UL)
  inspect((r2.to_int(), g2.to_int(), b2.to_int()), content="(0, 255, 0)")
}

///|
test "render of an empty list is a no-op" {
  let image = render_wb_solid(4UL, 4UL, b'\xaa', b'\xbb', b'\xcc', b'\xdd')
  let list = DrawingList::new()
  match render(list, image, render_wb_budget(256UL, 256UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  let (r, g, b, a) = render_wb_pixel(image, 0UL, 0UL)
  inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(170, 187, 204, 221)")
}

///|
test "render strokes a horizontal line segment" {
  // 8x8 transparent image. Stroke a horizontal line from (2,4) to (6,4) with
  // width 2. The stroke band should cover roughly y in [3,5].
  let image = render_wb_solid(8UL, 8UL, b'\x00', b'\x00', b'\x00', b'\x00')
  let path = CanvasPath::new()
  path.move_to(2.0, 4.0)
  path.line_to(6.0, 4.0)
  let stroke = { ..StrokeStyle::new(2.0), cap: LineCap::Butt }
  let list = DrawingList::new()
  list.push_stroke(path.to_path2(), stroke, FillStyle::new(1.0, 1.0, 1.0))
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  // A pixel on the line (4,4) should be lit (white, high alpha).
  let (_, _, _, a_center) = render_wb_pixel(image, 4UL, 4UL)
  inspect(a_center.to_int() > 200, content="true")
  // A pixel well above the line (4,0) should be untouched.
  let (_, _, _, a_above) = render_wb_pixel(image, 4UL, 0UL)
  inspect(a_above.to_int(), content="0")
  // A pixel well below the line (4,7) should be untouched.
  let (_, _, _, a_below) = render_wb_pixel(image, 4UL, 7UL)
  inspect(a_below.to_int(), content="0")
}

///|
test "render strokes a closed rectangle outline" {
  // 8x8 image. Stroke a 4x4 rectangle outline from (2,2) to (6,6), width 1.
  let image = render_wb_solid(8UL, 8UL, b'\x00', b'\x00', b'\x00', b'\x00')
  let path = CanvasPath::new()
  path.rect(2.0, 2.0, 4.0, 4.0)
  let list = DrawingList::new()
  list.push_stroke(path.to_path2(), StrokeStyle::new(1.0), FillStyle::new(0.0, 0.0, 0.0))
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  // On the outline (4,2) top edge → lit.
  let (_, _, _, a_edge) = render_wb_pixel(image, 4UL, 2UL)
  inspect(a_edge.to_int() > 0, content="true")
  // Inside the rectangle (4,4) → not stroked (stroke only the outline).
  let (_, _, _, a_in) = render_wb_pixel(image, 4UL, 4UL)
  inspect(a_in.to_int(), content="0")
}

///|
test "render round cap extends past the line endpoint" {
  // 12x12 transparent image. Stroke a horizontal line from (4,6) to (8,6)
  // width 3 with round caps. The round cap extends past x=8 by half=1.5 toward
  // x≈9.5, so pixel (9,6) (inside the cap arc, past the butt stop) should be lit.
  let image = render_wb_solid(12UL, 12UL, b'\x00', b'\x00', b'\x00', b'\x00')
  let path = CanvasPath::new()
  path.move_to(4.0, 6.0)
  path.line_to(8.0, 6.0)
  let round_stroke = { ..StrokeStyle::new(3.0), cap: LineCap::Round }
  let list = DrawingList::new()
  list.push_stroke(path.to_path2(), round_stroke, FillStyle::new(1.0, 1.0, 1.0))
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  // Center on the line → lit.
  let (_, _, _, a_center) = render_wb_pixel(image, 6UL, 6UL)
  inspect(a_center.to_int() > 200, content="true")
  // Past the endpoint at x=9 (round cap bulge reaches ~9.5). Butt cap would
  // leave this empty; round cap should partially cover it.
  let (_, _, _, a_cap) = render_wb_pixel(image, 9UL, 6UL)
  inspect(a_cap.to_int() > 0, content="true")
  // Far past at x=11 → definitely outside even the round cap.
  let (_, _, _, a_far) = render_wb_pixel(image, 11UL, 6UL)
  inspect(a_far.to_int(), content="0")
}

///|
test "render dash pattern produces on/off gaps" {
  // 12x4 transparent image. Stroke a horizontal line from (1,2) to (11,2)
  // width 1 with dash [2,2] (draw 2, skip 2). Expected on-segments near
  // x=[1,3] and x=[5,7] and x=[9,11]; off-gaps near x=[3,5] and x=[7,9].
  let image = render_wb_solid(12UL, 4UL, b'\x00', b'\x00', b'\x00', b'\x00')
  let path = CanvasPath::new()
  path.move_to(1.0, 2.0)
  path.line_to(11.0, 2.0)
  let dashed = { ..StrokeStyle::new(1.0), dash: [2.0, 2.0] }
  let list = DrawingList::new()
  list.push_stroke(path.to_path2(), dashed, FillStyle::new(1.0, 1.0, 1.0))
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  // On-segment center (x=2) → lit.
  let (_, _, _, a_on) = render_wb_pixel(image, 2UL, 2UL)
  inspect(a_on.to_int() > 0, content="true")
  // Off-gap center (x=4) → not lit.
  let (_, _, _, a_off) = render_wb_pixel(image, 4UL, 2UL)
  inspect(a_off.to_int(), content="0")
  // Second on-segment (x=6) → lit.
  let (_, _, _, a_on2) = render_wb_pixel(image, 6UL, 2UL)
  inspect(a_on2.to_int() > 0, content="true")
  // Second off-gap (x=8) → not lit.
  let (_, _, _, a_off2) = render_wb_pixel(image, 8UL, 2UL)
  inspect(a_off2.to_int(), content="0")
}

///|
test "render round join fills the convex corner of an L-bend" {
  // 12x12 transparent image. Stroke an L-bend: (3,3)→(3,8)→(8,8), width 3.
  // At the corner (3,8) the convex side is the lower-right (outside the L).
  // A round join fills the arc there; a bevel/miter leaves a sharp/flat corner.
  // Pixel (5,7) sits in the convex-corner arc region (diagonal from the vertex,
  // outside the stroke band of either leg but inside the round-join fillet).
  let image = render_wb_solid(12UL, 12UL, b'\x00', b'\x00', b'\x00', b'\x00')
  let path = CanvasPath::new()
  path.move_to(3.0, 3.0)
  path.line_to(3.0, 8.0)
  path.line_to(8.0, 8.0)
  let round_join = { ..StrokeStyle::new(3.0), join: LineJoin::Round, cap: LineCap::Butt }
  let list = DrawingList::new()
  list.push_stroke(path.to_path2(), round_join, FillStyle::new(1.0, 1.0, 1.0))
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  // On the vertical leg (3,5) → lit.
  let (_, _, _, a_leg) = render_wb_pixel(image, 3UL, 5UL)
  inspect(a_leg.to_int() > 0, content="true")
  // Convex corner arc region (5,7): round join fills it; bevel would leave it empty.
  let (_, _, _, a_corner) = render_wb_pixel(image, 5UL, 7UL)
  inspect(a_corner.to_int() > 0, content="true")
}

///|
test "render applies a translate transform to the fill" {
  // 8x8 transparent image. A unit rect at (0,0) translated by (3,3) should land
  // at pixel (3,3).
  let image = render_wb_solid(8UL, 8UL, b'\x00', b'\x00', b'\x00', b'\x00')
  let path = CanvasPath::new()
  path.rect(0.0, 0.0, 1.0, 1.0)
  let list = DrawingList::new()
  list.push_transform(@math.Affine2::translate(3.0, 3.0))
  list.push_fill(path.to_path2(), FillStyle::new(1.0, 0.0, 0.0))
  list.pop_transform()
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  // The translated rect covers pixel (3,3).
  let (_, _, _, a_at) = render_wb_pixel(image, 3UL, 3UL)
  inspect(a_at.to_int() > 200, content="true")
  // The original location (0,0) is empty.
  let (_, _, _, a_origin) = render_wb_pixel(image, 0UL, 0UL)
  inspect(a_origin.to_int(), content="0")
}

///|
test "render clip confines the fill to the clip rectangle" {
  // 8x8 transparent image. Fill a 6x6 rect from (1,1), but clip to (3,3)-(5,5).
  // Only pixels inside the clip should be lit.
  let image = render_wb_solid(8UL, 8UL, b'\x00', b'\x00', b'\x00', b'\x00')
  let path = CanvasPath::new()
  path.rect(1.0, 1.0, 6.0, 6.0)
  let list = DrawingList::new()
  list.push_clip(@math.Rect2::new(3.0, 3.0, 2.0, 2.0))
  list.push_fill(path.to_path2(), FillStyle::new(0.0, 1.0, 0.0))
  list.pop_clip()
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  // Inside clip (3,3) → lit.
  let (_, _, _, a_in_clip) = render_wb_pixel(image, 3UL, 3UL)
  inspect(a_in_clip.to_int() > 0, content="true")
  // Inside the fill rect but outside the clip (1,1) → not lit.
  let (_, _, _, a_out_clip) = render_wb_pixel(image, 1UL, 1UL)
  inspect(a_out_clip.to_int(), content="0")
}

///|
test "render transform push/pop isolates state" {
  // 8x8 transparent image. Fill under a translate, pop it, then fill again
  // without transform — the second fill should land at its untransformed place.
  let image = render_wb_solid(8UL, 8UL, b'\x00', b'\x00', b'\x00', b'\x00')
  let path_a = CanvasPath::new()
  path_a.rect(0.0, 0.0, 1.0, 1.0)
  let path_b = CanvasPath::new()
  path_b.rect(5.0, 5.0, 1.0, 1.0)
  let list = DrawingList::new()
  list.push_transform(@math.Affine2::translate(2.0, 0.0))
  list.push_fill(path_a.to_path2(), FillStyle::new(1.0, 0.0, 0.0))
  list.pop_transform()
  // No transform now: path_b lands at (5,5) unmodified.
  list.push_fill(path_b.to_path2(), FillStyle::new(0.0, 0.0, 1.0))
  match render(list, image, render_wb_budget(65536UL, 65536UL)) {
    Err(_) => inspect(false, content="true")
    Ok(_) => ()
  }
  // First fill translated by (2,0) → pixel (2,0) lit.
  let (_, _, _, a_first) = render_wb_pixel(image, 2UL, 0UL)
  inspect(a_first.to_int() > 0, content="true")
  // Second fill at (5,5) unmodified → lit.
  let (_, _, _, a_second) = render_wb_pixel(image, 5UL, 5UL)
  inspect(a_second.to_int() > 0, content="true")
  // (0,0) should be empty: first fill was translated away, second is at (5,5).
  let (_, _, _, a_origin) = render_wb_pixel(image, 0UL, 0UL)
  inspect(a_origin.to_int(), content="0")
}

