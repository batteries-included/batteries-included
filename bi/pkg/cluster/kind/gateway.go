package kind

import (
	"archive/tar"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/url"
	"os"
	"os/exec"
	"strings"

	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/api/types/image"
	"github.com/docker/docker/api/types/network"
	"github.com/docker/docker/pkg/jsonmessage"
	"github.com/docker/go-connections/nat"
	"golang.org/x/sync/errgroup"
	"golang.org/x/term"
)

const (
	// UID/GIDs used by distroless.
	nonRootUID = 65532
	nonRootGID = 65532
)

func (c *KindClusterProvider) createWireGuardGateway(ctx context.Context) error {
	containerName := c.name + "-gateway"

	slog.Debug("Creating wireguard gateway", slog.String("name", containerName))

	// Remove the gateway container if it already exists (as we will be updating
	// keys).
	_ = c.destroyWireGuardGateway(ctx)

	// Detect container runtime for runtime-specific configuration
	runtimeInfo, err := DetectContainerRuntime(ctx)
	if err != nil {
		slog.Warn("Failed to detect container runtime, using default configuration", slog.String("error", err.Error()))
		runtimeInfo = &ContainerRuntimeInfo{
			Runtime:     RuntimeUnknown,
			HostIP:      "localhost",
			NetworkMode: "bridge",
		}
	}

	slog.Debug("Creating gateway for runtime", 
		slog.String("runtime", runtimeInfo.Runtime.String()),
		slog.String("networkMode", runtimeInfo.NetworkMode))

	// Check if the NoisySockets image is already available.
	_, err = c.dockerClient.ImageInspect(ctx, NoisySocketsImage)
	if err != nil {
		slog.Debug("NoisySockets image not found, pulling it")

		// Pull the NoisySockets image.
		pullProgressReader, err := c.dockerClient.ImagePull(ctx, NoisySocketsImage, image.PullOptions{})
		if err != nil {
			return fmt.Errorf("failed to pull noisy sockets image: %w", err)
		}
		defer pullProgressReader.Close()

		if err := displayImagePullProgress(pullProgressReader); err != nil {
			return fmt.Errorf("failed to display noisy sockets image pull progress: %w", err)
		}
	}

	// Create the wireguard gateway container with runtime-specific configuration.
	config := &container.Config{
		Image: NoisySocketsImage,
		Cmd: []string{"up", "--log-level=debug", "--enable-dns", "--enable-router",
			// Use Google's DNS servers as the upstream for public DNS queries,
			// to avoid the possibility of a DNS loop when using podman-machine.
			"--dns-public-upstream=8.8.8.8", "--dns-public-upstream=8.8.4.4"},
		Env: []string{"DO_NOT_TRACK=1"},
		ExposedPorts: map[nat.Port]struct{}{
			"51820/udp": {},
		},
	}

	hostConfig := c.createHostConfigForRuntime(runtimeInfo)
	networkingConfig := c.createNetworkingConfigForRuntime(runtimeInfo)

	resp, err := c.dockerClient.ContainerCreate(ctx, config, hostConfig, networkingConfig, nil, containerName)
	if err != nil {
		return fmt.Errorf("failed to create wireguard gateway container: %w", err)
	}

	// Copy the wireguard configuration to the container.
	configArchive, err := c.createWireGuardConfigArchive()
	if err != nil {
		return fmt.Errorf("failed to create wireguard config archive: %w", err)
	}

	if err := c.dockerClient.CopyToContainer(ctx, resp.ID, "/home/nonroot/",
		configArchive, container.CopyToContainerOptions{}); err != nil {
		return fmt.Errorf("failed to copy wireguard config to container: %w", err)
	}

	// Start the container.
	if err := c.dockerClient.ContainerStart(ctx, resp.ID, container.StartOptions{}); err != nil {
		return fmt.Errorf("failed to start wireguard gateway container: %w", err)
	}

	return nil
}

