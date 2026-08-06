///|
fn example_node(
  id : @core.NodeId,
  name : String,
  kind : @core.NodeKind,
  description : String,
) -> @core.Node[Int, Unit] {
  @core.Node::Node(
    id,
    @core.NodeMetadata::NodeMetadata(
      name~,
      description=Some(description),
      kind~,
      tags=[],
    ),
    async fn(_context, _state) {
      @async.pause()
      @core.NodeOutput::NodeOutput(None, None)
    },
  )
}

///|
async fn main {
  @async.pause()
  let plan = @core.NodeId::parse("01-plan")
  let implement = @core.NodeId::parse("02-implement")
  let verify = @core.NodeId::parse("03-test")
  let fix = @core.NodeId::parse("04-fix")
  let review = @core.NodeId::parse("05-review")
  let release = @core.NodeId::parse("06-release")
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(state, _patch) { state }),
  )
  definition.add_node(example_node(plan, "Plan", @core.Llm, "Create a plan"))
  definition.add_node(
    example_node(implement, "Implement", @core.CodingAgent, "Write the change"),
  )
  definition.add_node(
    example_node(verify, "Test", @core.Function, "Run automated tests"),
  )
  definition.add_node(
    example_node(fix, "Fix", @core.CodingAgent, "Repair a failed change"),
  )
  definition.add_node(
    example_node(
      review,
      "Review",
      @core.Custom("Human review"),
      "Review the verified change",
    ),
  )
  definition.add_node(
    example_node(release, "Release", @core.Function, "Publish the result"),
  )
  definition.set_router(
    plan,
    @core.router([@core.DeclaredRoute::DeclaredRoute(implement)], fn(
      _state,
      _completion,
    ) {
      @core.To(implement)
    }),
  )
  definition.set_router(
    implement,
    @core.router([@core.DeclaredRoute::DeclaredRoute(verify)], fn(
      _state,
      _completion,
    ) {
      @core.To(verify)
    }),
  )
  definition.set_router(
    verify,
    @core.router(
      [
        @core.DeclaredRoute::DeclaredRoute(
          fix,
          metadata=@core.DeclaredRouteMetadata::DeclaredRouteMetadata(
            label="failed",
          ),
        ),
        @core.DeclaredRoute::DeclaredRoute(
          review,
          metadata=@core.DeclaredRouteMetadata::DeclaredRouteMetadata(
            label="passed",
          ),
        ),
      ],
      fn(state, _completion) {
        if state == 0 {
          @core.To(fix)
        } else {
          @core.To(review)
        }
      },
      metadata=@core.RouterMetadata::RouterMetadata(description="Test result"),
    ),
  )
  definition.set_router(
    fix,
    @core.router([@core.DeclaredRoute::DeclaredRoute(verify)], fn(
      _state,
      _completion,
    ) {
      @core.To(verify)
    }),
  )
  definition.set_router(
    review,
    @core.router(
      [
        @core.DeclaredRoute::DeclaredRoute(
          fix,
          metadata=@core.DeclaredRouteMetadata::DeclaredRouteMetadata(
            label="changes requested",
          ),
        ),
        @core.DeclaredRoute::DeclaredRoute(
          release,
          metadata=@core.DeclaredRouteMetadata::DeclaredRouteMetadata(
            label="approved",
          ),
        ),
      ],
      fn(state, _completion) {
        if state == 0 {
          @core.To(fix)
        } else {
          @core.To(release)
        }
      },
      metadata=@core.RouterMetadata::RouterMetadata(description="Review result"),
    ),
  )
  definition.set_router(
    release,
    @core.router([], fn(_state, _completion) { @core.End }),
  )
  definition.set_entry(plan)
  println(@renderer.to_mermaid(definition.compile()))
}
