# from_json.mbt

Helper functions for extracting values from JSON objects.

## Public API

- `from_json_property`
- `from_json_property_or_default`
- `from_json_property_or_array_or_empty`

## Test

### from_json_property

| Variable | State        | Note    |  1  |  2  |  3  |  4  |
| :------- | :----------- | :------ | :-: | :-: | :-: | :-: |
| `key`    | `Exists`     |         |  ✓  |  -  |  -  |  -  |
| `key`    | `Missing`    |         |  -  |  ✓  |  -  |  -  |
| `key`    | `Null`       |         |  -  |  -  |  ✓  |  -  |
| `json`   | `Non-Object` | `panic` |  -  |  -  |  -  |  ✓  |

- Extracts an existing property

```mbt check
///|
struct TestStruct {
  key : String?
} derive(Show)

///|
impl FromJson for TestStruct with from_json(json, path) {
  TestStruct::{ key: from_json_property("key", json, path) }
}

///|
test {
  let json : Json = { "key": "value" }
  let result : TestStruct = @json.from_json(json)
  inspect(
    result,
    content=(
      #|{key: Some("value")}
    ),
  )
}
```

- Returns None for missing property

```mbt check
///|
test {
  let json : Json = {}
  let result : TestStruct = @json.from_json(json)
  inspect(result, content="{key: None}")
}
```

- Returns None for Null value

```mbt check
///|
test {
  let json : Json = { "key": Json::null() }
  let result : TestStruct = @json.from_json(json)
  inspect(result, content="{key: None}")
}
```

- Errors on non-object JSON

```mbt check
///|
test "panic_from_json_property - on non-object JSON" {
  let json : Json = Json::string("not an object")
  let _ : TestStruct = @json.from_json(json)
  ()
}
```

### from_json_property_or_default

| Variable | State        | Note    |  1  |  2  |  3  |  4  |
| :------- | :----------- | :------ | :-: | :-: | :-: | :-: |
| `key`    | `Exists`     |         |  ✓  |  -  |  -  |  -  |
| `key`    | `Missing`    |         |  -  |  ✓  |  -  |  -  |
| `key`    | `Null`       |         |  -  |  -  |  ✓  |  -  |
| `json`   | `Non-Object` | `panic` |  -  |  -  |  -  |  ✓  |

- Extracts an existing property

```mbt check
///|
struct TestStruct2 {
  key : String
} derive(Show)

///|
impl FromJson for TestStruct2 with from_json(json, path) {
  TestStruct2::{
    key: from_json_property_or_default("key", () => "default", json, path),
  }
}

///|
test {
  let json : Json = { "key": "value" }
  let result : TestStruct2 = @json.from_json(json)
  inspect(
    result,
    content=(
      #|{key: "value"}
    ),
  )
}
```

- Returns default for missing property

```mbt check
///|
test {
  let json : Json = {}
  let result : TestStruct2 = @json.from_json(json)
  inspect(
    result,
    content=(
      #|{key: "default"}
    ),
  )
}
```

- Returns default for Null value

```mbt check
///|
test {
  let json : Json = { "key": Json::null() }
  let result : TestStruct2 = @json.from_json(json)
  inspect(
    result,
    content=(
      #|{key: "default"}
    ),
  )
}
```

- Errors on non-object JSON

```mbt check
///|
test "panic_from_json_property_or_default - on non-object JSON" {
  let json : Json = Json::string("not an object")
  let _ : TestStruct2 = @json.from_json(json)
  ()
}
```

### from_json_property_or_array_or_empty

| Variable | State     | Note |  1  |  2  |  3  |
| :------- | :-------- | :--- | :-: | :-: | :-: |
| `key`    | `Exists`  |      |  ✓  |  -  |  -  |
| `key`    | `Missing` |      |  -  |  ✓  |  -  |
| `key`    | `Null`    |      |  -  |  -  |  ✓  |

- Extracts valid array

```mbt check
///|
struct TestStruct3 {
  key : Array[String]
} derive(Show)

///|
impl FromJson for TestStruct3 with from_json(json, path) {
  TestStruct3::{ key: from_json_property_or_array_or_empty("key", json, path) }
}

///|
test {
  let json : Json = { "key": ["value"] }
  let result : TestStruct3 = @json.from_json(json)
  inspect(
    result,
    content=(
      #|{key: ["value"]}
    ),
  )
}
```

- Returns empty array for missing property

```mbt check
///|
test {
  let json : Json = {}
  let result : TestStruct3 = @json.from_json(json)
  inspect(result, content="{key: []}")
}
```

- Returns empty array for Null value

```mbt check
///|
test {
  let json : Json = { "key": Json::null() }
  let result : TestStruct3 = @json.from_json(json)
  inspect(result, content="{key: []}")
}
```
