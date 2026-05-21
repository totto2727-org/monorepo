import { Context, Data } from 'effect'
import type { Effect } from 'effect'

export interface SendParams {
  readonly to: string
  readonly subject: string
  readonly text: string
  readonly html?: string
}

export type SentEmail = SendParams

export class EmailSendError extends Data.TaggedError('EmailSendError')<{
  readonly message: string
}> {}

export interface EmailSender {
  readonly send: (params: SendParams) => Effect.Effect<void, EmailSendError>
}

export const Service = Context.Service<EmailSender>('@app/identity-provider/feature/email/sender/Service')
