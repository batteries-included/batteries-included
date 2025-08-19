package gpu

import (
	"bi/pkg/cluster/kind"
	"bi/pkg/ctkutil"
	"bi/pkg/osutil"
	"context"
	"fmt"
	"log/slog"

	dockerclient "github.com/docker/docker/client"
	"github.com/spf13/cobra"
)

var (
	skipGPUCountValidation         bool
	skipCTKInstallValidation       bool
	skipDockerRuntimeValidation    bool
	skipContainerRuntimeValidation bool
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
	Run: func(cmd *cobra.Command, args []string) {
		ctx := context.Background()

		fmt.Println("🔍 Validating NVIDIA Container Toolkit setup...")
		fmt.Println()

		// First check if we can detect any GPUs using the new ctkutil GPU detector
		if !skipGPUCountValidation {
			fmt.Println("📊 Checking for NVIDIA GPUs...")

			// Create a provider to get Docker client access if available
			provider := kind.NewClusterProvider(slog.Default(), "validation-test", false, false) // Disable GPU auto-discovery
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
				fmt.Println("   Use --skip-gpu-count-validation to skip this check")
				return
			}

			fmt.Printf("✅ Found %d NVIDIA GPU(s)\n", gpuCount)
			fmt.Println()
		} else {
			fmt.Println("📊 Skipping GPU count validation (--skip-gpu-count-validation)")
			fmt.Println()
		}

		// Create a provider for validation
		provider := kind.NewClusterProvider(slog.Default(), "validation-test", false, false) // Disable GPU auto-discovery
		if err := provider.Init(ctx); err != nil {
			fmt.Printf("❌ Failed to initialize provider: %v\n", err)
			return
		}

		// Now run the validation
		fmt.Println("🔧 Running NVIDIA Container Toolkit validation...")
		fmt.Println()

		// Run the validation logic directly
		if err := validateNvidiaContainerToolkitDirect(provider, ctx); err != nil {
			fmt.Printf("❌ Validation failed: %v\n", err)
			fmt.Println()
			printInstallationInstructions()
			return
		}

		fmt.Println("✅ NVIDIA Container Toolkit validation passed!")
		fmt.Println("🚀 Your system is ready for GPU support in Kind clusters")
	},
}

// validateNvidiaContainerToolkitDirect runs validation without the provider's GPU detection logic
func validateNvidiaContainerToolkitDirect(provider *kind.KindClusterProvider, ctx context.Context) error {
	// Check if nvidia-ctk is installed
	if !skipCTKInstallValidation {
		fmt.Println("  Checking nvidia-ctk installation...")
		if err := ctkutil.ValidateNvidiaCtk(ctx); err != nil {
			return fmt.Errorf("nvidia-ctk validation failed: %w", err)
		}
		fmt.Println("  ✅ nvidia-ctk is installed")
	} else {
		fmt.Println("  ⏭️  Skipping nvidia-ctk installation check (--skip-ctk-install-validation)")
	}

	// Check Docker daemon configuration if using Docker
	if !skipDockerRuntimeValidation {
		fmt.Println("  Checking Docker daemon configuration...")
		if provider != nil && provider.HasDockerClient() {
			if err := ctkutil.ValidateDockerDaemonConfig(); err != nil {
				return fmt.Errorf("docker daemon configuration validation failed: %w", err)
			}
			fmt.Println("  ✅ Docker daemon has nvidia runtime configured")
		} else {
			fmt.Println("  ℹ️  Docker client not available, skipping Docker daemon validation")
		}
	} else {
		fmt.Println("  ⏭️  Skipping Docker daemon configuration check (--skip-docker-runtime-validation)")
	}

	// Check nvidia-container-runtime config
	if !skipContainerRuntimeValidation {
		fmt.Println("  Checking nvidia-container-runtime configuration...")
		if err := ctkutil.ValidateNvidiaContainerRuntimeConfig(); err != nil {
			return fmt.Errorf("nvidia-container-runtime configuration validation failed: %w", err)
		}
		fmt.Println("  ✅ nvidia-container-runtime is properly configured")
	} else {
		fmt.Println("  ⏭️  Skipping nvidia-container-runtime configuration check (--skip-container-runtime-config-validation)")
	}

	return nil
}

// printInstallationInstructions prints comprehensive installation instructions
func printInstallationInstructions() {
	fmt.Println("🔧 NVIDIA Container Toolkit Installation Instructions")
	fmt.Println("════════════════════════════════════════════════════")
	fmt.Println()

	distro := osutil.DetectLinuxDistribution()

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
	case osutil.DistroDebian:
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

	case osutil.DistroRHEL:
		fmt.Println("   📦 For RHEL/CentOS/Fedora/Amazon Linux:")
		fmt.Println("   # Configure the production repository")
		fmt.Println("   curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \\")
		fmt.Println("     sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo")
		fmt.Println()
		fmt.Println("   # Install the toolkit")
		fmt.Println("   sudo dnf install -y nvidia-container-toolkit")

	case osutil.DistroSUSE:
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
	validateNvidiaCmd.Flags().BoolVar(&skipGPUCountValidation, "skip-gpu-count-validation", false, "Skip checking for NVIDIA GPUs on the system")
	validateNvidiaCmd.Flags().BoolVar(&skipCTKInstallValidation, "skip-ctk-install-validation", false, "Skip validation that nvidia-ctk binary is installed")
	validateNvidiaCmd.Flags().BoolVar(&skipDockerRuntimeValidation, "skip-docker-runtime-validation", false, "Skip checking Docker daemon.json configuration")
	validateNvidiaCmd.Flags().BoolVar(&skipContainerRuntimeValidation, "skip-container-runtime-config-validation", false, "Skip checking nvidia-container-runtime config.toml")

	gpuCommand.AddCommand(validateNvidiaCmd)
}
