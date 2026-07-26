// White-box tests for SceneNode → DrawingList lowering. Asserts the recorded
// DrawOp sequence (counts and variant shapes) and reads style color fields.
// CoreError has no Show, so parse results are matched directly (no abort()).

///|
test "lower rect emits one fill op" {
  match parse_svg("<svg><rect x=\"1\" y=\"2\" width=\"3\" height=\"4\" fill=\"red\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="1")
      match list.get(0) {
        Some(Fill(_, style)) => inspect(style.color_r, content="1")
        _ => fail("expected fill operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower circle emits one fill with black default" {
  match parse_svg("<svg><circle cx=\"5\" cy=\"6\" r=\"2\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="1")
      match list.get(0) {
        Some(Fill(_, style)) => {
          inspect(style.color_r, content="0")
          inspect(style.color_g, content="0")
          inspect(style.color_b, content="0")
        }
        _ => fail("expected fill operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower stroke emits Fill then Stroke when both set" {
  // A shape with both fill and stroke lowers to two ops: Fill, then Stroke.
  match parse_svg("<svg><rect width=\"10\" height=\"10\" fill=\"red\" stroke=\"blue\" stroke-width=\"2\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="2")
      match list.get(0) {
        Some(Fill(_, style)) => inspect(style.color_b, content="0")
        _ => fail("expected fill operation")
      }
      match list.get(1) {
        Some(Stroke(_, stroke, color)) => {
          inspect(stroke.width, content="2")
          inspect(color.color_b, content="1")
        }
        _ => fail("expected stroke operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower fill none emits stroke only" {
  match parse_svg("<svg><circle r=\"3\" fill=\"none\" stroke=\"green\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="1")
      match list.get(0) {
        Some(Stroke(_, _, _)) => inspect("stroke", content="stroke")
        _ => fail("expected stroke operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower group wraps children with push/pop transform" {
  // <g transform="translate(10,0)"> with one rect child →
  // PushTransform, Fill, PopTransform.
  let src = "<svg><g transform=\"translate(10,0)\"><rect width=\"1\" height=\"1\"/></g></svg>"
  match parse_svg(src) {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="3")
      match list.get(0) {
        Some(PushTransform(t)) => inspect(t.tx(), content="10")
        _ => fail("expected push transform")
      }
      match list.get(1) {
        Some(Fill(_, _)) => inspect("fill", content="fill")
        _ => fail("expected fill operation")
      }
      match list.get(2) {
        Some(PopTransform) => inspect("pop", content="pop")
        _ => fail("expected pop transform")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower nested groups balance push/pop" {
  // Two nested groups, one rect leaf → Push, Push, Fill, Pop, Pop.
  let src = "<svg><g><g><rect width=\"1\" height=\"1\"/></g></g></svg>"
  match parse_svg(src) {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="5")
      match list.get(0) {
        Some(PushTransform(_)) => inspect("push", content="push")
        _ => fail("expected push transform")
      }
      match list.get(1) {
        Some(PushTransform(_)) => inspect("push", content="push")
        _ => fail("expected push transform")
      }
      match list.get(2) {
        Some(Fill(_, _)) => inspect("fill", content="fill")
        _ => fail("expected fill operation")
      }
      match list.get(3) {
        Some(PopTransform) => inspect("pop", content="pop")
        _ => fail("expected pop transform")
      }
      match list.get(4) {
        Some(PopTransform) => inspect("pop", content="pop")
        _ => fail("expected pop transform")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower path emits fill from parsed path data" {
  match parse_svg("<svg><path d=\"M0 0 L5 5 Z\" fill=\"blue\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="1")
      match list.get(0) {
        Some(Fill(p, style)) => {
          // The lowered path keeps the 3 commands (M, L, Z) from path data.
          inspect(p.length(), content="3")
          inspect(style.color_b, content="1")
        }
        _ => fail("expected fill operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower polygon and polyline both lower" {
  match parse_svg("<svg><polygon points=\"0,0 10,0 10,10\"/><polyline points=\"0,0 5,5\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      // polygon + polyline → 2 fill ops (default black fill).
      inspect(list.length(), content="2")
      match list.get(0) {
        Some(Fill(_, _)) => inspect("fill", content="fill")
        _ => fail("expected fill operation")
      }
      match list.get(1) {
        Some(Fill(_, _)) => inspect("fill", content="fill")
        _ => fail("expected fill operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower skips unknown deferred subtrees (no ops emitted)" {
  // <defs>/<linearGradient> skipped at scene build → no draw ops for them.
  let src = "<svg><defs><linearGradient id=\"g\"/></defs><rect width=\"1\" height=\"1\"/></svg>"
  match parse_svg(src) {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      // Only the rect emits an op.
      inspect(list.length(), content="1")
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower applies fill-opacity to the Fill op alpha" {
  // fill-opacity="0.5" must flow through Paint into the FillStyle's alpha.
  match parse_svg("<svg><rect width=\"4\" height=\"4\" fill=\"red\" fill-opacity=\"0.5\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(Fill(_, style)) => {
          inspect(style.color_r, content="1")
          inspect(style.color_a, content="0.5")
        }
        _ => fail("expected fill operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower applies stroke-opacity and keeps fill opaque by default" {
  match parse_svg("<svg><rect width=\"4\" height=\"4\" fill=\"red\" stroke=\"blue\" stroke-opacity=\"0.25\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      // Fill is opaque (no fill-opacity) → alpha 1.
      match list.get(0) {
        Some(Fill(_, style)) => inspect(style.color_a, content="1")
        _ => fail("expected fill operation")
      }
      // Stroke color carries stroke-opacity=0.25.
      match list.get(1) {
        Some(Stroke(_, _, color)) => inspect(color.color_a, content="0.25")
        _ => fail("expected stroke operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower wires stroke cap/join/miter/dash from attributes" {
  let src = "<svg><rect width=\"4\" height=\"4\" fill=\"none\" stroke=\"black\" stroke-width=\"3\" stroke-linecap=\"round\" stroke-linejoin=\"bevel\" stroke-miterlimit=\"6\" stroke-dasharray=\"2 1 0.5\"/></svg>"
  match parse_svg(src) {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      // No fill → only the Stroke op is emitted.
      match list.get(0) {
        Some(Stroke(_, stroke, _)) => {
          inspect(stroke.width, content="3")
          inspect(stroke.cap == @canvas.LineCap::Round, content="true")
          inspect(stroke.join == @canvas.LineJoin::Bevel, content="true")
          inspect(stroke.miter_limit, content="6")
          inspect(stroke.dash.length(), content="3")
          inspect(stroke.dash[2], content="0.5")
        }
        _ => fail("expected stroke operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower stroke defaults when no stroke attributes are given" {
  // Only stroke color set; cap/join/miter/dash keep SVG defaults.
  match parse_svg("<svg><rect width=\"4\" height=\"4\" stroke=\"black\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(1) {
        Some(Stroke(_, stroke, _)) => {
          inspect(stroke.width, content="1")
          inspect(stroke.cap == @canvas.LineCap::Butt, content="true")
          inspect(stroke.join == @canvas.LineJoin::Miter, content="true")
          inspect(stroke.miter_limit, content="4")
          inspect(stroke.dash.length(), content="0")
        }
        _ => fail("expected stroke operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower applies fill-rule=evenodd to the Fill op" {
  match parse_svg("<svg><path d=\"M0 0 L4 0 L4 4 Z\" fill=\"black\" fill-rule=\"evenodd\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(Fill(_, style)) =>
          inspect(style.rule == @canvas.FillRule::EvenOdd, content="true")
        _ => fail("expected evenodd fill operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower fill-rule defaults to Nonzero" {
  match parse_svg("<svg><rect width=\"4\" height=\"4\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(Fill(_, style)) =>
          inspect(style.rule == @canvas.FillRule::Nonzero, content="true")
        _ => fail("expected nonzero fill operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower rect rx>0 produces a rounded path (8 cubics + move + close = 10 cmds)" {
  // A rounded rect has: move + 4*(line + cubic) + close = 1 + 4*2 + 1 = 10.
  match parse_svg("<svg><rect width=\"10\" height=\"10\" rx=\"2\" ry=\"2\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(Fill(p, _)) => inspect(p.length(), content="10")
        _ => fail("expected rounded rectangle fill")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower rect rx=ry=0 stays a sharp path (move + 3 lines + close = 5 cmds)" {
  match parse_svg("<svg><rect width=\"10\" height=\"10\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(Fill(p, _)) => inspect(p.length(), content="5")
        _ => fail("expected sharp rectangle fill")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower viewBox mapping wraps svg children in a transform" {
  // viewBox 0 0 100 100 mapped to width=200 height=200 → uniform scale 2,
  // centered: tx = (200 - 100*2)/2 - 0*2 = 0, ty = 0. So transform = scale 2.
  match parse_svg("<svg viewBox=\"0 0 100 100\" width=\"200\" height=\"200\"><rect width=\"1\" height=\"1\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      // Expect: PushTransform(scale 2), Fill, PopTransform.
      inspect(list.length(), content="3")
      match list.get(0) {
        Some(PushTransform(t)) => {
          inspect(t.a(), content="2")
          inspect(t.d(), content="2")
          inspect(t.tx(), content="0")
        }
        _ => fail("expected push transform")
      }
      match list.get(2) {
        Some(PopTransform) => inspect("pop", content="pop")
        _ => fail("expected pop transform")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower viewBox with offset viewport centers content (xMidYMid meet)" {
  // viewBox 0 0 100 50 → width=200 height=200. scale = min(2, 4) = 2 (meet).
  // tx = (200 - 100*2)/2 - 0 = 0; ty = (200 - 50*2)/2 - 0 = 50.
  match parse_svg("<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\"><rect width=\"1\" height=\"1\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(PushTransform(t)) => {
          inspect(t.a(), content="2")
          inspect(t.d(), content="2")
          inspect(t.tx(), content="0")
          inspect(t.ty(), content="50")
        }
        _ => fail("expected push transform")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower no viewBox means no viewport transform" {
  // Without viewBox, children lower directly (no wrapping Push/Pop).
  match parse_svg("<svg width=\"200\" height=\"200\"><rect width=\"1\" height=\"1\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      // Just the Fill op, no transform wrap.
      inspect(list.length(), content="1")
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower preserveAspectRatio xMidYMid meet centers the smaller axis" {
  // viewBox 0 0 100 50 → vp 200×200. meet: s=min(2,4)=2. diff_y=200-50*2=100,
  // Mid → ty = 100/2 = 50. tx = (200-100*2)/2 = 0.
  match parse_svg("<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\" preserveAspectRatio=\"xMidYMid meet\"><rect width=\"1\" height=\"1\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(PushTransform(t)) => {
          inspect(t.a(), content="2")
          inspect(t.d(), content="2")
          inspect(t.tx(), content="0")
          inspect(t.ty(), content="50")
        }
        _ => fail("expected push transform")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower preserveAspectRatio xMinYMin meet aligns to top-left" {
  // Same as above but Min: ty = 0 (no centering on the slack axis).
  match parse_svg("<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\" preserveAspectRatio=\"xMinYMin meet\"><rect width=\"1\" height=\"1\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(PushTransform(t)) => {
          inspect(t.ty(), content="0")
          inspect(t.tx(), content="0")
        }
        _ => fail("expected push transform")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower preserveAspectRatio slice scales up and centers (overflow)" {
  // slice: s=max(2,4)=4. diff_x=200-400=-200, Mid → tx=-100. ty=0.
  match parse_svg("<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\" preserveAspectRatio=\"xMidYMid slice\"><rect width=\"1\" height=\"1\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(PushTransform(t)) => {
          inspect(t.a(), content="4")
          inspect(t.d(), content="4")
          inspect(t.tx(), content="-100")
          inspect(t.ty(), content="0")
        }
        _ => fail("expected push transform")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower preserveAspectRatio none uses non-uniform scaling" {
  // none: sx=2, sy=4 independently; no centering; tx=ty=0.
  match parse_svg("<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\" preserveAspectRatio=\"none\"><rect width=\"1\" height=\"1\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(PushTransform(t)) => {
          inspect(t.a(), content="2")
          inspect(t.d(), content="4")
          inspect(t.tx(), content="0")
          inspect(t.ty(), content="0")
        }
        _ => fail("expected push transform")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower wires stroke-dashoffset into the StrokeStyle" {
  match parse_svg("<svg><rect width=\"4\" height=\"4\" fill=\"none\" stroke=\"black\" stroke-dasharray=\"2 1\" stroke-dashoffset=\"5\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(Stroke(_, stroke, _)) => inspect(stroke.dash_offset, content="5")
        _ => fail("expected stroke operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower stroke-dashoffset defaults to 0" {
  match parse_svg("<svg><rect width=\"4\" height=\"4\" stroke=\"black\" stroke-dasharray=\"2 1\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(1) {
        Some(Stroke(_, stroke, _)) => inspect(stroke.dash_offset, content="0")
        _ => fail("expected stroke operation")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower group opacity<1 wraps children in PushLayer/PopLayer" {
  // <g opacity="0.5"> with one rect child → PushTransform, PushLayer(0.5),
  // Fill, PopLayer, PopTransform (5 ops).
  match parse_svg("<svg><g opacity=\"0.5\"><rect width=\"1\" height=\"1\"/></g></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="5")
      match list.get(1) {
        Some(PushLayer(op)) => inspect(op, content="0.5")
        _ => fail("expected push layer")
      }
      match list.get(3) {
        Some(PopLayer) => inspect("pop", content="pop")
        _ => fail("expected pop layer")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower group opacity=1 emits no layer ops" {
  // Default opacity (1.0) → no PushLayer/PopLayer; just transform + fill.
  match parse_svg("<svg><g><rect width=\"1\" height=\"1\"/></g></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      // PushTransform, Fill, PopTransform (3 ops).
      inspect(list.length(), content="3")
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "lower element opacity<1 wraps the shape in a layer" {
  // <rect opacity="0.5"> → PushLayer(0.5), Fill, PopLayer (3 ops).
  match parse_svg("<svg><rect width=\"1\" height=\"1\" opacity=\"0.5\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="3")
      match list.get(0) {
        Some(PushLayer(op)) => inspect(op, content="0.5")
        _ => fail("expected push layer")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "numeric contract: viewBox and opacity lower controls" {
  // SVG-NUM-VIEWBOX: a finite viewBox mapping remains a typed draw-operation path.
  match parse_svg("<svg viewBox=\"0 0 65536 65536\" width=\"32768\" height=\"32768\"><rect width=\"1\" height=\"1\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="3")
      match list.get(0) {
        Some(PushTransform(transform)) => {
          assert_eq(transform.a(), 0.5)
          assert_eq(transform.d(), 0.5)
        }
        _ => inspect(false, content="true")
      }
      match list.get(1) {
        Some(Fill(_, _)) => inspect(true, content="true")
        _ => inspect(false, content="true")
      }
      match list.get(2) {
        Some(PopTransform) => inspect(true, content="true")
        _ => inspect(false, content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
  // D-06: RFC 0008 group and element opacity layers retain their nesting order.
  match parse_svg("<svg><g opacity=\"0.5\"><rect width=\"1\" height=\"1\" opacity=\"0.25\"/></g></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="7")
      match (list.get(1), list.get(2), list.get(4), list.get(5)) {
        (Some(PushLayer(group_opacity)), Some(PushLayer(element_opacity)), Some(PopLayer), Some(PopLayer)) =>
          {
            assert_eq(group_opacity, 0.5)
            assert_eq(element_opacity, 0.25)
          }
        _ => inspect(false, content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
  // SVG-NUM-ROUND-RECT: finite clamp and ratio arithmetic yields a closed path.
  match parse_svg("<svg><rect width=\"65536\" height=\"32768\" rx=\"65536\" ry=\"65536\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(Fill(path, _)) => {
          inspect(path.length(), content="10")
          match (path.get(0), path.get(9)) {
            (Some(@math.PathCommand::MoveTo(point)), Some(@math.PathCommand::Close)) =>
              {
                assert_eq(point.x(), 32768.0)
                assert_eq(point.y(), 0.0)
              }
            _ => inspect(false, content="true")
          }
        }
        _ => inspect(false, content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
  // SVG-NUM-ELLIPSE-SAMPLING: 32 finite samples plus Close are preserved at the limit.
  match parse_svg("<svg><circle cx=\"0\" cy=\"0\" r=\"65536\"/></svg>") {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      match list.get(0) {
        Some(Fill(path, _)) => {
          inspect(path.length(), content="33")
          match (path.get(0), path.get(32)) {
            (Some(@math.PathCommand::MoveTo(point)), Some(@math.PathCommand::Close)) =>
              {
                assert_eq(point.x(), 65536.0)
                assert_eq(point.y().abs() < 1.0e-9, true)
              }
            _ => inspect(false, content="true")
          }
        }
        _ => inspect(false, content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parser-derived numeric rejection never reaches the total lowerer" {
  let cases = [
    "<svg><g transform=\"translate(65536,0)\"><path d=\"M 1 0 L 2 0\"/></g></svg>",
    "<svg><circle cx=\"65536\" cy=\"0\" r=\"1\"/></svg>",
  ]
  for source in cases {
    match parse_svg(source) {
      // A parser-produced SceneNode is the only input the total lowerer sees.
      Ok(_) => inspect(false, content="true")
      Err(error) =>
        assert_eq(error.context(), Some("svg-numeric-derived"))
    }
  }
}

///|
test "lower checked geometry retains compact map and path operation forms" {
  // The shared checked seam must leave the selected viewBox affine and every
  // supported compact geometry representation visible to the DrawingList.
  let source = "<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\" preserveAspectRatio=\"none\"><rect width=\"10\" height=\"10\" rx=\"2\" ry=\"2\"/><ellipse cx=\"5\" cy=\"6\" rx=\"4\" ry=\"2\"/><polyline points=\"0,0 1,1 2,0\"/><path d=\"M0 0 L1 1 Z\"/></svg>"
  match parse_svg(source) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="6")
      match list.get(0) {
        Some(PushTransform(map)) =>
          {
            assert_eq(map.a(), 2.0)
            assert_eq(map.d(), 4.0)
            assert_eq(map.tx(), 0.0)
            assert_eq(map.ty(), 0.0)
          }
        _ => inspect(false, content="true")
      }
      match list.get(1) {
        Some(Fill(path, _)) => inspect(path.length(), content="10")
        _ => inspect(false, content="true")
      }
      match list.get(2) {
        Some(Fill(path, _)) => {
          inspect(path.length(), content="33")
          match (path.get(0), path.get(32)) {
            (Some(@math.PathCommand::MoveTo(_)), Some(@math.PathCommand::Close)) => ()
            _ => inspect(false, content="true")
          }
        }
        _ => inspect(false, content="true")
      }
      match list.get(3) {
        Some(Fill(path, _)) => inspect(path.length(), content="3")
        _ => inspect(false, content="true")
      }
      match list.get(4) {
        Some(Fill(path, _)) => {
          inspect(path.length(), content="3")
          match (path.get(0), path.get(1), path.get(2)) {
            (
              Some(@math.PathCommand::MoveTo(_)),
              Some(@math.PathCommand::LineTo(_)),
              Some(@math.PathCommand::Close),
            ) => ()
            _ => inspect(false, content="true")
          }
        }
        _ => inspect(false, content="true")
      }
      match list.get(5) {
        Some(PopTransform) => ()
        _ => inspect(false, content="true")
      }
    }
  }
}

///|
test "lower invalid manual scenes recover deterministically without moving layers" {
  match parse_svg("<svg><rect width=\"1\" height=\"1\" fill=\"red\" stroke=\"blue\" opacity=\"0.25\"/></svg>") {
    Ok(Svg(_, [Rect(paint, _, _, _, _, _, _)])) => {
      // This root requires an out-of-envelope derived translation. The total
      // adapter must recover with identity, leaving emit_shape's layer order.
      let invalid_root : SvgRoot = {
        width: Some(65536.0),
        height: Some(1.0),
        view_box: Some((2.0, 0.0, 1.0, 1.0)),
        preserve_aspect_ratio: { align_x: 1, align_y: 1, meet: true, none: true },
      }
      let invalid_path = @canvas.CanvasPath::new()
      invalid_path.move_to(65537.0, 0.0)
      let invalid_scene = Svg(
        invalid_root,
        [
          Rect(paint, 65536.0, 0.0, 1.0, 1.0, 0.0, 0.0),
          Path(paint, invalid_path),
        ],
      )
      let first = lower_to_drawing_list(invalid_scene)
      let second = lower_to_drawing_list(invalid_scene)
      assert_eq(first.length(), 8)
      assert_eq(second.length(), 8)
      for list in [first, second] {
        match (list.get(0), list.get(1), list.get(2), list.get(3)) {
          (Some(PushLayer(0.25)), Some(Fill(rect, _)), Some(Stroke(_, _, _)), Some(PopLayer)) =>
            inspect(rect.length(), content="0")
          _ => inspect(false, content="true")
        }
        match (list.get(4), list.get(5), list.get(6), list.get(7)) {
          (Some(PushLayer(0.25)), Some(Fill(path, _)), Some(Stroke(_, _, _)), Some(PopLayer)) =>
            inspect(path.length(), content="0")
          _ => inspect(false, content="true")
        }
      }
    }
    _ => inspect(false, content="true")
  }
}

///|
test "manual invalid SceneNode matrix keeps parser rejection distinct from total lowering" {
  // The helper deliberately exercises values constructed outside parser
  // provenance.  Parser Err(CoreError) remains a separate observation; it is
  // never substituted with an empty DrawingList result.
  assert_manual_invalid_scene_matrix()
}

fn assert_manual_parser_derived_error(source : String) -> Unit raise {
  match parse_svg(source) {
    Ok(_) => inspect(false, content="true")
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::Data, content="true")
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
      inspect(error.operation() == Some("svg"), content="true")
      inspect(error.context() == Some("svg-numeric-derived"), content="true")
    }
  }
}

fn assert_manual_checked_path_error(
  result : Result[@math.Path2, @error.CoreError],
) -> Unit raise {
  match result {
    Err(error) =>
      assert_eq(error.context(), Some("svg-numeric-derived"))
    Ok(path) =>
      match checked_path_points(path, @math.Affine2::identity()) {
        Ok(_) => inspect(false, content="true")
        Err(error) =>
          assert_eq(error.context(), Some("svg-numeric-derived"))
      }
  }
}

fn assert_manual_empty_path_twice(node : SceneNode) -> Unit raise {
  let first = lower_to_drawing_list(node)
  let second = lower_to_drawing_list(node)
  assert_eq(first.length(), 4)
  assert_eq(second.length(), 4)
  match (first.get(0), first.get(1), first.get(2), first.get(3)) {
    (Some(PushLayer(0.25)), Some(Fill(fill, _)), Some(Stroke(stroke, _, _)), Some(PopLayer)) =>
      {
        assert_eq(fill.length(), 0)
        assert_eq(stroke.length(), 0)
      }
    _ => inspect(false, content="true")
  }
  match (second.get(0), second.get(1), second.get(2), second.get(3)) {
    (Some(PushLayer(0.25)), Some(Fill(fill, _)), Some(Stroke(stroke, _, _)), Some(PopLayer)) =>
      {
        assert_eq(fill.length(), 0)
        assert_eq(stroke.length(), 0)
      }
    _ => inspect(false, content="true")
  }
}

fn assert_manual_invalid_scene_matrix() -> Unit raise {
  // These public-parser assertions prove that parser-originated unsafe data is
  // rejected before a SceneNode or DrawingList exists.  The total-lowering
  // checks below use distinct, explicitly manual values.
  let derived_sources = [
    "<svg viewBox=\"-65536 0 1 1\" width=\"2\" height=\"2\"><rect width=\"1\" height=\"1\"/></svg>",
    "<svg><g transform=\"scale(65536) scale(2)\"><rect width=\"1\" height=\"1\"/></g></svg>",
    "<svg><rect x=\"65536\" width=\"1\" height=\"1\"/></svg>",
    "<svg><circle cx=\"65536\" r=\"1\"/></svg>",
    "<svg><ellipse cx=\"65536\" rx=\"1\" ry=\"1\"/></svg>",
    "<svg><g transform=\"translate(1,0)\"><line x1=\"65536\" y1=\"0\" x2=\"0\" y2=\"0\"/></g></svg>",
    "<svg><g transform=\"translate(1,0)\"><polyline points=\"65536,0 0,0\"/></g></svg>",
    "<svg><g transform=\"translate(1,0)\"><polygon points=\"65536,0 0,0\"/></g></svg>",
    "<svg><g transform=\"translate(1,0)\"><path d=\"M65536 0 L0 0\"/></g></svg>",
  ]
  for source in derived_sources {
    assert_manual_parser_derived_error(source)
  }

  // The fixture is valid parser output and contributes the resolved paint
  // shape (layer, fill, stroke, pop) used by each manually invalid row.
  match parse_svg("<svg><rect width=\"1\" height=\"1\" fill=\"red\" stroke=\"blue\" opacity=\"0.25\"/></svg>") {
    Ok(Svg(_, [Rect(paint, _, _, _, _, _, _)])) => {
      let invalid_root : SvgRoot = {
        width: Some(65536.0),
        height: Some(1.0),
        view_box: Some((2.0, 0.0, 1.0, 1.0)),
        preserve_aspect_ratio: { align_x: 1, align_y: 1, meet: true, none: true },
      }
      match checked_viewbox_transform(invalid_root) {
        Ok(_) => inspect(false, content="true")
        Err(error) =>
          assert_eq(error.context(), Some("svg-numeric-derived"))
      }
      let first_root = lower_to_drawing_list(Svg(invalid_root, [Rect(paint, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0)]))
      let second_root = lower_to_drawing_list(Svg(invalid_root, [Rect(paint, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0)]))
      assert_eq(first_root.length(), 4)
      assert_eq(second_root.length(), 4)
      match (first_root.get(0), first_root.get(1), first_root.get(2), first_root.get(3)) {
        (Some(PushLayer(0.25)), Some(Fill(path, _)), Some(Stroke(_, _, _)), Some(PopLayer)) => inspect(path.length(), content="5")
        _ => inspect(false, content="true")
      }
      match (second_root.get(0), second_root.get(1), second_root.get(2), second_root.get(3)) {
        (Some(PushLayer(0.25)), Some(Fill(path, _)), Some(Stroke(_, _, _)), Some(PopLayer)) => inspect(path.length(), content="5")
        _ => inspect(false, content="true")
      }

      assert_manual_inherited_affine_recovery(paint)

      assert_manual_checked_path_error(checked_rect_path(65536.0, 0.0, 1.0, 1.0, 0.0, 0.0))
      assert_manual_empty_path_twice(Rect(paint, 65536.0, 0.0, 1.0, 1.0, 0.0, 0.0))
      assert_manual_checked_path_error(checked_circle_path(65536.0, 0.0, 1.0))
      assert_manual_empty_path_twice(Circle(paint, 65536.0, 0.0, 1.0))
      assert_manual_checked_path_error(checked_ellipse_path(65536.0, 0.0, 1.0, 1.0))
      assert_manual_empty_path_twice(Ellipse(paint, 65536.0, 0.0, 1.0, 1.0))
      assert_manual_checked_path_error(checked_line_path(65537.0, 0.0, 0.0, 0.0))
      assert_manual_empty_path_twice(Line(paint, 65537.0, 0.0, 0.0, 0.0))

      let invalid_points = [@math.Point2::new(65537.0, 0.0), @math.Point2::new(0.0, 0.0)]
      assert_manual_checked_path_error(checked_polyline_path(invalid_points))
      assert_manual_empty_path_twice(Polyline(paint, invalid_points))
      assert_manual_checked_path_error(checked_polygon_path(invalid_points))
      assert_manual_empty_path_twice(Polygon(paint, invalid_points))

      let invalid_canvas_path = @canvas.CanvasPath::new()
      invalid_canvas_path.move_to(65537.0, 0.0)
      assert_manual_checked_path_error(checked_canvas_path(invalid_canvas_path))
      assert_manual_empty_path_twice(Path(paint, invalid_canvas_path))
      let invalid_path_point = @canvas.CanvasPath::new()
      invalid_path_point.move_to(65536.0, 0.0)
      invalid_path_point.line_to(65537.0, 0.0)
      assert_manual_checked_path_error(checked_canvas_path(invalid_path_point))
      assert_manual_empty_path_twice(Path(paint, invalid_path_point))
    }
    _ => inspect(false, content="true")
  }
}

fn assert_manual_inherited_affine_recovery(paint : Paint) -> Unit raise {
  let outer = @math.Affine2::translate(65536.0, 0.0)
  let inner = @math.Affine2::translate(1.0, 0.0)
  match checked_compose_affine(outer, inner) {
    Ok(_) => inspect(false, content="true")
    Err(error) =>
      assert_eq(error.context(), Some("svg-numeric-derived"))
  }

  let nested = Group(
    outer,
    1.0,
    [Group(inner, 1.0, [Rect(paint, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0)])],
  )
  let first_nested = lower_to_drawing_list(nested)
  let second_nested = lower_to_drawing_list(nested)
  for list in [first_nested, second_nested] {
    inspect(list.length(), content="8")
    match (
      list.get(0),
      list.get(1),
      list.get(2),
      list.get(3),
      list.get(4),
      list.get(5),
      list.get(6),
      list.get(7),
    ) {
      (
        Some(PushTransform(first)),
        Some(PushTransform(second)),
        Some(PushLayer(0.25)),
        Some(Fill(_, _)),
        Some(Stroke(_, _, _)),
        Some(PopLayer),
        Some(PopTransform),
        Some(PopTransform),
      ) => {
        inspect(first.tx(), content="65536")
        assert_eq(second.a(), 1.0)
        assert_eq(second.d(), 1.0)
        assert_eq(second.tx(), 0.0)
        assert_eq(second.ty(), 0.0)
      }
      _ => inspect(false, content="true")
    }
  }

  let root : SvgRoot = {
    width: Some(65536.0),
    height: Some(1.0),
    view_box: Some((0.0, 0.0, 1.0, 1.0)),
    preserve_aspect_ratio: { align_x: 1, align_y: 1, meet: true, none: true },
  }
  let local_scale = @math.Affine2::scale(2.0, 1.0)
  match checked_viewbox_transform(root) {
    Ok(map) =>
      match checked_compose_affine(map, local_scale) {
        Ok(_) => inspect(false, content="true")
        Err(error) =>
          assert_eq(error.context(), Some("svg-numeric-derived"))
      }
    Err(_) => inspect(false, content="true")
  }
  let viewbox_nested = Svg(
    root,
    [Group(local_scale, 1.0, [Rect(paint, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0)])],
  )
  for list in [lower_to_drawing_list(viewbox_nested), lower_to_drawing_list(viewbox_nested)] {
    inspect(list.length(), content="8")
    match (
      list.get(0),
      list.get(1),
      list.get(2),
      list.get(3),
      list.get(4),
      list.get(5),
      list.get(6),
      list.get(7),
    ) {
      (
        Some(PushTransform(map)),
        Some(PushTransform(group)),
        Some(PushLayer(0.25)),
        Some(Fill(_, _)),
        Some(Stroke(_, _, _)),
        Some(PopLayer),
        Some(PopTransform),
        Some(PopTransform),
      ) => {
        assert_eq(map.a(), 65536.0)
        assert_eq(map.d(), 1.0)
        assert_eq(group.a(), 1.0)
        assert_eq(group.d(), 1.0)
        assert_eq(group.tx(), 0.0)
        assert_eq(group.ty(), 0.0)
      }
      _ => inspect(false, content="true")
    }
  }

  let valid = Group(
    @math.Affine2::translate(10.0, 0.0),
    1.0,
    [Group(@math.Affine2::translate(1.0, 0.0), 1.0, [Rect(paint, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0)])],
  )
  let valid_list = lower_to_drawing_list(valid)
  match (
    valid_list.get(0),
    valid_list.get(1),
    valid_list.get(2),
    valid_list.get(3),
    valid_list.get(4),
    valid_list.get(5),
    valid_list.get(6),
    valid_list.get(7),
  ) {
    (
      Some(PushTransform(first)),
      Some(PushTransform(second)),
      Some(PushLayer(0.25)),
      Some(Fill(_, _)),
      Some(Stroke(_, _, _)),
      Some(PopLayer),
      Some(PopTransform),
      Some(PopTransform),
    ) => {
      assert_eq(first.tx(), 10.0)
      assert_eq(second.tx(), 1.0)
    }
    _ => inspect(false, content="true")
  }
}
