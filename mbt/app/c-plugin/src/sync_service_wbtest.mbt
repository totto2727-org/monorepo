///|
async test "sync_all links only enabled skills from lock file" {
  let root = @fs.tmpdir(prefix="c-plugin-sync-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let repo = @path.Path::join(root, "repo").to_string()
  @fs.mkdir(agents, recursive=true)
  @test_support.write_claude_marketplace(repo)
  @test_support.write_skill(repo, "skill-a")
  @test_support.write_skill(repo, "skill-b")
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
            enabled_skills: ["skill-a"],
          },
        ],
      },
    ],
  })
  sync_lock(agents, read_lock(agents))
  assert_true(
    @fs.exists(
      (agents |> @path.Path::join("skills") |> @path.Path::join("skill-a")).to_string(),
    ),
  )
  assert_false(
    @fs.exists(
      (agents |> @path.Path::join("skills") |> @path.Path::join("skill-b")).to_string(),
    ),
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "create_skill_link creates primary and additional relative symlinks" {
  let root = @fs.tmpdir(prefix="c-plugin-link-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let target = (agents
  |> @path.Path::join(".cache")
  |> @path.Path::join("owner")
  |> @path.Path::join("repo")
  |> @path.Path::join("plugins")
  |> @path.Path::join("p")
  |> @path.Path::join("skills")
  |> @path.Path::join("my-skill")).to_string()
  @fs.mkdir(target, recursive=true)
  create_skill_link(
    agents,
    [
      @path.Path::join(agents, "skills").to_string(),
      @path.Path::join(root, "extra-skills").to_string(),
    ],
    "my-skill",
    target,
  )
  assert_true(
    @fs.kind(
      (agents |> @path.Path::join("skills") |> @path.Path::join("my-skill")).to_string(),
      follow_symlink=false,
    ) ==
    @fs.FileKind::SymLink,
  )
  assert_true(
    @fs.kind(
      (root |> @path.Path::join("extra-skills") |> @path.Path::join("my-skill")).to_string(),
      follow_symlink=false,
    ) ==
    @fs.FileKind::SymLink,
  )
  @fs.rmdir(root, recursive=true)
}

///|
test "sync conflict detection finds shared target roots" {
  let shared = "/tmp/c-plugin-shared-skills"
  let empty_lock : LockFile = { skill_dirs: [], repositories: [] }
  assert_false(has_sync_conflicts([
    { agents: "/tmp/project-a/.agents", lock: empty_lock },
    { agents: "/tmp/project-b/.agents", lock: empty_lock },
  ]))
  assert_true(has_sync_conflicts([
    {
      agents: "/tmp/project-a/.agents",
      lock: { skill_dirs: [shared], repositories: [] },
    },
    {
      agents: "/tmp/project-b/.agents",
      lock: { skill_dirs: [shared], repositories: [] },
    },
  ]))
}

///|
test "update conflict detection finds shared Git repositories" {
  let repository : LockRepository = {
    source_type: RepositoryGithub,
    source: "owner/repo",
    marketplace_kind: Claude,
    commit_hash: None,
    plugins: [],
  }
  assert_true(has_update_conflicts([
    {
      agents: "/tmp/project-a/.agents",
      lock: { skill_dirs: [], repositories: [repository] },
    },
    {
      agents: "/tmp/project-b/.agents",
      lock: { skill_dirs: [], repositories: [repository] },
    },
  ]))
}

///|
async test "create_skill_link overwrites existing symlink" {
  let root = @fs.tmpdir(prefix="c-plugin-link-overwrite-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let target1 = @path.Path::join(agents, "target1").to_string()
  let target2 = @path.Path::join(agents, "target2").to_string()
  @fs.mkdir(target1, recursive=true)
  @fs.mkdir(target2, recursive=true)
  create_skill_link(agents, [], "my-skill", target1)
  create_skill_link(agents, [], "my-skill", target2)
  assert_true(
    @fs.kind(
      (agents |> @path.Path::join("skills") |> @path.Path::join("my-skill")).to_string(),
      follow_symlink=false,
    ) ==
    @fs.FileKind::SymLink,
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "clear_managed_links removes only symlinks from managed skill dirs" {
  let root = @fs.tmpdir(prefix="c-plugin-link-clear-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let extra = @path.Path::join(root, "extra-skills").to_string()
  let target = @path.Path::join(agents, "target").to_string()
  @fs.mkdir(target, recursive=true)
  create_skill_link(agents, [extra], "my-skill", target)
  @test_support.write_text(
    (agents |> @path.Path::join("skills") |> @path.Path::join("real-file")).to_string(),
    "keep",
  )
  clear_managed_links(agents, [extra])
  assert_false(
    @fs.exists(
      (agents |> @path.Path::join("skills") |> @path.Path::join("my-skill")).to_string(),
    ),
  )
  assert_false(@fs.exists(@path.Path::join(extra, "my-skill").to_string()))
  assert_true(
    @fs.exists(
      (agents |> @path.Path::join("skills") |> @path.Path::join("real-file")).to_string(),
    ),
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "sync_all keeps the last repository for duplicate skill names" {
  let root = @fs.tmpdir(prefix="c-plugin-sync-duplicate-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let first_repo = @path.Path::join(root, "repo-1").to_string()
  let second_repo = @path.Path::join(root, "repo-2").to_string()
  @fs.mkdir(agents, recursive=true)
  @async
  .all([
    () => {
      @test_support.write_claude_marketplace(first_repo)
      @test_support.write_skill(first_repo, "shared-skill")
    },
    () => {
      @test_support.write_claude_marketplace(second_repo)
      @test_support.write_skill(second_repo, "shared-skill")
    },
  ])
  |> ignore
  let plugin : LockPlugin = {
    name: "plugin-a",
    path: "plugins/plugin-a",
    enabled_skills: ["shared-skill"],
  }
  write_lock(agents, {
    skill_dirs: [],
    repositories: [
      {
        source_type: RepositoryLocal,
        source: "./repo-1",
        marketplace_kind: Claude,
        commit_hash: None,
        plugins: [plugin],
      },
      {
        source_type: RepositoryLocal,
        source: "./repo-2",
        marketplace_kind: Claude,
        commit_hash: None,
        plugins: [plugin],
      },
    ],
  })
  sync_lock(agents, read_lock(agents))
  let link = (agents
  |> @path.Path::join("skills")
  |> @path.Path::join("shared-skill")).to_string()
  let expected = (second_repo
  |> @path.Path::join("plugins")
  |> @path.Path::join("plugin-a")
  |> @path.Path::join("skills")
  |> @path.Path::join("shared-skill")).to_string()
  inspect(@fs.realpath(link), content=@fs.realpath(expected))
  @fs.rmdir(root, recursive=true)
}
