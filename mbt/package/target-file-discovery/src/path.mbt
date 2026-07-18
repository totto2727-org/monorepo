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
