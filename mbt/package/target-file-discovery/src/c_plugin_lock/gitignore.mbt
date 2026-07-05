///|
priv struct IgnoreRuleSet {
  base_dir : String
  patterns : Array[String]
}

///|
async fn read_ignore_rules(dir : String) -> IgnoreRuleSet? {
  let path = @path.Path::join(dir, ".gitignore").to_string()
  let content = @fs.read_file(path).text() catch { _ => "" }
  let patterns = content
    .split("\n")
    .map(fn(line) { line.trim().to_owned() })
    .filter(fn(line) { line != "" && !line.has_prefix("#") })
    .collect()
  if patterns.length() == 0 {
    None
  } else {
    Some({ base_dir: dir, patterns })
  }
}

///|
fn is_ignored_directory(
  target_path : String,
  ignore_rules : Array[IgnoreRuleSet],
) -> Bool {
  for rules in ignore_rules {
    let relative = @path.Path::relative(base=rules.base_dir, target_path).to_string()
    for pattern in rules.patterns {
      if matches_ignored_directory(relative, pattern) {
        return true
      }
    }
  }
  false
}

///|
fn matches_ignored_directory(relative : String, pattern : String) -> Bool {
  let normalized = if pattern.has_prefix("/") {
    pattern[1:].to_owned()
  } else {
    pattern
  }
  let directory_pattern = if normalized.has_suffix("/") {
    normalized[0:normalized.length() - 1].to_owned()
  } else {
    normalized
  }
  relative == directory_pattern ||
  relative.has_prefix("\{directory_pattern}/") ||
  relative.contains("/\{directory_pattern}/")
}

///|
async fn collect_recursive_target_files(
  start_dir : String,
  file_name : String,
) -> Array[String] {
  collect_recursive_target_files_from(start_dir, file_name, [])
}

///|
async fn collect_recursive_target_files_from(
  dir : String,
  file_name : String,
  inherited_ignore_rules : Array[IgnoreRuleSet],
) -> Array[String] {
  let target_file = @path.Path::join(dir, file_name).to_string()
  let local_ignore_rules = read_ignore_rules(dir)
  let ignore_rules = inherited_ignore_rules.copy()
  match local_ignore_rules {
    Some(rules) => ignore_rules.push(rules)
    None => ()
  }
  let files : Array[String] = []
  if @fs.exists(target_file) {
    files.push(target_file)
  }
  let entries = @fs.readdir(
    dir,
    include_hidden=true,
    include_special=false,
    sort=true,
  ) catch {
    _ => []
  }
  for entry in entries {
    let entry_path = @path.Path::join(dir, entry).to_string()
    let kind = @fs.kind(entry_path)
    if kind == @fs.FileKind::Directory &&
      !is_ignored_directory(entry_path, ignore_rules) {
      for
        found in collect_recursive_target_files_from(
          entry_path, file_name, ignore_rules,
        ) {
        files.push(found)
      }
    }
  }
  files
}
