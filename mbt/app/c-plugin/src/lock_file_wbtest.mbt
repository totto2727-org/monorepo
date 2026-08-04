///|
async test "lock file preserves plugin enabledSkills" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-")
  let agents = @path.Path::join(root, ".agents").to_string()
  @fs.mkdir(agents, recursive=true)
  write_lock(agents, {
    skill_dirs: [],
    repositories: [
      {
        source_type: RepositoryLocal,
        source: "./repo",
        marketplace_kind: Claude,
        commit_hash: None,
        plugins: [
          {
            name: "plugin-a",
            path: "plugins/plugin-a",
            enabled_skills: ["skill-a", "skill-b"],
          },
        ],
      },
    ],
  })
  let lock = read_lock(agents)
  inspect(lock.repositories.length(), content="1")
  inspect(lock.repositories[0].plugins.length(), content="1")
  inspect(
    lock.repositories[0].plugins[0].enabled_skills.join(","),
    content="skill-a,skill-b",
  )
  @fs.rmdir(root, recursive=true)
}

///|
test "LockFile ToJson roundtrips through standard FromJson" {
  let expected : LockFile = {
    skill_dirs: ["/custom/dir"],
    repositories: [
      {
        source_type: RepositoryGithub,
        source: "test/repo",
        marketplace_kind: Codex,
        commit_hash: Some("def456"),
        plugins: [
          {
            name: "test-plugin",
            path: "plugins/test-plugin",
            enabled_skills: ["skill-x", "skill-y"],
          },
        ],
      },
    ],
  }
  let actual : LockFile = @json.from_json(expected.to_json())
  inspect(actual.skill_dirs.join(","), content="/custom/dir")
  inspect(actual.repositories.length(), content="1")
  inspect(
    repository_source_type_to_string(actual.repositories[0].source_type),
    content="github",
  )
  inspect(actual.repositories[0].source, content="test/repo")
  inspect(
    marketplace_kind_to_string(actual.repositories[0].marketplace_kind),
    content="codex",
  )
  inspect(actual.repositories[0].commit_hash.unwrap_or(""), content="def456")
  inspect(actual.repositories[0].plugins.length(), content="1")
  inspect(actual.repositories[0].plugins[0].name, content="test-plugin")
  inspect(actual.repositories[0].plugins[0].path, content="plugins/test-plugin")
  inspect(
    actual.repositories[0].plugins[0].enabled_skills.join(","),
    content="skill-x,skill-y",
  )
}

///|
async test "read_lock returns empty lock file when file does not exist" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-missing-")
  let agents = @path.Path::join(root, ".agents").to_string()
  @fs.mkdir(agents, recursive=true)
  let lock = read_lock(agents)
  inspect(lock.skill_dirs.length(), content="0")
  inspect(lock.repositories.length(), content="0")
  @fs.rmdir(root, recursive=true)
}

///|
async fn run_sync_with_lock_text(lock_text : String) -> (String, String) {
  let root = @fs.tmpdir(prefix="c-plugin-lock-corrupt-")
  let agents = @path.Path::join(root, ".agents").to_string()
  @fs.mkdir(agents, recursive=true)
  let lock_path = lock_path_from_agents(agents)
  @test_support.write_text(lock_path, lock_text)
  let previous_pwd = @env.get_env_var("PWD")
  let previous_home = @env.get_env_var("HOME")
  @env.set_env_var("PWD", root)
  @env.set_env_var("HOME", root)
  let outcome = try {
    run_skill_sync(@admiral.Context())
    "returned"
  } catch {
    _ => "raised"
  }
  let contents = @fs.read_file(lock_path).text()
  match previous_pwd {
    Some(old) => @env.set_env_var("PWD", old)
    None => @env.unset_env_var("PWD")
  }
  match previous_home {
    Some(old) => @env.set_env_var("HOME", old)
    None => @env.unset_env_var("HOME")
  }
  @fs.rmdir(root, recursive=true)
  (outcome, contents)
}

