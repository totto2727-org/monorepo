///|
fn test_node(
  id : @core.NodeId,
  name : String,
  kind : @core.NodeKind,
  description? : String,
) -> @core.Node[Int, Unit] {
  @core.Node::Node(
    id,
    @core.NodeMetadata::NodeMetadata(name, description, kind, []),
    async fn(_context, _state) {
      @async.pause()
      @core.NodeOutput::NodeOutput(None, None, [])
    },
  )
}

///|
test "to_mermaid - renders escaped metadata and declared routes deterministically" {
  let first = @core.NodeId::parse("a#node")
  let second = @core.NodeId::parse("b-node")
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(state, _patch) { state }),
  )
  definition.add_node(
    test_node(second, "Review <result>", @core.Custom("human & agent")),
  )
  definition.add_node(
    test_node(
      first,
      "Plan \"safe\"",
      @core.Function,
      description="Prepare <inputs>",
    ),
  )
  definition.set_router(
    second,
    @core.router([], fn(_state, _completion) { @core.End }),
  )
  definition.set_router(
    first,
    @core.router(
      [
        @core.DeclaredRoute::DeclaredRoute(
          second,
          metadata=@core.DeclaredRouteMetadata::DeclaredRouteMetadata(
            label="continue & verify",
          ),
        ),
      ],
      fn(_state, _completion) { @core.To(second) },
    ),
  )
  definition.set_entry(first)
  inspect(
    to_mermaid(definition.compile()),
    content=(
      #|flowchart TD
      #|  node_0["Plan #quot;safe#quot; [a#35;node] / Function<br/>Prepare #60;inputs#62;"]
      #|  node_1["Review #60;result#62; [b-node] / Custom: human #38; agent"]
      #|  graph_entry(["Entry"]) --> node_0
      #|  node_0 -->|continue #38; verify| node_1
      #|
    ),
  )
}

///|
test "to_mermaid - renders a multi-target router as a branch" {
  let first = @core.NodeId::parse("a")
  let second = @core.NodeId::parse("b")
  let third = @core.NodeId::parse("c")
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(state, _patch) { state }),
  )
  definition.add_node(test_node(third, "Third", @core.Function))
  definition.add_node(test_node(first, "First", @core.Llm))
  definition.add_node(test_node(second, "Second", @core.CodingAgent))
  definition.set_router(
    first,
    @core.router(
      [
        @core.DeclaredRoute::DeclaredRoute(
          third,
          metadata=@core.DeclaredRouteMetadata::DeclaredRouteMetadata(
            label="failed",
          ),
        ),
        @core.DeclaredRoute::DeclaredRoute(
          second,
          metadata=@core.DeclaredRouteMetadata::DeclaredRouteMetadata(
            label="passed",
          ),
        ),
      ],
      fn(_state, _completion) { @core.To(second) },
      metadata=@core.RouterMetadata::RouterMetadata(
        description="Verification result",
      ),
    ),
  )
  definition.set_router(
    second,
    @core.router([], fn(_state, _completion) { @core.End }),
  )
  definition.set_router(
    third,
    @core.router([], fn(_state, _completion) { @core.End }),
  )
  definition.set_entry(first)
  inspect(
    to_mermaid(definition.compile()),
    content=(
      #|flowchart TD
      #|  node_0["First [a] / LLM"]
      #|  node_1["Second [b] / Coding Agent"]
      #|  node_2["Third [c] / Function"]
      #|  graph_entry(["Entry"]) --> node_0
      #|  node_0 --> router_0{"Verification result"}
      #|  router_0 -->|passed| node_1
      #|  router_0 -->|failed| node_2
      #|
    ),
  )
}
