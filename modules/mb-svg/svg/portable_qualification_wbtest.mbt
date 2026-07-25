// Portable SVG qualification: parser -> lowering -> canvas rasterization.
// Fixture literals mirror fixtures/svg/cases.json because wbtests do not load JSON.

fn qualification_budget() -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1048576UL,
    allocations=64UL,
    allocation_size=1048576UL,
    width=8UL,
    height=8UL,
    pixels=4096UL,
    depth=64UL,
    work=1048576UL,
  ))
}

fn qualification_image(r : Byte, g : Byte, b : Byte, a : Byte) -> @storage.OwnedImage {
  let length = 256UL
  let descriptor = @imgmodel.ImageDescriptor::new(
    8UL,
    8UL,
    @imgmodel.ImageFormat::rgba8(),
    [@imgmodel.PlaneDescriptor::new(0UL, length, 32UL, 32UL, 1UL, 1UL, 8UL, 8UL).unwrap()],
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
        qualification_budget(),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, qualification_budget()).unwrap()
  let _ = image.with_mut_view(fn(view) {
    for y = 0UL; y < 8UL; y = y + 1UL {
      for x = 0UL; x < 8UL; x = x + 1UL {
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

fn qualification_pixel(
  image : @storage.OwnedImage,
  x : UInt64,
  y : UInt64,
) -> (Byte, Byte, Byte, Byte) {
  let view = image.view()
  (
    view.get_byte(x, y, 0).unwrap(),
    view.get_byte(x, y, 1).unwrap(),
    view.get_byte(x, y, 2).unwrap(),
    view.get_byte(x, y, 3).unwrap(),
  )
}

///|
test "portable qualification opaque rect reaches semantic raster" {
  let source = "<svg><rect x=\"2\" y=\"2\" width=\"4\" height=\"4\" fill=\"red\"/></svg>"
  match parse_svg(source) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="1")
      match list.get(0) {
        Some(Fill(_, _)) => ()
        _ => inspect(false, content="true")
      }
      let image = qualification_image(b'\x00', b'\x00', b'\x00', b'\x00')
      match @canvas.render(list, image, qualification_budget()) {
        Err(_) => inspect(false, content="true")
        Ok(_) => ()
      }
      let (r, g, b, a) = qualification_pixel(image, 4UL, 4UL)
      inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(255, 0, 0, 255)")
      let (corner_r, corner_g, corner_b, corner_a) = qualification_pixel(image, 0UL, 0UL)
      inspect(
        (corner_r.to_int(), corner_g.to_int(), corner_b.to_int(), corner_a.to_int()),
        content="(0, 0, 0, 0)",
      )
    }
  }
}

///|
test "portable qualification preserves viewBox lowering and semantic blue raster" {
  let source = "<svg viewBox=\"0 0 4 4\" width=\"8\" height=\"8\"><rect width=\"4\" height=\"4\" fill=\"blue\"/></svg>"
  match parse_svg(source) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="3")
      match (list.get(0), list.get(1), list.get(2)) {
        (Some(PushTransform(_)), Some(Fill(_, _)), Some(PopTransform)) => ()
        _ => inspect(false, content="true")
      }
      let image = qualification_image(b'\x00', b'\x00', b'\x00', b'\x00')
      match @canvas.render(list, image, qualification_budget()) {
        Err(_) => inspect(false, content="true")
        Ok(_) => ()
      }
      let (r, g, b, a) = qualification_pixel(image, 4UL, 4UL)
      inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(0, 0, 255, 255)")
    }
  }
}

///|
test "portable qualification retains per-paint opacity without layers" {
  let source = "<svg><rect x=\"1\" y=\"1\" width=\"6\" height=\"6\" fill=\"red\" fill-opacity=\"0.5\" stroke=\"blue\" stroke-width=\"2\" stroke-opacity=\"0.5\"/></svg>"
  match parse_svg(source) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="2")
      match (list.get(0), list.get(1)) {
        (Some(Fill(_, fill)), Some(Stroke(_, _, stroke))) =>
          inspect((fill.color_a, stroke.color_a), content="(0.5, 0.5)")
        _ => inspect(false, content="true")
      }
      let image = qualification_image(b'\xff', b'\xff', b'\xff', b'\xff')
      match @canvas.render(list, image, qualification_budget()) {
        Err(_) => inspect(false, content="true")
        Ok(_) => ()
      }
      let (fill_r, fill_g, fill_b, fill_a) = qualification_pixel(image, 4UL, 4UL)
      inspect(
        (fill_r.to_int(), fill_g.to_int(), fill_b.to_int(), fill_a.to_int()),
        content="(255, 128, 128, 255)",
      )
      let (stroke_r, stroke_g, stroke_b, stroke_a) = qualification_pixel(image, 4UL, 1UL)
      inspect(
        (stroke_r.to_int(), stroke_g.to_int(), stroke_b.to_int(), stroke_a.to_int()),
        content="(128, 64, 192, 255)",
      )
    }
  }
}

///|
test "portable qualification keeps group opacity isolated" {
  let source = "<svg><g opacity=\"0.5\"><rect width=\"8\" height=\"8\" fill=\"red\"/><rect x=\"2\" y=\"2\" width=\"6\" height=\"6\" fill=\"blue\"/></g></svg>"
  match parse_svg(source) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="6")
      match (list.get(0), list.get(1), list.get(2), list.get(3), list.get(4), list.get(5)) {
        (Some(PushTransform(_)), Some(PushLayer(opacity)), Some(Fill(_, _)), Some(Fill(_, _)), Some(PopLayer), Some(PopTransform)) =>
          inspect(opacity, content="0.5")
        _ => inspect(false, content="true")
      }
      let image = qualification_image(b'\xff', b'\xff', b'\xff', b'\xff')
      match @canvas.render(list, image, qualification_budget()) {
        Err(_) => inspect(false, content="true")
        Ok(_) => ()
      }
      let (r, g, b, a) = qualification_pixel(image, 4UL, 4UL)
      inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(128, 128, 255, 255)")
    }
  }
}

