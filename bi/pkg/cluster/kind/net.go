package kind

import (
	"context"
	"fmt"
	"log/slog"
	"net"

	"github.com/dghubble/ipnets"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/client"
)

// Given a kind network, return the MetalLB IPs
func GetMetalLBIPs(ctx context.Context) (string, error) {
	networks, err := getKindNetwork(ctx)
	if err != nil {
		return "", err
	}

	if len(networks) == 0 {
		return "", fmt.Errorf("no kind networks found")
	}

	slog.Debug("Found kind networks: ", slog.Int("networks", len(networks)))
	for _, subnet := range networks[0].IPAM.Config {
		_, net, err := net.ParseCIDR(subnet.Subnet)
		if err == nil && net.IP.To4() != nil {
			split, err := split(net)
			if err != nil {
				return "", fmt.Errorf("error splitting network: %w", err)
			}

			slog.Debug("Found kind network", slog.Any("split", split))
			return split.String(), nil
		}
	}

	return "", fmt.Errorf("no kind network subnets found")
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

func getKindNetwork(ctx context.Context) ([]types.NetworkResource, error) {
	apiClient, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		return []types.NetworkResource{}, err
	}
	defer apiClient.Close()
	apiClient.NegotiateAPIVersion(ctx)

	// Filter for kind networks
	filters := filters.NewArgs()
	filters.Add("name", "kind")

	networks, err := apiClient.NetworkList(ctx, types.NetworkListOptions{Filters: filters})
	if err != nil {
		return []types.NetworkResource{}, err
	}
	return networks, nil
}
