# Research Note: skills-lock registry & plugin loader

- **Identifier:** 2026-05-04-totto2727-coding-plugin
- **Topic:** skills-lock-registry
- **Researcher:** researcher (skills-lock observation perspective)
- **Created at:** 2026-05-04
- **Scope:** Intent Spec の Open Question #1 (dotfiles 側 registry 更新の要否) と #2 (新プラグイン登録形式) を、`.agents/skills-lock.json` のスキーマ・loader 実装・marketplace.json の解決経路から確定する。

## Subject of investigation

本 Note は以下に限定する:

- `.agents/skills-lock.json` のスキーマと現状エントリの意味 (`repositories[]`, `plugins[]`, `enabledSkills`, `skillDirs`, `version`)
- Lock ファイルを読み込む側 (loader) の実装 = 本リポジトリ `js/app/c-plugin/` (Effect ベースの CLI ツール) の挙動
- `.claude-plugin/marketplace.json` (本リポジトリ / dotfiles 双方) と lock ファイルの依存関係
- 新プラグイン `totto2727-coding` を本リポジトリで有効化するために、どの登録方式 (A: dotfiles repo に追加, B: `skillDirs[]` 利用, C: 本リポジトリ自身を `repositories[]` の source とする, D: その他) が技術的に適合するか

スコープ外: `coding/SKILL.md` 構造設計、`test/SKILL.md` の TS セクション扱い、CLAUDE.md への追記要否、移行スクリプト書き換え (他観点 / 後続ステップが扱う)。

## Findings

### 1. lock ファイルのスキーマ (Effect Schema)

- スキーマ定義: `js/app/c-plugin/src/schema/lock-file.ts:11-19`

  ```ts
  export const RepositoryEntry = Schema.Struct({
    commitHash: Schema.String,
    marketplaceKind: Schema.Literals(['claude', 'cursor', 'codex']),
    plugins: Schema.Array(PluginEntry),
    source: Schema.String,
    sourceType: Schema.Literal('github'),
  })
  ```

  - `sourceType` は **`'github'` 固定リテラル** (それ以外を許容しない)。
  - `marketplaceKind` フィールドが現状スキーマには **存在する** が、本リポジトリ `.agents/skills-lock.json:1-23` の `repositories[0]` には欠落している (旧版のまま) → Step 6 でバリデーション通過のために `marketplaceKind: "claude"` を補う必要がある。

- `skillDirs` の意味: `js/app/c-plugin/src/service/symlink.ts:33-36`

  ```ts
  const getAllDirs = (agentsDir: string, skillDirs: readonly string[]): string[] => {
    const primary = getSkillsDir(agentsDir)
    return [primary, ...skillDirs]
  }
  ```

  → `skillDirs` は **「skill symlink を追加で張る出力先ディレクトリ」** であり、**プラグイン / スキルを「登録」する仕組みではない**。`.claude/skills/` のように plugin 非対応環境向けに symlink をミラーする用途。

- `target add` コマンド (`js/app/c-plugin/src/cli/skill/target/add.ts:8-32`) は `path` 引数を受け取り `lockFile.skillDirs` に push するだけ。プラグインとは無関係。

### 2. lock ファイルを読み込む loader = 本リポジトリ内 `c-plugin` CLI

- ADR `docs/adr/2026-04-06-c-plugin-cli-tool.md:1-211` で本リポジトリ内 `js/app/c-plugin/` が **lock ファイルの単一 owner** であることが確定済み (npm 公開予定 `c-plugin`)。
- Path 解決: `js/app/c-plugin/src/lib/paths.ts:13`

  ```ts
  export const getLockFilePath = (agentsDir: string): string => NodePath.join(agentsDir, 'skills-lock.json')
  ```

  CWD の `.agents/skills-lock.json` または `~/.agents/skills-lock.json` (`-g`) を読む。

