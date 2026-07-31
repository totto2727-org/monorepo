///|
pub(all) suberror GraphBuildError {
  DuplicateNode(NodeId)
  DuplicateRouter(NodeId)
  InvalidId(String)
} derive(Debug)

///|
pub(all) suberror GraphValidationError {
  MissingEntry
  UnknownEntry(NodeId)
  MissingRouter(NodeId)
  UnknownRouterSource(NodeId)
  UnknownDestination(from~ : NodeId, to~ : NodeId)
  UnreachableNode(NodeId)
} derive(Debug)

///|
pub(all) struct RunFailure {
  primary : Error
  cleanup : Array[Error]
} derive(Debug)

///|
pub(all) suberror GraphRuntimeError {
  NodeTimedOut(node_id~ : NodeId, step~ : Int, timeout_ms~ : Int)
  NodeFailed(node_id~ : NodeId, step~ : Int, cause~ : Error)
  ReduceFailed(node_id~ : NodeId, step~ : Int, cause~ : Error)
  RouteFailed(node_id~ : NodeId, step~ : Int, cause~ : Error)
  RouteContractViolated(from~ : NodeId, to~ : NodeId)
  StepLimitExceeded(limit~ : Int)
  ExplicitFailure(node_id~ : NodeId, message~ : String)
  ResourceCleanupFailed(failure~ : RunFailure)
  NodeNotFound(NodeId)
  RouterNotFound(NodeId)
} derive(Debug)

///|
pub struct GraphDefinition[S, P] {
  reducer : Reducer[S, P]
  nodes : Map[NodeId, Node[S, P]]
  routers : Map[NodeId, Router[S]]
  mut entry : NodeId?
}

///|
pub fn[S, P] GraphDefinition::GraphDefinition(
  reducer : Reducer[S, P],
) -> GraphDefinition[S, P] {
  { reducer, nodes: Map([]), routers: Map([]), entry: None }
}

///|
pub fn[S, P] GraphDefinition::add_node(
  self : GraphDefinition[S, P],
  node : Node[S, P],
) -> Unit raise GraphBuildError {
  guard !self.nodes.contains(node.id) else { raise DuplicateNode(node.id) }
  self.nodes[node.id] = node
}

///|
pub fn[S, P] GraphDefinition::set_router(
  self : GraphDefinition[S, P],
  from : NodeId,
  value : Router[S],
) -> Unit raise GraphBuildError {
  guard !self.routers.contains(from) else { raise DuplicateRouter(from) }
  self.routers[from] = copy_router(value)
}

///|
pub fn[S, P] GraphDefinition::set_entry(
  self : GraphDefinition[S, P],
  entry : NodeId,
) -> Unit raise GraphBuildError {
  guard !entry.to_string().is_empty() else { raise InvalidId("NodeId") }
  self.entry = Some(entry)
}

///|
fn[S] copy_router(value : Router[S]) -> Router[S] {
  router(
    value.declared_routes,
    value.evaluate,
    metadata=RouterMetadata::RouterMetadata(
      description?=value.metadata.description,
    ),
  )
}

///|
fn[S, P] copy_node(value : Node[S, P]) -> Node[S, P] {
  Node::{
    id: value.id,
    metadata: NodeMetadata::{
      name: value.metadata.name,
      description: value.metadata.description,
      kind: value.metadata.kind,
      tags: ReadOnlyArray::from_array([..value.metadata.tags]),
    },
    execute: value.execute,
  }
}

