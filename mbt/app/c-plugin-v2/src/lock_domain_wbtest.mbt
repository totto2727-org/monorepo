///|
test "lock domain preserves version two order and equality" {
  let plugin = Plugin::Plugin(
    PluginName::PluginName("c-plugin"),
    RelativePluginPath::RelativePluginPath("plugins/c-plugin"),
    [SkillName::SkillName("install"), SkillName::SkillName("sync")],
  )
  let github = LockRepository::github(
    GitHubLockRepository::GitHubLockRepository(
      GitHubRepository::from_route("OpenAI/Codex"),
      MarketplaceKind::codex(),
      CommitId::CommitId("0123456789ABCDEF0123456789abcdef01234567"),
      [plugin],
    ),
  )
  let local_repository = LockRepository::from_local(
    LocalLockRepository::LocalLockRepository(
      RelativeSourcePath::RelativeSourcePath("vendor/plugin"),
      MarketplaceKind::claude(),
      [
        Plugin::Plugin(
          PluginName::PluginName("local"),
          RelativePluginPath::RelativePluginPath("plugin"),
          [],
        ),
      ],
    ),
  )
  let lock = Lock::Lock(
    [Target::Target(".agents/skills"), Target::Target(".cursor/skills")],
    [github, local_repository],
  )
  inspect(lock.version, content="2")
  inspect(lock.targets[0].path.to_string(), content=".agents/skills")
  inspect(lock.repositories[0] == github, content="true")
  match lock.repositories[0] {
    LockRepository::GitHub(repository) => {
      inspect(repository.repository.owner().value(), content="openai")
      inspect(repository.repository.name().value(), content="codex")
      inspect(repository.repository.route(), content="openai/codex")
      inspect(
        repository.commit.value(),
        content="0123456789abcdef0123456789abcdef01234567",
      )
      inspect(
        repository.plugins[0].enabled_skills[0].value(),
        content="install",
      )
    }
    LockRepository::Local(_) =>
      fail("first repository must preserve GitHub order")
  }
}

///|
test "lock rejects duplicate target repository plugin and skill identities" {
  let target = Target::Target(".agents/skills")
  let equivalent_target = Target::Target(".agents/./skills")
  expect_rejection(
    fn() -> Unit raise { Lock::Lock([target, equivalent_target], []) |> ignore },
    "normalized target identity",
  )
  let duplicate_skills = [
    SkillName::SkillName("sync"),
    SkillName::SkillName("sync"),
  ]
  expect_rejection(
    fn() -> Unit raise {
      Plugin::Plugin(
        PluginName::PluginName("plugin"),
        RelativePluginPath::RelativePluginPath("plugin"),
        duplicate_skills,
      )
      |> ignore
    },
    "enabled skill identity",
  )
  let first_plugin = Plugin::Plugin(
    PluginName::PluginName("plugin"),
    RelativePluginPath::RelativePluginPath("first/plugin"),
    [],
  )
  let same_plugin_identity = Plugin::Plugin(
    PluginName::PluginName("plugin"),
    RelativePluginPath::RelativePluginPath("second/plugin"),
    [SkillName::SkillName("different-skill")],
  )
  expect_rejection(
    fn() -> Unit raise {
      GitHubLockRepository::GitHubLockRepository(
        GitHubRepository::from_route("owner/repo"),
        MarketplaceKind::claude(),
        CommitId::CommitId("0123456789abcdef0123456789abcdef01234567"),
        [first_plugin, same_plugin_identity],
      )
      |> ignore
    },
    "plugin name identity",
  )
  let first_repository = LockRepository::github(
    GitHubLockRepository::GitHubLockRepository(
      GitHubRepository::from_route("owner/repo"),
      MarketplaceKind::claude(),
      CommitId::CommitId("0123456789abcdef0123456789abcdef01234567"),
      [],
    ),
  )
  let same_repository_identity = LockRepository::github(
    GitHubLockRepository::GitHubLockRepository(
      GitHubRepository::from_route("OWNER/REPO"),
      MarketplaceKind::cursor(),
      CommitId::CommitId("fedcba9876543210fedcba9876543210fedcba98"),
      [],
    ),
  )
  expect_rejection(
    fn() -> Unit raise {
      Lock::Lock([], [first_repository, same_repository_identity]) |> ignore
    },
    "canonical repository identity",
  )
}
