///|
priv struct IgnoreRuleSet {
  base_dir : String
  patterns : Array[String]
}

///|
fn parse_ignore_patterns(content : String) -> Array[String] {
  let patterns : Array[String] = []
  for raw_line in content.split("\n") {
    let line = raw_line.to_owned().trim().to_owned()
    if line == "" || line.has_prefix("#") || line.has_prefix("!") {
      continue
    }
    patterns.push(line.trim_start(chars="/").trim_end(chars="/").to_owned())
  }
  patterns
}

///|
async fn read_ignore_rules(dir : String) -> IgnoreRuleSet? {
  let path = join_path(dir, ".gitignore")
  let content = @fs.read_file(path).text() catch { _ => "" }
  if content.trim() == "" {
    None
  } else {
    Some({ base_dir: dir, patterns: parse_ignore_patterns(content) })
  }
}

///|
fn path_matches_pattern(relative : String, pattern : String) -> Bool {
  if pattern == "" {
    return false
  }
  relative == pattern ||
  relative.has_prefix("\{pattern}/") ||
  relative.contains("/\{pattern}/")
}

///|
fn is_ignored_directory(
  target_path : String,
  ignore_rules : Array[IgnoreRuleSet],
) -> Bool {
  for rules in ignore_rules {
    let relative = relative_path(rules.base_dir, target_path)
    for pattern in rules.patterns {
      if path_matches_pattern(relative, pattern) {
        return true
      }
    }
  }
  false
}
