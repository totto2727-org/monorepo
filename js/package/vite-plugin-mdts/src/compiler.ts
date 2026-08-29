import { Predicate, String } from 'effect'
import ts from 'typescript'

export interface LinkRequest {
  readonly hash: string | undefined
  readonly path: string
  readonly query: string
  readonly text: string | undefined
}

interface CompileMarkdownModuleOptions {
  readonly code: string
  readonly id: string
  readonly resolveLink: (specifier: string) => Promise<string>
}

export interface CompiledMarkdownModule {
  readonly code: string
  readonly source: string
}

interface FormatMarkdownLinkOptions {
  readonly destination: string
  readonly request: LinkRequest
  readonly title: string
}

export class MarkdownCompileError extends Error {
  readonly fileName: string
  override readonly name = 'MarkdownCompileError'

  constructor(fileName: string, message: string) {
    super(`${fileName}: ${message}`)
    this.fileName = fileName
  }
}

export const parseLinkRequest = (id: string): LinkRequest | undefined => {
  const queryIndex = id.indexOf('?')
  if (queryIndex === -1) {
    return undefined
  }

  const path = id.slice(0, queryIndex)
  const query = id.slice(queryIndex + 1)
  const parameters = new URLSearchParams(query)
  if (!path.endsWith('.md.ts') || !parameters.has('link')) {
    return undefined
  }

  return {
    hash: parameters.get('hash') ?? undefined,
    path,
    query,
    text: parameters.get('text') ?? undefined,
  }
}

const escapeLinkText = (text: string): string =>
  text.replaceAll('\\', '\\\\').replaceAll('[', '\\[').replaceAll(']', '\\]')

export const formatMarkdownLink = (options: FormatMarkdownLinkOptions): string => {
  const text = options.request.text ?? options.title
  const hashValue = options.request.hash
  const hash = Predicate.isString(hashValue) && String.isNonEmpty(hashValue) ? `#${encodeURIComponent(hashValue)}` : ''

  return `[${escapeLinkText(text)}](${options.destination}${hash})`
}

const findLinkImports = (sourceFile: ts.SourceFile): ReadonlyMap<string, string> => {
  const imports = new Map<string, string>()

  for (const statement of sourceFile.statements) {
    if (!ts.isImportDeclaration(statement) || !ts.isStringLiteral(statement.moduleSpecifier)) {
      continue
    }

    const request = parseLinkRequest(statement.moduleSpecifier.text)
    const binding = statement.importClause?.name
    if (request && binding) {
      imports.set(binding.text, statement.moduleSpecifier.text)
    }
  }

  return imports
}

const findMarkdownTemplate = (sourceFile: ts.SourceFile): ts.TemplateLiteral => {
  for (const statement of sourceFile.statements) {
    if (!ts.isExportAssignment(statement) || statement.isExportEquals === true) {
      continue
    }

    const { expression } = statement
    if (ts.isTaggedTemplateExpression(expression) && ts.isIdentifier(expression.tag) && expression.tag.text === 'md') {
      return expression.template
    }
  }

  throw new MarkdownCompileError(sourceFile.fileName, 'expected a default export using the md tagged template')
}

export const compileMarkdownModule = async (options: CompileMarkdownModuleOptions): Promise<CompiledMarkdownModule> => {
  const sourceFile = ts.createSourceFile(options.id, options.code, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS)
  const template = findMarkdownTemplate(sourceFile)
  const linkImports = findLinkImports(sourceFile)

  if (ts.isNoSubstitutionTemplateLiteral(template)) {
    return { code: `export default ${JSON.stringify(template.text)}\n`, source: template.text }
  }

  const spans = template.templateSpans.map((span) => {
    if (!ts.isIdentifier(span.expression)) {
      throw new MarkdownCompileError(options.id, 'md interpolations must reference a ?link default import')
    }

    const specifier = linkImports.get(span.expression.text)
    if (!Predicate.isString(specifier)) {
      throw new MarkdownCompileError(options.id, `interpolation ${span.expression.text} is not a ?link default import`)
    }

    return { literal: span.literal.text, specifier }
  })

  const interpolations = await Promise.all(
    spans.map(async (span) => `${await options.resolveLink(span.specifier)}${span.literal}`),
  )
  const source = `${template.head.text}${interpolations.join('')}`
  const dependencies = new Set(spans.map((span) => span.specifier))

  const imports = [...dependencies].map((specifier) => `import ${JSON.stringify(specifier)}`).join('\n')

  return { code: `${imports}\nexport default ${JSON.stringify(source)}\n`, source }
}

const findMetadataObject = (sourceFile: ts.SourceFile): ts.ObjectLiteralExpression | undefined => {
  for (const statement of sourceFile.statements) {
    if (!ts.isVariableStatement(statement)) {
      continue
    }

    const exported =
      ts.getModifiers(statement)?.some((modifier) => modifier.kind === ts.SyntaxKind.ExportKeyword) ?? false
    if (!exported) {
      continue
    }

    for (const declaration of statement.declarationList.declarations) {
      if (ts.isIdentifier(declaration.name) && declaration.name.text === 'meta' && declaration.initializer) {
        const { initializer } = declaration
        return ts.isObjectLiteralExpression(initializer) ? initializer : undefined
      }
    }
  }

  return undefined
}

export const readMarkdownTitle = (fileName: string): string => {
  const code = ts.sys.readFile(fileName)
  if (!Predicate.isString(code)) {
    throw new MarkdownCompileError(fileName, 'could not read the linked document')
  }

  const sourceFile = ts.createSourceFile(fileName, code, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS)
  const metadata = findMetadataObject(sourceFile)

  for (const property of metadata?.properties ?? []) {
    if (!ts.isPropertyAssignment(property)) {
      continue
    }

    const name = ts.isIdentifier(property.name) || ts.isStringLiteral(property.name) ? property.name.text : undefined
    if (name === 'title' && ts.isStringLiteralLike(property.initializer)) {
      return property.initializer.text
    }
  }

  throw new MarkdownCompileError(fileName, 'expected a static meta.title string for ?link imports')
}
