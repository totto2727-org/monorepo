///|
struct ResolvedSkill {
  plugin_name : String
  plugin_path : String
  skill_name : String
  skill_path : String
}

///|
struct MarketplaceInfo {
  kind : String
  path : String
}

///|
fn marketplace_path(kind : String) -> String {
  match kind {
    "cursor" => ".cursor-plugin/marketplace.json"
    "codex" => ".codex-plugin/marketplace.json"
    _ => ".claude-plugin/marketplace.json"
  }
}

///|
async fn detect_marketplace(repo_dir : String) -> MarketplaceInfo? {
  if @fs.exists("\{repo_dir}/.claude-plugin/marketplace.json") {
    Some({ kind: "claude", path: "\{repo_dir}/.claude-plugin/marketplace.json" })
  } else if @fs.exists("\{repo_dir}/.cursor-plugin/marketplace.json") {
    Some({ kind: "cursor", path: "\{repo_dir}/.cursor-plugin/marketplace.json" })
  } else if @fs.exists("\{repo_dir}/.codex-plugin/marketplace.json") {
    Some({ kind: "codex", path: "\{repo_dir}/.codex-plugin/marketplace.json" })
  } else {
    None
  }
}

///|
fn source_value(text : String, object_start : Int, kind : String) -> String? {
  if kind == "codex" {
    quoted_value(text, "path", object_start)
  } else {
    quoted_value(text, "source", object_start)
  }
}

///|
async fn resolve_skills(
  repo_dir : String,
  kind : String,
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
