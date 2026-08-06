///|
pub struct NodeId {
  value : String
} derive(Eq, Hash, Debug)

///|
pub struct RunId {
  value : String
} derive(Eq, Hash, Debug)

///|
pub struct ResourceKey {
  value : String
} derive(Eq, Hash, Debug)

///|
pub suberror IdError {
  EmptyId(kind~ : String)
} derive(Debug)

///|
fn parse_id(value : String, kind : String) -> String raise IdError {
  guard !value.is_empty() else { raise EmptyId(kind~) }
  value
}

///|
pub fn NodeId::NodeId(value : String) -> NodeId raise IdError {
  NodeId::{ value: parse_id(value, "NodeId") }
}

///|
pub fn NodeId::to_string(self : NodeId) -> String {
  self.value
}

///|
pub fn RunId::RunId(value : String) -> RunId raise IdError {
  RunId::{ value: parse_id(value, "RunId") }
}

///|
pub fn RunId::to_string(self : RunId) -> String {
  self.value
}

///|
pub fn ResourceKey::ResourceKey(value : String) -> ResourceKey raise IdError {
  ResourceKey::{ value: parse_id(value, "ResourceKey") }
}

///|
pub fn ResourceKey::to_string(self : ResourceKey) -> String {
  self.value
}