// createHostConfigForRuntime creates runtime-specific host configuration
func (c *KindClusterProvider) createHostConfigForRuntime(runtimeInfo *ContainerRuntimeInfo) *container.HostConfig {
	hostConfig := &container.HostConfig{
		PortBindings: nat.PortMap{
			nat.Port("51820/udp"): []nat.PortBinding{
				{
					HostIP:   "127.0.0.1",
					HostPort: "0",
				},
			},
		},
	}

	// Runtime-specific host configuration
	switch runtimeInfo.Runtime {
	case RuntimePodman:
		hostConfig.PortBindings[nat.Port("51820/udp")] = []nat.PortBinding{
			{
				HostIP:   "0.0.0.0",
				HostPort: "0",
			},
		}
	case RuntimeColima:
		hostConfig.PortBindings[nat.Port("51820/udp")] = []nat.PortBinding{
			{
				HostIP:   "0.0.0.0",
				HostPort: "0",
			},
		}
	case RuntimeDockerDesktop:
	}

	return hostConfig
}

func (c *KindClusterProvider) createNetworkingConfigForRuntime(runtimeInfo *ContainerRuntimeInfo) *network.NetworkingConfig {
	networkName := GetNetworkNameForRuntime(runtimeInfo.Runtime)
	
	networkingConfig := &network.NetworkingConfig{
		EndpointsConfig: map[string]*network.EndpointSettings{
			networkName: {},
		},
	}

	// Runtime-specific networking configuration
	switch runtimeInfo.Runtime {
	case RuntimePodman:
		if !c.networkExists(networkName) {
			networkingConfig.EndpointsConfig = map[string]*network.EndpointSettings{
				"bridge": {},
			}
		}
	case RuntimeColima:
		if !c.networkExists(networkName) {
			networkingConfig.EndpointsConfig = map[string]*network.EndpointSettings{
				"bridge": {},
			}
		}
	case RuntimeDockerDesktop:
		// Docker Desktop typically has the 'kind' network available
	}

	return networkingConfig
}

// networkExists checks if a network exists
func (c *KindClusterProvider) networkExists(networkName string) bool {
	networks, err := c.dockerClient.NetworkList(context.Background(), network.ListOptions{
		Filters: filters.NewArgs(filters.Arg("name", networkName)),
	})
	if err != nil {
		slog.Debug("Failed to check if network exists", slog.String("network", networkName), slog.String("error", err.Error()))
		return false
	}
	return len(networks) > 0
}

func (c *KindClusterProvider) destroyWireGuardGateway(ctx context.Context) error {
	containerID, err := c.getWireGuardGatewayContainer(ctx)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}

		return fmt.Errorf("failed to get wireguard gateway container: %w", err)
	}

	if err := c.dockerClient.ContainerRemove(ctx, containerID, container.RemoveOptions{Force: true}); err != nil {
		return fmt.Errorf("failed to remove wireguard gateway container: %w", err)
	}

	return nil
}

func (c *KindClusterProvider) getWireGuardGatewayContainer(ctx context.Context) (string, error) {
	containers, err := c.dockerClient.ContainerList(ctx, container.ListOptions{
		Filters: filters.NewArgs(filters.Arg("name", c.name+"-gateway")),
		All:     true,
	})
	if err != nil {
		return "", fmt.Errorf("failed to list containers: %w", err)
	}

	if len(containers) == 0 {
		return "", os.ErrNotExist
	}

	return containers[0].ID, nil
}

