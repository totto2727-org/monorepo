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
impl ToJson for LockPlugin with fn to_json(self) -> Json {
  Json::object({
    "name": self.name.to_json(),
    "path": self.path.to_json(),
    "enabledSkills": self.enabled_skills.to_json(),
  })
}

///|
impl ToJson for LockRepository with fn to_json(self) -> Json {
  let object : Map[String, Json] = Map([])
  object.set(
    "sourceType",
    repository_source_type_to_string(self.source_type).to_json(),
  )
  object.set("source", self.source.to_json())
  match self.commit_hash {
    Some(value) => object.set("commitHash", value.to_json())
    None => ()
  }
  object.set(
    "marketplaceKind",
    marketplace_kind_to_string(self.marketplace_kind).to_json(),
  )
  object.set("plugins", self.plugins.to_json())
  Json::object(object)
}

///|
impl ToJson for LockFile with fn to_json(self) -> Json {
  Json::object({
    "version": Json::number(1.0, repr="1"),
    "skillDirs": self.skill_dirs.to_json(),
    "repositories": self.repositories.to_json(),
  })
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
fn empty_lock_file() -> LockFile {
  { skill_dirs: [], repositories: [] }
}

///|
fn lock_plugin_from_json(json : Json) -> LockPlugin? {
  match json {
    Json::Object(object) => {
      let name = match object.get("name") {
        Some(Json::String(value)) => value
        _ => "plugin"
      }
      let path = match object.get("path") {
        Some(Json::String(value)) => value
        _ => name
      }
      let enabled_skills : Array[String] = []
      match object.get("enabledSkills") {
        Some(Json::Array(values)) =>
          for value in values {
            match value {
              Json::String(text) => enabled_skills.push(text)
              _ => ()
            }
          }
        _ => ()
      }
      Some({ name, path, enabled_skills })
    }
    _ => None
  }
}

///|
fn lock_plugins_from_json(json : Array[Json]) -> Array[LockPlugin] {
  let plugins : Array[LockPlugin] = []
  for value in json {
    match lock_plugin_from_json(value) {
      Some(plugin) => plugins.push(plugin)
      None => ()
    }
  }
  plugins
}

///|
fn lock_repository_from_json(json : Json) -> LockRepository? raise {
  match json {
    Json::Object(object) => {
      let source = match object.get("source") {
        Some(Json::String(value)) => value
        _ => ""
      }
      guard source != "" else { return None }
      let source_type = match object.get("sourceType") {
        Some(Json::String(value)) => value
        _ => "local"
      }
      let marketplace_kind = match object.get("marketplaceKind") {
        Some(Json::String(value)) => value
        _ => "claude"
      }
      let commit_hash = match object.get("commitHash") {
        Some(Json::String(value)) => Some(value)
        _ => None
      }
      let plugins = match object.get("plugins") {
        Some(Json::Array(values)) => lock_plugins_from_json(values)
        _ => []
      }
      Some({
        source_type: repository_source_type_from_string(source_type),
        source,
        marketplace_kind: marketplace_kind_from_string(marketplace_kind),
        commit_hash,
        plugins,
      })
    }
    _ => None
  }
}

///|
struct LockFile {
  skill_dirs : Array[String]
  repositories : Array[LockRepository]
}

///|
fn empty_lock_text() -> String {
  empty_lock_file().to_json().stringify(indent=2) + "\n"
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
  let object = match (@json.parse(text) catch { _ => Json::null() }) {
    Json::Object(object) => object
    _ => return empty_lock_file()
  }
  guard object.get("version") == Some(Json::number(1.0, repr="1")) else {
    return empty_lock_file()
  }
  let skill_dirs : Array[String] = []
  match object.get("skillDirs") {
    Some(Json::Array(values)) =>
      for value in values {
        match value {
          Json::String(text) => skill_dirs.push(text)
          _ => ()
        }
      }
    _ => ()
  }
  let repositories : Array[LockRepository] = []
  match object.get("repositories") {
    Some(Json::Array(values)) =>
      for value in values {
        match (lock_repository_from_json(value) catch { _ => None }) {
          Some(repo) => repositories.push(repo)
          None => ()
        }
      }
    _ => ()
  }
  { skill_dirs, repositories }
}

///|
async fn write_lock(agents : String, lock : LockFile) -> Unit {
  @fs.write_file(
    lock_path_from_agents(agents),
    lock.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
  )
}
