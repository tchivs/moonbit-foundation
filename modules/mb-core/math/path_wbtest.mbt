// White-box tests for Path2 vector path geometry.

///|
test "path2 push and length track command count" {
  let path = Path2::new()
  inspect(path.length(), content="0")
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(LineTo(Point2::new(10.0, 0.0)))
  path.push(LineTo(Point2::new(10.0, 10.0)))
  path.push(Close)
  inspect(path.length(), content="4")
}

///|
test "path2 get retrieves commands by index" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(1.0, 2.0)))
  path.push(LineTo(Point2::new(3.0, 4.0)))
  match path.get(0) {
    Some(MoveTo(p)) => {
      inspect(approx(p.x(), 1.0), content="true")
      inspect(approx(p.y(), 2.0), content="true")
    }
    _ => inspect(false, content="true")
  }
  match path.get(1) {
    Some(LineTo(p)) => inspect(approx(p.x(), 3.0), content="true")
    _ => inspect(false, content="true")
  }
  // Out of bounds.
  match path.get(5) {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}

///|
test "path2 bounds of a triangle" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(LineTo(Point2::new(10.0, 0.0)))
  path.push(LineTo(Point2::new(5.0, 8.0)))
  path.push(Close)
  match path.bounds() {
    Some(r) => {
      inspect(approx(r.min_x(), 0.0), content="true")
      inspect(approx(r.min_y(), 0.0), content="true")
      inspect(approx(r.width(), 10.0), content="true")
      inspect(approx(r.height(), 8.0), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "path2 bounds includes bezier control points" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(QuadTo(Point2::new(15.0, 20.0), Point2::new(10.0, 0.0)))
  match path.bounds() {
    Some(r) => {
      // Control point (15, 20) extends the bounds.
      inspect(approx(r.max_x(), 15.0), content="true")
      inspect(approx(r.max_y(), 20.0), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "path2 bounds of empty path returns None" {
  let path = Path2::new()
  match path.bounds() {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}

///|
test "path2 each iterates all commands in order" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(LineTo(Point2::new(1.0, 0.0)))
  path.push(Close)
  let visited : Array[String] = []
  path.each(fn(cmd) {
    match cmd {
      MoveTo(_) => visited.push("M")
      LineTo(_) => visited.push("L")
      QuadTo(_, _) => visited.push("Q")
      CubicTo(_, _, _) => visited.push("C")
      Close => visited.push("Z")
    }
  })
  inspect(visited.length(), content="3")
  inspect(visited[0] == "M", content="true")
  inspect(visited[1] == "L", content="true")
  inspect(visited[2] == "Z", content="true")
}

///|
test "path2 with cubic commands computes bounds correctly" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(CubicTo(Point2::new(-5.0, 10.0), Point2::new(15.0, 10.0), Point2::new(10.0, 0.0)))
  match path.bounds() {
    Some(r) => {
      inspect(approx(r.min_x(), -5.0), content="true")
      inspect(approx(r.max_x(), 15.0), content="true")
      inspect(approx(r.max_y(), 10.0), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "affine apply_to_path transforms all point commands" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(1.0, 2.0)))
  path.push(LineTo(Point2::new(3.0, 4.0)))
  path.push(QuadTo(Point2::new(5.0, 6.0), Point2::new(7.0, 8.0)))
  path.push(CubicTo(Point2::new(9.0, 10.0), Point2::new(11.0, 12.0), Point2::new(13.0, 14.0)))
  path.push(Close)
  let t = Affine2::translate(10.0, 20.0)
  let out = t.apply_to_path(path)
  inspect(out.length(), content="5")
  match out.get(0) {
    Some(MoveTo(p)) => inspect(approx(p.x(), 11.0) && approx(p.y(), 22.0), content="true")
    _ => inspect(false, content="true")
  }
  match out.get(1) {
    Some(LineTo(p)) => inspect(approx(p.x(), 13.0) && approx(p.y(), 24.0), content="true")
    _ => inspect(false, content="true")
  }
  match out.get(2) {
    Some(QuadTo(c, e)) =>
      inspect(
        approx(c.x(), 15.0) && approx(c.y(), 26.0) && approx(e.x(), 17.0) && approx(e.y(), 28.0),
        content="true",
      )
    _ => inspect(false, content="true")
  }
  match out.get(3) {
    Some(CubicTo(c1, c2, e)) =>
      inspect(
        approx(c1.x(), 19.0) &&
        approx(c1.y(), 30.0) &&
        approx(c2.x(), 21.0) &&
        approx(c2.y(), 32.0) &&
        approx(e.x(), 23.0) &&
        approx(e.y(), 34.0),
        content="true",
      )
    _ => inspect(false, content="true")
  }
  match out.get(4) {
    Some(Close) => inspect(true, content="true")
    _ => inspect(false, content="true")
  }
  // Source path is unchanged.
  inspect(path.length(), content="5")
  match path.get(0) {
    Some(MoveTo(p)) => inspect(approx(p.x(), 1.0) && approx(p.y(), 2.0), content="true")
    _ => inspect(false, content="true")
  }
}

///|
test "affine apply_to_path of empty path is empty" {
  let empty = Path2::new()
  let out = Affine2::scale(2.0, 2.0).apply_to_path(empty)
  inspect(out.length(), content="0")
}
