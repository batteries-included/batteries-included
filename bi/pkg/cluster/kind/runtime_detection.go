package kind

import (
	"context"
	"log/slog"
	"os/exec"
	"strings"

	dockerclient "github.com/docker/docker/client"
)

// ContainerRuntime represents different container runtime environments
type ContainerRuntime int

const (
	RuntimeUnknown ContainerRuntime = iota
	RuntimeDockerDesktop
	RuntimePodman
	RuntimeColima
)

func (r ContainerRuntime) String() string {
	switch r {
	case RuntimeDockerDesktop:
		return "Docker Desktop"
	case RuntimePodman:
		return "Podman"
	case RuntimeColima:
		return "Colima"
	default:
		return "Unknown"
	}
}

// ContainerRuntimeInfo contains information about the detected container runtime
type ContainerRuntimeInfo struct {
	Runtime     ContainerRuntime
	HostIP      string
	NetworkMode string
}

// DetectContainerRuntime detects which container runtime is being used on macOS
func DetectContainerRuntime(ctx context.Context) (*ContainerRuntimeInfo, error) {
	info := &ContainerRuntimeInfo{
		Runtime:     RuntimeUnknown,
		HostIP:      "localhost",
		NetworkMode: "bridge",
	}

	if isDockerDesktop, err := IsDockerDesktop(ctx); err == nil && isDockerDesktop {
		info.Runtime = RuntimeDockerDesktop
		info.HostIP = "localhost"
		info.NetworkMode = "bridge"
		slog.Debug("Detected Docker Desktop")
		return info, nil
	}

	if isPodman, err := IsPodmanAvailable(); err == nil && isPodman {
		info.Runtime = RuntimePodman
		info.HostIP = getPodmanHostIP(ctx)
		info.NetworkMode = "bridge"
		slog.Debug("Detected Podman", slog.String("hostIP", info.HostIP))
		return info, nil
	}

	if isColima := IsColimaRunning(); isColima {
		info.Runtime = RuntimeColima
		info.HostIP = getColimaHostIP(ctx)
		info.NetworkMode = "bridge"
		slog.Debug("Detected Colima", slog.String("hostIP", info.HostIP))
		return info, nil
	}

	slog.Debug("No supported container runtime detected, using default settings")
	return info, nil
}

func IsColimaRunning() bool {
	cmd := exec.Command("colima", "status")
	output, err := cmd.Output()
	if err != nil {
		return false
	}
	return strings.Contains(string(output), "running")
}

// getPodmanHostIP gets the host IP for Podman connections
func getPodmanHostIP(ctx context.Context) string {
	cmd := exec.CommandContext(ctx, "podman", "machine", "inspect", "--format", "{{.Host.IP}}")
	output, err := cmd.Output()
	if err != nil {
		slog.Debug("Failed to get Podman machine IP, using localhost", slog.String("error", err.Error()))
		return "localhost"
	}
	
	ip := strings.TrimSpace(string(output))
	if ip != "" {
		return ip
	}
	
	return "localhost"
}

// getColimaHostIP gets the host IP for Colima connections
func getColimaHostIP(ctx context.Context) string {
	cmd := exec.CommandContext(ctx, "colima", "ls", "-j")
	output, err := cmd.Output()
	if err != nil {
		slog.Debug("Failed to get Colima status, using localhost", slog.String("error", err.Error()))
		return "localhost"
	}
	
	// Parse the JSON output to extract the address
	if strings.Contains(string(output), "192.168.") {
		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			if strings.Contains(line, "\"address\"") && strings.Contains(line, "192.168.") {
				start := strings.Index(line, "192.168.")
				if start >= 0 {
					end := start
					for i := start; i < len(line) && (line[i] >= '0' && line[i] <= '9' || line[i] == '.'); i++ {
						end = i + 1
					}
					if end > start {
						return line[start:end]
					}
				}
			}
		}
	}
	
	return "localhost"
}

// GetNetworkNameForRuntime returns the appropriate network name for different container runtimes
func GetNetworkNameForRuntime(runtime ContainerRuntime) string {
	switch runtime {
	case RuntimeDockerDesktop:
		return "kind"
	case RuntimePodman:
		return "kind"
	case RuntimeColima:
		return "kind"
	default:
		return "kind"
	}
}

// SupportsGateway checks if the container runtime supports the WireGuard gateway
func SupportsGateway(runtime ContainerRuntime) bool {
	switch runtime {
	case RuntimeDockerDesktop, RuntimePodman, RuntimeColima:
		return true
	default:
		return false
	}
}

// NewDockerClient creates a new Docker client with standard configuration
func NewDockerClient() (*dockerclient.Client, error) {
	return dockerclient.NewClientWithOpts(dockerclient.FromEnv, dockerclient.WithAPIVersionNegotiation())
}
