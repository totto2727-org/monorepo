///|
async test "sync_all links only enabled skills from lock file" {
  let root = @fs.tmpdir(prefix="c-plugin-sync-")
  let agents = @test_support.join_path(root, ".agents")
  let repo = @test_support.join_path(root, "repo")
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
  assert_true(@fs.exists(@test_support.join_path(agents, "skills/skill-a")))
  assert_false(@fs.exists(@test_support.join_path(agents, "skills/skill-b")))
  @fs.rmdir(root, recursive=true)
}

///|
async test "create_skill_link creates primary and additional relative symlinks" {
  let root = @fs.tmpdir(prefix="c-plugin-link-")
  let agents = @test_support.join_path(root, ".agents")
  let target = @test_support.join_path(
    agents, ".cache/owner/repo/plugins/p/skills/my-skill",
  )
  @fs.mkdir(target, recursive=true)
  create_skill_link(
    agents,
    [@test_support.join_path(root, "extra-skills")],
    "my-skill",
    target,
  )
  assert_true(
    @fs.kind(
      @test_support.join_path(agents, "skills/my-skill"),
      follow_symlink=false,
    ) ==
    @fs.FileKind::SymLink,
  )
  assert_true(
    @fs.kind(
      @test_support.join_path(root, "extra-skills/my-skill"),
      follow_symlink=false,
    ) ==
    @fs.FileKind::SymLink,
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "create_skill_link overwrites existing symlink" {
  let root = @fs.tmpdir(prefix="c-plugin-link-overwrite-")
  let agents = @test_support.join_path(root, ".agents")
  let target1 = @test_support.join_path(agents, "target1")
  let target2 = @test_support.join_path(agents, "target2")
  @fs.mkdir(target1, recursive=true)
  @fs.mkdir(target2, recursive=true)
  create_skill_link(agents, [], "my-skill", target1)
  create_skill_link(agents, [], "my-skill", target2)
  assert_true(
    @fs.kind(
      @test_support.join_path(agents, "skills/my-skill"),
      follow_symlink=false,
    ) ==
    @fs.FileKind::SymLink,
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "clear_managed_links removes only symlinks from managed skill dirs" {
  let root = @fs.tmpdir(prefix="c-plugin-link-clear-")
  let agents = @test_support.join_path(root, ".agents")
  let extra = @test_support.join_path(root, "extra-skills")
  let target = @test_support.join_path(agents, "target")
  @fs.mkdir(target, recursive=true)
  create_skill_link(agents, [extra], "my-skill", target)
  @test_support.write_text(
    @test_support.join_path(agents, "skills/real-file"),
    "keep",
  )
  clear_managed_links(agents, [extra])
  assert_false(@fs.exists(@test_support.join_path(agents, "skills/my-skill")))
  assert_false(@fs.exists(@test_support.join_path(extra, "my-skill")))
  assert_true(@fs.exists(@test_support.join_path(agents, "skills/real-file")))
  @fs.rmdir(root, recursive=true)
}
