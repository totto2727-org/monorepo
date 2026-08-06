///|
test "Coding agent identifiers - non-empty strings round trip" {
  inspect(
    CodingAgentId::CodingAgentId("agent-alpha").to_string(),
    content="agent-alpha",
  )
  inspect(
    SessionId::parse("session-alpha").to_string(),
    content="session-alpha",
  )
}

///|
test "Coding agent identifiers - empty strings report each wrapper kind" {
  let agent_error = try {
    CodingAgentId::CodingAgentId("") |> ignore
    "no error"
  } catch {
    EmptyId(kind~) => "EmptyId:\{kind}"
  }
  let session_error = try {
    SessionId::parse("") |> ignore
    "no error"
  } catch {
    EmptyId(kind~) => "EmptyId:\{kind}"
  }
  inspect(agent_error, content="EmptyId:CodingAgentId")
  inspect(session_error, content="EmptyId:SessionId")
}
