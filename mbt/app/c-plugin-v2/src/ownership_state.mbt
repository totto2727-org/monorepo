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
pub struct OwnershipLink {
  path : @path.Path
} derive(Eq)

///|
pub fn OwnershipLink::OwnershipLink(path : @path.Path) -> OwnershipLink raise {
  guard path.is_absolute() else { fail("ownership link must be absolute") }
  { path: path.normalize() }
}

///|
pub struct OwnershipResolvedTarget {
  path : @path.Path
} derive(Eq)

///|
pub fn OwnershipResolvedTarget::OwnershipResolvedTarget(
  path : @path.Path,
) -> OwnershipResolvedTarget raise {
  guard path.is_absolute() else {
    fail("ownership resolved target must be absolute")
  }
  { path: path.normalize() }
}

///|
pub struct OwnershipManagedRoot {
  path : @path.Path
} derive(Eq)

///|
pub fn OwnershipManagedRoot::OwnershipManagedRoot(
  path : @path.Path,
) -> OwnershipManagedRoot raise {
  guard path.is_absolute() else {
    fail("ownership managed root must be absolute")
  }
  { path: path.normalize() }
}

///|
pub struct OwnershipEntry {
  link : OwnershipLink
  symlink_target : @path.Path
  resolved_target : OwnershipResolvedTarget
  managed_root : OwnershipManagedRoot
  source : OwnershipSource
} derive(Eq)

///|
pub fn OwnershipEntry::OwnershipEntry(
  link : OwnershipLink,
  symlink_target : @path.Path,
  resolved_target : OwnershipResolvedTarget,
  managed_root : OwnershipManagedRoot,
  source : OwnershipSource,
) -> OwnershipEntry raise {
  guard link.path.dirname() == managed_root.path else {
    fail("ownership link must be a direct child of its managed root")
  }
  { link, symlink_target, resolved_target, managed_root, source }
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
pub impl Compare for OwnershipLinkIdentity with fn compare(self, other) {
  self.path.to_string().lexical_compare(other.path.to_string())
}

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
    entries.map(entry => (OwnershipLinkIdentity(entry.link.path), entry)),
  )
  guard stored_entries.length() == entries.length() else {
    fail("ownership links must be unique")
  }
  { version: 1, entries: stored_entries }
}
