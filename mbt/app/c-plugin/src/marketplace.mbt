///|
struct ResolvedSkill {
  plugin_name : String
  plugin_path : String
  skill_name : String
  skill_path : String
}

///|
struct NormalizedPlugin {
  name : String
  source : String
  description : String?
}

///|
fn plugins_from_skills(skills : Array[ResolvedSkill]) -> Array[LockPlugin] {
  skills
  .iter()
  .fold(init=[], fn(plugins, skill) { upsert_plugin_skill(plugins, skill) })
}

///|
fn append_enabled_skill(plugin : LockPlugin, skill_name : String) -> LockPlugin {
  if plugin.enabled_skills.contains(skill_name) {
    plugin
  } else {
    {
      name: plugin.name,
      path: plugin.path,
      enabled_skills: plugin.enabled_skills
      .iter()
      .concat([skill_name].iter())
      .collect(),
    }
  }
}

///|
fn upsert_plugin_skill(
  plugins : Array[LockPlugin],
  skill : ResolvedSkill,
) -> Array[LockPlugin] {
  let updated = plugins.map(fn(plugin) {
    if plugin.name == skill.plugin_name {
      append_enabled_skill(plugin, skill.skill_name)
    } else {
      plugin
    }
  })
  if plugins.any(fn(plugin) { plugin.name == skill.plugin_name }) {
    updated
  } else {
    updated
    .iter()
    .concat(
      [
        {
          name: skill.plugin_name,
          path: skill.plugin_path,
          enabled_skills: [skill.skill_name],
        },
      ].iter(),
    )
    .collect()
  }
}

///|
fn merge_plugins(
  existing : Array[LockPlugin],
  incoming : Array[LockPlugin],
) -> Array[LockPlugin] {
  incoming.iter().fold(init=existing, merge_plugin)
}

///|
fn merge_plugin(
  plugins : Array[LockPlugin],
  incoming : LockPlugin,
) -> Array[LockPlugin] {
  let updated = plugins.map(fn(plugin) {
    if plugin.name == incoming.name {
      incoming.enabled_skills.iter().fold(init=plugin, append_enabled_skill)
    } else {
      plugin
    }
  })
  if plugins.any(fn(plugin) { plugin.name == incoming.name }) {
    updated
  } else {
    updated.iter().concat([incoming].iter()).collect()
  }
}

///|
enum MarketplaceKind {
  Claude
  Cursor
  Codex
} derive(Eq)

///|
struct MarketplaceInfo {
  kind : MarketplaceKind
  path : String
}

///|
fn marketplace_kind_from_string(value : String) -> MarketplaceKind raise {
  match value {
    "claude" => Claude
    "cursor" => Cursor
    "codex" => Codex
    _ => fail("unsupported marketplace kind: \{value}")
  }
}

///|
fn marketplace_kind_to_string(kind : MarketplaceKind) -> String {
  match kind {
    Claude => "claude"
    Cursor => "cursor"
    Codex => "codex"
  }
}

///|
fn marketplace_kinds() -> Array[MarketplaceKind] {
  [Claude, Cursor, Codex]
}

///|
fn marketplace_path(kind : MarketplaceKind) -> String {
  match kind {
    Claude => @path.Path::join(".claude-plugin", "marketplace.json").to_string()
    Cursor => @path.Path::join(".cursor-plugin", "marketplace.json").to_string()
    Codex =>
      (".agents"
      |> @path.Path::join("plugins")
      |> @path.Path::join("marketplace.json")).to_string()
  }
}

///|
fn marketplace_config_dir(kind : MarketplaceKind) -> String {
  match kind {
    Claude => ".claude-plugin"
    Cursor => ".cursor-plugin"
    Codex => ".codex-plugin"
  }
}

///|
async fn detect_marketplace(repo_dir : String) -> MarketplaceInfo? {
  let claude = @path.Path::join(repo_dir, marketplace_path(Claude)).to_string()
  let cursor = @path.Path::join(repo_dir, marketplace_path(Cursor)).to_string()
  let codex = @path.Path::join(repo_dir, marketplace_path(Codex)).to_string()
  match
    @async.all([
      () => @fs.exists(claude),
      () => @fs.exists(cursor),
      () => @fs.exists(codex),
    ]) {
    [true, _, _] => Some({ kind: Claude, path: claude })
    [false, true, _] => Some({ kind: Cursor, path: cursor })
    [false, false, true] => Some({ kind: Codex, path: codex })
    _ => None
  }
}

///|
pub async fn has_supported_plugin_format(dir : String) -> Bool {
  @async.all(
    marketplace_kinds().map(kind => {
      () => {
        @fs.exists(
          @path.Path::join(dir, marketplace_config_dir(kind)).to_string(),
        )
      }
    }),
  ).any(value => value)
}

///|
fn normalize_plugin_source(value : String?) -> String? {
  match value {
    Some(path) if path.has_prefix("./") => Some(path[2:].to_owned())
    _ => value
  }
}

///|
struct MarketplaceSourceWire {
  wire_string : String?
  wire_path : String?
}

///|
impl FromJson for MarketplaceSourceWire with fn from_json(json, _path) {
  match json {
    Json::String(value) => { wire_string: Some(value), wire_path: None }
    _ => {
      let wire_path = match optional_json_field(json, "path") {
        Some(value) =>
          Some((@json.from_json(value) : String)) catch {
            _ => None
          }
        None => None
      }
      { wire_string: None, wire_path }
    }
  }
}

