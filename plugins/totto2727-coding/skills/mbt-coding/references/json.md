# MoonBit JSON

> Document type: concrete MoonBit implementation guidance.

Keep `Json` at the serialization boundary. Decode incoming JSON into an external response type, convert that response into a validated domain type, and expose only the domain type to internal application layers. For outbound data, convert the domain type into a dedicated request type and call its `ToJson` implementation at the wire boundary.

Never pass a generic `Json` value, `Map[String, Json]`, or serialized JSON string through internal services when the structure is known. Never build JSON by concatenating strings. Prefer direct `Json::object({ ... })` construction, pattern matching for variants, and explicit `ToJson` implementations for external request types.

Use `Map[String, Json]` only when the wire format distinguishes omitted fields from explicit `Json::null()` values, or when a dynamic key set cannot be expressed directly with `Json::object({ ... })`. When omission is required by an external API, keep the map inside the one `to_json` implementation that needs it.

## Lens initialization

Define and compose typed lenses once instead of rebuilding them for every request. Eager lens construction is normally negligible in a small application, so keep the straightforward eager definition unless startup measurements identify it as a bottleneck.

An application that defines hundreds of lenses may spend a meaningful part of its startup time constructing lens paths that are not used in every run. When measurements show that lens initialization is a startup bottleneck, split the lenses into independently used groups, wrap each group in [`@lazy.Lazy`](https://mooncakes.io/docs/moonbitlang/core/lazy), and call `force` at the group's first use. This defers construction and leaves groups that are never used uninitialized.

```mbt
struct UserLenses {
  name : @lens.Lens[String]
  age : @lens.Lens[Int]
}

let user_lenses : @lazy.Lazy[UserLenses] = @lazy.Lazy(() => {
  let user = @lens.object("user")
  UserLenses::{ name: user.string("name"), age: user.int("age") }
})

fn read_user(document : Json) -> User raise {
  let lenses = user_lenses.force()
  User::{ name: lenses.name.get(document), age: lenses.age.get(document) }
}
```

Do not introduce `Lazy` solely because lenses are present. It adds deferred-cell and `force` overhead, and it does not reduce startup work when every lens group is forced immediately.

See [`boundary-conversion.md`](boundary-conversion.md) for the full ingress, domain, and egress pipeline.
