///|
fn test_reducer() -> Reducer[Int, Int] {
  Reducer::Reducer(fn(state, patch) { state + patch })
}

///|
fn test_node(id : NodeId, tags : ReadOnlyArray[String]) -> Node[Int, Int] {
  Node::Node(
    id,
    NodeMetadata::NodeMetadata(
      name=id.to_string(),
      description=None,
      kind=Function,
      tags~,
    ),
    async fn(_context, _state) {
      @async.pause()
      NodeOutput::NodeOutput(None, None, [])
    },
  )
}

///|
fn end_router() -> Router[Int] {
  router([], fn(_state, _completion) { End })
}

///|
fn to_router(target : NodeId) -> Router[Int] {
  router([DeclaredRoute::DeclaredRoute(target)], fn(_state, _completion) {
    To(target)
  })
}

///|
test "GraphDefinition compile GRAPH-001 - one node, router, and entry" {
  let a = NodeId::parse("A")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, []))
  definition.set_router(a, end_router())
  definition.set_entry(a)
  inspect(definition.compile().entry().to_string(), content="A")
}

///|
test "GraphDefinition add_node GRAPH-002 - duplicate node" {
  let a = NodeId::parse("A")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, []))
  try definition.add_node(test_node(a, [])) catch {
    DuplicateNode(id) => inspect(id.to_string(), content="A")
    _ => fail("expected DuplicateNode")
  } noraise {
    _ => fail("expected DuplicateNode")
  }
}

///|
test "GraphDefinition set_router GRAPH-003 - duplicate router" {
  let a = NodeId::parse("A")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.set_router(a, end_router())
  try definition.set_router(a, end_router()) catch {
    DuplicateRouter(id) => inspect(id.to_string(), content="A")
    _ => fail("expected DuplicateRouter")
  } noraise {
    _ => fail("expected DuplicateRouter")
  }
}

///|
test "GraphDefinition compile GRAPH-004 - missing entry" {
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  try definition.compile() catch {
    MissingEntry => ()
    _ => fail("expected MissingEntry")
  } noraise {
    _ => fail("expected MissingEntry")
  }
}

///|
test "GraphDefinition compile GRAPH-005 - unknown entry" {
  let unknown = NodeId::parse("unknown")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.set_entry(unknown)
  try definition.compile() catch {
    UnknownEntry(id) => inspect(id.to_string(), content="unknown")
    _ => fail("expected UnknownEntry")
  } noraise {
    _ => fail("expected UnknownEntry")
  }
}

///|
test "GraphDefinition compile GRAPH-006 - missing router" {
  let a = NodeId::parse("A")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, []))
  definition.set_entry(a)
  try definition.compile() catch {
    MissingRouter(id) => inspect(id.to_string(), content="A")
    _ => fail("expected MissingRouter")
  } noraise {
    _ => fail("expected MissingRouter")
  }
}

///|
test "GraphDefinition compile GRAPH-007 - unknown destination" {
  let a = NodeId::parse("A")
  let unknown = NodeId::parse("unknown")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, []))
  definition.set_router(a, to_router(unknown))
  definition.set_entry(a)
  try definition.compile() catch {
    UnknownDestination(from~, to~) => {
      inspect(from.to_string(), content="A")
      inspect(to.to_string(), content="unknown")
    }
    _ => fail("expected UnknownDestination")
  } noraise {
    _ => fail("expected UnknownDestination")
  }
}

///|
test "GraphDefinition compile GRAPH-008 - unreachable node" {
  let a = NodeId::parse("A")
  let b = NodeId::parse("B")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, []))
  definition.add_node(test_node(b, []))
  definition.set_router(a, end_router())
  definition.set_router(b, end_router())
  definition.set_entry(a)
  try definition.compile() catch {
    UnreachableNode(id) => inspect(id.to_string(), content="B")
    _ => fail("expected UnreachableNode")
  } noraise {
    _ => fail("expected UnreachableNode")
  }
}

///|
test "GraphDefinition compile GRAPH-009 - cyclic graph" {
  let a = NodeId::parse("A")
  let b = NodeId::parse("B")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, []))
  definition.add_node(test_node(b, []))
  definition.set_router(a, to_router(b))
  definition.set_router(b, to_router(a))
  definition.set_entry(a)
  inspect(definition.compile().entry().to_string(), content="A")
}

