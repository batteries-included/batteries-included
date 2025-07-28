package kind

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"

	"github.com/apparentlymart/go-cidr/cidr"

	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/api/types/network"
	"github.com/docker/docker/client"
)

// Given a kind network, return the MetalLB IPs
func GetMetalLBIPs(ctx context.Context) (string, error) {
	existing, networks, err := getKindNetworks(ctx)
	if err != nil {
		return "", err
	}

	slog.Debug("Found kind networks: ", slog.Int("networks", len(networks)), slog.Int("existing", existing))
	for _, subnet := range networks {
		if subnet.IP.To4() == nil {
			continue
		}

		split, err := split(subnet, existing)
		if err != nil {
			return "", fmt.Errorf("error splitting network: %w", err)
		}

		slog.Debug("Found kind network", slog.Any("split", split))
		return split.String(), nil

	}

	return "", errors.New("no kind networks found")
}

// Given a Network such as 172.18.0.0/16
// Return the bottom half of the network, such as 172.18.1.0/24
func split(ipNet *net.IPNet, count int) (*net.IPNet, error) {
	shift := calculateShift(ipNet, count)
	return cidr.Subnet(ipNet, shift, count+1)
}

func calculateShift(ipNet *net.IPNet, count int) int {
	ones, bits := ipNet.Mask.Size()
	
	// Original logic for backward compatibility
	if ones < 24 {
		// For networks smaller than /24, try to create /24 subnets
		return 24 - ones
	}
	
	// For /24 and smaller networks, calculate required bits dynamically
	// Calculate how many bits we need to accommodate count+1 subnets
	requiredSubnets := count + 2 // +1 for the new subnet, +1 for safety margin
	requiredBits := 0
	for i := 1; i < requiredSubnets; i <<= 1 {
		requiredBits++
	}
	
	// Default to 3 bits (8 subnets) for most cases to maintain compatibility
	// But use more bits if needed to accommodate more containers
	defaultShift := 3
	if requiredBits < defaultShift {
		requiredBits = defaultShift
	}
	
	// Calculate available bits
	availableBits := bits - ones
	
	// If we need more bits than available, use what we have
	// This will cause an error later in cidr.Subnet, but at least we tried
	if requiredBits > availableBits {
		return availableBits
	}
	
	return requiredBits
}

func getKindNetworks(ctx context.Context) (int, []*net.IPNet, error) {
	dockerClient, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		return 0, nil, err
	}
	defer dockerClient.Close()

	networks, err := dockerClient.NetworkList(ctx, network.ListOptions{
		Filters: filters.NewArgs(filters.Arg("name", "kind")),
	})
	if err != nil {
		return 0, nil, err
	}

	if len(networks) == 0 {
		return 0, nil, errors.New("no kind networks found")
	}

	if len(networks) > 1 {
		return 0, nil, errors.New("multiple kind networks found")
	}

	// we have to do an inspect to get the full details
	network, err := dockerClient.NetworkInspect(ctx, networks[0].ID, network.InspectOptions{})
	if err != nil {
		return 0, nil, err
	}

	var ipNets []*net.IPNet
	for _, config := range network.IPAM.Config {
		_, ipNet, err := net.ParseCIDR(config.Subnet)
		if err != nil {
			return 0, nil, fmt.Errorf("error parsing subnet: %w", err)
		}
		ipNets = append(ipNets, ipNet)
	}

	return len(network.Containers), ipNets, nil
}
