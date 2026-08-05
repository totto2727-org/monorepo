# Go CLI E2E template

This standalone module is an opt-in Testcontainers template for CLI end-to-end tests. Ordinary tests exclude `e2e_test.go`, so they do not compile Docker code or contact Docker. An explicit `-tags=e2e` run requires Docker and fails rather than skips when Docker is unavailable.

Run these commands from the repository root:

```sh
GOTOOLCHAIN=go1.25.9 go -C go/e2e/example test -count=1 ./...
GOTOOLCHAIN=go1.25.9 go -C go/e2e/example test -tags=e2e -count=1 -v -parallel=2 ./...
GOTOOLCHAIN=go1.25.9 go -C go/e2e/example test -tags=e2e -race -shuffle=on -count=1 -v -parallel=2 ./...
gofmt -d go/e2e/example/*.go
GOTOOLCHAIN=go1.25.9 go -C go/e2e/example vet -tags=e2e ./...
GOTOOLCHAIN=go1.25.9 go -C go/e2e/example mod verify
```

For maintenance after editing dependencies or Go files, run `gofmt -w go/e2e/example/*.go` and `GOTOOLCHAIN=go1.25.9 go -C go/e2e/example mod tidy`.

The tagged test builds one uniquely tagged `ubuntu:24.04` image, retains it only for the parent test, and creates a fresh container for every scenario. At most two scenarios hold a slot at once; verbose output logs image and full container IDs, plus `started` and completion progress. Testcontainers cleans each scenario container and then the image-owning container, which removes the built image.

The examples assert exact stdout, sequential file creation and copied-file bytes, and a deliberate command failure with exit code 7. Add a scenario by adding a table entry and a small function that executes argv slices with exact exit/output assertions. Keep scenarios independent because each receives a new container.

To test a real CLI, replace the sample Dockerfile with one that builds or installs the CLI into the image, then replace the sample argv values. Keep the working directory, opt-in `e2e` build tag, one parent image build, fresh scenario containers, and no host mounts.
