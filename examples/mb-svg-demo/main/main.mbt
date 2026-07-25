// mb-svg end-to-end demo: SVG source → parse → scene → lower → render → pixels.
//
// Exercises the full RFC 0002 Phase A → Phase B chain against the mb-canvas
// software rasterizer and an mb-image RGBA8 surface. Kept as an example (not a
// mb-svg test) so the heavy mb-image descriptor/metadata scaffolding stays out
// of mb-svg's package boundary, per RFC 0002 §4.2. The image-construction
// helpers mirror mb-canvas's render_wbtest pattern.
//
// Runs on js, wasm, wasm-gc, and native (no target-specific code).

// ---------------------------------------------------------------------------
// Image / budget scaffolding (mirrors mb-canvas/canvas/render_wbtest.mbt)
// ---------------------------------------------------------------------------

fn demo_budget(bytes : UInt64, work : UInt64) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes~,
    allocations=1UL,
    allocation_size=bytes,
    width=16UL,
    height=16UL,
    pixels=256UL,
    depth=0UL,
    work~,
  ))
}

// A solid RGBA8 test image of the given size filled with (r,g,b,a) bytes.
fn demo_solid(
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
        demo_budget(0UL, 0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, demo_budget(length, 0UL)).unwrap()
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
fn demo_pixel(
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

// ---------------------------------------------------------------------------
// End-to-end: SVG → DrawingList → rendered RGBA8 pixels
// ---------------------------------------------------------------------------

fn run_case(
  label : String,
  svg_source : String,
  width : UInt64,
  height : UInt64,
  inside : (UInt64, UInt64),
  expected_inside : (Int, Int, Int, Int),
) -> Bool {
  // Parse SVG source into a scene tree.
  let scene = match @svg.parse_svg(svg_source) {
    Ok(s) => s
    Err(_) => {
      println(label + ": FAIL (parse_svg returned Err)")
      return false
    }
  }
  // Lower the scene tree into a canvas drawing list.
  let list = @svg.lower_to_drawing_list(scene)
  if list.length() == 0 {
    println(label + ": FAIL (drawing list is empty)")
    return false
  }
  // Render into a transparent RGBA8 image.
  let image = demo_solid(width, height, b'\x00', b'\x00', b'\x00', b'\x00')
  match @canvas.render(list, image, demo_budget(65536UL, 65536UL)) {
    Err(_) => {
      println(label + ": FAIL (render returned Err)")
      return false
    }
    Ok(_) => ()
  }
  // Assert the interior pixel matches the expected fill color.
  let (px, py) = inside
  let (r, g, b, a) = demo_pixel(image, px, py)
  let got = (r.to_int(), g.to_int(), b.to_int(), a.to_int())
  if got != expected_inside {
    println(
      label +
        ": FAIL (pixel (" +
        px.to_string() +
        "," +
        py.to_string() +
        ") = " +
        got.0.to_string() +
        "," +
        got.1.to_string() +
        "," +
        got.2.to_string() +
        "," +
        got.3.to_string() +
        ", expected " +
        expected_inside.0.to_string() +
        "," +
        expected_inside.1.to_string() +
        "," +
        expected_inside.2.to_string() +
        "," +
        expected_inside.3.to_string() +
        ")",
    )
    return false
  }
  println(label + ": OK")
  true
}

// Like run_case but renders onto a caller-specified opaque background instead
// of a transparent one. Used for opacity-compositing cases where the result
// depends on source-over blending against the backdrop.
fn run_case_on_bg(
  label : String,
  svg_source : String,
  width : UInt64,
  height : UInt64,
  bg_r : Byte,
  bg_g : Byte,
  bg_b : Byte,
  bg_a : Byte,
  inside : (UInt64, UInt64),
) -> Bool {
  let scene = match @svg.parse_svg(svg_source) {
    Ok(s) => s
    Err(_) => {
      println(label + ": FAIL (parse_svg returned Err)")
      return false
    }
  }
  let list = @svg.lower_to_drawing_list(scene)
  if list.length() == 0 {
    println(label + ": FAIL (drawing list is empty)")
    return false
  }
  let image = demo_solid(width, height, bg_r, bg_g, bg_b, bg_a)
  match @canvas.render(list, image, demo_budget(65536UL, 65536UL)) {
    Err(_) => {
      println(label + ": FAIL (render returned Err)")
      return false
    }
    Ok(_) => ()
  }
  let (px, py) = inside
  let (r, g, b, a) = demo_pixel(image, px, py)
  let got = (r.to_int(), g.to_int(), b.to_int(), a.to_int())
  // For opacity cases the exact byte depends on mb-color's sRGB quantizer, so
  // assert the invariant (alpha full, green==blue for red-over-white) rather
  // than the brittle exact tuple. Print the actual value for visibility.
  let invariant_ok = got.3 == 255 && got.1 == got.2 && got.1 > 0 && got.1 < 255
  if not(invariant_ok) {
    println(
      label +
        ": FAIL (pixel (" +
        px.to_string() +
        "," +
        py.to_string() +
        ") = " +
        got.0.to_string() +
        "," +
        got.1.to_string() +
        "," +
        got.2.to_string() +
        "," +
        got.3.to_string() +
        "; expected pink a=255, g==b in (0,255))",
    )
    return false
  }
  println(
    label +
      ": OK (pixel " +
      got.0.to_string() +
      "," +
      got.1.to_string() +
      "," +
      got.2.to_string() +
      "," +
      got.3.to_string() +
      ")",
  )
  true
}

fn main {
  // Case 1: a red rectangle covering the whole 8×8 image. Every pixel should
  // be opaque red (255,0,0,255).
  let ok1 = run_case(
    "full-canvas red rect",
    "<svg><rect width=\"8\" height=\"8\" fill=\"red\"/></svg>",
    8UL,
    8UL,
    (4UL, 4UL),
    (255, 0, 0, 255),
  )
  // Case 2: a centered 4×4 blue rectangle. Interior (4,4) is blue; corner
  // (0,0) stays transparent (0,0,0,0).
  let ok2 = run_case(
    "centered blue rect",
    "<svg><rect x=\"2\" y=\"2\" width=\"4\" height=\"4\" fill=\"blue\"/></svg>",
    8UL,
    8UL,
    (4UL, 4UL),
    (0, 0, 255, 255),
  )
  // Verify the exterior pixel of case 2 explicitly.
  let image2 = demo_solid(8UL, 8UL, b'\x00', b'\x00', b'\x00', b'\x00')
  match @svg.parse_svg("<svg><rect x=\"2\" y=\"2\" width=\"4\" height=\"4\" fill=\"blue\"/></svg>") {
    Ok(scene) => {
      let list = @svg.lower_to_drawing_list(scene)
      let _ = @canvas.render(list, image2, demo_budget(65536UL, 65536UL))
      let (r0, g0, b0, a0) = demo_pixel(image2, 0UL, 0UL)
      if (r0.to_int(), g0.to_int(), b0.to_int(), a0.to_int()) == (0, 0, 0, 0) {
        println("centered blue rect exterior: OK")
      } else {
        println("centered blue rect exterior: FAIL")
      }
    }
    Err(_) => println("centered blue rect exterior: FAIL (parse)")
  }
  // Case 3: fill-opacity compositing. A 50% opaque red rect drawn over an
  // opaque white background. Source-over of (1,0,0,0.5) over (1,1,1,1):
  //   out_a = 0.5 + 1*0.5 = 1.0
  //   out_r = (1*0.5 + 1*0.5)/1 = 1.0   → 255
  //   out_g = (0*0.5 + 1*0.5)/1 = 0.5   → mid-range (sRGB quantized)
  //   out_b = 0.5                       → mid-range
  // This proves fill-opacity flows end-to-end into real pixels, not just the
  // FillStyle field. The exact G/B byte depends on mb-color's sRGB quantizer,
  // so run_case_on_bg asserts the invariant (alpha full, green==blue in
  // (0,255) — pink, not pure red or pure white) and prints the actual value.
  let ok3 = run_case_on_bg(
    "half-opacity red over white",
    "<svg><rect width=\"8\" height=\"8\" fill=\"red\" fill-opacity=\"0.5\"/></svg>",
    8UL,
    8UL,
    b'\xff',
    b'\xff',
    b'\xff',
    b'\xff',
    (4UL, 4UL),
  )
  if ok1 && ok2 && ok3 {
    println("mb-svg end-to-end: PASS")
  } else {
    println("mb-svg end-to-end: FAIL")
  }
}
