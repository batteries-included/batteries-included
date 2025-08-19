package debug

import (
	"bi/pkg/cluster/kind"
	"bi/pkg/ctkutil"
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"strings"

	dockerclient "github.com/docker/docker/client"
	"github.com/spf13/cobra"
)

var validateNvidiaCmd = &cobra.Command{
	Use:   "validate-nvidia-ctk",
	Short: "Validate NVIDIA Container Toolkit setup for GPU support in Kind clusters",
	Long: `Validates that the NVIDIA Container Toolkit is properly configured for GPU support in Kind clusters.
This checks:
- nvidia-ctk is installed and available
- Docker daemon.json has nvidia runtime configured (if using Docker)
- nvidia-container-runtime config.toml is properly configured

If validation fails, it provides helpful instructions to fix the setup.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
			Level: slog.LevelDebug,
		}))

		ctx := context.Background()

		fmt.Println("🔍 Validating NVIDIA Container Toolkit setup...")
		fmt.Println()

		// First check if we can detect any GPUs using the new ctkutil GPU detector
		fmt.Println("📊 Checking for NVIDIA GPUs...")

		// Create a provider to get Docker client access if available
		provider := kind.NewClusterProvider(logger, "validation-test", false, false) // Disable GPU auto-discovery
		var dockerClient *dockerclient.Client
		if err := provider.Init(ctx); err == nil && provider.HasDockerClient() {
			dockerClient = provider.GetDockerClient()
		}

		detector := ctkutil.NewGPUDetector(dockerClient)
		gpuCount, err := detector.DetectGPUs(ctx)

		if err != nil || gpuCount == 0 {
			fmt.Println("⚠️  No NVIDIA GPUs detected")
			fmt.Println("   This validation is only relevant if you have NVIDIA GPUs")
			if err != nil {
				fmt.Printf("   GPU detection error: %v\n", err)
			}
			return nil
		}

		fmt.Printf("✅ Found %d NVIDIA GPU(s)\n", gpuCount)
		fmt.Println()

		// Now run the validation
		fmt.Println("🔧 Running NVIDIA Container Toolkit validation...")
		fmt.Println()

		// Run the validation logic directly
		if err := validateNvidiaContainerToolkitDirect(provider, ctx); err != nil {
			fmt.Printf("❌ Validation failed: %v\n", err)
			fmt.Println()
			printInstallationInstructions()
			return fmt.Errorf("validation failed: %w", err)
		}

		fmt.Println("✅ NVIDIA Container Toolkit validation passed!")
		fmt.Println("🚀 Your system is ready for GPU support in Kind clusters")

		return nil
	},
}

// validateNvidiaContainerToolkitDirect runs validation without the provider's GPU detection logic
func validateNvidiaContainerToolkitDirect(provider *kind.KindClusterProvider, ctx context.Context) error {
	// Check if nvidia-ctk is installed
	fmt.Println("  Checking nvidia-ctk installation...")
	if err := ctkutil.ValidateNvidiaCtk(ctx); err != nil {
		return fmt.Errorf("nvidia-ctk validation failed: %w", err)
	}
	fmt.Println("  ✅ nvidia-ctk is installed")

	// Check Docker daemon configuration if using Docker
	fmt.Println("  Checking Docker daemon configuration...")
	if provider != nil && provider.HasDockerClient() {
		if err := ctkutil.ValidateDockerDaemonConfig(); err != nil {
			return fmt.Errorf("docker daemon configuration validation failed: %w", err)
		}
		fmt.Println("  ✅ Docker daemon has nvidia runtime configured")
	} else {
		fmt.Println("  ℹ️  Docker client not available, skipping Docker daemon validation")
	}

	// Check nvidia-container-runtime config
	fmt.Println("  Checking nvidia-container-runtime configuration...")
	if err := ctkutil.ValidateNvidiaContainerRuntimeConfig(); err != nil {
		return fmt.Errorf("nvidia-container-runtime configuration validation failed: %w", err)
	}
	fmt.Println("  ✅ nvidia-container-runtime is properly configured")

	return nil
}

// validateNvidiaContainerToolkit uses the shared validation logic
func validateNvidiaContainerToolkit(provider *kind.KindClusterProvider, ctx context.Context) error {
	// Check if nvidia-ctk is installed
	fmt.Println("  Checking nvidia-ctk installation...")
	if err := ctkutil.ValidateNvidiaCtk(ctx); err != nil {
		return fmt.Errorf("nvidia-ctk validation failed: %w", err)
	}
	fmt.Println("  ✅ nvidia-ctk is installed")

	// Check Docker daemon configuration if using Docker
	fmt.Println("  Checking Docker daemon configuration...")
	if provider.HasDockerClient() {
		if err := ctkutil.ValidateDockerDaemonConfig(); err != nil {
			return fmt.Errorf("docker daemon configuration validation failed: %w", err)
		}
		fmt.Println("  ✅ Docker daemon has nvidia runtime configured")
	} else {
		fmt.Println("  ℹ️  Docker client not available, skipping Docker daemon validation")
	}

	// Check nvidia-container-runtime config
	fmt.Println("  Checking nvidia-container-runtime configuration...")
	if err := ctkutil.ValidateNvidiaContainerRuntimeConfig(); err != nil {
		return fmt.Errorf("nvidia-container-runtime configuration validation failed: %w", err)
	}
	fmt.Println("  ✅ nvidia-container-runtime is properly configured")

	return nil
}

// detectLinuxDistribution attempts to detect the Linux distribution
func detectLinuxDistribution() string {
	// Try to read /etc/os-release
	if data, err := os.ReadFile("/etc/os-release"); err == nil {
		content := string(data)
		if strings.Contains(strings.ToLower(content), "ubuntu") || strings.Contains(strings.ToLower(content), "debian") {
			return "debian"
		}
		if strings.Contains(strings.ToLower(content), "rhel") || strings.Contains(strings.ToLower(content), "centos") ||
			strings.Contains(strings.ToLower(content), "fedora") || strings.Contains(strings.ToLower(content), "amazon") {
			return "rhel"
		}
		if strings.Contains(strings.ToLower(content), "opensuse") || strings.Contains(strings.ToLower(content), "sle") {
			return "suse"
		}
	}

	// Try to check for package managers
	if _, err := exec.LookPath("apt"); err == nil {
		return "debian"
	}
	if _, err := exec.LookPath("dnf"); err == nil {
		return "rhel"
	}
	if _, err := exec.LookPath("yum"); err == nil {
		return "rhel"
	}
	if _, err := exec.LookPath("zypper"); err == nil {
		return "suse"
	}

	return "unknown"
}

// printInstallationInstructions prints comprehensive installation instructions
func printInstallationInstructions() {
	fmt.Println("🔧 NVIDIA Container Toolkit Installation Instructions")
	fmt.Println("════════════════════════════════════════════════════")
	fmt.Println()

	distro := detectLinuxDistribution()

	// Step 1: Prerequisites
	fmt.Println("1️⃣ Prerequisites:")
	fmt.Println("   • NVIDIA GPU driver must be installed")
	fmt.Println("   • Docker must be installed and running")
	fmt.Println("   • Verify GPU driver: nvidia-smi")
	fmt.Println()

	// Step 2: Install NVIDIA Container Toolkit
	fmt.Println("2️⃣ Install NVIDIA Container Toolkit:")
	fmt.Println()

	switch distro {
	case "debian":
		fmt.Println("   📦 For Ubuntu/Debian:")
		fmt.Println("   # Configure the production repository")
		fmt.Println("   curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg")
		fmt.Println("   curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \\")
		fmt.Println("     sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \\")
		fmt.Println("     sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list")
		fmt.Println()
		fmt.Println("   # Update package list and install")
		fmt.Println("   sudo apt-get update")
		fmt.Println("   sudo apt-get install -y nvidia-container-toolkit")

	case "rhel":
		fmt.Println("   📦 For RHEL/CentOS/Fedora/Amazon Linux:")
		fmt.Println("   # Configure the production repository")
		fmt.Println("   curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \\")
		fmt.Println("     sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo")
		fmt.Println()
		fmt.Println("   # Install the toolkit")
		fmt.Println("   sudo dnf install -y nvidia-container-toolkit")

	case "suse":
		fmt.Println("   📦 For OpenSUSE/SLE:")
		fmt.Println("   # Configure the production repository")
		fmt.Println("   sudo zypper ar https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo")
		fmt.Println()
		fmt.Println("   # Install the toolkit")
		fmt.Println("   sudo zypper --gpg-auto-import-keys install -y nvidia-container-toolkit")

	default:
		fmt.Println("   📦 For your distribution, please visit:")
		fmt.Println("   https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html")
	}

	fmt.Println()

	// Step 3: Configure Docker
	fmt.Println("3️⃣ Configure Docker for NVIDIA runtime:")
	fmt.Println("   sudo nvidia-ctk runtime configure --runtime=docker")
	fmt.Println()

	// Step 4: Enable volume mounts
	fmt.Println("4️⃣ Enable volume mount support (required for Kind):")
	fmt.Println("   sudo nvidia-ctk config --set accept-nvidia-visible-devices-as-volume-mounts=true --in-place")
	fmt.Println()

	// Step 5: Restart Docker
	fmt.Println("5️⃣ Restart Docker daemon:")
	fmt.Println("   sudo systemctl restart docker")
	fmt.Println()

	// Step 6: Verify
	fmt.Println("6️⃣ Verify installation:")
	fmt.Println("   # Test with nvidia runtime")
	fmt.Println("   docker run --rm --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=all ubuntu:24.04 nvidia-smi -L")
	fmt.Println()
	fmt.Println("   # Test with volume mount (used by Kind)")
	fmt.Println("   docker run --rm -v /dev/null:/var/run/nvidia-container-devices/all ubuntu:24.04 nvidia-smi -L")
	fmt.Println()

	// Step 7: Validate
	fmt.Println("7️⃣ Run validation again:")
	fmt.Println("   bi debug validate-nvidia-ctk")
	fmt.Println()
	fmt.Println("════════════════════════════════════════════════════")
}

func init() {
	debugCmd.AddCommand(validateNvidiaCmd)
}
