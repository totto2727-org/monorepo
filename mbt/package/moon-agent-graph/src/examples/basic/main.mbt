///|
struct ExampleState {
  labels : Array[String]
} derive(Debug, Eq, FromJson, ToJson)

///|
struct ExampleRuntimeResource {
  visits : Ref[Int]
} derive(Debug)

///|
extenum @any.Payload += {
  ExampleRuntimeResource(ExampleRuntimeResource)
}

///|
impl @any.Anyable for ExampleRuntimeResource with fn iso() {
  {
    id: @any.TypeId::TypeId(
      "totto2727/moon-agent-graph/examples/basic",
      "ExampleRuntimeResource",
      [],
    ),
    box: resource => ExampleRuntimeResource(resource),
    unbox: payload => {
      guard payload is ExampleRuntimeResource(resource)
      resource
    },
  }
}

///|
fn example_runtime_resource_ref() -> @any_collection.AnyRef[
  @core.ResourceKey,
  ExampleRuntimeResource,
] {
  @any_collection.AnyRef::AnyRef(
    @core.ResourceKey::parse("example-runtime-resource") catch {
      _ => abort("static example resource key must be valid")
    },
  )
}

///|
fn example_reducer() -> @core.Reducer[ExampleState, String] {
  @core.Reducer::{
    apply: fn(state, patch) { { labels: [..state.labels, patch] } },
  }
}

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
) -> @core.Node[ExampleState, String] {
  @core.function_node(id, example_metadata(label), async fn(context, _state) {
    @async.pause()
    let reference = example_runtime_resource_ref()
    let resource = match context.resources.get(reference) {
      Some(resource) => resource
      None => {
        let resource = ExampleRuntimeResource::{ visits: Ref(0) }
        context.resources.set(reference, resource)
        resource
      }
    }
    resource.visits.val = resource.visits.val + 1
    @core.NodeOutput::{
      patch: Some("\{label}:\{resource.visits.val}"),
      value: None,
      artifacts: [],
    }
  })
}

///|
async fn main {
  let plan = example_id("plan")
  let verify = example_id("test")
  let definition = @core.GraphDefinition::GraphDefinition(example_reducer())
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
  let result = runtime.invoke({ labels: [] })
  let snapshot = result.final_state.to_json()
  let restored : ExampleState = @json.from_json(snapshot)
  println("labels=\{restored.labels.join(",")}")
  println("snapshot=\{snapshot.stringify()}")
  println("steps=\{result.steps}")
}
