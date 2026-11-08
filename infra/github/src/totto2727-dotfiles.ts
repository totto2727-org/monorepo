import * as pulumi from '@pulumi/pulumi'

import { createRepositoryFactory } from './repository.ts'

const createRepository = createRepositoryFactory(
  'totto2727-dotfiles',
  new pulumi.Config('githubOwners').requireSecret('totto2727DotfilesToken'),
)

// CI in nix#1 is push-only. Require check only after PR validation is available.
export const nix = createRepository('nix', {}, [])
