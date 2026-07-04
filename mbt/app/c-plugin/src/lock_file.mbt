///|
struct LockRepository {
  source_type : RepositorySourceType
  source : String
  marketplace_kind : MarketplaceKind
  commit_hash : String?
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
    _ => fail("unsupported repository source type: \{value}")
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
        if source != "" {
          repositories.push({
            source_type,
            source,
            marketplace_kind: kind,
            commit_hash: commit,
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
fn repository_json(
  repo : LockRepository,
  skills : Array[ResolvedSkill],
) -> String {
  let plugins : Array[String] = []
  for skill in skills {
    plugins.push(
      "\t\t\t{ \"name\": \"\{json_escape(skill.plugin_name)}\", \"path\": \"\{json_escape(skill.plugin_path)}\", \"enabledSkills\": [\"\{json_escape(skill.skill_name)}\"] }",
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
    let repo_dir = repo_dir_for(lock_path_from_agents(agents), repo)
    let skills = resolve_skills(repo_dir, repo.marketplace_kind) catch {
      _ => []
    }
    repo_blocks.push(repository_json(repo, skills))
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
