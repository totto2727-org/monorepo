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
pub impl Compare for GitHubOwnershipSource with fn compare(self, other) {
  let repository = self.repository.compare(other.repository)
  if repository != 0 {
    repository
  } else {
    let plugin = self.plugin.compare(other.plugin)
    if plugin != 0 {
      plugin
    } else {
      self.skill.compare(other.skill)
    }
  }
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
pub impl Compare for LocalOwnershipSource with fn compare(self, other) {
  let repository = self.repository.compare(other.repository)
  if repository != 0 {
    repository
  } else {
    let plugin = self.plugin.compare(other.plugin)
    if plugin != 0 {
      plugin
    } else {
      self.skill.compare(other.skill)
    }
  }
}

///|
pub enum OwnershipSource {
  GitHub(GitHubOwnershipSource)
  Local(LocalOwnershipSource)
} derive(Eq)

///|
pub(all) suberror OwnershipLinkError {
  RelativeOwnershipLink(path~ : @path.Path)
}

///|
pub(all) suberror OwnershipResolvedTargetError {
  RelativeOwnershipResolvedTarget(path~ : @path.Path)
}

///|
pub(all) suberror OwnershipManagedRootError {
  RelativeOwnershipManagedRoot(path~ : @path.Path)
}

///|
pub(all) suberror OwnershipEntryError {
  OwnershipLinkOutsideManagedRoot(
    link~ : @path.Path,
    managed_root~ : @path.Path
  )
}

///|
pub(all) suberror OwnershipStateError {
  DuplicateOwnershipLink(link~ : @path.Path)
}

///|
pub impl Compare for OwnershipSource with fn compare(self, other) {
  match (self, other) {
    (GitHub(left), GitHub(right)) => left.compare(right)
    (GitHub(_), Local(_)) => -1
    (Local(_), GitHub(_)) => 1
    (Local(left), Local(right)) => left.compare(right)
  }
}

///|
pub fn OwnershipSource::from_github(
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
pub struct OwnershipStatePath {
  path : @path.Path
} derive(Eq)

///|
pub fn OwnershipStatePath::OwnershipStatePath(
  path : @path.Path,
) -> OwnershipStatePath raise {
  guard path.is_absolute() else {
    fail("ownership state path must be absolute")
  }
  { path: path.normalize() }
}

///|
pub struct OwnershipLink {
  path : @path.Path
} derive(Eq)

///|
pub fn OwnershipLink::OwnershipLink(
  path : @path.Path,
) -> OwnershipLink raise OwnershipLinkError {
  guard path.is_absolute() else { raise RelativeOwnershipLink(path~) }
  { path: path.normalize() }
}

///|
pub impl Compare for OwnershipLink with fn compare(self, other) {
  self.path.to_string().lexical_compare(other.path.to_string())
}

///|
pub struct OwnershipResolvedTarget {
  path : @path.Path
} derive(Eq)

///|
pub fn OwnershipResolvedTarget::OwnershipResolvedTarget(
  path : @path.Path,
) -> OwnershipResolvedTarget raise OwnershipResolvedTargetError {
  guard path.is_absolute() else { raise RelativeOwnershipResolvedTarget(path~) }
  { path: path.normalize() }
}

///|
pub impl Compare for OwnershipResolvedTarget with fn compare(self, other) {
  self.path.to_string().lexical_compare(other.path.to_string())
}

///|
pub struct OwnershipManagedRoot {
  path : @path.Path
} derive(Eq)

///|
pub fn OwnershipManagedRoot::OwnershipManagedRoot(
  path : @path.Path,
) -> OwnershipManagedRoot raise OwnershipManagedRootError {
  guard path.is_absolute() else { raise RelativeOwnershipManagedRoot(path~) }
  { path: path.normalize() }
}

///|
pub impl Compare for OwnershipManagedRoot with fn compare(self, other) {
  self.path.to_string().lexical_compare(other.path.to_string())
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
) -> OwnershipEntry raise OwnershipEntryError {
  guard link.path.dirname() == managed_root.path else {
    raise OwnershipLinkOutsideManagedRoot(
      link=link.path,
      managed_root=managed_root.path,
    )
  }
  { link, symlink_target, resolved_target, managed_root, source }
}

///|
pub impl Compare for OwnershipEntry with fn compare(self, other) {
  let link = self.link.compare(other.link)
  if link != 0 {
    link
  } else {
    let symlink_target = self.symlink_target
      .to_string()
      .lexical_compare(other.symlink_target.to_string())
    if symlink_target != 0 {
      symlink_target
    } else {
      let resolved_target = self.resolved_target.compare(other.resolved_target)
      if resolved_target != 0 {
        resolved_target
      } else {
        let managed_root = self.managed_root.compare(other.managed_root)
        if managed_root != 0 {
          managed_root
        } else {
          self.source.compare(other.source)
        }
      }
    }
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
) -> OwnershipState raise OwnershipStateError {
  let mut stored_entries : @immut_hashmap.HashMap[
    OwnershipLinkIdentity,
    OwnershipEntry,
  ] = @immut_hashmap.HashMap([])
  for entry in entries {
    let identity = OwnershipLinkIdentity(entry.link.path)
    guard stored_entries.get(identity) is None else {
      raise DuplicateOwnershipLink(link=entry.link.path)
    }
    stored_entries = stored_entries.add(identity, entry)
  }
  { version: 1, entries: stored_entries }
}

///|
pub fn OwnershipState::empty() -> OwnershipState {
  { version: 1, entries: @immut_hashmap.HashMap([]) }
}
