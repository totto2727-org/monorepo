///|
struct ResourceStoreTestValue {
  label : String
  counter : Ref[Int]
} derive(Debug)

///|
extenum @any.Payload += {
  ResourceStoreTestValue(ResourceStoreTestValue)
}

///|
impl @any.Anyable for ResourceStoreTestValue with fn iso() {
  {
    id: @any.TypeId::TypeId(
      "totto2727/workgraph-core",
      "ResourceStoreTestValue",
      [],
    ),
    box: resource => ResourceStoreTestValue(resource),
    unbox: payload => {
      guard payload is ResourceStoreTestValue(resource)
      resource
    },
  }
}

///|
test "ResourceStore values 1 - stores and removes a typed in-memory value" {
  let store = ResourceStore::ResourceStore()
  let key = ResourceKey::parse("counter")
  let resource_ref : @any_collection.AnyRef[ResourceKey, ResourceStoreTestValue] = @any_collection.AnyRef::AnyRef(
    key,
  )
  let wrong_ref : @any_collection.AnyRef[ResourceKey, String] = @any_collection.AnyRef::AnyRef(
    key,
  )
  let counter = Ref(1)
  store.set(resource_ref, ResourceStoreTestValue::{ label: "counter", counter })
  guard store.get(resource_ref) is Some(stored) else {
    fail("expected the typed runtime value")
  }
  stored.counter.val = stored.counter.val + 1
  inspect(counter.val, content="2")
  let mismatch_raised = try {
    store.get(wrong_ref) |> ignore
    false
  } catch {
    Failure::Failure(_) => true
    _ => false
  }
  inspect(mismatch_raised, content="true")
  store.remove(resource_ref)
  inspect(store.get(resource_ref) is None, content="true")
}

///|
async test "ResourceStore acquire_resource 1 - reuses run resources and closes node resources by owner" {
  let store = ResourceStore::ResourceStore()
  let opened : Array[String] = []
  let closed : Array[String] = []
  let run_ref : @any_collection.AnyRef[ResourceKey, ResourceStoreTestValue] = @any_collection.AnyRef::AnyRef(
    ResourceKey::parse("run-resource"),
  )
  let node_ref : @any_collection.AnyRef[ResourceKey, ResourceStoreTestValue] = @any_collection.AnyRef::AnyRef(
    ResourceKey::parse("node-resource"),
  )
  let first_node = NodeId::parse("first")
  let second_node = NodeId::parse("second")
  let close = async fn(resource : ResourceStoreTestValue) {
    @async.pause()
    closed.push(resource.label)
  }
  let run_resource = store.acquire_resource(
    run_ref,
    Run,
    async fn() {
      @async.pause()
      opened.push("run")
      ResourceStoreTestValue::{ label: "run", counter: Ref(1) }
    },
    close,
  )
  let reused_run_resource = store.acquire_resource(
    run_ref,
    Run,
    async fn() {
      @async.pause()
      opened.push("unexpected")
      ResourceStoreTestValue::{ label: "unexpected", counter: Ref(2) }
    },
    close,
  )
  let first_node_resource = store.acquire_resource(
    node_ref,
    Node,
    async fn() {
      @async.pause()
      opened.push("node-first")
      ResourceStoreTestValue::{ label: "node-first", counter: Ref(3) }
    },
    close,
    owner=first_node,
  )
  store.release_node(first_node)
  let second_node_resource = store.acquire_resource(
    node_ref,
    Node,
    async fn() {
      @async.pause()
      opened.push("node-second")
      ResourceStoreTestValue::{ label: "node-second", counter: Ref(4) }
    },
    close,
    owner=second_node,
  )
  debug_inspect(
    [
      run_resource.label,
      reused_run_resource.label,
      first_node_resource.label,
      second_node_resource.label,
    ],
    content="[\"run\", \"run\", \"node-first\", \"node-second\"]",
  )
  inspect(opened.join(","), content="run,node-first,node-second")
  inspect(closed.join(","), content="node-first")
  store.release_node(first_node)
  store.close_all()
  inspect(closed.join(","), content="node-first,node-second,run")
  store.close_all()
  inspect(closed.join(","), content="node-first,node-second,run")
}

///|
suberror LifecycleTestError {
  LifecycleOpenFailed(String)
  LifecycleCloseFailed(String)
} derive(Debug)

///|
enum LifecycleClosePlan {
  Succeeds
  Fails(String)
  Sleeps(Int)
} derive(Debug)

///|
struct LifecycleResource {
  label : String
  closed : Array[String]
  plan : LifecycleClosePlan
} derive(Debug)

///|
extenum @any.Payload += {
  LifecycleResource(LifecycleResource)
}

///|
impl @any.Anyable for LifecycleResource with fn iso() {
  {
    id: @any.TypeId::TypeId("totto2727/workgraph-core", "LifecycleResource", []),
    box: resource => LifecycleResource(resource),
    unbox: payload => {
      guard payload is LifecycleResource(resource)
      resource
    },
  }
}

///|
async fn close_lifecycle_resource(resource : LifecycleResource) -> Unit {
  match resource.plan {
    Succeeds => resource.closed.push(resource.label)
    Fails(message) => {
      resource.closed.push(resource.label)
      raise LifecycleCloseFailed(message)
    }
    Sleeps(milliseconds) => {
      resource.closed.push("\{resource.label}:started")
      @async.sleep(milliseconds)
      resource.closed.push("\{resource.label}:finished")
    }
  }
}

