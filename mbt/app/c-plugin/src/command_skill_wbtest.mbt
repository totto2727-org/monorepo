///|
test "skill_add_options - rejects a local path that escapes its root" {
  let context = @admiral.Context(values={ "local": ["./../outside"] })
  let outcome = try {
    skill_add_options(context) |> ignore
    "returned"
  } catch {
    _ => "raised"
  }
  inspect(outcome, content="raised")
}

///|
test "skill_add_options - rejects simultaneous repository and local sources" {
  let context = @admiral.Context(values={
    "repo": ["owner/repository"],
    "local": ["./marketplace"],
  })
  let outcome = try {
    skill_add_options(context) |> ignore
    "returned"
  } catch {
    _ => "raised"
  }
  inspect(outcome, content="raised")
}

///|
async test "run_skill_remove - preserves links owned by a remaining unavailable repository" {
  let root = @fs.tmpdir(prefix="c-plugin-skill-remove-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let links = agents |> @path.Path::join("skills")
  let source = @path.Path::join(root, "source").to_string()
  @fs.mkdir(links.to_string(), recursive=true)
  @fs.mkdir(source, recursive=true)
  @fs.symlink(target=source, @path.Path::join(links, "removed").to_string())
  @fs.symlink(target=source, @path.Path::join(links, "remaining").to_string())
  let plugin = fn(name : String) -> LockPlugin {
    { name, path: "plugins/\{name}", enabled_skills: [name] }
  }
  write_lock(agents, {
    skill_dirs: [],
    repositories: [
      {
        source_type: RepositoryLocal,
        source: "./removed-repo",
        marketplace_kind: Claude,
        commit_hash: None,
        plugins: [plugin("removed")],
      },
      {
        source_type: RepositoryLocal,
        source: "./unavailable-repo",
        marketplace_kind: Claude,
        commit_hash: None,
        plugins: [plugin("remaining")],
      },
    ],
  })
  let previous_pwd = @env.get_env_var("PWD")
  @env.set_env_var("PWD", root)
  run_skill_remove(@admiral.Context(values={ "repo": ["./removed-repo"] }))
  let removed_kind = @fs.kind(
    @path.Path::join(links, "removed").to_string(),
    follow_symlink=false,
  ) catch {
    _ => @fs.FileKind::Unknown
  }
  let remaining_kind = @fs.kind(
    @path.Path::join(links, "remaining").to_string(),
    follow_symlink=false,
  ) catch {
    _ => @fs.FileKind::Unknown
  }
  let repositories = read_lock(agents).repositories
  match previous_pwd {
    Some(old) => @env.set_env_var("PWD", old)
    None => @env.unset_env_var("PWD")
  }
  @fs.rmdir(root, recursive=true)
  assert_true(removed_kind != @fs.FileKind::SymLink)
  assert_true(remaining_kind == @fs.FileKind::SymLink)
  inspect(repositories.length(), content="1")
}
