import { BetterAuthService } from '#@/auth/service.ts'
import { DatabaseService } from '#@/db/service.ts'
import { app } from '#api/api.ts'
import { Effect } from '@totto2727/fp/effect'

// oxlint-disable-next-line jest/require-hook no-await-expression-member
;(
  await app.pipe(Effect.provide(BetterAuthService.Default), Effect.provide(DatabaseService.Default), Effect.runPromise)
).listen({
  port: 3000,
})
