// White-box tests for the bounded XML/markup tokenizer.

///|
test "tokenize empty input yields no tokens" {
  match tokenize_markup("") {
    Ok(tokens) => inspect(tokens.length(), content="0")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "tokenize start tag with attributes and text" {
  let input = "<svg width=\"10\" height='20'>hi</svg>"
  match tokenize_markup(input) {
    Ok(tokens) => {
      inspect(tokens.length(), content="9")
      inspect(tokens[0] is StartTag("svg"), content="true")
      inspect(tokens[1] is AttributeName("width"), content="true")
      inspect(tokens[2] is AttributeValue("10"), content="true")
      inspect(tokens[3] is AttributeName("height"), content="true")
      inspect(tokens[4] is AttributeValue("20"), content="true")
      inspect(tokens[5] is TagEnd, content="true")
      inspect(tokens[6] is Text("hi"), content="true")
      inspect(tokens[7] is EndTag("svg"), content="true")
      inspect(tokens[8] is TagEnd, content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "tokenize empty tag and namespaced name" {
  match tokenize_markup("<path d=\"M0 0\"/>") {
    Ok(tokens) => {
      inspect(tokens[0] is StartTag("path"), content="true")
      inspect(tokens[1] is AttributeName("d"), content="true")
      inspect(tokens[2] is AttributeValue("M0 0"), content="true")
      inspect(tokens[3] is EmptyTagEnd, content="true")
      inspect(tokens.length(), content="4")
    }
    Err(_) => inspect(false, content="true")
  }
  match tokenize_markup("<svg:rect x=\"1\"/>") {
    Ok(tokens) => inspect(tokens[0] is StartTag("svg:rect"), content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "tokenize comment and surrounding text" {
  match tokenize_markup("a<!-- note -->b") {
    Ok(tokens) => {
      inspect(tokens.length(), content="3")
      inspect(tokens[0] is Text("a"), content="true")
      inspect(tokens[1] is Comment(" note "), content="true")
      inspect(tokens[2] is Text("b"), content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "tokenize rejects unquoted attribute value" {
  match tokenize_markup("<g id=x>") {
    Ok(_) => inspect(false, content="true")
    Err(e) => {
      inspect(e.code() is InvalidEncoding, content="true")
      inspect(e.context() is Some("text-markup-unquoted-attribute-value"), content="true")
    }
  }
}

///|
test "tokenize rejects unterminated comment" {
  match tokenize_markup("<!--oops") {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(e.context() is Some("text-markup-unterminated-comment"), content="true")
  }
}

///|
test "tokenize rejects bare less-than" {
  match tokenize_markup("<") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.code() is InvalidEncoding, content="true")
  }
}
