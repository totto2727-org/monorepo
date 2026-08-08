///|
let ownership_source_type_lens : @lens.Lens[String] = @lens.root().string(
  "type",
)

///|
let ownership_source_repository_lens : @lens.Lens[Json] = @lens.root().json(
  "repository",
)

///|
let ownership_source_plugin_lens : @lens.Lens[Json] = @lens.root().json(
  "plugin",
)

///|
let ownership_source_skill_lens : @lens.Lens[Json] = @lens.root().json("skill")

///|
let ownership_entry_link_lens : @lens.Lens[Json] = @lens.root().json("link")

///|
let ownership_entry_symlink_target_lens : @lens.Lens[Json] = @lens.root().json(
  "symlinkTarget",
)

///|
let ownership_entry_resolved_target_lens : @lens.Lens[Json] = @lens.root().json(
  "resolvedTarget",
)

///|
let ownership_entry_managed_root_lens : @lens.Lens[Json] = @lens.root().json(
  "managedRoot",
)

///|
let ownership_entry_source_lens : @lens.Lens[Json] = @lens.root().json("source")

///|
let ownership_state_version_lens : @lens.Lens[Json] = @lens.root().json(
  "version",
)

///|
let ownership_state_entries_lens : @lens.Lens[Json] = @lens.root().json(
  "entries",
)

///|
pub impl FromJson for OwnershipSource with fn from_json(json, path) {
  let source_type = ownership_source_type_lens.get_or_json_decode_error(
    json, path,
  )
  match source_type {
    "github" => {
      let repository : GitHubRepository = @json.from_json(
        ownership_source_repository_lens.get_or_json_decode_error(json, path),
        path=ownership_source_repository_lens.add_to_json_path(path),
      )
      let plugin : PluginName = @json.from_json(
        ownership_source_plugin_lens.get_or_json_decode_error(json, path),
        path=ownership_source_plugin_lens.add_to_json_path(path),
      )
      let skill : SkillName = @json.from_json(
        ownership_source_skill_lens.get_or_json_decode_error(json, path),
        path=ownership_source_skill_lens.add_to_json_path(path),
      )
      OwnershipSource::github(
        GitHubOwnershipSource::GitHubOwnershipSource(repository, plugin, skill),
      )
    }
    "local" => {
      let repository : RelativeSourcePath = @json.from_json(
        ownership_source_repository_lens.get_or_json_decode_error(json, path),
        path=ownership_source_repository_lens.add_to_json_path(path),
      )
      let plugin : PluginName = @json.from_json(
        ownership_source_plugin_lens.get_or_json_decode_error(json, path),
        path=ownership_source_plugin_lens.add_to_json_path(path),
      )
      let skill : SkillName = @json.from_json(
        ownership_source_skill_lens.get_or_json_decode_error(json, path),
        path=ownership_source_skill_lens.add_to_json_path(path),
      )
      OwnershipSource::from_local(
        LocalOwnershipSource::LocalOwnershipSource(repository, plugin, skill),
      )
    }
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
        ToJson::to_json(source.repository),
      )
      ownership_source_plugin_lens.set_or_abort(
        builder,
        ToJson::to_json(source.plugin),
      )
      ownership_source_skill_lens.set_or_abort(
        builder,
        ToJson::to_json(source.skill),
      )
    }
    Local(source) => {
      ownership_source_type_lens.set_or_abort(builder, "local")
      ownership_source_repository_lens.set_or_abort(
        builder,
        ToJson::to_json(source.repository),
      )
      ownership_source_plugin_lens.set_or_abort(
        builder,
        ToJson::to_json(source.plugin),
      )
      ownership_source_skill_lens.set_or_abort(
        builder,
        ToJson::to_json(source.skill),
      )
    }
  }
  builder.to_json()
}

///|
pub impl FromJson for OwnershipLink with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  OwnershipLink::OwnershipLink(@path.Path(value)) catch {
    _ => raise @json.JsonDecodeError((path, "ownership link must be absolute"))
  }
}

