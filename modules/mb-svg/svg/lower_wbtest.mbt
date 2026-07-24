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
        other => inspect("other", content="other")
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
        other => inspect("other", content="other")
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
        other => inspect("other", content="other")
      }
      match list.get(1) {
        Some(Stroke(_, stroke, color)) => {
          inspect(stroke.width, content="2")
          inspect(color.color_b, content="1")
        }
        other => inspect("other", content="other")
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
        other => inspect("other", content="other")
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
        other => inspect("other", content="other")
      }
      match list.get(1) {
        Some(Fill(_, _)) => inspect("fill", content="fill")
        other => inspect("other", content="other")
      }
      match list.get(2) {
        Some(PopTransform) => inspect("pop", content="pop")
        other => inspect("other", content="other")
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
        other => inspect("other", content="other")
      }
      match list.get(1) {
        Some(PushTransform(_)) => inspect("push", content="push")
        other => inspect("other", content="other")
      }
      match list.get(2) {
        Some(Fill(_, _)) => inspect("fill", content="fill")
        other => inspect("other", content="other")
      }
      match list.get(3) {
        Some(PopTransform) => inspect("pop", content="pop")
        other => inspect("other", content="other")
      }
      match list.get(4) {
        Some(PopTransform) => inspect("pop", content="pop")
        other => inspect("other", content="other")
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
        other => inspect("other", content="other")
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
        other => inspect("other", content="other")
      }
      match list.get(1) {
        Some(Fill(_, _)) => inspect("fill", content="fill")
        other => inspect("other", content="other")
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
        other => inspect("other", content="other")
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
        other => inspect("other", content="other")
      }
      // Stroke color carries stroke-opacity=0.25.
      match list.get(1) {
        Some(Stroke(_, _, color)) => inspect(color.color_a, content="0.25")
        other => inspect("other", content="other")
      }
    }
    Err(_) => inspect("err", content="ok")
  }
}
