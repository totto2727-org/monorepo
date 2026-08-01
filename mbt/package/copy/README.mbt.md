# totto2727/copy

An explicit copy trait for MoonBit values.

MoonBit does not move values when they are passed to a function, so this package is not a marker for Rust-style move semantics. `Copy::copy` instead creates an independent logical copy. Composite implementations recursively copy their contents, while immutable storage may be shared when it cannot expose mutation.

`Copy` has no blanket or default implementation. Every custom type must explicitly define how its independent logical copy is constructed so mutable fields and collections cannot be shared accidentally.

## Generic copying

Use a `Copy` bound when an operation must produce a logically independent value:

```mbt check
fn[T : Copy] duplicate(value : T) -> (T, T) {
  (Copy::copy(value), Copy::copy(value))
}

test {
  debug_inspect(duplicate(42), content="(42, 42)")
}
```

The package implements `Copy` for primitive and immutable scalar values, `Option`, `Result`, `Array`, `FixedArray`, `ReadOnlyArray`, `Map`, and two- and three-element tuples. Composite implementations require their contained values to implement `Copy`; map keys must also implement `Hash` and `Eq`.

## Custom mutable values

Mutable types define their own copy policy:

```mbt check
struct Counter {
  mut value : Int
}

impl Copy for Counter with fn copy(self) {
  Counter::{ value: self.value }
}

test {
  let source = Counter::{ value: 1 }
  let copied = Copy::copy(source)
  copied.value = 2
  debug_inspect((source.value, copied.value), content="(1, 2)")
}
```

MoonBit's trait syntax and generic trait bounds are documented in the [official Method and Trait reference](https://docs.moonbitlang.com/en/latest/language/methods.html).
