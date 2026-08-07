///|
fn node_kind_name(kind : @core.NodeKind) -> String {
  match kind {
    @core.Function => "Function"
    @core.Llm => "LLM"
    @core.CodingAgent => "Coding Agent"
    @core.Custom(name) => "Custom: \{name}"
  }
}

///|
fn escape_mermaid_label(value : String) -> String {
  value
  .replace_all(old="#", new="#35;")
  .replace_all(old="&", new="#38;")
  .replace_all(old="\"", new="#quot;")
  .replace_all(old="<", new="#60;")
  .replace_all(old=">", new="#62;")
  .replace_all(old="\r", new=" ")
  .replace_all(old="\n", new=" ")
}

///|
fn node_label(node : @core.CompiledNodeSnapshot) -> String {
  let summary = escape_mermaid_label(
    "\{node.metadata.name} [\{node.id.to_string()}] / \{node_kind_name(node.metadata.kind)}",
  )
  match node.metadata.description {
    Some(description) => "\{summary}<br/>\{escape_mermaid_label(description)}"
    None => summary
  }
}

///|
fn write_route_edge(
  output : StringBuilder,
  from : String,
  to : String,
  route : @core.DeclaredRoute,
) -> Unit {
  match route.metadata.label {
    Some(label) =>
      output.write_string(
        "  \{from} -->|\{escape_mermaid_label(label)}| \{to}\n",
      )
    None => output.write_string("  \{from} --> \{to}\n")
  }
}

///|
/// Renders a compiled graph as a deterministic Mermaid flowchart.
///
/// Node and router descriptions and declared route labels come from core
/// metadata. Routers with multiple declared destinations or descriptions are
/// rendered as decision diamonds. Runtime-only conditions, `End`, and `Fail`
/// outcomes are not inferred.
pub fn[S, P] to_mermaid(graph : @core.CompiledGraph[S, P]) -> String {
  let snapshot = graph.snapshot()
  let mermaid_ids : Map[@core.NodeId, String] = Map([])
  for index, node in snapshot.nodes {
    mermaid_ids[node.id] = "node_\{index}"
  }
  let output = StringBuilder::new()
  output.write_string("flowchart TD\n")
  for node in snapshot.nodes {
    output.write_string("  \{mermaid_ids[node.id]}[\"\{node_label(node)}\"]\n")
  }
  output.write_string(
    "  graph_entry([\"Entry\"]) --> \{mermaid_ids[snapshot.entry]}\n",
  )
  for index, node in snapshot.nodes {
    if node.declared_routes.length() > 1 ||
      node.router_metadata.description is Some(_) {
      let router_id = "router_\{index}"
      let router_label = match node.router_metadata.description {
        Some(description) => escape_mermaid_label(description)
        None => escape_mermaid_label("\{node.metadata.name} Router")
      }
      output.write_string(
        "  \{mermaid_ids[node.id]} --> \{router_id}{\"\{router_label}\"}\n",
      )
      for route in node.declared_routes {
        write_route_edge(output, router_id, mermaid_ids[route.target], route)
      }
    } else {
      for route in node.declared_routes {
        write_route_edge(
          output,
          mermaid_ids[node.id],
          mermaid_ids[route.target],
          route,
        )
      }
    }
  }
  output.to_string()
}
