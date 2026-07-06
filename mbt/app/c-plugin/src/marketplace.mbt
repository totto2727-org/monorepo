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
    _ => raise Failure::Failure("unsupported marketplace kind: \{value}")
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
  if @fs.exists(claude) {
    Some({ kind: Claude, path: claude })
  } else if @fs.exists(cursor) {
    Some({ kind: Cursor, path: cursor })
  } else if @fs.exists(codex) {
    Some({ kind: Codex, path: codex })
  } else {
    None
  }
}

///|
pub async fn has_supported_plugin_format(dir : String) -> Bool {
  has_supported_plugin_format_from(dir, marketplace_kinds(), 0)
}

///|
async fn has_supported_plugin_format_from(
  dir : String,
  kinds : Array[MarketplaceKind],
  index : Int,
) -> Bool {
  if index >= kinds.length() {
    return false
  }
  if @fs.exists(
      @path.Path::join(dir, marketplace_config_dir(kinds[index])).to_string(),
    ) {
    true
  } else {
    has_supported_plugin_format_from(dir, kinds, index + 1)
  }
}

///|
fn normalize_plugin_source(value : String?) -> String? {
  match value {
    Some(path) if path.has_prefix("./") => Some(path[2:].to_owned())
    _ => value
  }
}

///|
fn plugin_source_from_json(
  plugin : Map[String, Json],
  kind : MarketplaceKind,
) -> String? {
  match kind {
    Codex =>
      match plugin.get("source") {
        Some(Json::Object(source)) =>
          normalize_plugin_source(
            match source.get("path") {
              Some(Json::String(value)) => Some(value)
              _ => None
            },
          )
        None => None
        _ => None
      }
    _ =>
      normalize_plugin_source(
        match plugin.get("source") {
          Some(Json::String(value)) => Some(value)
          _ => None
        },
      )
  }
}

///|
fn normalized_plugins_from_json(
  text : String,
  kind : MarketplaceKind,
) -> Array[NormalizedPlugin] {
  let object = match (@json.parse(text) catch { _ => Json::null() }) {
    Json::Object(object) => object
    _ => Map([])
  }
  match object.get("plugins") {
    Some(Json::Array(values)) =>
      values
      .iter()
      .fold(init=[], fn(plugins, value) {
        match value {
          Json::Object(plugin) =>
            match normalized_plugin_from_json(plugin, kind) {
              Some(plugin) => plugins.iter().concat([plugin].iter()).collect()
              None => plugins
            }
          _ => plugins
        }
      })
    _ => []
  }
}

///|
fn normalized_plugin_from_json(
  plugin : Map[String, Json],
  kind : MarketplaceKind,
) -> NormalizedPlugin? {
  let name = match plugin.get("name") {
    Some(Json::String(value)) => value
    _ => "plugin"
  }
  let source = plugin_source_from_json(plugin, kind).unwrap_or(name)
  if is_relative_plugin_path(source) {
    Some({
      name,
      source,
      description: match plugin.get("description") {
        Some(Json::String(value)) => Some(value)
        _ => None
      },
    })
  } else {
    None
  }
}

///|
fn marketplace_name_from_json(text : String) -> String {
  match (@json.parse(text) catch { _ => Json::null() }) {
    Json::Object(object) =>
      match object.get("name") {
        Some(Json::String(value)) => value
        _ => "marketplace"
      }
    _ => "marketplace"
  }
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
    0,
  )
}

///|
async fn resolve_skills_from_plugins(
  repo_dir : String,
  plugins : Array[NormalizedPlugin],
  index : Int,
) -> Array[ResolvedSkill] {
  if index >= plugins.length() {
    return []
  }
  let plugin = plugins[index]
  let current = resolve_plugin_skills(repo_dir, plugin)
  let rest = resolve_skills_from_plugins(repo_dir, plugins, index + 1)
  current.iter().concat(rest.iter()).collect()
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
  resolve_skill_entries(plugin, skill_dir, entries, 0)
}

///|
async fn resolve_skill_entries(
  plugin : NormalizedPlugin,
  skill_dir : String,
  entries : Array[String],
  index : Int,
) -> Array[ResolvedSkill] {
  if index >= entries.length() {
    return []
  }
  let entry = entries[index]
  let skill_path = @path.Path::join(skill_dir, entry).to_string()
  let current = if @fs.exists(
      @path.Path::join(skill_path, "SKILL.md").to_string(),
    ) {
    [
      {
        plugin_name: plugin.name,
        plugin_path: plugin.source,
        skill_name: entry,
        skill_path,
      },
    ]
  } else {
    []
  }
  let rest = resolve_skill_entries(plugin, skill_dir, entries, index + 1)
  current.iter().concat(rest.iter()).collect()
}
