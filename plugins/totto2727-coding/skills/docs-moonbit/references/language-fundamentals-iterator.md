<!-- Derived from MoonBit documentation by moonbitlang -->
<!-- https://github.com/moonbitlang/moonbit-docs -->
<!-- Prose content (post July 4, 2024): CC BY-SA 4.0 -->
<!-- Code examples: Apache 2.0 -->
<!-- Modifications: Extracted and reformatted as Claude Code skill files -->

### Iterator

An iterator is an object that traverse through a sequence while providing access
to its elements. Traditional OO languages like Java's `Iterator<T>` use `next()`
`hasNext()` to step through the iteration process, whereas functional languages
(JavaScript's `forEach`, Lisp's `mapcar`) provides a high-order function which
takes an operation and a sequence then consumes the sequence with that operation
being applied to the sequence. The former is called _external iterator_ (visible
to user) and the latter is called _internal iterator_ (invisible to user).

The built-in type `Iter[T]` is MoonBit's external iterator implementation. It
exposes `next()` to pull the next value: it returns `Some(value)` and advances
the iterator, or `None` when the iteration is finished.
Almost all built-in sequential data structures have implemented `Iter`:

```moonbit
///|
fn filter_even(l : Array[Int]) -> Array[Int] {
  let l_iter : Iter[Int] = l.iter()
  l_iter.filter(x => (x & 1) == 0).collect()
}

///|
fn fact(n : Int) -> Int {
  let start = 1
  let range : Iter[Int] = start.until(n)
  range.fold(Int::mul, init=start)
}
```

Commonly used methods include:

- `each`: Iterates over each element in the iterator, applying some function to each element.
- `fold`: Folds the elements of the iterator using the given function, starting with the given initial value.
- `collect`: Collects the elements of the iterator into an array.
- `filter`: _lazy_ Filters the elements of the iterator based on a predicate function.
- `map`: _lazy_ Transforms the elements of the iterator using a mapping function.
- `concat`: _lazy_ Combines two iterators into one by appending the elements of the second iterator to the first.

Methods like `filter` and `map` are very common on a sequence object e.g. Array.
But what makes `Iter` special is that any method that constructs a new `Iter` is
_lazy_ (i.e. iteration doesn't start on call because it's wrapped inside a
function), as a result of no allocation for intermediate value. That's what
makes `Iter` superior for traversing through sequence: no extra cost. MoonBit
encourages user to pass an `Iter` across functions instead of the sequence
object itself.

Pre-defined sequence structures like `Array` and its iterators should be
enough to use. But to take advantages of these methods when used with a custom
sequence with elements of type `S`, we will need to implement `Iter`, namely, a function that returns
an `Iter[S]`. Take `Bytes` as an example:

```moonbit
///|
fn iter(data : Bytes) -> Iter[Byte] {
  let mut index = 0
  Iter::new(fn() -> Byte? {
    if index < data.length() {
      let byte = data[index]
      index += 1
      Some(byte)
    } else {
      None
    }
  })
}
```

Iterators are single-pass: once you call `next()` or consume them with methods
like `each`, `fold`, or `collect`, their internal state advances and cannot be
reset. If you need to traverse the sequence again, request a new `Iter` from
the source.

Use `[| ... |]` to construct an `Iter` explicitly. Elements, spread syntax,
and comprehensions are supported inside the delimiters:

```moonbit
  let prefix = [| 1, 2, 3 |]
  let values = [| ..prefix, 4, 5 |]
  let squares = [| for x in 1..<=3 => x * x |]
```

In `[| x, y |]`, `x` and `y` are evaluated when the iterator literal is
constructed. For `..xs`, evaluating `xs` happens immediately, while consuming
the resulting iterator remains lazy. A comprehension `[| for ... |]` is fully
lazy and runs as the outer iterator is consumed.

Using an overloaded array literal such as `[x, ..xs]` to construct an `Iter`
from its expected type is deprecated because the type would silently change
evaluation order. Use `[| x, ..xs |]` instead.
