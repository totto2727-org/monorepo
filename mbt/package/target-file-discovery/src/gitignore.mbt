///|
priv struct IgnoreRuleSet {
  base_dir : String
  patterns : Array[String]
}

// Minimal traversal-only matcher until this package can use bit_ignore.
// Supported today: comments, blank lines, literal directory patterns, and `*` within a path segment.

///|
let char_star : UInt16 = {
  let c : Int = '*'.to_int()
  c.to_uint16()
}

///|
fn parse_ignore_patterns(content : String) -> Array[String] {
  content
  .split("\n")
  .map(fn(raw_line) { raw_line.to_owned().trim().to_owned() })
  .filter(fn(line) {
    line != "" && !line.has_prefix("#") && !line.has_prefix("!")
  })
  .map(fn(line) { line.trim_start(chars="/").trim_end(chars="/").to_owned() })
  .collect()
}

///|
async fn read_ignore_rules(dir : String) -> IgnoreRuleSet? {
  let path = @path.Path::join(dir, ".gitignore").to_string()
  let content = @fs.read_file(path).text() catch { _ => "" }
  if content.trim() == "" {
    None
  } else {
    Some({ base_dir: dir, patterns: parse_ignore_patterns(content) })
  }
}

///|
fn path_matches_pattern(relative : String, pattern : String) -> Bool {
  let pattern_segments = non_empty_path_segments(pattern)
  let relative_segments = non_empty_path_segments(relative)
  if pattern_segments.length() == 0 || relative_segments.length() == 0 {
    return false
  }
  if pattern_segments.length() == 1 {
    return relative_segments.any(fn(segment) {
      glob_segment_matches(pattern_segments[0], segment)
    })
  }
  contains_contiguous_segments(relative_segments, pattern_segments)
}

///|
fn non_empty_path_segments(path : String) -> Array[String] {
  path
  .split("/")
  .map(fn(segment) { segment.to_owned() })
  .filter(fn(segment) { segment != "" })
  .collect()
}

///|
fn contains_contiguous_segments(
  path_segments : Array[String],
  pattern_segments : Array[String],
) -> Bool {
  if pattern_segments.length() > path_segments.length() {
    return false
  }
  (0)
  .until(path_segments.length() - pattern_segments.length() + 1)
  .any(fn(start) {
    (0)
    .until(pattern_segments.length())
    .all(fn(offset) {
      glob_segment_matches(
        pattern_segments[offset],
        path_segments[start + offset],
      )
    })
  })
}

///|
fn glob_segment_matches(pattern : String, text : String) -> Bool {
  let pattern_length = pattern.length()
  let text_length = text.length()
  let mut pattern_index = 0
  let mut text_index = 0
  let mut star_index = -1
  let mut match_index = 0
  while text_index < text_length {
    if pattern_index < pattern_length &&
      pattern.unsafe_get(pattern_index) == text.unsafe_get(text_index) {
      pattern_index += 1
      text_index += 1
    } else if pattern_index < pattern_length &&
      pattern.unsafe_get(pattern_index) == char_star {
      star_index = pattern_index
      match_index = text_index
      pattern_index += 1
    } else if star_index != -1 {
      pattern_index = star_index + 1
      match_index += 1
      text_index = match_index
    } else {
      return false
    }
  }
  while pattern_index < pattern_length &&
        pattern.unsafe_get(pattern_index) == char_star {
    pattern_index += 1
  }
  pattern_index == pattern_length
}

///|
fn is_ignored_directory(
  target_path : String,
  ignore_rules : Array[IgnoreRuleSet],
) -> Bool {
  ignore_rules
  .iter()
  .any(fn(rules) {
    let relative = @path.Path::relative(
      base=normalize_path(rules.base_dir),
      normalize_path(target_path),
    ).to_string()
    rules.patterns
    .iter()
    .any(fn(pattern) { path_matches_pattern(relative, pattern) })
  })
}
