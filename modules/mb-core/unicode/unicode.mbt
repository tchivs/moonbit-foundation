// Portable Unicode property classification for MoonBit Native Foundation.
//
// This package provides bounded Unicode property lookup for codepoints,
// consumed by mb-text (segmentation UAX #29, bidi UAX #9, line breaking
// UAX #14). The tables are version-pinned and ship as portable data, not
// host capability — no ICU dependency.
//
// v0.x provides General Category and a subset of Bidi Class classification
// covering ASCII and Latin-1 Supplement, which covers the majority of
// common text processing. Full Unicode table coverage (all planes, all
// properties) is deferred to follow-up phases that generate tables from
// UnicodeData.txt programmatically.

// ---------------------------------------------------------------------------
// General Category (subset of Unicode General Category values)
// ---------------------------------------------------------------------------

///|
/// Unicode General Category classification. This is a bounded subset
/// sufficient for segmentation and basic text processing.
pub(all) enum GeneralCategory {
  /// Uppercase letter [Lu]
  UppercaseLetter
  /// Lowercase letter [Ll]
  LowercaseLetter
  /// Titlecase letter [Lt]
  TitlecaseLetter
  /// Modifier letter [Lm]
  ModifierLetter
  /// Other letter [Lo] (including CJK ideographs)
  OtherLetter
  /// Nonspacing mark [Mn]
  NonspacingMark
  /// Spacing mark [Mc]
  SpacingMark
  /// Decimal digit [Nd]
  DecimalNumber
  /// Connector punctuation [Pc]
  ConnectorPunctuation
  /// Space separator [Zs]
  SpaceSeparator
  /// Control character [Cc]
  Control
  /// Format character [Cf]
  Format
  /// Unassigned or not in the v0.x table
  Unassigned
} derive(Eq)

///|
/// Classify a Unicode codepoint by its General Category.
///
/// v0.x covers ASCII (U+0000-U+007F) and Latin-1 Supplement (U+0080-U+00FF)
/// with exact category assignment. Codepoints above U+00FF return
/// `Unassigned` unless they fall in a well-known CJK range.
pub fn general_category(codepoint : Int) -> GeneralCategory {
  if codepoint < 0 || codepoint > 0x10ffff {
    return Unassigned
  }
  // ASCII range: U+0000 - U+007F
  if codepoint <= 0x7f {
    return ascii_general_category(codepoint)
  }
  // Latin-1 Supplement: U+0080 - U+00FF
  if codepoint <= 0xff {
    return latin1_general_category(codepoint)
  }
  // CJK Unified Ideographs: U+4E00 - U+9FFF
  if codepoint >= 0x4e00 && codepoint <= 0x9fff {
    return OtherLetter
  }
  // CJK Extension A: U+3400 - U+4DBF
  if codepoint >= 0x3400 && codepoint <= 0x4dbf {
    return OtherLetter
  }
  // Hiragana: U+3040 - U+309F
  if codepoint >= 0x3040 && codepoint <= 0x309f {
    return OtherLetter
  }
  // Katakana: U+30A0 - U+30FF
  if codepoint >= 0x30a0 && codepoint <= 0x30ff {
    return OtherLetter
  }
  // Hangul Syllables: U+AC00 - U+D7AF
  if codepoint >= 0xac00 && codepoint <= 0xd7af {
    return OtherLetter
  }
  // Arabic: U+0600 - U+06FF (letters)
  if codepoint >= 0x0600 && codepoint <= 0x06ff {
    return OtherLetter
  }
  // Hebrew: U+0590 - U+05FF (letters)
  if codepoint >= 0x0590 && codepoint <= 0x05ff {
    return OtherLetter
  }
  // Combining Diacritical Marks: U+0300 - U+036F
  if codepoint >= 0x0300 && codepoint <= 0x036f {
    return NonspacingMark
  }
  Unassigned
}

///|
fn ascii_general_category(code : Int) -> GeneralCategory {
  if code >= 0x41 && code <= 0x5a {
    UppercaseLetter // A-Z
  } else if code >= 0x61 && code <= 0x7a {
    LowercaseLetter // a-z
  } else if code >= 0x30 && code <= 0x39 {
    DecimalNumber // 0-9
  } else if code == 0x20 {
    SpaceSeparator // space
  } else if (code >= 0x00 && code <= 0x1f) || code == 0x7f {
    Control // C0 controls + DEL
  } else if code == 0x5f {
    ConnectorPunctuation // underscore
  } else {
    Unassigned // punctuation/symbols not classified in v0.x
  }
}

