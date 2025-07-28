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
	shift := calculateShift(ipNet)
	
	// Calculate maximum number of subnets we can create
	maxSubnets := 1 << shift
	
	// Use count + 1 as the subnet number to avoid subnet 0
	// This ensures we get sequential subnets starting from 1
	subnetNum := count + 1
	
	// Check if we can fit the requested subnet
	if subnetNum >= maxSubnets {
		return nil, fmt.Errorf("cannot allocate subnet %d, maximum subnets: %d", subnetNum, maxSubnets)
	}
	
	subnet, err := cidr.Subnet(ipNet, shift, subnetNum)
	if err != nil {
		return nil, fmt.Errorf("failed to allocate subnet %d: %w", subnetNum, err)
	}
	
	slog.Debug("Allocated subnet", 
		slog.Int("shift", shift),
		slog.Int("maxSubnets", maxSubnets),
		slog.Int("selectedSubnet", subnetNum),
		slog.String("subnet", subnet.String()))
	
	return subnet, nil
}

func calculateShift(ipNet *net.IPNet) int {
	ones, _ := ipNet.Mask.Size()

	// For networks smaller than /24, we need more careful handling
	if ones >= 24 {
		return 1
	}
	
	// Ensure we don't create subnets that are too small
	maxShift := 32 - ones - 8 // Leave at least 8 bits for host addresses
	desiredShift := 24 - ones
	
	if desiredShift > maxShift {
		return maxShift
	}
	
	return desiredShift
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
