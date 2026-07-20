///|
pub async fn find_home_target_file(
  home_dir : String,
  file_name : String,
) -> String {
  let target_file = @path.Path::join(home_dir, file_name).to_string()
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
  let target_file = @path.Path::join(current_dir, file_name).to_string()
  if @fs.exists(target_file) {
    return target_file
  }
  guard current_dir != boundary_dir else {
    fail("Could not find ancestor file: \{file_name}")
  }
  let parent_dir = @path.Path::dirname(current_dir).to_string()
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
  let target_file = @path.Path::join(dir, file_name).to_string()
  let (local_ignore_rules, has_target_file, entries) = @async.with_task_group(group => {
    let ignore_task = group.spawn(() => read_ignore_rules(dir))
    let target_task = group.spawn(() => @fs.exists(target_file))
    let entries_task = group.spawn(() => {
      @fs.readdir(dir, include_hidden=true, include_special=false, sort=true)
    })
    (ignore_task.wait(), target_task.wait(), entries_task.wait())
  })
  let ignore_rules = match local_ignore_rules {
    Some(rules) =>
      inherited_ignore_rules.iter().concat([rules].iter()).collect()
    None => inherited_ignore_rules
  }
  let local_files = if has_target_file { [target_file] } else { [] }
  let descendant_files = collect_descendant_target_files(
    entries, dir, file_name, ignore_rules,
  )
  local_files.iter().concat(descendant_files.iter()).collect()
}

///|
async fn collect_descendant_target_files(
  entries : Array[String],
  dir : String,
  file_name : String,
  ignore_rules : Array[IgnoreRuleSet],
) -> Array[String] {
  @async.all(
    entries.map(entry => {
      () => {
        let entry_path = @path.Path::join(dir, entry).to_string()
        if @fs.kind(entry_path) == @fs.FileKind::Directory &&
          !is_ignored_directory(entry_path, ignore_rules) {
          collect_recursive_target_files_from(
            entry_path, file_name, ignore_rules,
          )
        } else {
          []
        }
      }
    }),
  )
  .iter()
  .flat_map(files => files.iter())
  .collect()
}
