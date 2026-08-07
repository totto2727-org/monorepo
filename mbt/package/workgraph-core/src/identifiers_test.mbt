///|
test "NodeId parse ID-001 - creates an identifier from non-empty text" {
  let id = NodeId::NodeId("node-alpha")
  debug_inspect(id, content="NodeId(\"node-alpha\")")
}

///|
test "NodeId parse ID-002 - rejects empty text with the identifier kind" {
  let detail = try {
    NodeId::NodeId("") |> ignore
    "no error"
  } catch {
    EmptyId(kind~) => "EmptyId:\{kind}"
  }
  inspect(detail, content="EmptyId:NodeId")
}

///|
test "NodeId equality ID-003 - equal text creates equal identifiers" {
  let first = NodeId::NodeId("node-alpha")
  let second = NodeId::NodeId("node-alpha")
  inspect(first == second, content="true")
}

///|
test "NodeId equality ID-004 - different text creates unequal identifiers" {
  let first = NodeId::NodeId("node-alpha")
  let second = NodeId::NodeId("node-beta")
  inspect(first != second, content="true")
}

///|
test "NodeId Map ID-005 - retrieves a value by an equivalent identifier" {
  let values : Map[NodeId, String] = Map([])
  values[NodeId::NodeId("node-alpha")] = "retrieved"
  debug_inspect(
    values.get(NodeId::NodeId("node-alpha")),
    content="Some(\"retrieved\")",
  )
}

///|
test "NodeId to_string ID-006 - returns the original text" {
  let id = NodeId::NodeId("node-alpha")
  inspect(id.to_string(), content="node-alpha")
}

///|
test "Identifier family parse - non-empty strings round trip through every wrapper" {
  inspect(RunId::RunId("run-alpha").to_string(), content="run-alpha")
  inspect(
    ResourceKey::ResourceKey("resource-alpha").to_string(),
    content="resource-alpha",
  )
}

///|
test "Identifier family parse - empty strings report each wrapper kind" {
  let run_error = try {
    RunId::RunId("") |> ignore
    "no error"
  } catch {
    EmptyId(kind~) => "EmptyId:\{kind}"
  }
  let resource_error = try {
    ResourceKey::ResourceKey("") |> ignore
    "no error"
  } catch {
    EmptyId(kind~) => "EmptyId:\{kind}"
  }
  inspect(run_error, content="EmptyId:RunId")
  inspect(resource_error, content="EmptyId:ResourceKey")
}
