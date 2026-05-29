// oxlint-disable max-classes-per-file -- TaggedError subclasses are grouped by domain
import type { DateTime, FileSystem } from 'effect'
import { Data, Effect, Predicate, Schema } from 'effect'

import type { Milestone, MilestoneStatus, Task } from '#@/feature/schema/current.ts'
import { Task as TaskSchema } from '#@/feature/schema/current.ts'
import type { ProgressFileNotFoundError, ProgressReadError, ProgressWriteError } from '#@/lib/progress.ts'
import { ProgressValidationError, readProgressFile, writeProgressFile } from '#@/lib/progress.ts'

import { findMilestone, MilestoneNotFoundError } from './milestone.ts'

export class TaskAlreadyExistsError extends Data.TaggedError('TaskAlreadyExistsError')<{
  readonly roadmapId: string
  readonly milestoneId: string
  readonly taskId: string
}> {}

export class TaskNotFoundError extends Data.TaggedError('TaskNotFoundError')<{
  readonly roadmapId: string
  readonly milestoneId: string
  readonly taskId: string
}> {}

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- draft is a partially-typed literal
const decodeTask = Schema.decodeUnknownEffect(TaskSchema)

export const findTask = (milestone: Milestone, taskId: string): Task | undefined =>
  milestone.tasks.find((t) => t.id === taskId)

const replaceTaskInMilestones = (
  milestones: readonly Milestone[],
  milestoneId: string,
  taskId: string,
  update: (t: Task) => Task,
): readonly Milestone[] =>
  milestones.map((m) =>
    m.id === milestoneId ? { ...m, tasks: m.tasks.map((t) => (t.id === taskId ? update(t) : t)) } : m,
  )

export interface AddTaskInput {
  readonly dir: string
  readonly roadmapId: string
  readonly milestoneId: string
  readonly taskId: string
  readonly title: string
  readonly now: DateTime.Utc
}

export const addTask = (
  input: AddTaskInput,
): Effect.Effect<
  { readonly progressPath: string },
  | MilestoneNotFoundError
  | ProgressFileNotFoundError
  | ProgressReadError
  | ProgressValidationError
  | ProgressWriteError
  | TaskAlreadyExistsError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const progress = yield* readProgressFile({ dir: input.dir, roadmapId: input.roadmapId })

    const milestone = findMilestone(progress, input.milestoneId)
    if (Predicate.isNullish(milestone)) {
      return yield* new MilestoneNotFoundError({
        milestoneId: input.milestoneId,
        roadmapId: input.roadmapId,
      })
    }

    if (milestone.tasks.some((t) => t.id === input.taskId)) {
      return yield* new TaskAlreadyExistsError({
        milestoneId: input.milestoneId,
        roadmapId: input.roadmapId,
        taskId: input.taskId,
      })
    }

    const task = yield* decodeTask({
      id: input.taskId,
      notes: null,
      prs: [],
      status: 'planned',
      title: input.title,
      workflow_identifiers: [],
    }).pipe(Effect.mapError((error) => new ProgressValidationError({ message: String(error) })))

    const updatedMilestones = progress.milestones.map((m) =>
      m.id === input.milestoneId ? { ...m, tasks: [...m.tasks, task] } : m,
    )

    const result = yield* writeProgressFile({
      data: { ...progress, milestones: updatedMilestones, updated_at: input.now },
      dir: input.dir,
      roadmapId: input.roadmapId,
    })

    return { progressPath: result.path }
  })

const ensureTask = (
  progress: { readonly milestones: readonly Milestone[] },
  roadmapId: string,
  milestoneId: string,
  taskId: string,
): Effect.Effect<Milestone, MilestoneNotFoundError | TaskNotFoundError> => {
  const milestone = findMilestone(progress, milestoneId)
  if (Predicate.isNullish(milestone)) {
    return Effect.fail(new MilestoneNotFoundError({ milestoneId, roadmapId }))
  }
  if (Predicate.isNullish(findTask(milestone, taskId))) {
    return Effect.fail(new TaskNotFoundError({ milestoneId, roadmapId, taskId }))
  }
  return Effect.succeed(milestone)
}

