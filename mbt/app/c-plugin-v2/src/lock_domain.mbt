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
