///|
fn desired_links_local_repository(
  enabled_skills : Array[SkillName],
) -> LockRepository raise {
  desired_links_local_repository_at("vendor/repository", enabled_skills)
}

///|
fn desired_links_local_repository_at(
  path : String,
  enabled_skills : Array[SkillName],
) -> LockRepository raise {
  LockRepository::from_local(
    LocalLockRepository::LocalLockRepository(
      RelativeSourcePath::RelativeSourcePath(@path.Path(path)),
      MarketplaceKind::claude(),
      [
        Plugin::Plugin(
          PluginName::PluginName("plugin"),
          RelativePluginPath::RelativePluginPath(@path.Path("plugins/plugin")),
          enabled_skills,
        ),
      ],
    ),
  )
}

///|
fn desired_links_github_repository(
  enabled_skills : Array[SkillName],
) -> LockRepository raise {
  LockRepository::github(
    GitHubLockRepository::GitHubLockRepository(
      GitHubRepository::from_route("owner/repository"),
      MarketplaceKind::claude(),
      CommitId::CommitId("0123456789abcdef0123456789abcdef01234567"),
      [
        Plugin::Plugin(
          PluginName::PluginName("plugin"),
          RelativePluginPath::RelativePluginPath(@path.Path("plugins/plugin")),
          enabled_skills,
        ),
      ],
    ),
  )
}

///|
fn desired_links_resolved_skill(
  root : @path.Path,
  name : String,
) -> ResolvedSkill raise {
  {
    plugin_name: PluginName::PluginName("plugin"),
    plugin_path: RelativePluginPath::RelativePluginPath(
      @path.Path("plugins/plugin"),
    ),
    skill_name: SkillName::SkillName(name),
    skill_path: root.join("repository/plugins/plugin/skills").join(name),
  }
}

///|
fn desired_links_entry(
  plan : DesiredLinkPlan,
  link : @path.Path,
) -> OwnershipEntry {
  plan.ownership_state.entries
  .get(OwnershipLinkIdentity::OwnershipLinkIdentity(link))
  .unwrap()
}

///|
test "ManagedSkillRoot::ManagedSkillRoot - normalizes absolute path and rejects relative path" {
  let normalized = ManagedSkillRoot::ManagedSkillRoot(
    @path.Path("/tmp/managed/../managed"),
  )
  inspect(normalized.path.to_string(), content="/tmp/managed")
  try ManagedSkillRoot::ManagedSkillRoot(@path.Path("managed")) catch {
    _ => ()
  } noraise {
    _ => fail("relative managed root must fail")
  }
}

///|
async test "DesiredLinks plan_desired_skill_links - expands one enabled skill" {
  @async.with_task_group() <| group => {
    let root : @path.Path = @fs.tmpdir(prefix="c-plugin-v2-desired-links-")
    group.add_defer(() => @fs.rmdir(root.to_string(), recursive=true))
    let repository = desired_links_local_repository([
      SkillName::SkillName("install"),
    ])
    let plan = plan_desired_skill_links(
      @immut_hashset.HashSet([
        ManagedSkillRoot::ManagedSkillRoot(root.join(".agents/skills")),
        ManagedSkillRoot::ManagedSkillRoot(root.join(".cursor/skills")),
      ]),
      @immut_hashmap.HashMap([
        (
          repository.identity(),
          RepositorySkillResolution::Available(
            repository~,
            skills=ReadOnlyArray::from_array([
              desired_links_resolved_skill(root, "install"),
            ]),
          ),
        ),
      ]),
    )
    inspect(plan.ownership_state.entries.length(), content="2")
    for
      managed_root in [root.join(".agents/skills"), root.join(".cursor/skills")] {
      let entry = desired_links_entry(plan, managed_root.join("install"))
      inspect(
        entry.link.path.to_string(),
        content=managed_root.join("install").to_string(),
      )
      inspect(
        managed_root.join(entry.symlink_target).normalize().to_string(),
        content=entry.resolved_target.path.to_string(),
      )
    }
  }
}

