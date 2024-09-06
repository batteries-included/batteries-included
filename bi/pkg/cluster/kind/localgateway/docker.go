package localgateway

import (
	"archive/tar"
	"bi/pkg/wireguard"
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

	dockerclient "github.com/docker/docker/client"
)

type DockerGateway struct {
	name         string
	dockerClient *dockerclient.Client
	wgGateway    *wireguard.Gateway
}

func NewDockerGateway(name string, wgGateway *wireguard.Gateway) (*DockerGateway, error) {
	dockerClient, err := dockerclient.NewClientWithOpts(dockerclient.FromEnv, dockerclient.WithAPIVersionNegotiation())
	if err != nil {
		return nil, fmt.Errorf("failed to create docker client: %w", err)
	}

	return &DockerGateway{
		name:         name + "-gateway",
		dockerClient: dockerClient,
		wgGateway:    wgGateway,
	}, nil
}

func (gw *DockerGateway) Create(ctx context.Context) error {
	containerName := gw.name

	slog.Debug("Creating wireguard gateway", slog.String("name", containerName))

	// Remove the gateway container if it already exists (as we will be updating
	// keys).
	_ = gw.Destroy(ctx)

	// Check if the NoisySockets image is already available.
	_, _, err := gw.dockerClient.ImageInspectWithRaw(ctx, noisySocketsImage)
	if err != nil {
		slog.Debug("NoisySockets image not found, pulling it")

		// Pull the NoisySockets image.
		pullProgressReader, err := gw.dockerClient.ImagePull(ctx, noisySocketsImage, image.PullOptions{})
		if err != nil {
			return fmt.Errorf("failed to pull noisy sockets image: %w", err)
		}
		defer pullProgressReader.Close()

		if err := displayImagePullProgress(pullProgressReader); err != nil {
			return fmt.Errorf("failed to display noisy sockets image pull progress: %w", err)
		}
	}

	// Create the wireguard gateway container.
	config := &container.Config{
		Image: noisySocketsImage,
		Cmd:   []string{"up", "--enable-dns", "--enable-router", "--log-level=debug"},
		Env:   []string{"NSH_NO_TELEMETRY=1"},
		ExposedPorts: map[nat.Port]struct{}{
			"51820/udp": {},
		},
	}

	hostConfig := &container.HostConfig{
		// Use a random port on the host.
		PortBindings: nat.PortMap{
			nat.Port("51820/udp"): []nat.PortBinding{
				{
					HostIP:   "127.0.0.1",
					HostPort: "0",
				},
			},
		},
	}

	// Use the `kind` network.
	networkingConfig := &network.NetworkingConfig{
		EndpointsConfig: map[string]*network.EndpointSettings{
			"kind": {},
		},
	}

	resp, err := gw.dockerClient.ContainerCreate(ctx, config, hostConfig, networkingConfig, nil, containerName)
	if err != nil {
		return fmt.Errorf("failed to create wireguard gateway container: %w", err)
	}

	// Copy the wireguard configuration to the container.
	configArchive, err := gw.createWireGuardConfigArchive()
	if err != nil {
		return fmt.Errorf("failed to create wireguard config archive: %w", err)
	}

	if err := gw.dockerClient.CopyToContainer(ctx, resp.ID, "/home/nonroot/",
		configArchive, container.CopyToContainerOptions{}); err != nil {
		return fmt.Errorf("failed to copy wireguard config to container: %w", err)
	}

	// Start the container.
	if err := gw.dockerClient.ContainerStart(ctx, resp.ID, container.StartOptions{}); err != nil {
		return fmt.Errorf("failed to start wireguard gateway container: %w", err)
	}

	return nil
}

func (gw *DockerGateway) Destroy(ctx context.Context) error {
	containerID, err := gw.getWireGuardGatewayContainer(ctx)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}

		return fmt.Errorf("failed to get wireguard gateway container: %w", err)
	}

	if err := gw.dockerClient.ContainerRemove(ctx, containerID, container.RemoveOptions{Force: true}); err != nil {
		return fmt.Errorf("failed to remove wireguard gateway container: %w", err)
	}

	return nil
}

func (gw *DockerGateway) Endpoint(ctx context.Context) (string, error) {
	containerID, err := gw.getWireGuardGatewayContainer(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to get wireguard gateway container: %w", err)
	}

	info, err := gw.dockerClient.ContainerInspect(ctx, containerID)
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

	daemonHostURL, err := url.Parse(gw.dockerClient.DaemonHost())
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
					host = fields[2]
					break
				}
			}
		}
	default:
		return "", fmt.Errorf("unsupported daemon host scheme: %s" + daemonHostURL.Scheme)
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

	return net.JoinHostPort(host, port[0].HostPort), nil
}

func (gw *DockerGateway) GetNetworks(ctx context.Context) ([]*net.IPNet, error) {
	networks, err := gw.dockerClient.NetworkList(ctx, network.ListOptions{
		Filters: filters.NewArgs(filters.Arg("name", "kind")),
	})
	if err != nil {
		return nil, err
	}

	if len(networks) == 0 {
		return nil, errors.New("no kind networks found")
	}

	var ipNets []*net.IPNet
	for _, network := range networks {
		for _, config := range network.IPAM.Config {
			_, ipNet, err := net.ParseCIDR(config.Subnet)
			if err != nil {
				return nil, fmt.Errorf("error parsing subnet: %w", err)
			}
			ipNets = append(ipNets, ipNet)
		}
	}

	return ipNets, nil
}

func (gw *DockerGateway) getWireGuardGatewayContainer(ctx context.Context) (string, error) {
	containers, err := gw.dockerClient.ContainerList(ctx, container.ListOptions{
		Filters: filters.NewArgs(filters.Arg("name", gw.name)),
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

func (gw *DockerGateway) createWireGuardConfigArchive() (io.Reader, error) {
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
	if err := gw.wgGateway.WriteNoisySocketsConfig(&wgConfig); err != nil {
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
