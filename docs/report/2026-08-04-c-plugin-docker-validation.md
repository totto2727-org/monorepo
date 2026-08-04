# c-plugin Docker Validation Report

Date: 2026-08-04

## Result

The post-review combined `all` Docker matrix passed as the non-root `sandbox` user. It covers project-local and global state, repeated operations, repository updates, recursive operations, marketplace conversion, malformed input, pre-existing filesystem objects, managed-link ownership, relative targets, targeted source removal, and repository-cache safety.

```text
SUMMARY: mode=all failures=0 expected-current-red=0
```

No `c-plugin` flow required interactive input, so a `mizchi/tui` prompt was not applicable.

## Environment and reusable validation assets

- Host Docker: Docker 29.4.0 with a Linux daemon.
- Target platform: `linux/amd64` (the repository's MoonBit Nix flake supports `x86_64-linux`; the host daemon is `arm64`).
- Base image: `ghcr.io/totto2727-org/monorepo/sandbox-base:latest`.
- Dockerfile: `sandbox/c-plugin.Dockerfile`.
- Scenario harness: `sandbox/verify-c-plugin.sh`.
- Scoped build-context exclusions: `sandbox/c-plugin.Dockerfile.dockerignore`.
- Evidence source commit: `e34ba84f6d114c557a3e7baf1f0d6910e291879d`.
- Evidence image: `c-plugin-validation:final-post-merge`, image ID `sha256:a53903734aa5c9bbf81a4a02c06069fdb316f05129bde6cadf2b281d047eb011`.
- Runtime identity assertions: `PASS: running as non-root` and `PASS: HOME=/sandbox`.

The image builds `path:/src#c-plugin` with Nix, installs the binary at `/sandbox/.local/bin/c-plugin`, and makes the harness its entry point. Fixtures use a local bare Git repository and a Git URL rewrite, so lifecycle verification is deterministic and does not depend on a live GitHub repository.

## Commands and observed output

The repository-root commands used for the current post-review Docker verification were:

```bash
docker build --no-cache --platform linux/amd64 --file sandbox/c-plugin.Dockerfile --tag c-plugin-validation:final-post-merge .
docker image inspect c-plugin-validation:final-post-merge --format '{{.Id}}'
docker run --rm --platform linux/amd64 c-plugin-validation:final-post-merge all
```

The final combined evidence ended with:

```text
SUMMARY: mode=all failures=0 expected-current-red=0
EXIT=0
```

The final combined output is retained as `docker-all-final-post-merge.log` in the ULW evidence directory for this task. Failing old-binary comparisons are retained as `docker-atomicity-security-red.log`, `docker-lock-first-red.log`, `docker-remove-lock-first-red.log`, and `docker-lock-symlink-red.log`.

The harness prints every command and its exit status. Representative successful output was:

```text
+ c-plugin init
Created /tmp/c-plugin-validation/init/c-plugin-lock.json
[exit 0]
PASS: c-plugin init
+ c-plugin init
[exit 1]
PASS: rejected safely: c-plugin init
PASS: repeat init preserved lock
+ c-plugin skill add acme/market
[exit 0]
PASS: c-plugin skill add acme/market
+ c-plugin skill update
[exit 0]
PASS: c-plugin skill update
+ c-plugin skill target remove /tmp/c-plugin-validation/target
[exit 0]
PASS: target remove deleted managed links
SUMMARY: mode=lifecycle failures=0 expected-current-red=0
```

The current version check printed `0.2.0` and the harness asserted the exact value:

```text
+ c-plugin --version
0.2.0
[exit 0]
PASS: version is 0.2.0
```

The focused c-plugin regression suite passed after the post-review fixes:

```bash
moon test -p totto2727/c-plugin --target native --no-parallelize
```

Observed results:

```text
Total tests: 56, passed: 56, failed: 0.
```

The repository-wide validation commands were:

```bash
vp run mbt:check
vp run mbt:test
vp run mbt:build
```

```text
vp run mbt:check: exit 0
Total tests: 579, passed: 579, failed: 0. [wasm-gc]
Total tests: 387, passed: 387, failed: 0. [native]
vp run mbt:test: exit 0
vp run mbt:build: exit 0
```

The shell harness also passed syntax validation:

```text
+ bash -n sandbox/verify-c-plugin.sh
[exit 0]
```

The validation image was removed after evidence collection. The cleanup commands and observed result were:

```bash
docker image rm \
  c-plugin-validation:atomicity-green \
  c-plugin-validation:final \
  c-plugin-validation:lock-first-green \
  c-plugin-validation:remove-lock-first-green \
  c-plugin-validation:lock-symlink-green
container_count=$(docker ps -a --format '{{.Image}}' | rg '^c-plugin-validation:' | wc -l | tr -d ' ')
image_count=$(docker images --format '{{.Repository}}:{{.Tag}}' | rg '^c-plugin-validation:' | wc -l | tr -d ' ')
printf 'containers-after=%s\nimages-after=%s\n' "$container_count" "$image_count"
```

```text
containers-after=0
images-after=0
EXIT=0
```

After merging the latest `origin/main`, the package was rebuilt from the merged tree and the two new validation images were removed separately:

```bash
docker image rm c-plugin-validation:post-merge-green c-plugin-validation:final-post-merge
container_count=$(docker ps -a --format '{{.Image}}' | rg '^c-plugin-validation:' | wc -l | tr -d ' ')
image_count=$(docker images --format '{{.Repository}}:{{.Tag}}' | rg '^c-plugin-validation:' | wc -l | tr -d ' ')
printf 'containers-after=%s\nimages-after=%s\n' "$container_count" "$image_count"
```

```text
Deleted: sha256:0e42ba229f44f70580836d1785b6725395709805736c69b468589b711dfdb1dc
Deleted: sha256:a53903734aa5c9bbf81a4a02c06069fdb316f05129bde6cadf2b281d047eb011
containers-after=0
images-after=0
EXIT=0
```

## CLI coverage matrix

| Area | Commands and state transitions verified | Result |
| --- | --- | --- |
| Discovery | `c-plugin --help`, `--version`, `help`, and help for every parser-exposed subcommand | Exit 0; all command surfaces present |
| Initialization | `init`, repeated `init`, `init -g`, repeated `init --global`; pre-existing `.agents` sentinel | First initialization succeeded; re-initialization failed safely without changing the lock or sentinel |
| Project-local source | `skill add --local ./marketplace`, re-add, and `skill sync` | Exit 0; deterministic symlink created and retained |
| GitHub source | `skill add acme/market`, sync an older pinned revision into a fresh cache, re-add after remote advance, `skill update` | Exit 0; full-history cache honored the pinned revision, then update installed the remote tip and linked the newly added `beta` skill |
| Recursive operation | `skill sync -r`, `skill update --recursive` from nested lock trees | Exit 0 |
| Removal | Repeated `skill remove acme/market` and `skill remove ./marketplace`; remove one of two local sources while the remaining source is temporarily unavailable | Exit 0; removal was targeted to the selected source, idempotent, and preserved the remaining source's managed link |
| Global operation | GitHub add with `-g`; local add and sync with `--global`; update with `-g`; removal with both forms | Global lock at `/sandbox/c-plugin-lock.json`; global and project-local targets remained isolated |
| Targets | Repeated local/global `skill target add` and `skill target remove`; relative target invoked from a nested working directory | Idempotent; relative paths resolved from the lock root, removed targets lost only lock-owned links, and an unrelated symlink survived sync and removal |
| Marketplace development | `dev marketplace sync claude`, `cursor`, and `codex` | Exit 0; Claude, Cursor, Codex marketplace and plugin manifests generated |
| No lock and malformed input | Sync without a reachable lock; invalid/missing repo and target arguments; unsupported marketplace kind; absent local marketplace | Non-zero exit with no state corruption |
| Source ambiguity and containment | `--local ./../outside/marketplace`, repo plus `--local`, `.`, and absolute paths | Non-zero exit; traversal and mutually exclusive inputs rejected |
| Existing filesystem state | Existing lock, `.agents`, regular file, directory, and symlink at a target | File/directory collisions rejected; colliding objects and lock bytes were preserved; managed symlink refreshed safely |
| Lock path safety | Broken `c-plugin-lock.json` symlink during `init`; symlink to an external valid lock during `skill add` | Non-zero exit; symlink retained, missing victim not created, existing victim bytes preserved, and no skill link created |
| Corrupt lock | Invalid JSON and syntactically valid malformed `skillDirs`, repository, and `enabledSkills` values followed by `skill sync` | Non-zero exit; byte-for-byte lock preservation confirmed for every case |
| Repository cache safety | Cached repository with a mismatched `origin`; symlinked cache-root path pointing at a victim directory; Git metadata stored as a regular gitfile | Source was skipped with an explicit diagnostic; prior managed links, sentinel files, and the symlink target were preserved; non-directory Git metadata was rejected |

Selected failure-path evidence:

```text
Failure(... FAILED: --local path must start with ./ and stay within its root)
[exit 1]
PASS: parent traversal rejected
Failure(... FAILED: Provide either <repo> or --local <path>, not both)
[exit 1]
PASS: repo plus --local rejected
Failure(... FAILED: Refusing to replace non-symlink path: .../target/local-skill)
[exit 1]
PASS: existing file collision rejected
PASS: existing file preserved
[exit 1]
PASS: corrupt lock rejected and preserved
PASS: malformed enabledSkills rejected and preserved
PASS: symlink exists: .../relative-target/unrelated-link
PASS: origin mismatch reported as skipped
PASS: file exists: .../cache/mbt/acme/market/sentinel
PASS: symlinked cache reported as skipped
PASS: symlinked cache parent victim preserved
PASS: symlink exists: c-plugin-lock.json
PASS: absent: /tmp/c-plugin-validation/broken-lock/outside/victim.json
PASS: bytes preserved: /tmp/c-plugin-validation/linked-lock/outside/victim.json
PASS: absent: .agents/skills/local-skill
```

## Defects found and fixed

The validation was intentionally run RED before production changes. It found the following issues:

1. The Nix package metadata still requested Admiral `0.5.0`, while the workspace used Admiral `0.6.0`, Lens `0.4.0`, and c-plugin `0.2.0`. The first Docker build failed with `error: attribute '"0.5.0"' missing`. Commit `022bb456` (`fix(c-plugin): sync Nix package metadata`) synchronized the local sources, workspace members, and versions.
2. `--local ./../...` escaped the intended project-local root.
3. A GitHub repository argument and `--local` were accepted together instead of being rejected as ambiguous.
4. A corrupt lock file was interpreted as an empty lock and could be overwritten.
5. `skill target remove` removed the target from the lock but left managed symlinks behind.
6. `skill update` used `pull --ff-only`; a normal remote advance could not replace a divergent depth-one cache.
7. Sync and target removal deleted every symlink in a target, including links not owned by the lock.
8. Relative `skillDirs` were resolved from the caller's current working directory rather than the lock-file root.
9. `skill remove` performed a full sync, so removing one source could delete a remaining source's link when that remaining source was unavailable.
10. A fresh depth-one clone could not check out an older revision pinned by the lock.
11. Existing repository caches were modified with destructive reset/clean operations without first proving their origin and path safety.
12. Syntactically valid but structurally malformed lock values were silently filtered or defaulted instead of being rejected.
13. A skipped repository lost its last usable managed links because sync deleted all managed links before repository resolution.
14. Add, target add, and update persisted lock changes before sync collision checks, so a failed operation could leave changed lock bytes or partially updated links.
15. An unsafe `enabledSkills` filename component such as `../../victim` could escape a managed target during link cleanup.
16. A regular `.git` gitfile could redirect cache operations to Git metadata outside the validated cache path.
17. An option-like `commitHash` such as `-f` could be passed to `git checkout` and force-discard dirty cache changes.
18. Writing the lock after link application meant a read-only lock could reject persistence after unrecorded target links had already been created.
19. Skill and target removal deleted links before persisting the lock, while pure sync redundantly rewrote an unchanged lock after relinking; read-only locks could therefore produce mutation-before-failure behavior.
20. Lock initialization, reading, and writing followed a `c-plugin-lock.json` symlink. A broken link could create a file outside the project during `init`, while a link to an existing valid lock could allow lifecycle commands to overwrite external bytes.
21. Merging the latest `origin/main` changed Nix packages to parse native `moon.mod`, exposing the invalid top-level `source = "src"` spelling. The overlay converter rejected it with `Invalid moon.mod config: unexpected key source`.
22. The native Nix metadata initially exposed unpublished workspace dependencies to the external Moon registry resolver. Docker then failed with `attribute '"0.4.0"' missing` for Lens even though Lens was supplied locally through `moon.work`.

Commit `59e03983` (`fix(c-plugin): harden skill lifecycle handling`) added regression coverage for the initial runtime defects by validating source containment/exclusivity, propagating lock parse errors, cleaning removed targets, and updating cached repositories. It also exposed the package version to Admiral: the initial binary printed `0.0.0`; the corrected application declares `0.2.0`.

Commit `a3198235` (`fix(c-plugin): reject malformed lock data`) made the lock decoder strict for present values while preserving defaults for absent optional fields. Invalid arrays, repository records, and nested `enabledSkills` values now fail without changing the original lock bytes.

Commit `25aaff92` (`fix(c-plugin): preserve managed lifecycle state`) restricted link cleanup to lock-owned skill names, resolved relative targets from the lock root, made source removal targeted, changed repository caches to retain full history so pinned revisions remain reachable, and rejected unsafe caches with mismatched origins, symlinked path components, or dirty worktrees. Cache operations no longer use destructive hard reset or clean commands.

Commit `a391ef14` (`test(c-plugin): add Docker lifecycle validation`) added the reusable Dockerfile, scoped build context, and comprehensive harness.

Commit `93240a79` (`test(c-plugin): cover managed state boundaries`) extended the Docker matrix with pinned-revision recovery, unrelated-link preservation, relative-target resolution, targeted removal with an unavailable remaining source, malformed-lock preservation, cache-origin validation, and symlinked-cache victim preservation.

Commit `d112f6ed` (`fix(c-plugin): preserve state on sync failure`) changed sync to resolve and preflight successful repositories before mutation, retained existing links for skipped sources, rejected unsafe skill-name components and non-directory Git metadata, and added Docker assertions for lock/link preservation.

Commit `46c2661f` (`fix(c-plugin): validate sync plans before persistence`) separated planning from link application so collisions are detected before lock persistence and links are applied only after a successful lock write. It also validates hexadecimal Git object IDs, uses detached checkout, and refuses pinned checkout from a dirty cache.

Commit `d580c1d2` (`fix(c-plugin): persist removals before unlinking`) made skill and target removal persist their updated lock before deleting links and removed the unnecessary same-content lock rewrite from pure sync. Docker now verifies read-only lock behavior for sync, target add/remove, and skill remove with byte and link preservation assertions.

Commit `2ac87337` (`fix(c-plugin): reject symlinked lock files`) requires the lock path to be a regular file or absent without following symlinks. `init`, reads, and writes reject both broken and live lock symlinks before touching their targets.

Commit `4a26098e` (`fix(c-plugin): use valid moon.mod source syntax`) uses the documented native form `options(source: "src")`. Commit `e34ba84f` (`fix(c-plugin): keep local Nix dependencies in workspace`) keeps Admiral and Lens in the generated `moon.work` while restricting Nix registry metadata to external async/x dependencies. The first post-merge Docker builds reproduced both failures; the final no-cache build and `all` run passed from the merged tree.

The current focused regression run is GREEN at 56 of 56 tests. The cache-history behavior is covered by dedicated Git fixture regression tests and by the Docker fresh-cache pinned-revision and remote-advance scenarios.

## Implementation notes and official references

- Docker build context and Dockerfile-specific ignore behavior informed the small, explicit context: [Docker build context](https://docs.docker.com/build/concepts/context/).
- The build uses a read-only BuildKit bind mount for the MoonBit source: [Docker bind mounts](https://docs.docker.com/engine/storage/bind-mounts/).
- Validation containers use `--rm` for automatic cleanup: [`docker run --rm`](https://docs.docker.com/reference/cli/docker/container/run/#clean-up---rm).
- The non-root user, `HOME`, working directory, and copied harness follow the documented Dockerfile semantics: [Dockerfile reference](https://docs.docker.com/reference/dockerfile/).
- Repository-cache behavior was evaluated against [git-clone](https://git-scm.com/docs/git-clone), [git-checkout](https://git-scm.com/docs/git-checkout), [git-clean](https://git-scm.com/docs/git-clean), and [git-fetch](https://git-scm.com/docs/git-fetch). The final implementation retains full history, validates cache provenance and path safety before use, rejects dirty caches, and deliberately avoids destructive hard reset and clean operations.
- The native source-directory spelling follows the official [`moon.mod` module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html), which documents `options(source: "src")` for the new format.

## Final assessment

The combined Docker matrix, the 56-test focused native suite, and the repository-wide MoonBit checks, tests, and build are green. The observed behavior demonstrates isolated local/global state, safe repeated operations, collision preflight followed by lock-first persistence, no link mutation when lock writing fails, rejection of symlinked lock paths, managed-only link cleanup, preservation of links for skipped sources, lock-root-relative targets, targeted source removal, strict malformed-lock rejection, full-history pinned-revision recovery, safe pinned checkout, and cache origin/path safeguards. All validation containers and task-specific images were removed after evidence collection. c-plugin is healthy for the exercised parser-visible command surface and filesystem boundary cases.
