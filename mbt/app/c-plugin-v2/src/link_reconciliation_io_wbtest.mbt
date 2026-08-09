///|
async test "LinkReconciliation reconcile_skill_links 14 - continues independent desired links after typed per-link failures" {
  @async.with_task_group() <| group => {
    let temporary : @path.Path = @fs.tmpdir(prefix="c-plugin-v2-link-failures-")
    group.add_defer(() => @fs.rmdir(temporary.to_string(), recursive=true))
    let root : @path.Path = @fs.realpath(temporary.to_string())
    let names = ["a-mkdir", "b-realpath", "c-kind", "d-create", "e-success"]
    let entries = []
    for name in names {
      let target = root.join("targets").join(name)
      @fs.mkdir(target.to_string(), recursive=true)
      entries.push(
        stale_reconciliation_entry(root.join(name), "install", target),
      )
    }
    let checkpoints = []
    let io : LinkReconciliationIO = {
      mkdir: async fn(path) {
        if path == entries[0].managed_root.path {
          fail("mkdir failed")
        }
        @fs.mkdir(path.to_string(), recursive=true) catch {
          @os_error.OSError(_) as error if error.is_EEXIST() => ()
          error => raise error
        }
      },
      kind: async fn(path) {
        if path == entries[2].link.path {
          fail("kind failed")
        }
        @fs.kind(path.to_string(), follow_symlink=false)
      },
      realpath: async fn(path) {
        if path == entries[1].managed_root.path {
          fail("realpath failed")
        }
        @path.Path(@fs.realpath(path.to_string()))
      },
      symlink: async fn(target, link) {
        if link == entries[3].link.path {
          fail("create failed")
        }
        @fs.symlink(target=target.to_string(), link.to_string())
      },
      remove: async fn(path) { @fs.remove(path.to_string()) },
      checkpoint: fn(_path, state) { checkpoints.push(state) },
    }
    let result = reconcile_skill_links_with_io(
      io,
      root.join("state.json"),
      OwnershipState::OwnershipState(entries),
      Trusted(OwnershipState::OwnershipState([])),
    )
    debug_inspect(result.status, content="Partial")
    inspect(result.notices.length(), content="4")
    for
      index, expected_operation in [
        EnsureManagedRoot,
        VerifyContainment,
        ClassifyLink,
        CreateLink,
      ] {
      match result.notices[index] {
        OperationFailed(operation~, path~, reason=_) => {
          inspect(operation == expected_operation, content="true")
          let expected_path = if index == 0 {
            entries[index].managed_root.path
          } else {
            entries[index].link.path
          }
          inspect(path == expected_path, content="true")
        }
        _ => fail("expected typed per-link operation failure")
      }
    }
    inspect(checkpoints.length(), content="1")
    inspect(result.durable_state.entries.length(), content="1")
    inspect(
      result.durable_state.entries.get(
        OwnershipLinkIdentity::OwnershipLinkIdentity(entries[4].link.path),
      ) ==
      Some(entries[4]),
      content="true",
    )
  }
}

///|
async test "LinkReconciliation reconcile_skill_links 15 - retains failed stale removal while checkpointing an independent removal" {
  @async.with_task_group() <| group => {
    let temporary : @path.Path = @fs.tmpdir(
      prefix="c-plugin-v2-remove-partial-",
    )
    group.add_defer(() => @fs.rmdir(temporary.to_string(), recursive=true))
    let root : @path.Path = @fs.realpath(temporary.to_string())
    let entries = []
    for name in ["a-fail", "b-success"] {
      let managed_root = root.join(name)
      let target = root.join("targets").join(name)
      @fs.mkdir(managed_root.to_string(), recursive=true)
      @fs.mkdir(target.to_string(), recursive=true)
      let entry = stale_reconciliation_entry(managed_root, "install", target)
      @fs.symlink(
        target=entry.symlink_target.to_string(),
        entry.link.path.to_string(),
      )
      entries.push(entry)
    }
    let checkpoints = []
    let io : LinkReconciliationIO = {
      mkdir: async fn(path) { @fs.mkdir(path.to_string(), recursive=true) },
      kind: async fn(path) { @fs.kind(path.to_string(), follow_symlink=false) },
      realpath: async fn(path) { @path.Path(@fs.realpath(path.to_string())) },
      symlink: async fn(target, link) {
        @fs.symlink(target=target.to_string(), link.to_string())
      },
      remove: async fn(path) {
        if path == entries[0].link.path {
          fail("remove failed")
        }
        @fs.remove(path.to_string())
      },
      checkpoint: fn(_path, state) { checkpoints.push(state) },
    }
    let result = reconcile_skill_links_with_io(
      io,
      root.join("state.json"),
      OwnershipState::OwnershipState([]),
      Trusted(OwnershipState::OwnershipState(entries)),
    )
    debug_inspect(result.status, content="Partial")
    inspect(result.durable_state.entries.length(), content="1")
    inspect(checkpoints.length(), content="1")
    match result.notices[0] {
      OperationFailed(operation=RemoveLink, path~, reason=_) =>
        inspect(path == entries[0].link.path, content="true")
      _ => fail("expected stale remove failure")
    }
    debug_inspect(
      @fs.kind(entries[0].link.path.to_string(), follow_symlink=false),
      content="SymLink",
    )
    let removed = @fs.kind(
      entries[1].link.path.to_string(),
      follow_symlink=false,
    ) catch {
      _ => @fs.FileKind::Unknown
    }
    debug_inspect(removed, content="Unknown")
  }
}
