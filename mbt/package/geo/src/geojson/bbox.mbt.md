# BBox

## Public API

- `BBoxTrait`
  - `bbox`
- `BBox`
  - `new_2d`
  - `new_3d`
  - `from_coordinate_array`
  - `ToJson`
    - `to_json`
  - `FromJson`
    - `from_json`

## Test

### new_2d

- non sorting

```mbt check
///|
test "BBox new_2d - non sorting" {
  let bbox = BBox::new_2d(10.0, 20.0, 0.0, 5.0)
  inspect(bbox, content="BBox2D(0, 5, 10, 20)")
}
```

- sorting

```mbt check
///|
test "BBox new_2d - sorting" {
  let bbox = BBox::new_2d(0.0, 5.0, 10.0, 20.0)
  inspect(bbox, content="BBox2D(0, 5, 10, 20)")
}
```

### new_3d

- sorting

```mbt check
///|
test "BBox new_3d - sorting" {
  let bbox = BBox::new_3d(10.0, 20.0, 30.0, 0.0, 5.0, 10.0)
  inspect(bbox, content="BBox3D(0, 5, 10, 10, 20, 30)")
}
```

- non sorting

```mbt check
///|
test "BBox new_3d - non sorting" {
  let bbox = BBox::new_3d(0.0, 5.0, 10.0, 20.0, 30.0, 10.0)
  inspect(bbox, content="BBox3D(0, 5, 10, 20, 30, 10)")
}
```

### from_coordinate_array

- 2d

```mbt check
///|
test "BBox from_coordinate_array - 2d" {
  let coords = [
    Coordinates::XY(0.0, 0.0),
    Coordinates::XY(10.0, 10.0),
    Coordinates::XY(5.0, 5.0),
  ]
  inspect(coords, content="[XY(0, 0), XY(10, 10), XY(5, 5)]")
}
```

- 3d

```mbt check
///|
test "BBox from_coordinate_array - 3d" {
  let coords = [
    Coordinates::XYZ_OR_XYM(0.0, 0.0, 0.0),
    Coordinates::XYZ_OR_XYM(10.0, 10.0, 10.0),
    Coordinates::XYZ_OR_XYM(5.0, 5.0, 5.0),
  ]
  inspect(
    coords,
    content="[XYZ_OR_XYM(0, 0, 0), XYZ_OR_XYM(10, 10, 10), XYZ_OR_XYM(5, 5, 5)]",
  )
}
```

- empty

```mbt check
///|
test "panic_BBox from_coordinate_array - empty" {
  let _ = BBox::from_coordinate_array([])

}
```

- mixed dimensions

```mbt check
///|
test "panic_BBox from_coordinate_array - mixed dimensions" {
  let coords = [
    Coordinates::XY(0.0, 0.0),
    Coordinates::XYZ_OR_XYM(0.0, 0.0, 0.0),
  ]
  let _ = BBox::from_coordinate_array(coords)

}
```

### ToJson

- bbox2d

```mbt check
///|
test "BBox ToJson::to_json - bbox2d" {
  json_inspect(BBox::BBox2D(0.0, 1.0, 2.0, 3.0), content=[0, 1, 2, 3])
}
```

- bbox3d

```mbt check
///|
test "BBox ToJson::to_json - bbox3d" {
  json_inspect(BBox::BBox3D(0.0, 1.0, 2.0, 3.0, 4.0, 5.0), content=[
    0, 1, 2, 3, 4, 5,
  ])
}
```

### FromJson

- bbox2d

```mbt check
///|
test "BBox FromJson::from_json - bbox2d" {
  let bbox : BBox = @json.from_json([0.0, 1.0, 2.0, 3.0])
  inspect(bbox, content="BBox2D(0, 1, 2, 3)")
}
```

- bbox3d

```mbt check
///|
test "BBox FromJson::from_json - bbox3d" {
  let bbox : BBox = @json.from_json([0.0, 1.0, 2.0, 3.0, 4.0, 5.0])
  inspect(bbox, content="BBox3D(0, 1, 2, 3, 4, 5)")
}
```

- panic_Invalid

```mbt check
///|
test "panic_BBox FromJson::from_json - invalid" {
  let _ : BBox = @json.from_json([0.0, 1.0])

}
```
