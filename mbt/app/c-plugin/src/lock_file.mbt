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
  put_json_if_some(
    object,
    "commitHash",
    match self.commit_hash {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
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
      let name = json_string(object, "name").unwrap_or("plugin")
      let path = json_string(object, "path").unwrap_or(name)
      Some({
        name,
        path,
        enabled_skills: json_string_array(object, "enabledSkills"),
      })
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
      let source = json_string(object, "source").unwrap_or("")
      guard source != "" else { return None }
      Some({
        source_type: repository_source_type_from_string(
          json_string(object, "sourceType").unwrap_or("local"),
        ),
        source,
        marketplace_kind: marketplace_kind_from_string(
          json_string(object, "marketplaceKind").unwrap_or("claude"),
        ),
        commit_hash: json_string(object, "commitHash"),
        plugins: lock_plugins_from_json(json_array(object, "plugins")),
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
  json_document_text(empty_lock_file().to_json())
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
  let object = match parse_json_object(text) {
    Some(object) => object
    None => return empty_lock_file()
  }
  guard object.get("version") == Some(Json::number(1.0, repr="1")) else {
    return empty_lock_file()
  }
  let skill_dirs = json_string_array(object, "skillDirs")
  let repositories : Array[LockRepository] = []
  for value in json_array(object, "repositories") {
    match (lock_repository_from_json(value) catch { _ => None }) {
      Some(repo) => repositories.push(repo)
      None => ()
    }
  }
  { skill_dirs, repositories }
}

///|
async fn write_lock(agents : String, lock : LockFile) -> Unit {
  @fs.write_file(
    lock_path_from_agents(agents),
    json_document_text(lock.to_json()),
    create_mode=CreateOrTruncate,
  )
}
