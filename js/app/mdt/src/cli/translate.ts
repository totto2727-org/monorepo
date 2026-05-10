import { Effect } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import * as Locale from '#@/lib/locale.ts'
import { targetPath } from '#@/lib/path.ts'
import * as OpencodeService from '#@/service/opencode.ts'
import * as Output from '#@/service/output.ts'

export const translateCommand = Command.make(
  'mdt',
  {
    file: Argument.string('file'),
    force: Flag.boolean('force').pipe(Flag.withAlias('f'), Flag.withDescription('Overwrite existing output file')),
    lang: Flag.string('lang').pipe(Flag.withAlias('l'), Flag.withDescription('Target language code (e.g. ja, ja-JP)')),
    model: Flag.string('model').pipe(
      Flag.withAlias('m'),
      Flag.withDefault('opencode-go/deepseek-v4-flash'),
      Flag.withDescription('Model in provider/model format'),
    ),
  },
  (config) =>
    Effect.gen(function* () {
      const lang = yield* Locale.normalize(config.lang)
      const output = targetPath(config.file, lang)
      const text = yield* Output.readText(config.file)
      const translated = yield* OpencodeService.translate({
        lang,
        model: config.model,
        text,
      })
      yield* Output.writeText(output, translated, config.force)
      yield* Effect.log(`Written to ${output}`)
    }),
).pipe(Command.withDescription('Translate a markdown file via opencode'))
