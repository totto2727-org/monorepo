///|

///|
struct LockPlugin {
  name : String
  path : String
  enabled_skills : Array[String]
}

///|
struct LockRepository {
  source_type : RepositorySourceType
  source : String
  marketplace_kind : MarketplaceKind
  commit_hash : String?
  plugins : Array[LockPlugin]
}

///|
enum RepositorySourceType {
  RepositoryLocal
  RepositoryGithub
}

///|
fn repository_source_type_from_string(
  value : String,
) -> RepositorySourceType raise {
  match value {
    "local" => RepositoryLocal
    "github" => RepositoryGithub
    _ => raise Failure::Failure("unsupported repository source type: \{value}")
  }
}

///|
fn repository_source_type_to_string(
  source_type : RepositorySourceType,
) -> String {
  match source_type {
    RepositoryLocal => "local"
    RepositoryGithub => "github"
  }
}

///|
fn parse_string_array_property(
  text : String,
  key : String,
  start : Int,
) -> Array[String] {
  let values : Array[String] = []
  match text[start:].find("\"\{key}\"") {
    Some(relative_key) => {
      let key_start = start + relative_key
      match text[key_start:].find("]") {
        Some(relative_end) => {
          let block = text[key_start:key_start + relative_end]
          let mut cursor = 0
          while cursor < block.length() {
            match block[cursor:].find("\"") {
              Some(open) => {
                let value_start = cursor + open + 1
                match block[value_start:].find("\"") {
                  Some(close) => {
                    let value = block[value_start:value_start + close].to_owned()
                    if value != key {
                      values.push(value)
                    }
                    cursor = value_start + close + 1
                    continue
                  }
                  None => break
                }
              }
              None => break
            }
          }
        }
        None => ()
      }
    }
    None => ()
  }
  values
}

///|
fn parse_plugins(text : String, start : Int, end : Int) -> Array[LockPlugin] {
  let plugins : Array[LockPlugin] = []
  let block = text[start:end].to_owned()
  let mut cursor = 0
  while cursor < block.length() {
    match block[cursor:].find("\"enabledSkills\"") {
      Some(found) => {
        let enabled_start = cursor + found
        let name = previous_quoted_value(block, "name", enabled_start).unwrap_or(
          "plugin",
        )
        let path = previous_quoted_value(block, "path", enabled_start).unwrap_or(
          name,
        )
        let enabled_skills = parse_string_array_property(
          block, "enabledSkills", enabled_start,
        )
        plugins.push({ name, path, enabled_skills })
        cursor = enabled_start + 15
        continue
      }
      None => break
    }
  }
  plugins
}

///|
struct LockFile {
  skill_dirs : Array[String]
  repositories : Array[LockRepository]
}

///|
fn empty_lock_text() -> String {
  "{\n\t\"version\": 1,\n\t\"skillDirs\": [],\n\t\"repositories\": []\n}\n"
}

///|
async fn ensure_lock(agents : String) -> Unit {
  if !@fs.exists(agents) {
    @fs.mkdir(agents, recursive=true)
  }
  let path = lock_path_from_agents(agents)
  if !@fs.exists(path) {
    @fs.write_file(path, empty_lock_text(), create_mode=CreateOrTruncate)
  }
}

///|
async fn read_lock(agents : String) -> LockFile {
  let path = lock_path_from_agents(agents)
  let text = if @fs.exists(path) {
    @fs.read_file(path).text()
  } else {
    empty_lock_text()
  }
  let skill_dirs : Array[String] = []
  match text.find("\"skillDirs\"") {
    Some(from) =>
      match text[from:].find("]") {
        Some(end) => {
          let block = text[from:from + end]
          let mut inner = 0
          while inner < block.length() {
            match block[inner:].find("\"") {
              Some(open) => {
                let value_start = inner + open + 1
                match block[value_start:].find("\"") {
                  Some(close) => {
                    let value = block[value_start:value_start + close].to_owned()
                    if value != "skillDirs" {
                      skill_dirs.push(value)
                    }
                    inner = value_start + close + 1
                    continue
                  }
                  None => break
                }
              }
              None => break
            }
          }
        }
        None => ()
      }
    None => ()
  }
  let repositories : Array[LockRepository] = []
  let mut repo_cursor = 0
  while repo_cursor < text.length() {
    match text[repo_cursor:].find("\"sourceType\"") {
      Some(found) => {
        let start = repo_cursor + found
        let source_type = repository_source_type_from_string(
          quoted_value(text, "sourceType", start).unwrap_or("local"),
        )
        let source = quoted_value(text, "source", start).unwrap_or("")
        let kind = marketplace_kind_from_string(
          quoted_value(text, "marketplaceKind", start).unwrap_or("claude"),
        )
        let commit = quoted_value(text, "commitHash", start)
        let end = match text[start + 12:].find("\"sourceType\"") {
          Some(next) => start + 12 + next
          None => text.length()
        }
        let plugins = parse_plugins(text, start, end)
        if source != "" {
          repositories.push({
            source_type,
            source,
            marketplace_kind: kind,
            commit_hash: commit,
            plugins,
          })
        }
        repo_cursor = start + 12
        continue
      }
      None => break
    }
  }
  { skill_dirs, repositories }
}

///|
fn repository_json(repo : LockRepository) -> String {
  let plugins : Array[String] = []
  for plugin in repo.plugins {
    let skills = plugin.enabled_skills
      .map(fn(skill) { "\"\{json_escape(skill)}\"" })
      .join(", ")
    plugins.push(
      "\t\t\t{ \"name\": \"\{json_escape(plugin.name)}\", \"path\": \"\{json_escape(plugin.path)}\", \"enabledSkills\": [\{skills}] }",
    )
  }
  let commit_line = match repo.commit_hash {
    Some(hash) => "\t\t\"commitHash\": \"\{json_escape(hash)}\",\n"
    None => ""
  }
  let source_type = repository_source_type_to_string(repo.source_type)
  let marketplace_kind = marketplace_kind_to_string(repo.marketplace_kind)
  "\t{\n\t\t\"sourceType\": \"\{source_type}\",\n\t\t\"source\": \"\{json_escape(repo.source)}\",\n\{commit_line}\t\t\"marketplaceKind\": \"\{marketplace_kind}\",\n\t\t\"plugins\": [\n\{plugins.join(",\n")}\n\t\t]\n\t}"
}

///|
async fn write_lock(agents : String, lock : LockFile) -> Unit {
  let repo_blocks : Array[String] = []
  for repo in lock.repositories {
    repo_blocks.push(repository_json(repo))
  }
  let dirs = lock.skill_dirs
    .map(fn(path) { "\"\{json_escape(path)}\"" })
    .join(", ")
  let text = "{\n\t\"version\": 1,\n\t\"skillDirs\": [\{dirs}],\n\t\"repositories\": [\n\{repo_blocks.join(",\n")}\n\t]\n}\n"
  @fs.write_file(
    lock_path_from_agents(agents),
    text,
    create_mode=CreateOrTruncate,
  )
}
