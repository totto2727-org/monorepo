///|
pub fn validate_github_source(source : String) -> Unit raise {
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
pub fn validate_relative_plugin_path(path : String) -> Unit raise {
  guard path != "" &&
    !path.has_prefix("/") &&
    !path.contains("..") &&
    !path.contains("\\") else {
    fail(
      "Marketplace plugin source must be a relative path inside the repository",
    )
  }
}
