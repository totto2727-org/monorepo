import { Predicate, Schema } from 'effect'

export type MarkdownFrontmatterValue =
  | boolean
  | null
  | number
  | string
  | readonly MarkdownFrontmatterValue[]
  | { readonly [key: string]: MarkdownFrontmatterValue }

export interface MarkdownMetadata {
  readonly frontmatter?: Readonly<Record<string, MarkdownFrontmatterValue>>
  readonly title: string
}

export interface MarkdownLinkReference {
  readonly hash: string | undefined
  readonly kind: 'vite-plugin-mdts/link'
  readonly targetPath: string
  readonly text: string | undefined
}

export interface MarkdownTemplate {
  readonly kind: 'vite-plugin-mdts/template'
  readonly strings: readonly string[]
  readonly values: readonly MarkdownTemplateValue[]
}

export type MarkdownTemplateValue = bigint | MarkdownLinkReference | MarkdownTemplate | number | string
export type MarkdownContent = MarkdownLinkReference | MarkdownTemplate | string

export interface MarkdownNoteInput {
  readonly body: MarkdownContent
  readonly slug: string
}

export interface MarkdownNote extends MarkdownNoteInput {
  readonly index: string
}

export type DefinedMarkdownNotes<
  Notes extends readonly MarkdownNoteInput[],
  Position extends readonly unknown[] = readonly [],
> = Notes extends readonly []
  ? readonly []
  : Notes extends readonly [infer Note extends MarkdownNoteInput, ...infer Rest extends readonly MarkdownNoteInput[]]
    ? readonly [
        Readonly<Note & { readonly index: `${[...Position, unknown]['length']}` }>,
        ...DefinedMarkdownNotes<Rest, readonly [...Position, unknown]>,
      ]
    : readonly MarkdownNote[]

const createMarkdownTemplate = (
  strings: readonly string[],
  values: readonly MarkdownTemplateValue[],
): MarkdownTemplate =>
  Object.freeze({
    kind: 'vite-plugin-mdts/template' as const,
    strings: Object.freeze([...strings]),
    values: Object.freeze([...values]),
  })

export const md = (strings: TemplateStringsArray, ...values: readonly MarkdownTemplateValue[]): MarkdownTemplate =>
  createMarkdownTemplate(strings, values)

const invalidFrontmatter = (path: string): never => {
  throw new TypeError(`${path} must contain only strings, numbers, booleans, null, arrays, or objects`)
}

const validateFrontmatterValue = (
  value: unknown,
  path: string,
  ancestors: ReadonlySet<object>,
): MarkdownFrontmatterValue => {
  // oxlint-disable-next-line rules/prefer-is-nullish -- null is a valid frontmatter value while undefined is invalid.
  if (Schema.is(Schema.Null)(value) || Predicate.isBoolean(value) || Predicate.isString(value)) {
    return value
  }
  if (Predicate.isNumber(value) && Number.isFinite(value)) {
    return value
  }
  if (Array.isArray(value)) {
    if (ancestors.has(value)) {
      throw new TypeError(`${path} must not contain circular references`)
    }
    const nestedAncestors = new Set(ancestors).add(value)
    return value.map((item, index) => validateFrontmatterValue(item, `${path}[${index}]`, nestedAncestors))
  }
  if (Predicate.isObject(value) && !Array.isArray(value)) {
    const prototype: unknown = Object.getPrototypeOf(value)
    // oxlint-disable-next-line rules/prefer-is-nullish -- A null prototype is valid, while undefined cannot be returned by Object.getPrototypeOf.
    if (prototype !== Object.prototype && !Schema.is(Schema.Null)(prototype)) {
      return invalidFrontmatter(path)
    }
    if (ancestors.has(value)) {
      throw new TypeError(`${path} must not contain circular references`)
    }
    const nestedAncestors = new Set(ancestors).add(value)
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [
        key,
        validateFrontmatterValue(item, `${path}.${key}`, nestedAncestors),
      ]),
    )
  }
  return invalidFrontmatter(path)
}

export const validateMarkdownMetadata = (value: unknown): MarkdownMetadata => {
  if (!Predicate.isObject(value) || Array.isArray(value)) {
    throw new TypeError('meta must be an object')
  }

  const title: unknown = Reflect.get(value, 'title')
  if (!Predicate.isString(title)) {
    throw new TypeError('meta.title must be a string')
  }

  const frontmatterValue: unknown = Reflect.get(value, 'frontmatter')
  // oxlint-disable-next-line rules/prefer-is-nullish -- undefined means the optional property is absent, while null is invalid metadata.
  if (Schema.is(Schema.Undefined)(frontmatterValue)) {
    return { title }
  }
  if (!Predicate.isObject(frontmatterValue) || Array.isArray(frontmatterValue)) {
    throw new TypeError('meta.frontmatter must be an object')
  }

  const frontmatter = validateFrontmatterValue(frontmatterValue, 'meta.frontmatter', new Set())
  if (!Predicate.isObject(frontmatter) || Array.isArray(frontmatter)) {
    throw new TypeError('meta.frontmatter must be an object')
  }
  return { frontmatter, title }
}