- Sync の流れ: `js/app/c-plugin/src/service/sync.ts:14-80` (抜粋)

  ```ts
  for (const repo of lockFile.repositories) {
    yield* Effect.log(`Syncing ${repo.source}...`)
    const repoDir = yield* Cache.ensureRepo(agentsDir, repo.source)
    yield* Git.checkout(repoDir, repo.commitHash)
    const availableSkills = yield* SkillResolver.resolveFromRepo(repoDir, repo.marketplaceKind)
    ...
  }
  ```

  → `repositories[]` の各エントリは **必ず GitHub clone される** (`Cache.ensureRepo` 経由)。

- `Cache.ensureRepo`: `js/app/c-plugin/src/service/cache.ts:17-29`

  ```ts
  export const ensureRepo = (agentsDir: string, source: string) => {
    const repoDir = getRepoCacheDir(agentsDir, source)
    return Effect.tryPromise({...}).pipe(
      Effect.map(() => repoDir),
      Effect.catchTag('GitError', () => {
        const url = getGitHubCloneUrl(source)
        return Git.clone(url, repoDir).pipe(...)
      }),
    )
  }
  ```

  `getGitHubCloneUrl` は `js/app/c-plugin/src/lib/paths.ts:34` で `https://github.com/${source}.git` 固定。
  → **`source` に "本リポジトリのローカルパス" や "." 等を指定すると `git clone https://github.com/./.git` 相当の不正 URL となり失敗する**。

- Skill resolver: `js/app/c-plugin/src/service/skill-resolver.ts:88-108` は cache 済みの `repoDir` から `.claude-plugin/marketplace.json` を読み、その `plugins[].source` で示された相対パス配下の `skills/*/SKILL.md` を列挙する。**つまり `repositories[]` 配下のプラグインは "GitHub 上の marketplace.json で公開されているプラグインの中から選ばれる" 必要がある**。

### 3. 本リポジトリと dotfiles 双方の marketplace.json

- 本リポジトリ `.claude-plugin/marketplace.json:1-27`: `name: totto2727`, `plugins: [totto2727, moonbit, components-build, dev-workflow]` (4 件、すべて `./plugins/<name>` 相対)。
- dotfiles リポジトリ `totto2727-dotfiles/agents/.claude-plugin/marketplace.json` (WebFetch 確認): `plugins: [totto2727, moonbit, components-build]` (3 件)。**`dev-workflow` は dotfiles 側に存在せず、本リポジトリ側のみで宣言されている**。
- dotfiles `plugins/` 配下 (WebFetch 確認): `totto2727`, `moonbit`, `components-build` の 3 ディレクトリ。
- 本リポジトリ `.agents/skills-lock.json:14-19` の `source: "totto2727-dotfiles/agents"` は dotfiles を指している → `c-plugin sync` 実行時には dotfiles が clone され、dotfiles 側の `moonbit` / `components-build` プラグインが解決される (現リポジトリ内の `plugins/moonbit/` ではない)。

### 4. `add` コマンドで取れる選択肢

- `js/app/c-plugin/src/cli/skill/add.ts:30-125`: `c-plugin skill add <repo>` は `repo` 引数を `parseRepoSource` (`paths.ts:20-32`) で `owner/repo` 形式でしか受け付けない (`parts.length !== 2` で reject)。**ローカルパス・URL は不可**。
- 結果として本リポジトリ単独で完結する手段は **lock ファイルを直接編集する** か **dotfiles を経由する** の 2 択しかない。

### 5. 現行 lock ファイルの schema 不整合

- 本リポジトリ `.agents/skills-lock.json:1-23` には `marketplaceKind` フィールドが**ない**。スキーマ (`lock-file.ts:11-19`) では required → 現在 `c-plugin sync` を実行すると `LockFileCorruptError` 相当の decode 失敗となる可能性。
- これは Step 6 で必ず修正対象となる。

## Sources

