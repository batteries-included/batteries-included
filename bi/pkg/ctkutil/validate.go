package ctkutil

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"

	"github.com/BurntSushi/toml"
)

// ValidateNvidiaContainerToolkit validates the complete NVIDIA container toolkit setup
func ValidateNvidiaContainerToolkit(ctx context.Context, hasDockerClient bool) error {
	// Check if nvidia-ctk is installed
	if err := ValidateNvidiaCtk(ctx); err != nil {
		return fmt.Errorf("nvidia-ctk validation failed: %w", err)
	}

	// Check Docker daemon configuration if using Docker
	if hasDockerClient {
		if err := ValidateDockerDaemonConfig(); err != nil {
			return fmt.Errorf("docker daemon configuration validation failed: %w", err)
		}
	}

	// Check nvidia-container-runtime config
	if err := ValidateNvidiaContainerRuntimeConfig(); err != nil {
		return fmt.Errorf("nvidia-container-runtime configuration validation failed: %w", err)
	}

	return nil
}

// ValidateNvidiaCtk checks if nvidia-ctk is installed
func ValidateNvidiaCtk(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, "nvidia-ctk", "--version")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("nvidia-ctk not found. Install with: sudo apt-get install nvidia-container-toolkit (Ubuntu/Debian) or sudo dnf install nvidia-container-toolkit (RHEL/Fedora). Run 'bi gpu validate-nvidia-ctk' for detailed instructions")
	}
	return nil
}

// ValidateDockerDaemonConfig checks if Docker daemon.json has nvidia runtime configured
func ValidateDockerDaemonConfig() error {
	configPath := "/etc/docker/daemon.json"

	// Check if daemon.json exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return fmt.Errorf("docker daemon.json not found. Configure with: sudo nvidia-ctk runtime configure --runtime=docker. Run 'bi gpu validate-nvidia-ctk' for detailed instructions")
	}

	// Read and parse daemon.json
	data, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read %s: %w. Please ensure Docker daemon.json is readable and configured with NVIDIA runtime", configPath, err)
	}

	var config map[string]interface{}
	if err := json.Unmarshal(data, &config); err != nil {
		return fmt.Errorf("failed to parse %s: %w. Please ensure Docker daemon.json is valid JSON", configPath, err)
	}

	// Check if runtimes section exists
	runtimes, ok := config["runtimes"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("docker daemon.json missing 'runtimes' section. Configure with: sudo nvidia-ctk runtime configure --runtime=docker. Run 'bi gpu validate-nvidia-ctk' for detailed instructions")
	}

	// Check if nvidia runtime exists
	if _, ok := runtimes["nvidia"]; !ok {
		return fmt.Errorf("docker daemon.json missing 'nvidia' runtime. Configure with: sudo nvidia-ctk runtime configure --runtime=docker. Run 'bi gpu validate-nvidia-ctk' for detailed instructions")
	}

	return nil
}

// ValidateNvidiaContainerRuntimeConfig checks if nvidia-container-runtime config is properly configured
func ValidateNvidiaContainerRuntimeConfig() error {
	configPath := "/etc/nvidia-container-runtime/config.toml"

	// Check if config.toml exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return fmt.Errorf("nvidia-container-runtime config not found. Install with: sudo apt-get install nvidia-container-toolkit (Ubuntu/Debian). Run 'bi gpu validate-nvidia-ctk' for detailed instructions")
	}

	// Read and parse config.toml
	data, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read %s: %w. Please ensure NVIDIA container runtime config is readable", configPath, err)
	}

	var config map[string]interface{}
	if err := toml.Unmarshal(data, &config); err != nil {
		return fmt.Errorf("failed to parse %s: %w. Please ensure NVIDIA container runtime config is valid TOML", configPath, err)
	}

	// Check for accept-nvidia-visible-devices-as-volume-mounts setting
	acceptNvidiaVisibleDevices, ok := config["accept-nvidia-visible-devices-as-volume-mounts"]
	if !ok {
		return fmt.Errorf("nvidia-container-runtime config missing 'accept-nvidia-visible-devices-as-volume-mounts' setting. Configure with: sudo nvidia-ctk config --set accept-nvidia-visible-devices-as-volume-mounts=true --in-place. Run 'bi gpu validate-nvidia-ctk' for detailed instructions")
	}

	// Check if the setting is true
	if accept, ok := acceptNvidiaVisibleDevices.(bool); !ok || !accept {
		return fmt.Errorf("nvidia-container-runtime 'accept-nvidia-visible-devices-as-volume-mounts' must be true. Configure with: sudo nvidia-ctk config --set accept-nvidia-visible-devices-as-volume-mounts=true --in-place. Run 'bi gpu validate-nvidia-ctk' for detailed instructions")
	}

	return nil
}