///|
test "DesiredLinks plan_desired_skill_links - excludes disabled skill" {
  let repository = desired_links_local_repository([])
  let plan = plan_desired_skill_links(
    @immut_hashset.HashSet([
      ManagedSkillRoot::ManagedSkillRoot(@path.Path("/tmp/managed")),
    ]),
    @immut_hashmap.HashMap([
      (
        repository.identity(),
        Available(
          repository~,
          skills=ReadOnlyArray::from_array([
            desired_links_resolved_skill(@path.Path("/tmp"), "disabled"),
          ]),
        ),
      ),
    ]),
  )
  inspect(plan.ownership_state.entries.length(), content="0")
}

///|
test "DesiredLinks plan_desired_skill_links - canonical repository wins independent of insertion" {
  let skill = SkillName::SkillName("shared")
  let first = desired_links_local_repository_at("vendor/a", [skill])
  let last = desired_links_local_repository_at("vendor/z", [skill])
  let resolved = ReadOnlyArray::from_array([
    desired_links_resolved_skill(@path.Path("/tmp"), "shared"),
  ])
  let roots = @immut_hashset.HashSet([
    ManagedSkillRoot::ManagedSkillRoot(@path.Path("/tmp/managed")),
  ])
  let forward = plan_desired_skill_links(
    roots,
    @immut_hashmap.HashMap([
      (first.identity(), Available(repository=first, skills=resolved)),
      (last.identity(), Available(repository=last, skills=resolved)),
    ]),
  )
  let reverse = plan_desired_skill_links(
    roots,
    @immut_hashmap.HashMap([
      (last.identity(), Available(repository=last, skills=resolved)),
      (first.identity(), Available(repository=first, skills=resolved)),
    ]),
  )
  inspect(forward.ownership_state == reverse.ownership_state, content="true")
  match desired_links_entry(forward, @path.Path("/tmp/managed/shared")).source {
    Local(source) =>
      inspect(source.repository.path.to_string(), content="vendor/z")
    _ => fail("expected local winner")
  }
}

///|
test "DesiredLinks plan_desired_skill_links - later candidate in one repository wins" {
  let repository = desired_links_local_repository([
    SkillName::SkillName("shared"),
  ])
  let first = desired_links_resolved_skill(@path.Path("/tmp/first"), "shared")
  let last = desired_links_resolved_skill(@path.Path("/tmp/last"), "shared")
  let plan = plan_desired_skill_links(
    @immut_hashset.HashSet([
      ManagedSkillRoot::ManagedSkillRoot(@path.Path("/tmp/managed")),
    ]),
    @immut_hashmap.HashMap([
      (
        repository.identity(),
        Available(repository~, skills=ReadOnlyArray::from_array([first, last])),
      ),
    ]),
  )
  inspect(
    desired_links_entry(plan, @path.Path("/tmp/managed/shared")).resolved_target.path.to_string(),
    content=last.skill_path.to_string(),
  )
}

///|
test "DesiredLinks plan_desired_skill_links - unavailable repository reports without shadowing" {
  let skill = SkillName::SkillName("shared")
  let available = desired_links_local_repository_at("vendor/a", [skill])
  let unavailable = desired_links_local_repository_at("vendor/z", [skill])
  let plan = plan_desired_skill_links(
    @immut_hashset.HashSet([
      ManagedSkillRoot::ManagedSkillRoot(@path.Path("/tmp/managed")),
    ]),
    @immut_hashmap.HashMap([
      (
        available.identity(),
        Available(
          repository=available,
          skills=ReadOnlyArray::from_array([
            desired_links_resolved_skill(@path.Path("/tmp"), "shared"),
          ]),
        ),
      ),
      (
        unavailable.identity(),
        Unavailable(repository=unavailable, reason="offline"),
      ),
    ]),
  )
  inspect(plan.ownership_state.entries.length(), content="1")
  inspect(plan.unavailable_repositories.length(), content="1")
  inspect(
    plan.unavailable_repositories.get(unavailable.identity()).unwrap().reason,
    content="offline",
  )
}

