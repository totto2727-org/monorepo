///|
test "Ownership path values OwnershipLink - normalize absolute paths" {
  inspect(
    OwnershipLink::OwnershipLink("/workspace/skills/./sync").path.to_string(),
    content="/workspace/skills/sync",
  )
  inspect(
    OwnershipResolvedTarget::OwnershipResolvedTarget(
      "/cache/skills/../skills/sync",
    ).path.to_string(),
    content="/cache/skills/sync",
  )
  inspect(
    OwnershipManagedRoot::OwnershipManagedRoot("/workspace/./skills").path.to_string(),
    content="/workspace/skills",
  )
}

///|
test "panic_OwnershipLink OwnershipLink - rejects a relative path" {
  try! (OwnershipLink::OwnershipLink("skills/sync") |> ignore)
}

///|
test "panic_OwnershipResolvedTarget OwnershipResolvedTarget - rejects a relative path" {
  try! (OwnershipResolvedTarget::OwnershipResolvedTarget("cache/sync") |> ignore)
}

///|
test "panic_OwnershipManagedRoot OwnershipManagedRoot - rejects a relative path" {
  try! (OwnershipManagedRoot::OwnershipManagedRoot("workspace/skills") |> ignore)
}

///|
fn github_ownership_source() -> OwnershipSource raise {
  OwnershipSource::github(
    GitHubOwnershipSource::GitHubOwnershipSource(
      GitHubRepository::from_route("OpenAI/Codex"),
      PluginName::PluginName("c-plugin"),
      SkillName::SkillName("sync"),
    ),
  )
}

///|
fn ownership_entry(link : @path.Path) -> OwnershipEntry raise {
  OwnershipEntry::OwnershipEntry(
    OwnershipLink::OwnershipLink(link),
    "../../../cache/skills/sync",
    OwnershipResolvedTarget::OwnershipResolvedTarget(
      "/home/alice/.cache/c-plugin/skills/sync",
    ),
    OwnershipManagedRoot::OwnershipManagedRoot(
      "/home/alice/project/.agents/skills",
    ),
    github_ownership_source(),
  )
}

///|
test "OwnershipEntry OwnershipEntry - normalizes absolute paths but preserves symlink target" {
  let entry = ownership_entry(
    "/home/alice/project/.agents/skills/../skills/sync",
  )
  inspect(
    entry.link.path.to_string(),
    content="/home/alice/project/.agents/skills/sync",
  )
  inspect(
    entry.symlink_target.to_string(),
    content="../../../cache/skills/sync",
  )
  inspect(
    entry.resolved_target.path.to_string(),
    content="/home/alice/.cache/c-plugin/skills/sync",
  )
  inspect(
    entry.managed_root.path.to_string(),
    content="/home/alice/project/.agents/skills",
  )
}

///|
test "OwnershipState entries - stores an immutable hash map" {
  let state = OwnershipState::OwnershipState([
    ownership_entry("/home/alice/project/.agents/skills/sync"),
  ])
  let entries = state.entries
  let added_entry = ownership_entry(
    "/home/alice/project/.agents/skills/install",
  )
  let expanded_entries = state.entries.add(
    OwnershipLinkIdentity(added_entry.link.path),
    added_entry,
  )
  inspect(entries.length(), content="1")
  inspect(expanded_entries.length(), content="2")
}

///|
test "OwnershipState equality - ignores entry order" {
  let sync = ownership_entry("/home/alice/project/.agents/skills/sync")
  let install = ownership_entry("/home/alice/project/.agents/skills/install")
  let state = OwnershipState::OwnershipState([sync, install])
  let reordered = OwnershipState::OwnershipState([install, sync])
  inspect(state == reordered, content="true")
}

///|
test "OwnershipLinkIdentity Compare::compare - uses normalized lexical path order" {
  let first = OwnershipLinkIdentity(
    "/home/alice/project/.agents/skills/other/../alpha",
  )
  let last = OwnershipLinkIdentity("/home/alice/project/.agents/skills/z")
  inspect(first.compare(last), content="-1")
}

///|
test "OwnershipEntry OwnershipEntry - rejects a link outside managed root" {
  expect_ownership_rejection(
    fn() -> Unit raise {
      ownership_entry("/home/alice/project/.agents-other/skills/sync") |> ignore
    },
    "link outside managed root",
  )
}

///|
test "OwnershipEntry OwnershipEntry - rejects a nested link below a managed skill root" {
  expect_ownership_rejection(
    fn() -> Unit raise {
      ownership_entry("/home/alice/project/.agents/skills/nested/sync")
      |> ignore
    },
    "nested link below managed root",
  )
}

///|
test "OwnershipState OwnershipState - rejects duplicate normalized links" {
  expect_ownership_rejection(
    fn() -> Unit raise {
      OwnershipState::OwnershipState([
        ownership_entry("/home/alice/project/.agents/skills/sync"),
        ownership_entry("/home/alice/project/.agents/skills/./sync"),
      ])
      |> ignore
    },
    "duplicate normalized links",
  )
}
