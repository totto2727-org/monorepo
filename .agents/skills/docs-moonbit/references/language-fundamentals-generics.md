<!-- Derived from MoonBit documentation by moonbitlang -->
<!-- https://github.com/moonbitlang/moonbit-docs -->
<!-- Prose content (post July 4, 2024): CC BY-SA 4.0 -->
<!-- Code examples: Apache 2.0 -->
<!-- Modifications: Extracted and reformatted as Claude Code skill files -->

### Generics

Generics are supported in top-level function and data type definitions. Type parameters can be introduced within square brackets. We can rewrite the aforementioned data type `List` to add a type parameter `T` to obtain a generic version of lists. We can then define generic functions over lists like `map` and `reduce`.

```moonbit
///|
enum List[T] {
  Nil
  Cons(T, List[T])
}

///|
fn[S, T] List::map(self : List[S], f : (S) -> T) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), xs.map(f))
  }
}

///|
fn[S, T] List::reduce(self : List[S], op : (T, S) -> T, init : T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => xs.reduce(op, op(init, x))
  }
}
```
