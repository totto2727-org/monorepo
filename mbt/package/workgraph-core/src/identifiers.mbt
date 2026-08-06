///|
pub struct NodeId(String) derive(Eq, Hash, Debug)

///|
pub struct RunId(String) derive(Eq, Hash, Debug)

///|
pub struct ResourceKey(String) derive(Eq, Hash, Debug)

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
pub fn NodeId::parse(value : String) -> NodeId raise IdError {
  NodeId(parse_id(value, "NodeId"))
}

///|
pub fn NodeId::to_string(self : NodeId) -> String {
  let NodeId(value) = self
  value
}

///|
pub fn RunId::parse(value : String) -> RunId raise IdError {
  RunId(parse_id(value, "RunId"))
}

///|
pub fn RunId::to_string(self : RunId) -> String {
  let RunId(value) = self
  value
}

///|
pub fn ResourceKey::parse(value : String) -> ResourceKey raise IdError {
  ResourceKey(parse_id(value, "ResourceKey"))
}

///|
pub fn ResourceKey::to_string(self : ResourceKey) -> String {
  let ResourceKey(value) = self
  value
}
