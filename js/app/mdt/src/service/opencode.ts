import { createOpencode } from '@opencode-ai/sdk'
import { Effect } from 'effect'

import { TranslateError } from '#@/lib/translate-error.ts'

interface TranslateInput {
  readonly text: string
  readonly lang: string
  readonly model: string
}

const buildSystemPrompt = (lang: string): string =>
  [
    `You are a markdown translator. Translate the user's input markdown to ${lang}.`,
    'Strict rules:',
    '- Preserve all code blocks, inline code, links, HTML tags, and YAML/TOML frontmatter exactly as-is (do not translate code, URLs, fence languages, or attribute values).',
    '- Translate prose in headings, paragraphs, lists, blockquotes, and table cells.',
    '- Keep the original markdown structure (heading levels, list markers, blank lines).',
    '- Output ONLY the translated markdown. No commentary, no explanation, no fence wrapping.',
  ].join('\n')

const parseModel = (raw: string): { providerID: string; modelID: string } | null => {
  const slash = raw.indexOf('/')
  if (slash <= 0 || slash >= raw.length - 1) {
    return null
  }
  return { modelID: raw.slice(slash + 1), providerID: raw.slice(0, slash) }
}

export const translate = (input: TranslateInput): Effect.Effect<string, TranslateError> =>
  Effect.acquireUseRelease(
    Effect.tryPromise({
      catch: (error) => new TranslateError({ error }),
      try: () => createOpencode(),
    }),
    (opencode) =>
      Effect.gen(function* () {
        const { client } = opencode

        const toolIdsRes = yield* Effect.tryPromise({
          catch: (error) => new TranslateError({ error }),
          try: () => client.tool.ids(),
        })
        const toolIds = toolIdsRes.data ?? []
        const disabledTools = Object.fromEntries(toolIds.map((id) => [id, false]))

        const sessionRes = yield* Effect.tryPromise({
          catch: (error) => new TranslateError({ error }),
          try: () => client.session.create({ body: { title: 'mdt-translate' } }),
        })
        const session = sessionRes.data
        if (!session) {
          return yield* Effect.fail(new TranslateError({ message: 'Failed to create opencode session' }))
        }

        const model = parseModel(input.model)
        if (!model) {
          return yield* Effect.fail(new TranslateError({ message: `Invalid model format: ${input.model}` }))
        }

        yield* Effect.tryPromise({
          catch: (error) => new TranslateError({ error }),
          try: () =>
            client.session.prompt({
              body: {
                model,
                parts: [{ text: input.text, type: 'text' }],
                system: buildSystemPrompt(input.lang),
                tools: disabledTools,
              },
              path: { id: session.id },
            }),
        })

        const messagesRes = yield* Effect.tryPromise({
          catch: (error) => new TranslateError({ error }),
          try: () => client.session.messages({ path: { id: session.id } }),
        })
        const messages = messagesRes.data ?? []

        const lastAssistant = messages.findLast((message) => message.info.role === 'assistant')
        const assistantText = lastAssistant
          ? lastAssistant.parts
              .filter((part) => part.type === 'text')
              .map((part) => part.text)
              .join('')
          : ''

        if (!assistantText) {
          return yield* Effect.fail(new TranslateError({ message: 'No text output from model' }))
        }

        return assistantText
      }),
    (opencode) =>
      Effect.sync(() => {
        opencode.server.close()
      }),
  )
