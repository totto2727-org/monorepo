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
      Some(CommitId::CommitId("0123456789ABCDEF0123456789abcdef01234567")),
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
        repository.commit.unwrap().value(),
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
test "panic_GitHubRepository from_route rejects empty and malformed components" {
  try! (GitHubRepository::from_route("owner/") |> ignore)
  try! (GitHubRepository::from_route("owner/repo/extra") |> ignore)
  try! (GitHubRepository::from_route("owner/repo/name") |> ignore)
}

///|
test "panic_GitHubRepository from_route rejects path-like repository names" {
  try! (GitHubRepository::from_route("owner/.") |> ignore)
  try! (GitHubRepository::from_route("owner/..") |> ignore)
}

///|
test "panic_relative paths reject traversal and absolute paths" {
  try! (RelativeSourcePath::RelativeSourcePath("../outside") |> ignore)
  try! (RelativePluginPath::RelativePluginPath("plugin/../outside") |> ignore)
  try! (RelativeSourcePath::RelativeSourcePath("/absolute/repository") |> ignore)
  try! (RelativePluginPath::RelativePluginPath("/absolute/plugin") |> ignore)
}

///|
test "panic_domain names reject empty and slash values" {
  try! (PluginName::PluginName("") |> ignore)
  try! (PluginName::PluginName("plugin/name") |> ignore)
  try! (SkillName::SkillName("") |> ignore)
  try! (SkillName::SkillName("skill/name") |> ignore)
}

///|
test "panic_CommitId rejects bad length and hexadecimal boundaries" {
  try! (CommitId::CommitId("0123456789abcdef0123456789abcdef0123456") |> ignore)
  try! (CommitId::CommitId("0123456789abcdef0123456789abcdef012345678")
  |> ignore)
  try! (CommitId::CommitId("g123456789abcdef0123456789abcdef01234567") |> ignore)
}

///|
test "panic_lock rejects duplicate target repository plugin and skill identities" {
  let target = Target::Target(".agents/skills")
  let equivalent_target = Target::Target(".agents/./skills")
  try! (Lock::Lock([target, equivalent_target], []) |> ignore)
  let duplicate_skills = [
    SkillName::SkillName("sync"),
    SkillName::SkillName("sync"),
  ]
  try! (Plugin::Plugin(
    PluginName::PluginName("plugin"),
    RelativePluginPath::RelativePluginPath("plugin"),
    duplicate_skills,
  )
  |> ignore)
  let plugin = Plugin::Plugin(
    PluginName::PluginName("plugin"),
    RelativePluginPath::RelativePluginPath("plugin"),
    [],
  )
  try! (GitHubLockRepository::GitHubLockRepository(
    GitHubRepository::from_route("owner/repo"),
    MarketplaceKind::claude(),
    None,
    [plugin, plugin],
  )
  |> ignore)
  let repository = LockRepository::github(
    GitHubLockRepository::GitHubLockRepository(
      GitHubRepository::from_route("owner/repo"),
      MarketplaceKind::claude(),
      None,
      [],
    ),
  )
  try! (Lock::Lock([], [repository, repository]) |> ignore)
}

///|
test "SkillName preserves the c-plugin skill namespace" {
  inspect(SkillName::SkillName("c-plugin").value(), content="c-plugin")
}
