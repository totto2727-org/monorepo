import { Context, Effect, Layer } from "@totto/function/effect"
import {
  CUID,
  CUIDProductionLive,
  CUIDTestLive,
  type Cuid,
  createCUIDSeed,
} from "@totto/function/effect/id"

const CUIDGeneratorClass: Context.TagClass<
  CUIDGenerator,
  "CUIDGenerator",
  () => Cuid
> = Context.Tag("CUIDGenerator")()

export class CUIDGenerator extends CUIDGeneratorClass {}

export const productionLive = () =>
  Layer.effect(CUIDGenerator, CUID.pipe(Effect.provide(CUIDProductionLive)))

export const testLive = (seed: string) =>
  Layer.effect(
    CUIDGenerator,
    CUID.pipe(
      Effect.provide(CUIDTestLive),
      Effect.provide(createCUIDSeed(seed)),
    ),
  )
