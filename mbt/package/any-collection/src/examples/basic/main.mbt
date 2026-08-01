///|
struct RequestContext {
  request_id : String
  retry_count : Int
} derive(Debug, Eq)

///|
extenum @any.Payload += {
  RequestContext(RequestContext)
}

///|
impl @any.Anyable for RequestContext with fn iso() {
  {
    id: @any.TypeId::TypeId(
      "totto2727/any-collection/examples/basic",
      "RequestContext",
      [],
    ),
    box: context => RequestContext(context),
    unbox: payload => {
      guard payload is RequestContext(context)
      context
    },
  }
}

///|
fn main {
  let request_id : @any_collection.AnyRef[String, String] = @any_collection.AnyRef::AnyRef(
    "request_id",
  )
  let retry_count : @any_collection.AnyRef[String, Int] = @any_collection.AnyRef::AnyRef(
    "retry_count",
  )
  let request_context : @any_collection.AnyRef[String, RequestContext] = @any_collection.AnyRef::AnyRef(
    "request_context",
  )
  let mutable = @any_collection.AnyMutableMap::AnyMutableMap([
    request_id.entry("mutable-request"),
    retry_count.entry(2),
    request_context.entry(RequestContext::{
      request_id: "mutable-custom",
      retry_count: 3,
    }),
  ])
  let immutable = @any_collection.AnyImmutableHashMap::AnyImmutableHashMap([
    request_id.entry("immutable-request"),
    request_context.entry(RequestContext::{
      request_id: "immutable-custom",
      retry_count: 4,
    }),
  ])
  guard mutable.map.contains(request_id.key) else {
    abort("missing mutable request ID key")
  }
  guard immutable.map.contains(request_id.key) else {
    abort("missing immutable request ID key")
  }
  guard mutable.get_or_none(request_id) is Some(mutable_request_id) else {
    abort("missing mutable request ID")
  }
  let retries = mutable.get_or(retry_count, 0)
  guard immutable.get_or_none(request_id) is Some(immutable_request_id) else {
    abort("missing immutable request ID")
  }
  guard mutable.get_or_none(request_context) is Some(mutable_context) else {
    abort("missing mutable custom context")
  }
  guard immutable.get_or_none(request_context) is Some(immutable_context) else {
    abort("missing immutable custom context")
  }
  println(
    mutable_request_id +
    "," +
    retries.to_string() +
    "," +
    immutable_request_id +
    "," +
    mutable_context.request_id +
    ":" +
    mutable_context.retry_count.to_string() +
    "," +
    immutable_context.request_id +
    ":" +
    immutable_context.retry_count.to_string(),
  )
}
