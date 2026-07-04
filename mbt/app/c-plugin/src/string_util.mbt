///|
fn quoted_value(text : String, key : String, start : Int) -> String? {
  match text[start:].find("\"\{key}\"") {
    Some(relative_key) => {
      let after_key = start + relative_key + key.length() + 2
      match text[after_key:].find("\"") {
        Some(first_quote) => {
          let value_start = after_key + first_quote + 1
          match text[value_start:].find("\"") {
            Some(end_quote) =>
              Some(text[value_start:value_start + end_quote].to_owned())
            None => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn previous_quoted_value(text : String, key : String, before : Int) -> String? {
  match text[:before].rev_find("\"\{key}\"") {
    Some(start) => quoted_value(text, key, start)
    None => None
  }
}

///|
fn json_escape(value : String) -> String {
  value.replace(old="\\", new="\\\\").replace(old="\"", new="\\\"")
}