///|
async test "run_skill_sync - rejects and preserves a corrupt lock file" {
  let corrupt = "{ invalid json }}}"
  let (outcome, contents) = run_sync_with_lock_text(corrupt)
  inspect(outcome, content="raised")
  inspect(contents, content=corrupt)
}

///|
test "LockFile FromJson - defaults absent optional fields" {
  let lock : LockFile = @json.from_json(
    @json.parse(
      (
        #|{
        #|  "version": 1,
        #|  "repositories": [
        #|    { "source": "./repo", "plugins": [{}] }
        #|  ]
        #|}
      ),
    ),
  )
  inspect(lock.skill_dirs.join(","), content="")
  inspect(lock.repositories.length(), content="1")
  inspect(
    repository_source_type_to_string(lock.repositories[0].source_type),
    content="local",
  )
  inspect(lock.repositories[0].plugins.length(), content="1")
  inspect(lock.repositories[0].plugins[0].name, content="plugin")
  inspect(lock.repositories[0].plugins[0].path, content="plugin")
  debug_inspect(lock.repositories[0].plugins[0].enabled_skills, content="[]")
}

///|
async test "run_skill_sync - rejects and preserves malformed skillDirs" {
  let malformed =
    #|{"version":1,"skillDirs":["/custom/dir",1],"repositories":[]}
  let (outcome, contents) = run_sync_with_lock_text(malformed)
  inspect(outcome, content="raised")
  inspect(contents, content=malformed)
}

///|
async test "run_skill_sync - rejects and preserves malformed repositories" {
  let malformed =
    #|{"version":1,"skillDirs":[],"repositories":[42]}
  let (outcome, contents) = run_sync_with_lock_text(malformed)
  inspect(outcome, content="raised")
  inspect(contents, content=malformed)
}

///|
async test "run_skill_sync - rejects and preserves malformed nested plugins" {
  let malformed =
    #|{"version":1,"skillDirs":[],"repositories":[{"source":"./repo","plugins":[{"name":"plugin-a","enabledSkills":["skill-a",1]}]}]}
  let (outcome, contents) = run_sync_with_lock_text(malformed)
  inspect(outcome, content="raised")
  inspect(contents, content=malformed)
}

///|
async test "run_skill_sync - rejects and preserves unsafe enabled skill names" {
  for
    skill_name in ["", ".", "..", "../../victim", "/tmp/victim", "dir\\victim"] {
    let encoded_skill_name = skill_name.to_json().stringify()
    let malformed = "{\"version\":1,\"skillDirs\":[],\"repositories\":[{\"source\":\"./repo\",\"plugins\":[{\"name\":\"plugin-a\",\"enabledSkills\":[\{encoded_skill_name}]}]}]}"
    let (outcome, contents) = run_sync_with_lock_text(malformed)
    inspect(outcome, content="raised")
    inspect(contents, content=malformed)
  }
}

///|
async test "write_lock creates parent directory and roundtrips github repository" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-roundtrip-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let expected : LockFile = {
    skill_dirs: ["/custom/dir"],
    repositories: [
      {
        source_type: RepositoryGithub,
        source: "test/repo",
        marketplace_kind: Claude,
        commit_hash: Some("def456"),
        plugins: [
          {
            name: "test-plugin",
            path: "plugins/test-plugin",
            enabled_skills: ["skill-x", "skill-y"],
          },
        ],
      },
    ],
  }
  write_lock(agents, expected)
  let lock = read_lock(agents)
  inspect(lock.skill_dirs.join(","), content="/custom/dir")
  inspect(lock.repositories.length(), content="1")
  inspect(
    repository_source_type_to_string(lock.repositories[0].source_type),
    content="github",
  )
  inspect(lock.repositories[0].source, content="test/repo")
  inspect(lock.repositories[0].commit_hash.unwrap_or(""), content="def456")
  inspect(
    lock.repositories[0].plugins[0].enabled_skills.join(","),
    content="skill-x,skill-y",
  )
  @fs.rmdir(root, recursive=true)
}
