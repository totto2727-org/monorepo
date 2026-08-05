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
fn ownership_root_json_path() -> @json.JsonPath raise {
  try {
    let _ : Bool = @json.from_json(Json::null())
    fail("expected JsonDecodeError")
  } catch {
    @json.JsonDecodeError::JsonDecodeError((path, _)) => path
    _ => fail("unexpected error")
  }
}

///|
test "OwnershipState ToJson::to_json - round trips ownership metadata" {
  let state = OwnershipState::OwnershipState([
    ownership_entry("/home/alice/project/.agents/skills/./sync"),
  ])
  let decoded : OwnershipState = @json.from_json(ToJson::to_json(state))
  inspect(decoded == state, content="true")
}

///|
test "OwnershipEntry OwnershipEntry - normalizes absolute paths but preserves symlink target" {
  let entry = ownership_entry(
    "/home/alice/project/.agents/skills/../skills/sync",
  )
  inspect(
    entry.link().to_string(),
    content="/home/alice/project/.agents/skills/sync",
  )
  inspect(
    entry.symlink_target().to_string(),
    content="../../../cache/skills/sync",
  )
  inspect(
    entry.resolved_target().to_string(),
    content="/home/alice/.cache/c-plugin/skills/sync",
  )
  inspect(
    entry.managed_root().to_string(),
    content="/home/alice/project/.agents/skills",
  )
}

///|
test "panic_OwnershipEntry OwnershipEntry - rejects a relative link" {
  try! (ownership_entry(".agents/skills/sync") |> ignore)
}

///|
test "panic_OwnershipEntry OwnershipEntry - rejects a relative resolved target" {
  try! (OwnershipEntry::OwnershipEntry(
    "/home/alice/project/.agents/skills/sync",
    "../../../cache/skills/sync",
    "cache/skills/sync",
    "/home/alice/project/.agents/skills",
    github_ownership_source(),
  )
  |> ignore)
}

///|
test "panic_OwnershipEntry OwnershipEntry - rejects a relative managed root" {
  try! (OwnershipEntry::OwnershipEntry(
    "/home/alice/project/.agents/skills/sync",
    "../../../cache/skills/sync",
    "/home/alice/.cache/c-plugin/skills/sync",
    ".agents",
    github_ownership_source(),
  )
  |> ignore)
}

///|
test "panic_OwnershipEntry OwnershipEntry - rejects a link outside managed root" {
  try! (ownership_entry("/home/alice/project/.agents-other/skills/sync")
  |> ignore)
}

///|
test "panic_OwnershipEntry OwnershipEntry - rejects a nested link below a managed skill root" {
  try! (ownership_entry("/home/alice/project/.agents/skills/nested/sync")
  |> ignore)
}

///|
test "panic_OwnershipState OwnershipState - rejects duplicate normalized links" {
  try! (OwnershipState::OwnershipState([
    ownership_entry("/home/alice/project/.agents/skills/sync"),
    ownership_entry("/home/alice/project/.agents/skills/./sync"),
  ])
  |> ignore)
}

///|
test "panic_OwnershipSource FromJson::from_json - rejects an invalid discriminator" {
  let json = @json.parse(
    "{\"type\":\"archive\",\"repository\":\"OpenAI/Codex\",\"plugin\":\"c-plugin\",\"skill\":\"sync\"}",
  )
  try! ((@json.from_json(json) : OwnershipSource) |> ignore)
}

///|
test "OwnershipSource FromJson::from_json - reports an invalid plugin at its exact path" {
  let json = @json.parse(
    "{\"type\":\"github\",\"repository\":\"OpenAI/Codex\",\"plugin\":\"bad/plugin\",\"skill\":\"sync\"}",
  )
  try {
    let _ : OwnershipSource = @json.from_json(json)
    fail("expected JsonDecodeError")
  } catch {
    @json.JsonDecodeError::JsonDecodeError((error_path, _)) =>
      inspect(error_path, content="/plugin")
    _ => fail("unexpected error")
  }
}

///|
test "panic_OwnershipState FromJson::from_json - rejects an unsupported version" {
  let json = @json.parse("{\"version\":2,\"entries\":[]}")
  try! ((@json.from_json(json) : OwnershipState) |> ignore)
}

///|
test "OwnershipState FromJson::from_json - retains the incoming JSON path" {
  let json = @json.parse("{\"version\":1,\"entries\":[{}]}")
  let path = ownership_root_json_path().add_key("ownership")
  try {
    let _ : OwnershipState = @json.from_json(json, path~)
    fail("expected JsonDecodeError")
  } catch {
    @json.JsonDecodeError::JsonDecodeError((error_path, _)) =>
      inspect(error_path, content="/ownership/entries/0/link")
    _ => fail("unexpected error")
  }
}
