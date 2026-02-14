import { Array, Effect } from '#@/effect.ts'
import { describe, expect, test } from 'bun:test'
import { pipe, Schema, String } from 'effect'

import * as CUID from './cuid.ts'

const decode = Schema.decodeUnknownSync(CUID.schema)

test('generatorProductionLive', () => {
  Effect.gen(function* () {
    const cuid1 = yield* CUID.makeCUID
    const cuid2 = yield* CUID.makeCUID

    expect(cuid1).not.toBe(cuid2)
  }).pipe(Effect.provide(CUID.Generator.Default), Effect.runSync)
})

describe('generatorTestLive', () => {
  test('Fixed', () => {
    Effect.gen(function* () {
      const cuid = yield* CUID.makeCUID

      expect(cuid).toBe(decode('gk1pfmhav2vkvudlk25qrot8'))
    }).pipe(Effect.provideService(CUID.Generator, CUID.makeTestGenerator('test')), Effect.runSync)
  })

  test('Snapshot', () => {
    Effect.gen(function* () {
      const actual = yield* pipe(
        Array.makeBy(10, () => CUID.makeCUID),
        Effect.allSuccesses,
      )

      expect(actual).toEqual([
        decode('gk1pfmhav2vkvudlk25qrot8'),
        decode('dk3p231wqtob3kin8dt7p6sv'),
        decode('p1o29mevenep5ehytgf7slsz'),
        decode('cl2ag2azhfpn6gvbjiol9wrv'),
        decode('fw2odl6k7umbv8kpyf1pl4vj'),
        decode('gu480f94gvmqfx44ugeeaed7'),
        decode('u8pozhspgav0zp048uvqw7im'),
        decode('ci2whviybacarg4p69xnzdlg'),
        decode('eh42helbpmmlw7jmco41rpcy'),
        decode('dl1dsmlxhq6tba02sofl2apd'),
      ])
    }).pipe(Effect.provideService(CUID.Generator, CUID.makeTestGenerator('test')), Effect.runSync)
  })
})

describe('Cuid2', () => {
  test('cuid is string', () => {
    const id = CUID.init()()

    expect(String.isString(id)).toBeTruthy()
  })

  test('cuid has default length', () => {
    const id = CUID.init()()
    const { defaultLength } = CUID.getDefaultConstants()

    expect(id.length).toBe(defaultLength)
  })

  test('cuid has custom length', () => {
    const id = CUID.init({ length: 10 })()

    expect(id.length).toBe(10)
  })

  test('cuid has large length', () => {
    const id = CUID.init({ length: 32 })()

    expect(id.length).toBe(32)
  })

  test('cuid has length greater than maximum (33)', () => {
    expect(() => CUID.init({ length: 33 })()).toThrow('Length must be between 2 and 32. Received: 33')
  })

  test('cuid has length much greater than maximum (100)', () => {
    expect(() => CUID.init({ length: 100 })()).toThrow('Length must be between 2 and 32. Received: 100')
  })
})

test('createCounter', () => {
  const counter = CUID.createCounter(10)

  expect([counter(), counter(), counter(), counter()]).toEqual([10, 11, 12, 13])
})

describe('bufToBigInt', () => {
  test('empty Uint8Array', () => {
    expect(CUID.bufToBigInt(new Uint8Array(2)).toString()).toBe('0')
  })

  test('maximum value Uint8Array', () => {
    expect(CUID.bufToBigInt(new Uint8Array([0xff, 0xff, 0xff, 0xff])).toString()).toBe('4294967295')
  })
})

describe('createFingerprint', () => {
  test('no arguments', () => {
    const fingerprint = CUID.createFingerprint()

    expect(fingerprint.length).toBeGreaterThanOrEqual(24)
  })

  test('globalObj is empty object', () => {
    const fingerprint = CUID.createFingerprint({ globalObj: {} })

    expect(fingerprint.length).toBeGreaterThanOrEqual(24)
  })
})

describe('isCuid', () => {
  test('valid cuid', () => {
    expect(CUID.is(CUID.init()())).toBe(true)
  })

  test('cuid is too long', () => {
    expect(CUID.is(CUID.init()() + CUID.init()() + CUID.init()())).toBe(false)
  })

  test('cuid is empty string', () => {
    expect(CUID.is('')).toBe(false)
  })

  test('cuid is non-CUID string', () => {
    expect(CUID.is('42')).toBe(false)
  })

  test('cuid is string with capital letters', () => {
    expect(CUID.is('aaaaDLL')).toBe(false)
  })

  test('cuid is valid CUID2 string', () => {
    expect(CUID.is('yi7rqj1trke')).toBe(true)
  })

  test('cuid is string with invalid characters', () => {
    expect(CUID.is('-x!ha')).toBe(false)
    expect(CUID.is('ab*%@#x')).toBe(false)
  })
})

describe('CSPRNG', () => {
  test('multiple cuid2 calls', () => {
    const id1 = CUID.init()()
    const id2 = CUID.init()()

    expect(id1 !== id2).toBe(true)
  })

  test('100 IDs generated with CSPRNG', () => {
    const ids = Array.makeBy(100, () => CUID.init()())
    const allValid = ids.every((id) => CUID.is(id))
    const allUnique = new Set(ids).size === ids.length
    expect(allValid).toBeTrue()
    expect(allUnique).toBeTrue()
  })
})