- `.agents/skills-lock.json:1-23` (現行 lock 内容)
- `.claude-plugin/marketplace.json:1-27` (本リポジトリ marketplace)
- `js/app/c-plugin/src/schema/lock-file.ts:1-33` (lock スキーマ全体)
- `js/app/c-plugin/src/schema/marketplace.ts:1-55` (marketplace スキーマ)
- `js/app/c-plugin/src/lib/paths.ts:1-35` (`getLockFilePath` / `getGitHubCloneUrl` / `parseRepoSource`)
- `js/app/c-plugin/src/service/cache.ts:17-29` (GitHub clone 強制)
- `js/app/c-plugin/src/service/sync.ts:14-80` (sync フロー)
- `js/app/c-plugin/src/service/skill-resolver.ts:88-108` (marketplace → skills 解決)
- `js/app/c-plugin/src/service/symlink.ts:33-36` (`skillDirs` の真の用途)
- `js/app/c-plugin/src/cli/skill/add.ts:30-125` (add コマンド)
- `js/app/c-plugin/src/cli/skill/target/add.ts:8-32` (target add コマンド)
- `docs/adr/2026-04-06-c-plugin-cli-tool.md:1-211` (c-plugin 設計 ADR)
- `docs/adr/2026-04-16-c-plugin-recursive-sync-and-gitignore.md:1-50` (recursive sync ADR)
- WebFetch: `https://raw.githubusercontent.com/totto2727-dotfiles/agents/main/.claude-plugin/marketplace.json` (dotfiles marketplace に `totto2727` / `moonbit` / `components-build` の 3 件のみ存在、`dev-workflow` は不在)
- WebFetch: `https://github.com/totto2727-dotfiles/agents/tree/main/plugins` (`plugins/` 配下に同 3 ディレクトリ存在)

## Implications for design

### 結論: 採用すべき方式は **A 改 (dotfiles 側に `totto2727-coding` を追加する) のみ実現可能**

ただしこれは Intent Spec の "Out of scope: dotfiles 側更新は本サイクル外" と直接衝突する。Architect (Step 3) はこの矛盾を必ず Main 経由でユーザー判断にエスカレーションすること。判断材料は以下のとおり整理した。

#### 各選択肢の評価

| 方式    | 内容                                                                                                                                                                                                                                                    | 実現可能性                     | 根拠                                                                                                                                                                                                                                |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A**   | dotfiles `totto2727-dotfiles/agents` の `.claude-plugin/marketplace.json` に `totto2727-coding` を追加し、dotfiles 側 `plugins/totto2727-coding/` に実体を置き、本リポジトリ lock では既存 `repositories[0].plugins[]` に `totto2727-coding` を追加する | **○ (唯一の正攻法)**           | `Cache.ensureRepo` は GitHub clone 必須 (`cache.ts:17-29`)。dotfiles の marketplace.json に登録すれば `SkillResolver.resolveFromRepo` (`skill-resolver.ts:88-108`) が拾える                                                         |
| **B**   | `skillDirs[]` に `./plugins/totto2727-coding` を追加                                                                                                                                                                                                    | **× (用途違い)**               | `skillDirs` は「symlink 出力先」(`symlink.ts:33-36`)。プラグイン解決には使われない。push しても `sync` が拾わない                                                                                                                   |
| **C**   | 本リポジトリ自身を `repositories[]` のエントリ (`source: "totto2727/monorepo"` 等) として追加                                                                                                                                                           | **△ (可能だが実用的に不適)**   | スキーマ上は `sourceType: 'github'` を満たせば許可されるが、`Cache.ensureRepo` が **本リポジトリを GitHub から clone しキャッシュ** する形になり、ローカル変更が反映されない (commit/push 後でないと sync 不可)。開発サイクルが破綻 |
| **D-1** | lock ファイルだけを「documentation 用」に書き換え、c-plugin の sync/symlink フローを使わない                                                                                                                                                            | **× (Intent Spec SC-5 違反)**  | SC-5 が `enabledSkills` への登録を観測可能要件として求めているが、symlink が張られないため実行時に Claude が認知しない                                                                                                              |
| **D-2** | c-plugin にローカル plugin 登録機能 (`sourceType: 'local'`) を新設してから本リポジトリの `plugins/totto2727-coding/` を直接登録                                                                                                                         | **× (本サイクルのスコープ外)** | c-plugin への機能追加は別サイクル。Intent Spec の Scope にも含まれない                                                                                                                                                              |

#### Architect への申し送り

