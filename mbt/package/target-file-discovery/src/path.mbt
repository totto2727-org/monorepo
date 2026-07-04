///|
fn join_path(base : String, name : String) -> String {
  if base == "" || base == "/" {
    "/\{name}"
  } else if base.has_suffix("/") {
    "\{base}\{name}"
  } else {
    "\{base}/\{name}"
  }
}

///|
fn normalize_path(path : String) -> String {
  let absolute = if path.has_prefix("/") {
    path
  } else {
    let cwd = @env.get_env_var("PWD").unwrap_or(
      @env.current_dir().unwrap_or("."),
    )
    join_path(cwd, path)
  }
  let parts : Array[String] = []
  for raw in absolute.split("/") {
    let part = raw.to_owned()
    if part == "" || part == "." {
      continue
    }
    if part == ".." {
      if parts.length() > 0 {
        let _ = parts.pop()
      }
    } else {
      parts.push(part)
    }
  }
  "/\{parts.join("/")}"
}

///|
fn dirname(path : String) -> String {
  let normalized = normalize_path(path).trim_end(chars="/").to_owned()
  match normalized.rev_find("/") {
    Some(0) => "/"
    Some(index) => normalized[:index].to_owned()
    None => "/"
  }
}

///|
fn relative_path(from : String, to : String) -> String {
  let from_parts = normalize_path(from)
    .split("/")
    .filter(fn(part) { part != "" })
    .map(fn(part) { part.to_owned() })
    .collect()
  let to_parts = normalize_path(to)
    .split("/")
    .filter(fn(part) { part != "" })
    .map(fn(part) { part.to_owned() })
    .collect()
  let mut index = 0
  while index < from_parts.length() &&
        index < to_parts.length() &&
        from_parts[index] == to_parts[index] {
    index = index + 1
  }
  let result : Array[String] = []
  let mut parent_count = from_parts.length() - index
  while parent_count > 0 {
    result.push("..")
    parent_count = parent_count - 1
  }
  let mut child_index = index
  while child_index < to_parts.length() {
    result.push(to_parts[child_index])
    child_index = child_index + 1
  }
  result.join("/")
}
