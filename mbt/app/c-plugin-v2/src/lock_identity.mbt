///|
pub struct GitHubOwner {
  value : String
} derive(Eq)

///|
pub fn GitHubOwner::GitHubOwner(value : String) -> GitHubOwner raise {
  guard value != "" &&
    value.length() <= 39 &&
    !value.has_prefix("-") &&
    !value.has_suffix("-") &&
    !value.contains("--") &&
    value.all(char => {
      char.is_ascii_alphabetic() || char.is_ascii_digit() || char == '-'
    }) else {
    fail("GitHub owner must be a valid GitHub account component")
  }
  { value: value.to_lower() }
}

///|
pub fn GitHubOwner::value(self : GitHubOwner) -> String {
  self.value
}

///|
pub struct GitHubRepositoryName {
  value : String
} derive(Eq)

///|
pub fn GitHubRepositoryName::GitHubRepositoryName(
  value : String,
) -> GitHubRepositoryName raise {
  guard value != "" &&
    value.length() <= 100 &&
    value != "." &&
    value != ".." &&
    value.all(char => {
      char.is_ascii_alphabetic() ||
      char.is_ascii_digit() ||
      char == '-' ||
      char == '_' ||
      char == '.'
    }) else {
    fail("GitHub repository name contains an unsupported character")
  }
  { value: value.to_lower() }
}

///|
pub fn GitHubRepositoryName::value(self : GitHubRepositoryName) -> String {
  self.value
}

///|
pub struct GitHubRepository {
  owner : GitHubOwner
  name : GitHubRepositoryName
} derive(Eq)

///|
pub fn GitHubRepository::GitHubRepository(
  owner : GitHubOwner,
  name : GitHubRepositoryName,
) -> GitHubRepository {
  { owner, name }
}

///|
pub fn GitHubRepository::from_route(route : String) -> GitHubRepository raise {
  let components = route
    .split("/")
    .map(fn(component) { component.to_owned() })
    .collect()
  guard components.length() == 2 else {
    fail("GitHub repository route must be owner/name")
  }
  GitHubRepository(
    GitHubOwner(components[0]),
    GitHubRepositoryName(components[1]),
  )
}

///|
pub fn GitHubRepository::owner(self : GitHubRepository) -> GitHubOwner {
  self.owner
}

///|
pub fn GitHubRepository::name(self : GitHubRepository) -> GitHubRepositoryName {
  self.name
}

///|
pub fn GitHubRepository::route(self : GitHubRepository) -> String {
  "\{self.owner.value()}/\{self.name.value()}"
}

///|
pub struct Target {
  path : @path.Path
} derive(Eq)

///|
pub fn Target::Target(path : @path.Path) -> Target raise {
  guard path.to_string() != "" else { fail("target path must not be empty") }
  { path: path.normalize() }
}

///|
pub fn Target::path(self : Target) -> @path.Path {
  self.path
}

///|
pub struct RelativeSourcePath {
  path : @path.Path
} derive(Eq)

///|
pub fn RelativeSourcePath::RelativeSourcePath(
  path : @path.Path,
) -> RelativeSourcePath raise {
  validate_relative_path(path, "local repository path")
  { path: path.normalize() }
}

///|
pub fn RelativeSourcePath::path(self : RelativeSourcePath) -> @path.Path {
  self.path
}

///|
pub struct RelativePluginPath {
  path : @path.Path
} derive(Eq)

///|
pub fn RelativePluginPath::RelativePluginPath(
  path : @path.Path,
) -> RelativePluginPath raise {
  validate_relative_path(path, "plugin path")
  { path: path.normalize() }
}

///|
pub fn RelativePluginPath::path(self : RelativePluginPath) -> @path.Path {
  self.path
}

///|
fn validate_relative_path(path : @path.Path, kind : String) -> Unit raise {
  let value = path.to_string()
  guard value != "" && !path.is_absolute() && !value.contains("\\") else {
    fail("\{kind} must be a relative path")
  }
  let segments = value
    .split("/")
    .map(fn(segment) { segment.to_owned() })
    .collect()
  guard !segments.contains("..") else {
    fail("\{kind} must not traverse parent directories")
  }
}

///|
pub struct PluginName {
  value : String
} derive(Eq)

///|
pub fn PluginName::PluginName(value : String) -> PluginName raise {
  validate_item_name(value, "plugin name")
  { value, }
}

///|
pub fn PluginName::value(self : PluginName) -> String {
  self.value
}

///|
pub struct SkillName {
  value : String
} derive(Eq)

///|
pub fn SkillName::SkillName(value : String) -> SkillName raise {
  validate_item_name(value, "skill name")
  { value, }
}

///|
pub fn SkillName::value(self : SkillName) -> String {
  self.value
}

///|
fn validate_item_name(value : String, kind : String) -> Unit raise {
  guard value != "" &&
    value != "." &&
    value != ".." &&
    !value.contains("/") &&
    !value.contains("\\") else {
    fail("\{kind} must be a non-path name")
  }
}

///|
pub struct CommitId {
  value : String
} derive(Eq)

///|
pub fn CommitId::CommitId(value : String) -> CommitId raise {
  guard value.length() == 40 && value.all(is_ascii_hexadecimal) else {
    fail("commit ID must be a 40-character hexadecimal object ID")
  }
  { value: value.to_lower() }
}

///|
pub fn CommitId::value(self : CommitId) -> String {
  self.value
}

///|
fn is_ascii_hexadecimal(char : Char) -> Bool {
  char.is_ascii_digit() ||
  (char >= 'a' && char <= 'f') ||
  (char >= 'A' && char <= 'F')
}
