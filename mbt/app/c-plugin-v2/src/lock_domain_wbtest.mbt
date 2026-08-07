///|
fn expect_rejection(action : () -> Unit raise, detail : String) -> Unit raise {
  try action() catch {
    _ => ()
  } noraise {
    _ => fail("expected rejection: \{detail}")
  }
}

///|
test "GitHubRepository from_route rejects empty and malformed components" {
  expect_rejection(
    fn() -> Unit raise { GitHubRepository::from_route("owner/") |> ignore },
    "empty repository component",
  )
  expect_rejection(
    fn() -> Unit raise {
      GitHubRepository::from_route("owner/repo/extra") |> ignore
    },
    "three route components",
  )
  expect_rejection(
    fn() -> Unit raise {
      GitHubRepository::from_route("owner/repo/name") |> ignore
    },
    "path-like route",
  )
}

///|
test "GitHubRepository from_route rejects path-like repository names" {
  expect_rejection(
    fn() -> Unit raise { GitHubRepository::from_route("owner/.") |> ignore },
    "dot repository",
  )
  expect_rejection(
    fn() -> Unit raise { GitHubRepository::from_route("owner/..") |> ignore },
    "dot-dot repository",
  )
}

///|
test "GitHubOwner enforces GitHub component boundaries" {
  inspect(GitHubOwner::GitHubOwner("a".repeat(39)).value.length(), content="39")
  expect_rejection(
    fn() -> Unit raise { GitHubOwner::GitHubOwner("-owner") |> ignore },
    "leading hyphen",
  )
  expect_rejection(
    fn() -> Unit raise { GitHubOwner::GitHubOwner("owner-") |> ignore },
    "trailing hyphen",
  )
  expect_rejection(
    fn() -> Unit raise { GitHubOwner::GitHubOwner("owner--name") |> ignore },
    "consecutive hyphens",
  )
  expect_rejection(
    fn() -> Unit raise { GitHubOwner::GitHubOwner("a".repeat(40)) |> ignore },
    "length 40",
  )
}

///|
test "GitHubRepositoryName enforces GitHub length boundary" {
  inspect(
    GitHubRepositoryName::GitHubRepositoryName("a".repeat(100)).value.length(),
    content="100",
  )
  expect_rejection(
    fn() -> Unit raise {
      GitHubRepositoryName::GitHubRepositoryName("a".repeat(101)) |> ignore
    },
    "length 101",
  )
}

///|
test "relative paths reject traversal and absolute paths" {
  expect_rejection(
    fn() -> Unit raise {
      RelativeSourcePath::RelativeSourcePath("../outside") |> ignore
    },
    "source parent traversal",
  )
  expect_rejection(
    fn() -> Unit raise {
      RelativePluginPath::RelativePluginPath("plugin/../outside") |> ignore
    },
    "plugin parent traversal",
  )
  expect_rejection(
    fn() -> Unit raise {
      RelativeSourcePath::RelativeSourcePath("/absolute/repository") |> ignore
    },
    "absolute source path",
  )
  expect_rejection(
    fn() -> Unit raise {
      RelativePluginPath::RelativePluginPath("/absolute/plugin") |> ignore
    },
    "absolute plugin path",
  )
}

///|
test "domain names reject empty and slash values" {
  expect_rejection(
    fn() -> Unit raise { PluginName::PluginName("") |> ignore },
    "empty plugin",
  )
  expect_rejection(
    fn() -> Unit raise { PluginName::PluginName("plugin/name") |> ignore },
    "path-like plugin",
  )
  expect_rejection(
    fn() -> Unit raise { SkillName::SkillName("") |> ignore },
    "empty skill",
  )
  expect_rejection(
    fn() -> Unit raise { SkillName::SkillName("skill/name") |> ignore },
    "path-like skill",
  )
}

///|
test "CommitId rejects bad length and hexadecimal boundaries" {
  expect_rejection(
    fn() -> Unit raise {
      CommitId::CommitId("0123456789abcdef0123456789abcdef0123456") |> ignore
    },
    "39-character commit",
  )
  expect_rejection(
    fn() -> Unit raise {
      CommitId::CommitId("0123456789abcdef0123456789abcdef012345678") |> ignore
    },
    "41-character commit",
  )
  expect_rejection(
    fn() -> Unit raise {
      CommitId::CommitId("g123456789abcdef0123456789abcdef01234567") |> ignore
    },
    "non-hexadecimal commit",
  )
}

///|
test "SkillName preserves the c-plugin skill namespace" {
  inspect(SkillName::SkillName("c-plugin").value, content="c-plugin")
}

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
  inspect(lock.targets()[0].path.to_string(), content=".agents/skills")
  inspect(lock.repositories()[0] == github, content="true")
  match lock.repositories()[0] {
    LockRepository::GitHub(repository) => {
      inspect(repository.repository.owner.value, content="openai")
      inspect(repository.repository.name.value, content="codex")
      inspect(repository.repository.route(), content="openai/codex")
      inspect(
        repository.commit.value,
        content="0123456789abcdef0123456789abcdef01234567",
      )
      inspect(
        repository.plugins()[0].enabled_skills()[0].value,
        content="install",
      )
    }
    LockRepository::Local(_) =>
      fail("first repository must preserve GitHub order")
  }
}

///|
test "mutable aggregate fields expose detached readonly snapshots" {
  let plugin = Plugin::Plugin(
    PluginName::PluginName("plugin"),
    RelativePluginPath::RelativePluginPath("plugin"),
    [SkillName::SkillName("install")],
  )
  let enabled_skills = plugin.enabled_skills()
  plugin.enabled_skills.push(SkillName::SkillName("sync"))
  inspect(enabled_skills.length(), content="1")
  inspect(plugin.enabled_skills().length(), content="2")
  let github = GitHubLockRepository::GitHubLockRepository(
    GitHubRepository::from_route("openai/codex"),
    MarketplaceKind::codex(),
    CommitId::CommitId("0123456789abcdef0123456789abcdef01234567"),
    [plugin],
  )
  let github_plugins = github.plugins()
  github.plugins.push(
    Plugin::Plugin(
      PluginName::PluginName("github-extra"),
      RelativePluginPath::RelativePluginPath("github-extra"),
      [],
    ),
  )
  inspect(github_plugins.length(), content="1")
  inspect(github.plugins().length(), content="2")
  let local_repository = LocalLockRepository::LocalLockRepository(
    RelativeSourcePath::RelativeSourcePath("vendor/plugin"),
    MarketplaceKind::claude(),
    [plugin],
  )
  let local_plugins = local_repository.plugins()
  local_repository.plugins.push(
    Plugin::Plugin(
      PluginName::PluginName("local-extra"),
      RelativePluginPath::RelativePluginPath("local-extra"),
      [],
    ),
  )
  inspect(local_plugins.length(), content="1")
  inspect(local_repository.plugins().length(), content="2")
  let lock = Lock::Lock([Target::Target(".agents/skills")], [
    LockRepository::github(github),
  ])
  let targets = lock.targets()
  let repositories = lock.repositories()
  lock.targets.push(Target::Target(".cursor/skills"))
  lock.repositories.push(LockRepository::from_local(local_repository))
  inspect(targets.length(), content="1")
  inspect(repositories.length(), content="1")
  inspect(lock.targets().length(), content="2")
  inspect(lock.repositories().length(), content="2")
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