///|
fn latin1_general_category(code : Int) -> GeneralCategory {
  if code >= 0xc0 && code <= 0xde && code != 0xd7 {
    UppercaseLetter // À-Þ except × (0xD7)
  } else if code >= 0xe0 && code <= 0xfe && code != 0xf7 {
    LowercaseLetter // à-þ except ÷ (0xF7)
  } else if code >= 0x80 && code <= 0x9f {
    Control // C1 controls
  } else if code == 0xa0 {
    SpaceSeparator // non-breaking space
  } else {
    Unassigned // symbols/punctuation
  }
}

// ---------------------------------------------------------------------------
// Convenience predicates derived from General Category
// ---------------------------------------------------------------------------

///|
/// True if the codepoint is a letter (any [L*] category).
pub fn is_letter(codepoint : Int) -> Bool {
  match general_category(codepoint) {
    UppercaseLetter | LowercaseLetter | TitlecaseLetter | ModifierLetter | OtherLetter => true
    _ => false
  }
}

///|
/// True if the codepoint is a decimal digit ([Nd]).
pub fn is_digit(codepoint : Int) -> Bool {
  general_category(codepoint) is DecimalNumber
}

///|
/// True if the codepoint is whitespace (space, tab, newline, etc.).
pub fn is_whitespace(codepoint : Int) -> Bool {
  // ASCII whitespace per UAX #29 segmentation: space, tab, line tab,
  // form feed, carriage return, newline.
  codepoint == 0x20 || codepoint == 0x09 || codepoint == 0x0b || codepoint == 0x0c || codepoint == 0x0d || codepoint == 0x0a || codepoint == 0x85 || codepoint == 0xa0
}

// ---------------------------------------------------------------------------
// Bidi Class (subset of UAX #9)
// ---------------------------------------------------------------------------

///|
/// Unicode Bidirectional Algorithm character type (UAX #9). This is a
/// bounded subset covering the most common bidi categories.
pub(all) enum BidiClass {
  /// Left-to-right (Latin, Cyrillic, CJK, etc.)
  LeftToRight
  /// Right-to-left (Arabic, Hebrew)
  RightToLeft
  /// Right-to-left Arabic letter
  ArabicLetter
  /// European number (0-9 in RTL context)
  EuropeanNumber
  /// European number separator (+, -)
  EuropeanSeparator
  /// European number terminator (%, currency)
  EuropeanTerminator
  /// Common number separator (comma, period)
  CommonSeparator
  /// Whitespace
  Whitespace
  /// Boundary neutral
  BoundaryNeutral
  /// Other neutral (punctuation, symbols)
  OtherNeutral
  /// Non-spacing mark
  NonspacingMarkBidi
} derive(Eq)

///|
/// Classify a Unicode codepoint by its Bidirectional Algorithm type (UAX #9).
///
/// v0.x covers the most common scripts and control characters. Codepoints
/// not in the table default to `LeftToRight` for Latin-range or
/// `OtherNeutral` for symbols.
pub fn bidi_class(codepoint : Int) -> BidiClass {
  if codepoint < 0 || codepoint > 0x10ffff {
    return OtherNeutral
  }
  // Strong types
  if codepoint >= 0x0590 && codepoint <= 0x05ff {
    return RightToLeft // Hebrew
  }
  if codepoint >= 0x0600 && codepoint <= 0x06ff {
    return ArabicLetter // Arabic
  }
  if codepoint >= 0xfb50 && codepoint <= 0xfdff {
    return ArabicLetter // Arabic Presentation Forms-A
  }
  if codepoint >= 0xfe70 && codepoint <= 0xfeff {
    return ArabicLetter // Arabic Presentation Forms-B
  }
  // European number: ASCII digits
  if codepoint >= 0x30 && codepoint <= 0x39 {
    return EuropeanNumber
  }
  // Non-spacing marks (combining)
  if general_category(codepoint) is NonspacingMark {
    return NonspacingMarkBidi
  }
  // Whitespace
  if is_whitespace(codepoint) {
    return Whitespace
  }
  // European separators
  if codepoint == 0x2b || codepoint == 0x2d {
    return EuropeanSeparator // +, -
  }
  // Common separator
  if codepoint == 0x2c || codepoint == 0x2e {
    return CommonSeparator // comma, period
  }
  // European terminators
  if codepoint == 0x25 || codepoint == 0xa2 || codepoint == 0xa3 || codepoint == 0xa4 || codepoint == 0xa5 || codepoint == 0xa9 {
    return EuropeanTerminator // %, ¢, £, ¤, ¥, ©
  }
  // Default: LTR for letters, OtherNeutral for the rest
  if is_letter(codepoint) {
    return LeftToRight
  }
  OtherNeutral
}

