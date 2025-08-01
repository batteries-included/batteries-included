package kind

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"os/exec"

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
// Return an available subnet for MetalLB, such as 172.18.1.0/24
func split(ipNet *net.IPNet, count int) (*net.IPNet, error) {
	ones, bits := ipNet.Mask.Size()
	slog.Debug("Split network details", 
		slog.String("baseNetwork", ipNet.String()),
		slog.Int("maskOnes", ones),
		slog.Int("maskBits", bits))
	
	shift := calculateShift(ipNet)
	
	// Special case: if shift is 0, use the entire network
	if shift == 0 {
		slog.Debug("Using entire network for MetalLB", 
			slog.String("subnet", ipNet.String()),
			slog.Int("shift", shift))
		return ipNet, nil
	}
	
	// Calculate maximum number of subnets we can create
	maxSubnets := 1 << shift
	
	// Find the first available subnet number
	// Always try to use subnet 1 first (avoiding subnet 0)
	// If that fails, find the next available subnet
	var selectedSubnet int
	
	// Start with subnet 1 (avoiding 0 which is typically used by the bridge)
	selectedSubnet = 1
	
	// If we have more containers than available subnets, we need to wrap around
	// but ensure we don't exceed the maximum
	if selectedSubnet >= maxSubnets {
		// Fall back to using modulo to stay within bounds
		selectedSubnet = (count % maxSubnets)
		if selectedSubnet == 0 {
			selectedSubnet = 1 % maxSubnets
		}
	}
	
	// Final safety check - if we still exceed maxSubnets, it's an error
	if selectedSubnet >= maxSubnets {
		return nil, fmt.Errorf("cannot allocate subnet %d, maximum subnets: %d", selectedSubnet, maxSubnets)
	}
	
	subnet, err := cidr.Subnet(ipNet, shift, selectedSubnet)
	if err != nil {
		return nil, fmt.Errorf("failed to allocate subnet %d: %w", selectedSubnet, err)
	}
	
	slog.Debug("Allocated subnet", 
		slog.Int("shift", shift),
		slog.Int("maxSubnets", maxSubnets),
		slog.Int("containerCount", count),
		slog.Int("selectedSubnet", selectedSubnet),
		slog.String("subnet", subnet.String()))
	
	return subnet, nil
}

func calculateShift(ipNet *net.IPNet) int {
	ones, _ := ipNet.Mask.Size()

	slog.Debug("Calculate shift details", 
		slog.String("network", ipNet.String()),
		slog.Int("ones", ones))

	// For /24 networks or smaller, use the entire network for MetalLB
	// since splitting it into /25 subnets is too restrictive
	if ones >= 24 {
		slog.Debug("Using shift=0 for /24 or larger networks", slog.Int("ones", ones))
		return 0  // Use the entire network - THIS IS THE CRITICAL FIX
	}
	
	// For larger networks (smaller prefix), calculate appropriate shift
	// We want to create /24 subnets for MetalLB
	desiredShift := 24 - ones
	
	// Ensure we don't create subnets that are too small
	maxShift := 32 - ones - 8 // Leave at least 8 bits for host addresses (/24 minimum)
	
	slog.Debug("Shift calculation", 
		slog.Int("maxShift", maxShift),
		slog.Int("desiredShift", desiredShift))
	
	if desiredShift > maxShift {
		slog.Debug("Using maxShift instead of desiredShift", 
			slog.Int("maxShift", maxShift),
			slog.Int("desiredShift", desiredShift))
		return maxShift
	}
	
	slog.Debug("Using desiredShift", slog.Int("desiredShift", desiredShift))
	return desiredShift
}

func getKindNetworks(ctx context.Context) (int, []*net.IPNet, error) {
	// Detect container runtime first to determine which approach to use
	runtimeInfo, err := DetectContainerRuntime(ctx)
	if err != nil {
		slog.Warn("Failed to detect container runtime for getting kind networks", slog.String("error", err.Error()))
		runtimeInfo = &ContainerRuntimeInfo{Runtime: RuntimeUnknown}
	}

	if runtimeInfo.Runtime == RuntimePodman {
		return getKindNetworksFromPodman(ctx)
	} else {
		return getKindNetworksFromDocker(ctx)
	}
}

// Get Kind network information using Podman CLI (for macOS Podman machines)
func getKindNetworksFromPodman(ctx context.Context) (int, []*net.IPNet, error) {
	// Use podman network inspect to get the network details
	cmd := exec.CommandContext(ctx, "podman", "network", "inspect", "kind")
	output, err := cmd.Output()
	if err != nil {
		return 0, nil, fmt.Errorf("failed to inspect kind network with podman: %w", err)
	}

	// Parse JSON output
	var networks []struct {
		Subnets []struct {
			Subnet string `json:"subnet"`
		} `json:"subnets"`
		Containers map[string]interface{} `json:"containers"`
	}

	if err := json.Unmarshal(output, &networks); err != nil {
		return 0, nil, fmt.Errorf("failed to parse podman network inspect output: %w", err)
	}

	if len(networks) == 0 {
		return 0, nil, errors.New("no kind networks found")
	}

	var ipNets []*net.IPNet
	containerCount := len(networks[0].Containers)

	for _, subnet := range networks[0].Subnets {
		_, ipNet, err := net.ParseCIDR(subnet.Subnet)
		if err != nil {
			continue // Skip invalid subnets
		}
		// Only include IPv4 networks
		if ipNet.IP.To4() != nil {
			ipNets = append(ipNets, ipNet)
		}
	}

	if len(ipNets) == 0 {
		return 0, nil, errors.New("no IPv4 subnets found in kind network")
	}

	return containerCount, ipNets, nil
}

// Get Kind network information using Docker API (for Docker Desktop)
func getKindNetworksFromDocker(ctx context.Context) (int, []*net.IPNet, error) {
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