func (c *KindClusterProvider) getWireGuardGatewayEndpoint(ctx context.Context, containerID string) (string, error) {
	info, err := c.dockerClient.ContainerInspect(ctx, containerID)
	if err != nil {
		return "", fmt.Errorf("failed to inspect wireguard gateway container: %w", err)
	}

	// Is the container running?
	if !info.State.Running {
		return "", errors.New("wireguard gateway container is not running (it may have crashed)")
	}

	port := info.NetworkSettings.Ports[nat.Port("51820/udp")]
	if len(port) == 0 {
		return "", fmt.Errorf("failed to get wireguard gateway container port")
	}

	// Detect the container runtime to determine the correct host IP
	runtimeInfo, err := DetectContainerRuntime(ctx)
	if err != nil {
		slog.Warn("Failed to detect container runtime, falling back to default logic", slog.String("error", err.Error()))
		return c.getWireGuardGatewayEndpointFallback(ctx, port[0].HostPort)
	}

	slog.Debug("Using detected container runtime for gateway endpoint", 
		slog.String("runtime", runtimeInfo.Runtime.String()),
		slog.String("hostIP", runtimeInfo.HostIP))

	host := runtimeInfo.HostIP

	// Special handling for container runtimes that need additional logic
	switch runtimeInfo.Runtime {
	case RuntimePodman:
		if host == "localhost" {
			host = c.getPodmanGatewayHost(ctx)
		}
	case RuntimeColima:
		if host == "localhost" {
			host = c.getColimaGatewayHost(ctx)
		}
	case RuntimeDockerDesktop:
		host = "localhost"
	default:
		return c.getWireGuardGatewayEndpointFallback(ctx, port[0].HostPort)
	}

	if net.ParseIP(host) == nil {
		ips, err := net.LookupIP(host)
		if err != nil {
			return "", fmt.Errorf("failed to resolve host: %w", err)
		}

		var found bool
		for _, ip := range ips {
			if ip.To4() != nil {
				host = ip.String()
				found = true
				break
			}
		}
		if !found {
			return "", fmt.Errorf("no IPv4 address found for host: %s", host)
		}
	}

	return net.JoinHostPort(host, port[0].HostPort), nil
}

// getWireGuardGatewayEndpointFallback provides the original logic as a fallback
func (c *KindClusterProvider) getWireGuardGatewayEndpointFallback(ctx context.Context, hostPort string) (string, error) {
	daemonHostURL, err := url.Parse(c.dockerClient.DaemonHost())
	if err != nil {
		return "", fmt.Errorf("failed to parse daemon host URL: %w", err)
	}

	host := "localhost"
	switch daemonHostURL.Scheme {
	case "http", "https", "tcp":
		host = daemonHostURL.Hostname()
	case "unix", "npipe":
		// Use the default gateway IP (presumably the Docker host) if we are inside
		// a container.
		if _, err := os.Stat("/.dockerenv"); err == nil {
			cmd := exec.CommandContext(ctx, "ip", "route")
			stdout, err := cmd.Output()
			if err != nil {
				return "", fmt.Errorf("failed to get default gateway IP: %w", err)
			}

			for _, line := range strings.Split(string(stdout), "\n") {
				if strings.Contains(line, "default") {
					fields := strings.Fields(line)
					if len(fields) > 2 {
						host = fields[2]
					}
					break
				}
			}
		}
	default:
		return "", fmt.Errorf("unsupported daemon host scheme: %s", daemonHostURL.Scheme)
	}

	// Do we have an IP address or a hostname?
	if net.ParseIP(host) == nil {
		// Resolve the hostname to an IPv4 address (Docker shenanigans).
		ips, err := net.LookupIP(host)
		if err != nil {
			return "", fmt.Errorf("failed to resolve host: %w", err)
		}

		var found bool
		for _, ip := range ips {
			if ip.To4() != nil {
				host = ip.String()
				found = true
				break
			}
		}
		if !found {
			return "", fmt.Errorf("no IPv4 address found for host: %s", host)
		}
	}

	return net.JoinHostPort(host, hostPort), nil
}

// getPodmanGatewayHost determines the correct host for Podman networking
func (c *KindClusterProvider) getPodmanGatewayHost(ctx context.Context) string {
	cmd := exec.CommandContext(ctx, "podman", "machine", "inspect", "--format", "{{.Host.IP}}")
	output, err := cmd.Output()
	if err != nil {
		slog.Debug("Failed to get Podman machine IP, using localhost", slog.String("error", err.Error()))
		return "localhost"
	}
	
	ip := strings.TrimSpace(string(output))
	if ip != "" && net.ParseIP(ip) != nil {
		slog.Debug("Using Podman machine IP", slog.String("ip", ip))
		return ip
	}
	
	return "localhost"
}

