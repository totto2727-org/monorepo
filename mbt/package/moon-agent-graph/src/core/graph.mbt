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
  self.routers[from] = router(value.declared_targets, value.evaluate)
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
  router(value.declared_targets, value.evaluate)
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
    for target in value.declared_targets {
      guard nodes.contains(target) else {
        raise UnknownDestination(from=source, to=target)
      }
    }
  }
  let reachable : Set[NodeId] = Set::default()
  let pending = [entry]
  while pending.pop() is Some(node_id) {
    if reachable.add_and_check(node_id) {
      let value = routers[node_id]
      for target in value.declared_targets {
        if !reachable.contains(target) {
          pending.push(target)
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
