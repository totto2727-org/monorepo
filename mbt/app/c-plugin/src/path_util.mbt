///|
let lock_file_name = "c-plugin-lock.json"

///|
fn current_home_dir() -> String {
  @env.get_env_var("HOME").unwrap_or(".")
}

///|
fn current_working_dir() -> String {
  @env.get_env_var("PWD").unwrap_or(@env.current_dir().unwrap_or("."))
}

///|
fn relative_path(from : String, to : String) -> String {
  let normalized_from = if @path.Path::is_absolute(from) {
    @path.Path::normalize(from).to_string()
  } else {
    @path.Path::join(current_working_dir(), from).normalize().to_string()
  }
  let normalized_to = if @path.Path::is_absolute(to) {
    @path.Path::normalize(to).to_string()
  } else {
    @path.Path::join(current_working_dir(), to).normalize().to_string()
  }
  let relative = @path.Path::relative(base=normalized_from, normalized_to).to_string()
  if relative == "" {
    "."
  } else {
    relative
  }
}

///|
fn expand_home(path : String) -> String {
  if path == "~" {
    current_home_dir()
  } else if path.has_prefix("~/") {
    @path.Path::join(current_home_dir(), path[2:].to_owned()).to_string()
  } else {
    path
  }
}

///|
fn agents_dir_from_lock_file(lock_file : String) -> String {
  @path.Path::join(@path.Path::dirname(lock_file), ".agents").to_string()
}

///|
fn lock_path_from_agents(agents : String) -> String {
  @path.Path::join(@path.Path::dirname(agents), lock_file_name).to_string()
}

///|
async fn resolve_agents_dirs(recursive : Bool) -> Array[String] {
  let nearest_lock_file = @target_file_discovery.find_parent_target_file(
    lock_file_name,
    current_home_dir(),
    current_working_dir(),
  )
  if !recursive {
    return [agents_dir_from_lock_file(nearest_lock_file)]
  }
  @target_file_discovery.collect_recursive_target_files(
    @path.Path::dirname(nearest_lock_file).to_string(),
    lock_file_name,
  ).map(agents_dir_from_lock_file)
}

///|
async fn resolve_global_agents_dir() -> String {
  agents_dir_from_lock_file(
    @target_file_discovery.find_home_target_file(
      current_home_dir(),
      lock_file_name,
    ),
  )
}

///|
async fn resolve_agents_dir() -> String {
  match resolve_agents_dirs(false) {
    [agents, ..] => agents
    [] => fail("Could not find .agents directory with \{lock_file_name}")
  }
}

///|
async fn command_agents_dir(global : Bool) -> String {
  if global {
    resolve_global_agents_dir()
  } else {
    resolve_agents_dir()
  }
}

///|
fn cache_root() -> String {
  @env.get_env_var("C_PLUGIN_CACHE_ROOT").unwrap_or(
    (current_home_dir()
    |> @path.Path::join(".c-plugin")
    |> @path.Path::join("cache")).to_string(),
  )
}

///|
fn repo_cache_dir(source : String) -> String {
  (cache_root() |> @path.Path::join("mbt") |> @path.Path::join(source)).to_string()
}

///|
fn validate_github_source(source : String) -> Unit raise {
  guard !source.contains("..") &&
    !source.contains("\\") &&
    !source.contains(":") &&
    !source.has_prefix("/") &&
    !source.has_suffix(".git") else {
    fail("GitHub source must be owner/repo")
  }
  let parts = source.split("/").map(fn(part) { part.to_owned() }).collect()
  guard parts.length() == 2 && parts[0] != "" && parts[1] != "" else {
    fail("GitHub source must be owner/repo")
  }
}

///|
fn is_relative_plugin_path(path : String) -> Bool {
  path != "" &&
  !path.has_prefix("/") &&
  !path.contains("..") &&
  !path.contains("\\")
}

///|
fn local_source_path(source : String, root : String) -> String {
  if source.has_prefix("./") {
    let path = @path.Path::join(root, source).to_string()
    if @path.Path::is_absolute(path) {
      @path.Path::normalize(path).to_string()
    } else {
      @path.Path::join(current_working_dir(), path).normalize().to_string()
    }
  } else {
    expand_home(source)
  }
}