///|
test "portable qualification nests group and element layers with semantic pixels" {
  let source = "<svg><g opacity=\"0.5\"><rect width=\"8\" height=\"8\" fill=\"red\" opacity=\"0.5\" stroke=\"blue\" stroke-width=\"2\"/></g></svg>"
  match parse_svg(source) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="8")
      match (list.get(0), list.get(1), list.get(2), list.get(3), list.get(4), list.get(5), list.get(6), list.get(7)) {
        (Some(PushTransform(_)), Some(PushLayer(group)), Some(PushLayer(element)), Some(Fill(_, _)), Some(Stroke(_, _, _)), Some(PopLayer), Some(PopLayer), Some(PopTransform)) =>
          inspect((group, element), content="(0.5, 0.5)")
        _ => inspect(false, content="true")
      }
      let opaque = qualification_image(b'\xff', b'\xff', b'\xff', b'\xff')
      match @canvas.render(list, opaque, qualification_budget()) {
        Err(_) => inspect(false, content="true")
        Ok(_) => ()
      }
      let (opaque_r, opaque_g, opaque_b, opaque_a) = qualification_pixel(opaque, 4UL, 4UL)
      inspect(
        (opaque_r.to_int(), opaque_g.to_int(), opaque_b.to_int(), opaque_a.to_int()),
        content="(255, 191, 191, 255)",
      )
      let transparent = qualification_image(b'\x00', b'\x00', b'\x00', b'\x00')
      match @canvas.render(list, transparent, qualification_budget()) {
        Err(_) => inspect(false, content="true")
        Ok(_) => ()
      }
      let (transparent_r, transparent_g, transparent_b, transparent_a) = qualification_pixel(transparent, 4UL, 4UL)
      inspect(
        (transparent_r.to_int(), transparent_g.to_int(), transparent_b.to_int(), transparent_a.to_int()),
        content="(255, 0, 0, 64)",
      )
    }
  }
}

///|
test "portable qualification retains parser rejection before lowering or raster" {
  match parse_svg("<svg><rect opacity=\"bad\"/></svg>") {
    Ok(_) => inspect(false, content="true")
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::Data, content="true")
      inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
      inspect(error.operation() == Some("svg"), content="true")
      inspect(error.context() == Some("svg-numeric-source"), content="true")
    }
  }
}

fn qualification_nested_opacity_svg(levels : Int) -> String {
  let source = StringBuilder::new()
  source.write_string("<svg>")
  for i = 0; i < levels; i = i + 1 {
    source.write_string("<g opacity=\"0.5\">")
  }
  source.write_string("<rect x=\"2\" y=\"2\" width=\"4\" height=\"4\" fill=\"red\"/>")
  for i = 0; i < levels; i = i + 1 {
    source.write_string("</g>")
  }
  source.write_string("</svg>")
  source.to_string()
}

fn qualification_assert_nested_layers(list : @canvas.DrawingList, levels : Int) -> Unit raise {
  inspect(list.length(), content=(levels * 4 + 1).to_string())
  for i = 0; i < levels; i = i + 1 {
    match (list.get(i * 2), list.get(i * 2 + 1)) {
      (Some(PushTransform(_)), Some(PushLayer(opacity))) => inspect(opacity, content="0.5")
      _ => inspect(false, content="true")
    }
  }
  match list.get(levels * 2) {
    Some(Fill(_, _)) => ()
    _ => inspect(false, content="true")
  }
  for i = 0; i < levels; i = i + 1 {
    let offset = levels * 2 + 1 + i * 2
    match (list.get(offset), list.get(offset + 1)) {
      (Some(PopLayer), Some(PopTransform)) => ()
      _ => inspect(false, content="true")
    }
  }
}

///|
test "portable qualification renders sixteen SVG-originated opacity layers" {
  match parse_svg(qualification_nested_opacity_svg(16)) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      qualification_assert_nested_layers(list, 16)
      let image = qualification_image(b'\x10', b'\x20', b'\x30', b'\xff')
      match @canvas.render(list, image, qualification_budget()) {
        Err(_) => inspect(false, content="true")
        Ok(_) => ()
      }
      let (_, _, _, center_a) = qualification_pixel(image, 4UL, 4UL)
      inspect(center_a.to_int() > 0, content="true")
      let (corner_r, corner_g, corner_b, corner_a) = qualification_pixel(image, 0UL, 0UL)
      inspect(
        (corner_r.to_int(), corner_g.to_int(), corner_b.to_int(), corner_a.to_int()),
        content="(16, 32, 48, 255)",
      )
    }
  }
}

///|
test "portable qualification rejects a seventeenth SVG-originated opacity layer atomically" {
  match parse_svg(qualification_nested_opacity_svg(17)) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      qualification_assert_nested_layers(list, 17)
      let image = qualification_image(b'\x10', b'\x20', b'\x30', b'\xff')
      match @canvas.render(list, image, qualification_budget()) {
        Ok(_) => inspect(false, content="true")
        Err(error) => {
          inspect(error.category() == @error.ErrorCategory::Resource, content="true")
          inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
          inspect(error.operation() == Some("canvas-render"), content="true")
          inspect(
            error.context() == Some("canvas-layer-depth: layer nesting depth exceeded"),
            content="true",
          )
        }
      }
      let (r, g, b, a) = qualification_pixel(image, 4UL, 4UL)
      inspect((r.to_int(), g.to_int(), b.to_int(), a.to_int()), content="(16, 32, 48, 255)")
    }
  }
}