///|
struct MarketplacePluginWire {
  wire_name : String?
  wire_source : MarketplaceSourceWire?
  wire_description : String?
}

///|
impl FromJson for MarketplacePluginWire with fn from_json(json, path) {
  require_object(json, path, "MarketplacePluginWire: expected object")
  let wire_name = match optional_json_field(json, "name") {
    Some(value) => Some((@json.from_json(value) : String)) catch { _ => None }
    None => None
  }
  let wire_source = match optional_json_field(json, "source") {
    Some(value) =>
      Some((@json.from_json(value) : MarketplaceSourceWire)) catch {
        _ => None
      }
    None => None
  }
  let wire_description = match optional_json_field(json, "description") {
    Some(value) => Some((@json.from_json(value) : String)) catch { _ => None }
    None => None
  }
  { wire_name, wire_source, wire_description }
}

///|
struct MarketplaceWire {
  wire_name : String?
  wire_plugins : Array[MarketplacePluginWire]?
}

///|
impl FromJson for MarketplaceWire with fn from_json(json, _path) {
  let wire_name = match optional_json_field(json, "name") {
    Some(value) => Some((@json.from_json(value) : String)) catch { _ => None }
    None => None
  }
  let wire_plugins = match optional_json_field(json, "plugins") {
    Some(Json::Array(values)) =>
      Some(
        values
        .iter()
        .filter_map(value => {
          Some((@json.from_json(value) : MarketplacePluginWire)) catch {
            _ => None
          }
        })
        .collect(),
      )
    _ => None
  }
  { wire_name, wire_plugins }
}

///|
fn plugin_source_from_wire(
  plugin : MarketplacePluginWire,
  kind : MarketplaceKind,
) -> String? {
  let source = match (kind, plugin.wire_source) {
    (Codex, Some(source)) => source.wire_path
    (Codex, None) => None
    (_, Some(source)) => source.wire_string
    (_, None) => None
  }
  normalize_plugin_source(source)
}

///|
fn normalized_plugins_from_json(
  text : String,
  kind : MarketplaceKind,
) -> Array[NormalizedPlugin] {
  let document = @json.parse(text) catch { _ => return [] }
  let marketplace : MarketplaceWire = @json.from_json(document) catch {
    _ => return []
  }
  match marketplace.wire_plugins {
    Some(plugins) =>
      plugins
      .iter()
      .filter_map(plugin => normalized_plugin_from_wire(plugin, kind))
      .collect()
    None => []
  }
}

///|
fn normalized_plugin_from_wire(
  plugin : MarketplacePluginWire,
  kind : MarketplaceKind,
) -> NormalizedPlugin? {
  let name = plugin.wire_name.unwrap_or("plugin")
  let source = plugin_source_from_wire(plugin, kind).unwrap_or(name)
  if is_relative_plugin_path(source) {
    Some({ name, source, description: plugin.wire_description })
  } else {
    None
  }
}

///|
fn marketplace_name_from_json(text : String) -> String {
  let document = @json.parse(text) catch { _ => return "marketplace" }
  let marketplace : MarketplaceWire = @json.from_json(document) catch {
    _ => return "marketplace"
  }
  marketplace.wire_name.unwrap_or("marketplace")
}

///|
async fn resolve_skills(
  repo_dir : String,
  kind : MarketplaceKind,
) -> Array[ResolvedSkill] {
  let path = @path.Path::join(repo_dir, marketplace_path(kind)).to_string()
  let text = @fs.read_file(path).text()
  resolve_skills_from_plugins(
    repo_dir,
    normalized_plugins_from_json(text, kind),
  )
}

///|
async fn resolve_skills_from_plugins(
  repo_dir : String,
  plugins : Array[NormalizedPlugin],
) -> Array[ResolvedSkill] {
  @async.all(
    plugins.map(plugin => () => resolve_plugin_skills(repo_dir, plugin)),
  )
  .iter()
  .flat_map(skills => skills.iter())
  .collect()
}

///|
async fn resolve_plugin_skills(
  repo_dir : String,
  plugin : NormalizedPlugin,
) -> Array[ResolvedSkill] {
  let skill_dir = (repo_dir
  |> @path.Path::join(plugin.source)
  |> @path.Path::join("skills")).to_string()
  let entries = @fs.readdir(
    skill_dir,
    include_hidden=false,
    include_special=false,
    sort=true,
  ) catch {
    _ => []
  }
  resolve_skill_entries(plugin, skill_dir, entries)
}

///|
async fn resolve_skill_entries(
  plugin : NormalizedPlugin,
  skill_dir : String,
  entries : Array[String],
) -> Array[ResolvedSkill] {
  @async.all(
    entries.map(entry => {
      () => {
        let skill_path = @path.Path::join(skill_dir, entry).to_string()
        if @fs.exists(@path.Path::join(skill_path, "SKILL.md").to_string()) {
          Some({
            plugin_name: plugin.name,
            plugin_path: plugin.source,
            skill_name: entry,
            skill_path,
          })
        } else {
          None
        }
      }
    }),
  )
  .iter()
  .filter_map(skill => skill)
  .collect()
}
