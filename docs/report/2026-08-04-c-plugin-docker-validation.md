# c-plugin Docker Validation Report

Date: 2026-08-04

## Result

`c-plugin` passed the complete Docker validation matrix as the non-root `sandbox` user, including project-local and global state, repeated operations, repository updates, recursive operations, marketplace conversion, malformed input, and pre-existing filesystem objects. The final harness result was:

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
- Final recorded image: `sha256:64c782b8df5525f3a4a1f1a85ff85cd3e753133df518b37ab870da37f60c679b` (`c-plugin-validation:final`).
- Runtime identity assertions: `PASS: running as non-root` and `PASS: HOME=/sandbox`.

The image builds `path:/src#c-plugin` with Nix, installs the binary at `/sandbox/.local/bin/c-plugin`, and makes the harness its entry point. Fixtures use a local bare Git repository and a Git URL rewrite, so lifecycle verification is deterministic and does not depend on a live GitHub repository.

## Commands and observed output

The repository-root commands used for the final Docker verification were:

```bash
docker build --platform linux/amd64 --file sandbox/c-plugin.Dockerfile --tag c-plugin-validation:final .
docker run --rm --platform linux/amd64 --name c-plugin-validation-final c-plugin-validation:final all
```

Relevant build output:

```text
#8 [stage-0 3/4] RUN --mount=type=bind,source=mbt,target=/src,readonly ...
#10 writing image sha256:64c782b8df5525f3a4a1f1a85ff85cd3e753133df518b37ab870da37f60c679b done
#10 naming to docker.io/library/c-plugin-validation:final done
DOCKER_BUILD_EXIT=0
```

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
SUMMARY: mode=all failures=0 expected-current-red=0
DOCKER_RUN_EXIT=0
```

The final version check printed `0.2.0` and the harness asserted the exact value:

```text
+ c-plugin --version
0.2.0
[exit 0]
PASS: version is 0.2.0
```

MoonBit validation was run from the repository root:

```bash
vp run mbt:check
vp run mbt:test
vp run mbt:build
```

Observed results:

```text
MBT_CHECK_EXIT=0
Total tests: 579, passed: 579, failed: 0. [wasm-gc]
Total tests: 367, passed: 367, failed: 0. [native]
MBT_TEST_EXIT=0
MBT_BUILD_EXIT=0
```

The defect-focused regression command also passed after the fixes:

```bash
moon test --no-parallelize mbt/app/c-plugin/src/command_skill_wbtest.mbt mbt/app/c-plugin/src/command_target_wbtest.mbt mbt/app/c-plugin/src/lock_file_wbtest.mbt mbt/app/c-plugin/src/sync_service_wbtest.mbt mbt/app/c-plugin/src/main_wbtest.mbt
```

```text
Total tests: 19, passed: 19, failed: 0.
MOON_TEST_EXIT=0
```

The shell harness also passed syntax validation:

```text
+ bash -n sandbox/verify-c-plugin.sh
[exit 0]
```

After evidence capture, all validation containers and task-specific images were removed:

```bash
docker image rm c-plugin-validation:working c-plugin-validation:green c-plugin-validation:final
docker ps -a --filter name=c-plugin-validation --format '{{.ID}}'
docker images --format '{{.Repository}}:{{.Tag}}' | rg '^c-plugin-validation:'
```

```text
containers-after=0
images-after=0
```

## CLI coverage matrix

| Area | Commands and state transitions verified | Result |
| --- | --- | --- |
| Discovery | `c-plugin --help`, `--version`, `help`, and help for every parser-exposed subcommand | Exit 0; all command surfaces present |
| Initialization | `init`, repeated `init`, `init -g`, repeated `init --global`; pre-existing `.agents` sentinel | First initialization succeeded; re-initialization failed safely without changing the lock or sentinel |
| Project-local source | `skill add --local ./marketplace`, re-add, and `skill sync` | Exit 0; deterministic symlink created and retained |
| GitHub source | `skill add acme/market`, re-add after remote advance, `skill update` | Exit 0; cache created, remote tip installed, newly added `beta` skill linked |
| Recursive operation | `skill sync -r`, `skill update --recursive` from nested lock trees | Exit 0 |
| Removal | Repeated `skill remove acme/market` and `skill remove ./marketplace` | Exit 0; idempotent and all managed links removed |
| Global operation | GitHub add with `-g`; local add and sync with `--global`; update with `-g`; removal with both forms | Global lock at `/sandbox/c-plugin-lock.json`; global and project-local targets remained isolated |
| Targets | Repeated local/global `skill target add` and `skill target remove` | Idempotent; removed targets were cleaned of managed links |
| Marketplace development | `dev marketplace sync claude`, `cursor`, and `codex` | Exit 0; Claude, Cursor, Codex marketplace and plugin manifests generated |
| No lock and malformed input | Sync without a reachable lock; invalid/missing repo and target arguments; unsupported marketplace kind; absent local marketplace | Non-zero exit with no state corruption |
| Source ambiguity and containment | `--local ./../outside/marketplace`, repo plus `--local`, `.`, and absolute paths | Non-zero exit; traversal and mutually exclusive inputs rejected |
| Existing filesystem state | Existing lock, `.agents`, regular file, directory, and symlink at a target | File/directory collisions rejected and preserved; managed symlink refreshed safely |
| Corrupt lock | Invalid JSON followed by `skill sync` | Non-zero exit; byte-for-byte lock preservation confirmed |

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
```

