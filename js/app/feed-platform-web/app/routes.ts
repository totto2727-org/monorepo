import { getContext } from 'hono/context-storage'
import { createFrameHelpers } from 'remix-helper'

export type FrameName = never

const helpers = createFrameHelpers<FrameName>()

export const isFrameRequest = (frame: FrameName): boolean => helpers.isFrameRequest(getContext().req.raw, frame)
