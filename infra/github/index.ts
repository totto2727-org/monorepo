import * as repositories from './src/totto2727-org.ts'

export const repositoryNames = Object.values(repositories).map(({ repository }) => repository.name)
export const rulesetIds = Object.values(repositories).map(({ ruleset }) => ruleset.id)
