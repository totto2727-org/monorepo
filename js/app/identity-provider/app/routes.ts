import { getContext } from 'hono/context-storage'
import { createFrameHelpers } from 'remix-helper'

export type FrameName = 'login' | 'check-email' | 'register-passkey' | 'account' | 'oauth-consent'

const helpers = createFrameHelpers<FrameName>()

export const isFrameRequest = (frame: FrameName): boolean => helpers.isFrameRequest(getContext().req.raw, frame)
