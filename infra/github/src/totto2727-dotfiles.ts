import * as pulumi from '@pulumi/pulumi'

import { createRepositoryFactory } from './repository.ts'

const createRepository = createRepositoryFactory(
  'totto2727-dotfiles',
  new pulumi.Config('githubOwners').requireSecret('totto2727DotfilesToken'),
)

// Merge nix#1 to install CI before applying this policy.
export const nix = createRepository('nix')
