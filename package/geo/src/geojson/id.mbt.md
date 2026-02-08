
# ID

## Public API

- `ID`
  - `ToJson`
    - `to_json`
  - `FromJson`
    - `from_json`

## Test

### ToJson

- String

```mbt check
///|
test "ID ToJson::to_json - string" {
  json_inspect(ID::String("test"), content="test")
}
```

- Number

```mbt check
///|
test "ID ToJson::to_json - number" {
  json_inspect(ID::Number(123.0), content=123)
}
```

### FromJson

- String

```mbt check
///|
test "ID FromJson::from_json - string" {
  let id : ID = @json.from_json("test")
  inspect(id, content="String(\"test\")")
}
```

- Number

```mbt check
///|
test "ID FromJson::from_json - number" {
  let id : ID = @json.from_json(123.0)
  inspect(id, content="Number(123)")
}
```

- panic_Invalid

```mbt check
///|
test "panic_ID FromJson::from_json - invalid" {
  let _ : ID = @json.from_json(true)

}
```
