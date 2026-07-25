// White-box tests for the scene-tree builder. CoreError does not implement
// Show, so each test matches on Result directly and inspects plain values;
// no abort() is used (it crashes the native test runner via the GS check).

///|
test "parse_svg minimal self-closed root" {
  match parse_svg("<svg/>") {
    Ok(Svg(_, children)) => inspect(children.length(), content="0")
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "parse_svg root captures width/height/viewBox" {
  match parse_svg("<svg viewBox=\"0 0 100 50\" width=\"10\" height=\"20\"/>") {
    Ok(Svg(root, _)) => {
      inspect(root.width, content="Some(10)")
      inspect(root.height, content="Some(20)")
      match root.view_box {
        Some((x, y, w, h)) => inspect((x, y, w, h), content="(0, 0, 100, 50)")
        None => inspect(false, content="true")
      }
    }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "parse_svg group with transform wraps a rect child" {
  let src = "<svg><g transform=\"translate(10,0)\"><rect x=\"1\" y=\"2\" width=\"3\" height=\"4\"/></g></svg>"
  match parse_svg(src) {
    Ok(Svg(_, children)) =>
      match children.length() {
        1 =>
          match children[0] {
            Group(t, _, gc) => {
              inspect((t.a(), t.d(), t.tx(), t.ty()), content="(1, 1, 10, 0)")
              inspect(gc.length(), content="1")
              match gc[0] {
                Rect(_, x, y, w, h, _, _) =>
                  inspect((x, y, w, h), content="(1, 2, 3, 4)")
                _ => inspect(false, content="true")
              }
            }
            _ => inspect(false, content="true")
          }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "parse_svg rect with fill parses geometry and paint" {
  match parse_svg("<svg><rect x=\"1\" y=\"2\" width=\"3\" height=\"4\" fill=\"red\"/></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Rect(paint, x, y, w, h, rx, ry) => {
          inspect((x, y, w, h, rx, ry), content="(1, 2, 3, 4, 0, 0)")
          match paint.fill {
            Some((r, g, b)) => inspect((r, g, b), content="(1, 0, 0)")
            None => inspect(false, content="true")
          }
          inspect(paint.stroke, content="None")
        }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "parse_svg circle fill none / stroke blue" {
  match parse_svg("<svg><circle cx=\"5\" cy=\"6\" r=\"2\" fill=\"none\" stroke=\"blue\"/></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Circle(paint, cx, cy, r) => {
          inspect((cx, cy, r), content="(5, 6, 2)")
          inspect(paint.fill, content="None")
          match paint.stroke {
            Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
            None => inspect(false, content="true")
          }
        }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "parse_svg path command count via to_path2" {
  match parse_svg("<svg><path d=\"M0 0 L5 5 Z\"/></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Path(_, cp) => inspect(cp.to_path2().length(), content="3")
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "parse_svg polygon points become Point2 pairs" {
  match parse_svg("<svg><polygon points=\"0,0 10,0 10,10\"/></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Polygon(_, pts) =>
          match pts.length() {
            3 => {
              let p0 = pts[0]
              let p1 = pts[1]
              let p2 = pts[2]
              inspect((p0.x(), p0.y()), content="(0, 0)")
              inspect((p1.x(), p1.y()), content="(10, 0)")
              inspect((p2.x(), p2.y()), content="(10, 10)")
            }
            n => inspect(n, content="3")
          }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "parse_svg skips unknown/deferred subtrees" {
  // <defs> with a nested <linearGradient> is RFC §6.2 deferred; it must be
  // skipped whole, leaving only the trailing rect as a child.
  let src = "<svg><defs><linearGradient id=\"g\"/></defs><rect x=\"1\" y=\"2\" width=\"3\" height=\"4\"/></svg>"
  match parse_svg(src) {
    Ok(Svg(_, children)) => inspect(children.length(), content="1")
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "parse_svg skips self-closing deferred elements without consuming siblings" {
  let src = "<svg><defs/><rect x=\"1\" y=\"2\" width=\"3\" height=\"4\"/></svg>"
  match parse_svg(src) {
    Ok(Svg(_, children)) =>
      match children.length() {
        1 =>
          match children[0] {
            Rect(_, x, y, width, height, _, _) =>
              inspect((x, y, width, height), content="(1, 2, 3, 4)")
            _ => inspect(false, content="true")
          }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_svg accepts a self-closing deferred-only document" {
  match parse_svg("<svg><metadata/></svg>") {
    Ok(Svg(_, children)) => inspect(children.length(), content="0")
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_svg rejects non-svg root" {
  match parse_svg("<rect/>") {
    Err(_) => inspect("err", content="err")
    Ok(_) => inspect("ok", content="err")
  }
}

///|
test "parse_svg propagates tokenize failure (unquoted attribute)" {
  // tokenize_markup rejects unquoted attribute values; parse_svg surfaces it.
  match parse_svg("<svg><g id=x></g></svg>") {
    Err(_) => inspect("err", content="err")
    Ok(_) => inspect("ok", content="err")
  }
}

///|
test "parse_svg path without d attribute is an error" {
  match parse_svg("<svg><path fill=\"red\"/></svg>") {
    Err(_) => inspect("err", content="err")
    Ok(_) => inspect("ok", content="err")
  }
}

// ---------------------------------------------------------------------------
// Paint inheritance + currentColor (build-time resolution)
// ---------------------------------------------------------------------------

///|
test "inherited fill flows from <g> to a child rect that omits fill" {
  // rect has no fill attribute → inherits the group's red.
  match parse_svg("<svg><g fill=\"red\"><rect width=\"1\" height=\"1\"/></g></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Group(_, _, gc) =>
          match gc[0] {
            Rect(paint, _, _, _, _, _, _) =>
              match paint.fill {
                Some((r, g, b)) => inspect((r, g, b), content="(1, 0, 0)")
                None => inspect(false, content="true")
              }
            _ => inspect(false, content="true")
          }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "currentColor resolves against the inherited color attribute" {
  // <g color="blue"> sets currentColor; child fill="currentColor" → blue.
  match parse_svg("<svg><g color=\"blue\"><rect fill=\"currentColor\" width=\"1\" height=\"1\"/></g></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Group(_, _, gc) =>
          match gc[0] {
            Rect(paint, _, _, _, _, _, _) =>
              match paint.fill {
                Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
                None => inspect(false, content="true")
              }
            _ => inspect(false, content="true")
          }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "inheritance penetrates multiple nested groups" {
  // Two nested <g>, innermost rect inherits the outer group's green fill.
  match parse_svg("<svg><g fill=\"green\"><g><rect width=\"1\" height=\"1\"/></g></g></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Group(_, _, gc) =>
          match gc[0] {
            Group(_, _, ggc) =>
              match ggc[0] {
                Rect(paint, _, _, _, _, _, _) =>
                  match paint.fill {
                    // green = (0, 0.5019..., 0)
                    Some((_, g, _)) => inspect(g > 0.49 && g < 0.51, content="true")
                    None => inspect(false, content="true")
                  }
                _ => inspect(false, content="true")
              }
            _ => inspect(false, content="true")
          }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "explicit child fill overrides the inherited group fill" {
  match parse_svg("<svg><g fill=\"red\"><rect fill=\"blue\" width=\"1\" height=\"1\"/></g></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Group(_, _, gc) =>
          match gc[0] {
            Rect(paint, _, _, _, _, _, _) =>
              match paint.fill {
                Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
                None => inspect(false, content="true")
              }
            _ => inspect(false, content="true")
          }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "explicit fill=none does NOT inherit the group fill" {
  // rect fill="none" must stay none, not inherit the group's red.
  match parse_svg("<svg><g fill=\"red\"><rect fill=\"none\" width=\"1\" height=\"1\"/></g></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Group(_, _, gc) =>
          match gc[0] {
            Rect(paint, _, _, _, _, _, _) => inspect(paint.fill, content="None")
            _ => inspect(false, content="true")
          }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "group opacity attribute is captured on the Group node" {
  // <g opacity="0.5"> → Group's opacity field == 0.5 (default 1.0 otherwise).
  match parse_svg("<svg><g opacity=\"0.5\"><rect width=\"1\" height=\"1\"/></g></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Group(_, opacity, _) => inspect(opacity, content="0.5")
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "element opacity attribute is captured on the shape Paint" {
  // <rect opacity="0.5"> → paint.opacity == 0.5.
  match parse_svg("<svg><rect width=\"1\" height=\"1\" opacity=\"0.5\"/></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Rect(paint, _, _, _, _, _, _) => inspect(paint.opacity, content="0.5")
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "inherited stroke and stroke-width flow to a child" {
  // <g stroke="blue" stroke-width="3">; child rect (no stroke attrs) inherits.
  match parse_svg("<svg><g stroke=\"blue\" stroke-width=\"3\"><rect fill=\"none\" width=\"1\" height=\"1\"/></g></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Group(_, _, gc) =>
          match gc[0] {
            Rect(paint, _, _, _, _, _, _) => {
              match paint.stroke {
                Some((r, g, b)) => inspect((r, g, b), content="(0, 0, 1)")
                None => inspect(false, content="true")
              }
              inspect(paint.stroke_width, content="3")
            }
            _ => inspect(false, content="true")
          }
        _ => inspect(false, content="true")
      }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "numeric contract: scene ingress and absent controls" {
  let finite_scene = "<svg width=\"65536\" height=\"65536\" viewBox=\"0 0 65536 65536\"><rect x=\"-65536\" y=\"-65536\" width=\"65536\" height=\"65536\" rx=\"1\" ry=\"1\" fill=\"rgb(255,0,0)\" stroke=\"rgb(100%,0%,0%)\" fill-opacity=\"65536\" stroke-opacity=\"65536\" stroke-width=\"65536\" stroke-miterlimit=\"65536\" stroke-dasharray=\"1,65536\" stroke-dashoffset=\"65536\"/><circle cx=\"0\" cy=\"0\" r=\"65536\" fill=\"rgba(100%,0%,0%,0.25)\"/><ellipse cx=\"0\" cy=\"0\" rx=\"65536\" ry=\"1\" fill=\"hsl(120,100%,50%)\"/><line x1=\"-65536\" y1=\"-65536\" x2=\"65536\" y2=\"65536\" fill=\"hsla(0,100%,50%,0.25)\"/><polygon points=\"-65536,-65536 65536,-65536 65536,65536\" fill=\"hsl(0,0%,50%)\"/><polyline points=\"-65536,-65536 0,0 65536,65536\"/></svg>"
  match parse_svg(finite_scene) {
    Ok(Svg(root, children)) => {
      // SVG-NUM-ROOT: finite root dimensions and all four viewBox scalars.
      inspect(root.width, content="Some(65536)")
      inspect(root.height, content="Some(65536)")
      inspect(root.view_box, content="Some((0, 0, 65536, 65536))")
      // SVG-NUM-GEOMETRY / SVG-NUM-PAINT-SCALAR / SVG-NUM-DASH-LIST.
      match children[0] {
        Rect(paint, x, y, width, height, _, _) => {
          inspect((x, y, width, height), content="(-65536, -65536, 65536, 65536)")
          inspect(paint.stroke_dash, content="[1, 65536]")
          inspect((paint.fill_opacity, paint.stroke_opacity, paint.stroke_width, paint.stroke_miterlimit, paint.stroke_dashoffset), content="(65536, 65536, 65536, 65536, 65536)")
          // SVG-NUM-RGB-NUMERIC: lowercase comma-separated numeric RGB.
          inspect(paint.fill, content="Some((1, 0, 0))")
          // SVG-NUM-RGB-PERCENT: lowercase comma-separated percent RGB.
          inspect(paint.stroke, content="Some((1, 0, 0))")
        }
        _ => inspect(false, content="true")
      }
      match children[1] {
        // SVG-NUM-RGB-PERCENT: rgba consumes the first three percent components.
        Circle(paint, cx, cy, radius) => {
          inspect((cx, cy, radius), content="(0, 0, 65536)")
          inspect(paint.fill, content="Some((1, 0, 0))")
        }
        _ => inspect(false, content="true")
      }
      match children[2] {
        // SVG-NUM-HSL-HUE: numeric hue remains an admitted source scalar.
        Ellipse(paint, _, _, _, _) => inspect(paint.fill, content="Some((0, 1, 0))")
        _ => inspect(false, content="true")
      }
      match children[3] {
        // SVG-NUM-HSL-PERCENT: saturation percent is an admitted source scalar.
        Line(paint, _, _, _, _) => inspect(paint.fill, content="Some((1, 0, 0))")
        _ => inspect(false, content="true")
      }
      match children[4] {
        // SVG-NUM-HSL-PERCENT: lightness percent is an admitted source scalar.
        Polygon(paint, points) => {
          inspect(points.length(), content="3")
          inspect(paint.fill, content="Some((0.5, 0.5, 0.5))")
        }
        _ => inspect(false, content="true")
      }
      match children[5] {
        // SVG-NUM-POINTS: finite polyline pairs retain all supplied coordinates.
        Polyline(_, points) => inspect(points.length(), content="3")
        _ => inspect(false, content="true")
      }
    }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(false, content="true")
  }

  // D-03: only absent attributes retain their existing default or inheritance branch.
  match parse_svg("<svg><g fill=\"blue\"><rect width=\"1\" height=\"1\"/></g><polygon/></svg>") {
    Ok(Svg(root, children)) => {
      inspect(root.width, content="None")
      inspect(root.height, content="None")
      match children[0] {
        Group(_, _, group_children) =>
          match group_children[0] {
            Rect(paint, _, _, _, _, _, _) => inspect(paint.fill, content="Some((0, 0, 1))")
            _ => inspect(false, content="true")
          }
        _ => inspect(false, content="true")
      }
      match children[1] {
        Polygon(_, points) => inspect(points.length(), content="0")
        _ => inspect(false, content="true")
      }
    }
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "paint scalar ingress rejects explicit invalid values without changing omitted inheritance" {
  let invalid_sources = [
    "<svg><rect fill-opacity=\"bad\"/></svg>",
    "<svg><rect stroke-width=\"1e999\"/></svg>",
    "<svg><rect stroke-dasharray=\"1,65537\"/></svg>",
    "<svg><rect fill=\"rgb(bad,0,0)\"/></svg>",
    "<svg><rect fill=\"rgb(1e999,0,0)\"/></svg>",
    "<svg><rect fill=\"rgb(65537,0,0)\"/></svg>",
    "<svg><rect fill=\"rgb(0,1e999%,0)\"/></svg>",
    "<svg><rect fill=\"hsl(65537,0%,0%)\"/></svg>",
    "<svg><rect fill=\"hsl(0,1e999%,0%)\"/></svg>",
  ]
  for source in invalid_sources {
    match parse_svg(source) {
      Ok(_) => inspect(false, content="true")
      Err(error) => inspect(error.operation(), content="Some(svg)")
    }
  }
  match parse_svg("<svg><g fill=\"blue\"><rect width=\"1\" height=\"1\"/></g></svg>") {
    Ok(Svg(_, children)) =>
      match children[0] {
        Group(_, _, [Rect(paint, _, _, _, _, _, _)]) => inspect(paint.fill, content="Some((0, 0, 1))")
        _ => inspect(false, content="true")
      }
    _ => inspect(false, content="true")
  }
}
