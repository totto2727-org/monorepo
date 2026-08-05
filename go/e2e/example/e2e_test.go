//go:build e2e

package example

import (
	"context"
	"fmt"
	"io"
	"os"
	"testing"
	"time"

	"github.com/testcontainers/testcontainers-go"
	tcexec "github.com/testcontainers/testcontainers-go/exec"
)

type commandResult struct {
	exitCode int
	output   string
}

type scenario struct {
	name string
	run  func(*testing.T, context.Context, testcontainers.Container)
}

func TestCLI(t *testing.T) {
	parentCtx, cancel := context.WithTimeout(t.Context(), 5*time.Minute)
	defer cancel()
	repo := fmt.Sprintf("go-cli-e2e-%d", os.Getpid())
	tag := fmt.Sprintf("%d", time.Now().UnixNano())
	imageName := repo + ":" + tag
	imageOwner, err := testcontainers.Run(parentCtx, "", testcontainers.WithDockerfile(testcontainers.FromDockerfile{
		Context: ".", Dockerfile: "Dockerfile", Repo: repo, Tag: tag, KeepImage: false,
	}))
	testcontainers.CleanupContainer(t, imageOwner)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("image=%s image_owner=%s", imageName, imageOwner.GetContainerID())

	slots := make(chan struct{}, 2)
	scenarios := []scenario{
		{name: "stdout", run: stdoutScenario},
		{name: "file_output", run: fileOutputScenario},
		{name: "expected_failure", run: expectedFailureScenario},
	}
	for _, s := range scenarios {
		t.Run(s.name, func(t *testing.T) {
			t.Parallel()
			ctx, cancel := context.WithTimeout(t.Context(), time.Minute)
			defer cancel()
			select {
			case slots <- struct{}{}:
			case <-ctx.Done():
				t.Fatal(ctx.Err())
			}
			t.Log("started")
			t.Cleanup(func() { <-slots })
			t.Cleanup(func() { t.Logf("completed pass=%t", !t.Failed()) })
			container, err := testcontainers.Run(ctx, imageName)
			testcontainers.CleanupContainer(t, container)
			if err != nil {
				t.Fatal(err)
			}
			t.Logf("container=%s", container.GetContainerID())
			s.run(t, ctx, container)
		})
	}
}

func stdoutScenario(t *testing.T, ctx context.Context, container testcontainers.Container) {
	t.Helper()
	requireCommand(t, ctx, "stdout", container, []string{"echo", "hello from e2e"}, 0, "hello from e2e\n")
}

func fileOutputScenario(t *testing.T, ctx context.Context, container testcontainers.Container) {
	t.Helper()
	requireCommand(t, ctx, "file_output", container, []string{"sh", "-c", "echo first > /workspace/result.txt"}, 0, "")
	requireCommand(t, ctx, "file_output", container, []string{"sh", "-c", "echo second >> /workspace/result.txt"}, 0, "")
	requireCommand(t, ctx, "file_output", container, []string{"cat", "/workspace/result.txt"}, 0, "first\nsecond\n")
	reader, err := container.CopyFileFromContainer(ctx, "/workspace/result.txt")
	if err != nil {
		t.Fatal(err)
	}
	data, readErr := io.ReadAll(reader)
	closeErr := reader.Close()
	if readErr != nil || closeErr != nil {
		t.Fatalf("scenario=file_output copy read=%v close=%v", readErr, closeErr)
	}
	if string(data) != "first\nsecond\n" {
		t.Fatalf("scenario=file_output copied_output=%q", string(data))
	}
}

func expectedFailureScenario(t *testing.T, ctx context.Context, container testcontainers.Container) {
	t.Helper()
	requireCommand(t, ctx, "expected_failure", container, []string{"sh", "-c", "echo expected-failure; exit 7"}, 7, "expected-failure\n")
}

func requireCommand(t *testing.T, ctx context.Context, name string, container testcontainers.Container, argv []string, wantCode int, wantOutput string) {
	t.Helper()
	result, err := execCommand(ctx, container, argv)
	if err != nil {
		t.Fatalf("scenario=%s argv=%q error=%v", name, argv, err)
	}
	if result.exitCode != wantCode || result.output != wantOutput {
		t.Fatalf("scenario=%s argv=%q exit_code=%d output=%q want_exit_code=%d want_output=%q", name, argv, result.exitCode, result.output, wantCode, wantOutput)
	}
}

func execCommand(ctx context.Context, container testcontainers.Container, argv []string) (commandResult, error) {
	exitCode, output, err := container.Exec(ctx, argv, tcexec.Multiplexed())
	if err != nil {
		return commandResult{exitCode: exitCode}, err
	}
	data, err := io.ReadAll(output)
	if err != nil {
		return commandResult{exitCode: exitCode}, err
	}
	return commandResult{exitCode: exitCode, output: string(data)}, nil
}
