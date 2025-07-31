package kind

import (
	"context" 
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

// ContainerEngine represents a detected container engine
type ContainerEngine struct {
	Name     string
	Version  string
	Socket   string
	Running  bool
	Platform string
}

// DetectContainerEngines discovers all available container engines
func DetectContainerEngines(ctx context.Context) ([]ContainerEngine, error) {
	var engines []ContainerEngine

	// Check Docker
	if docker, err := detectDocker(ctx); err == nil {
		engines = append(engines, *docker)
	}

	// Check Podman
	if podman, err := detectPodman(ctx); err == nil {
		engines = append(engines, *podman)
	}

	// macOS specific engines
	if runtime.GOOS == "darwin" {
		// Check Colima
		if colima, err := detectColima(ctx); err == nil {
			engines = append(engines, *colima)
		}

		// Check Apple Virtualization
		if apple, err := detectAppleVirtualization(ctx); err == nil {
			engines = append(engines, *apple)
		}
	}

	return engines, nil
}

// GetPreferredEngine returns the best available container engine
func GetPreferredEngine(ctx context.Context) (*ContainerEngine, error) {
	engines, err := DetectContainerEngines(ctx)
	if err != nil {
		return nil, err
	}

	if len(engines) == 0 {
		return nil, fmt.Errorf("no container engines detected")
	}

	// Preference order: Docker > Colima > Podman > Apple Virtualization
	for _, engine := range engines {
		if engine.Running {
			switch engine.Name {
			case "docker":
				return &engine, nil
			}
		}
	}

	for _, engine := range engines {
		if engine.Running {
			switch engine.Name {
			case "colima":
				return &engine, nil
			}
		}
	}

	for _, engine := range engines {
		if engine.Running {
			switch engine.Name {
			case "podman":
				return &engine, nil
			}
		}
	}

	// Return first running engine
	for _, engine := range engines {
		if engine.Running {
			return &engine, nil
		}
	}

	return &engines[0], nil
}

func detectDocker(ctx context.Context) (*ContainerEngine, error) {
	engine := &ContainerEngine{
		Name:     "docker",
		Platform: runtime.GOOS,
	}

	// Try common Docker socket locations
	sockets := []string{"/var/run/docker.sock"}
	if runtime.GOOS == "darwin" {
		homeDir, _ := os.UserHomeDir()
		sockets = append(sockets, 
			homeDir+"/.docker/run/docker.sock",
			homeDir+"/.docker/desktop/docker.sock",
		)
	}

	for _, sock := range sockets {
		if _, err := os.Stat(sock); err == nil {
			engine.Socket = sock
			engine.Running = true
			break
		}
	}

	// Get version if running
	if engine.Running {
		if version, err := getDockerVersion(ctx); err == nil {
			engine.Version = version
		}
	}

	if !engine.Running {
		return nil, fmt.Errorf("docker not running")
	}

	return engine, nil
}

func detectPodman(ctx context.Context) (*ContainerEngine, error) {
	engine := &ContainerEngine{
		Name:     "podman",
		Platform: runtime.GOOS,
	}

	// Try common Podman socket locations
	var sockets []string
	if runtime.GOOS == "darwin" {
		homeDir, _ := os.UserHomeDir()
		sockets = []string{
			homeDir + "/.local/share/containers/podman/machine/qemu/podman.sock",
			homeDir + "/.local/share/containers/podman/machine/podman-machine-default/podman.sock",
		}
	} else {
		uid := os.Getenv("UID")
		if uid == "" {
			uid = "1000" // fallback
		}
		sockets = []string{
			"/run/user/" + uid + "/podman/podman.sock",
			"/run/podman/podman.sock",
		}
	}

	for _, sock := range sockets {
		if _, err := os.Stat(sock); err == nil {
			engine.Socket = sock
			engine.Running = true
			break
		}
	}

	// Get version if running
	if engine.Running {
		if version, err := getPodmanVersion(ctx); err == nil {
			engine.Version = version
		}
	}

	if !engine.Running {
		return nil, fmt.Errorf("podman not running")
	}

	return engine, nil
}

func detectColima(ctx context.Context) (*ContainerEngine, error) {
	if runtime.GOOS != "darwin" {
		return nil, fmt.Errorf("colima only available on macOS")
	}

	engine := &ContainerEngine{
		Name:     "colima",
		Platform: "darwin",
	}

	// Check if Colima is running
	running, err := IsColimaRunning(ctx)
	if err != nil {
		return nil, err
	}

	engine.Running = running

	if running {
		homeDir, _ := os.UserHomeDir()
		engine.Socket = homeDir + "/.colima/default/docker.sock"

		// Get version
		if version, err := getColimaVersion(ctx); err == nil {
			engine.Version = version
		}
	}

	if !engine.Running {
		return nil, fmt.Errorf("colima not running")
	}

	return engine, nil
}

func detectAppleVirtualization(ctx context.Context) (*ContainerEngine, error) {
	if runtime.GOOS != "darwin" {
		return nil, fmt.Errorf("apple virtualization only available on macOS")
	}

	available, err := IsAppleVirtualizationAvailable()
	if err != nil {
		return nil, err
	}

	if !available {
		return nil, fmt.Errorf("apple virtualization not available")
	}

	engine := &ContainerEngine{
		Name:     "apple-virtualization",
		Platform: "darwin",
		Running:  true, // If available, it's considered "running"
	}

	// Try to get macOS version as "version"
	if version, err := getMacOSVersion(); err == nil {
		engine.Version = version
	}

	return engine, nil
}

func getDockerVersion(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "docker", "--version")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func getPodmanVersion(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "podman", "--version")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func getColimaVersion(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "colima", "--version")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func getMacOSVersion() (string, error) {
	cmd := exec.Command("sw_vers", "-productVersion")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

// SetupMacOSRouting configures macOS-specific routing for container networks
func SetupMacOSRouting(ctx context.Context, engine *ContainerEngine, gatewayIP string, subnets []string) error {
	if runtime.GOOS != "darwin" {
		return nil // No-op on non-macOS
	}

	switch engine.Name {
	case "docker":
		return setupDockerDesktopRouting(ctx, gatewayIP, subnets)
	case "colima":
		return setupColimaRouting(ctx, gatewayIP, subnets)
	case "podman":
		return setupPodmanRouting(ctx, gatewayIP, subnets)
	case "apple-virtualization":
		return setupAppleVirtualizationRouting(ctx, gatewayIP, subnets)
	default:
		return fmt.Errorf("unsupported engine for macOS routing: %s", engine.Name)
	}
}

func setupDockerDesktopRouting(ctx context.Context, gatewayIP string, subnets []string) error {
	// Docker Desktop on macOS handles most routing internally
	// We mainly need to ensure the WireGuard gateway can reach container networks
	for _, subnet := range subnets {
		if err := addRoute(ctx, subnet, gatewayIP); err != nil {
			return fmt.Errorf("failed to add route for subnet %s: %w", subnet, err)
		}
	}
	return nil
}

func setupColimaRouting(ctx context.Context, gatewayIP string, subnets []string) error {
	// Colima uses a VM, so we need to route through the VM's IP
	for _, subnet := range subnets {
		if err := addRoute(ctx, subnet, gatewayIP); err != nil {
			return fmt.Errorf("failed to add route for subnet %s: %w", subnet, err)
		}
	}
	return nil
}

func setupPodmanRouting(ctx context.Context, gatewayIP string, subnets []string) error {
	// Podman on macOS uses a VM (similar to Colima)
	for _, subnet := range subnets {
		if err := addRoute(ctx, subnet, gatewayIP); err != nil {
			return fmt.Errorf("failed to add route for subnet %s: %w", subnet, err)
		}
	}
	return nil
}

func setupAppleVirtualizationRouting(ctx context.Context, gatewayIP string, subnets []string) error {
	// Apple Virtualization framework routing
	for _, subnet := range subnets {
		if err := addRoute(ctx, subnet, gatewayIP); err != nil {
			return fmt.Errorf("failed to add route for subnet %s: %w", subnet, err)
		}
	}
	return nil
}

func addRoute(ctx context.Context, subnet, gateway string) error {
	// Add route on macOS
	cmd := exec.CommandContext(ctx, "sudo", "route", "add", "-net", subnet, gateway)
	if err := cmd.Run(); err != nil {
		// Check if route already exists
		if checkRoute(ctx, subnet) {
			return nil // Route already exists, that's ok
		}
		return err
	}
	return nil
}

func checkRoute(ctx context.Context, subnet string) bool {
	cmd := exec.CommandContext(ctx, "route", "get", subnet)
	return cmd.Run() == nil
}