# Go CLI E2E template

This opt-in Testcontainers template demonstrates the reusable `github.com/totto2727-org/monorepo/go/e2e/cli` package. Ordinary tests exclude the Docker implementation through the `e2e` build tag. An explicit `-tags=e2e` run requires Docker and fails rather than skips when Docker is unavailable.

Run these commands from the repository root:

```sh
GOWORK=off GOTOOLCHAIN=go1.25.9 go -C go/e2e test -count=1 ./...
GOWORK=off GOTOOLCHAIN=go1.25.9 go -C go/e2e test -tags=e2e -count=1 -v -parallel=2 ./...
GOWORK=off GOTOOLCHAIN=go1.25.9 go -C go/e2e test -tags=e2e -race -shuffle=on -count=1 -v -parallel=2 ./...
gofmt -d go/e2e/cli/*.go go/e2e/example/*.go
GOWORK=off GOTOOLCHAIN=go1.25.9 go -C go/e2e vet -tags=e2e ./...
GOWORK=off GOTOOLCHAIN=go1.25.9 go -C go/e2e mod verify
```

For maintenance after editing dependencies or Go files, run `gofmt -w go/e2e/cli/*.go go/e2e/example/*.go` and `GOWORK=off GOTOOLCHAIN=go1.25.9 go -C go/e2e mod tidy`.

`cli.Run` builds one uniquely tagged image from the caller's `cli.ImageConfig`, retains it only for the parent test, and creates a fresh container for every case. The library does not hard-code a base image: this example selects its `ubuntu:24.04` Dockerfile, while another consumer can provide a different build context and Dockerfile. At most two cases hold a slot at once; verbose output logs image and full container IDs, plus `started` and completion progress. Testcontainers cleans each case container and then the image-owning container, which removes the built image.

`Environment.CheckStdout` verifies an argv command's exact exit code and multiplexed stdout/stderr stream. `Environment.CheckFile` copies and verifies one file. `Environment.Exec` is the lower-level primitive for custom checks. The multi-command file workflow stays in this example; consumers should similarly implement multiple-file or domain-specific workflows in their own case instead of extending the library with a workflow DSL.

To test a real CLI, point `cli.ImageConfig` at a Dockerfile that builds or installs the CLI, then replace the sample argv values. Keep the opt-in `e2e` build tag, one parent image build, fresh case containers, and no host mounts.
