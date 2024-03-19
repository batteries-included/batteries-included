package docker

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
func GetMetalLBIPs() (string, error) {
	ctx := context.TODO()
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
			split := split(net)
			slog.Debug("Found kind network: ", slog.Any("split", split))
			return split.String(), nil
		}
	}

	return "", fmt.Errorf("no kind network subnets found")
}

// Given a Network suck as 172.18.0.0/16
// Return the bottom half of the network, such as 172.18.128.0/17
func split(ipNet *net.IPNet) *net.IPNet {
	subnets, err := ipnets.SubnetShift(ipNet, 1)
	if err != nil {
		slog.Debug("Error splitting network: ", slog.Any("err", err))
		return nil
	}
	if len(subnets) <= 1 {
		slog.Debug("No upper subnets found")
		return nil
	}

	return subnets[1]
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
