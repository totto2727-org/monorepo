///|
fn normalize_path(path : String) -> String {
  if @path.Path::is_absolute(path) {
    @path.Path::normalize(path).to_string()
  } else {
    let cwd = @env.get_env_var("PWD").unwrap_or(
      @env.current_dir().unwrap_or("."),
    )
    @path.Path::join(cwd, path).normalize().to_string()
  }
}

///|
fn sibling_dir_for_target_file(
  target_file : String,
  sibling_dir_name : String,
) -> String {
  @path.Path::join(
    @path.Path::dirname(normalize_path(target_file)),
    sibling_dir_name,
  ).to_string()
}

///|
pub fn target_file_for_sibling_dir(
  sibling_dir : String,
  file_name : String,
) -> String {
  @path.Path::join(@path.Path::dirname(normalize_path(sibling_dir)), file_name).to_string()
}

///|
async fn find_home_target_file(home_dir : String, file_name : String) -> String {
  let target_file = @path.Path::join(home_dir, file_name).to_string()
  guard @fs.exists(target_file) else {
    raise Failure::Failure("Could not find home-level file: \{file_name}")
  }
  target_file
}

///|
pub async fn find_home_sibling_dir_for_target_file(
  home_dir : String,
  file_name : String,
  sibling_dir_name : String,
) -> String {
  sibling_dir_for_target_file(
    find_home_target_file(home_dir, file_name),
    sibling_dir_name,
  )
}

///|
async fn find_parent_target_file(
  file_name : String,
  top_dir : String,
  start_dir : String,
) -> String {
  find_parent_target_file_from(
    file_name,
    normalize_path(top_dir),
    normalize_path(start_dir),
  )
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
    raise Failure::Failure("Could not find ancestor file: \{file_name}")
  }
  let parent_dir = @path.Path::dirname(current_dir).to_string()
  guard parent_dir != current_dir else {
    raise Failure::Failure(
      "Reached filesystem root before top directory: \{boundary_dir}",
    )
  }
  find_parent_target_file_from(file_name, boundary_dir, parent_dir)
}

///|
pub async fn resolve_sibling_dirs_for_target_file(
  file_name : String,
  sibling_dir_name : String,
  recursive : Bool,
  top_dir : String,
  start_dir : String,
) -> Array[String] {
  let nearest_target_file = find_parent_target_file(
    file_name, top_dir, start_dir,
  )
  if !recursive {
    return [sibling_dir_for_target_file(nearest_target_file, sibling_dir_name)]
  }
  let target_files = collect_recursive_target_files(
    @path.Path::dirname(nearest_target_file).to_string(),
    file_name,
  )
  target_files.map(fn(target_file) {
    sibling_dir_for_target_file(target_file, sibling_dir_name)
  })
}
