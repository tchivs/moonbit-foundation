// White-box tests for Unicode property classification.

///|
test "general_category classifies ASCII letters and digits" {
  inspect(general_category(0x41) is UppercaseLetter, content="true") // 'A'
  inspect(general_category(0x5a) is UppercaseLetter, content="true") // 'Z'
  inspect(general_category(0x61) is LowercaseLetter, content="true") // 'a'
  inspect(general_category(0x7a) is LowercaseLetter, content="true") // 'z'
  inspect(general_category(0x30) is DecimalNumber, content="true") // '0'
  inspect(general_category(0x39) is DecimalNumber, content="true") // '9'
}

///|
test "general_category classifies ASCII control and space" {
  inspect(general_category(0x00) is Control, content="true") // NUL
  inspect(general_category(0x0a) is Control, content="true") // LF
  inspect(general_category(0x7f) is Control, content="true") // DEL
  inspect(general_category(0x20) is SpaceSeparator, content="true") // space
  inspect(general_category(0x5f) is ConnectorPunctuation, content="true") // '_'
}

///|
test "general_category classifies Latin-1 Supplement" {
  inspect(general_category(0xc0) is UppercaseLetter, content="true") // À
  inspect(general_category(0xdc) is UppercaseLetter, content="true") // Ü
  inspect(general_category(0xe0) is LowercaseLetter, content="true") // à
  inspect(general_category(0xfc) is LowercaseLetter, content="true") // ü
  inspect(general_category(0x80) is Control, content="true") // C1 control
  inspect(general_category(0xa0) is SpaceSeparator, content="true") // NBSP
  // × (0xD7) and ÷ (0xF7) are symbols, not letters
  inspect(general_category(0xd7) is Unassigned, content="true")
  inspect(general_category(0xf7) is Unassigned, content="true")
}

///|
test "general_category classifies CJK and combining marks" {
  inspect(general_category(0x4e00) is OtherLetter, content="true") // CJK 一
  inspect(general_category(0x9999) is OtherLetter, content="true") // CJK 香
  inspect(general_category(0x3042) is OtherLetter, content="true") // Hiragana あ
  inspect(general_category(0x30ab) is OtherLetter, content="true") // Katakana カ
  inspect(general_category(0xac00) is OtherLetter, content="true") // Hangul 가
  inspect(general_category(0x0301) is NonspacingMark, content="true") // combining acute
}

///|
test "is_letter covers ASCII, Latin-1, and CJK" {
  inspect(is_letter(0x41), content="true") // 'A'
  inspect(is_letter(0xe9), content="true") // 'é'
  inspect(is_letter(0x4e2d), content="true") // '中'
  inspect(is_letter(0x30), content="false") // '0'
  inspect(is_letter(0x20), content="false") // space
}

///|
test "is_digit detects only decimal numbers" {
  inspect(is_digit(0x30), content="true") // '0'
  inspect(is_digit(0x39), content="true") // '9'
  inspect(is_digit(0x41), content="false") // 'A'
  inspect(is_digit(0x20), content="false") // space
}

///|
test "is_whitespace detects standard whitespace" {
  inspect(is_whitespace(0x20), content="true") // space
  inspect(is_whitespace(0x09), content="true") // tab
  inspect(is_whitespace(0x0a), content="true") // LF
  inspect(is_whitespace(0x0d), content="true") // CR
  inspect(is_whitespace(0xa0), content="true") // NBSP
  inspect(is_whitespace(0x41), content="false") // 'A'
}

///|
test "bidi_class classifies strong types" {
  inspect(bidi_class(0x41) is LeftToRight, content="true") // 'A' Latin
  inspect(bidi_class(0x4e00) is LeftToRight, content="true") // CJK
  inspect(bidi_class(0x05d0) is RightToLeft, content="true") // Hebrew Alef
  inspect(bidi_class(0x0627) is ArabicLetter, content="true") // Arabic Alef
}

///|
test "bidi_class classifies numbers and marks" {
  inspect(bidi_class(0x30) is EuropeanNumber, content="true") // '0'
  inspect(bidi_class(0x0301) is NonspacingMarkBidi, content="true") // combining acute
}

///|
test "bidi_class classifies whitespace and neutrals" {
  inspect(bidi_class(0x20) is Whitespace, content="true") // space
  inspect(bidi_class(0x2c) is CommonSeparator, content="true") // comma
  inspect(bidi_class(0x2b) is EuropeanSeparator, content="true") // '+'
}

///|
test "unicode_version returns pinned version" {
  inspect(unicode_version() == "15.1.0", content="true")
}

///|
test "general_category rejects out-of-range codepoints" {
  inspect(general_category(-1) is Unassigned, content="true")
  inspect(general_category(0x110000) is Unassigned, content="true")
}

///|
test "grapheme_break_class classifies CR LF Control Extend Other" {
  inspect(grapheme_break_class(0x0d) is CR, content="true")
  inspect(grapheme_break_class(0x0a) is LF, content="true")
  inspect(grapheme_break_class(0x00) is Control, content="true")
  inspect(grapheme_break_class(0x0301) is Extend, content="true") // combining acute
  inspect(grapheme_break_class(0x41) is Other, content="true") // 'A'
  inspect(grapheme_break_class(0x4e00) is Other, content="true") // CJK
}

///|
test "should_break_grapheme implements GB3 GB4 GB5 GB9 GB999 skeleton" {
  // GB3: CR × LF
  inspect(should_break_grapheme(0x0d, 0x0a), content="false")
  // GB4: CR ÷ Other
  inspect(should_break_grapheme(0x0d, 0x41), content="true")
  // GB5: Other ÷ LF
  inspect(should_break_grapheme(0x41, 0x0a), content="true")
  // GB9: Other × Extend
  inspect(should_break_grapheme(0x65, 0x0301), content="false") // e + combining acute
  // GB999: Other ÷ Other
  inspect(should_break_grapheme(0x41, 0x42), content="true")
  // CJK pair breaks (no Hangul composition in skeleton)
  inspect(should_break_grapheme(0x4e00, 0x4e8c), content="true")
}

///|
test "segment_graphemes groups base plus combining mark" {
  // "e\u{0301}" → one cluster [0x65, 0x0301]
  let cps = [0x65, 0x0301, 0x61]
  let clusters = segment_graphemes(cps)
  inspect(clusters.length(), content="2")
  inspect(clusters[0].length(), content="2")
  inspect(clusters[0][0], content="101")
  inspect(clusters[0][1], content="769")
  inspect(clusters[1].length(), content="1")
  inspect(clusters[1][0], content="97")
}

///|
test "segment_graphemes keeps CRLF as one cluster" {
  let clusters = segment_graphemes([0x0d, 0x0a, 0x41])
  inspect(clusters.length(), content="2")
  inspect(clusters[0].length(), content="2")
  inspect(clusters[0][0], content="13")
  inspect(clusters[0][1], content="10")
  inspect(clusters[1][0], content="65")
}

///|
test "segment_graphemes of empty input is empty" {
  inspect(segment_graphemes([]).length(), content="0")
}
