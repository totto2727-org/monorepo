///|
pub struct CodingAgentNodeSpec[S, P] {
  agent : CodingAgent
  resource_key : @core.ResourceKey
  resource_scope : @core.ResourceScope
  open_context : (@core.NodeContext, S) -> CodingAgentOpenContext raise
  build_request : (@core.NodeContext, S) -> CodingAgentRequest raise
  decode_response : (S, CodingAgentResponse) -> @core.NodeOutput[P] raise
}

///|
/// Creates the callbacks and resource policy used by a coding-agent node.
pub fn[S, P] CodingAgentNodeSpec::CodingAgentNodeSpec(
  agent~ : CodingAgent,
  resource_key~ : @core.ResourceKey,
  resource_scope~ : @core.ResourceScope,
  open_context~ : (@core.NodeContext, S) -> CodingAgentOpenContext raise,
  build_request~ : (@core.NodeContext, S) -> CodingAgentRequest raise,
  decode_response~ : (S, CodingAgentResponse) -> @core.NodeOutput[P] raise,
) -> CodingAgentNodeSpec[S, P] {
  CodingAgentNodeSpec::{
    agent,
    resource_key,
    resource_scope,
    open_context,
    build_request,
    decode_response,
  }
}

///|
priv struct CodingAgentResource {
  session : &CodingAgentSession
}

///|
impl Debug for CodingAgentResource with fn to_repr(_self) {
  @debug.Repr::literal("CodingAgentResource")
}

///|
extenum @any.Payload += {
  CodingAgentResource(CodingAgentResource)
}

///|
impl @any.Anyable for CodingAgentResource with fn iso() {
  {
    id: @any.TypeId::TypeId(
      "totto2727/workgraph-agent-cli",
      "CodingAgentResource",
      [],
    ),
    box: resource => CodingAgentResource(resource),
    unbox: payload => {
      guard payload is CodingAgentResource(resource)
      resource
    },
  }
}

///|
fn coding_agent_resource_ref(
  key : @core.ResourceKey,
) -> @any_collection.AnyRef[@core.ResourceKey, CodingAgentResource] {
  @any_collection.AnyRef::AnyRef(key)
}

///|
/// Create a graph node that acquires a coding-agent session, executes a request, and decodes its response.
pub fn[S, P] coding_agent_node(
  id : @core.NodeId,
  metadata : @core.NodeMetadata,
  spec : CodingAgentNodeSpec[S, P],
) -> @core.Node[S, P] {
  @core.Node::Node(id, metadata, async fn(context, state) {
    let open_context = (spec.open_context)(context, state)
    let reference = coding_agent_resource_ref(spec.resource_key)
    let resource = match spec.resource_scope {
      @core.Node =>
        context.resources.acquire_resource(
          reference,
          @core.Node,
          async fn() {
            CodingAgentResource::{ session: (spec.agent.open)(open_context) }
          },
          async fn(resource) { resource.session.close() },
          owner=context.node_id,
        )
      @core.Run =>
        context.resources.acquire_resource(
          reference,
          @core.Run,
          async fn() {
            CodingAgentResource::{ session: (spec.agent.open)(open_context) }
          },
          async fn(resource) { resource.session.close() },
        )
    }
    let request = (spec.build_request)(context, state)
    let response = resource.session.execute(request)
    (spec.decode_response)(state, response)
  })
}
