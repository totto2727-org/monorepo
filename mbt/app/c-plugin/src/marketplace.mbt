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
  let plugins : Array[LockPlugin] = []
  for skill in skills {
    let mut found = false
    for index, plugin in plugins {
      if plugin.name == skill.plugin_name {
        if !plugin.enabled_skills.contains(skill.skill_name) {
          plugin.enabled_skills.push(skill.skill_name)
        }
        plugins[index] = plugin
        found = true
      }
    }
    if !found {
      plugins.push({
        name: skill.plugin_name,
        path: skill.plugin_path,
        enabled_skills: [skill.skill_name],
      })
    }
  }
  plugins
}

///|
fn merge_plugins(
  existing : Array[LockPlugin],
  incoming : Array[LockPlugin],
) -> Array[LockPlugin] {
  let merged = existing.copy()
  for plugin in incoming {
    let mut found = false
    for index, current in merged {
      if current.name == plugin.name {
        for skill in plugin.enabled_skills {
          if !current.enabled_skills.contains(skill) {
            current.enabled_skills.push(skill)
          }
        }
        merged[index] = current
        found = true
      }
    }
    if !found {
      merged.push(plugin)
    }
  }
  merged
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
    Claude => ".claude-plugin/marketplace.json"
    Cursor => ".cursor-plugin/marketplace.json"
    Codex => ".agents/plugins/marketplace.json"
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
  if @fs.exists("\{repo_dir}/.claude-plugin/marketplace.json") {
    Some({ kind: Claude, path: "\{repo_dir}/.claude-plugin/marketplace.json" })
  } else if @fs.exists("\{repo_dir}/.cursor-plugin/marketplace.json") {
    Some({ kind: Cursor, path: "\{repo_dir}/.cursor-plugin/marketplace.json" })
  } else if @fs.exists("\{repo_dir}/.agents/plugins/marketplace.json") {
    Some({ kind: Codex, path: "\{repo_dir}/.agents/plugins/marketplace.json" })
  } else {
    None
  }
}

///|
pub async fn has_supported_plugin_format(dir : String) -> Bool {
  for kind in marketplace_kinds() {
    if @fs.exists("\{dir}/\{marketplace_config_dir(kind)}") {
      return true
    }
  }
  false
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
  let plugins : Array[NormalizedPlugin] = []
  match object.get("plugins") {
    Some(Json::Array(values)) =>
      for value in values {
        match value {
          Json::Object(plugin) => {
            let name = match plugin.get("name") {
              Some(Json::String(value)) => value
              _ => "plugin"
            }
            let source = plugin_source_from_json(plugin, kind).unwrap_or(name)
            if is_relative_plugin_path(source) {
              plugins.push({
                name,
                source,
                description: match plugin.get("description") {
                  Some(Json::String(value)) => Some(value)
                  _ => None
                },
              })
            }
          }
          _ => ()
        }
      }
    _ => ()
  }
  plugins
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
  let path = "\{repo_dir}/\{marketplace_path(kind)}"
  let text = @fs.read_file(path).text()
  let skills : Array[ResolvedSkill] = []
  for plugin in normalized_plugins_from_json(text, kind) {
    let skill_dir = "\{repo_dir}/\{plugin.source}/skills"
    let entries = @fs.readdir(
      skill_dir,
      include_hidden=false,
      include_special=false,
      sort=true,
    ) catch {
      _ => []
    }
    for entry in entries {
      let skill_path = "\{skill_dir}/\{entry}"
      if @fs.exists("\{skill_path}/SKILL.md") {
        skills.push({
          plugin_name: plugin.name,
          plugin_path: plugin.source,
          skill_name: entry,
          skill_path,
        })
      }
    }
  }
  skills
}
