# Error Handling

This document defines error handling patterns for this project.

## HTTPException

Use Hono's `HTTPException` with constants for status codes:

```typescript
import { STATUS_CODE } from "@package/constant"
import { HTTPException } from "hono/http-exception"

if (Option.isNone(user)) {
  throw new HTTPException(STATUS_CODE.UNAUTHORIZED)
}
```

## Option Type

The Option type represents values that may or may not exist.

### Option generation

Create Option values:

```typescript
Option.none()
Option.fromNullable(value)
Option.fromIterable(array)
```

### Option checking

Check if Option contains a value:

```typescript
if (Option.isNone(user)) { /* ... */ }
if (Option.isSome(user)) { /* ... */ }
```

### Option extraction

Extract values from Option:

```typescript
Option.getOrThrow(userOption)
Option.fromIterable(result).pipe(Option.getOrThrow)
```

Usage in pipeline:

```typescript
getContext().var.user.pipe(Option.getOrThrow)
```

## Type Guards with Predicate

Use Predicate utilities for type checking:

```typescript
import { Predicate } from "@totto/function/effect"

if (Predicate.isNullable(jwtUser.id)) {
  c.set("user", Option.none())
  return next()
}
```

## Custom Error Types

Define custom error types using Effect's `TaggedError`:

```typescript
class UserNotFoundError extends Data.TaggedError("UserNotFoundError")<{
  userId: string
}> {}
```

This provides:

- Type-safe error handling
- Pattern matching capabilities
- Clear error discrimination
