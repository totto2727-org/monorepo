///|
fn example_id(value : String) -> @core.NodeId {
  @core.NodeId::parse(value) catch {
    _ => abort("static example node ID must be valid")
  }
}

///|
fn example_metadata(name : String) -> @core.NodeMetadata {
  { name, description: None, kind: @core.Function, tags: [] }
}

///|
fn example_node(
  id : @core.NodeId,
  label : String,
) -> @core.Node[Array[String], String] {
  @core.function_node(id, example_metadata(label), async fn(_context, _state) {
    @async.pause()
    @core.NodeOutput::{ patch: Some(label), value: None, artifacts: [] }
  })
}

///|
async fn main {
  let plan = example_id("plan")
  let verify = example_id("test")
  let definition = @core.GraphDefinition::GraphDefinition(@core.Reducer::{
    apply: fn(state, patch) { [..state, patch] },
  })
  definition.add_node(example_node(plan, "plan"))
  definition.add_node(example_node(verify, "test"))
  definition.set_router(
    plan,
    @core.router([@core.DeclaredRoute::DeclaredRoute(verify)], fn(
      _state,
      _completion,
    ) {
      @core.To(verify)
    }),
  )
  definition.set_router(
    verify,
    @core.router([], fn(_state, _completion) { @core.End }),
  )
  definition.set_entry(plan)
  let runtime = @core.GraphRuntime::GraphRuntime(definition.compile())
  let result = runtime.invoke([])
  println("labels=\{result.final_state.join(",")}")
  println("steps=\{result.steps}")
}