export const defineMeta = <const Metadata extends MarkdownMetadata>(metadata: Metadata): Readonly<Metadata> => {
  validateMarkdownMetadata(metadata)
  return Object.freeze(metadata)
}

export const isMarkdownLinkReference = (value: unknown): boolean =>
  Predicate.isObject(value) &&
  !Array.isArray(value) &&
  Reflect.get(value, 'kind') === 'vite-plugin-mdts/link' &&
  Predicate.isString(Reflect.get(value, 'targetPath'))

const optionalString = (value: unknown, name: string): string | undefined => {
  if (Predicate.isNullish(value)) {
    return undefined
  }
  if (!Predicate.isString(value)) {
    throw new TypeError(`${name} must be a string`)
  }
  return value
}

export const decodeMarkdownLinkReference = (value: unknown): MarkdownLinkReference => {
  if (!Predicate.isObject(value) || Array.isArray(value) || !isMarkdownLinkReference(value)) {
    throw new TypeError('expected a Markdown link reference')
  }
  const targetPath: unknown = Reflect.get(value, 'targetPath')
  if (!Predicate.isString(targetPath)) {
    throw new TypeError('Markdown link targetPath must be a string')
  }
  return Object.freeze({
    hash: optionalString(Reflect.get(value, 'hash'), 'Markdown link hash'),
    kind: 'vite-plugin-mdts/link' as const,
    targetPath,
    text: optionalString(Reflect.get(value, 'text'), 'Markdown link text'),
  })
}

export const isMarkdownTemplate = (value: unknown): boolean =>
  Predicate.isObject(value) &&
  !Array.isArray(value) &&
  Reflect.get(value, 'kind') === 'vite-plugin-mdts/template' &&
  Array.isArray(Reflect.get(value, 'strings')) &&
  Array.isArray(Reflect.get(value, 'values'))

export const decodeMarkdownTemplate = (value: unknown): MarkdownTemplate => {
  if (!Predicate.isObject(value) || Array.isArray(value) || !isMarkdownTemplate(value)) {
    throw new TypeError('expected a Markdown template')
  }
  const strings: unknown = Reflect.get(value, 'strings')
  const values: unknown = Reflect.get(value, 'values')
  if (!Array.isArray(strings) || !Array.isArray(values)) {
    throw new TypeError('expected a Markdown template')
  }
  const decodeValue = (templateValue: unknown): MarkdownTemplateValue => {
    if (Predicate.isBigInt(templateValue) || Predicate.isNumber(templateValue) || Predicate.isString(templateValue)) {
      return templateValue
    }
    if (isMarkdownLinkReference(templateValue)) {
      return decodeMarkdownLinkReference(templateValue)
    }
    if (isMarkdownTemplate(templateValue)) {
      return decodeMarkdownTemplate(templateValue)
    }
    throw new TypeError('Markdown template values must be strings, numbers, links, or Markdown templates')
  }
  return createMarkdownTemplate(
    strings.map((segment) => {
      if (!Predicate.isString(segment)) {
        throw new TypeError('Markdown template strings must be strings')
      }
      return segment
    }),
    values.map(decodeValue),
  )
}

export function defineNote<const Notes extends readonly MarkdownNoteInput[]>(notes: Notes): DefinedMarkdownNotes<Notes>
export function defineNote(notes: readonly MarkdownNoteInput[]): readonly MarkdownNote[] {
  const slugs = new Set<string>()
  const definitions = notes.map((note, index) => {
    if (slugs.has(note.slug)) {
      throw new TypeError(`Duplicate Markdown note slug: ${note.slug}`)
    }
    slugs.add(note.slug)
    return Object.freeze({ ...note, index: `${index + 1}` })
  })
  return Object.freeze(definitions)
}

const findNote = <Notes extends readonly MarkdownNote[]>(notes: Notes, slug: Notes[number]['slug']): MarkdownNote => {
  const note = notes.find((candidate) => candidate.slug === slug)
  if (Predicate.isNullish(note)) {
    throw new TypeError(`Unknown Markdown note slug: ${slug}`)
  }
  return note
}

export const noteRef = <Notes extends readonly MarkdownNote[]>(notes: Notes, slug: Notes[number]['slug']): string =>
  `[^${findNote(notes, slug).index}]`

export const noteBody = <Notes extends readonly MarkdownNote[]>(
  notes: Notes,
  slug: Notes[number]['slug'],
): MarkdownTemplate => {
  const note = findNote(notes, slug)
  return createMarkdownTemplate([`[^${note.index}]: `, ''], [note.body])
}
