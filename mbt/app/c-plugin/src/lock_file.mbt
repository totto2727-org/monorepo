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
impl FromJson for RepositorySourceType with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  match value {
    "local" => RepositoryLocal
    "github" => RepositoryGithub
    _ =>
      raise @json.JsonDecodeError(
        (path, "unsupported repository source type: \{value}"),
      )
  }
}

///|
impl FromJson for MarketplaceKind with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  match value {
    "claude" => Claude
    "cursor" => Cursor
    "codex" => Codex
    _ =>
      raise @json.JsonDecodeError(
        (path, "unsupported marketplace kind: \{value}"),
      )
  }
}

///|
impl FromJson for LockPlugin with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "expected lock plugin object"))
  }
  let root = @lens.root()
  let name_value = root.json("name").optional().get(json) catch { _ => None }
  let name = match name_value {
    Some(value) => @json.from_json(value) catch { _ => "plugin" }
    None => "plugin"
  }
  let path_value = root.json("path").optional().get(json) catch { _ => None }
  let path = match path_value {
    Some(value) => @json.from_json(value) catch { _ => name }
    None => name
  }
  let enabled_skills_value = root.json("enabledSkills").optional().get(json) catch {
      _ => None
    }
  let enabled_skills = match enabled_skills_value {
    Some(Json::Array(values)) =>
      values
      .iter()
      .filter_map(fn(value) {
        Some((@json.from_json(value) : String)) catch {
          _ => None
        }
      })
      .collect()
    _ => []
  }
  { name, path, enabled_skills }
}

///|
impl FromJson for LockRepository with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "expected lock repository object"))
  }
  let root = @lens.root()
  let source_value = root.json("source").optional().get(json) catch {
      _ => None
    }
  let source = match source_value {
    Some(value) => @json.from_json(value) catch { _ => "" }
    None => ""
  }
  guard source != "" else {
    raise @json.JsonDecodeError((path, "lock repository source is required"))
  }
  let source_type_value = root.json("sourceType").optional().get(json) catch {
      _ => None
    }
  let source_type = match source_type_value {
    Some(value) =>
      match value {
        Json::String(_) =>
          @json.from_json(value, path=path.add_key("sourceType"))
        _ => RepositoryLocal
      }
    None => RepositoryLocal
  }
  let marketplace_kind_value = root.json("marketplaceKind").optional().get(json) catch {
      _ => None
    }
  let marketplace_kind = match marketplace_kind_value {
    Some(value) =>
      match value {
        Json::String(_) =>
          @json.from_json(value, path=path.add_key("marketplaceKind"))
        _ => Claude
      }
    None => Claude
  }
  let commit_hash_value = root.json("commitHash").optional().get(json) catch {
      _ => None
    }
  let commit_hash = match commit_hash_value {
    Some(value) => Some((@json.from_json(value) : String)) catch { _ => None }
    None => None
  }
  let plugins_value = root.json("plugins").optional().get(json) catch {
      _ => None
    }
  let plugins = match plugins_value {
    Some(Json::Array(values)) =>
      values
      .iter()
      .filter_map(fn(value) {
        Some((@json.from_json(value) : LockPlugin)) catch {
          _ => None
        }
      })
      .collect()
    _ => []
  }
  { source_type, source, marketplace_kind, commit_hash, plugins }
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
extend LockFile with ToJson::{to_json}

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
struct LockFile {
  skill_dirs : Array[String]
  repositories : Array[LockRepository]
}

///|
impl FromJson for LockFile with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "expected lock file object"))
  }
  let root = @lens.root()
  let version_value = root.json("version").optional().get(json) catch {
      _ => None
    }
  let version = match version_value {
    Some(Json::Number(value, ..)) => value
    _ => 0.0
  }
  guard version == 1.0 else {
    raise @json.JsonDecodeError((path, "unsupported lock file version"))
  }
  let skill_dirs_value = root.json("skillDirs").optional().get(json) catch {
      _ => None
    }
  let skill_dirs = match skill_dirs_value {
    Some(Json::Array(values)) =>
      values
      .iter()
      .filter_map(fn(value) {
        Some((@json.from_json(value) : String)) catch {
          _ => None
        }
      })
      .collect()
    _ => []
  }
  let repositories_value = root.json("repositories").optional().get(json) catch {
      _ => None
    }
  let repositories = match repositories_value {
    Some(Json::Array(values)) =>
      values
      .iter()
      .filter_map(fn(value) {
        Some((@json.from_json(value) : LockRepository)) catch {
          _ => None
        }
      })
      .collect()
    _ => []
  }
  { skill_dirs, repositories }
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
  let document = @json.parse(text) catch { _ => return empty_lock_file() }
  (@json.from_json(document) : LockFile) catch {
    _ => empty_lock_file()
  }
}

///|
async fn write_lock(agents : String, lock : LockFile) -> Unit {
  @fs.write_file(
    lock_path_from_agents(agents),
    lock.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
  )
}
