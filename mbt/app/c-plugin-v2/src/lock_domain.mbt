///|
pub struct GitHubOwner {
  value : String
} derive(Eq, Hash)

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
} derive(Eq, Hash)

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
} derive(Eq, Hash)

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
pub impl Hash for Target with fn hash_combine(self, hasher) {
  self.path.to_string().hash_combine(hasher)
}

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
pub impl Hash for RelativeSourcePath with fn hash_combine(self, hasher) {
  self.path.to_string().hash_combine(hasher)
}

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
pub impl Hash for RelativePluginPath with fn hash_combine(self, hasher) {
  self.path.to_string().hash_combine(hasher)
}

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
} derive(Eq, Hash)

///|
pub fn PluginName::PluginName(value : String) -> PluginName raise {
  validate_item_name(value, "plugin name")
  { value, }
}

///|
pub struct SkillName {
  value : String
} derive(Eq, Hash)

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
  priv enabled_skills : Set[SkillName]
}

///|
pub impl Eq for Plugin with fn equal(self, other) {
  self.name == other.name &&
  self.path == other.path &&
  ordered_iter_equal(
    self.enabled_skills.iter(),
    other.enabled_skills.iter(),
    self.enabled_skills.length(),
    other.enabled_skills.length(),
  )
}

///|
pub fn Plugin::Plugin(
  name : PluginName,
  path : RelativePluginPath,
  enabled_skills : Array[SkillName],
) -> Plugin raise {
  let stored_skills : Set[SkillName] = Set::default()
  for skill in enabled_skills {
    guard stored_skills.add_and_check(skill) else {
      fail("plugin enabled skills must be unique")
    }
  }
  { name, path, enabled_skills: stored_skills }
}

///|
pub fn Plugin::enabled_skills(self : Plugin) -> ReadOnlyArray[SkillName] {
  ReadOnlyArray::from_array(self.enabled_skills.to_array())
}

///|
pub struct GitHubLockRepository {
  repository : GitHubRepository
  marketplace_kind : MarketplaceKind
  commit : CommitId
  priv plugins : Map[PluginName, Plugin]
}

///|
pub impl Eq for GitHubLockRepository with fn equal(self, other) {
  self.repository == other.repository &&
  self.marketplace_kind == other.marketplace_kind &&
  self.commit == other.commit &&
  ordered_iter_equal(
    self.plugins.values(),
    other.plugins.values(),
    self.plugins.length(),
    other.plugins.length(),
  )
}

///|
pub fn GitHubLockRepository::GitHubLockRepository(
  repository : GitHubRepository,
  marketplace_kind : MarketplaceKind,
  commit : CommitId,
  plugins : Array[Plugin],
) -> GitHubLockRepository raise {
  let stored_plugins : Map[PluginName, Plugin] = Map([])
  for plugin in plugins {
    guard !stored_plugins.contains(plugin.name) else {
      fail("repository plugin names must be unique")
    }
    stored_plugins[plugin.name] = plugin
  }
  { repository, marketplace_kind, commit, plugins: stored_plugins }
}

///|
pub fn GitHubLockRepository::plugins(
  self : GitHubLockRepository,
) -> ReadOnlyArray[Plugin] {
  ReadOnlyArray::from_array(self.plugins.values().collect())
}

///|
pub struct LocalLockRepository {
  path : RelativeSourcePath
  marketplace_kind : MarketplaceKind
  priv plugins : Map[PluginName, Plugin]
}

///|
pub impl Eq for LocalLockRepository with fn equal(self, other) {
  self.path == other.path &&
  self.marketplace_kind == other.marketplace_kind &&
  ordered_iter_equal(
    self.plugins.values(),
    other.plugins.values(),
    self.plugins.length(),
    other.plugins.length(),
  )
}

///|
pub fn LocalLockRepository::LocalLockRepository(
  path : RelativeSourcePath,
  marketplace_kind : MarketplaceKind,
  plugins : Array[Plugin],
) -> LocalLockRepository raise {
  let stored_plugins : Map[PluginName, Plugin] = Map([])
  for plugin in plugins {
    guard !stored_plugins.contains(plugin.name) else {
      fail("repository plugin names must be unique")
    }
    stored_plugins[plugin.name] = plugin
  }
  { path, marketplace_kind, plugins: stored_plugins }
}

///|
pub fn LocalLockRepository::plugins(
  self : LocalLockRepository,
) -> ReadOnlyArray[Plugin] {
  ReadOnlyArray::from_array(self.plugins.values().collect())
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
  priv targets : Set[Target]
  priv repositories : Map[RepositoryIdentity, LockRepository]
}

///|
pub impl Eq for Lock with fn equal(self, other) {
  self.version == other.version &&
  ordered_iter_equal(
    self.targets.iter(),
    other.targets.iter(),
    self.targets.length(),
    other.targets.length(),
  ) &&
  ordered_iter_equal(
    self.repositories.values(),
    other.repositories.values(),
    self.repositories.length(),
    other.repositories.length(),
  )
}

///|
pub fn Lock::Lock(
  targets : Array[Target],
  repositories : Array[LockRepository],
) -> Lock raise {
  let stored_targets : Set[Target] = Set::default()
  for target in targets {
    guard stored_targets.add_and_check(target) else {
      fail("lock targets must be unique")
    }
  }
  let stored_repositories : Map[RepositoryIdentity, LockRepository] = Map([])
  for repository in repositories {
    let identity = repository.identity()
    guard !stored_repositories.contains(identity) else {
      fail("lock repositories must be unique")
    }
    stored_repositories[identity] = repository
  }
  { version: 2, targets: stored_targets, repositories: stored_repositories }
}

///|
pub fn Lock::targets(self : Lock) -> ReadOnlyArray[Target] {
  ReadOnlyArray::from_array(self.targets.to_array())
}

///|
pub fn Lock::repositories(self : Lock) -> ReadOnlyArray[LockRepository] {
  ReadOnlyArray::from_array(self.repositories.values().collect())
}

///|
enum RepositoryIdentity {
  GitHubIdentity(GitHubRepository)
  LocalIdentity(RelativeSourcePath)
} derive(Eq, Hash)

///|
fn LockRepository::identity(self : LockRepository) -> RepositoryIdentity {
  match self {
    GitHub(repository) => GitHubIdentity(repository.repository)
    Local(repository) => LocalIdentity(repository.path)
  }
}

///|
fn[X : Eq] ordered_iter_equal(
  left : Iter[X],
  right : Iter[X],
  left_length : Int,
  right_length : Int,
) -> Bool {
  left_length == right_length &&
  left.zip(right).all(fn(pair) { pair.0 == pair.1 })
}
