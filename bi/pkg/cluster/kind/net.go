package kind

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"

	"github.com/dghubble/ipnets"

	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/api/types/network"
	"github.com/docker/docker/client"
)

// Given a kind network, return the MetalLB IPs
func GetMetalLBIPs(ctx context.Context) (string, error) {
	networks, err := getKindNetwork(ctx)
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

// Given a Network such as 172.18.0.0/16
// Return the bottom half of the network, such as 172.18.128.0/17
func split(ipNet *net.IPNet) (*net.IPNet, error) {
	shift := calculate_shift(ipNet)
	subnets, err := ipnets.SubnetShift(ipNet, shift)
	if err != nil {
		return nil, fmt.Errorf("unable to shift subnet: %w", err)
	}
	if len(subnets) <= 1 {
		return nil, fmt.Errorf("no upper subnets found")
	}

	return subnets[1], nil
}

func calculate_shift(ipNet *net.IPNet) int {
	ones, _ := ipNet.Mask.Size()

	if ones >= 24 {
		return 1
	}

	return 24 - ones
}

func getKindNetwork(ctx context.Context) ([]*net.IPNet, error) {
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
