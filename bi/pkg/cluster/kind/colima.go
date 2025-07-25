package kind

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"

	dockerclient "github.com/docker/docker/client"
)

// IsColimaRunning checks if Colima is running by:
// 1. Checking if colima command is available
// 2. Checking if colima is running
// 3. Checking if Docker context is set to colima
func IsColimaRunning(ctx context.Context) (bool, error) {
	// First check if colima command exists
	_, err := exec.LookPath("colima")
	if err != nil {
		return false, nil // Colima not installed
	}

	// Check if colima is running
	cmd := exec.Command("colima", "status")
	output, err := cmd.Output()
	if err != nil {
		return false, nil // Colima not running
	}

	// Check if status indicates running
	if !strings.Contains(string(output), "Running") {
		return false, nil
	}

	// Additional check: verify Docker context or socket
	// Colima typically creates a Docker socket at ~/.colima/default/docker.sock
	homeDir, err := os.UserHomeDir()
	if err == nil {
		colimaSocket := homeDir + "/.colima/default/docker.sock"
		if _, err := os.Stat(colimaSocket); err == nil {
			// Socket exists, likely using Colima
			return true, nil
		}
	}

	// Alternative: Check Docker info for Colima hints
	cli, err := dockerclient.NewClientWithOpts(dockerclient.FromEnv, dockerclient.WithAPIVersionNegotiation())
	if err != nil {
		return false, fmt.Errorf("failed to create docker client: %w", err)
	}

	info, err := cli.Info(ctx)
	if err != nil {
		return false, fmt.Errorf("failed to get docker server info: %w", err)
	}

	// Check for Colima-specific identifiers in Docker info
	if strings.Contains(info.Name, "colima") || strings.Contains(info.ServerVersion, "colima") {
		return true, nil
	}

	// Check if the Docker context name contains colima
	if os.Getenv("DOCKER_CONTEXT") == "colima" {
		return true, nil
	}

	return false, nil
}