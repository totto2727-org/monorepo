///|
async fn write_lock_for_path_test(dir : String) -> String {
  @fs.mkdir(dir, recursive=true) catch {
    _ => ()
  }
  let path = @path.Path::join(dir, lock_file_name).to_string()
  @fs.write_file(path, empty_lock_text(), create_mode=CreateOrTruncate)
  path
}

///|
async test "command_agents_dir uses nearest ancestor lock file" {
  let root = @fs.tmpdir(prefix="c-plugin-nearest-lock-command-")
  let _root_lock = write_lock_for_path_test(root)
  let package_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-a")).to_string()
  let _package_lock = write_lock_for_path_test(package_dir)
  let start = (package_dir
  |> @path.Path::join("src")
  |> @path.Path::join("feature")).to_string()
  @fs.mkdir(start, recursive=true)
  let previous_pwd = @env.get_env_var("PWD")
  @env.set_env_var("PWD", start)
  inspect(
    command_agents_dir(false),
    content=@path.Path::join(package_dir, ".agents").to_string(),
  )
  match previous_pwd {
    Some(old) => @env.set_env_var("PWD", old)
    None => @env.unset_env_var("PWD")
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "command_agents_dir global maps home lock file to agents dir" {
  let root = @fs.tmpdir(prefix="c-plugin-global-lock-command-")
  let home = @path.Path::join(root, "home").to_string()
  let _home_lock = write_lock_for_path_test(home)
  let previous_home = @env.get_env_var("HOME")
  @env.set_env_var("HOME", home)
  inspect(
    command_agents_dir(true),
    content=@path.Path::join(home, ".agents").to_string(),
  )
  match previous_home {
    Some(old) => @env.set_env_var("HOME", old)
    None => @env.unset_env_var("HOME")
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "resolve_agents_dirs recursive starts from nearest lock file directory" {
  let root = @fs.tmpdir(prefix="c-plugin-recursive-lock-command-")
  let _root_lock = write_lock_for_path_test(root)
  let package_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-a")).to_string()
  let _package_lock = write_lock_for_path_test(package_dir)
  let child_dir = (package_dir
  |> @path.Path::join("examples")
  |> @path.Path::join("demo")).to_string()
  let _child_lock = write_lock_for_path_test(child_dir)
  let other_package_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-b")).to_string()
  let _other_package_lock = write_lock_for_path_test(other_package_dir)
  let start = @path.Path::join(package_dir, "src").to_string()
  @fs.mkdir(start, recursive=true)
  let previous_pwd = @env.get_env_var("PWD")
  let previous_home = @env.get_env_var("HOME")
  @env.set_env_var("PWD", start)
  @env.set_env_var("HOME", root)
  let dirs = resolve_agents_dirs(true)
  assert_true(
    dirs.contains(@path.Path::join(package_dir, ".agents").to_string()),
  )
  assert_true(dirs.contains(@path.Path::join(child_dir, ".agents").to_string()))
  assert_false(dirs.contains(@path.Path::join(root, ".agents").to_string()))
  assert_false(
    dirs.contains(@path.Path::join(other_package_dir, ".agents").to_string()),
  )
  match previous_pwd {
    Some(old) => @env.set_env_var("PWD", old)
    None => @env.unset_env_var("PWD")
  }
  match previous_home {
    Some(old) => @env.set_env_var("HOME", old)
    None => @env.unset_env_var("HOME")
  }
  @fs.rmdir(root, recursive=true)
}
