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
fn source_value(
  text : String,
  object_start : Int,
  kind : MarketplaceKind,
) -> String? {
  let value = match kind {
    Codex => quoted_value(text, "path", object_start)
    _ => quoted_value(text, "source", object_start)
  }
  match value {
    Some(path) if path.has_prefix("./") => Some(path[2:].to_owned())
    _ => value
  }
}

///|
fn source_key(kind : MarketplaceKind) -> String {
  match kind {
    Codex => "\"path\""
    _ => "\"source\""
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
  let mut cursor = 0
  while cursor < text.length() {
    match text[cursor:].find(source_key(kind)) {
      Some(found) => {
        let object_start = cursor + found
        let plugin_name = previous_quoted_value(text, "name", object_start).unwrap_or(
          "plugin",
        )
        let plugin_path = source_value(text, object_start, kind).unwrap_or(
          plugin_name,
        )
        validate_relative_plugin_path(plugin_path)
        let skill_dir = "\{repo_dir}/\{plugin_path}/skills"
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
              plugin_name,
              plugin_path,
              skill_name: entry,
              skill_path,
            })
          }
        }
        cursor = object_start + 8
        continue
      }
      None => break
    }
  }
  skills
}
