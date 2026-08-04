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
  write_lock(agents, { skill_dirs: [target_dir], repositories: [] })
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
