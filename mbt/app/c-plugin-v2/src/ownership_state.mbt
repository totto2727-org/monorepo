///|
let ownership_source_type_lens : @lens.Lens[String] = @lens.root().string(
  "type",
)

///|
let ownership_source_repository_lens : @lens.Lens[String] = @lens.root().string(
  "repository",
)

///|
let ownership_source_plugin_lens : @lens.Lens[String] = @lens.root().string(
  "plugin",
)

///|
let ownership_source_skill_lens : @lens.Lens[String] = @lens.root().string(
  "skill",
)

///|
let ownership_entry_link_lens : @lens.Lens[String] = @lens.root().string("link")

///|
let ownership_entry_symlink_target_lens : @lens.Lens[String] = @lens.root().string(
  "symlinkTarget",
)

///|
let ownership_entry_resolved_target_lens : @lens.Lens[String] = @lens.root().string(
  "resolvedTarget",
)

///|
let ownership_entry_managed_root_lens : @lens.Lens[String] = @lens.root().string(
  "managedRoot",
)

///|
let ownership_entry_source_lens : @lens.Lens[Json] = @lens.root().json("source")

///|
let ownership_state_version_lens : @lens.Lens[Int] = @lens.root().int("version")

///|
let ownership_state_entries_lens : @lens.Lens[Json] = @lens.root().json(
  "entries",
)

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
pub struct OwnershipEntry {
  link : @path.Path
  symlink_target : @path.Path
  resolved_target : @path.Path
  managed_root : @path.Path
  source : OwnershipSource
} derive(Eq)

///|
pub fn OwnershipEntry::OwnershipEntry(
  link : @path.Path,
  symlink_target : @path.Path,
  resolved_target : @path.Path,
  managed_root : @path.Path,
  source : OwnershipSource,
) -> OwnershipEntry raise {
  guard link.is_absolute() else { fail("ownership link must be absolute") }
  guard resolved_target.is_absolute() else {
    fail("ownership resolved target must be absolute")
  }
  guard managed_root.is_absolute() else {
    fail("ownership managed root must be absolute")
  }
  let normalized_link = link.normalize()
  let normalized_resolved_target = resolved_target.normalize()
  let normalized_managed_root = managed_root.normalize()
  guard normalized_link.dirname() == normalized_managed_root else {
    fail("ownership link must be a direct child of its managed root")
  }
  {
    link: normalized_link,
    symlink_target,
    resolved_target: normalized_resolved_target,
    managed_root: normalized_managed_root,
    source,
  }
}

///|
pub fn OwnershipEntry::link(self : OwnershipEntry) -> @path.Path {
  self.link
}

///|
pub fn OwnershipEntry::symlink_target(self : OwnershipEntry) -> @path.Path {
  self.symlink_target
}

///|
pub fn OwnershipEntry::resolved_target(self : OwnershipEntry) -> @path.Path {
  self.resolved_target
}

///|
pub fn OwnershipEntry::managed_root(self : OwnershipEntry) -> @path.Path {
  self.managed_root
}

///|
pub fn OwnershipEntry::source(self : OwnershipEntry) -> OwnershipSource {
  self.source
}

///|
pub struct OwnershipState {
  version : Int
  entries : Array[OwnershipEntry]
} derive(Eq)

///|
pub fn OwnershipState::OwnershipState(
  entries : Array[OwnershipEntry],
) -> OwnershipState raise {
  let unique_links = entries
    .iter()
    .fold(init=[], fn(unique, entry) {
      if unique.contains(entry.link) {
        unique
      } else {
        [..unique, entry.link]
      }
    })
  guard unique_links.length() == entries.length() else {
    fail("ownership links must be unique")
  }
  { version: 1, entries: [..entries] }
}

///|
pub fn OwnershipState::version(self : OwnershipState) -> Int {
  self.version
}

///|
pub fn OwnershipState::entries(self : OwnershipState) -> Array[OwnershipEntry] {
  [..self.entries]
}

///|
fn decode_ownership_plugin(
  json : Json,
  path : @json.JsonPath,
) -> PluginName raise @json.JsonDecodeError {
  let plugin = ownership_source_plugin_lens.get_or_json_decode_error(json, path)
  PluginName(plugin) catch {
    _ =>
      raise ownership_source_plugin_lens.json_decode_error(
        path, "invalid ownership plugin",
      )
  }
}

///|
fn decode_ownership_skill(
  json : Json,
  path : @json.JsonPath,
) -> SkillName raise @json.JsonDecodeError {
  let skill = ownership_source_skill_lens.get_or_json_decode_error(json, path)
  SkillName(skill) catch {
    _ =>
      raise ownership_source_skill_lens.json_decode_error(
        path, "invalid ownership skill",
      )
  }
}

