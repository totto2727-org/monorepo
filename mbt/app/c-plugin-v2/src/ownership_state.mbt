///|
pub struct GitHubOwnershipSource {
  repository : GitHubRepository
  plugin : PluginName
  skill : SkillName
} derive(Eq)

///|
pub fn GitHubOwnershipSource::GitHubOwnershipSource(
  repository : GitHubRepository,
  plugin : PluginName,
  skill : SkillName,
) -> GitHubOwnershipSource {
  { repository, plugin, skill }
}

///|
pub struct LocalOwnershipSource {
  repository : RelativeSourcePath
  plugin : PluginName
  skill : SkillName
} derive(Eq)

///|
pub fn LocalOwnershipSource::LocalOwnershipSource(
  repository : RelativeSourcePath,
  plugin : PluginName,
  skill : SkillName,
) -> LocalOwnershipSource {
  { repository, plugin, skill }
}

///|
pub enum OwnershipSource {
  GitHub(GitHubOwnershipSource)
  Local(LocalOwnershipSource)
} derive(Eq)

///|
pub fn OwnershipSource::github(
  source : GitHubOwnershipSource,
) -> OwnershipSource {
  GitHub(source)
}

///|
pub fn OwnershipSource::from_local(
  source : LocalOwnershipSource,
) -> OwnershipSource {
  Local(source)
}

///|
pub struct OwnershipEntry {
  link : @path.Path
  symlink_target : @path.Path
  resolved_target : @path.Path
  managed_root : @path.Path
  source : OwnershipSource
} derive(Eq)

///|
pub fn OwnershipEntry::OwnershipEntry(
  link : @path.Path,
  symlink_target : @path.Path,
  resolved_target : @path.Path,
  managed_root : @path.Path,
  source : OwnershipSource,
) -> OwnershipEntry raise {
  guard link.is_absolute() else { fail("ownership link must be absolute") }
  guard resolved_target.is_absolute() else {
    fail("ownership resolved target must be absolute")
  }
  guard managed_root.is_absolute() else {
    fail("ownership managed root must be absolute")
  }
  let normalized_link = link.normalize()
  let normalized_resolved_target = resolved_target.normalize()
  let normalized_managed_root = managed_root.normalize()
  guard normalized_link.dirname() == normalized_managed_root else {
    fail("ownership link must be a direct child of its managed root")
  }
  {
    link: normalized_link,
    symlink_target,
    resolved_target: normalized_resolved_target,
    managed_root: normalized_managed_root,
    source,
  }
}

///|
pub struct OwnershipState {
  version : Int
  entries : @immut_hashmap.HashMap[OwnershipLinkIdentity, OwnershipEntry]
} derive(Eq)

///|
pub struct OwnershipLinkIdentity {
  path : @path.Path
} derive(Eq)

///|
pub fn OwnershipLinkIdentity::OwnershipLinkIdentity(
  path : @path.Path,
) -> OwnershipLinkIdentity {
  { path: path.normalize() }
}

///|
pub impl Hash for OwnershipLinkIdentity with fn hash_combine(self, hasher) {
  self.path.to_string().hash_combine(hasher)
}

///|
pub fn OwnershipState::OwnershipState(
  entries : Array[OwnershipEntry],
) -> OwnershipState raise {
  let stored_entries = @immut_hashmap.HashMap(
    entries.map(entry => (OwnershipLinkIdentity(entry.link), entry)),
  )
  guard stored_entries.length() == entries.length() else {
    fail("ownership links must be unique")
  }
  { version: 1, entries: stored_entries }
}
