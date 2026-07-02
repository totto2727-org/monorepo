///|
fn lines(text : String) -> Array[String] {
  text.split("\n").map(fn(line) { line.to_owned() }).collect()
}

///|
fn basename(path : String) -> String {
  let trimmed = path.trim_end(chars="/").to_owned()
  match trimmed.rev_find("/") {
    Some(index) => trimmed[index + 1:].to_owned()
    None => trimmed
  }
}

///|
fn value_after_prefix(line : String, prefix : String) -> String? {
  if line.has_prefix(prefix) {
    Some(line[prefix.length():].to_owned())
  } else {
    None
  }
}
