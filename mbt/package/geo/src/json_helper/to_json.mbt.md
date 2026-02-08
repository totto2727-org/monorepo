# to_json.mbt

Helper functions for constructing optional/nullable JSON fields.

## Public API

- `to_optional_json`
- `to_nullable_json`
- `to_json_or_default`

## Test

### to_optional_json

| Variable | State  | Note |  1  |  2  |
| :------- | :----- | :--- | :-: | :-: |
| `value`  | `Some` |      |  ✓  |  -  |
| `value`  | `None` |      |  -  |  ✓  |

- Some value sets key

```mbt check
///|
test {
  let map : Map[String, Json] = Map::new()
  to_optional_json(map, "key", Some("value"))
  json_inspect(map, content={ "key": "value" })
}
```

- None value does nothing

```mbt check
///|
test {
  let map : Map[String, Json] = Map::new()
  let s : String? = None
  to_optional_json(map, "key", s)
  json_inspect(map, content={})
}
```

### to_nullable_json

| Variable | State  | Note   |  1  |  2  |
| :------- | :----- | :----- | :-: | :-: |
| `value`  | `Some` |        |  ✓  |  -  |
| `value`  | `None` | `Null` |  -  |  ✓  |

- Some value sets key

```mbt check
///|
test {
  let map : Map[String, Json] = Map::new()
  to_nullable_json(map, "key", Some("value"))
  json_inspect(map, content={ "key": "value" })
}
```

- None value sets Null

```mbt check
///|
test {
  let map : Map[String, Json] = Map::new()
  let s : String? = None
  to_nullable_json(map, "key", s)
  json_inspect(map, content={ "key": Json::null() })
}
```

### to_json_or_default

| Variable | State  | Note      |  1  |  2  |
| :------- | :----- | :-------- | :-: | :-: |
| `value`  | `Some` |           |  ✓  |  -  |
| `value`  | `None` | `Default` |  -  |  ✓  |

- Some value uses value

```mbt check
///|
test {
  let map : Map[String, Json] = Map::new()
  to_json_or_default(map, "key", Some("value"), () => "default")
  json_inspect(map, content={ "key": "value" })
}
```

- None value uses default

```mbt check
///|
test {
  let map : Map[String, Json] = Map::new()
  let s : String? = None
  to_json_or_default(map, "key", s, () => "default")
  json_inspect(map, content={ "key": "default" })
}
```
