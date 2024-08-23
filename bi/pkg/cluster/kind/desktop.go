package kind

import (
	"context"
	"fmt"

	dockerclient "github.com/docker/docker/client"
)

// IsDockerDesktop checks if the current environment is Docker Desktop.
func IsDockerDesktop(ctx context.Context) (bool, error) {
	cli, err := dockerclient.NewClientWithOpts(dockerclient.FromEnv, dockerclient.WithAPIVersionNegotiation())
	if err != nil {
		return false, fmt.Errorf("failed to create docker client: %w", err)
	}

	info, err := cli.Info(ctx)
	if err != nil {
		return false, fmt.Errorf("failed to get docker server info: %w", err)
	}

	// Check if we are running in Docker Desktop.
	return info.OperatingSystem == "Docker Desktop", nil
}
