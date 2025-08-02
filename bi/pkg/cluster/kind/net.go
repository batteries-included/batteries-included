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
	
	// For Podman compatibility, try multiple subnet indices if the initial one fails
	for subnetIndex := count + 1; subnetIndex >= 0; subnetIndex-- {
		subnet, err := cidr.Subnet(ipNet, shift, subnetIndex)
		if err == nil {
			return subnet, nil
		}
		// If this subnet index doesn't work, try a smaller one
	}
	
	// If all attempts fail, try with a smaller shift (fewer subnets, larger subnet)
	if shift > 1 {
		return cidr.Subnet(ipNet, shift-1, 1)
	}
	
	return nil, fmt.Errorf("unable to split network %s with count %d", ipNet.String(), count)
}

func calculateShift(ipNet *net.IPNet, count int) int {
	ones, bits := ipNet.Mask.Size()
	
	// Original logic for backward compatibility
	if ones < 24 {
		// For networks smaller than /24, try to create /24 subnets
		return 24 - ones
	}
	
	// For /24 and smaller networks, calculate required bits more conservatively
	// We need to accommodate the existing containers plus room for MetalLB
	availableBits := bits - ones
	
	// Conservative approach: use fewer bits to ensure we have room
	switch {
	case availableBits >= 4:
		// With 4+ available bits, we can safely use 2-3 bits for subnetting
		return 2 // This gives us 4 subnets, should be enough for most cases
	case availableBits >= 2:
		// With 2-3 available bits, use 1 bit (2 subnets)
		return 1
	case availableBits >= 1:
		// With only 1 available bit, use it
		return 1
	default:
		// Network is already at maximum size, can't split further
		return 0
	}
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
