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
