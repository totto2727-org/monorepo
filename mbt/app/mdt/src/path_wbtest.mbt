///|
test "normalize_locale 1 - lowercases a language tag" {
  inspect(normalize_locale("JA-jp"), content="ja-jp")
}

///|
test "panic_normalize_locale 2 - rejects invalid syntax" {
  try! (normalize_locale("invalid!") |> ignore)
}

///|
test "target_path 1 - inserts locale before a simple extension" {
  let input : @path.Path = "hoge.md"
  inspect(target_path(input, "ja").to_string(), content="hoge.ja.md")
}

///|
test "target_path 2 - preserves a compound extension" {
  let input : @path.Path = "hoge.mbt.md"
  inspect(target_path(input, "ja").to_string(), content="hoge.ja.mbt.md")
}

///|
test "target_path 3 - replaces an existing locale tag" {
  let input : @path.Path = "docs/intro.en.md"
  inspect(target_path(input, "ja").to_string(), content="docs/intro.ja.md")
}

///|
test "target_path 4 - keeps a non-locale segment" {
  let input : @path.Path = "README.draft.md"
  inspect(target_path(input, "ja").to_string(), content="README.draft.ja.md")
}

///|
test "target_path 5 - appends locale when no extension exists" {
  let input : @path.Path = "README"
  inspect(target_path(input, "ja").to_string(), content="README.ja")
}
