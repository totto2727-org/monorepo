import forceArrayEmpty from './rules/force-array-empty.ts'
import forceIterableEmpty from './rules/force-iterable-empty.ts'
import forcePredicate from './rules/force-predicate.ts'
import forceStringEmpty from './rules/force-string-empty.ts'
import forceTsExtension from './rules/force-ts-extension.ts'
import noEffectImportAs from './rules/no-effect-import-as.ts'
import noEffectRuntimeRun from './rules/no-effect-runtime-run.ts'
import noEffectSubpathImport from './rules/no-effect-subpath-import.ts'
import noErrorCauseOption from './rules/no-error-cause-option.ts'
import noErrorPropertyAccess from './rules/no-error-property-access.ts'
import noEslintDisableComments from './rules/no-eslint-disable-comments.ts'
import noFetch from './rules/no-fetch.ts'
import noInstanceofError from './rules/no-instanceof-error.ts'
import noJsDate from './rules/no-js-date.ts'
import noJsxScriptTag from './rules/no-jsx-script-tag.ts'
import noLet from './rules/no-let.ts'
import noNodeImports from './rules/no-node-imports.ts'
import noOptionTagComparison from './rules/no-option-tag-comparison.ts'
import noRedundantAlias from './rules/no-redundant-alias.ts'
import noStringStyle from './rules/no-string-style.ts'
import noSyncDecode from './rules/no-sync-decode.ts'
import noTypePredicate from './rules/no-type-predicate.ts'
import preferIsNullish from './rules/prefer-is-nullish.ts'
import preferNonUnknownDecode from './rules/prefer-non-unknown-decode.ts'
import requireDisableReason from './rules/require-disable-reason.ts'
import requireTopLevelDecoder from './rules/require-top-level-decoder.ts'

const plugin = {
  meta: { name: 'rules' },
  rules: {
    'force-array-empty': forceArrayEmpty,
    'force-iterable-empty': forceIterableEmpty,
    'force-predicate': forcePredicate,
    'force-string-empty': forceStringEmpty,
    'force-ts-extension': forceTsExtension,
    'no-effect-import-as': noEffectImportAs,
    'no-effect-runtime-run': noEffectRuntimeRun,
    'no-effect-subpath-import': noEffectSubpathImport,
    'no-error-cause-option': noErrorCauseOption,
    'no-error-property-access': noErrorPropertyAccess,
    'no-eslint-disable-comments': noEslintDisableComments,
    'no-fetch': noFetch,
    'no-instanceof-error': noInstanceofError,
    'no-js-date': noJsDate,
    'no-jsx-script-tag': noJsxScriptTag,
    'no-let': noLet,
    'no-node-imports': noNodeImports,
    'no-option-tag-comparison': noOptionTagComparison,
    'no-redundant-alias': noRedundantAlias,
    'no-string-style': noStringStyle,
    'no-sync-decode': noSyncDecode,
    'no-type-predicate': noTypePredicate,
    'prefer-is-nullish': preferIsNullish,
    'prefer-non-unknown-decode': preferNonUnknownDecode,
    'require-disable-reason': requireDisableReason,
    'require-top-level-decoder': requireTopLevelDecoder,
  },
}

export default plugin