## Defects found and fixed

The validation was intentionally run RED before production changes. It found the following issues:

1. The Nix package metadata still requested Admiral `0.5.0`, while the workspace used Admiral `0.6.0`, Lens `0.4.0`, and c-plugin `0.2.0`. The first Docker build failed with `error: attribute '"0.5.0"' missing`. Commit `022bb456` (`fix(c-plugin): sync Nix package metadata`) synchronized the local sources, workspace members, and versions.
2. `--local ./../...` escaped the intended project-local root.
3. A GitHub repository argument and `--local` were accepted together instead of being rejected as ambiguous.
4. A corrupt lock file was interpreted as an empty lock and could be overwritten.
5. `skill target remove` removed the target from the lock but left managed symlinks behind.
6. `skill update` used `pull --ff-only`; a normal remote advance could not replace a divergent depth-one cache.

Commit `59e03983` (`fix(c-plugin): harden skill lifecycle handling`) added regression coverage and fixed those five runtime defects by validating source containment/exclusivity, propagating lock parse errors, cleaning removed targets, and deterministically resetting/checkout/cleaning the cached repository to the fetched remote tip. It also exposed the package version to Admiral: the initial binary printed `0.0.0`; the corrected application declares `0.2.0`.

Commit `a391ef14` (`test(c-plugin): add Docker lifecycle validation`) added the reusable Dockerfile, scoped build context, and comprehensive harness.

The focused regression run was RED before the fixes (four command/lock/target tests failed) and GREEN afterwards. The cache-divergence behavior is covered by a dedicated Git fixture regression test and by the Docker remote-advance scenario.

## Implementation notes and official references

- Docker build context and Dockerfile-specific ignore behavior informed the small, explicit context: [Docker build context](https://docs.docker.com/build/concepts/context/).
- The build uses a read-only BuildKit bind mount for the MoonBit source: [Docker bind mounts](https://docs.docker.com/engine/storage/bind-mounts/).
- Validation containers use `--rm` for automatic cleanup: [`docker run --rm`](https://docs.docker.com/reference/cli/docker/container/run/#clean-up---rm).
- The non-root user, `HOME`, working directory, and copied harness follow the documented Dockerfile semantics: [Dockerfile reference](https://docs.docker.com/reference/dockerfile/).
- Deterministic cached-repository replacement uses branch checkout, removal of untracked files, and fetched remote references according to [git-checkout](https://git-scm.com/docs/git-checkout), [git-clean](https://git-scm.com/docs/git-clean), and [git-fetch](https://git-scm.com/docs/git-fetch).

## Final assessment

The final Docker matrix and both MoonBit backends are green. Local and global state remain isolated, repeated operations are idempotent or fail safely as designed, managed symlink behavior is deterministic, user-owned file and directory collisions are preserved, corrupt lock data is not silently replaced, and Git-backed skills update to the remote tip. The tested `c-plugin` lifecycle is healthy.
