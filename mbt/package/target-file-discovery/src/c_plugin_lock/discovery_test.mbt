///|
async fn write_lock_file(dir : String, file_name : String) -> String {
  @fs.mkdir(dir, recursive=true) catch {
    _ => ()
  }
  let path = @path.Path::join(dir, file_name).to_string()
  @fs.write_file(path, "{}", create_mode=CreateOrTruncate)
  path
}

///|
async test "find_home_sibling_dir_for_target_file maps home lock to sibling dir" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-home-lookup-")
  let home = @path.Path::join(root, "home").to_string()
  let _lock = write_lock_file(home, "c-plugin-lock.json")
  inspect(
    find_home_sibling_dir_for_target_file(home, "c-plugin-lock.json", ".agents"),
    content=@path.Path::join(home, ".agents").to_string(),
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "resolve_sibling_dirs_for_target_file selects nearest ancestor lock" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-nearest-lookup-")
  let _root_lock = write_lock_file(root, "c-plugin-lock.json")
  let package_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-a")).to_string()
  let _package_lock = write_lock_file(package_dir, "c-plugin-lock.json")
  let start = (package_dir
  |> @path.Path::join("src")
  |> @path.Path::join("feature")).to_string()
  @fs.mkdir(start, recursive=true)
  inspect(
    resolve_sibling_dirs_for_target_file(
      "c-plugin-lock.json", ".agents", false, root, start,
    ).join(","),
    content=@path.Path::join(package_dir, ".agents").to_string(),
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "resolve_sibling_dirs_for_target_file recursive starts at nearest lock directory" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-recursive-lookup-")
  let _root_lock = write_lock_file(root, "c-plugin-lock.json")
  let package_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-a")).to_string()
  let _package_lock = write_lock_file(package_dir, "c-plugin-lock.json")
  let child_dir = (package_dir
  |> @path.Path::join("examples")
  |> @path.Path::join("demo")).to_string()
  let _child_lock = write_lock_file(child_dir, "c-plugin-lock.json")
  let sibling_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-b")).to_string()
  let _sibling_lock = write_lock_file(sibling_dir, "c-plugin-lock.json")
  let start = @path.Path::join(package_dir, "src").to_string()
  @fs.mkdir(start, recursive=true)
  let dirs = resolve_sibling_dirs_for_target_file(
    "c-plugin-lock.json", ".agents", true, root, start,
  )
  assert_true(
    dirs.contains(@path.Path::join(package_dir, ".agents").to_string()),
  )
  assert_true(dirs.contains(@path.Path::join(child_dir, ".agents").to_string()))
  assert_false(dirs.contains(@path.Path::join(root, ".agents").to_string()))
  assert_false(
    dirs.contains(@path.Path::join(sibling_dir, ".agents").to_string()),
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "target_file_for_sibling_dir maps sibling dir back to adjacent target file" {
  let root = @fs.tmpdir(prefix="c-plugin-lock-target-from-sibling-")
  let agents = @path.Path::join(root, ".agents").to_string()
  inspect(
    target_file_for_sibling_dir(agents, "c-plugin-lock.json"),
    content=@path.Path::join(root, "c-plugin-lock.json").to_string(),
  )
  @fs.rmdir(root, recursive=true)
}
