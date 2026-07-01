import { getContext } from 'hono/context-storage'
import { createFrameHelpers } from 'remix-helper'

export type FrameName = 'login' | 'check-email' | 'register-passkey' | 'account'

const helpers = createFrameHelpers<FrameName>()

export const matchesFrameRequest = (frame: FrameName): boolean => helpers.isFrameRequest(getContext().req.raw, frame)
