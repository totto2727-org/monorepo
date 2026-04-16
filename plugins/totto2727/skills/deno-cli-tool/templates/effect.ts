#!/usr/bin/env -S deno run --allow-env --allow-net --allow-read
import * as process from 'node:process'

import { Console, Effect, Schema } from 'jsr:@totto2727/fp@3.0/effect'
import { Args, Command, Options } from 'jsr:@totto2727/fp@3.0/effect/cli'
import {
  FetchHttpClient,
  HttpClient,
  HttpClientRequest,
  HttpClientResponse,
} from 'jsr:@totto2727/fp@3.0/effect/platform'
import { NodeContext, NodeRuntime } from 'jsr:@totto2727/fp@3.0/effect/platform/node'

// --- Schema ---

const Item = Schema.Struct({
  id: Schema.Number,
  title: Schema.String,
})

const ItemList = Schema.Array(Item)

// --- Handlers ---

const handleList = (baseUrl: string) =>
  Effect.gen(function* () {
    const client = (yield* HttpClient.HttpClient).pipe(HttpClient.filterStatusOk)
    const req = HttpClientRequest.get(`${baseUrl}/items`)
    const response = yield* client.execute(req)
    const items = yield* HttpClientResponse.schemaBodyJson(ItemList)(response)
    for (const item of items) {
      yield* Console.log(`  ${item.id}: ${item.title}`)
    }
  })

const handleGet = (baseUrl: string, id: string) =>
  Effect.gen(function* () {
    const client = (yield* HttpClient.HttpClient).pipe(HttpClient.filterStatusOk)
    const req = HttpClientRequest.get(`${baseUrl}/items/${id}`)
    const response = yield* client.execute(req)
    const item = yield* HttpClientResponse.schemaBodyJson(Item)(response)
    yield* Console.log(`${item.id}: ${item.title}`)
  })

// --- CLI definition ---

const baseUrlOption = Options.text('base-url').pipe(
  Options.withAlias('u'),
  Options.withDefault('https://api.example.com'),
)

const itemId = Args.text({ name: 'id' })

const list = Command.make('list', { baseUrl: baseUrlOption }, ({ baseUrl }) => handleList(baseUrl))

const get = Command.make('get', { baseUrl: baseUrlOption, id: itemId }, ({ baseUrl, id }) => handleGet(baseUrl, id))

const root = Command.make('my-tool', {}).pipe(Command.withSubcommands([list, get]))

const cli = Command.run(root, {
  name: 'my-tool',
  version: '0.1.0',
})

// --- Entry point ---

cli(process.argv).pipe(Effect.provide(NodeContext.layer), Effect.provide(FetchHttpClient.layer), NodeRuntime.runMain)
