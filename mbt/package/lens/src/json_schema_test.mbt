///|
test "LensTrait to_json_schema - renders a nested required string" {
  @json.json_inspect(@lens.object("user").string("name").to_json_schema(), content={
    "type": "object",
    "properties": {
      "user": {
        "type": "object",
        "properties": { "name": { "type": "string" } },
        "required": ["name"],
      },
    },
    "required": ["user"],
  })
}

///|
test "LensTrait to_json_schema - renders optional nullable array items" {
  @json.json_inspect(
    @lens.root().string("tags").array().nullable().optional().to_json_schema(),
    content={
      "type": "object",
      "properties": {
        "tags": { "type": ["array", "null"], "items": { "type": "string" } },
      },
    },
  )
}

///|
test "json_schema - combines heterogeneous validator checks" {
  let user = @lens.object("user")
  @json.json_inspect(
    @lens.json_schema([
      user.string("name"),
      user.int("age"),
      user.bool("active").nullish(),
    ]),
    content={
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "properties": {
        "user": {
          "type": "object",
          "properties": {
            "name": { "type": "string" },
            "age": { "type": "number" },
            "active": { "type": ["boolean", "null"] },
          },
          "required": ["name", "age"],
        },
      },
      "required": ["user"],
    },
  )
}

///|
test "json_schema - renders object and unconstrained raw JSON checks" {
  let root = @lens.root()
  @json.json_inspect(
    @lens.json_schema([root.object("payload"), root.json("metadata")]),
    content={
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "properties": {
        "payload": { "type": "object" },
        "metadata": Json::empty_object(),
      },
      "required": ["payload", "metadata"],
    },
  )
}

///|
test "json_schema - intersects compatible declarations at one property" {
  let name = @lens.root().string("name")
  @json.json_inspect(@lens.json_schema([name.nullable(), name]), content={
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": { "name": { "type": "string" } },
    "required": ["name"],
  })
}

///|
test "json_schema - renders incompatible declarations as false" {
  let root = @lens.root()
  @json.json_inspect(
    @lens.json_schema([root.string("value"), root.bool("value")]),
    content={
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "properties": { "value": false },
      "required": ["value"],
    },
  )
}

///|
test "json_schema - renders an unconstrained empty validator" {
  @json.json_inspect(@lens.json_schema([]), content={
    "$schema": "https://json-schema.org/draft/2020-12/schema",
  })
}
