///|
fn is_language_subtag(segment : String) -> Bool {
  let length = segment.length()
  length >= 2 && length <= 3 && segment.all(char => char.is_ascii_alphabetic())
}

///|
fn is_locale_subtag(segment : String) -> Bool {
  let length = segment.length()
  length >= 2 &&
  length <= 8 &&
  segment.all(char => char.is_ascii_alphabetic() || char.is_ascii_digit())
}

///|
fn is_locale_tag(input : String) -> Bool {
  let segments : Array[String] = input
    .split("-")
    .map(segment => segment.to_owned())
    .collect()
  guard segments is [language, .. rest] else { return false }
  is_language_subtag(language) && rest.all(is_locale_subtag)
}

///|
fn normalize_locale(input : String) -> String raise {
  guard is_locale_tag(input) else { fail("invalid language code: \{input}") }
  input.to_lower()
}

///|
fn extension_start(path : String) -> Int? {
  if path.has_suffix(".mbt.md") {
    Some(path.length() - ".mbt.md".length())
  } else {
    match path.rev_find(".") {
      Some(index) =>
        match path.rev_find("/") {
          Some(slash) if index < slash => None
          _ => Some(index)
        }
      None => None
    }
  }
}

///|
fn strip_locale_tag(path : @path.Path) -> @path.Path {
  let text = path.to_string()
  guard extension_start(text) is Some(extension) else { return path }
  let stem = text[:extension].to_owned()
  guard stem.rev_find(".") is Some(tag_start) else { return path }
  let tag = stem[tag_start + 1:].to_owned()
  if is_locale_tag(tag) {
    @path.Path(stem[:tag_start].to_owned() + text[extension:].to_owned())
  } else {
    path
  }
}

///|
fn target_path(file : @path.Path, lang : String) -> @path.Path {
  let stripped = strip_locale_tag(file).to_string()
  match extension_start(stripped) {
    Some(index) =>
      @path.Path(
        stripped[:index].to_owned() + "." + lang + stripped[index:].to_owned(),
      )
    None => @path.Path(stripped + "." + lang)
  }
}
