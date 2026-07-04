///|
fn join_path(base : String, name : String) -> String {
  @path.Path::join(base, name).to_string()
}

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
fn dirname(path : String) -> String {
  @path.Path::dirname(normalize_path(path)).to_string()
}

///|
fn relative_path(from : String, to : String) -> String {
  @path.Path::relative(base=normalize_path(from), normalize_path(to)).to_string()
}
