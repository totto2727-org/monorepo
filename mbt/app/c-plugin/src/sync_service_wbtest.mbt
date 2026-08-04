///|
async test "sync_all links only enabled skills from lock file" {
  let root = @fs.tmpdir(prefix="c-plugin-sync-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let repo = @path.Path::join(root, "repo").to_string()
  @fs.mkdir(agents, recursive=true)
  @test_support.write_claude_marketplace(repo)
  @test_support.write_skill(repo, "skill-a")
  @test_support.write_skill(repo, "skill-b")
  let unrelated_source = @path.Path::join(root, "unrelated-source").to_string()
  let unrelated_link = (agents
  |> @path.Path::join("skills")
  |> @path.Path::join("unrelated")).to_string()
  @fs.mkdir(unrelated_source, recursive=true)
  @fs.mkdir(@path.Path::dirname(unrelated_link).to_string(), recursive=true)
  @fs.symlink(target=unrelated_source, unrelated_link)
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
  assert_true(
    @fs.kind(unrelated_link, follow_symlink=false) == @fs.FileKind::SymLink,
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
  assert_false(
    has_sync_conflicts([
      { agents: "/tmp/project-a/.agents", lock: empty_lock },
      { agents: "/tmp/project-b/.agents", lock: empty_lock },
    ]),
  )
  assert_true(
    has_sync_conflicts([
      {
        agents: "/tmp/project-a/.agents",
        lock: { skill_dirs: [shared], repositories: [] },
      },
      {
        agents: "/tmp/project-b/.agents",
        lock: { skill_dirs: [shared], repositories: [] },
      },
    ]),
  )
}

///|
test "managed_skill_roots resolves relative targets from the lock root" {
  debug_inspect(
    managed_skill_roots("/tmp/project/.agents", ["nested/skills"]),
    content="[\"/tmp/project/.agents/skills\", \"/tmp/project/nested/skills\"]",
  )
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
  assert_true(
    has_update_conflicts([
      {
        agents: "/tmp/project-a/.agents",
        lock: { skill_dirs: [], repositories: [repository] },
      },
      {
        agents: "/tmp/project-b/.agents",
        lock: { skill_dirs: [], repositories: [repository] },
      },
    ]),
  )
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
async fn create_test_remote(root : String) -> (String, String, String) {
  let remote = @path.Path::join(root, "remote.git").to_string()
  let seed = @path.Path::join(root, "seed").to_string()
  run_checked("git", ["init", "--bare", remote])
  run_checked("git", ["init", "-b", "main", seed])
  @test_support.write_text(
    @path.Path::join(seed, "state.txt").to_string(),
    "one",
  )
  run_checked("git", ["-C", seed, "add", "state.txt"])
  run_checked("git", [
    "-C", seed, "-c", "user.name=c-plugin test", "-c", "user.email=c-plugin@example.invalid",
    "commit", "-m", "initial",
  ])
  run_checked("git", ["-C", seed, "remote", "add", "origin", remote])
  run_checked("git", ["-C", seed, "push", "-u", "origin", "main"])
  run_checked("git", [
    "--git-dir", remote, "symbolic-ref", "HEAD", "refs/heads/main",
  ])
  let first = collect_or_empty("git", ["-C", seed, "rev-parse", "HEAD"])
  @test_support.write_text(
    @path.Path::join(seed, "state.txt").to_string(),
    "two",
  )
  run_checked("git", ["-C", seed, "add", "state.txt"])
  run_checked("git", [
    "-C", seed, "-c", "user.name=c-plugin test", "-c", "user.email=c-plugin@example.invalid",
    "commit", "-m", "advance remote",
  ])
  run_checked("git", ["-C", seed, "push", "origin", "main"])
  (remote, seed, first)
}

///|
async test "ensure_repo_dir - fresh cache retains pinned history" {
  let root = @fs.tmpdir(prefix="c-plugin-repo-history-")
  let (remote, _, first) = create_test_remote(root)
  let cache = @path.Path::join(root, "cache").to_string()
  ensure_repo_dir(cache, "file://\{remote}", root) |> ignore
  run_checked("git", ["-C", cache, "checkout", first])
  inspect(
    collect_or_empty("git", ["-C", cache, "rev-parse", "HEAD"]),
    content=first,
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "ensure_repo_dir - migrates an existing shallow cache" {
  let root = @fs.tmpdir(prefix="c-plugin-repo-unshallow-")
  let (remote, _, first) = create_test_remote(root)
  let cache = @path.Path::join(root, "cache").to_string()
  run_checked("git", ["clone", "--depth", "1", "file://\{remote}", cache])
  ensure_repo_dir(cache, "file://\{remote}", root) |> ignore
  inspect(
    collect_or_empty("git", [
      "-C", cache, "rev-parse", "--is-shallow-repository",
    ]),
    content="false",
  )
  run_checked("git", ["-C", cache, "checkout", first])
  @fs.rmdir(root, recursive=true)
}

///|
async test "update_repo_dir - fast-forwards a clean cache" {
  let root = @fs.tmpdir(prefix="c-plugin-update-repo-")
  let (remote, seed, _) = create_test_remote(root)
  let cache = @path.Path::join(root, "cache").to_string()
  ensure_repo_dir(cache, "file://\{remote}", root) |> ignore
  @test_support.write_text(
    @path.Path::join(seed, "state.txt").to_string(),
    "three",
  )
  run_checked("git", ["-C", seed, "add", "state.txt"])
  run_checked("git", [
    "-C", seed, "-c", "user.name=c-plugin test", "-c", "user.email=c-plugin@example.invalid",
    "commit", "-m", "advance again",
  ])
  run_checked("git", ["-C", seed, "push", "origin", "main"])
  let expected = collect_or_empty("git", ["-C", seed, "rev-parse", "HEAD"])
  ensure_repo_dir(cache, "file://\{remote}", root) |> ignore
  update_repo_dir(cache) |> ignore
  inspect(
    collect_or_empty("git", ["-C", cache, "rev-parse", "HEAD"]),
    content=expected,
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "ensure_repo_dir - rejects mismatched origin without changing the cache" {
  let root = @fs.tmpdir(prefix="c-plugin-origin-mismatch-")
  let (remote, _, _) = create_test_remote(root)
  let cache = @path.Path::join(root, "cache").to_string()
  ensure_repo_dir(cache, "file://\{remote}", root) |> ignore
  run_checked("git", [
    "-C", cache, "remote", "set-url", "origin", "file:///unexpected",
  ])
  let head = collect_or_empty("git", ["-C", cache, "rev-parse", "HEAD"])
  let outcome = try {
    ensure_repo_dir(cache, "file://\{remote}", root) |> ignore
    "returned"
  } catch {
    _ => "raised"
  }
  let preserved_head = collect_or_empty("git", [
    "-C", cache, "rev-parse", "HEAD",
  ])
  let preserved_origin = collect_or_empty("git", [
    "-C", cache, "config", "--get", "remote.origin.url",
  ])
  @fs.rmdir(root, recursive=true)
  inspect(outcome, content="raised")
  inspect(preserved_head, content=head)
  inspect(preserved_origin, content="file:///unexpected")
}

///|
async test "ensure_repo_dir - rejects a cache beneath a symlinked parent" {
  let root = @fs.tmpdir(prefix="c-plugin-cache-symlink-")
  let (remote, _, _) = create_test_remote(root)
  let actual_parent = @path.Path::join(root, "actual-parent").to_string()
  let actual = @path.Path::join(actual_parent, "cache").to_string()
  let linked_parent = @path.Path::join(root, "linked-parent").to_string()
  let cache = @path.Path::join(linked_parent, "cache").to_string()
  ensure_repo_dir(actual, "file://\{remote}", root) |> ignore
  @fs.symlink(target=actual_parent, linked_parent)
  let head = collect_or_empty("git", ["-C", actual, "rev-parse", "HEAD"])
  let outcome = try {
    ensure_repo_dir(cache, "file://\{remote}", root) |> ignore
    "returned"
  } catch {
    _ => "raised"
  }
  let preserved_head = collect_or_empty("git", [
    "-C", actual, "rev-parse", "HEAD",
  ])
  let preserved_kind = @fs.kind(linked_parent, follow_symlink=false)
  @fs.rmdir(root, recursive=true)
  inspect(outcome, content="raised")
  inspect(preserved_head, content=head)
  assert_true(preserved_kind == @fs.FileKind::SymLink)
}

///|
async test "update_repo_dir - rejects and preserves a dirty cache" {
  let root = @fs.tmpdir(prefix="c-plugin-dirty-cache-")
  let (remote, _, _) = create_test_remote(root)
  let cache = @path.Path::join(root, "cache").to_string()
  ensure_repo_dir(cache, "file://\{remote}", root) |> ignore
  @test_support.write_text(
    @path.Path::join(cache, "untracked.txt").to_string(),
    "keep",
  )
  let outcome = try {
    update_repo_dir(cache) |> ignore
    "returned"
  } catch {
    _ => "raised"
  }
  let preserved = @fs.read_file(
    @path.Path::join(cache, "untracked.txt").to_string(),
  ).text()
  @fs.rmdir(root, recursive=true)
  inspect(outcome, content="raised")
  inspect(preserved, content="keep")
}

///|
async test "sync_all keeps the last repository for duplicate skill names" {
  let root = @fs.tmpdir(prefix="c-plugin-sync-duplicate-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let first_repo = @path.Path::join(root, "repo-1").to_string()
  let second_repo = @path.Path::join(root, "repo-2").to_string()
  @fs.mkdir(agents, recursive=true)
  @async.all([
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