export interface UpdateTaskStatusInput {
  readonly dir: string
  readonly roadmapId: string
  readonly milestoneId: string
  readonly taskId: string
  readonly status: MilestoneStatus
  readonly now: DateTime.Utc
}

export const updateTaskStatus = (
  input: UpdateTaskStatusInput,
): Effect.Effect<
  { path: string },
  | MilestoneNotFoundError
  | ProgressFileNotFoundError
  | ProgressReadError
  | ProgressValidationError
  | ProgressWriteError
  | TaskNotFoundError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const progress = yield* readProgressFile({ dir: input.dir, roadmapId: input.roadmapId })
    yield* ensureTask(progress, input.roadmapId, input.milestoneId, input.taskId)

    const updatedMilestones = replaceTaskInMilestones(progress.milestones, input.milestoneId, input.taskId, (t) => ({
      ...t,
      status: input.status,
    }))

    const result = yield* writeProgressFile({
      data: { ...progress, milestones: updatedMilestones, updated_at: input.now },
      dir: input.dir,
      roadmapId: input.roadmapId,
    })

    return { path: result.path }
  })

export interface UpdateTaskNoteInput {
  readonly dir: string
  readonly roadmapId: string
  readonly milestoneId: string
  readonly taskId: string
  readonly note: string | null
  readonly now: DateTime.Utc
}

export const updateTaskNote = (
  input: UpdateTaskNoteInput,
): Effect.Effect<
  { path: string },
  | MilestoneNotFoundError
  | ProgressFileNotFoundError
  | ProgressReadError
  | ProgressValidationError
  | ProgressWriteError
  | TaskNotFoundError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const progress = yield* readProgressFile({ dir: input.dir, roadmapId: input.roadmapId })
    yield* ensureTask(progress, input.roadmapId, input.milestoneId, input.taskId)

    const updatedMilestones = replaceTaskInMilestones(progress.milestones, input.milestoneId, input.taskId, (t) => ({
      ...t,
      notes: input.note,
    }))

    const result = yield* writeProgressFile({
      data: { ...progress, milestones: updatedMilestones, updated_at: input.now },
      dir: input.dir,
      roadmapId: input.roadmapId,
    })

    return { path: result.path }
  })

export interface UpdateTaskPrsInput {
  readonly dir: string
  readonly roadmapId: string
  readonly milestoneId: string
  readonly taskId: string
  readonly prs: readonly string[]
  readonly append: boolean
  readonly now: DateTime.Utc
}

export const updateTaskPrs = (
  input: UpdateTaskPrsInput,
): Effect.Effect<
  { path: string },
  | MilestoneNotFoundError
  | ProgressFileNotFoundError
  | ProgressReadError
  | ProgressValidationError
  | ProgressWriteError
  | TaskNotFoundError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const progress = yield* readProgressFile({ dir: input.dir, roadmapId: input.roadmapId })
    yield* ensureTask(progress, input.roadmapId, input.milestoneId, input.taskId)

    const updatedMilestones = replaceTaskInMilestones(progress.milestones, input.milestoneId, input.taskId, (t) => {
      if (!input.append) {
        return { ...t, prs: [...input.prs] }
      }
      const seen = new Set(t.prs)
      const merged = [...t.prs]
      for (const pr of input.prs) {
        if (seen.has(pr)) {
          continue
        }
        seen.add(pr)
        merged.push(pr)
      }
      return { ...t, prs: merged }
    })

    const result = yield* writeProgressFile({
      data: { ...progress, milestones: updatedMilestones, updated_at: input.now },
      dir: input.dir,
      roadmapId: input.roadmapId,
    })

    return { path: result.path }
  })
