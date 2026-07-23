// White-box tests for XML escaping.

///|
test "escape_xml_text escapes ampersand lt gt" {
  inspect(escape_xml_text("a < b & c > d") == "a &lt; b &amp; c &gt; d", content="true")
}

///|
test "escape_xml_text leaves normal text unchanged" {
  inspect(escape_xml_text("hello world") == "hello world", content="true")
  inspect(escape_xml_text("") == "", content="true")
}

///|
test "escape_xml_attribute escapes quotes" {
  inspect(escape_xml_attribute("say \"hi\"") == "say &quot;hi&quot;", content="true")
  inspect(escape_xml_attribute("it's") == "it&apos;s", content="true")
  // Also escapes &, <, >.
  inspect(escape_xml_attribute("x < y & z > w") == "x &lt; y &amp; z &gt; w", content="true")
}

///|
test "unescape_xml reverses named entities" {
  inspect(unescape_xml("&lt;tag&gt;") == "<tag>", content="true")
  inspect(unescape_xml("a &amp; b") == "a & b", content="true")
  inspect(unescape_xml("&quot;hi&quot;") == "\"hi\"", content="true")
  inspect(unescape_xml("&apos;") == "'", content="true")
}

///|
test "unescape_xml handles numeric entities" {
  inspect(unescape_xml("&#65;") == "A", content="true")
  inspect(unescape_xml("&#x41;") == "A", content="true")
}

///|
test "escape then unescape is identity for text content" {
  let original = "if (a < b) && (c > d) return true"
  let escaped = escape_xml_text(original)
  let restored = unescape_xml(escaped)
  inspect(restored == original, content="true")
}

///|
test "unescape_xml passes through unrecognized entities" {
  inspect(unescape_xml("&unknown;") == "&unknown;", content="true")
}

///|
test "escape and unescape handle multiple entities in one string" {
  let original = "<div class=\"x\">Tom & Jerry</div>"
  let escaped = escape_xml_attribute(original)
  let restored = unescape_xml(escaped)
  inspect(restored == original, content="true")
}