///|
fn[S, P] validate_graph(
  nodes : Map[NodeId, Node[S, P]],
  routers : Map[NodeId, Router[S]],
  entry : NodeId,
) -> Unit raise GraphValidationError {
  guard nodes.contains(entry) else { raise UnknownEntry(entry) }
  for source in routers.keys() {
    guard nodes.contains(source) else { raise UnknownRouterSource(source) }
  }
  for node_id in nodes.keys() {
    guard routers.contains(node_id) else { raise MissingRouter(node_id) }
  }
  for source, value in routers {
    for route in value.declared_routes {
      guard nodes.contains(route.target) else {
        raise UnknownDestination(from=source, to=route.target)
      }
    }
  }
  let reachable : Set[NodeId] = Set::default()
  let pending = [entry]
  while pending.pop() is Some(node_id) {
    if reachable.add_and_check(node_id) {
      let value = routers[node_id]
      for route in value.declared_routes {
        if !reachable.contains(route.target) {
          pending.push(route.target)
        }
      }
    }
  }
  for node_id in nodes.keys() {
    guard reachable.contains(node_id) else { raise UnreachableNode(node_id) }
  }
}

///|
pub fn[S, P] GraphDefinition::compile(
  self : GraphDefinition[S, P],
) -> CompiledGraph[S, P] raise GraphValidationError {
  let entry = self.entry.unwrap_or_error(MissingEntry)
  validate_graph(self.nodes, self.routers, entry)
  let nodes = self.nodes.map((_id, value) => copy_node(value))
  let routers = self.routers.map((_source, value) => copy_router(value))
  CompiledGraph::{ reducer: self.reducer, nodes, routers, entry }
}

///|
pub struct CompiledGraph[S, P] {
  reducer : Reducer[S, P]
  nodes : Map[NodeId, Node[S, P]]
  routers : Map[NodeId, Router[S]]
  entry : NodeId
}

///|
/// Describes one node in a compiled graph without exposing its callbacks.
pub(all) struct CompiledNodeSnapshot {
  id : NodeId
  metadata : NodeMetadata
  router_metadata : RouterMetadata
  declared_routes : ReadOnlyArray[DeclaredRoute]
} derive(Debug)

///|
/// Contains the callback-free static structure of a compiled graph.
pub(all) struct CompiledGraphSnapshot {
  entry : NodeId
  nodes : ReadOnlyArray[CompiledNodeSnapshot]
} derive(Debug)

///|
pub fn[S, P] CompiledGraph::entry(self : CompiledGraph[S, P]) -> NodeId {
  self.entry
}

///|
pub fn[S, P] CompiledGraph::get_node(
  self : CompiledGraph[S, P],
  id : NodeId,
) -> Node[S, P] raise GraphRuntimeError {
  self.nodes.get(id).unwrap_or_error(NodeNotFound(id))
}

///|
pub fn[S, P] CompiledGraph::get_router(
  self : CompiledGraph[S, P],
  id : NodeId,
) -> Router[S] raise GraphRuntimeError {
  copy_router(self.routers.get(id).unwrap_or_error(RouterNotFound(id)))
}

///|
/// Returns a deterministic, callback-free snapshot for inspection and tooling.
pub fn[S, P] CompiledGraph::snapshot(
  self : CompiledGraph[S, P],
) -> CompiledGraphSnapshot {
  let node_ids = self.nodes.keys().to_array()
  node_ids.sort_by((left, right) => left.to_string().compare(right.to_string()))
  let nodes = node_ids.map(node_id => {
    let node = self.nodes[node_id]
    let router = self.routers[node_id]
    let routes = [..router.declared_routes]
    routes.sort_by((left, right) => {
      left.target.to_string().compare(right.target.to_string())
    })
    CompiledNodeSnapshot::{
      id: node_id,
      metadata: NodeMetadata::{
        name: node.metadata.name,
        description: node.metadata.description,
        kind: node.metadata.kind,
        tags: ReadOnlyArray::from_array([..node.metadata.tags]),
      },
      router_metadata: RouterMetadata::RouterMetadata(
        description?=router.metadata.description,
      ),
      declared_routes: ReadOnlyArray::from_array(routes),
    }
  })
  CompiledGraphSnapshot::{
    entry: self.entry,
    nodes: ReadOnlyArray::from_array(nodes),
  }
}
