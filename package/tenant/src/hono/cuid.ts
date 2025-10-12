import { Context, Effect, Layer } from "@totto/function/effect"
import {
  CUID,
  CUIDProductionLive,
  CUIDTestLive,
  type Cuid,
  createCUIDProductionState,
  createCUIDSeed,
} from "@totto/function/effect/id"

const CUIDGeneratorClass: Context.TagClass<
  CUIDGenerator,
  "CUIDGenerator",
  Effect.Effect<Cuid>
> = Context.Tag("CUIDGenerator")()

export class CUIDGenerator extends CUIDGeneratorClass {}

export const productionLive = (id: string) =>
  Layer.succeed(
    CUIDGenerator,
    CUID.pipe(
      Effect.provide(CUIDProductionLive),
      Effect.provide(createCUIDProductionState(id)),
    ),
  )

export const testLive = (seed: string) =>
  Layer.succeed(
    CUIDGenerator,
    CUID.pipe(
      Effect.provide(CUIDTestLive),
      Effect.provide(createCUIDSeed(seed)),
    ),
  )
