// Trigonometric primitives re-exported from the standard math library.
//
// mb-core/math is the single "geometry + basic math" facade for MNF: consumers
// (mb-canvas arc construction, future mb-svg path evaluation) import only
// tchivs/mb-core/math and do not need to reach into moonbitlang/core/math
// directly. These wrappers forward to the standard library so the underlying
// implementation stays target-native and portable.

///|
/// Cosine of `radians`.
pub fn cos(radians : Double) -> Double {
  @stdlib_math.cos(radians)
}

///|
/// Sine of `radians`.
pub fn sin(radians : Double) -> Double {
  @stdlib_math.sin(radians)
}

///|
/// Tangent of `radians`. Returns a large-magnitude value near ±π/2 rather than
/// an error, matching the standard-library behavior.
pub fn tan(radians : Double) -> Double {
  @stdlib_math.tan(radians)
}

///|
/// Arc-cosine of `x` in radians; `x` is expected in [-1, 1].
pub fn acos(x : Double) -> Double {
  @stdlib_math.acos(x)
}

///|
/// Arc-sine of `x` in radians; `x` is expected in [-1, 1].
pub fn asin(x : Double) -> Double {
  @stdlib_math.asin(x)
}

///|
/// Arc-tangent of `y / x` using the signs of both arguments to determine the
/// quadrant, in radians, in (-π, π].
pub fn atan2(y : Double, x : Double) -> Double {
  @stdlib_math.atan2(y, x)
}
