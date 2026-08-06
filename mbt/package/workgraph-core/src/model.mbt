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
pub struct NodeMetadata {
  name : String
  description : String?
  kind : NodeKind
  tags : ReadOnlyArray[String]
} derive(Debug)

///|
/// Creates metadata describing a graph node.
pub fn NodeMetadata::NodeMetadata(
  name~ : String,
  description~ : String?,
  kind~ : NodeKind,
  tags~ : ReadOnlyArray[String],
) -> NodeMetadata {
  NodeMetadata::{ name, description, kind, tags }
}

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
pub struct Artifact {
  kind : ArtifactKind
  name : String
  uri : String?
  metadata : Json?
} derive(Debug)

///|
/// Creates an artifact emitted by a graph node.
pub fn Artifact::Artifact(
  kind~ : ArtifactKind,
  name~ : String,
  uri~ : String?,
  metadata~ : Json?,
) -> Artifact {
  Artifact::{ kind, name, uri, metadata }
}

///|
pub struct NodeOutput[P] {
  patch : P?
  value : Json?
  artifacts : ReadOnlyArray[Artifact]
} derive(Debug)

///|
/// Creates the output produced by a graph node.
pub fn[P] NodeOutput::NodeOutput(
  patch : P?,
  value : Json?,
  artifacts : ReadOnlyArray[Artifact],
) -> NodeOutput[P] {
  NodeOutput::{ patch, value, artifacts }
}

///|
pub struct NodeCompletion {
  node_id : NodeId
  value : Json?
  artifacts : ReadOnlyArray[Artifact]
} derive(Debug)

///|
/// Creates the completion value passed to a router.
pub fn NodeCompletion::NodeCompletion(
  node_id : NodeId,
  value : Json?,
  artifacts : ReadOnlyArray[Artifact],
) -> NodeCompletion {
  NodeCompletion::{ node_id, value, artifacts }
}

///|
pub enum GraphEvent {
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
/// Creates the event emitted when a run starts.
pub fn run_started_event(run_id : RunId) -> GraphEvent {
  RunStarted(run_id)
}

///|
/// Creates the event emitted when a run completes.
pub fn run_completed_event(run_id : RunId, steps : Int) -> GraphEvent {
  RunCompleted(run_id~, steps~)
}

///|
/// Creates the event emitted before a runtime resource is opened.
pub fn resource_opening_event(run_id : RunId, key : ResourceKey) -> GraphEvent {
  ResourceOpening(run_id~, key~)
}

///|
/// Creates the event emitted after a runtime resource is opened.
pub fn resource_opened_event(run_id : RunId, key : ResourceKey) -> GraphEvent {
  ResourceOpened(run_id~, key~)
}

///|
/// Creates the event emitted after a runtime resource is closed.
pub fn resource_closed_event(run_id : RunId, key : ResourceKey) -> GraphEvent {
  ResourceClosed(run_id~, key~)
}

///|
pub struct EventSink {
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
pub struct NodeContext {
  run_id : RunId
  node_id : NodeId
  step : Int
  deadline_ms : Int64?
  task_group : @async.TaskGroup[Unit]
  events : EventSink
  resources : ResourceStore
}

///|
pub fn NodeContext::NodeContext(
  run_id : RunId,
  node_id : NodeId,
  step : Int,
  task_group : @async.TaskGroup[Unit],
  events? : EventSink = EventSink::discard(),
  resources? : ResourceStore = ResourceStore(),
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
pub struct Node[S, P] {
  id : NodeId
  metadata : NodeMetadata
  execute : async (NodeContext, S) -> NodeOutput[P]
}

///|
pub fn[S, P] Node::Node(
  id : NodeId,
  metadata : NodeMetadata,
  execute : async (NodeContext, S) -> NodeOutput[P],
) -> Node[S, P] {
  Node::{ id, metadata, execute }
}

///|
/// Contains optional display metadata for one statically declared route.
pub struct DeclaredRouteMetadata {
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
pub struct DeclaredRoute {
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
pub struct RouterMetadata {
  description : String?
} derive(Debug)

///|
/// Creates display metadata for a router.
pub fn RouterMetadata::RouterMetadata(description? : String) -> RouterMetadata {
  RouterMetadata::{ description, }
}

///|
pub struct Router[S] {
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
pub struct Reducer[S, P] {
  apply : (S, P) -> S raise
}

///|
/// Creates a state reducer from its transition function.
pub fn[S, P] Reducer::Reducer(apply : (S, P) -> S raise) -> Reducer[S, P] {
  Reducer::{ apply, }
}
