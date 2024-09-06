package kind

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"os/exec"

	"github.com/dghubble/ipnets"

	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/api/types/network"
	"github.com/docker/docker/client"
)

// Given a kind network, return the MetalLB IPs
func GetMetalLBIPs(ctx context.Context) (string, error) {
	var networks []*net.IPNet
	var err error
	if IsDockerAvailable() {
		networks, err = getKindDockerNetwork(ctx)
	} else if IsPodmanAvailable() {
		networks, err = getKindPodmanNetwork(ctx)
	} else {
		err = errors.New("neither docker nor podman are available")
	}
	if err != nil {
		return "", err
	}

	slog.Debug("Found kind networks: ", slog.Int("networks", len(networks)))
	for _, subnet := range networks {
		if subnet.IP.To4() != nil {
			split, err := split(subnet)
			if err != nil {
				return "", fmt.Errorf("error splitting network: %w", err)
			}

			slog.Debug("Found kind network", slog.Any("split", split))
			return split.String(), nil
		}
	}

	return "", errors.New("no kind networks found")
}

// Given a Network suck as 172.18.0.0/16
// Return the bottom half of the network, such as 172.18.128.0/17
func split(ipNet *net.IPNet) (*net.IPNet, error) {
	subnets, err := ipnets.SubnetShift(ipNet, 1)
	if err != nil {
		return nil, fmt.Errorf("unable to shift subnet: %w", err)
	}
	if len(subnets) <= 1 {
		return nil, fmt.Errorf("no upper subnets found")
	}

	return subnets[1], nil
}

func getKindDockerNetwork(ctx context.Context) ([]*net.IPNet, error) {
	dockerClient, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		return nil, err
	}
	defer dockerClient.Close()

	networks, err := dockerClient.NetworkList(ctx, network.ListOptions{
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

func getKindPodmanNetwork(ctx context.Context) ([]*net.IPNet, error) {
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
