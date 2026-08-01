///|
pub(all) enum Route {
  To(NodeId)
  End
  Fail(String)
} derive(Debug)

///|
pub(all) enum NodeKind {
  Function
  Llm
  CodingAgent
  Custom(String)
} derive(Debug, Eq)

///|
pub(all) struct NodeMetadata {
  name : String
  description : String?
  kind : NodeKind
  tags : ReadOnlyArray[String]
} derive(Debug)

///|
pub(all) enum ArtifactKind {
  File
  Directory
  Text
  Json
  CommandLog
  Custom(String)
} derive(Debug, Eq)

///|
pub(all) struct Artifact {
  kind : ArtifactKind
  name : String
  uri : String?
  metadata : Json?
} derive(Debug)

///|
pub(all) struct NodeOutput[P] {
  patch : P?
  value : Json?
  artifacts : ReadOnlyArray[Artifact]
} derive(Debug)

///|
pub(all) struct NodeCompletion {
  node_id : NodeId
  value : Json?
  artifacts : ReadOnlyArray[Artifact]
} derive(Debug)

///|
pub(all) enum GraphEvent {
  RunStarted(RunId)
  RunCompleted(run_id~ : RunId, steps~ : Int)
  RunFailed(run_id~ : RunId, cause~ : Error)
  RunCancelled(RunId)
  NodeStarted(run_id~ : RunId, node_id~ : NodeId, step~ : Int)
  NodeCompleted(
    run_id~ : RunId,
    node_id~ : NodeId,
    step~ : Int,
    completion~ : NodeCompletion
  )
  NodeFailed(run_id~ : RunId, node_id~ : NodeId, step~ : Int, cause~ : Error)
  StateUpdated(run_id~ : RunId, node_id~ : NodeId, step~ : Int)
  RouteSelected(run_id~ : RunId, from~ : NodeId, route~ : Route)
  ResourceOpening(run_id~ : RunId, key~ : ResourceKey)
  ResourceOpened(run_id~ : RunId, key~ : ResourceKey)
  ResourceClosed(run_id~ : RunId, key~ : ResourceKey)
} derive(Debug)

///|
pub(all) struct EventSink {
  emit : (GraphEvent) -> Unit raise
}

///|
pub fn EventSink::EventSink(emit : (GraphEvent) -> Unit raise) -> EventSink {
  EventSink::{ emit, }
}

///|
pub fn EventSink::discard() -> EventSink {
  EventSink(fn(_) { () })
}

///|
pub fn EventSink::try_emit(self : EventSink, event : GraphEvent) -> Unit {
  (self.emit)(event) catch {
    _ => ()
  }
}

///|
pub(all) struct NodeContext {
  run_id : RunId
  node_id : NodeId
  step : Int
  deadline_ms : Int64?
  task_group : @async.TaskGroup[Unit]
  events : EventSink
  resources : RuntimeResourceStore
}

///|
pub fn NodeContext::NodeContext(
  run_id : RunId,
  node_id : NodeId,
  step : Int,
  task_group : @async.TaskGroup[Unit],
  events? : EventSink = EventSink::discard(),
  resources? : RuntimeResourceStore = RuntimeResourceStore(),
  deadline_ms? : Int64,
) -> NodeContext {
  NodeContext::{
    run_id,
    node_id,
    step,
    deadline_ms,
    task_group,
    events,
    resources,
  }
}

///|
pub(all) struct Node[S, P] {
  id : NodeId
  metadata : NodeMetadata
  execute : async (NodeContext, S) -> NodeOutput[P]
}

///|
pub fn[S, P] function_node(
  id : NodeId,
  metadata : NodeMetadata,
  execute : async (NodeContext, S) -> NodeOutput[P],
) -> Node[S, P] {
  Node::{ id, metadata, execute }
}

///|
/// Contains optional display metadata for one statically declared route.
pub(all) struct DeclaredRouteMetadata {
  label : String?
} derive(Debug)

///|
/// Creates display metadata for a statically declared route.
pub fn DeclaredRouteMetadata::DeclaredRouteMetadata(
  label? : String,
) -> DeclaredRouteMetadata {
  DeclaredRouteMetadata::{ label, }
}

///|
/// Declares one possible runtime destination and its optional metadata.
pub(all) struct DeclaredRoute {
  target : NodeId
  metadata : DeclaredRouteMetadata
} derive(Debug)

///|
/// Declares a possible runtime destination.
pub fn DeclaredRoute::DeclaredRoute(
  target : NodeId,
  metadata? : DeclaredRouteMetadata = DeclaredRouteMetadata::DeclaredRouteMetadata(),
) -> DeclaredRoute {
  DeclaredRoute::{ target, metadata }
}

///|
/// Contains optional display metadata for a router.
pub(all) struct RouterMetadata {
  description : String?
} derive(Debug)

///|
/// Creates display metadata for a router.
pub fn RouterMetadata::RouterMetadata(description? : String) -> RouterMetadata {
  RouterMetadata::{ description, }
}

///|
pub(all) struct Router[S] {
  metadata : RouterMetadata
  declared_routes : ReadOnlyArray[DeclaredRoute]
  evaluate : (S, NodeCompletion) -> Route raise
}

///|
pub fn[S] router(
  declared_routes : ReadOnlyArray[DeclaredRoute],
  evaluate : (S, NodeCompletion) -> Route raise,
  metadata? : RouterMetadata = RouterMetadata::RouterMetadata(),
) -> Router[S] {
  Router::{ metadata, declared_routes, evaluate }
}

///|
pub(all) struct Reducer[S, P] {
  apply : (S, P) -> S raise
}
