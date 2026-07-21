# MoonBit Constructors

> Document type: concrete MoonBit implementation guidance.

## Canonical constructor

Give each domain type one canonical `TypeName::TypeName(...)` constructor. Put validation and normalization there so every normally constructed instance satisfies the same invariants.

```mbt check
pub fn Rect::Rect(x~ : Double, y~ : Double, width~ : Double, height~ : Double) -> Rect raise {
  guard width >= 0.0 && height >= 0.0 else { fail("negative size") }
  Rect::{ x, y, width, height }
}
```

Keep direct struct literals inside the canonical constructor. Production code and tests should use the constructor instead of bypassing its invariants.

## Alternate factories

Name alternate factories after the conversion or state they provide, such as `from_corners` or `unit_at`. Route the final value through the canonical constructor.

```mbt check
pub fn Rect::from_corners(x1~ : Double, y1~ : Double, x2~ : Double, y2~ : Double) -> Rect raise {
  Rect(x=x1, y=y1, width=x2 - x1, height=y2 - y1)
}
```

Do not add a generic `new` alias for the canonical constructor. Each additional entry point must communicate a distinct input representation or domain intent.
