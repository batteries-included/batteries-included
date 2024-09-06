package kind

import (
	"context"
	"log/slog"
	"strings"

	dockerclient "github.com/docker/docker/client"
	"sigs.k8s.io/kind/pkg/exec"
)

func IsDockerAvailable() bool {
	cmd := exec.Command("docker", "-v")
	lines, err := exec.OutputLines(cmd)
	if err != nil || len(lines) != 1 {
		return false
	}

	return strings.HasPrefix(lines[0], "Docker version")
}

// IsDockerDesktop checks if the current environment is Docker Desktop.
func IsDockerDesktop(ctx context.Context) bool {
	cli, err := dockerclient.NewClientWithOpts(dockerclient.FromEnv, dockerclient.WithAPIVersionNegotiation())
	if err != nil {
		return false
	}

	info, err := cli.Info(ctx)
	if err != nil {
		return false
	}

	slog.Debug("Docker is available")

	// Check if we are running in Docker Desktop.
	return info.OperatingSystem == "Docker Desktop"
}
