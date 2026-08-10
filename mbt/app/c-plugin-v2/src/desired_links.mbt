///|
pub struct ManagedSkillRoot {
  path : @path.Path
} derive(Eq)

///|
pub impl Hash for ManagedSkillRoot with fn hash_combine(self, hasher) {
  self.path.to_string().hash_combine(hasher)
}

///|
pub fn ManagedSkillRoot::ManagedSkillRoot(
  path : @path.Path,
) -> ManagedSkillRoot raise {
  guard path.is_absolute() else { fail("managed skill root must be absolute") }
  { path: path.normalize() }
}

///|
pub(all) enum RepositorySkillResolution {
  Available(
    repository~ : LockRepository,
    skills~ : ReadOnlyArray[ResolvedSkill]
  )
  Unavailable(repository~ : LockRepository, reason~ : String)
}

///|
pub struct RepositorySkillResolutions {
  entries : @immut_hashmap.HashMap[
    RepositoryIdentity,
    RepositorySkillResolution,
  ]
}

///|
pub(all) suberror RepositorySkillResolutionsError {
  DuplicateRepositoryIdentity(identity~ : RepositoryIdentity)
}

///|
pub fn RepositorySkillResolutions::RepositorySkillResolutions(
  resolutions : Array[RepositorySkillResolution],
) -> RepositorySkillResolutions raise RepositorySkillResolutionsError {
  let mut entries : @immut_hashmap.HashMap[
    RepositoryIdentity,
    RepositorySkillResolution,
  ] = @immut_hashmap.HashMap([])
  for resolution in resolutions {
    let identity = match resolution {
      Available(repository~, skills=_) | Unavailable(repository~, reason=_) =>
        repository.identity()
    }
    guard entries.get(identity) is None else {
      raise DuplicateRepositoryIdentity(identity~)
    }
    entries = entries.add(identity, resolution)
  }
  { entries, }
}

///|
pub(all) struct RepositoryUnavailable {
  repository : RepositoryIdentity
  reason : String
}

///|
pub(all) struct DesiredLinkPlan {
  ownership_state : OwnershipState
  unavailable_repositories : @immut_hashmap.HashMap[
    RepositoryIdentity,
    RepositoryUnavailable,
  ]
}

///|
pub(all) enum DesiredEntryConstructionStage {
  Link
  ResolvedTarget
  ManagedRoot
  Entry
} derive(Debug, Eq)

///|
pub(all) suberror DesiredLinkPlanningError {
  InvalidDesiredEntry(
    stage~ : DesiredEntryConstructionStage,
    repository~ : RepositoryIdentity,
    managed_root~ : @path.Path,
    skill~ : SkillName,
    skill_path~ : @path.Path
  )
  InvalidOwnershipState(link~ : @path.Path)
}

///|
struct DesiredLinkCandidate {
  repository : RepositoryIdentity
  entry : OwnershipEntry
}

///|
fn enabled_plugin(
  repository : LockRepository,
  skill : ResolvedSkill,
) -> Plugin? {
  match repository {
    GitHub(repository) => repository.plugins.get(skill.plugin_name)
    Local(repository) => repository.plugins.get(skill.plugin_name)
  }
}

///|
fn ownership_source(
  repository : LockRepository,
  skill : ResolvedSkill,
) -> OwnershipSource {
  match repository {
    GitHub(repository) =>
      OwnershipSource::from_github(
        GitHubOwnershipSource::GitHubOwnershipSource(
          repository.repository,
          skill.plugin_name,
          skill.skill_name,
        ),
      )
    Local(repository) =>
      OwnershipSource::from_local(
        LocalOwnershipSource::LocalOwnershipSource(
          repository.path,
          skill.plugin_name,
          skill.skill_name,
        ),
      )
  }
}

///|
fn desired_entry(
  root : ManagedSkillRoot,
  repository : LockRepository,
  skill : ResolvedSkill,
) -> OwnershipEntry raise DesiredLinkPlanningError {
  let repository_identity = repository.identity()
  let link_path = root.path.join(skill.skill_name.value)
  let link = OwnershipLink::OwnershipLink(link_path) catch {
    RelativeOwnershipLink(_) =>
      raise InvalidDesiredEntry(
        stage=Link,
        repository=repository_identity,
        managed_root=root.path,
        skill=skill.skill_name,
        skill_path=skill.skill_path,
      )
  }
  let resolved_target = OwnershipResolvedTarget::OwnershipResolvedTarget(
    skill.skill_path,
  ) catch {
    RelativeOwnershipResolvedTarget(_) =>
      raise InvalidDesiredEntry(
        stage=ResolvedTarget,
        repository=repository_identity,
        managed_root=root.path,
        skill=skill.skill_name,
        skill_path=skill.skill_path,
      )
  }
  let managed_root = OwnershipManagedRoot::OwnershipManagedRoot(root.path) catch {
    RelativeOwnershipManagedRoot(_) =>
      raise InvalidDesiredEntry(
        stage=ManagedRoot,
        repository=repository_identity,
        managed_root=root.path,
        skill=skill.skill_name,
        skill_path=skill.skill_path,
      )
  }
  OwnershipEntry::OwnershipEntry(
    link,
    skill.skill_path.relative(base=root.path),
    resolved_target,
    managed_root,
    ownership_source(repository, skill),
  ) catch {
    OwnershipLinkOutsideManagedRoot(..) =>
      raise InvalidDesiredEntry(
        stage=Entry,
        repository=repository_identity,
        managed_root=root.path,
        skill=skill.skill_name,
        skill_path=skill.skill_path,
      )
  }
}

///|
fn desired_ownership_state(
  entries : Array[OwnershipEntry],
) -> OwnershipState raise DesiredLinkPlanningError {
  OwnershipState::OwnershipState(entries) catch {
    DuplicateOwnershipLink(link~) => raise InvalidOwnershipState(link~)
  }
}

///|
pub fn plan_desired_skill_links(
  managed_roots : @immut_hashset.HashSet[ManagedSkillRoot],
  repositories : RepositorySkillResolutions,
) -> DesiredLinkPlan raise DesiredLinkPlanningError {
  let mut candidates : @immut_hashmap.HashMap[
    OwnershipLinkIdentity,
    DesiredLinkCandidate,
  ] = @immut_hashmap.HashMap([])
  let mut unavailable : @immut_hashmap.HashMap[
    RepositoryIdentity,
    RepositoryUnavailable,
  ] = @immut_hashmap.HashMap([])
  for pair in repositories.entries.to_array() {
    match pair.1 {
      Unavailable(repository~, reason~) => {
        let identity = repository.identity()
        unavailable = unavailable.add(identity, { repository: identity, reason })
      }
      Available(repository~, skills~) => {
        let identity = repository.identity()
        for skill in skills {
          match enabled_plugin(repository, skill) {
            Some(plugin) if plugin.enabled_skills.contains(skill.skill_name) =>
              for root in managed_roots {
                let entry = desired_entry(root, repository, skill)
                let link_identity = OwnershipLinkIdentity::OwnershipLinkIdentity(
                  entry.link.path,
                )
                match candidates.get(link_identity) {
                  Some(existing) if identity.compare(existing.repository) < 0 =>
                    ()
                  _ =>
                    candidates = candidates.add(link_identity, {
                      repository: identity,
                      entry,
                    })
                }
              }
            _ => ()
          }
        }
      }
    }
  }
  let entries = candidates.to_array().map(pair => pair.1.entry)
  {
    ownership_state: desired_ownership_state(entries),
    unavailable_repositories: unavailable,
  }
}