///|
fn decode_github_ownership_source_payload(
  json : Json,
  path : @json.JsonPath,
) -> OwnershipSource raise @json.JsonDecodeError {
  let repository_value = ownership_source_repository_lens.get_or_json_decode_error(
    json, path,
  )
  let repository = GitHubRepository::from_route(repository_value) catch {
    _ =>
      raise ownership_source_repository_lens.json_decode_error(
        path, "invalid GitHub ownership repository",
      )
  }
  GitHub(
    GitHubOwnershipSource(
      repository,
      decode_ownership_plugin(json, path),
      decode_ownership_skill(json, path),
    ),
  )
}

///|
fn decode_local_ownership_source_payload(
  json : Json,
  path : @json.JsonPath,
) -> OwnershipSource raise @json.JsonDecodeError {
  let repository_value = ownership_source_repository_lens.get_or_json_decode_error(
    json, path,
  )
  let repository = RelativeSourcePath(repository_value) catch {
    _ =>
      raise ownership_source_repository_lens.json_decode_error(
        path, "invalid local ownership repository",
      )
  }
  Local(
    LocalOwnershipSource(
      repository,
      decode_ownership_plugin(json, path),
      decode_ownership_skill(json, path),
    ),
  )
}

///|
pub impl FromJson for OwnershipSource with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "expected ownership source object"))
  }
  let source_type = ownership_source_type_lens.get_or_json_decode_error(
    json, path,
  )
  match source_type {
    "github" => decode_github_ownership_source_payload(json, path)
    "local" => decode_local_ownership_source_payload(json, path)
    _ =>
      raise ownership_source_type_lens.json_decode_error(
        path,
        "unsupported ownership source type: \{source_type}",
      )
  }
}

///|
pub impl ToJson for OwnershipSource with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  match self {
    GitHub(source) => {
      ownership_source_type_lens.set_or_abort(builder, "github")
      ownership_source_repository_lens.set_or_abort(
        builder,
        source.repository.route(),
      )
      ownership_source_plugin_lens.set_or_abort(builder, source.plugin.value())
      ownership_source_skill_lens.set_or_abort(builder, source.skill.value())
    }
    Local(source) => {
      ownership_source_type_lens.set_or_abort(builder, "local")
      ownership_source_repository_lens.set_or_abort(
        builder,
        source.repository.path().to_string(),
      )
      ownership_source_plugin_lens.set_or_abort(builder, source.plugin.value())
      ownership_source_skill_lens.set_or_abort(builder, source.skill.value())
    }
  }
  builder.to_json()
}

///|
pub impl FromJson for OwnershipEntry with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "expected ownership entry object"))
  }
  let link_value = ownership_entry_link_lens.get_or_json_decode_error(
    json, path,
  )
  let symlink_target_value = ownership_entry_symlink_target_lens.get_or_json_decode_error(
    json, path,
  )
  let resolved_target_value = ownership_entry_resolved_target_lens.get_or_json_decode_error(
    json, path,
  )
  let managed_root_value = ownership_entry_managed_root_lens.get_or_json_decode_error(
    json, path,
  )
  let source_json = ownership_entry_source_lens.get_or_json_decode_error(
    json, path,
  )
  let source : OwnershipSource = @json.from_json(
    source_json,
    path=ownership_entry_source_lens.add_to_json_path(path),
  )
  let link : @path.Path = link_value
  let symlink_target : @path.Path = symlink_target_value
  let resolved_target : @path.Path = resolved_target_value
  let managed_root : @path.Path = managed_root_value
  OwnershipEntry(link, symlink_target, resolved_target, managed_root, source) catch {
    _ =>
      raise ownership_entry_link_lens.json_decode_error(
        path, "invalid ownership entry paths",
      )
  }
}

///|
pub impl ToJson for OwnershipEntry with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  ownership_entry_link_lens.set_or_abort(builder, self.link.to_string())
  ownership_entry_symlink_target_lens.set_or_abort(
    builder,
    self.symlink_target.to_string(),
  )
  ownership_entry_resolved_target_lens.set_or_abort(
    builder,
    self.resolved_target.to_string(),
  )
  ownership_entry_managed_root_lens.set_or_abort(
    builder,
    self.managed_root.to_string(),
  )
  ownership_entry_source_lens.set_or_abort(
    builder,
    ToJson::to_json(self.source),
  )
  builder.to_json()
}

///|
pub impl FromJson for OwnershipState with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "expected ownership state object"))
  }
  let version = ownership_state_version_lens.get_or_json_decode_error(
    json, path,
  )
  guard version == 1 else {
    raise ownership_state_version_lens.json_decode_error(
      path, "unsupported ownership state version",
    )
  }
  let entries_json = ownership_state_entries_lens.get_or_json_decode_error(
    json, path,
  )
  let entries : Array[OwnershipEntry] = @json.from_json(
    entries_json,
    path=ownership_state_entries_lens.add_to_json_path(path),
  )
  OwnershipState(entries) catch {
    _ =>
      raise ownership_state_entries_lens.json_decode_error(
        path, "ownership links must be unique",
      )
  }
}

///|
pub impl ToJson for OwnershipState with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  ownership_state_version_lens.set_or_abort(builder, self.version)
  ownership_state_entries_lens.set_or_abort(builder, self.entries.to_json())
  builder.to_json()
}
