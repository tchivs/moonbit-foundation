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

fn require_benchmark(condition : Bool, message : String) -> Unit {
  if !condition {
    abort(message)
  }
}

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

///|
test "bench path-parse/1000-line-to" (b : @bench.T) {
  let corpus = path_parse_corpus()
  match parse_path_data(corpus) {
    Ok(path) => {
      let commands = path.to_path2()
      require_benchmark(commands.length() == 1001, "path benchmark command count")
      match commands.get(0) {
        Some(@math.PathCommand::MoveTo(point)) =>
          require_benchmark(point.x() == 0.0 && point.y() == 0.0, "path benchmark first command")
        _ => abort("path benchmark first command")
      }
      match commands.get(1000) {
        Some(@math.PathCommand::LineTo(point)) =>
          require_benchmark(point.x() == 99.0 && point.y() == 99.0, "path benchmark last command")
        _ => abort("path benchmark last command")
      }
    }
    Err(_) => abort("path benchmark parse")
  }
  b.bench(fn() {
    b.keep(parse_path_data(corpus))
  })
}

///|
test "bench parse_transform: 50-segment transform list" (b : @bench.T) {
  // Build "translate(1,1) scale(2) rotate(15) skewX(5) ..." × 10 segments.
  let s = StringBuilder::new()
  for i = 0; i < 10; i = i + 1 {
    s.write_string("translate(1,1) scale(2) rotate(15) skewX(5) skewY(3) matrix(1,0,0,1,2,3)")
  }
  let t = s.to_string()
  b.bench(fn() {
    b.keep(parse_transform(t))
  })
}

///|
test "bench parse_svg + lower_to_drawing_list: 50-rect document" (b : @bench.T) {
  // A document with 50 rects — exercises parse, scene build, and lower.
  let s = StringBuilder::new()
  s.write_string("<svg>")
  for i = 0; i < 50; i = i + 1 {
    s.write_string("<rect x=\"")
    s.write_string(i.to_string())
    s.write_string("\" y=\"0\" width=\"1\" height=\"1\" fill=\"red\"/>")
  }
  s.write_string("</svg>")
  let doc = s.to_string()
  b.bench(fn() {
    match parse_svg(doc) {
      Ok(scene) => b.keep(lower_to_drawing_list(scene))
      Err(_) => b.keep(())
    }
  })
}
