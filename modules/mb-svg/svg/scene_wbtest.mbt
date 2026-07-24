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
            Group(t, gc) => {
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
