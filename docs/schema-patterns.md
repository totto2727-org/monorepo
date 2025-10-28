# Schema Patterns

This document defines patterns for Effect Schema usage.

## Basic Principles

- One schema per file
  - Each file should define one primary schema
- Export make function

**Exception**: Discriminated union variants or Enum schema in the same file (see Union Types section).

## Template

```typescript
export const schema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
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

export const fromDTOTransformer = Schema.transformLiterals(
  ...Array.zip(DTO_CONSTANT, CONSTANT),
)

export const make = Schema.decodeSync(schema)
export const fromDTO = Schema.decodeSync(fromDTOTransformer)
export const toDTO = Schema.encodeSync(fromDTOTransformer)
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

## Decoding Patterns

```typescript
const decodeSync = Schema.decodeSync(schema)
const decode = Schema.decode(schema)
const decodeOption = Schema.decodeOption(schema)

const user = decodeSync({ id: "123", name: "test" })
const userEffect = decode({ id: "123", name: "test" })
const userOption = decodeOption(schema)
```
