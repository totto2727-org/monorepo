///|
fn test_join_path(base : String, name : String) -> String {
  if base == "" || base == "/" {
    "/\{name}"
  } else if base.has_suffix("/") {
    "\{base}\{name}"
  } else {
    "\{base}/\{name}"
  }
}

///|
async fn write_target_file(dir : String, file_name : String) -> String {
  @fs.mkdir(dir, recursive=true) catch {
    _ => ()
  }
  let path = test_join_path(dir, file_name)
  @fs.write_file(path, "{}", create_mode=CreateOrTruncate)
  path
}

///|
async fn write_gitignore(dir : String, content : String) -> Unit {
  @fs.mkdir(dir, recursive=true) catch {
    _ => ()
  }
  @fs.write_file(
    test_join_path(dir, ".gitignore"),
    content,
    create_mode=CreateOrTruncate,
  )
}

///|
async test "find_home_target_file finds direct home file" {
  let root = @fs.tmpdir(prefix="target-file-discovery-home-")
  let target = write_target_file(root, "target.lock")
  inspect(find_home_target_file(root, "target.lock"), content=target)
  @fs.rmdir(root, recursive=true)
}

///|
async test "find_parent_target_file finds nearest ancestor within boundary" {
  let root = @fs.tmpdir(prefix="target-file-discovery-parent-")
  let _root_target = write_target_file(root, "target.lock")
  let package_dir = test_join_path(root, "packages/pkg-a")
  let package_target = write_target_file(package_dir, "target.lock")
  let start_dir = test_join_path(package_dir, "src/feature")
  @fs.mkdir(start_dir, recursive=true)
  inspect(
    find_parent_target_file("target.lock", root, start_dir),
    content=package_target,
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files honors gitignore only for directories" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-")
  let root_target = write_target_file(root, "target.lock")
  write_gitignore(root, "ignored-packages/\ntarget.lock\n")
  let ignored_target = write_target_file(
    test_join_path(root, "ignored-packages/pkg-a"),
    "target.lock",
  )
  let visible_target = write_target_file(
    test_join_path(root, "packages/pkg-a"),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(root_target))
  assert_true(files.contains(visible_target))
  assert_false(files.contains(ignored_target))
  @fs.rmdir(root, recursive=true)
}
