///|
struct ResolvedSkill {
  plugin_name : String
  plugin_path : String
  skill_name : String
  skill_path : String
}

///|
enum MarketplaceKind {
  Claude
  Cursor
  Codex
}

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
fn same_marketplace_kind(
  left : MarketplaceKind,
  right : MarketplaceKind,
) -> Bool {
  match (left, right) {
    (Claude, Claude) => true
    (Cursor, Cursor) => true
    (Codex, Codex) => true
    _ => false
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
    Codex => ".codex-plugin/marketplace.json"
  }
}

///|
async fn detect_marketplace(repo_dir : String) -> MarketplaceInfo? {
  if @fs.exists("\{repo_dir}/.claude-plugin/marketplace.json") {
    Some({ kind: Claude, path: "\{repo_dir}/.claude-plugin/marketplace.json" })
  } else if @fs.exists("\{repo_dir}/.cursor-plugin/marketplace.json") {
    Some({ kind: Cursor, path: "\{repo_dir}/.cursor-plugin/marketplace.json" })
  } else if @fs.exists("\{repo_dir}/.codex-plugin/marketplace.json") {
    Some({ kind: Codex, path: "\{repo_dir}/.codex-plugin/marketplace.json" })
  } else {
    None
  }
}

///|
fn source_value(
  text : String,
  object_start : Int,
  kind : MarketplaceKind,
) -> String? {
  match kind {
    Codex => quoted_value(text, "path", object_start)
    _ => quoted_value(text, "source", object_start)
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
    match text[cursor:].find("\"source\"") {
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
