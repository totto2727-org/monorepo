///|
async test "lock file preserves plugin enabledSkills" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-")
  let agents = @test_support.join_path(root, ".agents")
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
async test "read_lock returns empty lock file when file does not exist" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-missing-")
  let agents = @test_support.join_path(root, ".agents")
  @fs.mkdir(agents, recursive=true)
  let lock = read_lock(agents)
  inspect(lock.skill_dirs.length(), content="0")
  inspect(lock.repositories.length(), content="0")
  @fs.rmdir(root, recursive=true)
}

///|
async test "read_lock returns empty lock file for corrupt JSON" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-corrupt-")
  let agents = @test_support.join_path(root, ".agents")
  @fs.mkdir(agents, recursive=true)
  @test_support.write_text(lock_path_from_agents(agents), "{ invalid json }}}")
  let lock = read_lock(agents)
  inspect(lock.skill_dirs.length(), content="0")
  inspect(lock.repositories.length(), content="0")
  @fs.rmdir(root, recursive=true)
}

///|
async test "write_lock creates parent directory and roundtrips github repository" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-roundtrip-")
  let agents = @test_support.join_path(root, ".agents")
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
