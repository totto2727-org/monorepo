///|
/// One invocation recorded by a scripted node.
pub struct ScriptedNodeCall[S] {
  context : @core.NodeContext
  state : S
}

///|
/// A node fixture and its fixture-owned call history.
pub struct ScriptedNode[S, P] {
  value : @core.Node[S, P]
  calls_value : Array[ScriptedNodeCall[S]]
}

///|
/// Wraps a node callback and records every context and input state in order.
pub fn[S, P] scripted_node(
  id : @core.NodeId,
  metadata : @core.NodeMetadata,
  execute : async (@core.NodeContext, S) -> @core.NodeOutput[P],
) -> ScriptedNode[S, P] {
  let calls : Array[ScriptedNodeCall[S]] = []
  let value = @core.function_node(id, metadata, async fn(context, state) {
    calls.push({ context, state })
    execute(context, state)
  })
  { value, calls_value: calls }
}

///|
/// Returns the node passed to a graph definition.
pub fn[S, P] ScriptedNode::node(self : ScriptedNode[S, P]) -> @core.Node[S, P] {
  self.value
}

///|
/// Returns a snapshot of recorded node calls.
pub fn[S, P] ScriptedNode::calls(
  self : ScriptedNode[S, P],
) -> ReadOnlyArray[ScriptedNodeCall[S]] {
  ReadOnlyArray::from_array([..self.calls_value])
}

///|
/// One invocation recorded by a scripted router.
pub struct ScriptedRouterCall[S] {
  state : S
  completion : @core.NodeCompletion
}

///|
/// A router fixture and its fixture-owned call history.
pub struct ScriptedRouter[S] {
  value : @core.Router[S]
  calls_value : Array[ScriptedRouterCall[S]]
}

///|
/// Wraps a router callback and records every state and completion in order.
pub fn[S] scripted_router(
  declared_targets : ReadOnlyArray[@core.NodeId],
  evaluate : (S, @core.NodeCompletion) -> @core.Route raise,
) -> ScriptedRouter[S] {
  let calls : Array[ScriptedRouterCall[S]] = []
  let declared_routes = declared_targets.map(target => {
    @core.DeclaredRoute::DeclaredRoute(target)
  })
  let value = @core.router(declared_routes, (state, completion) => {
    calls.push({ state, completion })
    evaluate(state, completion)
  })
  { value, calls_value: calls }
}

///|
/// Returns the router passed to a graph definition.
pub fn[S] ScriptedRouter::router(self : ScriptedRouter[S]) -> @core.Router[S] {
  self.value
}

///|
/// Returns a snapshot of recorded router calls.
pub fn[S] ScriptedRouter::calls(
  self : ScriptedRouter[S],
) -> ReadOnlyArray[ScriptedRouterCall[S]] {
  ReadOnlyArray::from_array([..self.calls_value])
}

///|
/// One invocation recorded by a reducer.
pub struct RecordingReducerCall[S, P] {
  state : S
  patch : P
}

///|
/// A reducer fixture and its fixture-owned call history.
pub struct RecordingReducer[S, P] {
  value : @core.Reducer[S, P]
  calls_value : Array[RecordingReducerCall[S, P]]
}

///|
/// Wraps a reducer callback and records every state and patch in order.
pub fn[S, P] recording_reducer(
  apply : (S, P) -> S raise,
) -> RecordingReducer[S, P] {
  let calls : Array[RecordingReducerCall[S, P]] = []
  let value = @core.Reducer::Reducer((state, patch) => {
    calls.push({ state, patch })
    apply(state, patch)
  })
  { value, calls_value: calls }
}

///|
/// Returns the reducer passed to a graph definition.
pub fn[S, P] RecordingReducer::reducer(
  self : RecordingReducer[S, P],
) -> @core.Reducer[S, P] {
  self.value
}

///|
/// Returns a snapshot of recorded reducer calls.
pub fn[S, P] RecordingReducer::calls(
  self : RecordingReducer[S, P],
) -> ReadOnlyArray[RecordingReducerCall[S, P]] {
  ReadOnlyArray::from_array([..self.calls_value])
}

///|
/// An event sink fixture with fixture-owned event history.
pub struct RecordingEventSink {
  value : @core.EventSink
  events_value : Array[@core.GraphEvent]
}

///|
/// Creates an event sink that records events in emission order.
pub fn recording_event_sink() -> RecordingEventSink {
  let events : Array[@core.GraphEvent] = []
  let value = @core.EventSink::EventSink(fn(event) { events.push(event) })
  { value, events_value: events }
}

///|
/// Returns the event sink passed to a graph runtime or context.
pub fn RecordingEventSink::event_sink(
  self : RecordingEventSink,
) -> @core.EventSink {
  self.value
}

///|
/// Returns a snapshot of recorded events.
pub fn RecordingEventSink::events(
  self : RecordingEventSink,
) -> ReadOnlyArray[@core.GraphEvent] {
  ReadOnlyArray::from_array([..self.events_value])
}