1. **Intent Spec と技術現実が衝突している**。Intent Spec `## Out of scope` (`intent-spec.md:131-134`) は dotfiles 側更新を明示的にサイクル外とするが、技術的には方式 A (dotfiles 側更新) でしか目的を達成できない。これは **Specialist Common §4 Case B (前提崩壊)** に該当するため、Architect は本観点を Main 経由でユーザー判断にエスカレーションすること。
2. **ユーザー判断の選択肢は 2 つ**:
   - (i) **本サイクルのスコープを拡大**: dotfiles 側更新を本サイクルに取り込む。サブタスクとして dotfiles リポジトリ側で `totto2727-coding/` プラグイン作成 + marketplace.json 追記が発生する。さらに dotfiles 側のコミットを pin する `commitHash` 更新が本リポジトリ lock の更新と協調する必要がある。
   - (ii) **本サイクルを Step 1 にロールバック**: Intent Spec の Out of scope 条項を改訂し、dotfiles 側更新を含むようスコープを拡大、もしくはサイクル分割 (本サイクル = dotfiles 側準備のみ、後続サイクル = 本リポジトリ側 lock 更新) する。
3. **必須の付随修正 (どちらの選択肢でも実施)**: 本リポジトリ `.agents/skills-lock.json` の `repositories[0]` に **`marketplaceKind: "claude"` を追加** すること。現行は欠落しており (`skills-lock.json:1-23`)、`c-plugin sync` 実行時に schema decode が失敗する。Step 6 (Implementation) のタスクに必ず含めること。
4. **`enabledSkills` の値**: Intent Spec `## Scope.4` (`intent-spec.md:116-122`) が指定する `["coding", "test", "moonbit-docs", "components-build-docs"]` は、`SkillResolver.resolveFromRepo` (`skill-resolver.ts:62-83`) が `skills/<name>/SKILL.md` を実在確認するため、dotfiles 側 `plugins/totto2727-coding/skills/{coding,test,moonbit-docs,components-build-docs}/SKILL.md` が物理的に存在する必要がある。Intent Spec Scope.1 と一致しているので問題なし。
5. **本リポジトリ側 marketplace.json (`./.claude-plugin/marketplace.json`) の取り扱い**: `c-plugin skill sync` は **lock ファイルの `repositories[]` 経由でしか marketplace を読まない**。本リポジトリの `marketplace.json` は dev/marketplace/sync (`cli/dev/marketplace/sync.ts`) や Claude Code 本体の plugin 探索のためのものと推定され、本サイクルで `totto2727-coding` 追加が必須。dotfiles 側更新と同期が必要。
6. **Intent Spec Open Question #1 への回答**: 「dotfiles 側更新の要否」 → **必須**。
7. **Intent Spec Open Question #2 への回答**: 「lock ファイル登録形式」 → **既存 `repositories[0].plugins[]` に追加** (方式 A)。新規 `repositories[]` エントリ作成や `skillDirs[]` 利用は不適。

## Remaining unknowns

- **Blocker (要ユーザー判断)**: Intent Spec Out of scope と技術現実の衝突 (上記 Implications #1-#2)。Architect が Step 3 開始時に Main 経由で必ず確認すること。本観点としてはこれ以上自律的に進められない。
- dotfiles リポジトリ側の `plugins/` ディレクトリ実体構造 (例: `plugins/totto2727/skills/` の階層) は WebFetch では浅い list しか取れていない。**dotfiles 側に新プラグインを追加する具体作業 (Scope 内に取り込む場合)** は dotfiles リポジトリを直接クローン / 編集する別サイクルが必要かもしれない。
- `marketplaceKind` 欠落の現行 lock が `c-plugin sync` で実際に decode 失敗するか (Effect `Schema.decodeUnknownEffect` の `optional` 補完の挙動) は実行確認をしていない。**Validator (Step 8) で `c-plugin skill sync` を一度実行する検証ステップを Task Plan に含めることを推奨**。
- `dev-workflow` プラグイン (本リポジトリ marketplace.json には登録、dotfiles には未登録) が現状どう運用されているか不明。本サイクルではスコープ外だが、`totto2727-coding` も同様に「本リポジトリの marketplace にだけ登録 / lock では dotfiles を見る」という不整合パターンを許容している前例の可能性あり。Architect が判断材料として参照可。
