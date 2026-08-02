///|
priv enum SchemaShape {
  AnySchema
  StringSchema
  BooleanSchema
  NumberSchema
  ObjectSchema
  ArraySchema(SchemaShape)
  NullableSchema(SchemaShape)
}

///|
fn SchemaShape::nullable(self : SchemaShape) -> SchemaShape {
  match self {
    AnySchema => AnySchema
    NullableSchema(_) => self
    _ => NullableSchema(self)
  }
}

///|
fn SchemaShape::type_names(self : SchemaShape) -> Array[String] {
  match self {
    AnySchema => []
    StringSchema => ["string"]
    BooleanSchema => ["boolean"]
    NumberSchema => ["number"]
    ObjectSchema => ["object"]
    ArraySchema(_) => ["array"]
    NullableSchema(shape) => [..shape.type_names(), "null"]
  }
}

///|
fn SchemaShape::items(self : SchemaShape) -> Json? {
  match self {
    ArraySchema(item_shape) => Some(item_shape.to_json())
    NullableSchema(shape) => shape.items()
    _ => None
  }
}

///|
fn SchemaShape::to_json(self : SchemaShape) -> Json {
  let properties : Map[String, Json] = Map([])
  let type_names = self.type_names()
  match type_names {
    [] => ()
    [type_name] => properties["type"] = type_name.to_json()
    _ =>
      properties["type"] = Json::array(
        type_names.map(type_name => type_name.to_json()),
      )
  }
  match self.items() {
    Some(items) => properties["items"] = items
    None => ()
  }
  Json::object(properties)
}

///|
fn property_schema(key : String, value_schema : Json, required : Bool) -> Json {
  let properties : Map[String, Json] = Map([])
  properties["type"] = "object".to_json()
  let property_schemas : Map[String, Json] = Map([])
  property_schemas[key] = value_schema
  properties["properties"] = Json::object(property_schemas)
  if required {
    properties["required"] = Json::array([key.to_json()])
  }
  Json::object(properties)
}

///|
fn indexed_schema(index : Int, value_schema : Json, required : Bool) -> Json {
  let prefix_items = Array::makei(index + 1, item_index => {
    if item_index == index {
      value_schema
    } else {
      Json::empty_object()
    }
  })
  let properties : Map[String, Json] = {
    "type": "array".to_json(),
    "prefixItems": Json::array(prefix_items),
  }
  if required {
    properties["minItems"] = (index + 1).to_json()
  }
  Json::object(properties)
}

///|
fn[T] Lens::schema_fragment(self : Lens[T]) -> Json {
  let (_, schema) = self.pointer.segments.rev_fold(
    init=(true, self.schema_shape.to_json()),
    (state, segment) => {
      let (is_leaf, child_schema) = state
      let required = if is_leaf { self.schema_required } else { true }
      let parent_schema = match segment {
        Key(key) => property_schema(key, child_schema, required)
        Index(index) => indexed_schema(index, child_schema, required)
      }
      (false, parent_schema)
    },
  )
  schema
}

///|
/// Generates a Draft 2020-12 JSON Schema for the same heterogeneous lens set
/// accepted by `validate`.
///
/// Each lens contributes one conjunct so incompatible duplicate declarations
/// remain incompatible instead of overwriting one another.
pub fn json_schema(lenses : Array[&LensTrait]) -> Json {
  let schema : Map[String, Json] = {
    "$schema": "https://json-schema.org/draft/2020-12/schema".to_json(),
  }
  if !lenses.is_empty() {
    schema["allOf"] = Json::array(
      lenses.map(lens => LensTrait::to_json_schema(lens)),
    )
  }
  Json::object(schema)
}
