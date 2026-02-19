/*
 * MIT License
 * Copyright (c) 2022 Eric Elliott
 * <https://github.com/paralleldrive/cuid2/blob/e2391a06836226249ed2ca1a287516d2c459dab7/LICENSE>
 * <https://github.com/paralleldrive/cuid2/blob/e2391a06836226249ed2ca1a287516d2c459dab7/src/index.js>
 */
import type { ParseOptions } from 'effect/SchemaAST'

import { Array, Effect, Schema } from '#@/effect.ts'
import { sha3_512 } from '@noble/hashes/sha3.js'
import BaseX from 'base-x'
import { BigNumber } from 'bignumber.js'
import SR from 'seedrandom'

const defaultLength = 24
const bigLength = 32

/** Effect Schema for CUID branded string type. */
export const schema: Schema.brand<
  Schema.filter<Schema.filter<Schema.filter<typeof Schema.String>>>,
  '@totto2727/fp/effect/cuid/Cuid'
> = Schema.String.pipe(
  Schema.pattern(/^[a-z][0-9a-z]+$/),
  Schema.minLength(2),
  Schema.maxLength(bigLength),
  Schema.brand('@totto2727/fp/effect/cuid/Cuid'),
)

/** Branded CUID type. */
export type CUID = typeof schema.Type

/** Type guard for CUID values. */
export const is: (value: unknown, overrideOptions?: ParseOptions | number) => value is CUID = Schema.is(schema)

const decodeSync = Schema.decodeSync(schema)

/** Returns default CUID length constants. */
export const getDefaultConstants = (): {
  defaultLength: number
  bigLength: number
} => ({ bigLength, defaultLength })

const createRandom = (): number => {
  // Generate a random 32-bit unsigned integer
  const buffer = new Uint32Array(1)
  globalThis.crypto.getRandomValues(buffer)
  // Convert to a float in [0, 1) by dividing by 2^32
  const [value] = buffer
  if (value === undefined) {
    throw new Error('Failed to generate random value')
  }
  return value / 0x1_00_00_00_00
}

const createEntropy = (length = 4, random = createRandom): string => {
  let entropy = ''

  while (entropy.length < length) {
    entropy += Math.floor(random() * 36).toString(36)
  }
  return entropy
}

/*
 * Adapted from https://github.com/juanelas/bigint-conversion
 * MIT License Copyright (c) 2018 Juan Hernández Serrano
 */
/** Converts a byte buffer to a BigNumber. */
export const bufToBigInt = (buf: Uint8Array): BigNumber => {
  let value = new BigNumber(0)

  for (const i of buf.values()) {
    // Multiply by 256 (left shift by 8 bits) and add the current byte
    value = value.multipliedBy(256).plus(i)
  }
  return value
}

const hash = (input: string): string => {
  // Drop the first character because it will bias the histogram
  // to the left.
  const encoder = new TextEncoder()
  return bufToBigInt(sha3_512(encoder.encode(input)))
    .toString(36)
    .slice(1)
}

const alphabet = [...'abcdefghijklmnopqrstuvwxyz']

const randomLetter = (rand: () => number): string => {
  const letter = alphabet[Math.floor(rand() * alphabet.length)]
  if (letter === undefined) {
    throw new Error('Failed to generate random letter')
  }
  return letter
}
/*
This is a fingerprint of the host environment. It is used to help
prevent collisions when generating ids in a distributed system.
If no global object is available, you can pass in your own, or fall back
on a random string.
*/
/** Creates a fingerprint of the host environment for collision prevention. */
export const createFingerprint = ({
  globalObj = typeof globalThis === 'undefined' ? {} : globalThis,
  random = createRandom,
}: {
  globalObj?: Record<string, unknown>
  random?: () => number
} = {}): string => {
  const globals = Object.keys(globalObj).toString()
  const sourceString = globals.length ? globals + createEntropy(bigLength, random) : createEntropy(bigLength, random)

  return hash(sourceString).slice(0, bigLength)
}

/** Creates an incrementing counter starting from the given value. */
export const createCounter = (initialCount: number): (() => number) => {
  let count = initialCount
  return () => {
    const current = count
    count += 1
    return current
  }
}

// ~22k hosts before 50% chance of initial counter collision
// with a remaining counter range of 9.0e+15 in JavaScript.
const initialCountMax = 476_782_367

/** Initializes a CUID generator with the given options. */
export const init = ({
  length = defaultLength,
}: {
  length?: number
} = {}): (() => CUID) => {
  const random = createRandom
  const counter = createCounter(Math.floor(random() * initialCountMax))
  const fingerprint = createFingerprint({ random })

  if (length > bigLength) {
    throw new Error(`Length must be between 2 and ${bigLength}. Received: ${length}`)
  }
  return () => {
    const firstLetter = randomLetter(random)

    // If we're lucky, the `.toString(36)` calls may reduce hashing rounds
    // by shortening the input to the hash function a little.
    const time = Date.now().toString(36)
    const count = counter().toString(36)

    // The salt should be long enough to be globally unique across the full
    // length of the hash. For simplicity, we use the same length as the
    // intended id output.
    const salt = createEntropy(length, random)
    const hashInput = `${time + salt + count + fingerprint}`

    return decodeSync(`${firstLetter + hash(hashInput).slice(1, length)}`)
  }
}

/** Effect service that provides CUID generation. */
export class Generator extends Effect.Service<Generator>()('@totto2727/fp/effect/cuid/Generator', {
  sync: () => {
    let createId: () => CUID
    return () => {
      createId ??= init()
      return createId()
    }
  },
}) {}

const base26 = BaseX('abcdefghijklmnopqrstuvwxyz')
const base36 = BaseX('0123456789abcdefghijklmnopqrstuvwxyz')

/** Creates a deterministic CUID generator for testing. */
export const makeTestGenerator = (seedString: string) => {
  let seed: SR.PRNG
  return new Generator(() => {
    seed ??= SR(seedString)
    const [r, ...rArray] = Array.makeBy(20, () => seed.int32())
    return decodeSync(`${base26.encode([r])}${base36.encode(rArray)}`.slice(0, 24).padEnd(24, '0'))
  })
}

/** Generates a new CUID using the Generator service. */
export const make: Effect.Effect<CUID, never, Generator> = Effect.gen(function* () {
  const makeCUID = yield* Generator
  return makeCUID()
})
