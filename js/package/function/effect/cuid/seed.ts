import { Context, Layer } from 'effect'
import SR from 'seedrandom'

export class Seed extends Context.Tag('@totto/function/effect/cuid/Seed')<Seed, SR.PRNG>() {}

export const createSeed = (seed: string): Layer.Layer<Seed, never, never> => Layer.succeed(Seed, Seed.of(SR(seed)))
