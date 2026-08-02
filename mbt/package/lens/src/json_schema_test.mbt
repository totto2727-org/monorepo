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
      "allOf": [
        {
          "type": "object",
          "properties": {
            "user": {
              "type": "object",
              "properties": { "name": { "type": "string" } },
              "required": ["name"],
            },
          },
          "required": ["user"],
        },
        {
          "type": "object",
          "properties": {
            "user": {
              "type": "object",
              "properties": { "age": { "type": "number" } },
              "required": ["age"],
            },
          },
          "required": ["user"],
        },
        {
          "type": "object",
          "properties": {
            "user": {
              "type": "object",
              "properties": { "active": { "type": ["boolean", "null"] } },
            },
          },
          "required": ["user"],
        },
      ],
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
      "allOf": [
        {
          "type": "object",
          "properties": { "payload": { "type": "object" } },
          "required": ["payload"],
        },
        {
          "type": "object",
          "properties": { "metadata": Json::empty_object() },
          "required": ["metadata"],
        },
      ],
    },
  )
}

///|
test "json_schema - renders an unconstrained empty validator" {
  @json.json_inspect(@lens.json_schema([]), content={
    "$schema": "https://json-schema.org/draft/2020-12/schema",
  })
}