///|
test "GraphDefinition compile GRAPH-010 - single node routes to end" {
  let a = NodeId::parse("A")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, []))
  definition.set_router(a, end_router())
  definition.set_entry(a)
  inspect(definition.compile().entry().to_string(), content="A")
}

///|
test "GraphDefinition compile GRAPH-011 - compiled snapshot ignores builder mutation" {
  let a = NodeId::parse("A")
  let b = NodeId::parse("B")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, []))
  definition.set_router(a, end_router())
  definition.set_entry(a)
  let compiled = definition.compile()
  definition.add_node(test_node(b, []))
  definition.set_router(b, end_router())
  definition.set_entry(b)
  inspect(compiled.entry().to_string(), content="A")
  try compiled.get_node(b) catch {
    NodeNotFound(id) => inspect(id.to_string(), content="B")
    _ => fail("expected NodeNotFound")
  } noraise {
    _ => fail("expected NodeNotFound")
  }
}

///|
test "CompiledGraph queries GRAPH-012 - router targets and node tags have no mutable aliases" {
  let a = NodeId::parse("A")
  let b = NodeId::parse("B")
  let declared_routes = [DeclaredRoute::DeclaredRoute(b)]
  let tags = ["original"]
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, ReadOnlyArray::from_array(tags)))
  definition.add_node(test_node(b, []))
  definition.set_router(
    a,
    router(ReadOnlyArray::from_array(declared_routes), fn(_state, _completion) {
      To(b)
    }),
  )
  definition.set_router(b, end_router())
  definition.set_entry(a)
  let compiled = definition.compile()
  declared_routes[0] = DeclaredRoute::DeclaredRoute(a)
  tags[0] = "mutated"
  let queried_router = compiled.get_router(a)
  let queried_node = compiled.get_node(a)
  inspect(queried_router.declared_routes[0].target.to_string(), content="B")
  inspect(queried_node.metadata.tags[0], content="original")
  let returned_routes = [..queried_router.declared_routes]
  let returned_tags = [..queried_node.metadata.tags]
  returned_routes[0] = DeclaredRoute::DeclaredRoute(a)
  returned_tags[0] = "returned mutation"
  inspect(
    compiled.get_router(a).declared_routes[0].target.to_string(),
    content="B",
  )
  inspect(compiled.get_node(a).metadata.tags[0], content="original")
}

///|
test "GraphDefinition compile - unknown router source" {
  let a = NodeId::parse("A")
  let unknown = NodeId::parse("unknown")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(a, []))
  definition.set_router(a, end_router())
  definition.set_router(unknown, end_router())
  definition.set_entry(a)
  try definition.compile() catch {
    UnknownRouterSource(id) => inspect(id.to_string(), content="unknown")
    _ => fail("expected UnknownRouterSource")
  } noraise {
    _ => fail("expected UnknownRouterSource")
  }
}

///|
test "CompiledGraph snapshot - returns sorted callback-free structure" {
  let a = NodeId::parse("A")
  let b = NodeId::parse("B")
  let definition = GraphDefinition::GraphDefinition(test_reducer())
  definition.add_node(test_node(b, ["second"]))
  definition.add_node(test_node(a, ["first"]))
  definition.set_router(b, end_router())
  definition.set_router(a, to_router(b))
  definition.set_entry(a)
  debug_inspect(
    definition.compile().snapshot(),
    content=(
      #|{
      #|  entry: NodeId("A"),
      #|  nodes: <ReadOnlyArray:
      #|    [
      #|      {
      #|        id: NodeId("A"),
      #|        metadata: {
      #|          name: "A",
      #|          description: None,
      #|          kind: Function,
      #|          tags: <ReadOnlyArray: ["first"]>,
      #|        },
      #|        router_metadata: { description: None },
      #|        declared_routes: <ReadOnlyArray: [{ target: NodeId("B"), metadata: { label: None } }]>,
      #|      },
      #|      {
      #|        id: NodeId("B"),
      #|        metadata: {
      #|          name: "B",
      #|          description: None,
      #|          kind: Function,
      #|          tags: <ReadOnlyArray: ["second"]>,
      #|        },
      #|        router_metadata: { description: None },
      #|        declared_routes: <ReadOnlyArray: []>,
      #|      },
      #|    ]>,
      #|}
    ),
  )
}
