///|
pub(all) suberror RuntimePathsError {
  RelativeRoot(name~ : String, path~ : @path.Path)
} derive(Debug)

///|
pub struct RuntimePaths {
  home_value : @path.Path
  cwd_value : @path.Path
  cache_root_value : @path.Path
}

///|
fn normalized_absolute_root(
  name : String,
  path : @path.Path,
) -> @path.Path raise RuntimePathsError {
  guard path.is_absolute() else { raise RelativeRoot(name~, path~) }
  path.normalize()
}

///|
pub fn RuntimePaths::RuntimePaths(
  home : @path.Path,
  cwd : @path.Path,
  cache_root : @path.Path,
) -> RuntimePaths raise RuntimePathsError {
  RuntimePaths::{
    home_value: normalized_absolute_root("home", home),
    cwd_value: normalized_absolute_root("cwd", cwd),
    cache_root_value: normalized_absolute_root("cache root", cache_root),
  }
}

///|
pub fn RuntimePaths::home(self : RuntimePaths) -> @path.Path {
  self.home_value
}

///|
pub fn RuntimePaths::cwd(self : RuntimePaths) -> @path.Path {
  self.cwd_value
}

///|
pub fn RuntimePaths::cache_root(self : RuntimePaths) -> @path.Path {
  self.cache_root_value
}

///|
pub fn RuntimePaths::project_lock_path(
  self : RuntimePaths,
  project_root : @path.Path,
) -> @path.Path raise RuntimePathsError {
  ignore(self)
  normalized_absolute_root("project root", project_root).join(
    "c-plugin-lock.json",
  )
}

///|
pub fn RuntimePaths::global_lock_path(self : RuntimePaths) -> @path.Path {
  self.home_value.join("c-plugin-lock.json")
}

///|
pub fn RuntimePaths::project_ownership_state_path(
  self : RuntimePaths,
  project_root : @path.Path,
) -> @path.Path raise RuntimePathsError {
  ignore(self)
  normalized_absolute_root("project root", project_root)
  .join(".agents")
  .join("c-plugin-state.json")
}

///|
pub fn RuntimePaths::global_ownership_state_path(
  self : RuntimePaths,
) -> @path.Path {
  self.home_value.join(".agents").join("c-plugin-state.json")
}

///|
pub fn RuntimePaths::project_managed_skill_root(
  self : RuntimePaths,
  project_root : @path.Path,
) -> @path.Path raise RuntimePathsError {
  ignore(self)
  normalized_absolute_root("project root", project_root)
  .join(".agents")
  .join("skills")
}

///|
pub fn RuntimePaths::global_managed_skill_root(
  self : RuntimePaths,
) -> @path.Path {
  self.home_value.join(".agents").join("skills")
}
