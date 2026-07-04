///|
pub async fn find_home_target_file(
  home_dir : String,
  file_name : String,
) -> String {
  let target_file = join_path(home_dir, file_name)
  guard @fs.exists(target_file) else {
    fail("Could not find home-level file: \{file_name}")
  }
  target_file
}

///|
pub async fn find_parent_target_file(
  file_name : String,
  top_dir : String,
  start_dir : String,
) -> String {
  let boundary_dir = normalize_path(top_dir)
  let current_dir = normalize_path(start_dir)
  find_parent_target_file_from(file_name, boundary_dir, current_dir)
}

///|
async fn find_parent_target_file_from(
  file_name : String,
  boundary_dir : String,
  current_dir : String,
) -> String {
  let target_file = join_path(current_dir, file_name)
  if @fs.exists(target_file) {
    return target_file
  }
  guard current_dir != boundary_dir else {
    fail("Could not find ancestor file: \{file_name}")
  }
  let parent_dir = dirname(current_dir)
  guard parent_dir != current_dir else {
    fail("Reached filesystem root before top directory: \{boundary_dir}")
  }
  find_parent_target_file_from(file_name, boundary_dir, parent_dir)
}

///|
pub async fn collect_recursive_target_files(
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
  let target_file = join_path(dir, file_name)
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
    let entry_path = join_path(dir, entry)
    let kind = @fs.kind(entry_path) catch { _ => @fs.FileKind::Unknown }
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
