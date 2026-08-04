///|
async test "run_target_remove - clears managed links from the removed target" {
  let root = @fs.tmpdir(prefix="c-plugin-target-remove-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let target_dir = @path.Path::join(root, "target-skills").to_string()
  let skill = @path.Path::join(root, "skill-source").to_string()
  let link = @path.Path::join(target_dir, "demo-skill").to_string()
  @fs.mkdir(skill, recursive=true)
  @fs.mkdir(target_dir, recursive=true)
  @fs.symlink(target=skill, link)
  let repository : LockRepository = {
    source_type: RepositoryLocal,
    source: "./missing-repo",
    marketplace_kind: Claude,
    commit_hash: None,
    plugins: [
      { name: "demo", path: "plugins/demo", enabled_skills: ["demo-skill"] },
    ],
  }
  write_lock(agents, { skill_dirs: [target_dir], repositories: [repository] })
  let previous_pwd = @env.get_env_var("PWD")
  let previous_home = @env.get_env_var("HOME")
  @env.set_env_var("PWD", root)
  @env.set_env_var("HOME", root)
  run_target_remove(@admiral.Context(values={ "dir": [target_dir] }))
  let link_exists = @fs.exists(link)
  let remaining_targets = read_lock(agents).skill_dirs.length()
  match previous_pwd {
    Some(old) => @env.set_env_var("PWD", old)
    None => @env.unset_env_var("PWD")
  }
  match previous_home {
    Some(old) => @env.set_env_var("HOME", old)
    None => @env.unset_env_var("HOME")
  }
  @fs.rmdir(root, recursive=true)
  inspect(remaining_targets, content="0")
  assert_false(link_exists)
}

///|
async test "run_target_remove - resolves relative targets from the lock root and preserves unrelated symlinks" {
  let root = @fs.tmpdir(prefix="c-plugin-target-remove-relative-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let target_dir = @path.Path::join(root, "target-skills").to_string()
  let nested = root |> @path.Path::join("nested") |> @path.Path::join("cwd")
  let source = @path.Path::join(root, "source").to_string()
  @fs.mkdir(nested.to_string(), recursive=true)
  @fs.mkdir(target_dir, recursive=true)
  @fs.mkdir(source, recursive=true)
  @fs.symlink(target=source, @path.Path::join(target_dir, "owned").to_string())
  @fs.symlink(
    target=source,
    @path.Path::join(target_dir, "unrelated").to_string(),
  )
  let repository : LockRepository = {
    source_type: RepositoryLocal,
    source: "./missing-repo",
    marketplace_kind: Claude,
    commit_hash: None,
    plugins: [{ name: "demo", path: "plugins/demo", enabled_skills: ["owned"] }],
  }
  write_lock(agents, {
    skill_dirs: ["target-skills"],
    repositories: [repository],
  })
  let previous_pwd = @env.get_env_var("PWD")
  @env.set_env_var("PWD", nested.to_string())
  run_target_remove(@admiral.Context(values={ "dir": ["target-skills"] }))
  let owned_kind = @fs.kind(
    @path.Path::join(target_dir, "owned").to_string(),
    follow_symlink=false,
  ) catch {
    _ => @fs.FileKind::Unknown
  }
  let unrelated_kind = @fs.kind(
    @path.Path::join(target_dir, "unrelated").to_string(),
    follow_symlink=false,
  ) catch {
    _ => @fs.FileKind::Unknown
  }
  match previous_pwd {
    Some(old) => @env.set_env_var("PWD", old)
    None => @env.unset_env_var("PWD")
  }
  @fs.rmdir(root, recursive=true)
  assert_true(owned_kind != @fs.FileKind::SymLink)
  assert_true(unrelated_kind == @fs.FileKind::SymLink)
}

///|
async test "run_target_remove - preserves links in an unconfigured target" {
  let root = @fs.tmpdir(prefix="c-plugin-target-remove-unconfigured-")
  let agents = @path.Path::join(root, ".agents").to_string()
  let configured_dir = @path.Path::join(root, "configured-skills").to_string()
  let unconfigured_dir = @path.Path::join(root, "unconfigured-skills").to_string()
  let skill = @path.Path::join(root, "skill-source").to_string()
  let link = @path.Path::join(unconfigured_dir, "demo-skill").to_string()
  @fs.mkdir(skill, recursive=true)
  @fs.mkdir(unconfigured_dir, recursive=true)
  @fs.symlink(target=skill, link)
  write_lock(agents, { skill_dirs: [configured_dir], repositories: [] })
  let previous_pwd = @env.get_env_var("PWD")
  let previous_home = @env.get_env_var("HOME")
  @env.set_env_var("PWD", root)
  @env.set_env_var("HOME", root)
  run_target_remove(@admiral.Context(values={ "dir": [unconfigured_dir] }))
  let link_exists = @fs.exists(link)
  let remaining_targets = read_lock(agents).skill_dirs
  match previous_pwd {
    Some(old) => @env.set_env_var("PWD", old)
    None => @env.unset_env_var("PWD")
  }
  match previous_home {
    Some(old) => @env.set_env_var("HOME", old)
    None => @env.unset_env_var("HOME")
  }
  @fs.rmdir(root, recursive=true)
  inspect(remaining_targets.length(), content="1")
  assert_true(remaining_targets.contains(configured_dir))
  assert_true(link_exists)
}
