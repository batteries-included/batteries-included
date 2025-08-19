package ctkutil

import (
	"context"
	"fmt"
	"io"
	"os/exec"
	"strings"

	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/client"
)

const ubuntuImage = "ubuntu:24.04"

// GPUDetector provides methods to detect NVIDIA GPUs on the host
type GPUDetector struct {
	dockerClient *client.Client
}

// NewGPUDetector creates a new GPU detector with optional Docker client
func NewGPUDetector(dockerClient *client.Client) *GPUDetector {
	return &GPUDetector{
		dockerClient: dockerClient,
	}
}

// DetectGPUs attempts to detect NVIDIA GPUs using various fallback methods
// Returns the number of GPUs found and any error encountered
func (d *GPUDetector) DetectGPUs(ctx context.Context) (int, error) {
	// Try to get GPU information using nvidia-smi locally first
	output, err := d.tryNvidiaSmiLocal(ctx)
	if err != nil {
		// Fallback to running nvidia-smi in Docker container
		output, err = d.tryNvidiaSmiDocker(ctx)
		if err != nil {
			return 0, fmt.Errorf("failed to detect GPUs: %w", err)
		}
	}

	// Count GPUs from nvidia-smi output
	gpuCount := d.countGPUsFromOutput(output)
	return gpuCount, nil
}

// tryNvidiaSmiLocal attempts to run nvidia-smi locally on the host
func (d *GPUDetector) tryNvidiaSmiLocal(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "nvidia-smi", "-L")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("local nvidia-smi failed: %w", err)
	}
	return string(output), nil
}

// tryNvidiaSmiDocker attempts to run nvidia-smi inside a Docker container
func (d *GPUDetector) tryNvidiaSmiDocker(ctx context.Context) (string, error) {
	if d.dockerClient == nil {
		// Fallback to command execution if Docker client is not available
		return d.tryNvidiaSmiDockerCommand(ctx)
	}

	// Try with nvidia runtime first
	output, err := d.runNvidiaSmiContainer(ctx, true, false)
	if err != nil {
		// Fallback to volume mount approach
		output, err = d.runNvidiaSmiContainer(ctx, false, true)
		if err != nil {
			return "", fmt.Errorf("docker nvidia-smi failed: %w", err)
		}
	}
	return output, nil
}

// tryNvidiaSmiDockerCommand is a fallback function that uses command execution
func (d *GPUDetector) tryNvidiaSmiDockerCommand(ctx context.Context) (string, error) {
	// Try with nvidia runtime first
	cmd := exec.CommandContext(ctx, "docker", "run", "--rm", "--runtime=nvidia",
		"-e", "NVIDIA_VISIBLE_DEVICES=all", ubuntuImage, "nvidia-smi", "-L")
	output, err := cmd.Output()
	if err != nil {
		// Fallback to volume mount approach
		cmd = exec.CommandContext(ctx, "docker", "run", "--rm",
			"-v", "/dev/null:/var/run/nvidia-container-devices/all",
			ubuntuImage, "nvidia-smi", "-L")
		output, err = cmd.Output()
		if err != nil {
			return "", fmt.Errorf("docker nvidia-smi failed: %w", err)
		}
	}
	return string(output), nil
}

// runNvidiaSmiContainer runs nvidia-smi in a Docker container using the Docker client API
func (d *GPUDetector) runNvidiaSmiContainer(ctx context.Context, useNvidiaRuntime, useVolumeMount bool) (string, error) {
	var hostConfig *container.HostConfig

	if useNvidiaRuntime {
		hostConfig = &container.HostConfig{
			AutoRemove: true,
			Runtime:    "nvidia",
		}
	} else if useVolumeMount {
		hostConfig = &container.HostConfig{
			AutoRemove: true,
			Binds: []string{
				"/dev/null:/var/run/nvidia-container-devices/all",
			},
		}
	} else {
		return "", fmt.Errorf("invalid container configuration")
	}

	// Container configuration
	containerConfig := &container.Config{
		Image: ubuntuImage,
		Cmd:   []string{"nvidia-smi", "-L"},
	}

	if useNvidiaRuntime {
		containerConfig.Env = []string{"NVIDIA_VISIBLE_DEVICES=all"}
	}

	// Create container
	resp, err := d.dockerClient.ContainerCreate(ctx, containerConfig, hostConfig, nil, nil, "")
	if err != nil {
		return "", fmt.Errorf("failed to create container: %w", err)
	}

	// Start container
	if err := d.dockerClient.ContainerStart(ctx, resp.ID, container.StartOptions{}); err != nil {
		return "", fmt.Errorf("failed to start container: %w", err)
	}

	// Wait for container to finish
	statusCh, errCh := d.dockerClient.ContainerWait(ctx, resp.ID, container.WaitConditionNotRunning)
	select {
	case err := <-errCh:
		if err != nil {
			return "", fmt.Errorf("error waiting for container: %w", err)
		}
	case status := <-statusCh:
		if status.StatusCode != 0 {
			// Get logs for error details
			logs, _ := d.dockerClient.ContainerLogs(ctx, resp.ID, container.LogsOptions{
				ShowStdout: true,
				ShowStderr: true,
			})
			if logs != nil {
				logData, _ := io.ReadAll(logs)
				logs.Close()
				return "", fmt.Errorf("container exited with code %d: %s", status.StatusCode, string(logData))
			}
			return "", fmt.Errorf("container exited with code %d", status.StatusCode)
		}
	}

	// Get container logs (output)
	logs, err := d.dockerClient.ContainerLogs(ctx, resp.ID, container.LogsOptions{
		ShowStdout: true,
		ShowStderr: false,
	})
	if err != nil {
		return "", fmt.Errorf("failed to get container logs: %w", err)
	}
	defer logs.Close()

	logData, err := io.ReadAll(logs)
	if err != nil {
		return "", fmt.Errorf("failed to read container logs: %w", err)
	}

	return string(logData), nil
}

// countGPUsFromOutput parses nvidia-smi output and counts the number of GPUs
func (d *GPUDetector) countGPUsFromOutput(output string) int {
	lines := strings.Split(strings.TrimSpace(output), "\n")
	gpuCount := 0
	for _, line := range lines {
		if strings.HasPrefix(line, "GPU ") && strings.Contains(line, ":") {
			gpuCount++
		}
	}
	return gpuCount
}