///|
fn lifecycle_resource(
  label : String,
  closed : Array[String],
  plan : LifecycleClosePlan,
) -> LifecycleResource {
  LifecycleResource::{ label, closed, plan }
}

///|
fn lifecycle_resource_ref(
  key : ResourceKey,
) -> @any_collection.AnyRef[ResourceKey, LifecycleResource] {
  @any_collection.AnyRef::AnyRef(key)
}

///|
async test "ResourceStore lifecycle 1 - preserves an open error and retries a later acquisition" {
  let store = ResourceStore::ResourceStore()
  let closed : Array[String] = []
  let mut opens = 0
  let key = ResourceKey::parse("retry-open")
  let first_error = try {
    store.acquire_resource(
      lifecycle_resource_ref(key),
      Run,
      async fn() {
        @async.pause()
        opens = opens + 1
        raise LifecycleOpenFailed("first")
      },
      close_lifecycle_resource,
    )
    |> ignore
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(
        rendered.contains("LifecycleOpenFailed(\"first\")"),
        content="true",
      )
      true
    }
  }
  inspect(first_error, content="true")
  let resource = store.acquire_resource(
    lifecycle_resource_ref(key),
    Run,
    async fn() {
      @async.pause()
      opens = opens + 1
      lifecycle_resource("retry", closed, Succeeds)
    },
    close_lifecycle_resource,
  )
  inspect(resource.label, content="retry")
  inspect(opens, content="2")
}

///|
async test "ResourceStore lifecycle 2 - rejects a node resource without its owner" {
  let store = ResourceStore::ResourceStore()
  let key = ResourceKey::parse("owner-required")
  let detail = try {
    store.acquire_resource(
      lifecycle_resource_ref(key),
      Node,
      async fn() {
        @async.pause()
        fail("node open must not run without an owner")
      },
      close_lifecycle_resource,
    )
    |> ignore
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(
        rendered.contains("NodeOwnerRequired(ResourceKey(\"owner-required\"))"),
        content="true",
      )
      true
    }
  }
  inspect(detail, content="true")
}

///|
async test "ResourceStore lifecycle 3 - aggregates one close error after reverse cleanup without double close" {
  let store = ResourceStore::ResourceStore()
  let closed : Array[String] = []
  let first = ResourceKey::parse("first")
  let failed = ResourceKey::parse("failed")
  let last = ResourceKey::parse("last")
  store.acquire_resource(
    lifecycle_resource_ref(first),
    Run,
    async fn() {
      @async.pause()
      lifecycle_resource("first", closed, Succeeds)
    },
    close_lifecycle_resource,
  )
  |> ignore
  store.acquire_resource(
    lifecycle_resource_ref(failed),
    Run,
    async fn() {
      @async.pause()
      lifecycle_resource("failed", closed, Fails("close-detail"))
    },
    close_lifecycle_resource,
  )
  |> ignore
  store.acquire_resource(
    lifecycle_resource_ref(last),
    Run,
    async fn() {
      @async.pause()
      lifecycle_resource("last", closed, Succeeds)
    },
    close_lifecycle_resource,
  )
  |> ignore
  let detail = try {
    store.close_all()
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(
        rendered.contains(
          "CloseFailed(errors=<ReadOnlyArray: [LifecycleCloseFailed(\"close-detail\")]>)",
        ),
        content="true",
      )
      true
    }
  }
  inspect(detail, content="true")
  inspect(closed.join(","), content="last,failed,first")
  store.close_all()
  inspect(closed.join(","), content="last,failed,first")
}

///|
async test "ResourceStore finalize 1 - rejects a non-positive timeout" {
  let store = ResourceStore::ResourceStore()
  let detail = try {
    store.finalize(0)
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(rendered.contains("InvalidCleanupTimeout(0)"), content="true")
      true
    }
  }
  inspect(detail, content="true")
}

///|
async test "ResourceStore finalize 2 - completes a suspended close before caller cancellation propagates" {
  @async.with_task_group() <| group => {
    let store = ResourceStore::ResourceStore()
    let closed : Array[String] = []
    let key = ResourceKey::parse("cancel-close")
    store.acquire_resource(
      lifecycle_resource_ref(key),
      Run,
      async fn() {
        @async.pause()
        lifecycle_resource("cancel-close", closed, Sleeps(50))
      },
      close_lifecycle_resource,
    )
    |> ignore
    let task = group.spawn(
      async fn() { store.finalize(500) },
      allow_failure=true,
    )
    @async.pause()
    task.cancel()
    let cancellation = try {
      task.wait()
      false
    } catch {
      error => @async.is_cancellation_error(error)
    }
    inspect(cancellation, content="true")
    inspect(
      closed.join(","),
      content="cancel-close:started,cancel-close:finished",
    )
  }
}

///|
async test "ResourceStore finalize 3 - raises the configured hard timeout" {
  let store = ResourceStore::ResourceStore()
  let closed : Array[String] = []
  let key = ResourceKey::parse("timeout-close")
  store.acquire_resource(
    lifecycle_resource_ref(key),
    Run,
    async fn() {
      @async.pause()
      lifecycle_resource("timeout-close", closed, Sleeps(100))
    },
    close_lifecycle_resource,
  )
  |> ignore
  let detail = try {
    store.finalize(5)
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(rendered.contains("CleanupTimedOut(5)"), content="true")
      true
    }
  }
  inspect(detail, content="true")
  inspect(closed.join(","), content="timeout-close:started")
}
