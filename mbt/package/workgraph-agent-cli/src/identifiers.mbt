///|
pub struct CodingAgentId {
  value : String
} derive(Eq, Hash, Debug)

///|
pub struct SessionId(String) derive(Eq, Hash, Debug)

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
pub fn CodingAgentId::CodingAgentId(
  value : String,
) -> CodingAgentId raise IdError {
  CodingAgentId::{ value: parse_id(value, "CodingAgentId") }
}

///|
pub fn CodingAgentId::to_string(self : CodingAgentId) -> String {
  self.value
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
