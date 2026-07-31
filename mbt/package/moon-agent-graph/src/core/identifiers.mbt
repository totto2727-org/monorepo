///|
pub struct NodeId(String) derive(Eq, Hash, Debug)

///|
pub impl @copy.Copy for NodeId

///|
pub struct RunId(String) derive(Eq, Hash, Debug)

///|
pub struct ResourceKey(String) derive(Eq, Hash, Debug)

///|
pub struct CodingAgentId(String) derive(Eq, Hash, Debug)

///|
pub struct SessionId(String) derive(Eq, Hash, Debug)

///|
pub(all) suberror IdError {
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

///|
pub fn CodingAgentId::parse(value : String) -> CodingAgentId raise IdError {
  CodingAgentId(parse_id(value, "CodingAgentId"))
}

///|
pub fn CodingAgentId::to_string(self : CodingAgentId) -> String {
  let CodingAgentId(value) = self
  value
}

///|
pub fn SessionId::parse(value : String) -> SessionId raise IdError {
  SessionId(parse_id(value, "SessionId"))
}

///|
pub fn SessionId::to_string(self : SessionId) -> String {
  let SessionId(value) = self
  value
}
