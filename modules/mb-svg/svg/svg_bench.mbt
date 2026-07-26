// Benchmarks for mb-svg performance-sensitive work (RFC 0002 §11.4).
//
// MoonBit benchmarks live in *_bench.mbt files and use a test block with an
// `@bench.T` argument; `b.bench(fn() { ... })` measures the closure, auto-
// picking iteration counts. Pure-function results are sunk through `keep` to
// defeat dead-code elimination. Run with `moon bench`.
//
// Workloads declared per RFC 0002 §11.4: path expansion, transform
// composition, and the full parse→lower pipeline. Each declares its workload
// size in the name so baselines are reproducible.

///|
fn require_benchmark(condition : Bool, message : String) -> Unit {
  if !condition {
    abort(message)
  }
}

///|
fn path_parse_corpus() -> String {
  let source = StringBuilder::new()
  source.write_string("M0 0")
  for i = 0; i < 1000; i = i + 1 {
    source.write_string(" L")
    source.write_string((i % 100).to_string())
    source.write_string(" ")
    source.write_string((i % 100).to_string())
  }
  source.to_string()
}

// Frozen workload provenance for the native-only evidence record in Plan 94-02.
// corpus/path: e97e1c8a8e29fdb3e84c309e421de34d41cbab7583cf1e88cf94a67af51eb259
// correctness/path: 0c7d3af32d324a136215c1158c4aab127d11e160f4b9239991114a0303762f22
// corpus/transform: c0ed3307e143d7cb20fd90e531e6208a14bbe2e42ce2816a0579d04cbd320840
// correctness/transform: ec32349185e19b24757e391c72ac5fa8709f889847a0035b7257fc3e0ba483ff
// corpus/parse-to-lower: db053c95e904e016041f8b2f4a5e6471ed4bf1b144cfd0fc99c44d7d670cdddc
// correctness/parse-to-lower: e76479b6744a5f062c21d7e5502971a45388346767e9d91aea0119c4340c18e5
// transform correctness: v1|ok|a=-764.5825470346006|b=981.6717123516748|c=-550.8736348781798|d=-664.151879387284|tx=-1060.1606213143448|ty=997.9648720635827|probe_x=1.25|probe_y=-2.5|out_x=-638.704717912146|out_y=3885.434210971386|tolerance=1e-9

///|
fn transform_composition_corpus() -> String {
  let source = StringBuilder::new()
  for i = 0; i < 10; i = i + 1 {
    source.write_string("translate(1,1) scale(2) rotate(15) skewX(5) skewY(3)")
  }
  source.to_string()
}

///|
fn parse_to_lower_corpus() -> String {
  let source = StringBuilder::new()
  source.write_string("<svg>")
  for i = 0; i < 50; i = i + 1 {
    source.write_string("<rect x=\"")
    source.write_string(i.to_string())
    source.write_string("\" y=\"0\" width=\"1\" height=\"1\" fill=\"red\"/>")
  }
  source.write_string("</svg>")
  source.to_string()
}

///|
fn in_svg_numeric_envelope(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf() && value.abs() <= 65536.0
}

///|
test "bench path-parse/1000-line-to" (b : @bench.T) {
  let corpus = path_parse_corpus()
  match parse_path_data(corpus) {
    Ok(path) => {
      let commands = path.to_path2()
      require_benchmark(
        commands.length() == 1001,
        "path benchmark command count",
      )
      match commands.get(0) {
        Some(@math.PathCommand::MoveTo(point)) =>
          require_benchmark(
            point.x() == 0.0 && point.y() == 0.0,
            "path benchmark first command",
          )
        _ => abort("path benchmark first command")
      }
      match commands.get(1000) {
        Some(@math.PathCommand::LineTo(point)) =>
          require_benchmark(
            point.x() == 99.0 && point.y() == 99.0,
            "path benchmark last command",
          )
        _ => abort("path benchmark last command")
      }
    }
    Err(_) => abort("path benchmark parse")
  }
  b.bench(fn() { b.keep(parse_path_data(corpus)) })
}

///|
test "bench transform-composition/50-segment" (b : @bench.T) {
  let corpus = transform_composition_corpus()
  match parse_transform(corpus) {
    Ok(affine) => {
      require_benchmark(
        in_svg_numeric_envelope(affine.a()) &&
        in_svg_numeric_envelope(affine.b()) &&
        in_svg_numeric_envelope(affine.c()) &&
        in_svg_numeric_envelope(affine.d()) &&
        in_svg_numeric_envelope(affine.tx()) &&
        in_svg_numeric_envelope(affine.ty()),
        "transform benchmark affine envelope",
      )
      let tolerance = 1.0e-9
      let output = affine.apply(@math.Point2::new(1.25, -2.5))
      require_benchmark(
        (affine.a() - -764.5825470346006).abs() <= tolerance &&
        (affine.b() - 981.6717123516748).abs() <= tolerance &&
        (affine.c() - -550.8736348781798).abs() <= tolerance &&
        (affine.d() - -664.151879387284).abs() <= tolerance &&
        (affine.tx() - -1060.1606213143448).abs() <= tolerance &&
        (affine.ty() - 997.9648720635827).abs() <= tolerance &&
        (output.x() - -638.704717912146).abs() <= tolerance &&
        (output.y() - 3885.434210971386).abs() <= tolerance,
        "transform benchmark oracle",
      )
    }
    Err(_) => abort("transform benchmark parse")
  }
  b.bench(fn() { b.keep(parse_transform(corpus)) })
}

///|
test "bench parse-to-lower/50-rect" (b : @bench.T) {
  let corpus = parse_to_lower_corpus()
  match parse_svg(corpus) {
    Ok(scene) => {
      let drawing_list = lower_to_drawing_list(scene)
      require_benchmark(
        drawing_list.length() == 50,
        "parse-to-lower benchmark operation count",
      )
      for index = 0; index < 50; index = index + 1 {
        match drawing_list.get(index) {
          Some(Fill(_, _)) => ()
          _ => abort("parse-to-lower benchmark operation shape")
        }
      }
    }
    Err(_) => abort("parse-to-lower benchmark parse")
  }
  b.bench(fn() {
    match parse_svg(corpus) {
      Ok(scene) => b.keep(lower_to_drawing_list(scene))
      Err(_) => abort("parse-to-lower benchmark parse")
    }
  })
}
