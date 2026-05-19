import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { allKinds, getKindConfig } from '#@/schema/marketplace-kind.ts'

export const hasSupportedPluginFormat = async (dirPath: string): Promise<boolean> => {
  for (const kind of allKinds) {
    try {
      await Fs.access(NodePath.join(dirPath, getKindConfig(kind).configDir))
      return true
    } catch {
      // keep checking other supported formats
    }
  }

  return false
}