///|
pub impl ToJson for OwnershipLink with fn to_json(self) -> Json {
  self.path.to_string().to_json()
}

///|
pub impl FromJson for OwnershipResolvedTarget with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  OwnershipResolvedTarget::OwnershipResolvedTarget(@path.Path(value)) catch {
    _ =>
      raise @json.JsonDecodeError(
        (path, "ownership resolved target must be absolute"),
      )
  }
}

///|
pub impl ToJson for OwnershipResolvedTarget with fn to_json(self) -> Json {
  self.path.to_string().to_json()
}

///|
pub impl FromJson for OwnershipManagedRoot with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  OwnershipManagedRoot::OwnershipManagedRoot(@path.Path(value)) catch {
    _ =>
      raise @json.JsonDecodeError(
        (path, "ownership managed root must be absolute"),
      )
  }
}

///|
pub impl ToJson for OwnershipManagedRoot with fn to_json(self) -> Json {
  self.path.to_string().to_json()
}

///|
pub impl FromJson for OwnershipEntry with fn from_json(json, path) {
  let link : OwnershipLink = ownership_entry_link_lens.decode_from_json(
    json, path,
  )
  let symlink_target_value : String = ownership_entry_symlink_target_lens.decode_from_json(
    json, path,
  )
  let resolved_target : OwnershipResolvedTarget = ownership_entry_resolved_target_lens.decode_from_json(
    json, path,
  )
  let managed_root : OwnershipManagedRoot = ownership_entry_managed_root_lens.decode_from_json(
    json, path,
  )
  let source : OwnershipSource = ownership_entry_source_lens.decode_from_json(
    json, path,
  )
  OwnershipEntry::OwnershipEntry(
    link,
    @path.Path(symlink_target_value),
    resolved_target,
    managed_root,
    source,
  ) catch {
    _ =>
      raise ownership_entry_link_lens.json_decode_error(
        path, "ownership link must be a direct child of its managed root",
      )
  }
}

///|
pub impl ToJson for OwnershipEntry with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  ownership_entry_link_lens.set_or_abort(builder, ToJson::to_json(self.link))
  ownership_entry_symlink_target_lens.set_or_abort(
    builder,
    self.symlink_target.to_string().to_json(),
  )
  ownership_entry_resolved_target_lens.set_or_abort(
    builder,
    ToJson::to_json(self.resolved_target),
  )
  ownership_entry_managed_root_lens.set_or_abort(
    builder,
    ToJson::to_json(self.managed_root),
  )
  ownership_entry_source_lens.set_or_abort(
    builder,
    ToJson::to_json(self.source),
  )
  builder.to_json()
}

///|
pub impl FromJson for OwnershipState with fn from_json(json, path) {
  let version : String = @json.from_json(
    ownership_state_version_lens.get_or_json_decode_error(json, path),
    path=ownership_state_version_lens.add_to_json_path(path),
  )
  guard version == "1" else {
    raise ownership_state_version_lens.json_decode_error(
      path,
      "unsupported ownership state version: \{version}",
    )
  }
  let entries : Array[OwnershipEntry] = @json.from_json(
    ownership_state_entries_lens.get_or_json_decode_error(json, path),
    path=ownership_state_entries_lens.add_to_json_path(path),
  )
  OwnershipState::OwnershipState(entries) catch {
    _ =>
      raise ownership_state_entries_lens.json_decode_error(
        path, "ownership links must be unique",
      )
  }
}

///|
pub impl ToJson for OwnershipState with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  let stored_entries = self.entries.to_array()
  stored_entries.sort_by((left, right) => left.0.compare(right.0))
  let entries = stored_entries.map(entry => entry.1)
  ownership_state_version_lens.set_or_abort(
    builder,
    self.version.to_string().to_json(),
  )
  ownership_state_entries_lens.set_or_abort(builder, entries.to_json())
  builder.to_json()
}
