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
	"os"
	"os/exec"
	"strings"
)

type PodmanGateway struct {
	name      string
	wgGateway *wireguard.Gateway
}

func NewPodmanGateway(name string, wgGateway *wireguard.Gateway) (*PodmanGateway, error) {
	return &PodmanGateway{
		name:      name + "-gateway",
		wgGateway: wgGateway,
	}, nil
}

func (gw *PodmanGateway) Create(ctx context.Context) error {
	containerName := gw.name

	slog.Debug("Creating wireguard gateway", slog.String("name", containerName))

	// Remove the gateway container if it already exists
	_ = gw.Destroy(ctx)

	// Check if the NoisySockets image is available locally, if not, pull it
	if err := gw.pullImage(ctx); err != nil {
		return err
	}

	// Create the wireguard gateway container
	cmd := exec.CommandContext(ctx, "podman", "create", "--name", containerName,
		"--network", "kind",
		"--expose", "51820/udp",
		"-p", "127.0.0.1::51820/udp",
		"-e", "NSH_NO_TELEMETRY=1",
		noisySocketsImage,
		"up", "--enable-dns", "--enable-router", "--log-level=debug")

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to create wireguard gateway container: %w", err)
	}

	// Copy the WireGuard configuration to the container
	configArchive, err := gw.createWireGuardConfigArchive()
	if err != nil {
		return fmt.Errorf("failed to create wireguard config archive: %w", err)
	}

	if err := gw.copyToContainer(ctx, containerName, "/home/nonroot/", configArchive); err != nil {
		return fmt.Errorf("failed to copy wireguard config to container: %w", err)
	}

	// Start the container
	cmd = exec.CommandContext(ctx, "podman", "start", containerName)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to start wireguard gateway container: %w", err)
	}

	return nil
}

func (gw *PodmanGateway) Destroy(ctx context.Context) error {
	containerID, err := gw.getWireGuardGatewayContainer(ctx)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		return fmt.Errorf("failed to get wireguard gateway container: %w", err)
	}

	// Remove the container
	cmd := exec.CommandContext(ctx, "podman", "rm", "-f", containerID)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to remove wireguard gateway container: %w", err)
	}

	return nil
}

func (gw *PodmanGateway) Endpoint(ctx context.Context) (string, error) {
	containerID, err := gw.getWireGuardGatewayContainer(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to get wireguard gateway container: %w", err)
	}

	// Inspect the container to get network information
	cmd := exec.CommandContext(ctx, "podman", "inspect", "--format", "{{ json .NetworkSettings.Ports }}", containerID)
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to inspect wireguard gateway container: %w", err)
	}

	// Extract port information from the inspection output
	portInfoJSON := strings.TrimSpace(string(output))
	if portInfoJSON == "" {
		return "", errors.New("wireguard gateway container is not running or has no port mapping")
	}

	portInfo := make(map[string][]struct {
		HostIP   string `json:"HostIp"`
		HostPort string `json:"HostPort"`
	})

	if err := json.Unmarshal([]byte(portInfoJSON), &portInfo); err != nil {
		return "", fmt.Errorf("failed to unmarshal port info: %w", err)
	}

	wgPortInfo, ok := portInfo["51820/udp"]
	if !ok || len(wgPortInfo) == 0 {
		return "", errors.New("wireguard gateway container has no port mapping")
	}

	return net.JoinHostPort(wgPortInfo[0].HostIP, wgPortInfo[0].HostPort), nil
}

func (gw *PodmanGateway) GetNetworks(ctx context.Context) ([]*net.IPNet, error) {
	cmd := exec.CommandContext(ctx, "podman", "network", "inspect", "kind")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get kind network subnet: %w", err)
	}

	var networks []struct {
		Name    string `json:"name"`
		Subnets []struct {
			Subnet  string `json:"subnet"`
			Gateway string `json:"gateway"`
		} `json:"subnets"`
	}

	if err := json.Unmarshal(output, &networks); err != nil {
		return nil, fmt.Errorf("failed to unmarshal kind network info: %w", err)
	}

	if len(networks) == 0 {
		return nil, errors.New("kind network not found")
	}

	var ipNets []*net.IPNet
	for _, subnet := range networks[0].Subnets {
		_, ipNet, err := net.ParseCIDR(subnet.Subnet)
		if err != nil {
			return nil, fmt.Errorf("error parsing subnet: %w", err)
		}
		ipNets = append(ipNets, ipNet)
	}

	return ipNets, nil
}

func (gw *PodmanGateway) getWireGuardGatewayContainer(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "podman", "ps", "-a", "--filter", fmt.Sprintf("name=%s", gw.name), "--format", "{{.ID}}")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to list containers: %w", err)
	}

	containerID := strings.TrimSpace(string(output))
	if containerID == "" {
		return "", os.ErrNotExist
	}

	return containerID, nil
}

func (gw *PodmanGateway) createWireGuardConfigArchive() (io.Reader, error) {
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

func (gw *PodmanGateway) pullImage(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, "podman", "pull", noisySocketsImage)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to pull image: %w", err)
	}
	return nil
}

func (gw *PodmanGateway) copyToContainer(ctx context.Context, containerName, destPath string, content io.Reader) error {
	cmd := exec.CommandContext(ctx, "podman", "cp", "-", fmt.Sprintf("%s:%s", containerName, destPath))
	cmd.Stdin = content
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to copy to container: %w", err)
	}
	return nil
}
