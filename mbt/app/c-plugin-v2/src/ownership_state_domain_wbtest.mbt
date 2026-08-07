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
    link,
    "../../../cache/skills/sync",
    "/home/alice/.cache/c-plugin/skills/sync",
    "/home/alice/project/.agents/skills",
    github_ownership_source(),
  )
}

///|
test "OwnershipEntry OwnershipEntry - normalizes absolute paths but preserves symlink target" {
  let entry = ownership_entry(
    "/home/alice/project/.agents/skills/../skills/sync",
  )
  inspect(
    entry.link.to_string(),
    content="/home/alice/project/.agents/skills/sync",
  )
  inspect(
    entry.symlink_target.to_string(),
    content="../../../cache/skills/sync",
  )
  inspect(
    entry.resolved_target.to_string(),
    content="/home/alice/.cache/c-plugin/skills/sync",
  )
  inspect(
    entry.managed_root.to_string(),
    content="/home/alice/project/.agents/skills",
  )
}

///|
test "OwnershipState entries - returns a detached readonly snapshot" {
  let state = OwnershipState::OwnershipState([
    ownership_entry("/home/alice/project/.agents/skills/sync"),
  ])
  let entries = state.entries()
  state.entries.push(
    ownership_entry("/home/alice/project/.agents/skills/install"),
  )
  inspect(entries.length(), content="1")
  inspect(state.entries().length(), content="2")
}

///|
test "OwnershipEntry OwnershipEntry - rejects a relative link" {
  expect_ownership_rejection(
    fn() -> Unit raise { ownership_entry(".agents/skills/sync") |> ignore },
    "relative link",
  )
}

///|
test "OwnershipEntry OwnershipEntry - rejects a relative resolved target" {
  expect_ownership_rejection(
    fn() -> Unit raise {
      OwnershipEntry::OwnershipEntry(
        "/home/alice/project/.agents/skills/sync",
        "../../../cache/skills/sync",
        "cache/skills/sync",
        "/home/alice/project/.agents/skills",
        github_ownership_source(),
      )
      |> ignore
    },
    "relative resolved target",
  )
}

///|
test "OwnershipEntry OwnershipEntry - rejects a relative managed root" {
  expect_ownership_rejection(
    fn() -> Unit raise {
      OwnershipEntry::OwnershipEntry(
        "/home/alice/project/.agents/skills/sync",
        "../../../cache/skills/sync",
        "/home/alice/.cache/c-plugin/skills/sync",
        ".agents",
        github_ownership_source(),
      )
      |> ignore
    },
    "relative managed root",
  )
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
