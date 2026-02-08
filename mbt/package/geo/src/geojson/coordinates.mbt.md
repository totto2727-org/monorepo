# Coordinates

## Public API

- `Coordinates`
  - `x`
  - `y`
  - `z`
  - `dimension`
  - `ToJson`
    - `to_json`
  - `FromJson`
    - `from_json`

## Test

### x

```mbt check
///|
test "Coordinates x" {
  let coord = Coordinates::XY(1, 2)
  inspect(coord.x(), content="1")
}
```

### y

```mbt check
///|
test "Coordinates y" {
  let coord = Coordinates::XY(1, 2)
  inspect(coord.y(), content="2")
}
```

### z

- non panic

```mbt check
///|
test "Coordinates z - non panic" {
  let coord = Coordinates::XYZ_OR_XYM(1, 2, 3)
  inspect(coord.z(), content="3")
}
```

- panic on XY

```mbt check
///|
test "panic_Coordinates z - on XY" {
  let coord = Coordinates::XY(0.0, 0.0)
  coord.z() |> ignore
}
```

### dimension

```mbt check
///|
test "Coordinates dimension" {
  inspect(Coordinates::XY(1.0, 2.0).dimension(), content="2")
  inspect(Coordinates::XYZ_OR_XYM(1.0, 2.0, 3.0).dimension(), content="3")
  inspect(Coordinates::XYZM(1.0, 2.0, 3.0, 4.0).dimension(), content="4")
}
```

### ToJson

- XY

```mbt check
///|
test "Coordinates ToJson::to_json - XY" {
  json_inspect(Coordinates::XY(1.0, 2.0), content=[1, 2])
}
```

- XYZ_OR_XYM

```mbt check
///|
test "Coordinates ToJson::to_json - XYZ_OR_XYM" {
  json_inspect(Coordinates::XYZ_OR_XYM(1.0, 2.0, 3.0), content=[1, 2, 3])
}
```

- XYZM

```mbt check
///|
test "Coordinates ToJson::to_json - XYZM" {
  json_inspect(Coordinates::XYZM(1.0, 2.0, 3.0, 4.0), content=[1, 2, 3, 4])
}
```

### FromJson

- XY

```mbt check
///|
test "Coordinates FromJson::from_json - XY" {
  let coordinates : Coordinates = @json.from_json([1.0, 2.0])
  inspect(coordinates, content="XY(1, 2)")
}
```

- XYZ_OR_XYM

```mbt check
///|
test "Coordinates FromJson::from_json - XYZ_OR_XYM" {
  let coordinates : Coordinates = @json.from_json([1.0, 2.0, 3.0])
  inspect(coordinates, content="XYZ_OR_XYM(1, 2, 3)")
}
```

- XYZM

```mbt check
///|
test "Coordinates FromJson::from_json - XYZM" {
  let coordinates : Coordinates = @json.from_json([1.0, 2.0, 3.0, 4.0])
  inspect(coordinates, content="XYZM(1, 2, 3, 4)")
}
```

- panic_Invalid

```mbt check
///|
test "panic_Coordinates FromJson::from_json - invalid" {
  let _ : Coordinates = @json.from_json([1.0])

}
```
