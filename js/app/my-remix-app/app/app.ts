import { Hono } from 'hono'
import { logger } from 'hono/logger'

import { counter } from './controllers/counter.tsx'
import { todo } from './controllers/todo.tsx'

const app = new Hono().use(logger()).get('/', counter).get('/todo', todo)

export default app
