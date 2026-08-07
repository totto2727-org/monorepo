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
pub fn GitHubRepository::route(self : GitHubRepository) -> String {
  "\{self.owner.value}/\{self.name.value}"
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
pub struct SkillName {
  value : String
} derive(Eq)

///|
pub fn SkillName::SkillName(value : String) -> SkillName raise {
  validate_item_name(value, "skill name")
  { value, }
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
fn is_ascii_hexadecimal(char : Char) -> Bool {
  char.is_ascii_digit() ||
  (char >= 'a' && char <= 'f') ||
  (char >= 'A' && char <= 'F')
}

///|
pub enum MarketplaceKind {
  Claude
  Cursor
  Codex
} derive(Eq)

///|
pub fn MarketplaceKind::claude() -> MarketplaceKind {
  Claude
}

///|
pub fn MarketplaceKind::cursor() -> MarketplaceKind {
  Cursor
}

///|
pub fn MarketplaceKind::codex() -> MarketplaceKind {
  Codex
}

///|
pub struct Plugin {
  name : PluginName
  path : RelativePluginPath
  enabled_skills : Array[SkillName]
} derive(Eq)

///|
pub fn Plugin::Plugin(
  name : PluginName,
  path : RelativePluginPath,
  enabled_skills : Array[SkillName],
) -> Plugin raise {
  guard unique_skill_count(enabled_skills) == enabled_skills.length() else {
    fail("plugin enabled skills must be unique")
  }
  { name, path, enabled_skills: [..enabled_skills] }
}

///|
pub struct GitHubLockRepository {
  repository : GitHubRepository
  marketplace_kind : MarketplaceKind
  commit : CommitId
  plugins : Array[Plugin]
} derive(Eq)

///|
pub fn GitHubLockRepository::GitHubLockRepository(
  repository : GitHubRepository,
  marketplace_kind : MarketplaceKind,
  commit : CommitId,
  plugins : Array[Plugin],
) -> GitHubLockRepository raise {
  guard unique_plugin_count(plugins) == plugins.length() else {
    fail("repository plugin names must be unique")
  }
  { repository, marketplace_kind, commit, plugins: [..plugins] }
}

///|
pub struct LocalLockRepository {
  path : RelativeSourcePath
  marketplace_kind : MarketplaceKind
  plugins : Array[Plugin]
} derive(Eq)

///|
pub fn LocalLockRepository::LocalLockRepository(
  path : RelativeSourcePath,
  marketplace_kind : MarketplaceKind,
  plugins : Array[Plugin],
) -> LocalLockRepository raise {
  guard unique_plugin_count(plugins) == plugins.length() else {
    fail("repository plugin names must be unique")
  }
  { path, marketplace_kind, plugins: [..plugins] }
}

///|
pub enum LockRepository {
  GitHub(GitHubLockRepository)
  Local(LocalLockRepository)
} derive(Eq)

///|
pub fn LockRepository::github(
  repository : GitHubLockRepository,
) -> LockRepository {
  GitHub(repository)
}

///|
pub fn LockRepository::from_local(
  repository : LocalLockRepository,
) -> LockRepository {
  Local(repository)
}

///|
pub struct Lock {
  version : Int
  targets : Array[Target]
  repositories : Array[LockRepository]
} derive(Eq)

///|
pub fn Lock::Lock(
  targets : Array[Target],
  repositories : Array[LockRepository],
) -> Lock raise {
  guard unique_target_count(targets) == targets.length() else {
    fail("lock targets must be unique")
  }
  guard unique_repository_count(repositories) == repositories.length() else {
    fail("lock repositories must be unique")
  }
  { version: 2, targets: [..targets], repositories: [..repositories] }
}

///|
fn unique_skill_count(skills : Array[SkillName]) -> Int {
  skills
  .iter()
  .fold(init=[], fn(unique, skill) {
    if unique.contains(skill) {
      unique
    } else {
      [..unique, skill]
    }
  })
  .length()
}

///|
fn unique_plugin_count(plugins : Array[Plugin]) -> Int {
  plugins
  .iter()
  .fold(init=[], fn(unique, plugin) {
    if unique.contains(plugin.name) {
      unique
    } else {
      [..unique, plugin.name]
    }
  })
  .length()
}

///|
fn unique_target_count(targets : Array[Target]) -> Int {
  targets
  .iter()
  .fold(init=[], fn(unique, target) {
    if unique.contains(target) {
      unique
    } else {
      [..unique, target]
    }
  })
  .length()
}

///|
enum RepositoryIdentity {
  GitHubIdentity(GitHubRepository)
  LocalIdentity(RelativeSourcePath)
} derive(Eq)

///|
fn unique_repository_count(repositories : Array[LockRepository]) -> Int {
  repositories
  .iter()
  .fold(init=[], fn(unique, repository) {
    let identity = match repository {
      GitHub(repository) => GitHubIdentity(repository.repository)
      Local(repository) => LocalIdentity(repository.path)
    }
    if unique.contains(identity) {
      unique
    } else {
      [..unique, identity]
    }
  })
  .length()
}
