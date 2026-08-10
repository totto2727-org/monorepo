# MoonBit Update Semantics

> Document type: concrete MoonBit implementation guidance.

Choose one update model for each type and make the choice visible in method names.

## Immutable values

Use `with_<field>` only for whole-field replacement on value objects. A wither returns a new value and never mutates the receiver.

```mbt check
pub fn Point::with_x(self : Point, x : Double) -> Point {
  Point(x, self.y())
}
```

Use a past-participle verb for an immutable transformation that is not whole-field replacement, such as `pushed_interior` or `filtered_interiors`.

## Mutable values

Use `set_<field>` only for types whose contract includes identity or in-place mutation, such as builders.

```mbt check
pub fn Builder::set_capacity(self : Builder, capacity : Int) -> Unit {
  self.capacity = capacity
}
```

Do not expose setters on values used as structural keys. Do not mix withers and setters on one type; split a mutable builder from the immutable value it produces.

## Validation

Route immutable updates through the canonical constructor so validation is not bypassed. Avoid raw struct update syntax when it would skip constructor invariants.
