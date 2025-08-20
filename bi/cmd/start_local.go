/*
Copyright © 2024 Elliott Clark <elliott@batteriesincl.com>
*/
package cmd

import (
	"bi/pkg/local"
	"bi/pkg/log"
	"bi/pkg/start"
	"fmt"
	"log/slog"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var startLocalCmd = &cobra.Command{
	Use:   "start-local",
	Short: "Start a local Batteries Included Installation",
	Long: `This will start a local Batteries Included Installation using Kind and Docker.
It will create a local kubernetes cluster and start the installation process.`,
	Args: cobra.NoArgs,
	RunE: runStartLocal,
}

func init() {
	RootCmd.AddCommand(startLocalCmd)

	// Define local flags
	startLocalCmd.Flags().String("home-base", "https://home.batteriesincl.com", "The URL of the home base to use for the local installation")
	startLocalCmd.Flags().Bool("nvidia-auto-discovery", true, "Enable NVIDIA GPU auto-discovery for Kind clusters")
	startLocalCmd.Flags().Bool("allow-test-keys", false, "Allow test keys for JWT verification when fetching specs (default: production keys only)")
	startLocalCmd.Flags().MarkHidden("allow-test-keys")

	// Bind flags to Viper
	viper.BindPFlag("home-base", startLocalCmd.Flags().Lookup("home-base"))
	viper.BindPFlag("nvidia-auto-discovery", startLocalCmd.Flags().Lookup("nvidia-auto-discovery"))
	viper.BindPFlag("allow-test-keys", startLocalCmd.Flags().Lookup("allow-test-keys"))
}

func runStartLocal(cmd *cobra.Command, args []string) error {
	slog.Debug("Starting local Batteries Included Installation")

	// Use Viper to get all configuration values with proper precedence
	baseURL := viper.GetString("home-base")
	nvidiaAutoDiscovery := viper.GetBool("nvidia-auto-discovery")
	allowTestKeys := viper.GetBool("allow-test-keys")

	ctx := cmd.Context()

	install, err := local.CreateNewLocalInstall(ctx, baseURL)
	if err != nil {
		return fmt.Errorf("failed to create local installation: %w", err)
	}

	slog.Debug("Created new local installation ", slog.Any("ID", install.ID))
	env, err := local.InitLocalInstallEnv(ctx, install, baseURL, nvidiaAutoDiscovery, allowTestKeys)
	if err != nil {
		return fmt.Errorf("failed to initialize local install environment: %w", err)
	}

	slog.Debug("Initialized local install environment")

	if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
		return err
	}

	return start.StartInstall(ctx, env, false)
}
