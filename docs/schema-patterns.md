# Schema Patterns

This document defines patterns for Effect Schema usage.

## Basic Principles

### One schema per file

Each file should define one primary schema:

```typescript
export const schema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
})

export const make = Schema.decodeSync(schema)
```

**Exception**: Discriminated union variants in the same file (see Union Types section).

### Export make function

Always export a `make` function using `Schema.decodeSync`:

```typescript
export const schema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
})

export const make = Schema.decodeSync(schema)
```

## Basic Schema Definitions

### Struct with primitive types

```typescript
export const schema = Schema.Struct({
  id: Schema.String,
  age: Schema.Number,
  isActive: Schema.Boolean,
  tags: Schema.Array(Schema.String),
  nickname: Schema.optional(Schema.String),
  description: Schema.NullOr(Schema.String),
})

export const make = Schema.decodeSync(schema)
```

## Enum Patterns

### Simple enum

```typescript
import { Data, Schema } from "@totto/function/effect"

export const CONSTANT = Data.array(["foo", "bar", "baz"] as const)

export const schema = Schema.Literal(...CONSTANT)

export const make = Schema.decodeSync(schema)
```

### Enum with DTO transformation

For cases where internal representation differs from DTO:

```typescript
import { Array, Data, Schema } from "@totto/function/effect"

export const CONSTANT = Data.array(["foo:a", "foo:b", "foo:c"] as const)

export const DTO_CONSTANT = Data.array(["foo_a", "foo_b", "foo_c"] as const)

export const schema = Schema.Literal(...CONSTANT)
export const dtoSchema = Schema.Literal(...DTO_CONSTANT)

export const fromDTO = Schema.transformLiterals(
  ...Array.zip(DTO_CONSTANT, CONSTANT),
)

export const make = Schema.decodeSync(schema)
```

**Usage**:

```typescript
const value = fromDTO.pipe(Schema.decodeSync)("foo_a")
```

## Union Types

```typescript
const fooSchema = Schema.Struct({
  type: Schema.Literal("foo"),
  fooValue: Schema.String,
})

const barSchema = Schema.Struct({
  type: Schema.Literal("bar"),
  barValue: Schema.Number,
})

export const schema = Schema.Union(fooSchema, barSchema)
export const simpleUnion = Schema.Union(Schema.String, Schema.Number)

export const make = Schema.decodeSync(schema)
```

## Transformation and Branding

```typescript
export const uppercaseSchema = Schema.transform(
  Schema.String,
  Schema.String,
  {
    decode: (input) => input.toUpperCase(),
    encode: (output) => output.toLowerCase(),
  },
)

export const userIDSchema = Schema.String.pipe(Schema.brand("UserId"))

export const make = Schema.decodeSync(userIDSchema)
```

## Validation Patterns

```typescript
const stringSchema = Schema.String.pipe(
  Schema.minLength(1),
  Schema.maxLength(255),
)

const numberSchema = Schema.Number.pipe(
  Schema.greaterThan(0),
  Schema.lessThanOrEqualTo(100),
)

export const schema = Schema.Struct({
  name: stringSchema,
  age: numberSchema,
  tags: Schema.NonEmptyArray(Schema.String),
})

export const make = Schema.decodeSync(schema)
```

## Type Extraction

```typescript
export const schema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
})

export type Type = typeof schema.Type
export type Encoded = typeof schema.Encoded
export const make = Schema.decodeSync(schema)
```

## Decoding Patterns

```typescript
export const make = Schema.decodeSync(schema)
export const makeAsync = Schema.decode(schema)
export const makeOption = Schema.decodeOption(schema)

const syncResult = make({ id: "123", name: "test" })
const asyncResult = await makeAsync({ id: "123" }).pipe(Effect.runPromise)
const optionResult = makeOption({ id: "123" })
```

## Database Integration

Transform database types to API types:

```typescript
const dbSchema = Schema.Struct({
  id: Schema.String,
  createdAt: Schema.Date,
})

export const schema = Schema.transform(
  dbSchema,
  Schema.Struct({
    id: Schema.String,
    createdAt: Schema.String,
  }),
  {
    decode: (db) => ({ ...db, createdAt: db.createdAt.toISOString() }),
    encode: (api) => ({ ...api, createdAt: new Date(api.createdAt) }),
  },
)

export const make = Schema.decodeSync(schema)
```
