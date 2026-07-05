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
  sync_all(agents)
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
    [@path.Path::join(root, "extra-skills").to_string()],
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
