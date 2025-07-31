package local

import (
	"bi/pkg/cluster/kind"
	"bi/pkg/installs"
	"bi/pkg/log" 
	"bi/pkg/start"
	"context"
	"fmt"
	"log/slog"
	"os"
	"runtime"

	"github.com/spf13/cobra"
)

var localStartCmd = &cobra.Command{
	Use:   "start [install-spec-file] [flags]",
	Short: "Start a local installation with container engine auto-detection",
	Long: `Start a local Batteries Included installation with automatic 
container engine detection and WireGuard VPN setup.

Supports:
- Docker Desktop (macOS/Linux)  
- Podman (macOS/Linux)
- Colima (macOS)
- Apple Virtualization (macOS)

This command will:
1. Detect available container engines
2. Start a local Kubernetes cluster  
3. Start the control server
4. Display WireGuard VPN connection commands

Example:
  bix local start bootstrap/local.spec.json`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		specFile := args[0]
		
		slog.Info("Starting local Batteries Included installation", 
			slog.String("specFile", specFile))

		ctx, cancel := context.WithCancel(cmd.Context())
		defer cancel()

		// Check if spec file exists
		if _, err := os.Stat(specFile); os.IsNotExist(err) {
			return fmt.Errorf("spec file not found: %s", specFile)
		}

		// Detect and report container engine
		engine, err := kind.GetPreferredEngine(ctx)
		if err != nil {
			return fmt.Errorf("failed to detect container engine: %w", err)
		}
		
		slog.Info("Detected container engine", 
			slog.String("engine", engine.Name),
			slog.String("version", engine.Version),
			slog.Bool("running", engine.Running))
		
		// Setup environment for the installation
		eb := installs.NewEnvBuilder(installs.WithSlugOrURL(specFile))
		env, err := eb.Build(ctx)
		if err != nil {
			return fmt.Errorf("failed to build environment: %w", err)
		}

		err = env.Init(ctx, true)
		if err != nil {
			return fmt.Errorf("failed to initialize environment: %w", err)
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		// Start the installation
		fmt.Printf("\n🚀 Starting Batteries Included local installation...\n")
		fmt.Printf("📋 Spec file: %s\n", specFile)
		fmt.Printf("🐳 Container engine: %s (%s)\n", engine.Name, engine.Version)
		fmt.Printf("💻 Platform: %s\n", runtime.GOOS)
		fmt.Println()

		// Start the installation process
		if err := start.StartInstall(ctx, env, false); err != nil {
			return fmt.Errorf("failed to start installation: %w", err)
		}

		// Setup macOS routing if needed
		if runtime.GOOS == "darwin" {
			if err := setupMacOSRouting(ctx, engine, env); err != nil {
				slog.Warn("Failed to setup macOS routing", slog.Any("error", err))
			}
		}

		// Display VPN connection information
		if err := displayVPNInfo(ctx, env, engine.Name); err != nil {
			slog.Warn("Failed to display VPN information", slog.Any("error", err))
		}

		return nil
	},
}

func setupMacOSRouting(ctx context.Context, engine *kind.ContainerEngine, env *installs.InstallEnv) error {
	slog.Info("Setting up macOS routing for container networks")

	// Get cluster networks that need routing
	subnets := []string{
		"172.18.0.0/16", // Kind network
		"10.89.0.0/16",  // MetalLB range
	}

	// Use the WireGuard gateway IP as the route destination
	gatewayIP := "100.64.250.1" // This should match the gateway config

	return kind.SetupMacOSRouting(ctx, engine, gatewayIP, subnets)
}

func displayVPNInfo(ctx context.Context, env *installs.InstallEnv, engine string) error {
	fmt.Println("\n🔐 WireGuard VPN Setup")
	fmt.Println("========================")
	
	// Get WireGuard config path
	configPath := env.WireGuardConfigPath()
	fmt.Printf("📁 WireGuard config: %s\n", configPath)

	// Check if config exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		fmt.Println("⚠️  WireGuard config not yet available - cluster may still be starting")
		return nil
	}

	fmt.Println("\n📝 To connect via WireGuard VPN:")
	
	// Platform-specific instructions
	switch runtime.GOOS {
	case "darwin":
		fmt.Println("# Install WireGuard (if not already installed)")
		fmt.Println("brew install wireguard-tools")
		fmt.Println()
		fmt.Printf("# Connect to VPN\nsudo wg-quick up %s\n", configPath)
		fmt.Println()
		fmt.Printf("# Disconnect from VPN\nsudo wg-quick down %s\n", configPath)
		
		// macOS-specific routing info
		if engine == "podman" || engine == "colima" {
			fmt.Println("\n🔧 macOS Container Routing:")
			fmt.Println("The VPN handles routing to container networks automatically.")
			fmt.Printf("Engine: %s\n", engine)
		}

	case "linux":
		fmt.Printf("# Connect to VPN\nsudo wg-quick up %s\n", configPath)
		fmt.Println()
		fmt.Printf("# Disconnect from VPN\nsudo wg-quick down %s\n", configPath)

	default:
		fmt.Printf("# Use your platform's WireGuard client with config: %s\n", configPath)
	}

	fmt.Println("\n🌐 Alternative connection methods:")
	fmt.Println("# Using NoisySockets (cross-platform)")
	fmt.Println("# Install: go install github.com/noisysockets/noisysockets/cmd/nsh@latest") 
	fmt.Printf("nsh up %s\n", configPath)

	// Try to get control server endpoint
	if endpoint, err := getControlServerEndpoint(ctx, env); err == nil {
		fmt.Printf("\n🎯 Control Server: %s\n", endpoint)
		fmt.Println("(Available once VPN is connected)")
	}

	return nil
}

func getControlServerEndpoint(ctx context.Context, env *installs.InstallEnv) (string, error) {
	// Try to read the control server endpoint from the environment
	// This is a placeholder - the actual implementation would depend on 
	// how the control server endpoint is stored/discovered
	return "https://control.<ip>.batrsinc.co", nil
}

func init() {
	localCmd.AddCommand(localStartCmd)
}