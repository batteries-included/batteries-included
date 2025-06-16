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
)

var startLocalCmd = &cobra.Command{
	Use:   "start-local",
	Short: "Start a local Batteries Included Installation",
	Long: `This will start a local Batteries Included Installation using Kind and Docker.
It will create a local kubernetes cluster and start the installation process.`,
	Args: cobra.NoArgs,
	RunE: func(cmd *cobra.Command, args []string) error {
		slog.Debug("Starting local Batteries Included Installation")

		baseURL, err := cmd.Flags().GetString("home-base")
		if err != nil {
			return fmt.Errorf("failed to get home-base flag: %w", err)
		}

		ctx := cmd.Context()

		install, err := local.CreateNewLocalInstall(ctx, baseURL)
		if err != nil {
			return fmt.Errorf("failed to create local installation: %w", err)
		}

		slog.Debug("Created new local installation ", slog.Any("ID", install.ID))
		env, err := local.InitLocalInstallEnv(ctx, install, baseURL)
		if err != nil {
			return fmt.Errorf("failed to initialize local install environment: %w", err)
		}

		slog.Debug("Initialized local install environment")

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		return start.StartInstall(ctx, env, false)
	},
}

func init() {
	RootCmd.AddCommand(startLocalCmd)

	// Flag for where to talk to home base
	startLocalCmd.Flags().String("home-base", "https://home.batteriesincl.com", "The URL of the home base to use for the local installation")
}