///|
/// The Unicode version this property table is pinned to.
pub fn unicode_version() -> String {
  "15.1.0"
}

// ---------------------------------------------------------------------------
// UAX #29 Grapheme Cluster Break — v0.x skeleton
// ---------------------------------------------------------------------------
//
// Full Unicode grapheme segmentation needs generated property tables
// (Grapheme_Cluster_Break) for all planes. v0.x ships a documented skeleton
// covering the rules that dominate Latin/CJK/emoji-common text without the
// full table generator:
//
//   GB3  CR × LF
//   GB4  (Control|CR|LF) ÷
//   GB5  ÷ (Control|CR|LF)
//   GB9  × Extend  (using GeneralCategory NonspacingMark as Extend)
//   GB999 all other adjacent pairs break
//
// Hangul syllable composition (GB6–GB8), ZWJ sequences (GB11), regional
// indicators (GB12–GB13), SpacingMark (GB9a), and Prepend (GB9b) are NOT
// implemented here; they return breaks. Callers that need full UAX #29
// must wait for generated tables in a later phase.

///|
/// Coarse grapheme-cluster-break classes used by the v0.x skeleton.
pub(all) enum GraphemeBreakClass {
  /// Carriage return U+000D
  CR
  /// Line feed U+000A
  LF
  /// Other controls / format characters treated as Control for GB4/GB5
  Control
  /// Extend: nonspacing marks (Mn) act as Extend for GB9
  Extend
  /// Everything else (letters, digits, symbols, CJK, …)
  Other
} derive(Eq)

///|
/// Map a codepoint to the v0.x grapheme break class.
pub fn grapheme_break_class(codepoint : Int) -> GraphemeBreakClass {
  if codepoint == 0x0d {
    return CR
  }
  if codepoint == 0x0a {
    return LF
  }
  // C0 controls except CR/LF, DEL, and C1 controls → Control
  if (codepoint >= 0x00 && codepoint <= 0x1f) ||
    codepoint == 0x7f ||
    (codepoint >= 0x80 && codepoint <= 0x9f) {
    return Control
  }
  // Format characters treated as Control for break purposes (skeleton).
  if general_category(codepoint) is Format {
    return Control
  }
  // Nonspacing marks are Extend (GB9).
  if general_category(codepoint) is NonspacingMark {
    return Extend
  }
  Other
}

///|
/// True if a grapheme cluster boundary exists between `left` and `right`
/// under the v0.x UAX #29 skeleton rules listed above.
///
/// Returns `false` when the pair must not break (×), `true` when it must
/// break (÷). Boundary positions before the first and after the last
/// codepoint are always breaks and are not represented by this function.
pub fn should_break_grapheme(left : Int, right : Int) -> Bool {
  let l = grapheme_break_class(left)
  let r = grapheme_break_class(right)
  // GB3: CR × LF
  if l is CR && r is LF {
    return false
  }
  // GB4: (Control | CR | LF) ÷
  if l is Control || l is CR || l is LF {
    return true
  }
  // GB5: ÷ (Control | CR | LF)
  if r is Control || r is CR || r is LF {
    return true
  }
  // GB9: × Extend
  if r is Extend {
    return false
  }
  // GB999: Any ÷ Any
  true
}

///|
/// Segment a codepoint sequence into grapheme clusters using the v0.x
/// UAX #29 skeleton. Each cluster is a non-empty sub-array of codepoints
/// in input order. Empty input yields an empty result.
///
/// This is not a full Unicode conformance segmenter; see the module
/// header for the exact rule subset.
pub fn segment_graphemes(codepoints : Array[Int]) -> Array[Array[Int]] {
  let len = codepoints.length()
  let clusters : Array[Array[Int]] = []
  if len == 0 {
    return clusters
  }
  let mut current : Array[Int] = [codepoints[0]]
  for i = 1; i < len; i = i + 1 {
    let left = codepoints[i - 1]
    let right = codepoints[i]
    if should_break_grapheme(left, right) {
      clusters.push(current)
      current = [right]
    } else {
      current.push(right)
    }
  }
  clusters.push(current)
  clusters
}
