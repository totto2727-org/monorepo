///|
let lock_file_name = "c-plugin-lock.json"

///|
fn home_dir() -> String {
  @env.get_env_var("HOME").unwrap_or(".")
}

///|
fn cwd() -> String {
  @env.get_env_var("PWD").unwrap_or(@env.current_dir().unwrap_or("."))
}

///|
fn normalize_path(path : String) -> String {
  if path.has_prefix("/") {
    path
  } else {
    "\{cwd()}/\{path}"
  }
}

///|
fn dirname(path : String) -> String {
  let trimmed = path.trim_end(chars="/").to_owned()
  match trimmed.rev_find("/") {
    Some(0) => "/"
    Some(index) => trimmed[:index].to_owned()
    None => "."
  }
}

///|
fn expand_home(path : String) -> String {
  if path == "~" {
    home_dir()
  } else if path.has_prefix("~/") {
    "\{home_dir()}/\{path[2:]}"
  } else {
    path
  }
}

///|
fn agents_dir(global : Bool) -> String {
  if global {
    "\{home_dir()}/.agents"
  } else {
    "\{cwd()}/.agents"
  }
}

///|
fn lock_path_from_agents(agents : String) -> String {
  "\{dirname(agents)}/\{lock_file_name}"
}

///|
fn cache_root() -> String {
  @env.get_env_var("C_PLUGIN_CACHE_ROOT").unwrap_or(
    "\{home_dir()}/.c-plugin/cache",
  )
}

///|
fn repo_cache_dir(source : String) -> String {
  "\{cache_root()}/mbt/\{source}"
}

///|
fn validate_github_source(source : String) -> Unit raise {
  @support.validate_github_source(source)
}

///|
fn validate_relative_plugin_path(path : String) -> Unit raise {
  @support.validate_relative_plugin_path(path)
}

///|
fn local_source_path(source : String, root : String) -> String {
  if source.has_prefix("./") {
    normalize_path("\{root}/\{source}")
  } else {
    expand_home(source)
  }
}
