///|
test "init_options - reads the global flag" {
  let context = @admiral.Context(flags={ "global": true })
  inspect(init_options(context).global, content="true")
}

///|
async test "init_lock_file creates agents directory and empty lock file" {
  let root = @fs.tmpdir(prefix="c-plugin-init-test-")
  let lock_path = init_lock_file(root)
  inspect(lock_path, content=@path.Path::join(root, lock_file_name).to_string())
  inspect(@fs.read_file(lock_path).text(), content=empty_lock_text())
  inspect(
    @fs.readdir(@path.Path::join(root, ".agents").to_string()).length(),
    content="0",
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "init_lock_file does not overwrite existing lock file" {
  let root = @fs.tmpdir(prefix="c-plugin-init-existing-test-")
  let lock_path = @path.Path::join(root, lock_file_name).to_string()
  @test_support.write_text(
    lock_path, "{\"version\":1,\"repositories\":[],\"skillDirs\":[\"/keep\"]}\n",
  )
  try {
    ignore(init_lock_file(root))
    inspect("no error", content="error")
  } catch {
    _ => ()
  }
  inspect(
    @fs.read_file(lock_path).text(),
    content="{\"version\":1,\"repositories\":[],\"skillDirs\":[\"/keep\"]}\n",
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "init_lock_file rejects a broken lock symlink" {
  let root = @fs.tmpdir(prefix="c-plugin-init-symlink-test-")
  let outside = @path.Path::join(root, "outside/victim.json").to_string()
  let lock_path = @path.Path::join(root, lock_file_name).to_string()
  @fs.mkdir(@path.Path::dirname(outside).to_string(), recursive=true)
  @fs.symlink(target=outside, lock_path)
  let outcome = try {
    init_lock_file(root) |> ignore
    "returned"
  } catch {
    _ => "raised"
  }
  let link_kind = @fs.kind(lock_path, follow_symlink=false)
  let victim_exists = @fs.exists(outside)
  @fs.rmdir(root, recursive=true)
  inspect(outcome, content="raised")
  assert_true(link_kind == @fs.FileKind::SymLink)
  assert_false(victim_exists)
}
