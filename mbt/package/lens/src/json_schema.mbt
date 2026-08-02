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
fn schema_type_names(value : Json) -> Array[String]? {
  match value {
    Json::String(name) => Some([name])
    Json::Array(values) => {
      let names : Array[String] = []
      for value in values {
        guard value is Json::String(name) else { return None }
        names.push(name)
      }
      Some(names)
    }
    _ => None
  }
}

///|
fn intersect_schema_types(left : Json, right : Json) -> Json? {
  guard schema_type_names(left) is Some(left_names) else { return None }
  guard schema_type_names(right) is Some(right_names) else { return None }
  match left_names.filter(name => right_names.contains(name)) {
    [] => None
    [name] => Some(name.to_json())
    names => Some(Json::array(names.map(name => name.to_json())))
  }
}

///|
fn required_names(value : Json) -> Array[String]? {
  guard value is Json::Array(values) else { return None }
  let names : Array[String] = []
  for value in values {
    guard value is Json::String(name) else { return None }
    names.push(name)
  }
  Some(names)
}

///|
fn merge_required(left : Json, right : Json) -> Json? {
  guard required_names(left) is Some(left_names) else { return None }
  guard required_names(right) is Some(right_names) else { return None }
  let names = right_names.fold(init=left_names, (names, name) => {
    if names.contains(name) {
      names
    } else {
      [..names, name]
    }
  })
  Some(Json::array(names.map(name => name.to_json())))
}

///|
fn merge_property_schemas(left : Json, right : Json) -> Json {
  guard left is Json::Object(left_properties) else {
    return Json::boolean(false)
  }
  guard right is Json::Object(right_properties) else {
    return Json::boolean(false)
  }
  let properties = left_properties.copy()
  for key, right_schema in right_properties {
    properties[key] = match properties.get(key) {
      Some(left_schema) => merge_schemas(left_schema, right_schema)
      None => right_schema
    }
  }
  Json::object(properties)
}

///|
fn merge_schema_values(key : String, left : Json, right : Json) -> Json? {
  match key {
    "type" => intersect_schema_types(left, right)
    "properties" => Some(merge_property_schemas(left, right))
    "required" => merge_required(left, right)
    "items" => Some(merge_schemas(left, right))
    _ => if left == right { Some(left) } else { None }
  }
}

///|
fn merge_schema_objects(
  left_properties : Map[String, Json],
  right_properties : Map[String, Json],
) -> Json {
  let properties = left_properties.copy()
  for key, right_value in right_properties {
    match properties.get(key) {
      None => properties[key] = right_value
      Some(left_value) => {
        guard merge_schema_values(key, left_value, right_value) is Some(value) else {
          return Json::boolean(false)
        }
        properties[key] = value
      }
    }
  }
  Json::object(properties)
}

///|
fn merge_schemas(left : Json, right : Json) -> Json {
  match (left, right) {
    (Json::False, _) | (_, Json::False) => Json::boolean(false)
    (Json::True, schema) | (schema, Json::True) => schema
    (Json::Object(left_properties), Json::Object(right_properties)) =>
      merge_schema_objects(left_properties, right_properties)
    _ => Json::boolean(false)
  }
}

///|
/// Generates a Draft 2020-12 JSON Schema for the same heterogeneous lens set
/// accepted by `validate`.
///
/// Compatible paths are merged into one object schema. Incompatible duplicate
/// declarations become a `false` property schema.
pub fn json_schema(lenses : Array[&LensTrait]) -> Json {
  let schema : Map[String, Json] = {
    "$schema": "https://json-schema.org/draft/2020-12/schema".to_json(),
  }
  let merged = lenses.fold(init=Json::empty_object(), (merged, lens) => {
    merge_schemas(merged, LensTrait::to_json_schema(lens))
  })
  match merged {
    Json::Object(properties) =>
      for key, value in properties {
        schema[key] = value
      }
    Json::False => return Json::boolean(false)
    _ => ()
  }
  Json::object(schema)
}