// getColimaGatewayHost determines the correct host for Colima networking
func (c *KindClusterProvider) getColimaGatewayHost(ctx context.Context) string {
	// For Colima, try to get the VM IP
	cmd := exec.CommandContext(ctx, "colima", "list", "--json")
	output, err := cmd.Output()
	if err != nil {
		slog.Debug("Failed to get Colima VM info, using localhost", slog.String("error", err.Error()))
		return "localhost"
	}
	
	// Simple string search for IP address (could be improved with JSON parsing)
	outputStr := string(output)
	if strings.Contains(outputStr, "192.168.") {
		lines := strings.Split(outputStr, "\n")
		for _, line := range lines {
			if strings.Contains(line, "\"address\"") {
				start := strings.Index(line, "192.168.")
				if start >= 0 {
					end := start
					for i := start; i < len(line) && (line[i] >= '0' && line[i] <= '9' || line[i] == '.'); i++ {
						end = i + 1
					}
					if end > start {
						ip := line[start:end]
						if net.ParseIP(ip) != nil {
							slog.Debug("Using Colima VM IP", slog.String("ip", ip))
							return ip
						}
					}
				}
			}
		}
	}
	
	return "localhost"
}

func (c *KindClusterProvider) createWireGuardConfigArchive() (io.Reader, error) {
	var buf bytes.Buffer
	tw := tar.NewWriter(&buf)

	// Create the .config and .config/nsh parent directories.
	if err := tw.WriteHeader(&tar.Header{
		Name:     ".config",
		Mode:     0o700,
		Typeflag: tar.TypeDir,
		Uid:      nonRootUID,
		Gid:      nonRootGID,
	}); err != nil {
		return nil, fmt.Errorf("failed to write .config directory header: %w", err)
	}

	if err := tw.WriteHeader(&tar.Header{
		Name:     ".config/nsh",
		Mode:     0o700,
		Typeflag: tar.TypeDir,
		Uid:      nonRootUID,
		Gid:      nonRootGID,
	}); err != nil {
		return nil, fmt.Errorf("failed to write .config/nsh directory header: %w", err)
	}

	var wgConfig bytes.Buffer
	if err := c.wgGateway.WriteNoisySocketsConfig(&wgConfig); err != nil {
		return nil, fmt.Errorf("failed to write wireguard client config: %w", err)
	}

	// Save the config to .config/nsh/noisysockets.yaml.
	header := &tar.Header{
		Name: ".config/nsh/noisysockets.yaml",
		Mode: 0o400,
		Size: int64(wgConfig.Len()),
		Uid:  nonRootUID,
		Gid:  nonRootGID,
	}

	if err := tw.WriteHeader(header); err != nil {
		return nil, fmt.Errorf("failed to write noisysockets.yaml header: %w", err)
	}

	if _, err := tw.Write(wgConfig.Bytes()); err != nil {
		return nil, fmt.Errorf("failed to write noisysockets.yaml: %w", err)
	}

	if err := tw.Close(); err != nil {
		return nil, fmt.Errorf("failed to close tar writer: %w", err)
	}

	return bytes.NewReader(buf.Bytes()), nil
}

func displayImagePullProgress(progressReader io.Reader) error {
	pr, pw := io.Pipe()
	defer pr.Close()

	progressReader = io.TeeReader(progressReader, pw)

	var g errgroup.Group

	// Store a copy of the progress messages for debugging.
	g.Go(func() error {
		seen := make(map[string]bool)

		dec := json.NewDecoder(pr)
		for {
			var j jsonmessage.JSONMessage
			if err := dec.Decode(&j); err != nil {
				if errors.Is(err, io.EOF) {
					return nil
				}

				return fmt.Errorf("failed to decode JSON progress message: %w", err)
			}

			messageKey := j.ID + j.Status
			if alreadyLogged := seen[messageKey]; !alreadyLogged {
				slog.Debug(j.Status, slog.String("id", j.ID))
				seen[messageKey] = true
			}
		}
	})

	// Display the progress messages to the user (if the terminal supports it).
	g.Go(func() error {
		defer pw.Close()

		if err := jsonmessage.DisplayJSONMessagesStream(progressReader,
			os.Stdout, os.Stdout.Fd(), term.IsTerminal(int(os.Stdout.Fd())), nil); err != nil {
			return err
		}

		return nil
	})

	return g.Wait()
}
