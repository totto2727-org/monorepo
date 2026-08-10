# MoonBit Sequences

> Document type: concrete MoonBit implementation guidance.

## Return shape

Return `Array[T]` when the result is small, bounded, or normally consumed in full. This keeps the API direct for fixed-size values such as a line's endpoints or a triangle's vertices.

Provide an `Iter[T]` form when callers benefit from streaming, short-circuiting, or avoiding a potentially large allocation. Name the lazy form with an `_iter` suffix when both forms exist.

Do not add eager and lazy variants speculatively. Add the second shape when a concrete consumer needs its allocation or traversal behavior.

## Dual implementations

When both shapes are justified, the lazy form must not allocate the full `Array`, and the eager form should use the direct immutable construction described by [MoonBit Arrays](arrays.md), under "Construction choices". Shared per-element logic may live in a private pure helper.

```mbt check
pub fn LineString::lines(self : LineString) -> Array[Line] {
  let n = self.coords.length()
  if n < 2 {
    []
  } else {
    Array::makei(n - 1, i => Line::Line(self.coords[i], self.coords[i + 1]))
  }
}
```