///|
test "DesiredLinks plan_desired_skill_links - preserves GitHub and local provenance" {
  let github = desired_links_github_repository([SkillName::SkillName("github")])
  let local_repository = desired_links_local_repository([
    SkillName::SkillName("local"),
  ])
  let plan = plan_desired_skill_links(
    @immut_hashset.HashSet([
      ManagedSkillRoot::ManagedSkillRoot(@path.Path("/tmp/managed")),
    ]),
    @immut_hashmap.HashMap([
      (
        github.identity(),
        Available(
          repository=github,
          skills=ReadOnlyArray::from_array([
            desired_links_resolved_skill(@path.Path("/tmp"), "github"),
          ]),
        ),
      ),
      (
        local_repository.identity(),
        Available(
          repository=local_repository,
          skills=ReadOnlyArray::from_array([
            desired_links_resolved_skill(@path.Path("/tmp"), "local"),
          ]),
        ),
      ),
    ]),
  )
  match desired_links_entry(plan, @path.Path("/tmp/managed/github")).source {
    GitHub(source) => {
      inspect(source.repository.route(), content="owner/repository")
      inspect(source.plugin.value, content="plugin")
      inspect(source.skill.value, content="github")
    }
    _ => fail("expected GitHub provenance")
  }
  match desired_links_entry(plan, @path.Path("/tmp/managed/local")).source {
    Local(source) => {
      inspect(source.repository.path.to_string(), content="vendor/repository")
      inspect(source.plugin.value, content="plugin")
      inspect(source.skill.value, content="local")
    }
    _ => fail("expected local provenance")
  }
}

///|
test "DesiredLinks plan_desired_skill_links - empty roots or repositories produce empty plan" {
  let empty = plan_desired_skill_links(
    @immut_hashset.HashSet([]),
    @immut_hashmap.HashMap([]),
  )
  let repository = desired_links_local_repository([])
  let no_roots = plan_desired_skill_links(
    @immut_hashset.HashSet([]),
    @immut_hashmap.HashMap([
      (
        repository.identity(),
        Available(repository~, skills=ReadOnlyArray::from_array([])),
      ),
    ]),
  )
  let no_repositories = plan_desired_skill_links(
    @immut_hashset.HashSet([
      ManagedSkillRoot::ManagedSkillRoot(@path.Path("/tmp/managed")),
    ]),
    @immut_hashmap.HashMap([]),
  )
  for plan in [empty, no_roots, no_repositories] {
    inspect(plan.ownership_state.entries.length(), content="0")
    inspect(plan.unavailable_repositories.length(), content="0")
  }
}

///|
test "DesiredLinks plan_desired_skill_links - rejects repository identity mismatch" {
  let repository = desired_links_local_repository([])
  let expected = desired_links_local_repository_at("vendor/other", []).identity()
  try
    plan_desired_skill_links(
      @immut_hashset.HashSet([]),
      @immut_hashmap.HashMap([
        (expected, Available(repository~, skills=ReadOnlyArray::from_array([]))),
      ]),
    )
  catch {
    RepositoryIdentityMismatch(expected=error_expected, actual=error_actual) =>
      inspect(
        error_expected == expected && error_actual == repository.identity(),
        content="true",
      )
    error => raise error
  } noraise {
    _ => fail("identity mismatch must fail")
  }
}

///|
test "DesiredLinks plan_desired_skill_links - propagates an invalid resolved skill path" {
  let skill_name = SkillName::SkillName("install")
  let repository = desired_links_local_repository([skill_name])
  let invalid_skill : ResolvedSkill = {
    plugin_name: PluginName::PluginName("plugin"),
    plugin_path: RelativePluginPath::RelativePluginPath(
      @path.Path("plugins/plugin"),
    ),
    skill_name,
    skill_path: @path.Path("relative/skill"),
  }
  try
    plan_desired_skill_links(
      @immut_hashset.HashSet([
        ManagedSkillRoot::ManagedSkillRoot(@path.Path("/tmp/managed")),
      ]),
      @immut_hashmap.HashMap([
        (
          repository.identity(),
          Available(
            repository~,
            skills=ReadOnlyArray::from_array([invalid_skill]),
          ),
        ),
      ]),
    )
  catch {
    Failure::Failure(_) => ()
    error => raise error
  } noraise {
    _ => fail("invalid resolved skill path must raise")
  }
}
